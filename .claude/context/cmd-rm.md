# cmd-rm

## Overview

`scripts/cmd-rm.sh` delete installed feature from `$CLAUDE_HOME`. Resolve names against **installed** state, not managed clone — user-authored feature with no source still removable.

## Public API

CLI:
- `chosko-llm rm <feature>` — `<feature>` = `<name>`, `command:<name>`,
  `skill:<name>`, `claude-md:<name>`, or `statusline:<name>`.

Exit codes:
- 0 success.
- 1 (via `die`) if: no arg, `<name>` ambiguous (more than one of
  command/skill/claude-md/statusline installed) without prefix, or nothing
  matching installed.

Side effects:
- Commands: `rm -f` on `.md` file.
- Skills: `rm -rf` on whole skill directory.
- claude-md: `remove_section` strips managed section from
  `$CLAUDE_HOME/CLAUDE.md` (user content around preserved).
- statusline: `rm -f` on `.sh` file, then warning — remind user update/remove
  `"statusLine"` key in `$CLAUDE_HOME/settings.json` if still pointing at
  deleted path.
- Logs one `Removed <kind> '<name>' (<path>)` line.

## Internal patterns

- **Resolution local, not via `resolve_feature`.** `cmd-rm.sh` parses
  `command:` / `skill:` / `claude-md:` / `statusline:` prefix itself (in
  `resolve_installed`), checks installed state direct
  (`inst_command_path`, `inst_skill_path`, `claudemd_is_installed`,
  `inst_statusline_path`). Intentional — `resolve_feature` checks managed
  clone, wrong source of truth here. Keep prefix-parsing case statement in
  sync with `lib.sh::resolve_feature` and `cmd-show.sh` if syntax change.
- **No source-existence check.** Feature whose source removed from managed
  clone still removable from `$CLAUDE_HOME`.

## Domain dependencies

- `../../CLAUDE.md` — "filesystem is source of truth"; script's reliance on
  `installed_kind` over lockfile follows that.

## Cross-references

- [shared-lib.md](./shared-lib.md) — uses `inst_command_path`,
  `inst_skill_path` / `inst_skill_dir`, `claudemd_is_installed` /
  `remove_section`.
- [cmd-add.md](./cmd-add.md) — inverse op.
- [cli-entry.md](./cli-entry.md) — `uninstall.sh` does bulk variant of this
  against managed-clone listing.

## When to read the source

- Changing disambiguation (e.g. interactive prompt instead of `die` on
  ambiguity) → `scripts/cmd-rm.sh`.
- Adding `--all` flag (currently absent — only `update` and `uninstall.sh`
  do bulk ops) → `cmd-rm.sh`.