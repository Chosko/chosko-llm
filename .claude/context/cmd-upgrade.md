# cmd-upgrade

## Overview

`scripts/cmd-upgrade.sh` run `git pull --ff-only` inside managed clone, refresh proxy at `$BIN_DIR/chosko-llm`. **Not** touch installed features — user must run `update --all` after.

## Public API

CLI:
- `chosko-llm upgrade` — pull + refresh.
- `chosko-llm upgrade --enable-auto` / `--disable-auto` — **toggle-only**:
  set daily auto-upgrade preference in state file, exit; do
  NOT pull. Mutually exclusive.

Exit codes:
- 0 on success (including "already up to date", and toggle flags).
- 1 (via `die`) if both toggle flags passed, if `$CHOSKO_LLM_HOME` not
  git repo (user must re-run `install.sh`), or if `git pull --ff-only`
  fails (e.g. local edits in managed clone, or non-fast-forward).

Side effects:
- `git pull --ff-only` in `$CHOSKO_LLM_HOME`.
- If `$BIN_DIR/chosko-llm` exists, copies freshly-pulled `bin/chosko-llm`
  over it, `chmod +x`; it never creates it — creation is `install.sh`'s job —
  so when absent it warns and tells the user to re-run `install.sh`.
- `chmod +x` on `scripts/*.sh` and `bin/chosko-llm` in managed clone
  (silenced).
- On non-empty pulls, prints **exactly one of two** things to stderr: the
  curated changelog range when the version moved, else the commit range
  pulled (`git log --oneline before..after`) — also when the clone has no
  `CHANGELOG.md`. See Internal patterns.
- Reads managed clone's raw `VERSION` twice — once before `git pull --ff-only`,
  once after — and passes both to `print_changelog_range` in `lib.sh`. Reads
  only; writes nothing, persists nothing between runs.
- On plain upgrade (no toggle flag), if daily auto-upgrade NOT enabled,
  prints TTY-gated tip to opt in (`chosko-llm upgrade --enable-auto`).
- Prints a TTY-gated tip pointing at `chosko-llm changelog`, after the
  `ls --available` / `update --all` tips. The readout above covers only the
  versions this pull moved through; the whole file is one subcommand away
  (see [cmd-changelog.md](./cmd-changelog.md)).

## Internal patterns

- **Fast-forward only.** Script won't try to recover.
- **Reads `BIN_DIR` env var, `~/bin` default**, matching `install.sh`.
  `lib.sh` doesn't set this default.
- **Version reads use `raw_version`, never `resolve_version`** — why in
  [shared-lib.md](./shared-lib.md) § Version. Comment in source says so;
  don't "fix" it.
- **Extraction lives in `print_changelog_range` (`lib.sh`), never inline
  here.** Range bounds, layout, colour gate, and degrade-never-fail handling
  of a missing or broken `CHANGELOG.md` per [shared-lib-changelog.md](./shared-lib-changelog.md)
  § Changelog readout.
- **Commit-list dump suppressed exactly when a range printed.** Branch keys off
  `print_changelog_range`'s return code (0 = printed) — a subject dump beside a
  curated summary is strictly worse for this audience, and commits stay one
  `git -C ~/.chosko-llm log` away.
- **Placement deliberate**: after the pull and its reporting, before the proxy
  refresh — news about what changed arrives before mechanical follow-up hints
  (`ls --available`, `update --all`).
- **Fires during daily auto-upgrade too.** `scripts/auto-upgrade.sh` invokes
  this script directly and doesn't swallow its output, so an opted-in user sees
  the block once, in front of whatever command triggered it. Intended — for most
  users that's the only moment an upgrade happens.
- **No flag gates it.** No `--changelog`, no `--no-changelog`; unconditional
  behaviour of a version-changing pull. `chosko-llm channel <branch>` prints
  nothing of this — a channel switch can move `VERSION` either direction and is
  a developer action, not an upgrade.

## Domain dependencies

- `../../CLAUDE.md` — "CLI logic ships via `git pull` (`chosko-llm upgrade`),
  not by re-running `install.sh`".
- `../../docs/authoring-guide.md` — "Editing managed clone (...)
  directly. `chosko-llm upgrade` will refuse to fast-forward over local
  changes."

## Cross-references

- [cli-entry.md](./cli-entry.md) — `install.sh` (the only path that creates
  the proxy) and `scripts/auto-upgrade.sh` (invoked by the proxy, calls this
  script once daily, reads the preference the toggle flags set).
- [cmd-update.md](./cmd-update.md) — `update --all`.
- [cmd-changelog.md](./cmd-changelog.md) — on-demand view onto the same file,
  sharing the same renderer but writing to stdout under its own colour gate.
- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for logging,
  `$CHOSKO_LLM_HOME`, `auto_upgrade_*` state helpers behind
  toggle flags and opt-in tip, and `raw_version` behind the readout.
- [shared-lib-changelog.md](./shared-lib-changelog.md) —
  `print_changelog_range` behind the readout.

## When to read the source

- Changing pull strategy (e.g. allowing rebases, recovering from dirty
  state) → `scripts/cmd-upgrade.sh`.
- Changing how proxy refreshed (e.g. detecting CLI-breaking change,
  refusing) → `scripts/cmd-upgrade.sh`.
- Adding notice when `update --all` required → `cmd-upgrade.sh`.
- Changing auto-upgrade toggle flags or opt-in tip → flag block
  at top of `cmd-upgrade.sh` and `auto_upgrade_*` helpers in
  `lib.sh`; daily trigger itself lives in `scripts/auto-upgrade.sh`.
- Changing the changelog readout → *where* it sits, which versions bracket it,
  and whether the commit dump is suppressed live in `cmd-upgrade.sh`; the range
  extraction, layout and colours live in `print_changelog_range` in `lib.sh`
  (see [shared-lib-changelog.md](./shared-lib-changelog.md)).
