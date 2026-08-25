# CLI entry & bootstrap

## Overview

CLI split four pieces:

- `install.sh` — first bootstrap. Clone repo into **managed clone** at `$CHOSKO_LLM_HOME` (default `~/.chosko-llm`) — from local working copy's `origin` when run from checkout, or `REPO_URL` (default GitHub) when run via `curl | bash` — copy `bin/chosko-llm` to `$BIN_DIR/chosko-llm` (default `~/bin`). Windows (MINGW/MSYS/Cygwin): also copy `bin/chosko-llm.cmd` into `$BIN_DIR`.
- `bin/chosko-llm` — thin proxy. Read subcommand, exec matching `scripts/cmd-<sub>.sh` from managed clone. Before dispatch, invoke `scripts/auto-upgrade.sh` (guarded, `|| true`) for daily auto-upgrade.
- `scripts/auto-upgrade.sh` — daily auto-upgrade hook. Source `lib.sh`; when user opted in and not run today, run `chosko-llm upgrade` once before requested command. Never abort command (every exit non-fatal).
- `bin/chosko-llm.cmd` — Windows-only batch shim. Detected via `PATHEXT` by cmd.exe/PowerShell. Auto-detect git-bash (`%ProgramFiles%\Git\bin\bash.exe` + two other standard locations, then `where bash`), forward all args to `%~dp0chosko-llm` (sibling bash proxy). Propagate exit code with `exit /b %ERRORLEVEL%`. No dispatch logic.
- `uninstall.sh` — remove proxy, optionally delete installed features from `$CLAUDE_HOME` (matched against managed clone), optionally delete managed clone itself. Reachable as `chosko-llm uninstall` via thin `scripts/cmd-uninstall.sh` wrapper, or standalone. Gated by up-front confirmation before any removal; `-y`/`--yes` auto-confirms.

Proxy reads from managed clone, not working repo. Edits in working repo reach users via `git push` → `chosko-llm upgrade` (runs `git pull` in managed clone). See [cmd-upgrade.md](./cmd-upgrade.md).

## Public API (CLI surface)

Proxy at `bin/chosko-llm` accepts these subcommands, forwards `$@`:
- `ls`, `add`, `rm`, `update`, `upgrade`, `channel`, `show`, `uninstall`, `export` → `scripts/cmd-<sub>.sh`. `cmd-uninstall.sh` thin wrapper execs repo-root `uninstall.sh` (single teardown implementation). `channel` points managed clone at branch to try unmerged work (see [cmd-channel.md](./cmd-channel.md)). `export` packages target repo's Claude config into Markdown or zip hand-off artifact (see [cmd-export.md](./cmd-export.md)).
- `-v`, `--version`, `version` → `scripts/cmd-version.sh` (falls back to `cat`-ing `VERSION` file if script missing). Prints string from `resolve_version` in `lib.sh` — same format install.sh reports.
- `""`, `-h`, `--help`, `help` → `scripts/cmd-help.sh` (falls back to `docs/cli-help.txt` if script missing).
- Anything else → exit code 2.
- Before dispatching above, proxy runs daily auto-upgrade hook (see Internal patterns).

Windows shim `bin/chosko-llm.cmd` transparent to subcommand routing above — locates git-bash, delegates to bash proxy, which routes subcommands. All CLI behavior single-sourced in bash proxy + scripts.

`install.sh` accepts no arguments. Uses these env vars:
- `CHOSKO_LLM_HOME` — managed clone path. Default `~/.chosko-llm`.
- `BIN_DIR` — proxy install dir. Default `~/bin`.

`uninstall.sh` interactive: prompts before removing features, before removing managed clone.

## Internal patterns

- **Copy, not symlink.** `install.sh` copies proxy; `cmd-add`/`cmd-update` copy feature files. Deliberate design rule (see `../../CLAUDE.md` hard rules).
- **Existing proxy backed up,** not overwritten. `install.sh` renames existing `$BIN_DIR/chosko-llm` to `chosko-llm.bak.<timestamp>`. Same backup policy for `chosko-llm.cmd` on Windows.
- **`.cmd` shim ships via `install.sh`, not `upgrade`.** `upgrade` only does `git pull` + proxy refresh — first-time Windows setup needs re-run of `install.sh` to drop `.cmd` into `$BIN_DIR`.
- **Windows PATH vs MSYS PATH.** Installer reminds Windows users to add `$BIN_DIR` to *Windows* PATH (via System Properties), not just MSYS PATH. Uses `cygpath -w` when available to print native path.
- **Origin URL inferred** from working repo's `origin` remote when cloning managed clone. If absent, install fails with clear message.
- **`curl | bash` install path.** No script file → `BASH_SOURCE[0]` unset; `install.sh` guards reference (needed under `set -u`), leaves `SCRIPT_DIR` empty. Empty `SCRIPT_DIR` (no `$SCRIPT_DIR/.git`) selects third clone branch: `git clone "$REPO_URL"` (default `https://github.com/Chosko/chosko-llm.git`, overridable via `REPO_URL`) instead of cloning local working copy's `origin`.
- **Re-running install.sh** on populated `$CHOSKO_LLM_HOME` does `git pull --ff-only` instead of cloning. Idempotent.
- **uninstall.sh removes features by intersecting** managed clone's `commands/` and `skills/` listings with `$CLAUDE_HOME` — user-authored files in `~/.claude/` untouched.
- **Daily auto-upgrade (opt-in).** Proxy runs `scripts/auto-upgrade.sh` before each dispatch. Fires `chosko-llm upgrade` at most once per calendar day, skipping `upgrade`/`help`/empty/`uninstall`/`version` subcommands, never recursing (no point pulling clone `uninstall` may delete, or for read-only version check). Preference + last-run date live in **gitignored** state file `$CHOSKO_LLM_HOME/.auto-upgrade-state` (`enabled`, `last_run`); missing file means enabled (opt-in default). `install.sh` writes it with `enabled=true`. `cmd-upgrade.sh` exposes toggle-only `--enable-auto`/`--disable-auto`. `last_run` stamped before upgrade so failure doesn't retry all day; `CHOSKO_LLM_NO_AUTO_UPGRADE` force-skips. Hook lives in `bin/chosko-llm` — existing users gain it only after one `upgrade` (refreshes proxy) or re-run of `install.sh`.

## Domain dependencies

- `../../CLAUDE.md` — copy-not-symlink, env-var override, idempotency rules.
- `../../README.md` — describes install flow shown to users.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `lib.sh` **not** sourced into main shell of `install.sh`/`uninstall.sh`/`bin/chosko-llm`. Those three reimplement own minimal logging + path defaults so they run before managed clone exists. (`scripts/auto-upgrade.sh`, invoked by proxy, *does* source `lib.sh` — holds `auto_upgrade_*` state helpers.) One narrow exception: `install.sh` step 4 sources `lib.sh` in isolated command-substitution **subshell** purely to call `resolve_version`, so own `[install]` logging untouched and version format stays single-sourced with `chosko-llm --version`.
- [cmd-upgrade.md](./cmd-upgrade.md) — owns post-install update path (`git pull` + proxy refresh).

## When to read the source

- Change subcommand routing table or proxy arg handling → `bin/chosko-llm`.
- Change bootstrap behavior (clone, PATH check, version banner, backup policy) → `install.sh`.
- Change uninstall prompts or feature-intersection deletion logic → `uninstall.sh`.
- Anything touching proxy's invariant that it must work *before* managed clone has any scripts → `bin/chosko-llm` (can't rely on `lib.sh`).
- Change daily auto-upgrade behavior (when fires, state-file format, toggle flags, install opt-in) → `scripts/auto-upgrade.sh`, `auto_upgrade_*` helpers in `scripts/lib.sh`, flag/tip handling in `scripts/cmd-upgrade.sh`, state-init block in `install.sh`.
- Change Windows shim (bash detection paths, argument forwarding, error message) → `bin/chosko-llm.cmd`.