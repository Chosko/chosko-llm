# cmd-ls

## Overview

`scripts/cmd-ls.sh` list features visible in managed clone or `$CLAUDE_HOME`, installed version + latest (managed-clone) version side by side.

## Public API

CLI:
- `chosko-llm ls` — all features.
- `chosko-llm ls --installed` — only features w/ installed version.
- `chosko-llm ls --available` — only features present in managed clone.
- `chosko-llm ls --all` — same as no flag.
- `chosko-llm ls --local` / `--global` — scope, see below.
- `-h` / `--help` — print local usage, exit 0.
- Any other flag → `die`.

Output: `Home: <scope_label>` line, blank line, then text table, header
`NAME KIND INSTALLED LATEST STATUS`. `KIND` is `command`, `skill`,
`claude-md`, `statusline`, or `hook`. `STATUS` is one of `up-to-date` /
`updatable` / `not installed` / `local only` / `superseded` / `migration
pending` — the last two flag a feature mid kind-migration (task 104).
Missing values render `—`. Installed file w/ no `version` frontmatter
shows `unversioned`. Rows print as one sequence ordered ascending by
feature name, not grouped by kind (task 153); two rows sharing a name break
the tie on kind rank — command, skill, claude-md, statusline, hook. On
interactive terminal, suggestions block follows
table (install / update / migrate hints, plus always-present `show`
inspect hint); suppressed when stdout piped or redirected.

**Scope (`--local` / `--global`, task 103).** First line after sourcing
`lib.sh` calls `resolve_scope "$@"` then re-sets `$@` from `SCOPE_ARGS`, so
the rest of the script's flag parsing is unaware scope flags ever existed.
No flag = `--global`, byte-identical to pre-103 behavior. `--local` repoints
`CLAUDE_HOME` at `<cwd>/.claude` (`resolve_scope` in `lib.sh`, task 102) and
requires `<cwd>/CLAUDE.md`. `list_all` prints `scope_label` above the table.
In local scope, the statusline listing pass is skipped entirely (wrapped in
`if ! scope_is_local`) — statusline is global-only. The hook pass mirrors it,
wrapped in `if scope_is_local`, so `ls --global` omits hooks. The claude-md pass reads
`claudemd_target_path` (task 103, in `lib.sh`) instead of a hardcoded
`$CLAUDE_HOME/CLAUDE.md`, since local scope's claude-md target is
`<cwd>/CLAUDE.md`, not `<cwd>/.claude/CLAUDE.md`.

## Internal patterns

- **Five passes, one name-ordered emit (task 153)**: passes still run
  commands, skills, claude-md artifacts, statusline scripts, hooks — each
  with its own filter + scope gate — but a pass no longer prints. It renders
  its row into a string and appends `<name>\t<kind rank>\t<line>` to a single
  `rows` array; after the last pass one `LC_ALL=C sort -t $'\t' -k1,1 -k2,2n
  | cut -f3-` emits the whole table in name order. `LC_ALL=C` is what makes
  the order byte-deterministic regardless of the caller's locale collation;
  the rank constants `KIND_RANK_*` are the same-name tie-break. Rendering
  into a string keeps `_colored_cell`'s visible-length padding intact, since
  the escape codes ride inside field 3 untouched. Names within each pass
  sorted + deduped across two homes (managed clone + `$CLAUDE_HOME`).
  claude-md "installed" state detected by managed section markers in
  `$CLAUDE_HOME/CLAUDE.md`, not file; statusline plain file check like
  commands/skills.
- **No version comparison.** `cmd-ls` only prints two version strings
  side by side; no `[new]` / `[upgradable]` markers.
- **Filenames are the truth.** File named `foo.md` w/ frontmatter
  `name` is `bar` listed as `foo` (basename) — matches what
  `cmd-add` / `cmd-update` resolve against. Authoring guide warns
  against this mismatch.
- **Footer suggestions TTY-gated.** After table, `cmd-ls` prints
  actionable hints on stdout only when stdout is terminal (`[ -t 1 ]`);
  piped/redirected output stays clean table. Block contains `add`
  hint for installable features, `update` hint for outdated ones, a
  migrate hint when any row is `superseded`/`migration pending` (or
  `Everything is up to date.` when none of the three apply), ALWAYS ends
  w/ `Run 'chosko-llm show <feature>' to inspect a feature.` Installable +
  updatable + migrating names accumulated from filtered rows during the
  listing passes — counts reflect what actually shown, and are unaffected by
  the emit-order sort, which reorders only the buffered rows.
- **Kind-migration statuses (task 104).** `compute_status` (shared by every
  pass) extends the base four-value vocabulary with `superseded`
  (a `local only` row whose installed artifact is claimed by some clone
  feature's `replaces:`, per `lib.sh::find_replacement`) and `migration
  pending` (a `not installed` row whose own `replaces:` names a currently
  installed artifact, per `lib.sh::check_migration_pending`). Both render
  distinct colors (`superseded` `C_MAGENTA`, `migration pending` `C_BLUE`)
  and feed the `migrating` array, not `installable`/`updatable`
  — a `superseded` row is not "add"-able, a `migration pending` row is not
  a plain install. The probes only run when the base status is already
  `local only` / `not installed`, never on every row.

## Domain dependencies

- `../../CLAUDE.md` — "filesystem is source of truth, no lockfile". Script
  implements that by walking both directories.

## Cross-references

- [shared-lib.md](./shared-lib.md) — uses `inst_command_path`,
  `src_command_path`, skill equivalents, `read_frontmatter_field`, and
  scope helpers `resolve_scope` / `scope_is_local` / `scope_label` /
  `claudemd_target_path`.
- [cmd-add.md](./cmd-add.md) / [cmd-update.md](./cmd-update.md) — features
  `ls` shows produced/consumed by these.
- [cmd-show.md](./cmd-show.md) — single-feature deep-dive footer's
  inspect hint points at; shares status/kind vocabulary.

## When to read the source

- Changing column layout, filter flags, output formatting →
  `scripts/cmd-ls.sh`.
- Changing row order, or the kind rank that breaks a same-name tie → the
  `rows` buffer, the `KIND_RANK_*` constants, and the final sort in
  `list_all` in `cmd-ls.sh`.
- Changing how names deduped across two homes → `collect_names`
  function in `cmd-ls.sh`.
- Changing scope behavior (home line, statusline omission, claude-md
  target) → `resolve_scope` call and `list_all` in `cmd-ls.sh`.