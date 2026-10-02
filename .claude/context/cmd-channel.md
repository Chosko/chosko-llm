# cmd-channel

## Overview

`scripts/cmd-channel.sh` switch managed clone (`$CHOSKO_LLM_HOME`) onto branch — a **channel** — so user try features before land on `master`, then switch back. Return to stable = just `chosko-llm channel master`.

## Public API

CLI:
- `chosko-llm channel` — print branch clone currently on.
- `chosko-llm channel --list` (also `-l`) — `git fetch --prune origin`, then list branches available on `origin`, mark current one with `* … (current)`.
- `chosko-llm channel <branch>` — `git fetch --prune origin`, `git checkout <branch>`,
  `git pull --ff-only`, then refresh proxy at `$BIN_DIR/chosko-llm` and
  `chmod +x` clone's scripts. Print reminder to run `update --all`
  (does NOT run it).

Exit codes:
- 0 on success (all three forms).
- 1 (via `die`) if `$CHOSKO_LLM_HOME` not git repo (re-run `install.sh`),
  or if `<branch>` not exist — checkout aborts, clone left
  on original branch, nothing half-applied.

Side effects:
- `<branch>` also checks out and fast-forwards branch, then `refresh_proxy`
  refreshes the proxy and the clone's executable bits exactly as `upgrade`
  does ([cmd-upgrade.md](./cmd-upgrade.md) § Public API).

## Internal patterns

- **No state file.** Checked-out branch = entire persistence mechanism:
  auto-upgrade's `git pull --ff-only` follows whatever branch checked out.
- **Deploy explicit**, as for `upgrade` ([cmd-upgrade.md](./cmd-upgrade.md)
  § Overview).
- **Fetch-first for `--list`** so branch list reflects origin, not stale
  local view — point is discover channels just pushed.
- **`BIN_DIR` env var with `~/bin` default**, matching `cmd-upgrade.sh` /
  `install.sh`.
- **Merged-and-deleted branch:** channel branch removed upstream fails
  `pull --ff-only`; documented recovery = `chosko-llm channel master`.

## Domain dependencies

- `../../CLAUDE.md` — no state files; env-var overrides; copy-not-symlink.
- `../../docs/authoring-guide.md` — don't edit managed clone by hand;
  `--ff-only` refuses to fast-forward over local changes.

## Cross-references

- [cmd-upgrade.md](./cmd-upgrade.md) — shares proxy-refresh + `chmod` block
  and `[ -d "$CHOSKO_LLM_HOME/.git" ]` guard; `upgrade` pulls *current*
  channel, `channel` switches between them.
- [cli-entry.md](./cli-entry.md) — proxy dispatches `channel` →
  `cmd-channel.sh`; `scripts/auto-upgrade.sh` skips `channel` (like `upgrade`), and its daily `pull --ff-only` is what makes a switched channel stick.
- [cmd-update.md](./cmd-update.md) — recommended follow-up after switching
  to actually deploy channel's features into `$CLAUDE_HOME`.
- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for `die`, `log_info`,
  `log_success`, `log_warn`, and `$CHOSKO_LLM_HOME`.

## When to read source

- Changing switch sequence (fetch/checkout/pull order, adding `--force`
  or rebase mode) → `scripts/cmd-channel.sh`.
- Changing how channels listed (e.g. showing local branches too, or
  annotating merge status) → `--list` branch of `scripts/cmd-channel.sh`.
- Changing proxy-refresh behavior → keep in sync with
  `scripts/cmd-upgrade.sh`.
- Changing which subcommands auto-upgrade skips → `scripts/auto-upgrade.sh`.