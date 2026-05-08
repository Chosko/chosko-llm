# cmd-rm

## Overview

`scripts/cmd-rm.sh` deletes an installed feature from `$CLAUDE_HOME`. It
resolves names against what is **installed**, not against the managed clone
— so a user-authored feature with no source can still be removed.

## Public API

CLI:
- `chosko-llm rm <feature>` — `<feature>` is `<name>`, `command:<name>`, or
  `skill:<name>`.

Exit codes:
- 0 on successful removal.
- 1 (via `die`) if no argument, if `<name>` is ambiguous (both kinds
  installed) without a prefix, or if nothing matching is installed.

Side effects:
- For commands: `rm -f` on the `.md` file.
- For skills: `rm -rf` on the entire skill directory.
- Logs a single `Removed <kind> '<name>' (<path>)` line.

## Internal patterns

- **Resolution is local, not via `resolve_feature`.** `cmd-rm.sh` parses
  the `command:` / `skill:` prefix itself and uses `installed_kind` from
  `lib.sh`. This is intentional — `resolve_feature` checks the managed
  clone, which is the wrong source of truth here. Keep the prefix-parsing
  case statement in sync with the one in `lib.sh::resolve_feature` if the
  syntax changes.
- **No source-existence check.** A feature whose source has been removed
  from the managed clone is still removable from `$CLAUDE_HOME`.

## Domain dependencies

- `../../CLAUDE.md` — "filesystem is the source of truth"; this script's
  reliance on `installed_kind` rather than a lockfile follows that.

## Cross-references

- [shared-lib.md](./shared-lib.md) — uses `installed_kind`,
  `inst_command_path`, `inst_skill_dir`.
- [cmd-add.md](./cmd-add.md) — inverse operation.
- [cli-entry.md](./cli-entry.md) — `uninstall.sh` performs a bulk variant of
  this against the managed-clone listing.

## When to read the source

- Changing how disambiguation works (e.g. adding an interactive prompt
  instead of `die` on ambiguity) → `scripts/cmd-rm.sh`.
- Adding a `--all` flag (currently absent — only `update` and `uninstall.sh`
  do bulk operations) → `cmd-rm.sh`.
