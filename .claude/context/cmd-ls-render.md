# cmd-ls: rendering and fork budget

## Overview

Covers how `list_all` in `scripts/cmd-ls.sh` builds and emits the listing: the
three passes, the fork budget, the one batched frontmatter read and the
in-memory CLAUDE.md scan. The rest of `cmd-ls`: [cmd-ls.md](./cmd-ls.md).

## Public API

- None of its own; the CLI and output contract: [cmd-ls.md](./cmd-ls.md) § Public API.

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
- **One awk for the whole listing.** Pass 1 collects the paths under **two
  separate guards**: `-f` decides whether the file counts (an existing file
  with no `version` still renders `unversioned`, not `—`), while `-r`
  separately decides whether it is handed to awk. Pass 2 loads `VER` / `REQ`
  keyed by path. Both follow `read_frontmatter_table`'s contract in
  [shared-lib-frontmatter.md](./shared-lib-frontmatter.md) § Public API › Frontmatter.
  Pass 3 then holds four values per row: `inst_ver` / `inst_req` (when `r_inst[i]` is
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

## Domain dependencies

- None beyond [cmd-ls.md](./cmd-ls.md) § Domain dependencies.

## Cross-references

- [cmd-ls.md](./cmd-ls.md) — the hub: CLI, output contract, REQUIRES cell,
  status vocabulary, and the `lib.sh` helpers these passes call.

## When to read the source

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
