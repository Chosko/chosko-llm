# cmd-upgrade

## Overview

`scripts/cmd-upgrade.sh` run `git pull --ff-only` inside managed clone, refresh proxy at `$BIN_DIR/chosko-llm`. **Not** touch installed features — user must run `update --all` after.

## Public API

CLI:
- `chosko-llm upgrade` — pull + refresh.
- `chosko-llm upgrade --enable-auto` / `--disable-auto` — **toggle-only**:
  set daily auto-upgrade preference in state file, exit; do
  NOT pull. Mutually exclusive (`die` if both).

Exit codes:
- 0 on success (including "already up to date", and toggle flags).
- 1 (via `die`) if both toggle flags passed, if `$CHOSKO_LLM_HOME` not
  git repo (user must re-run `install.sh`), or if `git pull --ff-only`
  fails (e.g. local edits in managed clone, or non-fast-forward).

Side effects:
- `git pull --ff-only` in `$CHOSKO_LLM_HOME`.
- If `$BIN_DIR/chosko-llm` exists, copies freshly-pulled
  `bin/chosko-llm` over it, `chmod +x`. If absent, warns, tells
  user re-run `install.sh`.
- `chmod +x` on `scripts/*.sh` and `bin/chosko-llm` in managed clone
  (silenced).
- Logs commit range pulled (`git log --oneline before..after`) on
  non-empty pulls.
- On plain upgrade (no toggle flag), if daily auto-upgrade NOT enabled,
  prints TTY-gated tip to opt in (`chosko-llm upgrade --enable-auto`).

## Internal patterns

- **Fast-forward only.** Divergent or dirty managed clone fails pull;
  script won't try recover. Authoring guide warns users not edit
  managed clone for this reason.
- **Proxy refresh conditional.** Only overwrites `$BIN_DIR/chosko-llm` if
  already exists — never creates it. Creation `install.sh`'s job.
- **Reads `BIN_DIR` env var, `~/bin` default**, matching `install.sh`.
  `lib.sh` doesn't set this default.

## Domain dependencies

- `../../CLAUDE.md` — "CLI logic ships via `git pull` (`chosko-llm upgrade`),
  not by re-running `install.sh`".
- `../../docs/authoring-guide.md` — "Editing managed clone (...)
  directly. `chosko-llm upgrade` will refuse to fast-forward over local
  changes."

## Cross-references

- [cli-entry.md](./cli-entry.md) — `install.sh` only path that
  *creates* proxy; `upgrade` only refreshes it.
- [cmd-update.md](./cmd-update.md) — recommended follow-up after
  `upgrade` to actually deploy new versions to `$CLAUDE_HOME`.
- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for logging,
  `$CHOSKO_LLM_HOME`, and `auto_upgrade_*` state helpers behind
  toggle flags and opt-in tip.
- [cli-entry.md](./cli-entry.md) — `scripts/auto-upgrade.sh` (invoked by
  proxy) calls this script once daily; toggle flags set preference it
  reads.

## When to read source

- Changing pull strategy (e.g. allowing rebases, recovering from dirty
  state) → `scripts/cmd-upgrade.sh`.
- Changing how proxy refreshed (e.g. detecting CLI-breaking change,
  refusing) → `scripts/cmd-upgrade.sh`.
- Adding notice when `update --all` required → `cmd-upgrade.sh`.
- Changing auto-upgrade toggle flags or opt-in tip → flag block
  at top of `cmd-upgrade.sh` and `auto_upgrade_*` helpers in
  `lib.sh`; daily trigger itself lives in `scripts/auto-upgrade.sh`.