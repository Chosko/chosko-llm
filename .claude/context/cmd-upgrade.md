# cmd-upgrade

## Overview

`scripts/cmd-upgrade.sh` runs `git pull --ff-only` inside the managed clone
and refreshes the proxy at `$BIN_DIR/chosko-llm`. It does **not** touch
installed features — the user must run `update --all` afterwards.

## Public API

CLI:
- `chosko-llm upgrade` — no arguments.

Exit codes:
- 0 on success (including "already up to date").
- 1 (via `die`) if `$CHOSKO_LLM_HOME` is not a git repo (user must re-run
  `install.sh`), or if `git pull --ff-only` fails (e.g. local edits in the
  managed clone, or non-fast-forward).

Side effects:
- `git pull --ff-only` in `$CHOSKO_LLM_HOME`.
- If `$BIN_DIR/chosko-llm` exists, copies the freshly-pulled
  `bin/chosko-llm` over it and `chmod +x`. If absent, warns and tells the
  user to re-run `install.sh`.
- `chmod +x` on `scripts/*.sh` and `bin/chosko-llm` in the managed clone
  (silenced).
- Logs the commit range pulled (`git log --oneline before..after`) on
  non-empty pulls.

## Internal patterns

- **Fast-forward only.** A divergent or dirty managed clone fails the pull;
  the script does not try to recover. Authoring guide warns users not to
  edit the managed clone for this reason.
- **Proxy refresh is conditional.** Only overwrites `$BIN_DIR/chosko-llm` if
  it already exists — never creates it. Creation is `install.sh`'s job.
- **Reads `BIN_DIR` env var with `~/bin` default**, matching `install.sh`.
  `lib.sh` does not set this default.

## Domain dependencies

- `../../CLAUDE.md` — "CLI logic ships via `git pull` (`chosko-llm upgrade`),
  not by re-running `install.sh`".
- `../../docs/authoring-guide.md` — "Editing the managed clone (...)
  directly. `chosko-llm upgrade` will refuse to fast-forward over local
  changes."

## Cross-references

- [cli-entry.md](./cli-entry.md) — `install.sh` is the only path that
  *creates* the proxy; `upgrade` only refreshes it.
- [cmd-update.md](./cmd-update.md) — the recommended follow-up after
  `upgrade` to actually deploy new versions to `$CLAUDE_HOME`.
- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for logging and
  `$CHOSKO_LLM_HOME`.

## When to read the source

- Changing the pull strategy (e.g. allowing rebases, recovering from dirty
  state) → `scripts/cmd-upgrade.sh`.
- Changing how the proxy is refreshed (e.g. detecting a CLI-breaking change
  and refusing) → `scripts/cmd-upgrade.sh`.
- Adding a notice when `update --all` would be required → `cmd-upgrade.sh`.
