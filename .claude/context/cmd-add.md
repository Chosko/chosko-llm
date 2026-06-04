# cmd-add

## Overview

`scripts/cmd-add.sh` copies a single feature from the managed clone into
`$CLAUDE_HOME`. It refuses to overwrite an already-installed feature — for
that, the user must call `update`.

## Public API

CLI:
- `chosko-llm add <feature>` — `<feature>` is `<name>`, `command:<name>`,
  `skill:<name>`, or `claude-md:<name>`.
- `chosko-llm add --all` — install every feature present in the managed clone
  (commands, skills, AND claude-md artifacts) that is not yet installed;
  already-installed features are skipped with an info log.

Exit codes:
- 0 on successful copy (or `--all` with nothing new to install).
- 1 (via `die`) if no argument, if the feature is not in the managed clone,
  if the source is missing required frontmatter, or if the target is already
  installed.

Side effects:
- Creates `$CLAUDE_HOME/commands/` or `$CLAUDE_HOME/skills/` if missing.
- For commands: copies one `.md` file.
- For skills: recursive copy (`cp -R`) of the entire skill directory.
- For claude-md: injects a managed section into `$CLAUDE_HOME/CLAUDE.md` via
  `inject_section` (no file copy); refuses if the section already exists.
- Logs a single `Installed <kind> '<name>' v<version> -> <path>` line.

## Internal patterns

- **Resolution is delegated** to `resolve_feature` in
  [shared-lib.md](./shared-lib.md). This script never parses the
  `command:` / `skill:` prefix itself.
- **Validation precedes copy.** `require_versioned_source` runs before any
  filesystem mutation, so a missing-frontmatter source cannot half-install.
- **Refuses to clobber.** If the target file/dir exists, `die`s with a
  pointer to `chosko-llm update`. This is the contract that distinguishes
  `add` from `update` — keep it.
- **Skills copy recursively.** Any supporting files alongside `SKILL.md`
  ride along. The authoring guide documents this for skill authors.

## Domain dependencies

- `../../docs/authoring-guide.md` — the frontmatter contract that
  `require_versioned_source` enforces lives here.
- `../../CLAUDE.md` — "copy, never symlink" hard rule.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `resolve_feature`,
  `require_versioned_source`, `src_*` / `inst_*` path helpers.
- [cmd-update.md](./cmd-update.md) — the "refresh / reinstall" counterpart;
  `update` will install if missing, so it can be used in place of `add`.
- [cmd-rm.md](./cmd-rm.md) — inverse operation.

## When to read the source

- Changing the "already installed → error" policy (e.g. adding a `--force`
  flag) → `scripts/cmd-add.sh`.
- Changing what gets copied for a skill (e.g. excluding patterns) → the
  `cp -R` call in the `skill)` branch and the `--all` loop of `cmd-add.sh`.
- Tweaking the success log line format → `cmd-add.sh`.
- Changing `--all` enumeration or skip logic → the `--all` block in `cmd-add.sh`.
