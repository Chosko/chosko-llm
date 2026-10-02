# Shared library

`scripts/lib.sh` core: logging, colors, version, auto-upgrade state; hub for the
rest of `lib.sh`.

## Overview

Implementing file: `scripts/lib.sh`.

Sets default env vars on first source:
- `CHOSKO_LLM_HOME` → `$HOME/.chosko-llm` (managed clone).
- `CLAUDE_HOME` → `$HOME/.claude` (where features get installed).

`lib.sh` is sourced (`source lib.sh`) by every `scripts/cmd-*.sh`, never
executed directly.

This file covers the core helpers and the conventions shared by every part of
`lib.sh`. The rest of `lib.sh`:
- [shared-lib-scope.md](./shared-lib-scope.md) — scope resolution and path
  resolution.
- [shared-lib-frontmatter.md](./shared-lib-frontmatter.md) — frontmatter
  parsing and source validation.
- [shared-lib-kinds.md](./shared-lib-kinds.md) — claude-md, statusline and
  hook kind helpers, kind resolution.
- [shared-lib-migration.md](./shared-lib-migration.md) — kind migration
  (`replaces:`).
- [shared-lib-requires.md](./shared-lib-requires.md) — dependencies
  (`requires:`).
- [shared-lib-changelog.md](./shared-lib-changelog.md) — the changelog readout.

## Public API

### Logging
- `log_info <msg>` / `log_warn <msg>` / `log_error <msg>` / `log_success <msg>` —
  write to stderr. Color on if `NO_COLOR` unset and stderr TTY (`[ -t 2 ]`).
  - `log_info` — blue `[info]` prefix.
  - `log_warn` — yellow `[warn]` prefix.
  - `log_error` — red `[error]` prefix.
  - `log_success` — green `[ok]` prefix. Use for successful installs, removals, updates.
- `die <msg>` — `log_error` then `exit 1`, never any other code.

### Stdout color variables
Set at lib.sh source time based on `NO_COLOR` and `[ -t 1 ]`. Empty when color
disabled; scripts use directly — never inline `\033[` escapes in `cmd-*.sh`.

- `C_GREEN` / `C_YELLOW` / `C_CYAN` / `C_BLUE` / `C_MAGENTA` / `C_DIM` / `C_BOLD` / `C_RESET`

Palette guidance:

*Status colors* (STATUS column of `ls`, `Status:` field of `show`):
- `C_GREEN` — success status (e.g. `up-to-date`).
- `C_YELLOW` — warning / attention (e.g. `updatable`).
- `C_DIM` — de-emphasised (e.g. `not installed`, `—` placeholders).
- `C_CYAN` — local-only highlight (e.g. `local only`).
- `C_MAGENTA` — `superseded` (kind-migration status): the old artifact on its
  way out.
- `C_BLUE` — `migration pending` (kind-migration status): the new artifact
  waiting to land.

The two kind-migration statuses deliberately differ from each other and from
`updatable`, so the two sides of one migration are distinguishable at a
glance.

*Kind colors* (KIND column of `ls`, `Kind:` field of `show`):
- `C_BLUE` — `command` kind.
- `C_MAGENTA` — `skill` kind.
- `C_CYAN` — `claude-md` kind.
- `C_GREEN` — `statusline` kind.
- `C_YELLOW` — `hook` kind.

The kind-migration statuses reuse kind-column colors, and every status/kind
color pair shared across the two lists (e.g. `C_CYAN` = `local only` and
`claude-md`) is fine: the STATUS and KIND columns are separate, so they never
collide.

*Structural*:
- `C_BOLD` — structural emphasis (header rows, `Usage:` headings, `show` header line).

Helper: `_use_color_stdout` — returns 0 when color should apply to stdout.

### Version
- `raw_version` → trimmed contents of `$CHOSKO_LLM_HOME/VERSION`, empty when
  file absent. Only place VERSION path + trim written. Bare semver, nothing
  appended — so two reads taken either side of a pull are comparable.
- `resolve_version` → `raw_version` plus ` (<git describe>)` when available,
  `unknown` when VERSION missing; reads *through* `raw_version`. Callers:
  `install.sh`, `cmd-version.sh`.

Never compare `resolve_version` outputs: no tags in this repo, so
`git describe --tags --always` yields bare sha that changes every commit.
`cmd-upgrade.sh` uses `raw_version` for exactly this reason.

### Auto-upgrade state
Helpers over gitignored key=value file `$CHOSKO_LLM_HOME/.auto-upgrade-state`
(keys: `enabled`, `last_run`). Used by `scripts/auto-upgrade.sh` and
`cmd-upgrade.sh`. See [cli-entry.md](./cli-entry.md) for feature.
- `auto_upgrade_state_file` → prints state-file path.
- `auto_upgrade_get <key>` / `auto_upgrade_set <key> <value>` → read/write one key.
- `auto_upgrade_enabled` → succeeds unless `enabled=false` (missing file/key =
  enabled, opt-in by default).
- `auto_upgrade_due` → succeeds when `last_run` not today (calendar-day).

## Internal patterns

- **A helper that runs per row assigns; a helper that runs once prints.**
  `feature_path_var`, `claudemd_target_path_var`, `split_kind_spec` and
  `requires_specs_from_value_into` are the assigning forms; the printing helpers
  of the same name are wrappers over them and stay the readable default. The
  split is not stylistic — it is the fork budget in [cmd-ls-render.md](./cmd-ls-render.md)
  § Internal patterns, the caller the assigning forms exist for.
- Subcommand exit-code conventions live in subcommand scripts, not here.

## Domain dependencies

- `../../docs/authoring-guide.md` — defines frontmatter schema this lib
  parses. Any change to required fields must update both
  [shared-lib-frontmatter.md](./shared-lib-frontmatter.md) and authoring guide.

## Cross-references

- [cli-entry.md](./cli-entry.md) — which entry scripts source `lib.sh` and
  which deliberately do not (they must run before the managed clone is
  populated).
- Every `cmd-*.md` — sources `lib.sh`. See those files for how each helper
  consumed.

## When to read the source

- Per helper: the § When to read the source of the file that documents it
  (list in § Overview).
