Compressed markdown ready.

# cmd-update

## Overview

`scripts/cmd-update.sh` re-copy feature from managed clone into
`$CLAUDE_HOME`, replace whatever there. Install if missing —
unlike `add`, no refuse on absence.

## Public API

CLI:
- `chosko-llm update <feature>` — single feature; same spec syntax as `add`
  (`<name>`, `command:`/`skill:`/`claude-md:`/`statusline:` prefixed).
  Install if missing.
- `chosko-llm update --all` — iterate installed commands
  (`$CLAUDE_HOME/commands/*.md`), skills (`$CLAUDE_HOME/skills/*/`),
  claude-md sections (markers in `claudemd_target_path`), statusline
  scripts (`$CLAUDE_HOME/statusline/*.sh`, skipped entirely in local
  scope), update only those whose managed-clone source version **newer**
  than installed.
- `chosko-llm update <feature> --local` / `--global` — scope, see below.

Exit codes:
- 0 success (including `--all` with nothing to update).
- 1 (via `die`) on no argument, missing source, missing/invalid
  frontmatter on source, or a single-feature `statusline` request with
  `--local`.

Side effects:
- Single feature: delete existing target (`rm -f` for command/statusline,
  `rm -rf` for skill), copy fresh (`chmod +x` for statusline);
  claude-md re-inject via `inject_section` into `claudemd_target_path`.
  Then `apply_replaces` — if source frontmatter carries
  `replaces: <kind>:<name>` and that artifact installed, remove it, log
  `Migrated <old-kind> '<name>' -> <new-kind> '<name>'`. Silent otherwise.
- `--all`: per installed feature, compare versions with `version_cmp`,
  log `Already up-to-date` (equal), `Local version ahead … — skipping`
  (installed newer), or update (source newer). When source disappeared,
  try `migrate_stale` first (below); only on no replacement emit
  `Skipping <kind> '<base>': no source in managed clone.`.
  `Skipping … version unreadable` when version unparseable. In local
  scope the statusline pass is skipped up front with one info log
  instead of iterating (statusline is global-only).
- One `Updated <kind> '<name>' -> v<version> (scope: <scope>)` log line
  per actual update.

**Scope (`--local` / `--global`, task 103).** First line after sourcing
`lib.sh` calls `resolve_scope "$@"` then re-sets `$@` from `SCOPE_ARGS`;
existing flag parsing runs unchanged on the cleaned arguments. No flag =
`--global`, byte-identical to pre-103 behavior. Single-feature path: after
`resolve_feature` returns `kind`, `scope_supports_kind "$kind"` gates the
update — `die`s naming statusline global-only if it fails, before
`update_one` runs.

## Internal patterns

- **Replace, not merge.** Skills deleted then re-copied wholesale; file
  removed from source skill folder disappears from installed skill folder.
  By design.
- **Validation before mutation.** Same `require_versioned_source` guard as
  `cmd-add`.
- **`--all` version-aware.** `version_cmp` (awk semver comparator,
  expects `x.y.z`) gates each update — only genuinely-newer sources
  copied; up-to-date and locally-ahead features left alone. Skip
  warning *not* error — script exits 0 even if all skipped, logs
  `Nothing to update.` only when no candidates touched.
- **Single-feature path uses `resolve_feature`** (managed clone) — can
  install-if-missing. `--all` path iterates `$CLAUDE_HOME` directly,
  including CLAUDE.md section markers for claude-md artifacts.
- **`migrate_stale <kind> <name>`** (script-local, defined above
  `version_cmp`) hooks the existing "no source" branch of all four `--all`
  loops — no new iteration pass. Calls `find_replacement`; on hit runs
  `update_one` for the replacement then `apply_replaces` to drop the stale
  artifact, and sets `any=1`. Returns 1 on no hit so the `elif` falls through
  to the unchanged warning. Globs expand before the loop body runs, so
  deleting the current entry mid-loop is safe.

## Domain dependencies

- `../../docs/authoring-guide.md` — versioning rules. `update --all` is
  user's primary mechanism for picking up new versions; unbumped
  `version` defeats it visually but copy still happens (file content
  refreshed regardless).
- `../../CLAUDE.md` — "filesystem is source of truth".

## Cross-references

- [shared-lib.md](./shared-lib.md) — `resolve_feature`,
  `require_versioned_source`, path helpers, scope helpers `resolve_scope` /
  `scope_supports_kind` / `claudemd_target_path`.
- [cmd-add.md](./cmd-add.md) — installs-only-if-absent counterpart.
- [cmd-upgrade.md](./cmd-upgrade.md) — typical user flow:
  `upgrade` (refresh source) then `update --all` (refresh installs).

## When to read source

- Change `--all` version-comparison semantics → `version_cmp` and
  per-kind `--all` blocks in `scripts/cmd-update.sh`.
- Change kind-migration behavior on `--all` → `migrate_stale` in
  `cmd-update.sh` and `find_replacement` / `apply_replaces` in `lib.sh`.
- Change skill-update merge vs. replace behavior → `skill)` branch's
  `rm -rf && cp -R` in `cmd-update.sh`.
- Add `--dry-run` → `cmd-update.sh`.
- Change scope behavior (statusline refusal/skip) → `resolve_scope` call,
  `scope_supports_kind` check, and the `--all` statusline block in
  `cmd-update.sh`.