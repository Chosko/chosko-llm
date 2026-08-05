# cmd-add

## Overview

`scripts/cmd-add.sh` copy single feature from managed clone into
`$CLAUDE_HOME`. Refuse overwrite already-installed feature — for
that, use `update`.

## Public API

CLI:
- `chosko-llm add <feature>` — `<feature>` is `<name>`, `command:<name>`,
  `skill:<name>`, `claude-md:<name>`, or `statusline:<name>`.
- `chosko-llm add --all` — install every feature in managed clone
  (commands, skills, claude-md artifacts, AND statusline scripts) not
  yet installed; already-installed skipped with info log.

Exit codes:
- 0 on successful copy (or `--all` with nothing new to install).
- 1 (via `die`) if no argument, feature not in managed clone,
  source missing required frontmatter, or target already
  installed.

Side effects:
- Creates `$CLAUDE_HOME/commands/` or `$CLAUDE_HOME/skills/` if missing.
- Commands: copies one `.md` file.
- Skills: recursive copy (`cp -R`) of entire skill directory.
- claude-md: injects managed section into `$CLAUDE_HOME/CLAUDE.md` via
  `inject_section` (no file copy); refuses if section already exists.
- Statusline: copies `.sh` file to `$CLAUDE_HOME/statusline/<name>.sh`,
  `chmod +x`'s it, then calls `print_statusline_prompt` — prints
  copy-pasteable prompt for wiring `"statusLine"` key in
  `$CLAUDE_HOME/settings.json` — no settings.json edit here.
- Logs single `Installed <kind> '<name>' v<version> -> <path>` line.

## Internal patterns

- **Resolution delegated** to `resolve_feature` in
  [shared-lib.md](./shared-lib.md). Script never parses
  `command:` / `skill:` prefix itself.
- **Validation precedes copy.** `require_versioned_source` runs before any
  filesystem mutation — missing-frontmatter source cannot half-install.
- **Refuses to clobber.** If target file/dir exists, `die`s with
  pointer to `chosko-llm update`. Contract distinguishes
  `add` from `update` — keep it.
- **Skills copy recursively.** Any supporting files alongside `SKILL.md`
  ride along. Authoring guide documents this for skill authors.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter contract
  `require_versioned_source` enforces lives here.
- `../../CLAUDE.md` — "copy, never symlink" hard rule.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `resolve_feature`,
  `require_versioned_source`, `src_*` / `inst_*` path helpers.
- [cmd-update.md](./cmd-update.md) — "refresh / reinstall" counterpart;
  `update` installs if missing, usable in place of `add`.
- [cmd-rm.md](./cmd-rm.md) — inverse operation.

## When to read the source

- Changing "already installed → error" policy (e.g. adding `--force`
  flag) → `scripts/cmd-add.sh`.
- Changing what gets copied for skill (e.g. excluding patterns) →
  `cp -R` call in `skill)` branch and `--all` loop of `cmd-add.sh`.
- Tweaking success log line format → `cmd-add.sh`.
- Changing `--all` enumeration or skip logic → `--all` block in `cmd-add.sh`.