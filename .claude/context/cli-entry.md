# CLI entry & bootstrap

## Overview

The CLI is split into four pieces:

- `install.sh` — first-time bootstrap. Clones the working repo into the
  **managed clone** at `$CHOSKO_LLM_HOME` (default `~/.chosko-llm`) and copies
  `bin/chosko-llm` to `$BIN_DIR/chosko-llm` (default `~/bin`). On Windows
  (MINGW/MSYS/Cygwin) it also copies `bin/chosko-llm.cmd` into `$BIN_DIR`.
- `bin/chosko-llm` — a thin proxy. Reads the subcommand and execs the matching
  `scripts/cmd-<sub>.sh` from inside the managed clone. Before dispatching it
  invokes `scripts/auto-upgrade.sh` (guarded, `|| true`) to run the daily
  auto-upgrade.
- `scripts/auto-upgrade.sh` — the daily auto-upgrade hook. Sources `lib.sh`,
  and when the user is opted in and it has not run today, runs
  `chosko-llm upgrade` once before the requested command. Never aborts the
  command (every exit is non-fatal).
- `bin/chosko-llm.cmd` — Windows-only batch shim. Detected via `PATHEXT` by
  cmd.exe and PowerShell. Auto-detects git-bash (`%ProgramFiles%\Git\bin\bash.exe`
  and two other standard locations, then `where bash`), then forwards all
  arguments to `%~dp0chosko-llm` (the sibling bash proxy). Propagates exit
  code with `exit /b %ERRORLEVEL%`. Contains no dispatch logic.
- `uninstall.sh` — removes the proxy, optionally deletes installed features
  from `$CLAUDE_HOME` (matched against the managed clone), and optionally
  deletes the managed clone itself.

The proxy reads from the managed clone, not from the working repo. Edits in
the working repo reach users via `git push` → `chosko-llm upgrade` (which
runs `git pull` in the managed clone). See [cmd-upgrade.md](./cmd-upgrade.md).

## Public API (CLI surface)

The proxy at `bin/chosko-llm` accepts these subcommands and forwards `$@`:
- `ls`, `add`, `rm`, `update`, `upgrade`, `show` → `scripts/cmd-<sub>.sh`
- `task-impl` → `scripts/cmd-task-impl.sh` (the external-LLM orchestrator;
  see [cmd-task-impl.md](./cmd-task-impl.md)).
- `""`, `-h`, `--help`, `help` → `scripts/cmd-help.sh` (falls back to
  `docs/cli-help.txt` if the script is missing).
- Anything else → exits with code 2.
- Before dispatching any of the above, the proxy runs the daily auto-upgrade
  hook (see Internal patterns).

The Windows shim `bin/chosko-llm.cmd` is transparent to the subcommand routing
above — it locates git-bash and delegates to the bash proxy, which then routes
subcommands. All CLI behavior is single-sourced in the bash proxy and scripts.

`install.sh` accepts no arguments. It uses these env vars:
- `CHOSKO_LLM_HOME` — managed clone path. Default `~/.chosko-llm`.
- `BIN_DIR` — proxy install dir. Default `~/bin`.

`uninstall.sh` is interactive: prompts before removing features and before
removing the managed clone.

## Internal patterns

- **Copy, not symlink.** `install.sh` copies the proxy and `cmd-add` /
  `cmd-update` copy feature files. This is a deliberate design rule (see
  `../../CLAUDE.md` hard rules).
- **Existing proxy is backed up,** not overwritten. `install.sh` renames any
  existing `$BIN_DIR/chosko-llm` to `chosko-llm.bak.<timestamp>`. The same
  backup policy applies to `chosko-llm.cmd` on Windows.
- **`.cmd` shim ships via `install.sh`, not `upgrade`.** Because `upgrade`
  only does `git pull` + proxy refresh, first-time Windows setup requires
  re-running `install.sh` to drop the `.cmd` into `$BIN_DIR`.
- **Windows PATH vs MSYS PATH.** The installer reminds Windows users to add
  `$BIN_DIR` to their *Windows* PATH (via System Properties), not just the
  MSYS PATH. Uses `cygpath -w` when available to print the native path.
- **Origin URL is inferred** from the working repo's `origin` remote when
  cloning the managed clone. If absent, install fails with a clear message.
- **Re-running install.sh** on a populated `$CHOSKO_LLM_HOME` does
  `git pull --ff-only` instead of cloning. Idempotent.
- **uninstall.sh removes features by intersecting** the managed clone's
  `commands/` and `skills/` listings with `$CLAUDE_HOME`, so user-authored
  files in `~/.claude/` are left alone.
- **Daily auto-upgrade (opt-in).** The proxy runs `scripts/auto-upgrade.sh`
  before each dispatch. It fires `chosko-llm upgrade` at most once per
  calendar day, skipping the `upgrade`/`help`/empty subcommands and never
  recursing. Preference + last-run date live in a **gitignored** state file
  `$CHOSKO_LLM_HOME/.auto-upgrade-state` (`enabled`, `last_run`); a missing
  file means enabled (opt-in default). `install.sh` writes it with
  `enabled=true`. `cmd-upgrade.sh` exposes toggle-only `--enable-auto` /
  `--disable-auto`. `last_run` is stamped before the upgrade so a failure
  doesn't retry all day; `CHOSKO_LLM_NO_AUTO_UPGRADE` force-skips. Because the
  hook lives in `bin/chosko-llm`, existing users gain it only after one
  `upgrade` (which refreshes the proxy) or re-running `install.sh`.

## Domain dependencies

- `../../CLAUDE.md` — copy-not-symlink, env-var override, idempotency rules.
- `../../README.md` — describes the install flow shown to users.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `lib.sh` is **not** sourced by
  `install.sh` / `uninstall.sh` / `bin/chosko-llm`. Those three reimplement
  their own minimal logging and path defaults so they can run before the
  managed clone exists. (`scripts/auto-upgrade.sh`, invoked by the proxy,
  *does* source `lib.sh` — it holds the `auto_upgrade_*` state helpers.)
- [cmd-upgrade.md](./cmd-upgrade.md) — owns the post-install update path
  (`git pull` + proxy refresh).

## When to read the source

- Changing the subcommand routing table or proxy arg handling →
  `bin/chosko-llm`.
- Changing bootstrap behavior (clone, PATH check, version banner, backup
  policy) → `install.sh`.
- Changing uninstall prompts or the feature-intersection deletion logic →
  `uninstall.sh`.
- Anything touching the proxy's invariant that it must work *before* the
  managed clone has any scripts → `bin/chosko-llm` (it cannot rely on
  `lib.sh`).
- Changing the daily auto-upgrade behavior (when it fires, the state-file
  format, the toggle flags, the install opt-in) → `scripts/auto-upgrade.sh`,
  the `auto_upgrade_*` helpers in `scripts/lib.sh`, the flag/tip handling in
  `scripts/cmd-upgrade.sh`, and the state-init block in `install.sh`.
- Changing the Windows shim (bash detection paths, argument forwarding,
  error message) → `bin/chosko-llm.cmd`.
