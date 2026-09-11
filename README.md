# chosko-llm

An opinionated, document-driven workflow for building software with Claude
Code, and the CLI that installs it anywhere.

Claude Code is very good at the next step and forgetful about everything
before it. This repo is a set of **commands and skills** that give a project
enough written structure that Claude can pick up any stage cold: a domain
layer that records what the product is and why, a navigation layer that
records where things live, a backlog of tasks small enough to build in one
sitting, and handoff documents for the work in between. You decide and
approve; Claude designs, plans, implements and reviews inside that structure.

Three principles run through all of it:

- **Documents, not conversations.** Every stage writes its output into the
  repo, so the work survives sessions, machines and people.
- **Stages are entered, not marched through.** Nothing downstream requires
  that an upstream stage was ever run. Start wherever your project is.
- **You decide, Claude executes.** Every writing feature stops at an approval
  gate before it changes anything that matters, and the states that mean
  "finished" are confirmed by a human, never inferred.

Everything is opt-in and installs with one command. The full flag-by-flag
detail for every feature lives in [docs/reference.md](docs/reference.md);
this page is the tour.

## Quick start

```sh
# install the CLI (clones a managed copy to ~/.chosko-llm, proxy at ~/bin/chosko-llm)
curl -fsSL https://raw.githubusercontent.com/Chosko/chosko-llm/master/install.sh | bash

chosko-llm ls --available      # see what ships
chosko-llm add --all           # or pick: chosko-llm add task-add task-implement context-build

# then, inside Claude Code, in a project:
/project-setup                 # CLAUDE.md, backlog, domain and context layers, in one pass
/task-add "add a health endpoint"
/task-implement next
```

`chosko-llm upgrade && chosko-llm update --all` picks up new versions. On
Windows, run the installer from Git Bash. See [The CLI](#the-cli) below.

## How a project flows through it

| Stage | You run | It writes |
| --- | --- | --- |
| 1. Set up | `/project-setup`, `/task-setup`, `/domain-setup` | `CLAUDE.md`, `.claude/TASKS.md`, `.claude/domain/`, `.claude/FEATURES.md` |
| 2. Orient | `/context-build`, `/context-update`, `/context-convert` | `.claude/context/` — the navigation layer |
| 3. Design | `/product-design`, `/product-roadmap`, `/architect` | `product-design.md`, `technical-direction.md`, `product-roadmap.md`, one feature document per architected feature |
| 4. Plan | `/production-plan`, `/production-status`, `/pipeline-check`, `/task-add` | `.claude/PLAN.md`, task bodies + `TASKS.md` entries |
| 5. Build | `/task-implement`, `/task-review`, `/task-iterate` | code, one reviewed commit per task |
| 6. Continue | `/runbook-*`, `/session-save`, `/session-resume` | `.claude/runbooks/`, `.claude/sessions/` |
| 7. Maintain | `/refactor-codebase`, `/refactor-tests` | a cleaner codebase, tests green throughout |

Two realistic starting points:

- **A brand new product.** `/project-setup`, then `/product-design` to work
  out what you're building, `/architect` per feature, `/task-add
  feature=<slug>`, `/task-implement`.
- **An existing codebase.** `/project-setup` with the context layer, then go
  straight to `/architect` (it reads your code and accepts a bare
  description), or skip design entirely and use plain `/task-add
  <description>`. The free-form path is unchanged by any of the pipeline.

## What it leaves in your repo

Every stage writes into the project's own `.claude/` directory, beside a
root `CLAUDE.md` that points at it. Nothing lives in your home directory
except the installed features themselves. A fully set-up project looks like
this; every entry is optional and appears only when its stage has run.

```
CLAUDE.md                        # entry point every session reads first: pointers to the
                                 # layers below, testing policy, VCS notes
.claude/
├── context/                     # NAVIGATION — where things are in the code
│   ├── INDEX.md                 #   one row per context file; `Layout: flat|nested`
│   └── <area>.md                #   six-section summary of one source area
├── domain/                      # KNOWLEDGE — what the product is and why
│   ├── INDEX.md                 #   index of the documents below
│   ├── product-design.md        #   what it is, for whom, key flows, decisions, high-level features
│   ├── technical-direction.md   #   stack, topology, data, hosting for the whole product
│   ├── business-model.md        #   optional
│   ├── design-process.md        #   /product-design's resume state
│   ├── product-roadmap.md       #   ordered milestones + the scope slices they take on
│   └── features/<slug>.md       #   one low-level feature document per architected feature
├── FEATURES.md                  # WORK — index of architected features: status, source, tasks
├── PLAN.md                      #   which feature in which milestone, in what order, after what
├── TASKS.md                     #   index of tasks: status, target, files, preconditions, feature
├── tasks/<n>.md                 #   one task body each: goal, acceptance criteria, hints
├── external/                    #   run-affected-tests.sh, run-full-tests.sh — the test dispatch
├── RUNBOOKS.md + runbooks/      #   ordered prompt lists for work not yet done
├── sessions/                    #   handoff snapshots of work in flight
└── hooks/ + settings.json       #   local hooks (e.g. remote-session-protocol), committed
```

Three kinds of document, three jobs:

- **Navigation** (`CLAUDE.md`, `.claude/context/`) answers *where is what*.
  Built from the code by `/context-build`, refreshed by `/context-update`,
  read at the start of every session so Claude opens only the files it
  needs. It describes the code; it never decides anything.
- **Knowledge** (`.claude/domain/`) answers *what is this and why*. Written
  by the design stage (`/product-design`, `/product-roadmap`, `/architect`)
  through interviews with you, read by everything downstream. It changes
  when the product changes, not when the code does.
- **Work** (`FEATURES.md`, `PLAN.md`, `TASKS.md` and their bodies, runbooks,
  sessions) answers *what is done, what is next*. Written and updated by the
  planning and build commands as work moves. These are the only documents
  with status.

### The production hierarchy

The design and work documents form one chain from the broadest statement of
intent to the smallest unit of work. Each level is many-to-one with the
level above, and each link is a named field in the document, so the whole
chain can be walked in either direction by reading files.

```
product-design.md               a section per HIGH-LEVEL FEATURE, from the user's side
  │                             ("Authentication", "Billing")
  │  product-roadmap.md         MILESTONES in order, each with `Covers:` slices saying
  │  ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈       which share of a section it takes on ("email+password only")
  ▼
features/<slug>.md              one LOW-LEVEL FEATURE per architectural decision;
  indexed in FEATURES.md        `Source: product-design.md § Authentication (m1-mvp)`
  │                             links it up to its section and, if sliced, its milestone
  │  PLAN.md                    orders the low-level features inside each milestone and
  │  ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈       records the dependency edges between them
  ▼
tasks/<n>.md                    one TASK per unit of work, small enough for one sitting;
  indexed in TASKS.md           `Feature: <slug>` links it up, and the feature's
                                `Tasks: 31, 32, 33` entry in FEATURES.md links down
```

The two documents drawn to the side, the roadmap and the plan, don't hold
features or tasks of their own. They *arrange* the level they sit beside:
the roadmap decides how a high-level feature is split across releases (a
business call), the plan decides in what order the resulting low-level
features get built (an engineering call). Both are optional; without them
`/architect` designs whole sections and `PLAN.md` is simply absent.

Each level has its own status vocabulary, and they mean different things:

| Level | Lives in | Statuses | Means |
| --- | --- | --- | --- |
| High-level feature | `product-design.md` | none | intent; never tracked |
| Milestone (roadmap) | `product-roadmap.md` | none | intent; never tracked |
| Milestone (plan) | `PLAN.md` | `[PLANNED]` `[ACTIVE]` `[SHIPPED]` | delivery; at most one active, shipped never reopens |
| Low-level feature | `FEATURES.md` | `[NEW]` `[ITERATED]` `[PLANNED]` `[DONE]` | whether the **backlog matches the design**; `[DONE]` also means every task finished |
| Task | `TASKS.md` | `[MISSING]` `[STUBBED]` `[INCORRECT]` `[PARTIAL]` `[IN PROGRESS]` `[DONE]` `[SKIP]` `[STALE]` | whether the **work** is done; the first four are the implementable states, `[STALE]` means the design moved underneath it |

`[ITERATED]` is the one state that demands action (re-plan the feature's
tasks); `[DONE]` on a feature and `[SHIPPED]` on a milestone are the ones a
human always confirms. `/production-status` reads across all three work
indexes and tells you what to build next; `/task-list` groups the backlog by
milestone through the same links.

## 1. Set up a project

**`/project-setup`** is the one-pass wizard: it seeds `CLAUDE.md` from
whatever you paste, adds an optional `AGENTS.md` pointer, injects a VCS
section for non-git projects, and offers to run the backlog, domain and
context setups below. It gathers every choice up front and confirms once.

Behind it sit two narrower commands you can also run alone. **`/task-setup`**
creates the backlog (`.claude/TASKS.md`, `.claude/tasks/`) and the project's
test-dispatch scripts under `.claude/external/`, so `/task-implement` never
has to guess the test command. **`/domain-setup`** scaffolds
`.claude/domain/` with a `features/` folder, an index and the
`.claude/FEATURES.md` feature index, then stops. It never writes design
documents; those come from the design stage.

All three are authoring commands: uncommitted by default, `--commit` to
commit and push. [Details →](docs/reference.md#1-setting-up-a-project)

## 2. Keep Claude oriented

Two layers, two questions. The **context layer** under `.claude/context/`
answers *where is what*: small structured summaries, one per source area,
that let a session open only the files it needs. The **domain layer** under
`.claude/domain/` answers *what is this and why*: the product design, the
technical direction, one document per architected feature. `CLAUDE.md`
points at both, so every session starts by reading an index instead of the
tree.

- **`/context-build`** creates the context layer once. Flat by default (one
  `INDEX.md`, every context file beside it); `nested` builds a router index
  plus one leaf per unit for repos where a single index is itself an
  expensive read.
- **`/context-update`** refreshes only the parts the latest diffs touched,
  and commits. Run it after landing code.
- **`/context-convert`** moves an existing layer between flat and nested
  without rebuilding it, plan-first.

The domain layer is written by the design stage, not by a build command.
[Details →](docs/reference.md#2-keeping-claude-oriented)

## 3. Design the product

This is where the workflow is most opinionated. Design happens in three
documents that hand off to each other, and each command is resumable because
its state lives in the document it writes, not in the conversation.

**`/product-design`** brainstorms the product with you and writes
`product-design.md` (what it is, who it's for, the key flows, the decisions,
the high-level features from the user's side) and `technical-direction.md`
(stack, topology, data, hosting for the product as a whole). It works on an
existing codebase too: it opens with "here's what I see you've built; is this
still the intent?". Run it again weeks later and it picks up where it
stopped.

**`/product-roadmap`** writes `product-roadmap.md`: ordered milestones, each
with a goal, exit criteria, a rationale, and **scope slices** saying which
share of a high-level feature it takes on ("email and password only; no SSO").
No status, no dates, no estimates: it records intent, not progress.

**`/architect`** takes one high-level feature (or a bare description) and
decides how it will actually be built, writing a low-level feature document
under `.claude/domain/features/` and an entry in `FEATURES.md`. One product
feature often becomes several architectural ones. It stops at components,
data and contracts; no code, no file-by-file plans. On a roadmapped project
it architects one slice at a time, so every low-level feature belongs to
exactly one milestone.

At a genuine fork, `/product-design` and `/architect` can hand the decision
to **`claude-council`**, a vendored copy of
[TorpedoD/claude-council](https://github.com/TorpedoD/claude-council): five
thinking lenses, anonymous peer review, forced debate when consensus looks
too clean, and a verdict that keeps dissent intact. Entirely optional; when
it isn't installed the commands say nothing.

**The iterate loop.** Designs change after tasks exist. Re-run `/architect`
on a feature that already has tasks and it checks them first: if any is
`[IN PROGRESS]` it refuses outright; otherwise it asks, rewrites the
document, marks the unfinished tasks `[STALE]` and the feature `[ITERATED]`.
Nothing is deleted. `/task-add feature=<slug>` then reconciles each stale
task, and `[DONE]` tasks are never touched. For a targeted change rather
than a redesign, `/architect amend feature=<slug> "<change>"` edits only the
sections the change names and marks `[STALE]` only the tasks the change
touches, judged from each task's title and `Files:` line. An `[IN PROGRESS]`
task blocks it only when the change touches that task, and it asks every
time whether the change is editorial; if it is, nothing is staled. What each
status means at each level is in
[the production hierarchy](#the-production-hierarchy) above.

All four are authoring features: uncommitted by default, `--commit` to
commit and push. [Details →](docs/reference.md#3-designing-the-product)

## 4. Plan the work

**`/production-plan`** writes `.claude/PLAN.md`: which architected feature
belongs to which milestone, in what order, and after what. The order *is*
the priority; there is no P0/P1 label, no size, no date, because a second
ordering would eventually contradict the first. Dependency edges are
proposed from the feature documents' prose and confirmed by you, and the
skill refuses the two arrangements that cannot be built: a cycle, and a
feature scheduled before something it needs.

**`/production-status`** is the read side. It joins `PLAN.md`,
`FEATURES.md` and `TASKS.md` on every run and tells you the active
milestone, what's ready, what's blocked and by what, and the single
recommended next feature. It writes nothing and stores nothing; a plan that
has fallen behind shows up as gaps, not as a date.

**`/pipeline-check`** reports drift between those indexes and
`RUNBOOKS.md`: a task whose `Feature:` names no feature, or that has no
`Feature:` line on a project that keeps a feature index; a precondition
pointing at a task that was never assigned or at a `[SKIP]` one; a
precondition cycle; an `[ITERATED]` feature or a `[STALE]` task still waiting
to be re-planned; a feature missing from the plan, or a plan line naming one
that doesn't exist; a finished runbook still marked `[PENDING]`; and a
`[PLANNED]` feature whose tasks have all resolved. Each finding carries an
`ERROR` or `WARNING` severity and the one command that fixes it, and a clean
project prints a single line. It fixes nothing: it writes nothing, and every
fix stays with the command that owns the line. `feature=<slug>` narrows the
report to one feature and the tasks and plan lines that name it. Its
catalogue lives in the **`pipeline-engine`** skill, which installs alongside
it.

**`/task-add`** turns intent into tasks. Give it a short description and it
investigates the codebase, asks every question needed to fill the gaps, and
writes a task body with acceptance criteria you approve before anything is
saved. This is the heart of the workflow: spend the focus in planning, then
let the agent consume the tasks whenever it's convenient. With
`feature=<slug>` it plans from an `/architect` document instead, so a
feature becomes several tasks without re-explaining the work. New tasks go
at the end of the backlog unless you say otherwise: `--before <N>` /
`--after <N>` write the task at that spot together with the
`Preconditions:` edge the position implies, so a task found mid-feature runs
when it should rather than last, and `feature=<slug> --single` attaches one
task to an already-planned feature without re-planning it. When part of
a task only a human can do (an editor step, a cloud console) it records the
checkpoints and marks the task human-in-the-loop.

`/production-plan` is uncommitted by default; `/task-add` commits and
pushes; `/production-status` and `/pipeline-check` write nothing. [Details →](docs/reference.md#4-planning-the-work)

## 5. Build and review

**`/task-implement`** builds a task end-to-end, test-first, and lands it as
exactly one commit. `next` takes the first eligible task and follows
`Preconditions:`, so a task is picked only once everything it waits on is
done; `all` works through the backlog in that same order. Both skip stale
tasks so a batch run never guesses, and
a multi-task run can hand each task to a fresh subagent so later tasks don't
inherit earlier ones' context. On a human-in-the-loop task it pauses at each checkpoint,
walks you through it, and verifies the outcome itself before moving on. On a
Unity project set up with `/unity-mcp-setup` it can drive the editor over
MCP instead and hand you a verification step in place of an instruction.

Pass **`--review`** and each task is peer-reviewed before it's committed.
**`/task-review`** audits the diff against the task's acceptance criteria in
a fresh subagent and reports only findings it holds at 80% confidence or
better, each with a `file:line` and a concrete failure mode; it never runs
the tests and never edits. **`/task-iterate`** triages those findings: every
one gets exactly one of `fix`, `defer` or `reject`, written down before the
first edit, and rejections travel into the next round so a finding can't
simply be re-raised. The fixes ride in the task's own single commit. Reviewer
cost is tiered automatically from the size of the diff; `--rounds N` loops
it.

Around them, **`/task-list`** shows the backlog (grouped by milestone when a
plan exists, with blocked features flagged) and **`/task-clean`** prunes
finished tasks. The rules they all share live once, in the **`task-engine`**
skill, which installs automatically alongside the commands that read it.

The build commands commit and push by default (`--no-commit`, `--no-push`).
[Details →](docs/reference.md#5-building-and-reviewing)

## 6. Work across sessions

Three features solve one problem: a conversation ends and its context dies
with it.

**Runbooks** are for work not yet done. A design conversation ends with
seven follow-up prompts; run them in one long session and step six drifts
from step one's framing. **`/runbook-create`** captures them as an ordered
list of self-contained prompts, each written for a fresh agent that has none
of the conversation, and checks ten rules before it writes (self-contained,
names its document, carries every decision that exists nowhere on disk and
nothing that already does). **`/runbook-run`** executes it one step at a
time, one subagent per step, relaying each agent's questions to you and your
answers back, committing after every step. It never runs steps in parallel,
never does a step's work itself, and never reviews what a step did; that is
`/task-review`'s job, invoked from inside the step. `/runbook-list`,
`/runbook-describe` and `/runbook-clean` round out the set, and
`runbook-suggest` fires on its own when a conversation produces a list worth
capturing.

**Session handoffs** are for work in flight. **`/session-save`** writes what
this conversation knows into `.claude/sessions/`: what was tried and failed,
what was deliberately not tried, which files are half-finished, the exact
next step. Nine sections, every one written even when it's `N/A`.
**`/session-resume`** briefs a new conversation from that file, flags it if
stale, and **stops**; it takes no step of the plan it just described. A
handoff is deleted by finishing the work, not by a flag.

**`hook:remote-session-protocol`** is for cloud sessions, where a question
asked through the `AskUserQuestion` tool can be re-asked while nobody is at
the keyboard. The hook denies the tool there and has Claude batch every open
question into one numbered message instead, then end its turn. Install it
`--local` and commit it; it costs nothing in sessions where it doesn't fire.

[Details →](docs/reference.md#6-working-across-sessions)

## 7. Keep the codebase healthy

**`/refactor-codebase`** (constants, duplication, oversized files, imports,
naming) and **`/refactor-tests`** (split bloated test files) do
behaviour-preserving cleanup under a safety net: plan first, get approval,
proceed phase by phase, run the suite between phases, halt on the first
failure. Uncommitted by default.
[Details →](docs/reference.md#7-keeping-the-codebase-healthy)

## 8. Editor and shell extras

- **`/unity-mcp-setup`** wires a Unity project for MCP so `/task-implement`
  can drive the editor itself; **`unity-mcp-skill`** is the operator guide
  Claude leans on while doing so.
- **`claude-md:git-commit-style`** and **`claude-md:tool-usage-policy`**
  inject a managed section into `CLAUDE.md` (global, or a project's with
  `--local`): scannable commit messages with trailers only on big commits,
  and built-in file tools over shell commands.
- **`statusline:session-statusline`** shows model, directory, branch,
  context usage, cost and rate limits in the status bar. Global-only.

[Details →](docs/reference.md#8-editor-and-shell-extras)

## The CLI

The CLI is deliberately small: a managed clone at `~/.chosko-llm/`, a proxy
at `~/bin/chosko-llm`, and copy-not-symlink installs into `~/.claude/`. The
filesystem is the only state; there is no lockfile.

```sh
chosko-llm ls                     # every feature: installed vs available version
chosko-llm show <feature>         # inspect one (--diff --content previews an update)
chosko-llm add <feature> ...      # install (pulls in anything it requires:)
chosko-llm add --all              # install everything
chosko-llm rm <feature>           # remove (refuses while something still requires it)
chosko-llm upgrade                # pull the latest source; prints the changelog for what moved
chosko-llm update --all           # re-copy every installed feature from that source
chosko-llm changelog --since 30d  # read the changelog from a version, date or duration
chosko-llm channel <branch>       # point the clone at a branch to try unmerged work
chosko-llm export [--archive]     # package a repo's Claude config for a Project or a chat
chosko-llm uninstall              # tear it all down, prompting at each step
```

**Five feature kinds.** Commands and skills copy into `~/.claude/`; claude-md
snippets inject a managed section into `CLAUDE.md`; statusline scripts are
global-only; hooks are local-only. A bare name matches any kind, and
`kind:<name>` disambiguates.

**Per-repository installs.** Every verb takes `--local` to target
`<cwd>/.claude` instead of your home, so a cloud agent that can't run the
installer still gets the commands the project needs.

**Staying current.** The first command you run each day quietly runs
`upgrade`; `update --all` remains an explicit step. `upgrade
--disable-auto` opts out. Feature names, dependencies between features,
Windows notes and every environment variable are in the reference.

[Details →](docs/reference.md#9-the-cli)

---

## Development

This section is for contributors and authors working on the repo itself.

### Developer install

Clone the repo and run the installer from your working copy; it derives the origin URL from the local git remote:

```sh
git clone https://github.com/Chosko/chosko-llm.git chosko-llm
cd chosko-llm
./install.sh
```

### Authoring features

- New command → single `.md` file under `commands/`. See [docs/authoring-guide.md](docs/authoring-guide.md#commands).
- New skill → folder with a `SKILL.md` under `skills/`. See [docs/authoring-guide.md](docs/authoring-guide.md#skills).

Every feature requires YAML frontmatter (`name`, `version`, `type`, `description`). `add` and `update` refuse to install a file missing a `version` field. Three keys are optional: `replaces: <kind>:<name>` on a feature that changed kind, `requires: <kind>:<name>[, …]` on a feature whose body reads a file inside another installed feature, and the hook-only `event:` (required there) / `matcher:` pair.

**Versioning.** There are two version axes. The per-feature `version:` frontmatter versions a single command or skill (and gates `add` / `update`). The root `VERSION` file is the repo-level stamp that `install.sh` reports: bump it on every shipped change, patch for fixes, minor for a new feature, major for a breaking CLI change. A feature change bumps both.

Two things do not bump it. **Project documentation** (`README.md`, `docs/`, `.claude/domain/`, `.claude/context/` and `CLAUDE.md` itself) changes nothing a user receives, so it bumps nothing and gets no changelog entry; a shipped feature's own body (`commands/*.md`, `skills/*/SKILL.md`, `claude-md/*.md`, `statusline/*.sh`, `hooks/*.sh`) is the product rather than documentation and bumps as always, markdown or not. And the repo-local skills under this repo's own `.claude/skills/` are unversioned development tooling installed nowhere, so a change confined to them bumps neither axis.

A `VERSION` bump without a matching `CHANGELOG.md` section is an incomplete change; conversely, a change that does not bump `VERSION` gets no changelog entry. Each entry is one line: a bold subject naming the command, subcommand or script that changed, then a short clause saying what a user would notice. Run [`./scripts/check-changelog.sh`](scripts/check-changelog.sh) after bumping. It is silent when the top section matches `VERSION`, has at least one bullet, and the version headers are strictly descending semver, and fails naming the first violation otherwise.

### Repo layout

| Path                         | Purpose                                                                  |
| ---------------------------- | ------------------------------------------------------------------------ |
| `install.sh` / `uninstall.sh` | Bootstrap the managed clone and `~/bin` proxy / tear them down.          |
| `VERSION`                    | Repo-level version stamp, bumped on every shipped change (see above).     |
| `CHANGELOG.md`               | User-facing changes per `VERSION`, newest first. Read by `upgrade` to print what a pull changed. |
| `bin/chosko-llm`             | Proxy script copied to `~/bin/chosko-llm` by `install.sh`.               |
| `bin/chosko-llm.cmd`         | Windows batch shim copied alongside the proxy on Windows.                |
| `scripts/lib.sh`             | Shared shell helpers (logging, frontmatter, path resolution).            |
| `scripts/cmd-*.sh`           | One file per CLI subcommand. The proxy delegates here.                   |
| `scripts/check-changelog.sh` | Authoring-time guard: fails when a `VERSION` bump has no matching `CHANGELOG.md` section. Not a subcommand; run it by hand. |
| `scripts/check-routing.sh`   | Authoring-time guard: fails when a row of the pipeline routing table (`skills/pipeline-engine/references/routing.md`) names no shipped feature, or a feature declaring `requires: skill:pipeline-engine` has no row. Not a subcommand; run it by hand. |
| `commands/<name>.md`         | A Claude Code command. Frontmatter required.                             |
| `skills/<name>/SKILL.md`     | A Claude Code skill. Frontmatter required.                               |
| `claude-md/<name>.md`        | A CLAUDE.md snippet feature, merged into the user's CLAUDE.md.           |
| `statusline/<name>.sh`       | A status-line script feature, installed to `~/.claude/statusline/`.      |
| `hooks/<name>.sh`            | A hook-event script feature, installed to a project's `.claude/hooks/` (local-only). |
| `.claude/context/`           | Navigation context layer (`INDEX.md` + per-source files) for this repo.  |
| `.claude/domain/`            | Domain workflow docs (task, context, refactor, product) referenced by `CLAUDE.md`. |
| `.claude/skills/`            | Repo-local audit skills used to develop this repo (`/context-budget`, `/rule-overlap`). Unversioned, never installed; not features. |
| `.claude/TASKS.md` / `.claude/tasks/` | This repo's own task backlog and per-task body files.           |
| `docs/reference.md`          | The complete feature and CLI reference this README links into.           |
| `docs/authoring-guide.md`    | How to write a new feature of any kind.                                  |
| `docs/cli-help.txt`          | Help text rendered by `chosko-llm help`.                                 |
