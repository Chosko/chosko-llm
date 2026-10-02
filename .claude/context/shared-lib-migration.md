# Shared library: kind migration

## Overview

Covers kind migration (`replaces:`) in `scripts/lib.sh`: the helpers that
remove a stale artifact when a feature changes kind, and the `replaces:` index
`ls`, `show` and `update --all` probe. Kind helpers it builds on:
[shared-lib-kinds.md](./shared-lib-kinds.md). The rest of `lib.sh`:
[shared-lib.md](./shared-lib.md).

## Public API

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
  Its `skill` arm calls `skill_dir_is_managed` ([shared-lib-kinds.md](./shared-lib-kinds.md) § Feature kind), not `[ -d ]`,
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

## Internal patterns

- **Migration is declarative, not a map** (§ Kind migration). `--all` resolves
  migration from the *stale* side because the replacement isn't installed
  yet — iterating installed artifacts is the only place the stale one is
  visible.

## Domain dependencies

- None beyond [shared-lib-kinds.md](./shared-lib-kinds.md) § Domain
  dependencies.

## Cross-references

- [shared-lib-kinds.md](./shared-lib-kinds.md) — the kind helpers this builds
  on, and § Cross-references there for the `cmd-*` callers.
- [shared-lib-requires.md](./shared-lib-requires.md) — `requires:`, which
  reuses `split_kind_spec` for every entry.

## When to read the source

- Changing kind-migration semantics (spec syntax, deletion rules, scan order)
  → `apply_replaces` / `find_replacement` / `check_migration_pending` /
  `remove_installed_artifact` in `lib.sh`. Scan order specifically lives in
  `_build_replaces_index`, which is what decides the first claimant.
