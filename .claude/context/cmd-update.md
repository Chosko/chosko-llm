# cmd-update

## Overview

`scripts/cmd-update.sh` re-copies a feature from the managed clone into
`$CLAUDE_HOME`, replacing whatever was there. It installs if missing —
unlike `add`, it does not refuse on absence.

## Public API

CLI:
- `chosko-llm update <feature>` — single feature; same spec syntax as `add`.
- `chosko-llm update --all` — iterate every file in
  `$CLAUDE_HOME/commands/*.md` and every dir in `$CLAUDE_HOME/skills/*/`,
  updating each one for which a managed-clone source exists.

Exit codes:
- 0 on success (including `--all` with nothing to update).
- 1 (via `die`) on no argument, missing source, or missing/invalid
  frontmatter on the source.

Side effects:
- Single feature: deletes the existing target (`rm -f` for command,
  `rm -rf` for skill), then copies fresh from the managed clone.
- `--all`: same per matched feature; emits a `Skipping <kind> '<base>': no
  source in managed clone.` warning for installed features whose source has
  disappeared.
- One `Updated <kind> '<name>' -> v<version>` log line per success.

## Internal patterns

- **Replace, don't merge.** Skills are deleted then re-copied wholesale; a
  file removed from the source skill folder will disappear from the
  installed skill folder. This is by design.
- **Validation precedes mutation.** Same `require_versioned_source` guard as
  `cmd-add`.
- **`--all` is best-effort.** A skip warning is *not* an error. The script
  exits 0 even if every installed feature was skipped — only `Nothing to
  update.` if neither `commands/` nor `skills/` produced any candidates.
- **Single-feature path uses `resolve_feature`.** `--all` path does not — it
  iterates `$CLAUDE_HOME` directly.

## Domain dependencies

- `../../docs/authoring-guide.md` — versioning rules. `update --all` is the
  user's primary mechanism for picking up new versions; an unbumped
  `version` defeats it visually but the copy still happens (file content is
  refreshed regardless).
- `../../CLAUDE.md` — "filesystem is the source of truth".

## Cross-references

- [shared-lib.md](./shared-lib.md) — `resolve_feature`,
  `require_versioned_source`, path helpers.
- [cmd-add.md](./cmd-add.md) — installs-only-if-absent counterpart.
- [cmd-upgrade.md](./cmd-upgrade.md) — the typical user flow is
  `upgrade` (refresh source) then `update --all` (refresh installs).

## When to read the source

- Changing `--all` semantics (e.g. only update if `semver_cmp` says newer)
  → the `--all` block in `scripts/cmd-update.sh`, plus `semver_cmp` in
  `lib.sh`.
- Changing skill-update merge vs. replace behavior → the `skill)` branch's
  `rm -rf && cp -R` in `cmd-update.sh`.
- Adding `--dry-run` → `cmd-update.sh`.
