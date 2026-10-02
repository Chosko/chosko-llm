# Shared library: feature kinds

## Overview

Covers the feature-kind helpers of `scripts/lib.sh`: the claude-md, statusline
and hook kind helpers and kind resolution. The rest of `lib.sh`:
[shared-lib.md](./shared-lib.md). Built on these helpers:
- [shared-lib-migration.md](./shared-lib-migration.md) — kind migration
  (`replaces:`).
- [shared-lib-requires.md](./shared-lib-requires.md) — dependencies
  (`requires:`).

## Public API

### claude-md artifacts
Third feature kind. Instead of copying a file, injects a managed section into
the CLAUDE.md `claudemd_target_path` names ([shared-lib-scope.md](./shared-lib-scope.md) §
Scope resolution), delimited by
`<!-- chosko-llm:<name>:begin v<version> -->` / `:end` markers so user content
is preserved.
- `claudemd_is_installed <name>` → 0 if managed section exists.
- `claudemd_installed_version <name>` → version recorded in begin marker.
- `inject_section <name> <version> <src_file>` → insert/replace named
  section (body = `src_file` minus frontmatter).
- `remove_section <name>` → delete named section.

### statusline scripts
Fourth feature kind: status-bar shell script copied verbatim (not
wrapped) to `$CLAUDE_HOME/statusline/<name>.sh`. Frontmatter lives in bash
no-op heredoc (`: <<'CHOSKO_FRONTMATTER' ... CHOSKO_FRONTMATTER`) right
after shebang, so `parse_frontmatter`'s first-`---`-pair scan still
finds it while file stays directly executable.
- `print_statusline_prompt <name> <installed_path>` → prints
  copy-pasteable prompt telling user to have Claude Code session merge
  top-level `"statusLine"` key into `$CLAUDE_HOME/settings.json`. No
  jq/automated JSON editing — `cmd-add.sh` calls this after install instead.

### hooks
Fifth feature kind: script Claude Code runs on a hook event, copied verbatim
to `$CLAUDE_HOME/hooks/<name>.sh` and `chmod +x`'d. Frontmatter in the same
bash no-op heredoc statusline uses, plus `event:` (required) and `matcher:`
(optional) ([shared-lib-frontmatter.md](./shared-lib-frontmatter.md) § Frontmatter). LOCAL-ONLY kind
(see `scope_supports_kind` in [shared-lib-scope.md](./shared-lib-scope.md) § Scope
resolution).
- `require_hook_source <file>` → dies when `event:` missing. Runs alongside
  `require_versioned_source`; a hook with no event is unwireable, so it is
  refused rather than half-installed.
- `hook_wiring_label <event> <matcher>` → names the settings.json slot a hook
  occupies: `hooks.PreToolUse[matcher=AskUserQuestion]`, or `hooks.<event>`
  when the feature declares no matcher. Used by `cmd-update` to name the OLD
  slot when an update moves a hook, since settings.json carries no version of
  its own and the stale entry has to be removed by hand.
- `print_hook_prompt <name> <src_file>` → copy-pasteable prompt telling the
  user to have a Claude Code session merge this hook into the project's
  `settings.json` under `hooks.<event>` (and the `matcher` entry when the
  frontmatter names one). Wires `$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh`,
  NOT the absolute install path — settings.json is committed and travels to
  other machines and to cloud containers. Same no-jq reasoning as statusline.
  Called by `cmd-add.sh` after install, and by `cmd-update.sh` under the
  conditions in [cmd-update.md](./cmd-update.md) § Public API.

### Feature kind
- `skill_dir_is_managed <skill-dir>` → 0 when `SKILL.md` sits in that
  directory. **The one place the "is this a skill we manage" test is written.**
  A `skills/<dir>` without one — Claude Code's account-synced bucket
  `skills/synced/` — is installed but unmanaged: listed by `ls`, inspectable by
  `show`, passed over by `update --all` and `upgrade`, refused by `rm` (even
  under `--force`), by `update <name>` and by `add <name>`.
- `skill_is_unmanaged <name>` → the name-keyed wrapper: directory present under
  `$CLAUDE_HOME` and `skill_dir_is_managed` says no.
- `feature_kind <name>` → `command | skill | both | none` (checks managed clone).
- `installed_kind <name>` → same, checks `$CLAUDE_HOME`.
- `resolve_feature <spec>` — accepts `<name>`, `command:<name>`,
  `skill:<name>`, `claude-md:<name>`, `statusline:<name>`, or `hook:<name>`.
  Prints two lines on stdout: `<kind>\n<name>`. Errors if feature not in
  managed clone or bare name ambiguous (matches more than one of
  command/skill/claude-md/statusline/hook). Used by `cmd-add` / `cmd-update`.

## Internal patterns

- **`resolve_feature` is the source of truth** for kind-prefix parsing (every
  prefix § Feature kind lists). `cmd-rm.sh` and `cmd-show.sh` parse prefix
  themselves (resolve against installed/either kind, not source kind) — keep
  all three prefix parsers in sync if syntax changes.

## Domain dependencies

- None of its own; frontmatter schema: [shared-lib.md](./shared-lib.md) §
  Domain dependencies.

## Cross-references

- [shared-lib.md](./shared-lib.md) — the scope, frontmatter and path helpers
  the kind helpers here build on ([shared-lib-scope.md](./shared-lib-scope.md),
  [shared-lib-frontmatter.md](./shared-lib-frontmatter.md)).
- [cmd-add.md](./cmd-add.md), [cmd-rm.md](./cmd-rm.md),
  [cmd-update.md](./cmd-update.md), [cmd-ls.md](./cmd-ls.md),
  [cmd-show.md](./cmd-show.md) — the callers each helper above names.
- [shared-lib-migration.md](./shared-lib-migration.md),
  [shared-lib-requires.md](./shared-lib-requires.md) — the `replaces:` and
  `requires:` helpers built on the kind helpers here.

## When to read the source

- Changing how feature names resolve to source paths or how `command:` /
  `skill:` prefixes parsed → `resolve_feature` in `lib.sh`.
