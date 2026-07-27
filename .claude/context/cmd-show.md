# cmd-show

## Overview

`scripts/cmd-show.sh` inspects a single feature in detail: name, kind,
installed/latest version, status, description, and path — optionally printing
the body or a line-by-line diff. Unlike `ls`, it can also inspect a
**local-only** feature (installed but absent from the managed clone).

## Public API

CLI:
- `chosko-llm show <feature>` — `<feature>` is a bare name or
  `command:<name>`, `skill:<name>`, `claude-md:<name>`, `statusline:<name>`.
- `--installed` — show the installed copy (notes if not installed).
- `--latest` — show the latest copy from the managed clone.
- `--diff` — compare latest vs installed (summary; add `--content` for a line
  diff). These three are mutually exclusive (`die` if more than one).
- `--content` — also print the body of the selected copy (or the diff).
- `-h` / `--help` — usage, exit 0.

Default view (no flag): installed copy if installed, else latest.

Output: a metadata block (Name, Kind, Installed, Latest, Status, Description,
Path) using the same status/kind color vocabulary as `cmd-ls`, then optional
body/diff, then a status-specific footer tip (`add` / `update` /
`show --diff --content` / up-to-date / local-only).

Exit codes: 0 normally; 1 (via `die`) on no feature, an unknown flag, more
than one view flag, or an unresolvable/ambiguous name.

## Internal patterns

- **Own resolver, not `lib.sh::resolve_feature`.** `resolve_show_feature`
  matches a feature that exists in EITHER the managed clone OR `$CLAUDE_HOME`,
  so local-only installs are inspectable. Keep its `command:`/`skill:`/
  `claude-md:`/`statusline:` prefix parsing and 4-way ambiguity in sync with
  the resolvers in `lib.sh` and `cmd-rm.sh`.
- **Status vocabulary mirrors `cmd-ls`** exactly: `up-to-date` / `updatable`
  / `not installed` / `local only`, with the same color mapping. Changing the
  vocabulary means changing both scripts.
- **claude-md bodies have no frontmatter once installed.** Installed
  description is unavailable for claude-md (the managed section carries no
  YAML); the body is extracted from the begin/end markers in
  `$CLAUDE_HOME/CLAUDE.md`, while the latest body is the managed file minus
  its frontmatter.
- **statusline bodies behave like commands/skills.** Unlike claude-md, the
  installed `.sh` file carries its own frontmatter (in the no-op heredoc), so
  `print_installed_body`/`print_latest_body` just `cat` the file.
- **Colors come from `lib.sh`** (`C_*`, set on a TTY); never inline escapes.

## Domain dependencies

- `../../docs/authoring-guide.md` — the frontmatter (`version`, `description`)
  this surfaces.
- `../../CLAUDE.md` — "filesystem is the source of truth"; status is derived
  by comparing the two homes, no lockfile.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `src_*` / `inst_*` path helpers,
  `read_frontmatter_field`, `claudemd_is_installed` /
  `claudemd_installed_version`, and the `C_*` colors.
- [cmd-ls.md](./cmd-ls.md) — the multi-feature listing; `show` is the
  single-feature deep-dive whose footer tip points back at `add`/`update`.

## When to read the source

- Changing the metadata block, view flags, or footer tips →
  `scripts/cmd-show.sh`.
- Changing how local-only features resolve → `resolve_show_feature` in
  `cmd-show.sh`.
- Changing the diff rendering (currently `diff -u` over extracted bodies) →
  the `diff)` branch in `cmd-show.sh`.
