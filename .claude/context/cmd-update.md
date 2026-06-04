# cmd-update

## Overview

`scripts/cmd-update.sh` re-copies a feature from the managed clone into
`$CLAUDE_HOME`, replacing whatever was there. It installs if missing —
unlike `add`, it does not refuse on absence.

## Public API

CLI:
- `chosko-llm update <feature>` — single feature; same spec syntax as `add`
  (`<name>`, `command:`/`skill:`/`claude-md:` prefixed). Installs if missing.
- `chosko-llm update --all` — iterate installed commands
  (`$CLAUDE_HOME/commands/*.md`), skills (`$CLAUDE_HOME/skills/*/`), and
  claude-md sections (markers in `$CLAUDE_HOME/CLAUDE.md`), updating only
  those whose managed-clone source version is **newer** than installed.

Exit codes:
- 0 on success (including `--all` with nothing to update).
- 1 (via `die`) on no argument, missing source, or missing/invalid
  frontmatter on the source.

Side effects:
- Single feature: deletes the existing target (`rm -f` for command,
  `rm -rf` for skill) then copies fresh; claude-md re-injects via
  `inject_section`.
- `--all`: per installed feature, compares versions with `version_cmp` and
  logs `Already up-to-date` (equal), `Local version ahead … — skipping`
  (installed newer), or updates (source newer). Emits
  `Skipping <kind> '<base>': no source in managed clone.` when the source has
  disappeared, and `Skipping … version unreadable` when a version can't be
  parsed.
- One `Updated <kind> '<name>' -> v<version>` log line per actual update.

## Internal patterns

- **Replace, don't merge.** Skills are deleted then re-copied wholesale; a
  file removed from the source skill folder will disappear from the
  installed skill folder. This is by design.
- **Validation precedes mutation.** Same `require_versioned_source` guard as
  `cmd-add`.
- **`--all` is version-aware.** `version_cmp` (an awk semver comparator,
  expects `x.y.z`) gates each update so only genuinely-newer sources are
  copied; up-to-date and locally-ahead features are left alone. A skip
  warning is *not* an error — the script exits 0 even if everything was
  skipped, logging `Nothing to update.` only when no candidates were touched.
- **Single-feature path uses `resolve_feature`** (managed clone), so it can
  install-if-missing. The `--all` path iterates `$CLAUDE_HOME` directly,
  including the CLAUDE.md section markers for claude-md artifacts.

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

- Changing `--all` version-comparison semantics → `version_cmp` and the
  per-kind `--all` blocks in `scripts/cmd-update.sh`.
- Changing skill-update merge vs. replace behavior → the `skill)` branch's
  `rm -rf && cp -R` in `cmd-update.sh`.
- Adding `--dry-run` → `cmd-update.sh`.
