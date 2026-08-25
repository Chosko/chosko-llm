# chosko-llm

A CLI for managing personal [Claude Code](https://claude.com/claude-code) **commands** and **skills** — reusable AI behaviors that extend Claude's capabilities. Install them into `~/.claude/` on any machine, keep them up to date, and remove them when you no longer need them.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Chosko/chosko-llm/master/install.sh | bash
```

The installer clones a managed copy of the repo to `~/.chosko-llm/` and puts the `chosko-llm` CLI at `~/bin/chosko-llm`. If `~/bin` isn't on your `$PATH` the installer will tell you how to add it.

The installer does **not** install any features — features are opt-in. Run `chosko-llm ls --available` after installing to see what's available.

### Windows (cmd.exe / PowerShell)

Run the installer from **Git Bash** (not cmd.exe or PowerShell). On Windows the installer also drops a `chosko-llm.cmd` shim so you can call `chosko-llm` from cmd.exe and PowerShell.

The installer prints the native Windows directory you need to add to your **Windows** PATH (not just the Git Bash PATH). Add it via **System Properties → Advanced → Environment Variables → Path → Edit → New**.

**Known caveats:**
- **Git Bash only.** The shim targets Git for Windows' `bash.exe`. WSL users should run `chosko-llm` from inside WSL, where `~/.chosko-llm` is the WSL home — the two filesystems are separate.
- **Muted output in cmd/PowerShell.** Color and interactive suggestions are suppressed because cmd.exe and PowerShell don't allocate a TTY.

## Usage

### Browsing features

```sh
chosko-llm ls                  # all features: installed vs available versions
chosko-llm ls --installed      # only what's installed
chosko-llm ls --available      # only what's in the managed clone
chosko-llm show <feature>      # inspect one feature in detail
chosko-llm show <feature> --diff --content   # preview changes before updating
chosko-llm --version           # print the installed version (also: -v, version)
```

### Installing and removing

```sh
chosko-llm add <feature>       # install a feature into ~/.claude/
chosko-llm add <f1> <f2> ...   # install several features in one call (best-effort: one bad name doesn't block the rest)
chosko-llm rm <feature>        # remove an installed feature
chosko-llm rm <feature> --force  # remove it even when something installed still requires it
```

Some features read a file out of another feature, and say so in their frontmatter (`requires:`). `add` installs those requirements first, one level deep, naming each as it goes — so `chosko-llm add command:task-add` also installs `skill:task-engine`. A requirement that can't be installed aborts that feature before anything is copied for it; the other names in the same call still run. `rm` is the mirror: it refuses to remove a feature that an installed feature still declares in `requires:`, naming every dependent, unless you pass `--force` (which removes it anyway and warns about what you just broke). `add --all` needs neither, since it installs everything.

### Keeping up to date

```sh
chosko-llm upgrade             # pull the latest source from the repo
chosko-llm update --all        # re-copy all installed features from the updated source
chosko-llm update <feature>    # re-copy one feature
chosko-llm update <f1> <f2> ...  # re-copy several features in one call (same best-effort semantics as add)
```

Run `upgrade` first, then `update --all` to pick up new versions. `upgrade` only refreshes the source; it does not touch installed features.

When the pull moves the repo-level version, `upgrade` prints what changed — the `CHANGELOG.md` sections for exactly the versions just pulled, newest first. That readout replaces the raw commit list: you get the curated bullets when the version moved, and the `git log --oneline` subjects when it did not (or when the clone is old enough to have no `CHANGELOG.md`). The same block appears when the daily auto-upgrade runs.

#### Channels: trying unmerged work

A **channel** is just the branch the managed clone is checked out on. Switch onto a feature branch to try it before it lands on `master`, then switch back:

```sh
chosko-llm channel                # print the channel the clone is on
chosko-llm channel --list         # fetch origin and list channels you can switch to
chosko-llm channel my-feature     # switch to a branch: fetch, checkout, fast-forward, refresh proxy
chosko-llm update --all           # deploy that channel's features into ~/.claude/
chosko-llm channel master         # back to stable
```

Switching does a full fetch + checkout + `pull --ff-only` + proxy refresh, but only *suggests* `update --all` — deploying features into `~/.claude/` stays an explicit step, same as `upgrade`. There's no state file: the checked-out branch is the whole persistence mechanism, and the daily auto-upgrade's `pull --ff-only` already follows it. Once a feature branch is merged and deleted upstream its `pull --ff-only` will fail — recover with `chosko-llm channel master`.

#### Migrating `task-implement` from a command to a skill

As of v0.7.0 `task-implement` ships as a **skill** (`skills/task-implement/`) rather than a command. `update --all` cannot perform this migration: it walks what is currently *installed*, so it will report `Skipping command 'task-implement': no source in managed clone` and leave the stale command in place without installing the skill. Migrate once, by hand:

```sh
chosko-llm upgrade
chosko-llm rm command:task-implement
chosko-llm add skill:task-implement
```

The invocation is unchanged — you still run `/task-implement`. Only the packaging changed, so the skill can ship supporting files that Claude reads only when the relevant branch applies.

#### Daily auto-upgrade

The first `chosko-llm` command you run each day quietly runs `chosko-llm upgrade` for you before doing its job, so the source stays current without you thinking about it. You're opted in at install time; it runs at most once per calendar day and never blocks your command if the pull fails.

```sh
chosko-llm upgrade --disable-auto   # opt out of the daily auto-upgrade
chosko-llm upgrade --enable-auto    # opt back in
```

These flags only change the preference — they don't perform an upgrade. The opt-in/opt-out state and the last-run date live in a gitignored file in the managed clone (`~/.chosko-llm/.auto-upgrade-state`). Set `CHOSKO_LLM_NO_AUTO_UPGRADE` to skip the automatic run entirely (handy in CI or scripts).

### Exporting a repo's Claude config

`chosko-llm export` packages a repo's Claude config — `CLAUDE.md`, `AGENTS.md`, `README.md`, and the curated Markdown/JSON/TOML/shell subset of `.claude/` (the shell part covers hooks and the task-setup test runners, which `settings.json` and the backlog wiring reference) — into a single hand-off artifact, useful for sharing a repo's setup outside the working directory:

```sh
chosko-llm export                 # writes ~/claude-exports/<repo>-claude-config.md
chosko-llm export /path/to/repo   # export a different repo; defaults to $PWD
chosko-llm export --archive       # writes a .zip instead, for uploading to a Claude chat
```

The default Markdown shape concatenates every selected file into one document — suited to a Claude Project's knowledge base, where the whole thing gets ingested at once. `--archive` writes a zip with the files under a top-level `<repo>/` directory plus a root `MANIFEST.md`, suited to a Claude chat, where the assistant reads members selectively. Both shapes draw from the same file-selection rules, so they never disagree about what a repo's config is. Output goes to `$CHOSKO_LLM_EXPORT_DIR` (default `~/claude-exports`), created if missing; the written path is printed on success.

### Per-repository installs

`ls`, `show`, `add`, `rm`, and `update` all accept `--local` / `--global`. `--global` (the default) targets `$CLAUDE_HOME` as usual. `--local` targets `<cwd>/.claude` instead, so a feature can be installed into a single repository rather than globally:

```sh
chosko-llm add refactor-codebase --local   # install into <cwd>/.claude/ instead of ~/.claude/
chosko-llm ls --local                      # list what's installed in <cwd>/.claude
chosko-llm update --all --local            # refresh everything installed locally
chosko-llm rm refactor-codebase --local    # remove it again
```

`--local` requires `<cwd>/CLAUDE.md` to already exist — run it from the project root (or run `/project-setup` first on an empty directory). claude-md artifacts are the one exception to the `.claude/` target: they inject their managed section into `<cwd>/CLAUDE.md` itself, since that's the file Claude Code actually reads for the project.

statusline scripts are global-only — a status bar belongs to your terminal, not a repository. A single-feature `add`/`update`/`rm` naming a statusline feature fails with `--local`; `add --all --local` and `update --all --local` skip the statusline pass instead of failing; `ls --local` omits it entirely; `show --local` on a statusline feature reports it as global-only rather than erroring.

### Feature names

A bare name like `refactor-codebase` matches commands, skills, claude-md artifacts, statusline scripts, and hooks. If a name is ambiguous, disambiguate with `command:<name>`, `skill:<name>`, `claude-md:<name>`, `statusline:<name>`, or `hook:<name>`.

claude-md artifacts are a third feature kind: rather than copying a standalone file, they inject a managed section into `~/.claude/CLAUDE.md`. The section is delimited by HTML comment markers, so your own CLAUDE.md content around it is preserved.

statusline scripts are a fourth feature kind: a status-bar shell script installed to `~/.claude/statusline/<name>.sh`. Since `settings.json`'s shape isn't this repo's to own, `chosko-llm add` doesn't edit it — it prints a copy-pasteable prompt for a Claude Code session to safely merge the installed path into the top-level `"statusLine"` key.

hooks are a fifth feature kind: a script Claude Code runs on a hook event, installed to `<cwd>/.claude/hooks/<name>.sh` with the same printed-prompt approach to `settings.json`. Hooks are **local-only**, the mirror of statusline's global-only rule — a hook only fires where it is committed, and a cloud container clones the repository and nothing else, so a globally wired hook could never reach the agent it governs. A single-feature hook request without `--local` fails; `add --all` / `update --all` in global scope skip the hook pass; `ls --global` omits hooks; `show --global` on a hook reports it as local-only.

## Uninstall

```sh
chosko-llm uninstall
```

(or, from a working copy, the standalone `./uninstall.sh` — same flow).

Asks for an up-front confirmation, then prompts before each destructive step:

1. Remove the CLI proxy at `~/bin/chosko-llm` (and `chosko-llm.cmd` on Windows).
2. Optionally delete every installed feature under `~/.claude/` that matches a feature in the managed clone (user-authored files are left alone).
3. Optionally remove the managed clone at `~/.chosko-llm/`.

Pass `-y` (or `--yes`) to answer every prompt yes for non-interactive use.

## Configuration

| Env var           | Default         | Purpose                                              |
| ----------------- | --------------- | ---------------------------------------------------- |
| `CHOSKO_LLM_HOME` | `~/.chosko-llm` | Managed clone location.                              |
| `CLAUDE_HOME`     | `~/.claude`     | Where features get installed.                        |
| `BIN_DIR`         | `~/bin`         | Where the CLI proxy lives. Used by `install.sh`.     |
| `NO_COLOR`        | unset           | Set to any value to disable colored output.          |
| `CHOSKO_LLM_NO_AUTO_UPGRADE` | unset | Set to any value to skip the daily auto-upgrade.     |
| `CHOSKO_LLM_EXPORT_DIR` | `~/claude-exports` | Where `chosko-llm export` writes its output. |

---

## Claude Code Workflows

These features add up to a few connected ways of working in a project. Install
them with `chosko-llm add <feature>` (opt-in), then run them as slash commands
(`/<name>`) inside Claude Code. File-writing commands leave output uncommitted
for review by default; override with `--commit` / `--no-commit`.

### The product pipeline — from idea to merged code

Seven of these commands form one continuous pipeline. Each stage hands its
output to the next as a **document in the repo**, not as conversation, so the
work survives across sessions, machines, and people.

| Stage | Command | Consumes | Produces |
| --- | --- | --- | --- |
| 0 — scaffold | [`/domain-setup`](#set-up-the-domain-layer--domain-setup) | nothing | the domain layer + an empty `.claude/FEATURES.md` |
| 1 — design | [`/product-design`](#design-a-product--product-design) | you, and the repo when it already has code | `product-design.md`, `technical-direction.md`, optional `business-model.md`, `design-process.md` |
| 2 — roadmap | [`/product-roadmap`](#decide-what-ships-when--product-roadmap) | you, plus `product-design.md` when you have one | `product-roadmap.md` — ordered milestones and their scope slices |
| 3 — architect | [`/architect`](#design-how-to-build-it--architect) | a high-level feature, or a bare prompt — one milestone's scope slice of it when you have a roadmap | `.claude/domain/features/<slug>.md` + a `FEATURES.md` entry |
| 4 — sequence | [`/production-plan`](#decide-what-to-build-next--production-plan) | `FEATURES.md`, the feature documents' dependencies, the roadmap when you have one | `.claude/PLAN.md` — features per milestone, in order, plus the dependency edges |
| 5 — plan | `/task-add feature=<slug>` | a feature document | task bodies + `TASKS.md` entries |
| 6 — build | `/task-implement` | a task body | code, one commit per task |

Stages are **entered, not marched through**. Nothing downstream requires that
an upstream stage was ever run.

Reading across the whole of it there is one more command,
[`/production-status`](#see-what-to-build-next--production-status). It writes
nothing and belongs to no stage: it joins `PLAN.md`, `FEATURES.md` and
`TASKS.md` and tells you which feature to start next.

**Where to start.** Two realistic starting conditions:

- **A brand new product.** Run `/domain-setup`, then `/product-design` to work
  out what you're building, then `/architect` per feature.
- **An existing codebase.** Run `/domain-setup`, then go straight to
  `/architect` — it reads your code (via the context layer, if you have one)
  and accepts a bare description, so you never need design documents you
  don't have. Or skip the pipeline entirely and use plain
  `/task-add <description>`, exactly as before: the free-form path is
  unchanged by any of this.

**Worked example.** `/product-design` lands "user accounts" among the
high-level features in `product-design.md`. `/architect user accounts` decides
it's really two architectural features and writes
`.claude/domain/features/password-auth.md` and
`.claude/domain/features/session-handling.md`, each with a `FEATURES.md` entry
at `Status: [NEW]`. `/task-add feature=password-auth` reads that document,
proposes four implementation tasks plus a trailing documentation-update
task, and on your approval writes tasks 31–35 — each carrying
`Feature: password-auth`, task 35 preconditioned on 31–34 — sets the entry
to `Tasks: 31, 32, 33, 34, 35` and `Status: [PLANNED]`. `/task-implement 31`
builds the first one and commits it.

**The iterate loop.** Designs change after tasks exist, and this is the part
worth understanding before you hit it:

1. You re-run `/architect password-auth`. It sees the feature is `[PLANNED]`
   and checks the tasks it generated.
2. If any of them is `[IN PROGRESS]`, it **refuses** — an implementation is
   underway against the design you're about to change. There's no override.
   Finish or reset that task first.
3. Otherwise it lists the unfinished tasks and asks. On your go-ahead it
   rewrites the feature document, marks those tasks **`[STALE]`**, and sets
   the feature **`[ITERATED]`**.
4. `[STALE]` means "the design moved; this task needs reconciling". Nothing is
   deleted. `/task-clean` won't prune it, and `/task-implement` warns and lets
   you decide — `all` and `next` skip it.
5. `/task-add feature=password-auth` **reconciles**: each stale task is left
   alone, updated in place (back to `[MISSING]`), or skipped with a reason and
   replaced. `[DONE]` tasks are never touched. The feature returns to
   `[PLANNED]`.
6. Once tasks 31–35 are all `[DONE]`/`[SKIP]`, `/task-implement` notices —
   the last one to land triggers the check — and proposes, once, at the end
   of the run: flip `password-auth` to `[DONE]` in `FEATURES.md`? You decide;
   a many-task run batches every feature it finished into one proposal at
   the very end, never one per task. You can also flip a feature to `[DONE]`
   by hand, any time, with no command involved.

Three vocabularies are at work and they mean different things. A **feature**
status (`[NEW]` / `[ITERATED]` / `[PLANNED]` / `[DONE]`) describes whether
the backlog matches the design — never whether the feature is built, except
for `[DONE]`, which says both at once: backlog matches design *and* every
task finished. A **task** status (`[MISSING]` … `[DONE]`) describes the work
itself. A **milestone** status in `PLAN.md` (`[PLANNED]` / `[ACTIVE]` /
`[SHIPPED]`) describes delivery. `[ITERATED]` is the one state that demands
action; `[DONE]` is the one a human always confirms.

The sections below are the per-command reference.

### Start a project — `/project-setup`

One-pass setup for a new repo. Seeds `CLAUDE.md` from pasted material, adds an
optional `AGENTS.md` pointer, injects a VCS-mapping section for non-git
projects, and can kick off the task backlog and context layer. Gathers every
choice up front, confirms once, then executes. Leaves everything uncommitted
by default; `--commit` commits (and pushes) its own artifacts and forwards
`--commit` (plus `--no-push`, if set) to the sub-commands it runs. On a
non-git VCS (e.g. Plastic SCM), the injected `## VCS` section notes that
`cm checkin` already syncs to the server, so no push cycle ever runs there.

### Set up Unity MCP — `/unity-mcp-setup`

For Unity projects, wire up MCP so `/task-implement` can drive the editor
itself instead of pausing for you at every manual step. Idempotent and
re-runnable: it adds the `com.coplaydev.unity-mcp` package to
`Packages/manifest.json` if missing, records a marker in `CLAUDE.md` (and a
`.claude/context/mcp-tools.md` doc when the project has a context layer), and
registers + verifies the `UnityMCP` server on your machine
(`claude mcp add` / `claude mcp list`). The project-side artifacts are
versioned and shared; the Claude-side registration is machine-local (in
`~/.claude.json`) and stays per-machine. `/project-setup` offers to run it on
Unity projects. Leaves its versioned artifacts uncommitted by default;
`--commit` commits and pushes them (`--commit --no-push` to skip the push).

The repo also ships a `unity-mcp-skill` skill — a Unity-MCP operator guide
(resource-first workflow, tool categories, and reference files for tool
schemas and extended workflows) that Claude can lean on when driving the
editor over the `UnityMCP` server. Install it like any other feature with
`chosko-llm add skill:unity-mcp-skill`.

### Keep Claude oriented — `/context-build`, `/context-update`, `/context-convert`

Build a *navigation layer*: small structured summaries that let future Claude Code sessions
open only the source files they need, saving tokens.

All three ship as **skills**, not commands (`/context-build` and
`/context-update` were commands before v0.46.0 — see the migration note below).

- `/context-build` — create the layer once. (it can be invoked automatically by `/project-setup` if chosen when asked). Commits only under `--commit`, and pushes too unless `--no-push` is also passed.
- `/context-update` — refresh only the parts the latest diffs touched. Commits and pushes automatically; `--no-commit` skips both, `--no-push` commits without pushing.
- `/context-convert` — restructure a layer you already have from one layout to
  the other, without rebuilding it from source. Plan-first: it reports every
  move, date decision and link rewrite, then stops for approval (`-y` skips the
  gate). Commits only under `--commit`.

#### Two layouts: flat by default, nested on demand

- **Flat** (the default, and what every existing layer already is) — one
  `.claude/context/INDEX.md` with every context file beside it. Nothing to opt
  into; this is what `/context-build` produces when you pass no layout argument.
- **Nested** (opt in with `/context-build nested`, or
  `/context-build nested=api,worker` to name the units yourself) — a *router*
  `INDEX.md` that lists units, plus one *leaf* `INDEX.md` per unit that owns
  that unit's context files. Worth it on a repo big enough that a single index
  is itself an expensive read. Nesting is capped at two levels: router plus one
  rank of leaves.

Each leaf carries its own `Last updated` date, so refreshing one unit does not
make the others look fresher than they are; `/context-update unit=<name>` scopes
a run to a single leaf. The per-file six-section schema, the 150-line file cap
and the snippet cap are identical in both layouts — only *where the index files
live* changes.

A layer declares its own shape with a `Layout: flat` / `Layout: nested` line
directly under the title of `.claude/context/INDEX.md`. Detection is that line
and nothing else — a missing marker means flat, so pre-existing layers keep
working and `/context-update` backfills the marker on its next run.
`/context-build` will not convert an existing layer; that is `/context-convert`'s
job.

> **Upgrading from an older install:** `/context-build` and `/context-update`
> used to be commands. The new skills declare `replaces: command:<name>`, so
> `chosko-llm upgrade && chosko-llm update --all` installs the skill and removes
> the stale command copy for you — you should not end up with two definitions of
> the same slash command.

### Clean up safely — `/refactor-codebase` and `/refactor-tests`

Behaviour-preserving cleanup under a safety net: plan first, get approval, then
proceed phase by phase, running the test suite between steps and halting on the
first failure.

- `/refactor-codebase` — constants, duplication, oversized files, imports, naming.
- `/refactor-tests` — split bloated test files.

Both leave the result uncommitted by default; `--commit` commits and pushes it (`--commit --no-push` to commit without pushing).

### Set up the domain layer — `/domain-setup`

Scaffolds `.claude/domain/`, the counterpart to the context layer: where the
context layer records *codebase structure*, the domain layer records what the
product is, how its features are designed, and why. `/domain-setup` creates
the directory, a `features/` folder, a domain `INDEX.md`, the
`.claude/FEATURES.md` feature index, and a `CLAUDE.md` pointer — then stops.
It never writes design documents; those come from `/product-design` and
`/architect`.

Idempotent and safe to run on an existing project: if you already have
hand-written docs under `.claude/domain/`, it indexes them instead of
replacing them. Leaves everything uncommitted by default; `--commit`
commits and pushes it (`--commit --no-push` to skip the push).

### Design a product — `/product-design`

Brainstorm a product from the ground up with Claude and write the result into
the domain layer: what it is, who it's for, the key flows, the big decisions,
and the high-level feature set described from the user's side — plus a
technical direction (stack, topology, data, hosting) covering the product as
a whole, not feature-by-feature. A business model is optional and opt-in.
Requires `/domain-setup` to have run.

It works on an existing codebase as well as a blank one — it reads what's
there and opens with "here's what I see you've built; is this still the
intent?". The technical-direction round follows the same rule: on an
existing codebase it confirms and records what's already there rather than
re-opening the stack.

Designing a product takes more than one sitting, so the process is
**resumable**: its state lives in `.claude/domain/design-process.md`, not in
the conversation. Run `/product-design` again weeks later and it tells you
where the last session stopped and offers to pick up there. There's no flag
to remember. Before it stops after write-back, it also sweeps the
conversation for anything the written documents don't yet cover and folds
it in automatically, so detail raised in the interview doesn't quietly die
with the session.

On a greenfield project, when PHASE 6 hits a technical fork that genuinely
matters, it can route the decision through the council — see
[Pressure-testing a decision](#pressure-testing-a-decision--claude-council)
below.

The output — including `technical-direction.md` — is `/architect`'s input.
Nothing is committed by default; `--commit` commits and pushes what the run
wrote (`--commit --no-push` to skip the push).

### Decide what ships when — `/product-roadmap`

Writes `.claude/domain/product-roadmap.md`: an ordered list of milestones,
each with the outcome it delivers (`Goal:`), what makes it shippable
(`Exit criteria:`), why it comes where it does (`Rationale:`), and the
**scope slices** saying which share of a high-level feature it takes on
(`Covers:`). Plus a `Not now` list where every deferral carries the trigger
that would pull it back in, and the sequencing questions you couldn't close.

A slice names a `product-design.md` section and states its scope in prose —
and what really matters is the exclusions: "email and password only; no
third-party providers, no SSO". `§ Authentication` can appear in an early
milestone and again in a much later one, because how a feature splits across
releases is a business call, not an architectural one. `Covers:` is a
*decomposition instruction for `/architect`*, not a promise about what ships,
so a section spread over several milestones is normal and nothing checks that
the slices add up.

Milestone slugs (`m1-mvp`) are stable and never renumbered — order is just
list position, so you can insert a milestone between two others freely. The
roadmap carries **no status, no dates and no estimates**: it records intent,
not progress. It reads `.claude/FEATURES.md` and never writes it — when you
edit a slice whose section has already been architected, it says so and points
you at `/architect <slug>` rather than changing anything downstream.

Requires `/domain-setup`. `product-design.md` is optional — you can draft a
roadmap from a bare description. Re-run it whenever the plan moves: the
document is its own resume state, so a later run proposes changes against
what's already there, behind the same single approval gate. Nothing is
committed by default; `--commit` commits and pushes what the run wrote
(`--commit --no-push` to skip the push).

### Design how to build it — `/architect`

Takes a high-level feature and decides how it will actually be built, then
writes that down as a low-level feature document under
`.claude/domain/features/`, indexed in `.claude/FEATURES.md`. One product
feature often becomes several architectural ones.

It grounds the design in `technical-direction.md` when `/product-design` has
recorded one, adopting it exactly like an existing codebase stack — no
re-arguing it, no tech-stack proposal step, just a one-line note that it's
designing within the recorded direction. Otherwise it grounds the design in
the code you already have (reading the context layer first), and proposes a
tech stack only when there isn't one either way. It stops at components,
data, and contracts — no code, no file-by-file plans. Those come from
`/task-add`, which reads the code as it stands at planning time.

You can run it from a `/product-design` feature, from a feature name, or from
a bare description with no design documents at all.

**Slice mode.** If you've written a roadmap, `/architect` doesn't decompose a
whole product feature at once — it architects one *scope slice*, the share of
that feature a single milestone takes on. It switches into this mode purely on
finding `.claude/domain/product-roadmap.md` with a milestone that has a
`Covers:` line; there is no flag to turn on and nothing to configure. The
slice's scope statement becomes the boundary, its exclusions become the
feature document's non-goals, and the milestone is recorded on the
`FEATURES.md` entry as `Source: product-design.md § Authentication (m1-mvp)`.
Every low-level feature then belongs to exactly one milestone.

The choice is made **per feature, not per run**: a section your roadmap
doesn't slice takes the ordinary path even on a roadmapped project, and it
tells you when it does. If a section is sliced across several milestones it
asks which one you mean rather than guessing — and it never architects the
union of two slices. A project with no roadmap behaves exactly as it always
has, silently. Pass `--no-slices` to ignore the roadmap for a run; on a
project without one, the flag does nothing.

Re-architecting a feature that already produced tasks is guarded: if any of
those tasks is `[IN PROGRESS]` it refuses outright, and otherwise it asks
before marking the surviving tasks `[STALE]` and the feature `[ITERATED]` —
then tells you to reconcile with `/task-add feature=<slug>`.

At a genuine design fork — the stack choice, the shape of the architecture,
or where the low-level split falls — it can route the decision through the
council; see below.

Nothing committed by default; `--commit` commits and pushes exactly the
written paths (`--commit --no-push` to skip the push).

### Decide what to build next — `/production-plan`

Writes `.claude/PLAN.md`: a third index beside `TASKS.md` and `FEATURES.md`
saying which low-level feature belongs to which milestone, **in what order**,
and after what. The roadmap says which outcomes come first; this says which
architected features that implies and which one you can actually start.

Each milestone block carries a `Status:`, a derived `Covers:` line, and an
ordered `Features:` list — and that order **is** the priority. There is no
`P0`/`P1` label, no size, no estimate and no date, because a second ordering
alongside the list would eventually contradict it. Everything not yet placed
sits in an `Unscheduled` block. All the dependency edges live in one flat
`## Dependencies` list at the foot of the document, where a cycle is visible
to a human reader.

A feature's milestone is **inherited, not guessed**: it comes from the
parenthetical `/architect` writes on the `FEATURES.md` `Source:` line
(`… § Authentication (m1-mvp)`). Features architected without a roadmap start
in `Unscheduled`. You can place any feature by hand and that wins — an
override is reported plainly at the approval gate, never refused.

The edges come from prose. Each feature document already has a
`## Dependencies` section; the skill proposes the edge set it implies, you
confirm or edit it, and `PLAN.md` stores the result. The prose stays the
human-facing statement and is never rewritten — which is also what lets you
record an edge the documents never stated.

Then it **refuses the two arrangements that cannot be built**: a dependency
cycle (reported as the actual cycle path, with no override flag) and a feature
scheduled before something it needs (reported with both features and both
milestones). Validation runs before anything is written.

Milestone status is `[PLANNED]` / `[ACTIVE]` / `[SHIPPED]`, at most one
`[ACTIVE]` at a time. `[SHIPPED]` is only ever *proposed* — when every feature
in the milestone is `[PLANNED]` and all their tasks are `[DONE]` or `[SKIP]`
— and it never reopens; follow-up work is a new milestone.

Requires `/domain-setup` and at least one architected feature. A roadmap is
**optional**: without one everything lands in `Unscheduled` and the dependency
ordering still works. Re-run it whenever features or milestones move — it
reconciles against the current `FEATURES.md` and roadmap behind the same
single approval gate, keeping the orderings and edges you set. It is the sole
writer of `PLAN.md` and reads `FEATURES.md`, the feature documents, the
roadmap and `TASKS.md` without writing any of them. Nothing is committed by
default; `--commit` commits and pushes what the run wrote (`--commit
--no-push` to skip the push).

### See what to build next — `/production-status`

Reports what to build next by joining `PLAN.md`, `FEATURES.md` and `TASKS.md`
— the active milestone with its roadmap goal and exit criteria, its features
in plan order with their task rollup and readiness, the ready set, the single
recommended next feature, blocked features named with their blocker, coverage
gaps, features missing from the plan, and the remaining milestones. It writes
nothing.

The plan says what belongs where and in what order, `FEATURES.md` says whether
a feature's tasks match its design, and `TASKS.md` says whether the work is
done. The useful answer is in the join of the three and in none of them alone,
so this command computes it **on every read** and stores nothing:

- **Ready** — every dependency edge pointing at the feature comes from a
  feature that is `[PLANNED]` with all of its tasks `[DONE]` or `[SKIP]`. No
  dependencies means ready.
- **Blocked** — anything else, and always *named with what blocks it* and why,
  so a blocked list is somewhere to go rather than a dead end.
- **Recommended** — the first ready feature in plan order. Exactly one, and
  the command stops there: it reports the next thing to build, it doesn't
  start it.

Task rollups are counts per status by default (`4 tasks — DONE: 2, MISSING:
2`); pass `--task-ids` to name each task instead. `milestone=<slug>` reports a
named milestone rather than the active one.

Staleness is **structural, not temporal**: rather than checking dates, the
report simply names every `FEATURES.md` slug missing from `PLAN.md` and points
you at `/production-plan`. A plan that has fallen behind says so by having
gaps.

Nothing here refuses. No roadmap drops the goals and exit criteria, no
`TASKS.md` drops the rollups, no active milestone reports the first planned
one, and a dependency edge naming a feature that doesn't exist is reported as
a plan inconsistency with the feature treated as ready — failing open, because
a hand-edited plan must never make the report claim there's nothing to do. The
only thing it won't do is run without a `PLAN.md`, and then it tells you to
run `/production-plan`.

Read-only in the strict sense: no writes, no commits, no shell commands, and
it never opens a task body under `.claude/tasks/`.

### Pressure-testing a decision — `claude-council`

`/product-design` and `/architect` both reach forks where two or three
options are genuinely defensible and the wrong pick is expensive to undo.
Both can hand that decision to `claude-council` — a skill that runs the
question through five thinking lenses (Red Team, First Principles,
Expansionist, Outsider, Executor), peer-reviews them anonymously, forces an
adversarial debate when the consensus looks too clean, and returns a verdict
that keeps any minority dissent intact.

chosko-llm ships it, vendored from the upstream project
[TorpedoD/claude-council](https://github.com/TorpedoD/claude-council) —
credit and the design are theirs; this repo carries a copy so it installs and
upgrades like any other feature. Install it the usual way:

```sh
chosko-llm add skill:claude-council
```

It's **entirely optional** — shipping is not installing. When it's installed,
the two commands offer to convene it at a real fork and wait for your yes.
When it isn't, they say nothing and behave exactly as they always have — no
prompt, no warning, no missing-dependency error.

It needs `jq` on your `PATH`: the council's journal append (Step 10) and
`/claude-council meta` both use it. The rest of the run works without it.

Two things worth knowing:

- **The council advises; you still decide.** Its verdict feeds the
  recommendation you're shown. `/architect` still won't leave PHASE 2 without
  your confirmation, and `/product-design`'s PHASE 6 still ends when you say
  it ends.
- **Dissent is kept, not resolved.** A minority view that survives the
  synthesis lands in the feature document's open questions, or in
  `product-design.md`'s design decisions — recorded as a live concern rather
  than quietly dropped.

The council writes its own HTML report and markdown transcript into the
working directory. Neither command commits them or deletes them; you're told
where they landed and can keep or bin them.

### Work through a backlog — the `task-*` commands

A lightweight, in-repo issue tracker. Work is captured as small, reviewable
tasks. The core idea is to spend more focus in planning and writing down tasks, then let the agent consume them automatically whenever it is convenient.

- `/task-setup` — initialize the backlog.
- `/task-add` — plan a task and write it down. This is the real strength of this workflow: invoke the command with a very short description, let Claude Code investigate and expand it, in a conversational way. Claude will ask every question needed to fill the gaps, then it will write everything down for further implementation. It may propose splitting the description into several tasks when that gives better units (independent deliverables, or one task that's too large) — pass `--no-split` to always get exactly one task.
- `/task-add feature=<slug>` — plan from an `/architect` feature document instead of a description. The document is the input, so you don't re-explain the work in prose; a feature usually becomes several tasks. Run it again after re-architecting and it *reconciles* rather than duplicating: each existing task is either left alone, updated in place, or skipped with a reason and replaced — and `[DONE]` tasks are never touched. When the run drafts any new task, it appends one more at the end to update the affected documentation once the others land. You approve the whole plan, reconciliation included, in one pass.
- `/task-list` — show what's pending. On a project with a `.claude/PLAN.md` it groups the backlog **by milestone in plan order**, resolving each task's `Feature:` slug through the plan, and flags any task whose feature is blocked with `⚠ blocked by <slug>` alongside the existing markers; tasks with no feature, or one the plan doesn't list, fall under a trailing `Unplanned` heading. With no plan, the output is exactly what it has always been — no grouping, no flags, and no message about the missing plan.
- `/task-implement` — build a task end-to-end, test-first, one commit (and push) each. Pass `--review [--rounds N]` to have each task reviewed before it's committed: after the tests and before the status flip, the run spawns `/task-review` in a fresh subagent, waits for its findings, and runs `/task-iterate` in the session to triage and apply them — the fixes ride in the task's own single commit. When a feature-derived task finishes the last task for its feature, proposes — once, at the end of the run — flipping that feature to `[DONE]` in `FEATURES.md`; you decide.
- `/task-review` — audit a diff against the acceptance criteria of the task that produced it. Three input forms: no argument reviews the uncommitted tree, a branch name reviews that branch against the repo's default branch (`base=<ref>` overrides), a PR number or URL reviews that pull request through `gh`. It reports only findings it holds at 80% confidence or better, each citing a `file:line` and a concrete failure mode, at `BLOCKING` / `IMPORTANT` / `ADVISORY` — an unmet acceptance criterion is always blocking, and finding nothing is a valid, complete review. Read-only: it never edits, never commits, and never opens a PR.
- `/task-iterate` — triage the findings `/task-review` produced, apply the ones that survive, and record why the rest didn't. Every finding gets exactly one of `fix`, `defer` or `reject`, written out in full before the first edit — that table is the point of the skill, and its rejections travel into the next review round as binding context so a rejected finding can't simply be re-raised. It never invents a finding of its own.
- `/task-clean` — prune finished tasks.

The rules these features share — how a task is resolved from `TASKS.md`, what
each status means, what `Target:` gates, how `[STALE]` is handled, the
dirty-tree prompt, and how commits and pushes are gated — live once, in the
`task-engine` skill, and each feature references them instead of restating
them. `task-engine` is not a command you invoke; it is a reference library the
others read while they run. `/task-add`, `/task-list`, `/task-clean` and
`/task-implement` all declare `requires: skill:task-engine`, so installing any
one of them installs the engine too, and `chosko-llm rm skill:task-engine`
refuses while any of them is still installed.

`/task-add`, `/task-clean`, `/task-implement`, and `/task-iterate` commit
automatically and then push, once per task for `/task-implement` (pass
`--no-commit` to skip both, or `--no-push` to commit without pushing).
`/task-review` commits nothing at all — it is read-only by contract.
`/task-setup` only commits under `--commit`, at which point it pushes too
(`--commit --no-push` commits without pushing).

`/task-iterate` is the one exception to that, and deliberately so: run
standalone it commits and pushes like the rest, but run *inside*
`/task-implement --review` it commits nothing and leaves the corrected tree
for that run's own commit step. Otherwise a reviewed task would land an
implementation commit plus a separate fix commit for work nobody reviewed
separately — so a task stays at exactly one commit, reviewed or not.

Tasks can be **human-in-the-loop**: when part of the work only a human can
perform in an external tool (a Unity editor step, a cloud console, hardware),
`/task-add` marks the task `Target: claude+human` (or `human` for fully
manual work) and records the checkpoints in a `## Manual interventions`
section. `/task-implement` then pauses at each checkpoint, walks you through
the manual step, and verifies the outcome itself (the promised file exists,
the project compiles) before moving on — saying "done" isn't enough.
`/task-list` marks these tasks with a ⚠ so you know they need you present.

Tasks generated from a feature document carry a `Feature: <slug>` line and
can go **stale**: if the feature is re-architected afterwards, its unfinished
tasks are flipped to `[STALE]`, meaning the spec may no longer match the
design. Stale tasks are never pruned by `/task-clean` — they're live work
awaiting reconciliation, normally by re-running `/task-add feature=<slug>`.
`/task-implement` warns before starting one and lets you implement it anyway
or stop; `all` and `next` skip them so a batch run never guesses.

On a Unity project set up with [`/unity-mcp-setup`](#set-up-unity-mcp--unity-mcp-setup),
those checkpoints can flip around: when the `UnityMCP` server is connected,
`/task-implement` makes the editor changes itself — checking the Console
after compilation and creating GameObjects, components, and references via
MCP — then hands you a *verification* step ("I created Foo under Bar —
confirm you see it") instead of an instruction. It asks once per task
whether you want it to drive Unity or pause for you to do the steps
manually, and steps MCP genuinely can't perform stay manual. When the
server isn't connected, the standard manual protocol above runs unchanged.

### Hand off a conversation — `/session-save` and `/session-resume`

A conversation ends and its context dies with it. The backlog records *what*
was done and `.claude/context/` records *where things are*; neither records the
middle — what was tried and failed, what was deliberately not tried, which
files are half-finished, and what the exact next step was. That knowledge is
otherwise re-derived from scratch every time a session ends mid-flight, at full
token cost and with no guarantee the re-derivation matches.

- `/session-save` — write what this conversation knows into
  `.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md`. Pass a slug to override the
  generated one.
- `/session-resume` — brief the current conversation from one of those files,
  then stop.

The store is **per-project**, not global: session files sit beside the
project's other `.claude/` artifacts rather than mixing every project into one
bucket under your home directory. Nothing in the CLI reads them — no
`chosko-llm` subcommand walks `.claude/sessions/`, and nothing derives from
what's written there. They are context for a human or an agent, never input to
tooling.

A save takes one of **two forms**. The full form is nine sections — what we're
building, what worked and the evidence for it, what didn't work and why, what
hasn't been tried, the state of each file, decisions with their reasons,
blockers, the exact next step, and environment notes — and *every* section is
written even when it's empty, `N/A` rather than silence, because a skipped
section is indistinguishable from an overlooked one. The pointer form is
written instead when the work already has its own resume artifact — a
project-scoped state document carrying a current-stage marker, such as
`/product-design`'s `.claude/domain/design-process.md`. Then the session file
is a header block and one sentence saying where the state actually lives: two
accounts of the same state that can disagree is worse than one.

Both forms carry a **`Work:` line**, the one typed link from the session to the
document the work belongs to: `task <n>`, `feature <slug>`, `document <path>`,
or `none`. `none` is a first-class value, not a failure — a debugging session
that touched no backlog document is exactly what it's for, and inventing a link
there would make the link untrustworthy everywhere else.

`/session-resume` takes the newest file, the newest from a date you name, or a
path. It flags a handoff older than 14 days as stale and names any path the
file mentions that no longer exists — both *before* the briefing, not after —
then reports what was being built, what must not be retried, and the exact next
step verbatim, **and stops**. It starts no work, edits no file, and takes no
step of the plan it just described, not even the obvious one. The value is
entirely in the stopping: you asked to be told where things stood, not to have
the next step taken for you while you were reading.

Old handoffs are pruned by **finishing the work**, not by a flag.
`/session-resume` closes by naming the file it resumed from and handing over
its deletion: delete it once the `Work:` it describes is finished, deletion
being part of finishing rather than cleanup afterwards. If the session ends
first, the next `/session-save` in a conversation that resumed from a file
writes its new snapshot and deletes the one it superseded, so two snapshots of
the same work never coexist. A file that was never resumed is never deleted
automatically — the stale flag is the only signal it will ever get. There is no
`--prune`.

Neither command commits. `/session-save` writes the file, reports the path, and
notes in one line that it's untracked; whether a handoff belongs in the repo's
history is your call.

### Work through a plan of prompts — the `runbook-*` commands

A design conversation ends with seven follow-up prompts. Run them in one long
session and step 6 drifts from step 1's framing; save them for later and they
stop making sense, because each one leaned on a decision made an hour earlier
and written down nowhere. A **runbook** is that list made durable: an ordered
set of self-contained prompts, each written to be executed by a *fresh* agent
that has none of the conversation the prompts came out of.

- `/runbook-create` — author one from the conversation you're in (the default —
  the decisions, the rejected options and the verified probes are all still in
  context), or from a free-form description through one batched interview.
  `--append <name>` adds steps to an existing runbook, including one a run is in
  the middle of; `--append` with no name targets the runbook this session is
  running.
- `/runbook-run <name>` — execute it, one step at a time. `--from N`, `--only N`
  and `--model <model>` narrow or redirect the run.
- `/runbook-list` — every runbook as one line: status, name, steps done over
  total, created date, source.
- `/runbook-clean` — delete finished runbooks, planning and confirming first.
- `runbook-suggest` — a skill nobody invokes. It fires on its own description
  when a conversation produces a list worth capturing, points at
  `/runbook-create` in one line, and stops.

The store is committed, like the backlog: `.claude/runbooks/<name>.md` per
runbook, plus a `.claude/RUNBOOKS.md` index mirroring `TASKS.md`'s block shape
(minus its counter — names are the identifiers). The **body is the source of
truth**; the index's `Status:` and `Steps: <done>/<total>` are derived from it
and can be rebuilt by re-reading it. No `chosko-llm` subcommand walks
`.claude/runbooks/` — runbooks are input to agents, never to tooling.

**The execution loop.** `/runbook-run` re-reads the body at the start of *every*
step — which is what reconciles a hand-edited body and what makes steps appended
mid-run get picked up by the run already in progress — selects the first step
whose dependencies are all done, marks it `[~]`, spawns **one** subagent with a
fixed prompt (a preamble telling it to orient from `CLAUDE.md`, the companion
document, the runbook's `## Do not re-propose` section, the step's `Context:`
bullets, the prompt block verbatim, then the operating rules), and then waits.
It ticks nothing before that agent's result actually arrives. On `DONE` it
writes a `Done:` line recording the commit sha, the decisions taken and any
premise that proved wrong, then commits the runbook and the index — one commit
per completed step, and the `[~]` marker is never committed, so finding one in
your tree is the signal that this is the tree an interrupted run left behind.

Three things it deliberately does not do. It **never runs steps in parallel**,
even where the runbook says they're independent: you get one question stream
instead of interleaved clarifications from three agents, and two agents writing
`Done:` lines into one file would race. It **does the work of no step itself** —
it writes exactly two files, the runbook and the index, and every other change in
the tree comes from a subagent. And it **doesn't review** what a step did: it
reads two markers, `QUESTIONS FOR USER` and `DONE`, and takes the report at its
word. Review is `/task-review`'s job, invoked from inside a step's prompt when
you want it.

**The question relay** is what keeps you in the loop without keeping you in the
session. A subagent can't talk to you, so it stops at any question or approval
gate and ends its turn; the orchestrator renders it as a fixed block — the
question, the options with what each costs, a recommendation — and relays your
answer back to the *same* agent, whose context is still intact. It compresses,
it never answers for you, and at an approval gate the full draft is shown
unabridged, since a summarized draft can't be approved. When a step's report
changes a fact a later step relies on, the orchestrator appends a dated bullet
to that step's `Context:`; the prompt block itself is never edited, so you can
always see what was originally asked and what was learned since, separately.

**Writing prompts that survive a fresh session** is the hard part, and it's the
authoring side that enforces it. `/runbook-create` checks nine rules before it
writes: each step is self-contained, names the document to read first (or
carries its evidence inline), carries every decision that exists nowhere on disk
*and nothing that already does*, states its sequencing and why, states what must
not be re-proposed, uses real slash commands in their real argument form,
references no path that won't exist at run time (nothing under `docs/`, which is
never installed), produces one deliverable, and never invokes `/runbook-run` —
nested runbooks are forbidden at both authoring and spawn time. Rule three is
why one-line prompts are the expected case rather than a shortcut:
`/task-implement 134` is complete, because the task body already carries the
decisions and `/task-implement` reads it.

Commit behaviour follows each command's family: `/runbook-create` is an
authoring command and leaves the runbook uncommitted for one review pass
(`--commit`, or `--commit --no-push`), `/runbook-clean` commits and pushes the
deletion by default (`--no-commit` / `--no-push`), `/runbook-run` commits after
every step, and `/runbook-list` and `runbook-suggest` write nothing at all.

A runbook is not a [session handoff](#hand-off-a-conversation--session-save-and-session-resume):
a session file is a snapshot of work in flight, a runbook is a plan for work not
yet done. It's not a backlog either — a task is a unit of work with acceptance
criteria, a runbook step is a prompt.

### Survive a cloud session — `hook:remote-session-protocol`

In a Claude Code cloud session, a question asked with the `AskUserQuestion`
tool can be re-asked while you're away from the keyboard, burning tokens and
occasionally leaving two agents doing the same work. This hook denies that tool
in cloud sessions and hands Claude a plain-text protocol instead: batch every
open question into one numbered message with lettered options and a
recommendation each, then end the turn and wait. Nothing polls, so a slow reply
costs nothing; and because the batch is one self-contained message, a session
picked back up later gets the questions and their answers as a whole.

```sh
chosko-llm add hook:remote-session-protocol --local
# paste the printed prompt into a Claude Code session to wire settings.json
git add .claude/hooks .claude/settings.json && git commit -m "Add remote session protocol"
```

**Install it `--local` and commit both halves.** A cloud container clones your
repo and nothing else, so only the project's own committed `.claude/` arrives —
which is why hooks are local-only. `add` prints a prompt for a Claude Code
session to merge the wiring into `.claude/settings.json`; this CLI never edits
that file itself. Claude Code reads hook config at session start, so restart
the session (or start a fresh cloud one) before expecting it to fire.

Detection is positive-only, and the shell does it rather than the model: the
hook engages when `CLAUDE_CODE_REMOTE` is `true` or
`CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE` is non-empty, and prints nothing at all
otherwise, so local sessions keep the normal question UI untouched. Those
variable names are not a public API, so if they change the hook quietly stops
firing rather than blocking the tool everywhere — edit the script when that
happens.

Because it is a hook rather than a `CLAUDE.md` section, it costs zero tokens in
every session where it doesn't fire.

---

## Development

This section is for contributors and authors working on the repo itself.

### Developer install

Clone the repo and run the installer from your working copy — it derives the origin URL from the local git remote:

```sh
git clone https://github.com/Chosko/chosko-llm.git chosko-llm
cd chosko-llm
./install.sh
```

### Authoring features

- New command → single `.md` file under `commands/`. See [docs/authoring-guide.md](docs/authoring-guide.md#commands).
- New skill → folder with a `SKILL.md` under `skills/`. See [docs/authoring-guide.md](docs/authoring-guide.md#skills).

Every feature requires YAML frontmatter (`name`, `version`, `type`, `description`). `add` and `update` refuse to install a file missing a `version` field. Three keys are optional: `replaces: <kind>:<name>` on a feature that changed kind, `requires: <kind>:<name>[, …]` on a feature whose body reads a file inside another installed feature, and the hook-only `event:` (required there) / `matcher:` pair.

**Versioning.** There are two version axes. The per-feature `version:` frontmatter versions a single command or skill (and gates `add` / `update`). The root `VERSION` file is the repo-level stamp that `install.sh` reports — bump it on every shipped change: patch for fixes and docs, minor for a new feature, major for a breaking CLI change. A feature change bumps both. One narrow exception: the repo-local skills under this repo's own `.claude/skills/` are unversioned development tooling installed nowhere, so a change confined to them bumps neither axis — bumping for a file no user receives would corrupt the meaning of the version `install.sh` reports.

A `VERSION` bump without a matching `CHANGELOG.md` section is an incomplete change; conversely, a change that does not bump `VERSION` gets no changelog entry. Run [`./scripts/check-changelog.sh`](scripts/check-changelog.sh) after bumping — it is silent when the top section matches `VERSION`, has at least one bullet, and the version headers are strictly descending semver, and fails naming the first violation otherwise.

### Repo layout

| Path                         | Purpose                                                                  |
| ---------------------------- | ------------------------------------------------------------------------ |
| `install.sh` / `uninstall.sh` | Bootstrap the managed clone and `~/bin` proxy / tear them down.          |
| `VERSION`                    | Repo-level version stamp, bumped on every shipped change (see below).     |
| `CHANGELOG.md`               | User-facing changes per `VERSION`, newest first. Read by `upgrade` to print what a pull changed. |
| `bin/chosko-llm`             | Proxy script copied to `~/bin/chosko-llm` by `install.sh`.               |
| `bin/chosko-llm.cmd`         | Windows batch shim copied alongside the proxy on Windows.                |
| `scripts/lib.sh`             | Shared shell helpers (logging, frontmatter, path resolution).            |
| `scripts/cmd-*.sh`           | One file per CLI subcommand. The proxy delegates here.                   |
| `scripts/check-changelog.sh` | Authoring-time guard: fails when a `VERSION` bump has no matching `CHANGELOG.md` section. Not a subcommand — run it by hand. |
| `commands/<name>.md`         | A Claude Code command. Frontmatter required.                             |
| `skills/<name>/SKILL.md`     | A Claude Code skill. Frontmatter required.                               |
| `claude-md/<name>.md`        | A CLAUDE.md snippet feature, merged into the user's CLAUDE.md.           |
| `statusline/<name>.sh`       | A status-line script feature, installed to `~/.claude/statusline/`.      |
| `hooks/<name>.sh`            | A hook-event script feature, installed to a project's `.claude/hooks/` (local-only). |
| `.claude/context/`           | Navigation context layer (`INDEX.md` + per-source files) for this repo.  |
| `.claude/domain/`            | Domain workflow docs (task, context, refactor) referenced by `CLAUDE.md`. |
| `.claude/skills/`            | Repo-local audit skills used to develop this repo (`/context-budget`, `/rule-overlap`). Unversioned, never installed — not features. |
| `.claude/TASKS.md` / `.claude/tasks/` | This repo's own task backlog and per-task body files.           |
| `docs/authoring-guide.md`    | How to write a new feature of any kind.                                  |
| `docs/cli-help.txt`          | Help text rendered by `chosko-llm help`.                                 |
