# cmd-ls

## Overview

`scripts/cmd-ls.sh` lists features visible in either the managed clone or
`$CLAUDE_HOME`, with the installed version and the latest (managed-clone)
version side by side.

## Public API

CLI:
- `chosko-llm ls` — all features.
- `chosko-llm ls --installed` — only features with an installed version.
- `chosko-llm ls --available` — only features present in the managed clone.
- `chosko-llm ls --all` — same as no flag.
- `-h` / `--help` — prints local usage and exits 0.
- Any other flag → `die`.

Output: a 4-column text table with header `NAME KIND INSTALLED LATEST`.
`KIND` is `command` or `skill`. Missing values are rendered as `—`. An
installed file with no `version` frontmatter shows as `unversioned`.

## Internal patterns

- **Two-pass listing**: commands first, then skills. Names within each pass
  are sorted and deduplicated across the two homes (managed clone +
  `$CLAUDE_HOME`).
- **No version comparison.** `cmd-ls` only prints the two version strings
  side by side; there are no `[new]` / `[upgradable]` markers.
- **Filenames are the truth.** A file named `foo.md` whose frontmatter
  `name` is `bar` will be listed as `foo` (basename), which matches what
  `cmd-add` / `cmd-update` resolve against. The authoring guide warns
  against this mismatch.

## Domain dependencies

- `../../CLAUDE.md` — "filesystem is the source of truth, no lockfile". This
  script implements that by walking both directories.

## Cross-references

- [shared-lib.md](./shared-lib.md) — uses `inst_command_path`,
  `src_command_path`, and skill equivalents, plus `read_frontmatter_field`.
- [cmd-add.md](./cmd-add.md) / [cmd-update.md](./cmd-update.md) — the
  features `ls` shows are produced/consumed by these.

## When to read the source

- Changing column layout, filter flags, or output formatting →
  `scripts/cmd-ls.sh`.
- Changing how names are deduplicated across the two homes → the
  `collect_names` function in `cmd-ls.sh`.
