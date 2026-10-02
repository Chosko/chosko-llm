# Shared library

`scripts/lib.sh`: logging, frontmatter parsing, path helpers, source validation.

## Overview

Implementing file: `scripts/lib.sh`.

Sets default env vars on first source:
- `CHOSKO_LLM_HOME` → `$HOME/.chosko-llm` (managed clone).
- `CLAUDE_HOME` → `$HOME/.claude` (where features get installed).

`lib.sh` is sourced (`source lib.sh`) by every `scripts/cmd-*.sh`, never
executed directly.

This file covers the core helpers. The feature-kind helpers (claude-md,
statusline, hooks, kind resolution, `replaces:`, `requires:`):
[shared-lib-kinds.md](./shared-lib-kinds.md). The changelog readout:
[shared-lib-changelog.md](./shared-lib-changelog.md).

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

### Scope resolution
Lets a caller install into a per-project `.claude/` instead of the global
one. `ls`, `add`, `rm`, `update`, and `show` all consume it — each calls
`resolve_scope "$@"` as the first line after sourcing `lib.sh`, then re-sets
its positional parameters from `SCOPE_ARGS` before its own flag parsing runs.
Sourcing `lib.sh` without calling `resolve_scope` changes nothing.
- `CHOSKO_LLM_SCOPE` — `local` or `global`, default `global`.
- `SCOPE_ARGS` — array, empty by default. Safe to expand under `set -u` via
  `set -- ${SCOPE_ARGS[@]+"${SCOPE_ARGS[@]}"}` even when never assigned.
- `resolve_scope "$@"` — scans every argument for `--local` / `--global`
  (order-agnostic — the flag may appear anywhere in the arg list); `die`s if
  both appear. Sets `CHOSKO_LLM_SCOPE` and `SCOPE_ARGS` (args with the scope
  flag stripped, order and embedded whitespace preserved). In local scope,
  requires `$PWD/CLAUDE.md` to exist — `die`s naming the missing file and
  pointing at `/project-setup` otherwise — then sets
  `CLAUDE_HOME="$PWD/.claude"`, overriding any inherited `CLAUDE_HOME`. In
  global scope, `CLAUDE_HOME` is left untouched (env override still
  honoured). Local root is always `$PWD`, never a VCS query or upward walk —
  `--local` is an explicit "you are at the project root" contract.
- `scope_is_local` — 0 in local scope, 1 otherwise.
- `scope_label` — human-readable scope for log lines, e.g.
  `local (/path/to/repo/.claude)`.
- `scope_supports_kind <kind>` — 1 for the two kinds that only make sense in
  one scope, 0 for every other kind/scope combination. Two mirrored rules:
  `statusline` is GLOBAL-only (a status bar belongs to a terminal, not a repo);
  `hook` is LOCAL-only (a hook must be committed to the repo it governs — a
  cloud container clones the repo and nothing else, so a globally wired hook
  can never fire there).
- `scope_violation_message <kind>` — the `die` text for a kind
  `scope_supports_kind` just rejected. Lives in `lib.sh` so `cmd-add`,
  `cmd-rm` and `cmd-update` word both rules identically.
- `claudemd_target_path` / `claudemd_target_path_var <outvar>` (the `_var`
  form takes the local-scope parent directory with parameter expansion rather
  than `dirname`, which would put an exec back in) — the CLAUDE.md file
  claude-md artifacts read/write: `$CLAUDE_HOME/CLAUDE.md` in global scope,
  but `<cwd>/CLAUDE.md` (one directory up from `$CLAUDE_HOME`, which is
  `<cwd>/.claude` in local scope) in local scope — a project's CLAUDE.md
  lives at its root, not nested under `.claude/`. `claudemd_is_installed`,
  `claudemd_installed_version`, `inject_section`, and `remove_section` all
  call this instead of hardcoding `$CLAUDE_HOME/CLAUDE.md`, so every
  claude-md-consuming subcommand is scope-aware for free.

### Frontmatter
One scanner, `_FM_AWK`, with two `mode=` values — a second copy of the parser
would be a copy that drifts. It scans each file to the end rather than
`exit`ing at the closing `---` (a multi-file run cannot exit on the first file)
and clears `in_fm` there, so in both modes only the first `--- ... ---` block
is read.
- `parse_frontmatter <file>` — `mode=print`. Emits `key=value` lines, in file
  order, for eight recognized keys: `name`, `version`, `type`, `description`,
  `replaces`, `requires`, `event`, `matcher`. Quotes stripped. Unknown keys
  silently dropped. First four required in practice; `replaces` optional (kind
  migration, [shared-lib-kinds.md](./shared-lib-kinds.md) § Public API › Kind
  migration), `requires` optional on every kind (dependencies,
  [shared-lib-kinds.md](./shared-lib-kinds.md) § Public API › Dependencies),
  `event`/`matcher` read for hook kind only and ignored elsewhere. Split is on
  the FIRST colon, so a kind-prefixed value like `skill:task-engine` survives
  it intact.
- `read_frontmatter_field <file> <field>` — prints one field's value, empty if absent.
- `read_frontmatter_table <field-list> <file>…` — `mode=table`. ONE awk over
  every file given; prints `<file>` then one TAB-separated value per field, in
  the order `<field-list>` (a single space-separated string) names them, empty
  where the key is absent, first occurrence winning where it repeats. **Every
  path must exist and be readable** — awk aborts the whole run on one that is
  not, taking every file after it in the list with it, so the caller's own
  `-f` / `-r` guards stay the decider; that is the price of the batch. A file
  with no lines at all produces no output line, so read the result **by path,
  not by position**. Split each line with parameter expansion, **never
  `read -a`**: TAB is IFS whitespace, so `read -a` collapses two adjacent empty
  fields into one. TAB is also the field separator, so no requested field's
  value may contain one — a documented limit rather than a live case, since
  the keys read this way are versions and kind-prefixed specs.
- `read_frontmatter_fields <file> <field>…` — the parse-once reader for a
  caller needing two or more fields off the SAME block; it is
  `read_frontmatter_table` narrowed to one file, so the two cannot disagree
  about a value. Prints one line per requested field in the order given (empty
  line for an absent key), so the reader is one `read -r` per field:
  `{ IFS= read -r ver; IFS= read -r req; } < <(read_frontmatter_fields "$f"
  version requires)`. Line count always matches field count — no frontmatter
  value can carry a newline. Missing file yields empty values, not an error.
  One field → keep using `read_frontmatter_field`; a whole list of files → use
  the table directly and pay one awk for all of them.

### Path resolution
- `feature_path_var <outvar> <root> <kind> <name>` — **the one place a
  feature's path shape is written**; assigns rather than prints (§ Internal
  patterns), and returns non-zero on an unknown kind. Kinds: `command`,
  `skill`, `skill-dir`, `claude-md`, `statusline`, `hook`. Every named helper
  below is a printing wrapper over it.

Source paths in managed clone:
- `src_command_path <name>`  → `$CHOSKO_LLM_HOME/commands/<name>.md`
- `src_skill_path <name>`    → `$CHOSKO_LLM_HOME/skills/<name>/SKILL.md`
- `src_skill_dir <name>`     → `$CHOSKO_LLM_HOME/skills/<name>`
- `src_claudemd_path <name>` → `$CHOSKO_LLM_HOME/claude-md/<name>.md`
- `src_statusline_path <name>` → `$CHOSKO_LLM_HOME/statusline/<name>.sh`
- `src_hook_path <name>`       → `$CHOSKO_LLM_HOME/hooks/<name>.sh`
- `src_changelog_path`         → `$CHOSKO_LLM_HOME/CHANGELOG.md`. Takes no name —
  one file, not a per-feature artifact. `CHANGELOG.md` never installed into
  `$CLAUDE_HOME`, so no `inst_` twin.

Installed paths under `$CLAUDE_HOME` mirror same shape:
- `inst_command_path <name>`, `inst_skill_path <name>`, `inst_skill_dir <name>`,
  `inst_statusline_path <name>`, `inst_hook_path <name>`.
- `hook_settings_path` → `$CLAUDE_HOME/settings.json`. Hooks being local-only,
  this is always `<cwd>/.claude/settings.json` — the file that travels with
  the repo.

Export output:
- `export_dir_path` → `$CHOSKO_LLM_EXPORT_DIR` if set, else `$HOME/claude-exports`.
  Only place that path assembled; used by `cmd-export.sh`.

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

### Validation
- `require_versioned_source <file>` — `die`s if file missing or its
  frontmatter missing non-empty `version` or `name`. Called by
  `cmd-add` and `cmd-update` before copying. Never checks `replaces`.

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

- **Frontmatter parsing awk-only.** Adding a field means one more `key == "…"`
  clause in `_FM_AWK`'s allowlist, because the generic first-colon split
  already handles any value. Cheap, but never free: the allowlist is the only
  place a key becomes visible, so a new field that is not added there is
  silently dropped. Allowed tooling: `../../CLAUDE.md` § Things to avoid.
- **A helper that runs per row assigns; a helper that runs once prints.**
  `feature_path_var`, `claudemd_target_path_var`, `split_kind_spec` and
  `requires_specs_from_value_into` are the assigning forms; the printing helpers
  of the same name are wrappers over them and stay the readable default. The
  split is not stylistic — it is the fork budget in [cmd-ls.md](./cmd-ls.md)
  § Internal patterns, the caller the assigning forms exist for.
- **Path helpers only place** `$CHOSKO_LLM_HOME` and `$CLAUDE_HOME` should
  concatenate with subpaths (`../../CLAUDE.md` § Hard rules).
- Subcommand exit-code conventions live in subcommand scripts, not here.

## Domain dependencies

- `../../docs/authoring-guide.md` — defines frontmatter schema this lib
  parses. Any change to required fields must update both this file and
  authoring guide.

## Cross-references

- [cli-entry.md](./cli-entry.md) — which entry scripts source `lib.sh` and
  which deliberately do not (they must run before the managed clone is
  populated).
- Every `cmd-*.md` — sources `lib.sh`. See those files for how each helper
  consumed.

## When to read the source

- Adding/renaming frontmatter field → the `key == "…"` allowlist in `_FM_AWK` in
  `lib.sh`.
- Changing how many processes a caller spends reading frontmatter →
  `read_frontmatter_table` in `lib.sh` and the caller's own loop.
- Changing what makes source file installable → `require_versioned_source`
  in `lib.sh`.
- Changing scope semantics (flag parsing, local-root marker, which kinds are
  scope-restricted) → `resolve_scope` / `scope_is_local` / `scope_label` /
  `scope_supports_kind` in `lib.sh`.
- Changing where claude-md sections read/write in local scope →
  `claudemd_target_path_var` in `lib.sh`.
  `cmd-ls.sh::scan_claudemd` mirrors `claudemd_is_installed` /
  `claudemd_installed_version` — keep them in step per
  [cmd-ls.md](./cmd-ls.md) § Internal patterns.
