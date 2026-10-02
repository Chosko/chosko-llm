# cmd-show

## Overview

`scripts/cmd-show.sh` inspect single feature detail: name, kind,
installed/latest version, status, description, path, then the body's
leading `#` header (the `# /name` / `# Usage:` block carrying the flags,
which the short-by-contract `description` does not) — optional print
full body or line-by-line diff instead. Can also inspect a **local-only**
feature (installed but absent from the managed clone).

## Public API

CLI:
- `chosko-llm show <feature>` — `<feature>` bare name or
  `command:<name>`, `skill:<name>`, `claude-md:<name>`, `statusline:<name>`,
  `hook:<name>`.
- `--installed` — show installed copy (notes if not installed).
- `--latest` — show latest copy from managed clone.
- `--diff` — compare latest vs installed (summary; add `--content` for line
  diff). These three mutually exclusive (`die` if more than one).
- `--content` — print full body of selected copy (or diff) in place of the
  header block.
- `--local` / `--global` — scope, see below.
- `-h` / `--help` — usage, exit 0.

Default view (no flag): installed copy if installed, else latest.

Output: metadata block (Name, Kind, Installed, Latest, Status, Description,
Path) using same status/kind color vocabulary as `cmd-ls`, then the header
block (every view, unless `--content`; nothing when body has none), then
optional body/diff, then status-specific footer tip (`add` / `update` /
`show --diff --content` / up-to-date / local-only).

Exit codes: 0 normal; 1 (via `die`) on no feature, unknown flag, more
than one view flag, or unresolvable/ambiguous name.

## Internal patterns

- **Colors come from `lib.sh`** per [shared-lib.md](./shared-lib.md) §
  Public API › Stdout color variables.
- **Scope (`--local` / `--global`).** Scope flags are resolved before any
  other flag parsing, per [shared-lib.md](./shared-lib.md) § Public API ›
  Scope resolution. The claude-md `inst_file` and `loc` come from
  `claudemd_target_path` (in `lib.sh`). Where the scope does not support the
  kind — a statusline in local scope, a hook in global — `show` does not
  `die` (unlike `add`/`rm`/`update`): the footer's tip block is replaced with
  the "statusline scripts are global-only" or "hooks are local-only" note,
  while the metadata block above still renders normally (a statusline in
  local scope shows "not installed", since no local statusline path exists).
- **Own resolver, not `lib.sh::resolve_feature`.** `resolve_show_feature`
  matches feature existing in EITHER managed clone OR `$CLAUDE_HOME`,
  so local-only installs inspectable. Its prefix parsing and 5-way ambiguity
  stay in sync with the other resolvers per [shared-lib.md](./shared-lib.md)
  § Internal patterns.
- **An unmanaged skills directory resolves too.** An unmanaged skills
  directory ([shared-lib.md](./shared-lib.md) § Public API › Feature kind)
  sets `has_skill` via `lib.sh::skill_is_unmanaged`, then the local
  `unmanaged` flag: columns match the `ls` row ([cmd-ls.md](./cmd-ls.md) §
  Public API), `Path:` is the directory,
  and the footer states that this CLI does not manage it and `rm` refuses it.
  The flag also suppresses every read of the absent `SKILL.md` — version,
  description, body — and the `--content` hint.
- **Status vocabulary mirrors `cmd-ls`** exactly — the STATUS values in
  [cmd-ls.md](./cmd-ls.md) § Public API. Change vocabulary means change both
  scripts.
- **Kind-migration statuses.** After the base status is computed,
  `superseded` / `migration pending` are derived as in
  [cmd-ls.md](./cmd-ls.md) § Internal patterns; `mig_kind`/`mig_name` hold
  the replacement (superseded) or the stale artifact (migration pending).
  Both feed a dedicated footer tip pointing
  at `chosko-llm update --all`. `resolve_show_feature`'s ambiguous-name `die`
  also probes `check_migration_pending` across every kind the bare name
  matches, appending one line naming the pending migration when found.
- **Header block (`print_header_block`).** Awk over the file
  past the frontmatter's second `---`: skips blank lines, then prints the
  contiguous run of lines matching `^#($|[^#])` — single-`#` comment lines,
  `##` headings excluded — and stops at the first blank or non-`#` line. A
  body with no such run prints nothing, which is the case for the two `.sh`
  kinds (heredoc terminator sits between frontmatter and first comment).
  Read from the copy the view shows (`inst_file` for `installed`,
  `src_file` otherwise), falling back to `src_file` when the chosen file is
  absent or kind is claude-md. Indented two spaces via `sed`, printed only
  when `show_content` is 0 — `--content` prints the full body, which opens
  with the same block. This is the human-facing side of the `description`
  contract (`../../docs/authoring-guide.md` § The body header): flags live in
  the header, so `show` must surface it without a flag.
- **claude-md bodies have no frontmatter once installed.** Installed
  description unavailable for claude-md (managed section carries no
  YAML); body extracted from begin/end markers in the file
  `claudemd_target_path` names, latest body is managed file minus
  frontmatter.
- **statusline bodies behave like commands/skills.** Unlike claude-md, installed
  `.sh` file carries own frontmatter (in no-op heredoc), so
  `print_installed_body`/`print_latest_body` just `cat` file.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter (`version`, `description`)
  this surfaces; § The `description` contract and § The body header explain
  why the header block is printed.
- `../../CLAUDE.md` — "filesystem is source of truth"; status derived
  by comparing two homes, no lockfile.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `src_*` / `inst_*` path helpers,
  `read_frontmatter_field`, `claudemd_is_installed` /
  `claudemd_installed_version` / `claudemd_target_path`, scope helpers
  `resolve_scope` / `scope_is_local`, and `C_*` colors.
- [cmd-ls.md](./cmd-ls.md) — multi-feature listing; `show` single-feature
  deep-dive, footer tip point back at `add`/`update`.

## When to read the source

- Change metadata block, view flags, or footer tips →
  `scripts/cmd-show.sh`.
- Change how local-only features resolve → `resolve_show_feature` in
  `cmd-show.sh`.
- Change diff rendering (`diff -u` over extracted bodies) →
  `diff)` branch in `cmd-show.sh`.
- Change what counts as the header block, or which copy it is read from →
  `print_header_block` and the `header_file` selection just below it in
  `cmd-show.sh`.
- Change the statusline-in-local-scope footer note → the
  `scope_is_local` check just before the `case "$status"` footer block in
  `cmd-show.sh`.