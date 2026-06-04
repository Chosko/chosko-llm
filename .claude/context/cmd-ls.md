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

Output: a text table with header `NAME KIND INSTALLED LATEST STATUS`.
`KIND` is `command`, `skill`, or `claude-md`. Missing values are rendered as
`—`. An installed file with no `version` frontmatter shows as `unversioned`.
On an interactive terminal a suggestions block follows the table (install /
update hints, plus an always-present `show` inspect hint); it is suppressed
when stdout is piped or redirected.

## Internal patterns

- **Three-pass listing**: commands, then skills, then claude-md artifacts.
  Names within each pass are sorted and deduplicated across the two homes
  (managed clone + `$CLAUDE_HOME`). claude-md "installed" state is detected by
  the managed section markers in `$CLAUDE_HOME/CLAUDE.md`, not a file.
- **No version comparison.** `cmd-ls` only prints the two version strings
  side by side; there are no `[new]` / `[upgradable]` markers.
- **Filenames are the truth.** A file named `foo.md` whose frontmatter
  `name` is `bar` will be listed as `foo` (basename), which matches what
  `cmd-add` / `cmd-update` resolve against. The authoring guide warns
  against this mismatch.
- **Footer suggestions are TTY-gated.** After the table, `cmd-ls` prints
  actionable hints on stdout only when stdout is a terminal (`[ -t 1 ]`);
  piped/redirected output stays a clean table. The block contains an `add`
  hint for installable features, an `update` hint for outdated ones (or
  `Everything is up to date.` when neither applies), and ALWAYS ends with
  `Run 'chosko-llm show <feature>' to inspect a feature.` Installable and
  updatable names are accumulated from the filtered rows during the three
  listing passes, so counts reflect what was actually shown.

## Domain dependencies

- `../../CLAUDE.md` — "filesystem is the source of truth, no lockfile". This
  script implements that by walking both directories.

## Cross-references

- [shared-lib.md](./shared-lib.md) — uses `inst_command_path`,
  `src_command_path`, and skill equivalents, plus `read_frontmatter_field`.
- [cmd-add.md](./cmd-add.md) / [cmd-update.md](./cmd-update.md) — the
  features `ls` shows are produced/consumed by these.
- [cmd-show.md](./cmd-show.md) — the single-feature deep-dive the footer's
  inspect hint points at; shares the status/kind vocabulary.

## When to read the source

- Changing column layout, filter flags, or output formatting →
  `scripts/cmd-ls.sh`.
- Changing how names are deduplicated across the two homes → the
  `collect_names` function in `cmd-ls.sh`.
