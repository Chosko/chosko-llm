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
- On non-empty pulls, prints **exactly one of two** things to stderr: the
  curated changelog range when the version moved, else the commit range
  pulled (`git log --oneline before..after`). See Internal patterns.
- Reads managed clone's raw `VERSION` twice — once before `git pull --ff-only`,
  once after — and passes both to `print_changelog_range` in `lib.sh`. Reads
  only; writes nothing, persists nothing between runs.
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
- **Version reads use `raw_version`, never `resolve_version`.** Latter appends
  ` (<git describe>)`; no tags in this repo, so that's a bare sha changing every
  commit — useless as a comparison. Comment in source says so; don't "fix" it.
- **Changelog range two-sided, descending semver**: new version's section
  inclusive, down to but excluding old version's. Extraction + formatting both
  live in `print_changelog_range` (`lib.sh`), never inline here — colour
  handling belongs in `lib.sh`, and this block goes to stderr so it gates on
  `_use_color`, not the stdout-gated `C_*` vars.
- **Commit-list dump suppressed exactly when a range printed.** Branch keys off
  `print_changelog_range`'s return code (0 = printed): curated bullets when the
  version moved, `git log --oneline` subjects when it didn't or the clone has no
  `CHANGELOG.md`. Never both — a subject dump beside a curated summary is
  strictly worse for this audience, and commits stay one
  `git -C ~/.chosko-llm log` away.
- **Readout degrades, never fails.** Nothing in it can change `upgrade`'s exit
  code or abort the run: a malformed, truncated or unreadable `CHANGELOG.md`
  costs the user their release notes, never their upgrade. Missing changelog is
  silent (clones predating the feature are the normal case).
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

- [cli-entry.md](./cli-entry.md) — `install.sh` only path that
  *creates* proxy; `upgrade` only refreshes it.
- [cmd-update.md](./cmd-update.md) — recommended follow-up after
  `upgrade` to actually deploy new versions to `$CLAUDE_HOME`.
- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for logging,
  `$CHOSKO_LLM_HOME`, `auto_upgrade_*` state helpers behind
  toggle flags and opt-in tip, and `raw_version` +
  `print_changelog_range` behind the readout.
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
- Changing the changelog readout → *where* it sits, which versions bracket it,
  and whether the commit dump is suppressed live in `cmd-upgrade.sh`; the range
  extraction, layout and colours live in `print_changelog_range` in `lib.sh`
  (see [shared-lib.md](./shared-lib.md)).