# chosko-llm

A development repo for global [Claude Code](https://claude.com/claude-code)
commands and skills, plus a small CLI (`chosko-llm`) that installs them into
`~/.claude/` on any machine. You author features here, push, and on each target
machine `chosko-llm upgrade` pulls the latest source and `chosko-llm add` /
`update` copies individual features into `~/.claude/`.

## Install

Clone the repo somewhere and run the bootstrap. It clones a managed copy to
`~/.chosko-llm/` and drops a CLI proxy at `~/bin/chosko-llm`.

```sh
git clone <this-repo-url> chosko-llm
cd chosko-llm
./install.sh
```

If `~/bin` isn't on your `$PATH`, the installer will tell you how to add it.

`install.sh` does **not** install any features — features are opt-in.

## CLI

| Command                                | What it does                                                                |
| -------------------------------------- | --------------------------------------------------------------------------- |
| `chosko-llm ls`                        | Alias for `ls --installed`.                                                 |
| `chosko-llm ls --installed`            | List features in `~/.claude/{commands,skills}` with their installed version.|
| `chosko-llm ls --available`            | List features in the managed clone that are new or upgradable.              |
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
| `scripts/lib.sh`           | Shared shell helpers (logging, frontmatter, paths, semver).          |
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
