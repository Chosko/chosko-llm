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

- `C_GREEN` / `C_YELLOW` / `C_CYAN` / `C_DIM` / `C_BOLD` / `C_RESET`

Palette guidance:
- `C_GREEN` — success status or values (e.g. `up-to-date` in `ls`).
- `C_YELLOW` — warning / attention (e.g. `updatable`).
- `C_CYAN` — local-only or informational highlight (e.g. `local only`).
- `C_DIM` — de-emphasised content (e.g. `not installed`, KIND column, `—` placeholders).
- `C_BOLD` — structural emphasis (e.g. header rows, `Usage:` headings).

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
- `src_command_path <name>` → `$CHOSKO_LLM_HOME/commands/<name>.md`
- `src_skill_path <name>`   → `$CHOSKO_LLM_HOME/skills/<name>/SKILL.md`
- `src_skill_dir <name>`    → `$CHOSKO_LLM_HOME/skills/<name>`

Installed paths under `$CLAUDE_HOME` mirror the same shape:
- `inst_command_path <name>`, `inst_skill_path <name>`, `inst_skill_dir <name>`.

### Feature kind
- `feature_kind <name>` → `command | skill | both | none` (looks at managed
  clone).
- `installed_kind <name>` → same, but looks at `$CLAUDE_HOME`.
- `resolve_feature <spec>` — accepts `<name>`, `command:<name>`, or
  `skill:<name>`. Prints two lines on stdout: `<kind>\n<name>`. Errors if the
  feature is not in the managed clone or if a bare name is ambiguous (matches
  both a command and a skill). Used by `cmd-add` / `cmd-update`.

### Validation
- `require_versioned_source <file>` — `die`s if the file is missing or its
  frontmatter is missing a non-empty `version` or `name`. Called by
  `cmd-add` and `cmd-update` before copying.

## Internal patterns

- **Frontmatter parsing is awk-only.** Adding a fifth field means changing
  the awk regex in `parse_frontmatter`. No yq/jq/python — see
  `../../CLAUDE.md` hard rules.
- **Path helpers are the *only* place** `$CHOSKO_LLM_HOME` and
  `$CLAUDE_HOME` should be concatenated with subpaths. New code must use the
  helpers; do not hardcode `~/.chosko-llm` / `~/.claude`.
- **`resolve_feature` is the source of truth** for `command:` / `skill:`
  prefix parsing. `cmd-rm.sh` parses the prefix itself because it resolves
  against installed kind, not source kind — keep these two prefix parsers in
  sync if syntax changes.
- **`die` exits 1, no other code.** Subcommand exit-code conventions live in
  the subcommand scripts, not here.

## Domain dependencies

- `../../docs/authoring-guide.md` — defines the frontmatter schema this lib
  parses. Any change to required fields must update both this file and the
  authoring guide.

## Cross-references

- [cli-entry.md](./cli-entry.md) — `install.sh`, `uninstall.sh`, and
  `bin/chosko-llm` deliberately do **not** source `lib.sh` (must run before
  the managed clone is populated).
- Every `cmd-*.md` — sources `lib.sh`. See those files for how each helper is
  consumed.

## When to read the source

- Adding or renaming a frontmatter field → `parse_frontmatter` in `lib.sh`.
- Changing how feature names resolve to source paths or how `command:` /
  `skill:` prefixes are parsed → `resolve_feature` in `lib.sh`.
- Changing what makes a source file installable → `require_versioned_source`
  in `lib.sh`.
