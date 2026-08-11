# cmd-rm

## Overview

`scripts/cmd-rm.sh` delete installed feature from `$CLAUDE_HOME`. Resolve names against **installed** state, not managed clone — user-authored feature with no source still removable.

## Public API

CLI:
- `chosko-llm rm <feature>` — `<feature>` = `<name>`, `command:<name>`,
  `skill:<name>`, `claude-md:<name>`, `statusline:<name>`, or `hook:<name>`.
- `chosko-llm rm <feature> --local` / `--global` — scope, see below.
- `-h` / `--help` — usage, exit 0.

Exit codes:
- 0 success.
- 1 (via `die`) if: no arg, `<name>` ambiguous (more than one of
  command/skill/claude-md/statusline installed) without prefix, nothing
  matching installed, or the resolved kind is `statusline` with `--local`.

Side effects:
- Commands: `rm -f` on `.md` file.
- Skills: `rm -rf` on whole skill directory.
- claude-md: `remove_section` strips managed section from
  `claudemd_target_path` (user content around preserved).
  `claudemd_target_path` is `$CLAUDE_HOME/CLAUDE.md` globally but
  `<cwd>/CLAUDE.md` in local scope (task 103).
- hook: `rm -f` on `.sh` file, then warning — remind user to drop the entry
  from `hook_settings_path` too, since wiring pointing at a deleted script
  fails on every session.
- statusline: `rm -f` on `.sh` file, then warning — remind user update/remove
  `"statusLine"` key in `$CLAUDE_HOME/settings.json` if still pointing at
  deleted path. Global-only — `--local` `die`s before reaching this branch.
- Logs one `Removed <kind> '<name>' (<path>) (scope: <scope>)` line.

**Scope (`--local` / `--global`, task 103).** First line after sourcing
`lib.sh` calls `resolve_scope "$@"` then re-sets `$@` from `SCOPE_ARGS`; the
existing prefix-parsing/`resolve_installed` logic runs unchanged on the
cleaned arguments. No flag = `--global`, byte-identical to pre-103
behavior. Right after `resolve_installed` determines `kind`,
`scope_supports_kind "$kind"` gates the removal — `die`s naming statusline
global-only if it fails, before any filesystem check.

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
  `remove_section`, scope helpers `resolve_scope` / `scope_supports_kind` /
  `claudemd_target_path`.
- [cmd-add.md](./cmd-add.md) — inverse op.
- [cli-entry.md](./cli-entry.md) — `uninstall.sh` does bulk variant of this
  against managed-clone listing.

## When to read the source

- Changing disambiguation (e.g. interactive prompt instead of `die` on
  ambiguity) → `scripts/cmd-rm.sh`.
- Adding `--all` flag (currently absent — only `update` and `uninstall.sh`
  do bulk ops) → `cmd-rm.sh`.
- Changing scope behavior (statusline refusal) → `resolve_scope` call and
  `scope_supports_kind` check in `cmd-rm.sh`.