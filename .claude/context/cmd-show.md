# cmd-show

## Overview

`scripts/cmd-show.sh` inspect single feature detail: name, kind,
installed/latest version, status, description, path — optional print
body or line-by-line diff. Unlike `ls`, can also inspect
**local-only** feature (installed but absent from managed clone).

## Public API

CLI:
- `chosko-llm show <feature>` — `<feature>` bare name or
  `command:<name>`, `skill:<name>`, `claude-md:<name>`, `statusline:<name>`.
- `--installed` — show installed copy (notes if not installed).
- `--latest` — show latest copy from managed clone.
- `--diff` — compare latest vs installed (summary; add `--content` for line
  diff). These three mutually exclusive (`die` if more than one).
- `--content` — also print body of selected copy (or diff).
- `-h` / `--help` — usage, exit 0.

Default view (no flag): installed copy if installed, else latest.

Output: metadata block (Name, Kind, Installed, Latest, Status, Description,
Path) using same status/kind color vocabulary as `cmd-ls`, then optional
body/diff, then status-specific footer tip (`add` / `update` /
`show --diff --content` / up-to-date / local-only).

Exit codes: 0 normal; 1 (via `die`) on no feature, unknown flag, more
than one view flag, or unresolvable/ambiguous name.

## Internal patterns

- **Own resolver, not `lib.sh::resolve_feature`.** `resolve_show_feature`
  matches feature existing in EITHER managed clone OR `$CLAUDE_HOME`,
  so local-only installs inspectable. Keep its `command:`/`skill:`/
  `claude-md:`/`statusline:` prefix parsing and 4-way ambiguity in sync with
  resolvers in `lib.sh` and `cmd-rm.sh`.
- **Status vocabulary mirrors `cmd-ls`** exactly: `up-to-date` / `updatable`
  / `not installed` / `local only`, same color mapping. Change vocabulary
  means change both scripts.
- **claude-md bodies have no frontmatter once installed.** Installed
  description unavailable for claude-md (managed section carries no
  YAML); body extracted from begin/end markers in
  `$CLAUDE_HOME/CLAUDE.md`, latest body is managed file minus
  frontmatter.
- **statusline bodies behave like commands/skills.** Unlike claude-md, installed
  `.sh` file carries own frontmatter (in no-op heredoc), so
  `print_installed_body`/`print_latest_body` just `cat` file.
- **Colors come from `lib.sh`** (`C_*`, set on TTY); never inline escapes.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter (`version`, `description`)
  this surfaces.
- `../../CLAUDE.md` — "filesystem is source of truth"; status derived
  by comparing two homes, no lockfile.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `src_*` / `inst_*` path helpers,
  `read_frontmatter_field`, `claudemd_is_installed` /
  `claudemd_installed_version`, and `C_*` colors.
- [cmd-ls.md](./cmd-ls.md) — multi-feature listing; `show` single-feature
  deep-dive, footer tip point back at `add`/`update`.

## When to read the source

- Change metadata block, view flags, or footer tips →
  `scripts/cmd-show.sh`.
- Change how local-only features resolve → `resolve_show_feature` in
  `cmd-show.sh`.
- Change diff rendering (currently `diff -u` over extracted bodies) →
  `diff)` branch in `cmd-show.sh`.