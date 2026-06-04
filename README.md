# chosko-llm

A development repo for global [Claude Code](https://claude.com/claude-code)
commands and skills, plus a small CLI (`chosko-llm`) that installs them into
`~/.claude/` on any machine. You author features here, push, and on each target
machine `chosko-llm upgrade` pulls the latest source and `chosko-llm add` /
`update` copies individual features into `~/.claude/`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Chosko/chosko-llm/master/install.sh | bash
```

The installer clones a managed copy of the repo to `~/.chosko-llm/` and drops
a CLI proxy at `~/bin/chosko-llm`.

If `~/bin` isn't on your `$PATH`, the installer will tell you how to add it.

`install.sh` does **not** install any features — features are opt-in.

### Developer install

If you have a working checkout, you can run the installer directly — it will
derive the origin URL from the local git remote:

```sh
git clone https://github.com/Chosko/chosko-llm.git chosko-llm
cd chosko-llm
./install.sh
```

### Windows (cmd.exe / PowerShell)

`install.sh` must be run from **Git Bash** (not cmd.exe or PowerShell).
On Windows it installs both the bash proxy (`chosko-llm`) and a thin batch
shim (`chosko-llm.cmd`). Once both are on your **Windows** PATH, you can run
`chosko-llm` from any shell — cmd.exe, PowerShell, and Git Bash all resolve
it via `PATHEXT`.

The installer prints the native Windows path you need to add. Add it via:
**System Properties → Advanced → Environment Variables → Path → Edit → New**.

**Known caveats:**

- **git-bash only.** The shim auto-detects Git for Windows' `bash.exe`. WSL
  users should run `chosko-llm` from inside WSL, where `~/.chosko-llm`
  resolves to the WSL home — the two filesystems are separate.
- **Muted interactive output.** Actionable suggestions after `ls` and colored
  output are gated on a TTY. cmd.exe and PowerShell do not allocate a PTY, so
  those features are suppressed when invoked through the shim.

## CLI

| Command                                | What it does                                                                |
| -------------------------------------- | --------------------------------------------------------------------------- |
| `chosko-llm ls`                        | List all features with installed and latest versions.                       |
| `chosko-llm ls --installed`            | Same table, filtered to features currently installed under `~/.claude/`.    |
| `chosko-llm ls --available`            | Same table, filtered to features present in the managed clone.              |
| `chosko-llm show <feature>`            | Inspect one feature: versions, status, description, path. `--content` prints its body; `--diff` compares installed vs latest. |
| `chosko-llm add <feature>`             | Copy a feature from the managed clone into `~/.claude/`.                    |
| `chosko-llm rm <feature>`              | Delete an installed feature from `~/.claude/`.                              |
| `chosko-llm update <feature>`          | Re-copy a feature from the managed clone (installs if missing).             |
| `chosko-llm update --all`              | Update every currently installed feature.                                   |
| `chosko-llm upgrade`                   | `git pull` the managed clone and refresh the CLI proxy.                     |
| `chosko-llm help`                      | Show usage.                                                                 |

A bare feature name like `refactor-reviewer` matches both commands and skills.
If a name is ambiguous, disambiguate with `command:<name>` or `skill:<name>`.

`upgrade` only refreshes the source repo; it does not touch installed features.
Run `chosko-llm update --all` afterwards to pick up new versions.

## Layout

| Path                       | Purpose                                                              |
| -------------------------- | -------------------------------------------------------------------- |
| `bin/chosko-llm`           | Proxy script copied to `~/bin/chosko-llm` by `install.sh`.           |
| `scripts/lib.sh`           | Shared shell helpers (logging, frontmatter, paths, validation).      |
| `scripts/cmd-*.sh`         | One file per CLI subcommand. The proxy delegates here.               |
| `commands/<name>.md`       | A Claude Code command. Frontmatter required (see authoring guide).   |
| `skills/<name>/SKILL.md`   | A Claude Code skill. Frontmatter required.                           |
| `docs/authoring-guide.md`  | How to write a new command or skill.                                 |
| `tests/smoke/`             | Manual smoke-test checklists, one file per feature.                  |

## Authoring

- New command → see [docs/authoring-guide.md](docs/authoring-guide.md#commands).
- New skill   → see [docs/authoring-guide.md](docs/authoring-guide.md#skills).

Every feature requires YAML frontmatter (`name`, `version`, `type`,
`description`). `add` and `update` refuse to install a feature without a
`version` field, so the CLI always knows what's on disk.

## Uninstall

```sh
./uninstall.sh
```

It will:

1. Remove the CLI proxy at `~/bin/chosko-llm`.
2. Optionally delete every feature under `~/.claude/` whose name matches a
   feature in the managed clone (so user-authored files are left alone).
3. Optionally remove the managed clone at `~/.chosko-llm/`.

## Configuration

| Env var           | Default          | Notes                                                |
| ----------------- | ---------------- | ---------------------------------------------------- |
| `CHOSKO_LLM_HOME` | `~/.chosko-llm`  | Managed clone location.                              |
| `CLAUDE_HOME`     | `~/.claude`      | Where features get installed.                        |
| `BIN_DIR`         | `~/bin`          | Where the CLI proxy lives. Used by `install.sh`.     |
| `NO_COLOR`        | unset            | Set to disable colored log output.                   |
