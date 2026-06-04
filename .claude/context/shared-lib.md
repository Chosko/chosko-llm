# Shared library

`scripts/lib.sh` is sourced by every `scripts/cmd-*.sh`. It defines logging,
frontmatter parsing, path helpers, and source validation.

## Overview

Implementing file: `scripts/lib.sh`.

It also sets default env vars on first source:
- `CHOSKO_LLM_HOME` → `$HOME/.chosko-llm` (managed clone).
- `CLAUDE_HOME` → `$HOME/.claude` (where features get installed).

`lib.sh` is sourced (`source lib.sh`), never executed directly.

## Public API

All functions live in `scripts/lib.sh`.

### Logging
- `log_info <msg>` / `log_warn <msg>` / `log_error <msg>` / `log_success <msg>` —
  write to stderr. Color is on if `NO_COLOR` is unset and stderr is a TTY (`[ -t 2 ]`).
  - `log_info` — blue `[info]` prefix.
  - `log_warn` — yellow `[warn]` prefix.
  - `log_error` — red `[error]` prefix.
  - `log_success` — green `[ok]` prefix. Use for successful installs, removals, and updates.
- `die <msg>` — `log_error` then `exit 1`.

### Stdout color variables
Set at lib.sh source time based on `NO_COLOR` and `[ -t 1 ]`. Empty when color
is disabled; scripts use them directly — never inline `\033[` escapes in `cmd-*.sh`.

- `C_GREEN` / `C_YELLOW` / `C_CYAN` / `C_BLUE` / `C_MAGENTA` / `C_DIM` / `C_BOLD` / `C_RESET`

Palette guidance:

*Status colors* (used in the STATUS column of `ls` and the `Status:` field of `show`):
- `C_GREEN` — success status (e.g. `up-to-date`).
- `C_YELLOW` — warning / attention (e.g. `updatable`).
- `C_DIM` — de-emphasised (e.g. `not installed`, `—` placeholders).
- `C_CYAN` — local-only highlight (e.g. `local only`).

*Kind colors* (used in the KIND column of `ls` and the `Kind:` field of `show`):
- `C_BLUE` — `command` kind.
- `C_MAGENTA` — `skill` kind.
- `C_CYAN` — `claude-md` kind. (Dual-use with `local only` status — acceptable since they appear in separate columns.)

*Structural*:
- `C_BOLD` — structural emphasis (e.g. header rows, `Usage:` headings, `show` header line).

Helper: `_use_color_stdout` — returns 0 when color should be applied to stdout.

### Frontmatter
- `parse_frontmatter <file>` — emits `key=value` lines for the four keys it
  recognizes: `name`, `version`, `type`, `description`. Reads only the first
  `--- ... ---` block. Quotes around values are stripped. Unknown keys are
  silently dropped.
- `read_frontmatter_field <file> <field>` — convenience: prints just the
  value of one field, or empty if absent.

### Path resolution
Source paths in the managed clone:
- `src_command_path <name>`  → `$CHOSKO_LLM_HOME/commands/<name>.md`
- `src_skill_path <name>`    → `$CHOSKO_LLM_HOME/skills/<name>/SKILL.md`
- `src_skill_dir <name>`     → `$CHOSKO_LLM_HOME/skills/<name>`
- `src_claudemd_path <name>` → `$CHOSKO_LLM_HOME/claude-md/<name>.md`

Installed paths under `$CLAUDE_HOME` mirror the same shape:
- `inst_command_path <name>`, `inst_skill_path <name>`, `inst_skill_dir <name>`.

### claude-md artifacts
A third feature kind. Instead of copying a file, a claude-md artifact injects
a managed section into `$CLAUDE_HOME/CLAUDE.md`, delimited by
`<!-- chosko-llm:<name>:begin v<version> -->` / `:end` comment markers so user
content is preserved.
- `claudemd_is_installed <name>` → 0 if a managed section exists.
- `claudemd_installed_version <name>` → version recorded in the begin marker.
- `inject_section <name> <version> <src_file>` → insert or replace the named
  section (body = `src_file` minus its frontmatter).
- `remove_section <name>` → delete the named section.

### Feature kind
- `feature_kind <name>` → `command | skill | both | none` (looks at managed
  clone).
- `installed_kind <name>` → same, but looks at `$CLAUDE_HOME`.
- `resolve_feature <spec>` — accepts `<name>`, `command:<name>`,
  `skill:<name>`, or `claude-md:<name>`. Prints two lines on stdout:
  `<kind>\n<name>`. Errors if the feature is not in the managed clone or if a
  bare name is ambiguous (matches more than one of command/skill/claude-md).
  Used by `cmd-add` / `cmd-update`.

### Validation
- `require_versioned_source <file>` — `die`s if the file is missing or its
  frontmatter is missing a non-empty `version` or `name`. Called by
  `cmd-add` and `cmd-update` before copying.

### Auto-upgrade state
Helpers over a gitignored key=value file `$CHOSKO_LLM_HOME/.auto-upgrade-state`
(keys: `enabled`, `last_run`). Used by `scripts/auto-upgrade.sh` and
`cmd-upgrade.sh`. See [cli-entry.md](./cli-entry.md) for the feature.
- `auto_upgrade_state_file` → prints the state-file path.
- `auto_upgrade_get <key>` / `auto_upgrade_set <key> <value>` → read/write one key.
- `auto_upgrade_enabled` → succeeds unless `enabled=false` (missing file/key =
  enabled, i.e. opt-in by default).
- `auto_upgrade_due` → succeeds when `last_run` is not today (calendar-day).

## Internal patterns

- **Frontmatter parsing is awk-only.** Adding a fifth field means changing
  the awk regex in `parse_frontmatter`. No yq/jq/python — see
  `../../CLAUDE.md` hard rules.
- **Path helpers are the *only* place** `$CHOSKO_LLM_HOME` and
  `$CLAUDE_HOME` should be concatenated with subpaths. New code must use the
  helpers; do not hardcode `~/.chosko-llm` / `~/.claude`.
- **`resolve_feature` is the source of truth** for `command:` / `skill:` /
  `claude-md:` prefix parsing. `cmd-rm.sh` and `cmd-show.sh` parse the prefix
  themselves (they resolve against installed/either kind, not source kind) —
  keep all three prefix parsers in sync if the syntax changes.
- **`die` exits 1, no other code.** Subcommand exit-code conventions live in
  the subcommand scripts, not here.

## Domain dependencies

- `../../docs/authoring-guide.md` — defines the frontmatter schema this lib
  parses. Any change to required fields must update both this file and the
  authoring guide.

## Cross-references

- [cli-entry.md](./cli-entry.md) — `install.sh`, `uninstall.sh`, and
  `bin/chosko-llm` deliberately do **not** source `lib.sh` (must run before
  the managed clone is populated). `scripts/auto-upgrade.sh`, invoked by the
  proxy, *does* source it for the `auto_upgrade_*` helpers.
- Every `cmd-*.md` — sources `lib.sh`. See those files for how each helper is
  consumed.

## When to read the source

- Adding or renaming a frontmatter field → `parse_frontmatter` in `lib.sh`.
- Changing how feature names resolve to source paths or how `command:` /
  `skill:` prefixes are parsed → `resolve_feature` in `lib.sh`.
- Changing what makes a source file installable → `require_versioned_source`
  in `lib.sh`.
