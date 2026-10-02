# Shared library: feature kinds

## Overview

Covers the feature-kind half of `scripts/lib.sh`: the claude-md, statusline and
hook kind helpers, kind resolution, kind migration (`replaces:`) and
dependencies (`requires:`). The rest of `lib.sh`: [shared-lib.md](./shared-lib.md).

## Public API

### claude-md artifacts
Third feature kind. Instead of copying a file, injects a managed section into
the CLAUDE.md `claudemd_target_path` names ([shared-lib.md](./shared-lib.md) §
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
(optional) ([shared-lib.md](./shared-lib.md) § Frontmatter). LOCAL-ONLY kind
(see `scope_supports_kind` in [shared-lib.md](./shared-lib.md) § Scope
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

## Internal patterns

- **`split_kind_spec` parses two keys, not one.** `requires:` reuses it for
  every entry rather than growing a second kind-prefix parser, so `replaces:
  skill:x` and `requires: skill:x` can never disagree about what a spec means.
- **Migration is declarative, not a map** (§ Kind migration). `--all` resolves
  migration from the *stale* side because the replacement isn't installed
  yet — iterating installed artifacts is the only place the stale one is
  visible.
- **`resolve_feature` is the source of truth** for kind-prefix parsing (every
  prefix § Feature kind lists). `cmd-rm.sh` and `cmd-show.sh` parse prefix
  themselves (resolve against installed/either kind, not source kind) — keep
  all three prefix parsers in sync if syntax changes.

## Domain dependencies

- None of its own; frontmatter schema: [shared-lib.md](./shared-lib.md) §
  Domain dependencies.

## Cross-references

- [shared-lib.md](./shared-lib.md) — the scope, frontmatter and path helpers
  the kind helpers here build on.
- [cmd-add.md](./cmd-add.md), [cmd-rm.md](./cmd-rm.md),
  [cmd-update.md](./cmd-update.md), [cmd-ls.md](./cmd-ls.md),
  [cmd-show.md](./cmd-show.md) — the callers each helper above names.

## When to read the source

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
- Changing kind-migration semantics (spec syntax, deletion rules, scan order)
  → `apply_replaces` / `find_replacement` / `check_migration_pending` /
  `remove_installed_artifact` in `lib.sh`. Scan order specifically lives in
  `_build_replaces_index`, which is what decides the first claimant.
