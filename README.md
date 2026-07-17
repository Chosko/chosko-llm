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

### Work through a backlog — the `task-*` commands

A lightweight, in-repo issue tracker. Work is captured as small, reviewable
tasks. The core idea is to spend more focus in planning and writing down tasks, then let the agent consume them automatically whenever it is convenient.

- `/task-setup` — initialize the backlog.
- `/task-add` — plan a task and write it down. This is the real strength of this workflow: invoke the command with a very short description, let Claude Code investigate and expand it, in a conversational way. Claude will ask every question needed to fill the gaps, then it will write everything down for further implementation. It may propose splitting the description into several tasks when that gives better units (independent deliverables, or one task that's too large) — pass `--no-split` to always get exactly one task.
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
