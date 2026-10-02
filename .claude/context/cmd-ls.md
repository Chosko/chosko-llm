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
pending` — the last two flag a feature mid kind-migration — and it is padded
to `STATUS_WIDTH` (18, one wider than `migration pending`) so `REQUIRES` can be
last and unpadded. `REQUIRES` is the row's comma-separated kind-prefixed specs
as declared (`skill:task-engine`), or a dimmed `—` when none. Missing values
render `—`. Installed file w/ no `version` frontmatter shows `unversioned`. An
unmanaged skills directory ([shared-lib.md](./shared-lib.md) § Public API ›
Feature kind) is installed, not missing: the row renders `unversioned` / `—` /
`local only`, and being `local only` it is never counted installable and never
named in the footer `add` hint. Rows print as one sequence ordered ascending by
feature name, not grouped by kind; two rows sharing a name break the tie on
kind rank — command, skill, claude-md, statusline, hook. When stdout is a
terminal (`[ -t 1 ]`), a suggestions block follows the table: an `add` hint
for installable features, an `update` hint for outdated ones, a migrate hint
when any row is `superseded` / `migration pending` (or `Everything is up to
date.` when none of the three apply), and always, last, `Run 'chosko-llm show
<feature>' to inspect a feature.`; piped or redirected output is the bare
table.

**Scope (`--local` / `--global`).** Scope flags are resolved before any other
flag parsing, per [shared-lib.md](./shared-lib.md) § Public API › Scope
resolution. Scope decides the `kinds` array `list_all` iterates:
`command skill claude-md` always, plus `hook` in local scope and `statusline`
in global. The claude-md rows read `claudemd_target_path` (in `lib.sh`).

## Internal patterns

- **One row list, three passes, one name-ordered emit.** `list_all` runs
  pass 1 (enumerate every candidate row per kind, and with it every
  frontmatter file the listing will read), pass 2 (ONE
  `lib.sh::read_frontmatter_table "version requires" <every file>`, into the
  `VER` / `REQ` maps), pass 3 (render). The per-row work is identical for
  every kind, so the per-kind differences are the `kinds` array plus a `case`
  picking each kind's rank, label and colour. Rendering appends
  `<name>\t<kind rank>\t<line>` to a single `rows` array and one
  `LC_ALL=C sort -t $'\t' -k1,1 -k2,2n | cut -f3-` emits the whole table in
  name order. `LC_ALL=C` is what makes the order byte-deterministic regardless
  of the caller's locale collation; the rank constants `KIND_RANK_*` are the
  same-name tie-break. Rendering into a string keeps `_colored_cell`'s
  visible-length padding intact, since the escape codes ride inside field 3
  untouched. Names deduped across two homes (managed clone + `$CLAUDE_HOME`);
  statusline plain file check like commands/skills. Pass 1 also sets the
  parallel `r_unmg` flag for a skills directory with no `SKILL.md`, which
  pass 3 renders as `unversioned`; the test runs only on rows that already
  lack an installed `SKILL.md`, and it forks nothing — two `[` builtins inside
  `skill_is_unmanaged`.
- **The fork budget is the design constraint.** On Git Bash for Windows —
  this CLI's primary platform — a fork costs ~12 ms and a fork plus exec
  ~20 ms. At ~34 features `ls` spends 3 processes (the one `awk`, and the
  `sort | cut` of the final emit) and ~0.2 s. Everything that runs per row
  therefore appends to a variable instead of printing into a `$(...)`, and
  nothing per-row reads through `< <(...)`. Concretely: `_colored_cell` /
  `_requires_cell` append to the global `ROW`; `compute_status` sets the
  globals `STATUS_COL` / `STATUS_COLOR`; `collect_names` fills the global
  `NAMES`, takes basenames with parameter expansion instead of `basename` and
  dedupes with an associative array instead of `sort -u`; paths come from
  `lib.sh::feature_path_var`, not the printing path helpers. **A `$(...)`
  added inside one of these loops costs a measurable fraction of the whole
  command** — that is the rule to keep, not the specific numbers.
- **REQUIRES cell is read-only and non-fatal.** `_requires_cell
  <requires-value>` renders the last column. It takes the raw `requires:`
  VALUE, not a path: the calling pass already parsed that file's frontmatter
  for its version column, so it hands the second field over for free. Pass 3
  picks the value, `req_raw`, the way the LATEST column does: `src_req` when
  the source file exists, `inst_req` otherwise — so the cell answers what the
  feature will require after an `update`, and still gives a not-installed row
  a value before `add`. A source file that exists but declares nothing renders
  the em dash rather than falling back; the source is the answer and it said
  "none". A claude-md row has no installed pair — `inject_section` strips
  frontmatter, and its INSTALLED column comes from the `scan_claudemd` maps —
  so its `req_raw` is `src_req` or empty. Entries come from
  `lib.sh::requires_specs_from_value_into` — the lenient split, NOT
  `requires_specs`: a malformed entry renders raw + dimmed and the listing
  continues. Lenient versus strict split: [shared-lib.md](./shared-lib.md)
  § Public API › Dependencies.
- **One awk for the whole listing.** Pass 1 collects the paths under **two
  separate guards**: `-f` decides whether the file counts (an existing file
  with no `version` still renders `unversioned`, not `—`), while `-r`
  separately decides whether it is handed to awk. Pass 2 loads `VER` / `REQ`
  keyed by path. Both follow `read_frontmatter_table`'s contract in
  [shared-lib.md](./shared-lib.md) § Public API › Frontmatter. Pass 3 then
  holds four values per row: `inst_ver` / `inst_req` (when `r_inst[i]` is
  non-empty) and `src_ver` / `src_req` (when `r_src[i]` is).
- **The managed CLAUDE.md is read once.** `scan_claudemd` reads
  `claudemd_target_path` into `CLAUDEMD_BODY` and walks its managed section
  markers in bash — claude-md "installed" state is a section, not a file —
  filling `CLAUDEMD_NAMES` (what `collect_names claude-md` merges with the
  clone's filenames) and `CLAUDEMD_VERSION` (the INSTALLED column);
  `claudemd_scan_is_installed` then answers from the body already in memory.
  The two parameter-expansion parses deliberately mirror `lib.sh`'s two `sed`
  scripts, including their fall back to the raw line when the pattern does not
  match — `lib.sh::claudemd_is_installed` / `claudemd_installed_version` stay
  the authority for every other caller, so the mirror is what keeps `ls` from
  disagreeing with `show`.
- **No version comparison.** `cmd-ls` only prints two version strings
  side by side; no `[new]` / `[upgradable]` markers.
- **Filenames are the truth.** File named `foo.md` w/ frontmatter
  `name` is `bar` listed as `foo` (basename) — matches what
  `cmd-add` / `cmd-update` resolve against. Authoring guide warns
  against this mismatch.
- **Footer suggestions TTY-gated.** Installable + updatable + migrating names
  accumulated from filtered rows during the listing passes — counts reflect
  what actually shown, and are unaffected by the emit-order sort, which
  reorders only the buffered rows.
- **Kind-migration statuses.** `compute_status` extends the base four-value
  vocabulary with `superseded` (a `local only` row whose installed artifact is
  claimed by some clone feature's `replaces:`, per `lib.sh::find_replacement`)
  and `migration pending` (a `not installed` row whose own `replaces:` names a
  currently installed artifact, per `lib.sh::check_migration_pending`). Both render their own colours
  ([shared-lib.md](./shared-lib.md) § Public API › Stdout color variables) and
  feed the `migrating` array, not `installable`/`updatable` — a `superseded`
  row is not "add"-able, a `migration pending` row is not a plain install. The
  probes only run when the base status is already `local only` /
  `not installed`, never on every row, and both read `lib.sh`'s one-pass
  `replaces:` index, so even a listing where every row is local-only costs no
  extra process.

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
  fork-budget bullet above says how.
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