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

#### Daily auto-upgrade

The first `chosko-llm` command you run each day quietly runs `chosko-llm upgrade` for you before doing its job, so the source stays current without you thinking about it. You're opted in at install time; it runs at most once per calendar day and never blocks your command if the pull fails.

```sh
chosko-llm upgrade --disable-auto   # opt out of the daily auto-upgrade
chosko-llm upgrade --enable-auto    # opt back in
```

These flags only change the preference — they don't perform an upgrade. The opt-in/opt-out state and the last-run date live in a gitignored file in the managed clone (`~/.chosko-llm/.auto-upgrade-state`). Set `CHOSKO_LLM_NO_AUTO_UPGRADE` to skip the automatic run entirely (handy in CI or scripts).

### Disambiguation

A bare name like `refactor-codebase` resolves to whichever kind exists (command or skill). If a name is ambiguous, prefix it: `command:<name>` or `skill:<name>`.

## Uninstall

```sh
./uninstall.sh
```

Prompts before each destructive step:

1. Remove the CLI proxy at `~/bin/chosko-llm` (and `chosko-llm.cmd` on Windows).
2. Optionally delete every installed feature under `~/.claude/` that matches a feature in the managed clone (user-authored files are left alone).
3. Optionally remove the managed clone at `~/.chosko-llm/`.

## Configuration

| Env var           | Default         | Purpose                                              |
| ----------------- | --------------- | ---------------------------------------------------- |
| `CHOSKO_LLM_HOME` | `~/.chosko-llm` | Managed clone location.                              |
| `CLAUDE_HOME`     | `~/.claude`     | Where features get installed.                        |
| `BIN_DIR`         | `~/bin`         | Where the CLI proxy lives. Used by `install.sh`.     |
| `NO_COLOR`        | unset           | Set to any value to disable colored output.          |
| `CHOSKO_LLM_NO_AUTO_UPGRADE` | unset | Set to any value to skip the daily auto-upgrade.     |

---

## Workflows

The features this CLI installs aren't isolated tricks — they add up to a few
connected ways of working inside a project. You install them with
`chosko-llm add <feature>` (they're opt-in), then invoke them as slash
commands (`/<name>`) inside Claude Code. Most commands that write files leave
their output uncommitted for you to review; the few that commit do so on their
own. You can override either default with `--commit` / `--no-commit`.

**Start a project — `/project-setup`.** When you first bring a repo under this
tooling, `/project-setup` walks you through it in one pass: it seeds a
`CLAUDE.md` from material you paste, optionally adds an `AGENTS.md` pointer,
injects a VCS-mapping section for non-git projects, and can kick off the task
backlog and the context layer for you. It asks everything up front, confirms
once, then executes — so you're set up without running each piece by hand.

**Keep Claude oriented — `/context-build` and `/context-update`.** These build
a *navigation layer*: small, structured summaries of your codebase that let
future sessions decide which source files to actually open instead of reading
everything up front, which saves tokens and time. Run `/context-build` once to
create the layer; run `/context-update` after changes to refresh only the
parts the diffs touched.

**Clean up safely — `/refactor-codebase` and `/refactor-tests`.** This is
behaviour-preserving cleanup under a safety net: it plans the work and asks for
approval first, then proceeds phase by phase with the test suite run between
each step, stopping the moment anything goes red. `/refactor-codebase` handles
constants, duplication, oversized files, imports, and naming;
`/refactor-tests` focuses on splitting bloated test files.

**Work through a backlog — the `task-*` commands.** This is a lightweight,
LLM-friendly issue tracker that lives in the repo. `/task-setup` initializes
it; `/task-add` plans a task conversationally and writes it down; `/task-list`
shows what's pending; `/task-implement` builds tasks end-to-end with a
test-first sequence, committing each separately; and `/task-clean` prunes
finished ones. `/task-enrich` expands a task into a self-contained brief you
can hand to a local LLM. The idea is to capture work as small, reviewable
units and let the tooling drive each one to completion.

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

### Repo layout

| Path                      | Purpose                                                             |
| ------------------------- | ------------------------------------------------------------------- |
| `bin/chosko-llm`          | Proxy script copied to `~/bin/chosko-llm` by `install.sh`.         |
| `bin/chosko-llm.cmd`      | Windows batch shim copied alongside the proxy on Windows.           |
| `scripts/lib.sh`          | Shared shell helpers (logging, frontmatter, path resolution).       |
| `scripts/cmd-*.sh`        | One file per CLI subcommand. The proxy delegates here.              |
| `commands/<name>.md`      | A Claude Code command. Frontmatter required.                        |
| `skills/<name>/SKILL.md`  | A Claude Code skill. Frontmatter required.                          |
| `docs/authoring-guide.md` | How to write a new command or skill.                                |
| `tests/smoke/`            | Manual smoke-test checklists, one file per feature.                 |
