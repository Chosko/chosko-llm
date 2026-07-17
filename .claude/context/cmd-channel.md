# cmd-channel

## Overview

`scripts/cmd-channel.sh` switches the managed clone (`$CHOSKO_LLM_HOME`) onto a
branch — a **channel** — so a user can try features before they land on
`master`, then switch back. The checked-out branch is the entire persistence
mechanism: auto-upgrade's `git pull --ff-only` already follows whatever branch
is checked out, so there is no state file. Returning to stable is just
`chosko-llm channel master`.

## Public API

CLI:
- `chosko-llm channel` — print the branch the clone is currently on. Exits 0.
- `chosko-llm channel --list` (also `-l`) — `git fetch` origin, then list the
  branches available on `origin`, marking the current one with `* … (current)`.
  Exits 0.
- `chosko-llm channel <branch>` — `git fetch`, `git checkout <branch>`,
  `git pull --ff-only`, then refresh the proxy at `$BIN_DIR/chosko-llm` and
  `chmod +x` the clone's scripts. Prints a reminder to run `update --all`
  (does NOT run it). Exits 0.

Exit codes:
- 0 on success (all three forms).
- 1 (via `die`) if `$CHOSKO_LLM_HOME` is not a git repo (re-run `install.sh`),
  or if `<branch>` does not exist — the checkout aborts and the clone is left
  on its original branch, nothing half-applied.

Side effects:
- `--list` and `<branch>` run `git fetch --prune origin` in the clone.
- `<branch>` also checks out and fast-forwards the branch, and (like
  `cmd-upgrade.sh`) copies `bin/chosko-llm` over `$BIN_DIR/chosko-llm` if that
  proxy exists, then `chmod +x`es the clone's `scripts/*.sh` and proxy.

## Internal patterns

- **No state file.** The checked-out branch persists in the clone;
  auto-upgrade's `--ff-only` tracks it. Matches the "no lockfiles/state files"
  hard rule — the filesystem is the state.
- **Proxy refresh reuses cmd-upgrade.sh's logic** (`refresh_proxy`): only
  overwrites `$BIN_DIR/chosko-llm` if it already exists (creation is
  `install.sh`'s job), then re-marks scripts executable.
- **Switch is full but deploy is explicit.** A switch does
  fetch + checkout + `pull --ff-only` + proxy refresh in one shot, but only
  *suggests* `update --all` — deploying features into `$CLAUDE_HOME` stays an
  explicit user step, consistent with `upgrade`.
- **Fetch-first for `--list`** so the branch list reflects origin, not a stale
  local view — the point is to discover channels that were just pushed.
- **`BIN_DIR` env var with `~/bin` default**, matching `cmd-upgrade.sh` /
  `install.sh`.
- **Merged-and-deleted branch:** a channel branch removed upstream fails
  `pull --ff-only`; documented recovery is `chosko-llm channel master`.

## Domain dependencies

- `../../CLAUDE.md` — no state files; env-var overrides; copy-not-symlink.
- `../../docs/authoring-guide.md` — do not edit the managed clone by hand;
  `--ff-only` refuses to fast-forward over local changes.

## Cross-references

- [cmd-upgrade.md](./cmd-upgrade.md) — shares the proxy-refresh + `chmod` block
  and the `[ -d "$CHOSKO_LLM_HOME/.git" ]` guard; `upgrade` pulls the *current*
  channel, `channel` switches between them.
- [cli-entry.md](./cli-entry.md) — the proxy dispatches `channel` →
  `cmd-channel.sh`; `scripts/auto-upgrade.sh` skips `channel` (like `upgrade`),
  and its daily `pull --ff-only` is what makes a switched channel stick.
- [cmd-update.md](./cmd-update.md) — the recommended follow-up after switching
  to actually deploy the channel's features into `$CLAUDE_HOME`.
- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for `die`, `log_info`,
  `log_success`, `log_warn`, and `$CHOSKO_LLM_HOME`.

## When to read the source

- Changing the switch sequence (fetch/checkout/pull order, adding a `--force`
  or rebase mode) → `scripts/cmd-channel.sh`.
- Changing how channels are listed (e.g. showing local branches too, or
  annotating merge status) → the `--list` branch of `scripts/cmd-channel.sh`.
- Changing the proxy-refresh behavior → keep it in sync with
  `scripts/cmd-upgrade.sh` (both carry the same block).
- Changing which subcommands auto-upgrade skips → `scripts/auto-upgrade.sh`.
