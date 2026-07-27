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
chosko-llm rm <feature>        # remove an installed feature
```

### Keeping up to date

```sh
chosko-llm upgrade             # pull the latest source from the repo
chosko-llm update --all        # re-copy all installed features from the updated source
chosko-llm update <feature>    # re-copy one feature
```

Run `upgrade` first, then `update --all` to pick up new versions. `upgrade` only refreshes the source; it does not touch installed features.

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

### [Experimental] Implementing tasks with a local LLM

`chosko-llm task-impl` drives a **local** LLM (aider + Ollama, `qwen2.5-coder:14b` by default) through a project's task backlog — the offline counterpart to the `/task-implement` slash command. Run it from the project root once the backlog is initialized (`/task-setup`) and tasks exist:

```sh
chosko-llm task-impl <N> [<N> ...]   # implement specific tasks, one commit each
chosko-llm task-impl all             # implement every pending task, in order
```

It follows the same test-first sequence — write failing tests, implement, watch them pass — and commits each task separately. Pass `--model` / `--retries` / `--map-tokens`, or see `chosko-llm task-impl --help`, to tune the run. See [Workflows](#workflows) for how this fits the rest of the task tooling.

### Feature names

A bare name like `refactor-codebase` matches commands, skills, and claude-md artifacts. If a name is ambiguous, disambiguate with `command:<name>`, `skill:<name>`, or `claude-md:<name>`.

claude-md artifacts are a third feature kind: rather than copying a standalone file, they inject a managed section into `~/.claude/CLAUDE.md`. The section is delimited by HTML comment markers, so your own CLAUDE.md content around it is preserved.

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

---

## Claude Code Workflows

These features add up to a few connected ways of working in a project. Install
them with `chosko-llm add <feature>` (opt-in), then run them as slash commands
(`/<name>`) inside Claude Code. File-writing commands leave output uncommitted
for review by default; override with `--commit` / `--no-commit`.

### The product pipeline — from idea to merged code

Five of these commands form one continuous pipeline. Each stage hands its
output to the next as a **document in the repo**, not as conversation, so the
work survives across sessions, machines, and people.

| Stage | Command | Consumes | Produces |
| --- | --- | --- | --- |
| 0 — scaffold | [`/domain-setup`](#set-up-the-domain-layer--domain-setup) | nothing | the domain layer + an empty `.claude/FEATURES.md` |
| 1 — design | [`/product-design`](#design-a-product--product-design) | you, and the repo when it already has code | `product-design.md`, optional `business-model.md`, `design-process.md` |
| 2 — architect | [`/architect`](#design-how-to-build-it--architect) | a high-level feature, or a bare prompt | `.claude/domain/features/<slug>.md` + a `FEATURES.md` entry |
| 3 — plan | `/task-add feature=<slug>` | a feature document | task bodies + `TASKS.md` entries |
| 4 — build | `/task-implement` | a task body | code, one commit per task |

Stages are **entered, not marched through**. Nothing downstream requires that
an upstream stage was ever run.

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
proposes four tasks, and on your approval writes tasks 31–34 — each carrying
`Feature: password-auth` — sets the entry to `Tasks: 31, 32, 33, 34` and
`Status: [PLANNED]`. `/task-implement 31` builds the first one and commits it.

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
   deleted. `/task-clean` won't prune it, `chosko-llm task-impl` refuses it,
   and `/task-implement` warns and lets you decide — `all` and `next` skip it.
5. `/task-add feature=password-auth` **reconciles**: each stale task is left
   alone, updated in place (back to `[MISSING]`), or skipped with a reason and
   replaced. `[DONE]` tasks are never touched. The feature returns to
   `[PLANNED]`.

Two vocabularies are at work and they mean different things. A **feature**
status (`[NEW]` / `[ITERATED]` / `[PLANNED]`) describes whether the backlog
matches the design — never whether the feature is built. A **task** status
(`[MISSING]` … `[DONE]`) describes the work itself. `[ITERATED]` is the one
state that demands action.

The sections below are the per-command reference.

### Start a project — `/project-setup`

One-pass setup for a new repo. Seeds `CLAUDE.md` from pasted material, adds an
optional `AGENTS.md` pointer, injects a VCS-mapping section for non-git
projects, and can kick off the task backlog and context layer. Gathers every
choice up front, confirms once, then executes.

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
Unity projects.

The repo also ships a `unity-mcp-skill` skill — a Unity-MCP operator guide
(resource-first workflow, tool categories, and reference files for tool
schemas and extended workflows) that Claude can lean on when driving the
editor over the `UnityMCP` server. Install it like any other feature with
`chosko-llm add skill:unity-mcp-skill`.

### Keep Claude oriented — `/context-build` and `/context-update`

Build a *navigation layer*: small structured summaries that let future Claude Code sessions
open only the source files they need, saving tokens.

- `/context-build` — create the layer once. (it can be invoked automatically by `/project-setup` if chosen when asked)
- `/context-update` — refresh only the parts the latest diffs touched.

### Clean up safely — `/refactor-codebase` and `/refactor-tests`

Behaviour-preserving cleanup under a safety net: plan first, get approval, then
proceed phase by phase, running the test suite between steps and halting on the
first failure.

- `/refactor-codebase` — constants, duplication, oversized files, imports, naming.
- `/refactor-tests` — split bloated test files.

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
replacing them.

### Design a product — `/product-design`

Brainstorm a product from the ground up with Claude and write the result into
the domain layer: what it is, who it's for, the key flows, the big decisions,
and the high-level feature set described from the user's side. A business
model is optional and opt-in. Requires `/domain-setup` to have run.

It works on an existing codebase as well as a blank one — it reads what's
there and opens with "here's what I see you've built; is this still the
intent?".

Designing a product takes more than one sitting, so the process is
**resumable**: its state lives in `.claude/domain/design-process.md`, not in
the conversation. Run `/product-design` again weeks later and it tells you
where the last session stopped and offers to pick up there. There's no flag
to remember.

The output is `/architect`'s input.

### Design how to build it — `/architect`

Takes a high-level feature and decides how it will actually be built, then
writes that down as a low-level feature document under
`.claude/domain/features/`, indexed in `.claude/FEATURES.md`. One product
feature often becomes several architectural ones.

It grounds the design in the code you already have (reading the context layer
first), and proposes a tech stack only when there isn't one. It stops at
components, data, and contracts — no code, no file-by-file plans. Those come
from `/task-add`, which reads the code as it stands at planning time.

You can run it from a `/product-design` feature, from a feature name, or from
a bare description with no design documents at all.

Re-architecting a feature that already produced tasks is guarded: if any of
those tasks is `[IN PROGRESS]` it refuses outright, and otherwise it asks
before marking the surviving tasks `[STALE]` and the feature `[ITERATED]` —
then tells you to reconcile with `/task-add feature=<slug>`.

### Work through a backlog — the `task-*` commands

A lightweight, in-repo issue tracker. Work is captured as small, reviewable
tasks. The core idea is to spend more focus in planning and writing down tasks, then let the agent consume them automatically whenever it is convenient.

- `/task-setup` — initialize the backlog.
- `/task-add` — plan a task and write it down. This is the real strength of this workflow: invoke the command with a very short description, let Claude Code investigate and expand it, in a conversational way. Claude will ask every question needed to fill the gaps, then it will write everything down for further implementation. It may propose splitting the description into several tasks when that gives better units (independent deliverables, or one task that's too large) — pass `--no-split` to always get exactly one task.
- `/task-add feature=<slug>` — plan from an `/architect` feature document instead of a description. The document is the input, so you don't re-explain the work in prose; a feature usually becomes several tasks. Run it again after re-architecting and it *reconciles* rather than duplicating: each existing task is either left alone, updated in place, or skipped with a reason and replaced — and `[DONE]` tasks are never touched. You approve the whole plan, reconciliation included, in one pass.
- `/task-list` — show what's pending.
- `/task-implement` — build a task end-to-end, test-first, one commit each.
- `/task-clean` — prune finished tasks.

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
or stop; `all` and `next` skip them so a batch run never guesses. The
`chosko-llm task-impl` CLI refuses them outright, since a local model can't
judge whether a superseded design still applies.

On a Unity project set up with [`/unity-mcp-setup`](#set-up-unity-mcp--unity-mcp-setup),
those checkpoints can flip around: when the `UnityMCP` server is connected,
`/task-implement` makes the editor changes itself — checking the Console
after compilation and creating GameObjects, components, and references via
MCP — then hands you a *verification* step ("I created Foo under Bar —
confirm you see it") instead of an instruction. It asks once per task
whether you want it to drive Unity or pause for you to do the steps
manually, and steps MCP genuinely can't perform stay manual. When the
server isn't connected, the standard manual protocol above runs unchanged.

#### [Experimental] Implement with a local model instead of Claude

`/task-enrich` expands a task into a self-contained brief; the `chosko-llm
task-impl` CLI then drives a **local** LLM (aider + Ollama, e.g.
`qwen2.5-coder`) through the same 8-step, test-first loop, committing each task
as it goes. The offline counterpart to `/task-implement` — the backlog runs
under Claude interactively or a local model in batch.

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

Every feature requires YAML frontmatter (`name`, `version`, `type`, `description`). `add` and `update` refuse to install a file missing a `version` field.

**Versioning.** There are two version axes. The per-feature `version:` frontmatter versions a single command or skill (and gates `add` / `update`). The root `VERSION` file is the repo-level stamp that `install.sh` reports — bump it on every shipped change: patch for fixes and docs, minor for a new feature, major for a breaking CLI change. A feature change bumps both.

### Repo layout

| Path                         | Purpose                                                                  |
| ---------------------------- | ------------------------------------------------------------------------ |
| `install.sh` / `uninstall.sh` | Bootstrap the managed clone and `~/bin` proxy / tear them down.          |
| `VERSION`                    | Repo-level version stamp, bumped on every shipped change (see below).     |
| `bin/chosko-llm`             | Proxy script copied to `~/bin/chosko-llm` by `install.sh`.               |
| `bin/chosko-llm.cmd`         | Windows batch shim copied alongside the proxy on Windows.                |
| `scripts/lib.sh`             | Shared shell helpers (logging, frontmatter, path resolution).            |
| `scripts/lib-task-external.sh` | Helpers for the external-LLM task workflow.                            |
| `scripts/cmd-*.sh`           | One file per CLI subcommand. The proxy delegates here.                   |
| `commands/<name>.md`         | A Claude Code command. Frontmatter required.                             |
| `skills/<name>/SKILL.md`     | A Claude Code skill. Frontmatter required.                               |
| `claude-md/<name>.md`        | A CLAUDE.md snippet feature, merged into the user's CLAUDE.md.           |
| `.claude/context/`           | Navigation context layer (`INDEX.md` + per-source files) for this repo.  |
| `.claude/domain/`            | Domain workflow docs (task, context, refactor) referenced by `CLAUDE.md`. |
| `.claude/TASKS.md` / `.claude/tasks/` | This repo's own task backlog and per-task body files.           |
| `docs/authoring-guide.md`    | How to write a new command or skill.                                     |
| `docs/cli-help.txt`          | Help text rendered by `chosko-llm help`.                                 |
