# cmd-ls

## Overview

`scripts/cmd-ls.sh` list features visible in managed clone or `$CLAUDE_HOME`, installed version + latest (managed-clone) version side by side, plus each feature's declared `requires:` dependencies.

Rendering internals — the three passes of `list_all`, the fork budget, the one
batched frontmatter read, the in-memory CLAUDE.md scan:
[cmd-ls-render.md](./cmd-ls-render.md).

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
unmanaged skills directory ([shared-lib-kinds.md](./shared-lib-kinds.md) §
Public API › Feature kind) is installed, not missing: the row renders `unversioned` / `—` /
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
flag parsing, per [shared-lib-scope.md](./shared-lib-scope.md) § Public API › Scope
resolution. Scope decides the `kinds` array `list_all` iterates:
`command skill claude-md` always, plus `hook` in local scope and `statusline`
in global. The claude-md rows read `claudemd_target_path` (in `lib.sh`).

## Internal patterns

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
  continues. Lenient versus strict split: [shared-lib-requires.md](./shared-lib-requires.md)
  § Public API › Dependencies.
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

- [shared-lib-scope.md](./shared-lib-scope.md),
  [shared-lib-frontmatter.md](./shared-lib-frontmatter.md) — uses `feature_path_var` and
  `claudemd_target_path_var` (the fork-free path helpers; `cmd-ls` is why they
  exist), `read_frontmatter_table` (the one-awk batch reader; likewise), and
  scope helpers `resolve_scope` / `scope_is_local` / `scope_label`.
- [shared-lib-requires.md](./shared-lib-requires.md),
  [shared-lib-migration.md](./shared-lib-migration.md) — uses
  `requires_specs_from_value_into`, `find_replacement` /
  `check_migration_pending` over the `replaces:` index.
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
- Changing scope behavior (home line, which kinds are listed, claude-md
  target) → `resolve_scope` call and the `kinds` array in `list_all` in
  `cmd-ls.sh`.
