# Shared library

`scripts/lib.sh`: logging, frontmatter parsing, path helpers, source validation.

## Overview

Implementing file: `scripts/lib.sh`.

Sets default env vars on first source:
- `CHOSKO_LLM_HOME` → `$HOME/.chosko-llm` (managed clone).
- `CLAUDE_HOME` → `$HOME/.claude` (where features get installed).

`lib.sh` is sourced (`source lib.sh`) by every `scripts/cmd-*.sh`, never
executed directly.

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
  migration, below), `requires` optional on every kind (dependencies, below),
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

### Changelog readout

Two consumers: `cmd-upgrade.sh` (stderr, range just pulled) and
`cmd-changelog.sh` (stdout, user-chosen selection). Everything below is shared
between them except the colour gate.

Parser contract for `CHANGELOG.md`: `^## ` introduces a section, the first
whitespace-delimited token after it is the version, everything until the next
`^## ` is the body, and anything above the first `## ` is preamble and never
printed.

- `_render_changelog_sections <body> <fd> <color-predicate>` → **the single
  formatter.** Writes raw section text to file descriptor `<fd>` in the shared
  layout: two-space version indent, four-space bullets, blank line between
  sections and one after the block; version bold, ` — <date>` dim, bullet's
  leading ASCII `- ` marker cyan, bullet's `**Subject**` span bold, rest of the
  bullet text default; unrecognised line inside a section passed through
  indented and uncoloured rather than dropped.
  Bold spans go through `_render_bullet_markup <text> <on> <off>`, which returns
  its result in `_BULLET_MARKUP_OUT` — **not on stdout**: a command substitution
  would fork a subshell per bullet. With colour off `<on>`/`<off>` are empty, so
  the `**` markers are **stripped**, never printed literally; an unpaired `**`
  is left as the source wrote it.
  `<color-predicate>` is the NAME of a function returning 0 when colour applies
  to that stream. **It is a parameter, not read off `<fd>`, on purpose**:
  `changelog --since` may hand its output to a pager, at which point fd 1 is a
  pipe, and gating on the write fd would silently strip every escape from
  exactly the case that wants them. Both callers go through here so the two
  presentations cannot drift.
- `print_changelog_range <old-version> <new-version>` → writes `CHANGELOG.md`
  sections for versions just pulled to **stderr**; returns 0 when it printed at
  least one section, 1 otherwise. Caller (`cmd-upgrade.sh`) uses return value to
  decide whether to fall back to raw `git log --oneline` dump.
  Range two-sided: new version's header inclusive, down to but **excluding** old
  version's — the user already had that one. File descending semver, so single
  forward `awk` scan — no sort, no second pass, no temp file. Prints framing
  line via `log_info`, then delegates layout to `_render_changelog_sections`
  with fd 2 and `_use_color`.
  **Degrades, never fails**: missing/malformed/unreadable `CHANGELOG.md` returns
  1 silently (clones predating the feature are normal); missing header for new
  version logs one line and prints nothing; missing header for old version
  prints only the newest section. Never changes caller's exit code.
- `changelog_since_kind <value>` → classifies a `changelog --since` value into
  one of three **disjoint** forms and prints it: `version` (`1.10.0`), `date`
  (`2026-08-01`), `duration` (`30d` / `2w` / `6mo` / `1y`). Returns 1, printing
  nothing, on anything else. Disjointness is why `--since` auto-detects instead
  of carrying one flag per form.
- `changelog_duration_to_date <duration>` → the `YYYY-MM-DD` that many units
  before today. GNU `date -d` first, BSD `date -v` second, pure-awk
  civil-calendar conversion (Howard Hinnant's `days_from_civil` /
  `civil_from_days`) last, so a shell with neither still answers — **no new
  dependency for date maths**. The awk fallback approximates a month as 30 days
  and a year as 365; the two `date` paths do real calendar arithmetic.
- `select_changelog_sections <kind> <value>` → prints matching sections
  verbatim on stdout. `version`
  kind takes every section from the newest down to and **including** `<value>`'s
  (matched on the header's first token, so a version absent from the file
  matches nothing rather than guessing); `date` kind takes every section whose
  header carries a date on or after `<value>`, string-compared — and scans the
  whole file, not a prefix, because descending-semver order is
  non-chronological at this repo's one history merge. Returns 1, printing
  nothing, when the file is missing or nothing matched; the caller's handling:
  [cmd-changelog.md](./cmd-changelog.md) § Public API.
  Inclusive version bound is the deliberate mirror of `print_changelog_range`'s
  exclusive one: "since 1.10.0" reads as "1.10.0 and everything after".
- `terminal_height` → `$LINES`, else `tput lines`, else the constant 24. Used
  to decide whether a rendered block fits one screen. Falls back to a constant
  rather than taking a dependency — `tput` is absent often enough on the bare
  git-bash that is this CLI's primary platform.

**Lives in `lib.sh`, not in either `cmd-*.sh`**, for two reasons: this is where
colour handling belongs (`cmd-*.sh` never inline `\033[` escapes — see § Stdout
color variables), and the two streams need different gates. Stderr output
gates on `_use_color`, the predicate `log_info` and friends use (§ Logging);
stdout output gates on the stdout predicate (`_use_color_stdout` / the `C_*`
variables' condition), captured before any redirection — and that is the
predicate each caller hands `_render_changelog_sections`. Using either on the
wrong stream produces escapes in redirected output. Colour off → every escape
empty string, layout and bullet markers unchanged.

### claude-md artifacts
Third feature kind. Instead of copying a file, injects a managed section into
the CLAUDE.md `claudemd_target_path` names (§ Scope resolution), delimited by
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
(optional) (§ Frontmatter). LOCAL-ONLY kind (see `scope_supports_kind` above).
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

### Kind migration (`replaces:`)
Install copy-based, never prunes — feature changing kind
(`commands/<n>.md` → `skills/<n>/SKILL.md`) would leave stale installed
artifact beside new one under same `/<n>` name. Superseding feature declares
`replaces: <kind>:<name>` in frontmatter; helpers act on that. No rename map,
migration script or state file — the fact rides the same `git pull` as the
rename.
- `src_path_for_kind <kind> <name>` → managed-clone source file for that kind;
  non-zero on unknown kind.
- `split_kind_spec <kind-outvar> <name-outvar> <spec>` → the fork-free
  authority for the kind-prefix split; assigns rather than prints, non-zero if
  no recognized prefix.
- `parse_replaces_spec <spec>` → splits `command:foo` into `kind\nname`;
  non-zero if no recognized prefix. A printing wrapper over `split_kind_spec`.
- `artifact_is_installed <kind> <name>` → 0 if installed under `$CLAUDE_HOME`.
  Its `skill` arm calls `skill_dir_is_managed` (§ Feature kind), not `[ -d ]`,
  which is what keeps `apply_replaces` → `remove_installed_artifact` from
  `rm -rf`ing an unmanaged directory.
- `remove_installed_artifact <kind> <name>` → deletes with `cmd-rm` semantics
  per kind (`rm -f` command/statusline/hook, `rm -rf` skill, `remove_section`
  claude-md).
- `apply_replaces <kind> <name>` → post-install hook. Reads the just-installed
  feature's `replaces:`; if named artifact installed, removes it and logs
  `Migrated <old-kind> '<name>' -> <new-kind> '<name>'`. Silent when key absent
  or old artifact not installed. Warns + no-ops on malformed spec or
  self-replacement. Called by `cmd-add` (single-feature) and `cmd-update`
  (single-feature + `--all` migration path).
- **The `replaces:` index** — `_build_replaces_index` fills
  `_REPLACES_BY_FILE` (clone source path → its `replaces:` value) and
  `_REPLACES_CLAIMED_BY` (`<old-kind>:<old-name>` → `<kind>:<name>`) from ONE
  `read_frontmatter_table` over the whole clone, at most once per process, on
  first use. Both probes below read it. Kind order in the build (commands,
  skills, claude-md, statusline, hooks) and the lexical globs within each kind
  are what decide which claimant is first. **No state file** — it lives in the
  process and dies with it, and it maps only the clone, which no command
  mutates while it runs. The installed side, which `add`/`rm`/`update` *do*
  mutate, is deliberately not cached: `artifact_is_installed` still asks the
  filesystem every time.
- `find_replacement <old-kind> <old-name>` → which clone feature declares
  `replaces: <old-kind>:<old-name>`. Prints `<kind>\n<name>` on the first
  claimant, returns 1 on none. Used by `cmd-update --all`'s stale-artifact
  branch, and by `cmd-ls`/`cmd-show` to flag a `local only` row as
  `superseded`.
- `check_migration_pending <kind> <name>` → the mirror image of
  `find_replacement`, asked from the *new* side. For a clone feature not
  yet installed, takes its own `replaces:` from the index, and if the named
  artifact is currently installed (`artifact_is_installed`), prints
  `<old-kind>\n<old-name>` and returns 0 — meaning a plain `add` would leave two
  artifacts side by side instead of completing the migration. Returns 1
  with no output when `replaces:` is absent, malformed, or names
  something not installed. Used by `cmd-ls`/`cmd-show` to flag a `not
  installed` row as `migration pending`, and by `cmd-show`'s ambiguous-name
  `die` to name the pending migration in its error.

### Dependencies (`requires:`)
`requires:` names features this one reads a file out of. Flat, one level
deep, unversioned, non-transitive — a declaration, never a graph. `cmd-add`
installs what a feature names before installing it; `cmd-rm` refuses to
remove a feature something installed still requires.
- `requires_specs <file>` → one kind-prefixed spec per line, one per
  comma-separated entry of `requires:`. Whitespace around commas and around
  the kind colon squeezed out first, empty entries dropped. Each entry
  validated through `parse_replaces_spec` (§ Internal patterns). Prints
  nothing, returns 0, when the key is absent or empty.
  **`die`s on an entry with no kind prefix** rather than skipping it silently:
  the key exists to catch a dangling reference at install time, and a typo
  that parsed to nothing would defeat that. So call it through a command
  substitution (`specs="$(requires_specs "$f")" || exit 1`), NEVER a process
  substitution — there the `die` would kill only the subshell and leave the
  caller running.
- `requires_specs_lenient <file>` → the non-fatal sibling; `requires_specs` is
  a strict filter over it, re-reading the raw value only on its `die` path so
  the happy path parses the frontmatter once, not twice. Reads the
  `requires:` value and delegates to `requires_specs_from_value`, so it prints
  `ok<TAB><spec>` per well-formed entry, `bad<TAB><entry>` per entry with no
  kind prefix, nothing when the key is absent. For read-only consumers only —
  `cmd-ls`'s REQUIRES column, which must not be taken down by one typo in one
  unrelated feature; install- and removal-time callers use `requires_specs`
  and stay fatal.
- `requires_specs_from_value_into <value>` → the ONE place the value is
  actually split and trimmed, taking the raw string instead of a path so a
  caller that already parsed the file for another field doesn't parse it
  again — which is what `cmd-ls` does, once per row. Leaves its result in the
  **global array `REQUIRES_SPECS`** (`ok<TAB><spec>` / `bad<TAB><entry>` per
  element) so a looping caller needs no process substitution;
  `resolve_scope`/`SCOPE_ARGS` set that precedent. Split + both trims are
  parameter expansion. The three steps, in order: leading space, trailing
  space, then the FIRST colon's surroundings — hence a `%%`/`#` split on the
  last and not every colon.
- `requires_specs_from_value <value>` → the printing sibling; formats what
  `_into` left in `REQUIRES_SPECS`, one line per element.

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
- **`split_kind_spec` parses two keys, not one.** `requires:` reuses it for
  every entry rather than growing a second kind-prefix parser, so `replaces:
  skill:x` and `requires: skill:x` can never disagree about what a spec means.
- **Migration is declarative, not a map** (§ Kind migration). `--all` resolves
  migration from the *stale* side because the replacement isn't installed
  yet — iterating installed artifacts is the only place the stale one is
  visible.
- **Path helpers only place** `$CHOSKO_LLM_HOME` and `$CLAUDE_HOME` should
  concatenate with subpaths (`../../CLAUDE.md` § Hard rules).
- **`resolve_feature` is the source of truth** for kind-prefix parsing (every
  prefix § Feature kind lists). `cmd-rm.sh` and `cmd-show.sh` parse prefix
  themselves (resolve against installed/either kind, not source kind) — keep
  all three prefix parsers in sync if syntax changes.
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
- Changing what `requires:` accepts, how entries are split/trimmed, or whether
  a malformed entry dies rather than being skipped →
  `requires_specs_from_value_into` (the split/trim),
  `requires_specs_lenient` (the file-reading wrapper) and
  `requires_specs` (the strict filter over it) in
  `lib.sh`, plus `split_kind_spec` which validates each entry. The
  install-time and removal-time behaviour built on it lives in `cmd-add.sh`
  (`install_requires`) and `cmd-rm.sh` (the dependents guard) — see
  [cmd-add.md](./cmd-add.md) and [cmd-rm.md](./cmd-rm.md).
- Changing how feature names resolve to source paths or how `command:` /
  `skill:` prefixes parsed → `resolve_feature` in `lib.sh`.
- Changing what makes source file installable → `require_versioned_source`
  in `lib.sh`.
- Changing kind-migration semantics (spec syntax, deletion rules, scan order)
  → `apply_replaces` / `find_replacement` / `check_migration_pending` /
  `remove_installed_artifact` in `lib.sh`. Scan order specifically lives in
  `_build_replaces_index`, which is what decides the first claimant.
- Changing scope semantics (flag parsing, local-root marker, which kinds are
  scope-restricted) → `resolve_scope` / `scope_is_local` / `scope_label` /
  `scope_supports_kind` in `lib.sh`.
- Changing where claude-md sections read/write in local scope →
  `claudemd_target_path_var` in `lib.sh`.
  `cmd-ls.sh::scan_claudemd` mirrors `claudemd_is_installed` /
  `claudemd_installed_version` — keep them in step per
  [cmd-ls.md](./cmd-ls.md) § Internal patterns.
- Changing changelog range extraction or its degrade-never-fail branches →
  `print_changelog_range` in `lib.sh`; the caller's suppression rule lives in
  `cmd-upgrade.sh`.
- Changing the changelog block's layout or colours → `_render_changelog_sections`
  in `lib.sh` (inline markup: `_render_bullet_markup` beside it).
- Changing which sections `changelog --since` selects, how its value is
  classified, or how a duration resolves to a date → `select_changelog_sections`
  / `changelog_since_kind` / `changelog_duration_to_date` in `lib.sh`. The
  argument parsing, editor chain and paging rule live in `cmd-changelog.sh` —
  see [cmd-changelog.md](./cmd-changelog.md).
