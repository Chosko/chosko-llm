# Shared library

`scripts/lib.sh` sourced by every `scripts/cmd-*.sh`. Defines logging, frontmatter parsing, path helpers, source validation.

## Overview

Implementing file: `scripts/lib.sh`.

Sets default env vars on first source:
- `CHOSKO_LLM_HOME` → `$HOME/.chosko-llm` (managed clone).
- `CLAUDE_HOME` → `$HOME/.claude` (where features get installed).

`lib.sh` sourced (`source lib.sh`), never executed directly.

## Public API

All functions live in `scripts/lib.sh`.

### Logging
- `log_info <msg>` / `log_warn <msg>` / `log_error <msg>` / `log_success <msg>` —
  write to stderr. Color on if `NO_COLOR` unset and stderr TTY (`[ -t 2 ]`).
  - `log_info` — blue `[info]` prefix.
  - `log_warn` — yellow `[warn]` prefix.
  - `log_error` — red `[error]` prefix.
  - `log_success` — green `[ok]` prefix. Use for successful installs, removals, updates.
- `die <msg>` — `log_error` then `exit 1`.

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
- `C_MAGENTA` — `superseded` (kind-migration status, task 104): the old
  artifact on its way out.
- `C_BLUE` — `migration pending` (kind-migration status, task 104): the new
  artifact waiting to land.

The two kind-migration statuses deliberately differ from each other and from
`updatable`, so the two sides of one migration are distinguishable at a
glance. They reuse the kind-column colors, but never collide with them — the
STATUS and KIND columns are separate.

*Kind colors* (KIND column of `ls`, `Kind:` field of `show`):
- `C_BLUE` — `command` kind.
- `C_MAGENTA` — `skill` kind.
- `C_CYAN` — `claude-md` kind. (Dual-use w/ `local only` status — fine, separate columns.)
- `C_GREEN` — `statusline` kind. (Dual-use w/ `up-to-date` status — fine, separate columns.)
- `C_YELLOW` — `hook` kind. (Dual-use w/ `updatable` status — fine, separate columns.)

*Structural*:
- `C_BOLD` — structural emphasis (header rows, `Usage:` headings, `show` header line).

Helper: `_use_color_stdout` — returns 0 when color should apply to stdout.

### Scope resolution
Lets a caller install into a per-project `.claude/` instead of the global
one. `ls`, `add`, `rm`, `update`, and `show` all consume it (task 103) —
each calls `resolve_scope "$@"` as the first line after sourcing `lib.sh`,
then re-sets its positional parameters from `SCOPE_ARGS` before its own
flag parsing runs. Sourcing `lib.sh` without calling `resolve_scope`
changes nothing.
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
- `claudemd_target_path` (task 103) — prints the CLAUDE.md file claude-md
  artifacts read/write: `$CLAUDE_HOME/CLAUDE.md` in global scope, but
  `<cwd>/CLAUDE.md` (one directory up from `$CLAUDE_HOME`, which is
  `<cwd>/.claude` in local scope) in local scope — a project's CLAUDE.md
  lives at its root, not nested under `.claude/`. `claudemd_is_installed`,
  `claudemd_installed_version`, `inject_section`, and `remove_section` all
  call this instead of hardcoding `$CLAUDE_HOME/CLAUDE.md`, so every
  claude-md-consuming subcommand is scope-aware for free.

### Frontmatter
- `parse_frontmatter <file>` — emits `key=value` lines for five recognized keys:
  `name`, `version`, `type`, `description`, `replaces`. Reads only first
  `--- ... ---` block. Quotes stripped. Unknown keys silently dropped.
  `replaces` optional (kind migration, below); other four required in practice.
- `read_frontmatter_field <file> <field>` — prints one field's value, empty if absent.

### Path resolution
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
- `resolve_version` → unchanged output format (`raw_version` plus
  ` (<git describe>)` when available, `unknown` when VERSION missing); now
  reads *through* `raw_version` instead of re-doing the path + trim. Callers
  (`install.sh`, `cmd-version.sh`) untouched.

Never compare `resolve_version` outputs: no tags in this repo, so
`git describe --tags --always` yields bare sha that changes every commit.
`cmd-upgrade.sh` uses `raw_version` for exactly this reason.

### Changelog readout
- `print_changelog_range <old-version> <new-version>` → writes `CHANGELOG.md`
  sections for versions just pulled to **stderr**; returns 0 when it printed at
  least one section, 1 otherwise. Caller (`cmd-upgrade.sh`) uses return value to
  decide whether to fall back to raw `git log --oneline` dump.
  Range two-sided: new version's header inclusive, down to but excluding old
  version's. File descending semver, so single forward `awk` scan — no sort, no
  second pass, no temp file. Prints framing line via `log_info`; version bold,
  ` — <date>` dim, bullet's leading `- ` marker cyan, bullet text default.
  **Degrades, never fails**: missing/malformed/unreadable `CHANGELOG.md` returns
  1 silently (clones predating the feature are normal); missing header for new
  version logs one line and prints nothing; missing header for old version
  prints only the newest section; unrecognised line inside a section passed
  through indented and uncoloured rather than dropped. Never changes caller's
  exit code.

**Lives in `lib.sh`, not `cmd-upgrade.sh`**, for two reasons: this is where
colour handling belongs (`cmd-*.sh` never inline `\033[` escapes — see Internal
patterns), and the block goes to stderr, so it gates on `_use_color` (the
predicate `log_info` and friends use: `NO_COLOR` unset **and** `[ -t 2 ]`), NOT
the `C_*` variables, which are gated on *stdout* being a TTY. Colour off →
every escape empty string, layout and markers unchanged.

### claude-md artifacts
Third feature kind. Instead of copying file, injects managed section into
`$CLAUDE_HOME/CLAUDE.md`, delimited by
`<!-- chosko-llm:<name>:begin v<version> -->` / `:end` markers so user content preserved.
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
(optional) — both read by `parse_frontmatter`, ignored on every other kind.
LOCAL-ONLY kind (see `scope_supports_kind` above).
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
  Called by `cmd-add.sh` after install, and by `cmd-update.sh` only when the
  hook was not already installed (re-copying a script cannot re-wire JSON).

### Feature kind
- `feature_kind <name>` → `command | skill | both | none` (checks managed clone).
- `installed_kind <name>` → same, checks `$CLAUDE_HOME`.
- `resolve_feature <spec>` — accepts `<name>`, `command:<name>`,
  `skill:<name>`, `claude-md:<name>`, `statusline:<name>`, or `hook:<name>`.
  Prints two lines on stdout: `<kind>\n<name>`. Errors if feature not in
  managed clone or bare name ambiguous (matches more than one of
  command/skill/claude-md/statusline/hook). Used by `cmd-add` / `cmd-update`.

### Kind migration (`replaces:`)
Install copy-based, never prunes — feature changing kind
(`commands/<n>.md` → `skills/<n>/SKILL.md`) would leave stale installed
artifact beside new one under same `/<n>` name. Superseding feature declares
`replaces: <kind>:<name>` in frontmatter; helpers act on that. No state file —
fact rides same `git pull` as rename.
- `src_path_for_kind <kind> <name>` → managed-clone source file for that kind;
  non-zero on unknown kind.
- `parse_replaces_spec <spec>` → splits `command:foo` into `kind\nname`;
  non-zero if no recognized prefix.
- `artifact_is_installed <kind> <name>` → 0 if installed under `$CLAUDE_HOME`.
- `remove_installed_artifact <kind> <name>` → deletes with `cmd-rm` semantics
  per kind (`rm -f` command/statusline/hook, `rm -rf` skill, `remove_section`
  claude-md).
- `apply_replaces <kind> <name>` → post-install hook. Reads the just-installed
  feature's `replaces:`; if named artifact installed, removes it and logs
  `Migrated <old-kind> '<name>' -> <new-kind> '<name>'`. Silent when key absent
  or old artifact not installed. Warns + no-ops on malformed spec or
  self-replacement. Called by `cmd-add` (single-feature) and `cmd-update`
  (single-feature + `--all` migration path).
- `find_replacement <old-kind> <old-name>` → scans managed clone
  (commands, skills, claude-md, statusline, hooks) for feature declaring
  `replaces: <old-kind>:<old-name>`. Prints `<kind>\n<name>` on first hit,
  returns 1 on none. Used by `cmd-update --all`'s stale-artifact branch,
  and by `cmd-ls`/`cmd-show` (task 104) to flag a `local only` row as
  `superseded`.
- `check_migration_pending <kind> <name>` (task 104) → the mirror image of
  `find_replacement`, asked from the *new* side. For a clone feature not
  yet installed, reads its own `replaces:`, and if the named artifact is
  currently installed (`artifact_is_installed`), prints `<old-kind>\n
  <old-name>` and returns 0 — meaning a plain `add` would leave two
  artifacts side by side instead of completing the migration. Returns 1
  with no output when `replaces:` is absent, malformed, or names
  something not installed. Used by `cmd-ls`/`cmd-show` to flag a `not
  installed` row as `migration pending`, and by `cmd-show`'s ambiguous-name
  `die` to name the pending migration in its error.

### Validation
- `require_versioned_source <file>` — `die`s if file missing or its
  frontmatter missing non-empty `version` or `name`. Called by
  `cmd-add` and `cmd-update` before copying. Never checks `replaces` —
  that key always optional.

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

- **Frontmatter parsing awk-only.** Adding sixth field means changing
  awk regex in `parse_frontmatter` (the fifth, `replaces`, already cost that
  edit). No yq/jq/python — see `../../CLAUDE.md` hard rules.
- **Migration is declarative, not a map.** `replaces:` lives on the feature
  that supersedes the old one, so no rename map / migration script / state
  file outside the filesystem. `--all` resolves migration from the *stale*
  side because the replacement isn't installed yet — iterating installed
  artifacts is the only place the stale one is visible.
- **Path helpers only place** `$CHOSKO_LLM_HOME` and
  `$CLAUDE_HOME` should concatenate with subpaths. New code must use
  helpers; don't hardcode `~/.chosko-llm` / `~/.claude`.
- **`resolve_feature` source of truth** for `command:` / `skill:` /
  `claude-md:` / `statusline:` prefix parsing. `cmd-rm.sh` and `cmd-show.sh`
  parse prefix themselves (resolve against installed/either kind,
  not source kind) — keep all three prefix parsers in sync if syntax
  changes.
- **`die` exits 1, no other code.** Subcommand exit-code conventions live in
  subcommand scripts, not here.

## Domain dependencies

- `../../docs/authoring-guide.md` — defines frontmatter schema this lib
  parses. Any change to required fields must update both this file and
  authoring guide.

## Cross-references

- [cli-entry.md](./cli-entry.md) — `install.sh`, `uninstall.sh`, and
  `bin/chosko-llm` deliberately do **not** source `lib.sh` (must run before
  managed clone populated). `scripts/auto-upgrade.sh`, invoked by
  proxy, *does* source it for `auto_upgrade_*` helpers.
- Every `cmd-*.md` — sources `lib.sh`. See those files for how each helper
  consumed.

## When to read the source

- Adding/renaming frontmatter field → `parse_frontmatter` in `lib.sh`.
- Changing how feature names resolve to source paths or how `command:` /
  `skill:` prefixes parsed → `resolve_feature` in `lib.sh`.
- Changing what makes source file installable → `require_versioned_source`
  in `lib.sh`.
- Changing kind-migration semantics (spec syntax, deletion rules, scan order)
  → `apply_replaces` / `find_replacement` / `check_migration_pending` /
  `remove_installed_artifact` in `lib.sh`.
- Changing scope semantics (flag parsing, local-root marker, which kinds are
  scope-restricted) → `resolve_scope` / `scope_is_local` / `scope_label` /
  `scope_supports_kind` in `lib.sh`.
- Changing where claude-md sections read/write in local scope →
  `claudemd_target_path` in `lib.sh`.
- Changing changelog range extraction, its layout/colours, or its
  degrade-never-fail branches → `print_changelog_range` in `lib.sh` (the awk
  scan and the formatting loop are both there); the caller's suppression rule
  lives in `cmd-upgrade.sh`.