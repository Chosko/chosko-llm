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
Scope decides the `kinds` array `list_all` iterates: `command skill claude-md`
always, plus `hook` in local scope and `statusline` in global — statusline is
global-only, hooks are local-only (task 163 replaced the two `if
scope_is_local` wrappers around whole passes with this one list). The claude-md
rows read `claudemd_target_path` (task 103, in `lib.sh`) instead of a hardcoded
`$CLAUDE_HOME/CLAUDE.md`, since local scope's claude-md target is
`<cwd>/CLAUDE.md`, not `<cwd>/.claude/CLAUDE.md`.

## Internal patterns

- **One row list, three passes, one name-ordered emit (tasks 153, 163).**
  `list_all` runs pass 1 (enumerate every candidate row per kind, and with it
  every frontmatter file the listing will read), pass 2 (ONE
  `read_frontmatter_table` for all of them, into the `VER` / `REQ` maps), pass 3
  (render). Task 163 replaced the five near-identical per-kind passes with this;
  the per-row work is identical for every kind, so the shape that differed five
  ways is now the `kinds` array plus a `case` picking each kind's rank, label and
  colour. Rendering appends `<name>\t<kind rank>\t<line>` to a single `rows`
  array and one `LC_ALL=C sort -t $'\t' -k1,1 -k2,2n | cut -f3-` emits the whole
  table in name order. `LC_ALL=C` is what makes the order byte-deterministic
  regardless of the caller's locale collation; the rank constants `KIND_RANK_*`
  are the same-name tie-break. Rendering into a string keeps `_colored_cell`'s
  visible-length padding intact, since the escape codes ride inside field 3
  untouched. Names deduped across two homes (managed clone + `$CLAUDE_HOME`);
  claude-md "installed" state detected by managed section markers in
  `$CLAUDE_HOME/CLAUDE.md`, not a file; statusline plain file check like
  commands/skills.
- **The fork budget is the design constraint (task 163).** On Git Bash for
  Windows — this CLI's primary platform — a fork costs ~12 ms and a fork plus
  exec ~20 ms. At ~34 features `ls` was spending 217 processes and 5.4 s; after
  task 163 it spends 3 (the one `awk`, and the `sort | cut` of the final emit)
  and ~0.2 s. Everything that runs per row therefore appends to a variable
  instead of printing into a `$(...)`, and nothing per-row reads through
  `< <(...)`. Concretely: `_colored_cell` / `_requires_cell` append to the global
  `ROW`; `compute_status` sets the globals `STATUS_COL` / `STATUS_COLOR`;
  `collect_names` fills the global `NAMES`, takes basenames with parameter
  expansion instead of `basename` and dedupes with an associative array instead
  of `sort -u`; paths come from `lib.sh::feature_path_var`, not the printing
  path helpers. **A `$(...)` added inside one of these loops costs a measurable
  fraction of the whole command** — that is the rule to keep, not the specific
  numbers.
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
  from `lib.sh::requires_specs_from_value_into` — the lenient split, NOT
  `requires_specs`: a malformed entry renders raw + dimmed and the listing
  continues, because one typo in one unrelated feature must not take down a
  read-only lister. `cmd-add` / `cmd-rm` keep calling the strict
  `requires_specs` and keep dying — that is where a dangling reference has to
  be caught. The `_into` form (task 163) leaves its result in the global
  `REQUIRES_SPECS` so the cell can iterate it without a process substitution.
- **One awk for the whole listing (tasks 155, 163).** Task 155 got a row down to
  one `read_frontmatter_fields` per file instead of two
  `read_frontmatter_field` calls; task 163 got the whole listing down to one
  `lib.sh::read_frontmatter_table "version requires" <every file>`, because 66
  awk processes was the single largest cost in the command. Pass 1 collects the
  paths under **two separate guards**: `-f` decides whether the file counts (an
  existing file with no `version` still renders `unversioned`, not `—`), while
  `-r` separately decides whether it is handed to awk — which aborts the whole
  batch on a file it cannot open and would take every later row's values with
  it, where one awk per file lost only its own row. Pass 2 loads `VER` / `REQ`
  keyed by path, splitting each
  TAB line with parameter expansion — **not `read -a`**, since TAB is IFS
  whitespace and two adjacent empty fields would collapse. Pass 3 then holds four
  values per row: `inst_ver` / `inst_req` (when `r_inst[i]` is non-empty) and
  `src_ver` / `src_req` (when `r_src[i]` is), and picks `req_raw` from the source
  pair when the source file exists, the installed pair otherwise. A claude-md row
  has no installed pair at all — its INSTALLED column comes from the
  `scan_claudemd` maps, and there is no installed frontmatter to fall back to —
  so its `req_raw` is `src_req` or empty.
- **The managed CLAUDE.md is read once (task 163).** `scan_claudemd` reads
  `claudemd_target_path` into `CLAUDEMD_BODY` and walks it in bash, filling
  `CLAUDEMD_NAMES` (what `collect_names claude-md` merges with the clone's
  filenames) and `CLAUDEMD_VERSION` (the INSTALLED column);
  `claudemd_scan_is_installed` then answers from the body already in memory. It
  replaces one `grep` per listing plus a `grep` and a `grep | sed | head` per
  claude-md row. The two parameter-expansion parses deliberately mirror
  `lib.sh`'s two `sed` scripts, including their fall back to the raw line when
  the pattern does not match — `lib.sh::claudemd_is_installed` /
  `claudemd_installed_version` stay the authority for every other caller, so the
  mirror is what keeps `ls` from disagreeing with `show`.
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
- **Kind-migration statuses (task 104).** `compute_status` extends the base
  four-value vocabulary with `superseded`
  (a `local only` row whose installed artifact is claimed by some clone
  feature's `replaces:`, per `lib.sh::find_replacement`) and `migration
  pending` (a `not installed` row whose own `replaces:` names a currently
  installed artifact, per `lib.sh::check_migration_pending`). Both render
  distinct colors (`superseded` `C_MAGENTA`, `migration pending` `C_BLUE`)
  and feed the `migrating` array, not `installable`/`updatable`
  — a `superseded` row is not "add"-able, a `migration pending` row is not
  a plain install. The probes only run when the base status is already
  `local only` / `not installed`, never on every row — and since task 163 both
  read `lib.sh`'s one-pass `replaces:` index rather than rescanning the clone
  per call, so even a listing where every row is local-only costs no extra
  process.

## Domain dependencies

- `../../CLAUDE.md` — "filesystem is source of truth, no lockfile". Script
  implements that by walking both directories.

## Cross-references

- [shared-lib.md](./shared-lib.md) — uses `feature_path_var` and
  `claudemd_target_path_var` (the fork-free path helpers; `cmd-ls` is why they
  exist), `read_frontmatter_table` (the one-awk batch reader; likewise),
  `requires_specs_from_value_into`, `find_replacement` /
  `check_migration_pending` over the `replaces:` index, and scope helpers
  `resolve_scope` / `scope_is_local` / `scope_label`.
- [cmd-add.md](./cmd-add.md) / [cmd-update.md](./cmd-update.md) — features
  `ls` shows produced/consumed by these.
- [cmd-show.md](./cmd-show.md) — single-feature deep-dive footer's
  inspect hint points at; shares status/kind vocabulary.

## When to read the source

- Changing column layout, filter flags, output formatting →
  `scripts/cmd-ls.sh`.
- Changing what the REQUIRES column shows, which file it reads, or how a
  malformed entry renders → `_requires_cell` in `cmd-ls.sh` (which file's value
  reaches it is decided by the `req_raw` assignment in pass 3) and
  `requires_specs_from_value_into` in `lib.sh`.
- Changing which frontmatter fields a row needs, or how many processes the
  listing spends → passes 1 and 2 of `list_all` in `cmd-ls.sh` and
  `read_frontmatter_table` in `lib.sh`. Re-measure before and after: the
  fork-budget bullet above says how (`ls` was 5.4 s and 217 processes at ~34
  features before task 163).
- Changing how the INSTALLED column or the name list is derived for claude-md →
  `scan_claudemd` / `claudemd_scan_is_installed` in `cmd-ls.sh`, which mirror
  `claudemd_is_installed` / `claudemd_installed_version` in `lib.sh` — change
  both or they disagree.
- Changing row order, or the kind rank that breaks a same-name tie → the
  `rows` buffer, the `KIND_RANK_*` constants, and the final sort in
  `list_all` in `cmd-ls.sh`.
- Changing how names deduped across two homes → `collect_names`
  function in `cmd-ls.sh`.
- Changing scope behavior (home line, which kinds are listed, claude-md
  target) → `resolve_scope` call and the `kinds` array in `list_all` in
  `cmd-ls.sh`.