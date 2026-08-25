# cmd-ls

## Overview

`scripts/cmd-ls.sh` list features visible in managed clone or `$CLAUDE_HOME`, installed version + latest (managed-clone) version side by side, plus each feature's declared `requires:` dependencies.

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
`NAME KIND INSTALLED LATEST STATUS REQUIRES`. `KIND` is `command`, `skill`,
`claude-md`, `statusline`, or `hook`. `STATUS` is one of `up-to-date` /
`updatable` / `not installed` / `local only` / `superseded` / `migration
pending` — the last two flag a feature mid kind-migration (task 104), and it
is padded to `STATUS_WIDTH` (18, one wider than `migration pending`) so
`REQUIRES` can be last and unpadded (task 152). `REQUIRES` is the row's
comma-separated kind-prefixed specs as declared (`skill:task-engine`), or a
dimmed `—` when none. Missing values render `—`. Installed file w/ no
`version` frontmatter shows `unversioned`. Rows print as one sequence ordered ascending by
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
- **REQUIRES cell is read-only and non-fatal (task 152).** `_requires_cell
  <requires-value>` renders the last column. It takes the raw `requires:`
  VALUE, not a path (task 155): the calling pass already parsed that file's
  frontmatter for its version column, so it hands the second field over for
  free. Which file the value came from is the caller's choice, and every pass
  makes the LATEST column's: the source file's value when that file exists, the
  installed file's otherwise — so the cell answers what the feature will require
  after an `update`, and still gives a not-installed row a value before `add`. A
  source file that exists but declares nothing renders the em dash rather than
  falling back; the source is the answer and it said "none". The claude-md pass
  has only a source value to offer: `inject_section` strips frontmatter, so a
  section in `CLAUDE.md` carries no `requires:` to fall back to. Entries come
  from `lib.sh::requires_specs_from_value` — the lenient split, NOT
  `requires_specs`: a malformed entry renders raw + dimmed and the listing
  continues, because one typo in one unrelated feature must not take down a
  read-only lister. `cmd-add` / `cmd-rm` keep calling the strict
  `requires_specs` and keep dying — that is where a dangling reference has to
  be caught.
- **Parse each file's frontmatter once per row (task 155).** A pass reads its
  version column and its REQUIRES value out of ONE
  `lib.sh::read_frontmatter_fields <file> version requires` per file, not two
  `read_frontmatter_field` calls — which parsed each source file twice, and cost
  `ls` about 30% over its pre-152 runtime. Each pass therefore holds four
  values per row: `inst_ver` / `inst_req` (guarded by `-f "$inst_file"`) and
  `src_ver` / `src_req` (guarded by `-f "$src_file"`), and picks `req_raw` from
  the source pair when the source file exists, the installed pair otherwise.
  The claude-md pass has no installed pair at all — its INSTALLED column comes
  from `claudemd_installed_version`, and there is no installed frontmatter to
  fall back to — so its `req_raw` is `src_req` or empty. Out of scope, and
  still one read each: `find_replacement` / `check_migration_pending`, which
  run only on rows already computed as `local only` / `not installed`.
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
  `src_command_path`, skill equivalents, `read_frontmatter_fields` (the
  parse-once reader; `cmd-ls` is why it exists), `requires_specs_from_value`,
  and scope helpers `resolve_scope` / `scope_is_local` / `scope_label` /
  `claudemd_target_path`.
- [cmd-add.md](./cmd-add.md) / [cmd-update.md](./cmd-update.md) — features
  `ls` shows produced/consumed by these.
- [cmd-show.md](./cmd-show.md) — single-feature deep-dive footer's
  inspect hint points at; shares status/kind vocabulary.

## When to read the source

- Changing column layout, filter flags, output formatting →
  `scripts/cmd-ls.sh`.
- Changing what the REQUIRES column shows, which file it reads, or how a
  malformed entry renders → `_requires_cell` in `cmd-ls.sh` (which file's value
  reaches it is decided by the `req_raw` assignment in each pass) and
  `requires_specs_from_value` in `lib.sh`.
- Changing how many times a row parses a file, or which frontmatter fields a
  pass needs → the `read_frontmatter_fields` call in each pass of `cmd-ls.sh`
  and that helper in `lib.sh`.
- Changing row order, or the kind rank that breaks a same-name tie → the
  `rows` buffer, the `KIND_RANK_*` constants, and the final sort in
  `list_all` in `cmd-ls.sh`.
- Changing how names deduped across two homes → `collect_names`
  function in `cmd-ls.sh`.
- Changing scope behavior (home line, statusline omission, claude-md
  target) → `resolve_scope` call and `list_all` in `cmd-ls.sh`.