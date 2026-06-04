# cmd-help

## Overview

`scripts/cmd-help.sh` prints CLI usage. Default path is to cat
`docs/cli-help.txt` from the managed clone; if that file is missing, it
falls back to a small inline heredoc.

## Public API

CLI:
- `chosko-llm help` — also reachable via `chosko-llm`, `-h`, or `--help`
  (the proxy at `bin/chosko-llm` routes all of these here).

Exit code: 0.

Side effects: prints to stdout. No filesystem writes.

## Internal patterns

- **Two sources for the help text:** the shipped `docs/cli-help.txt` is the
  primary source. The inline heredoc is a minimal fallback used only when
  someone has deleted or moved that file in the managed clone (it lists the
  core subcommands incl. `task-impl`). Keep the two in rough sync, but the
  `.txt` file is the canonical, user-visible help.
- **`Usage:` headings are bolded.** Both paths pipe through
  `_bold_usage_headings` (a `sed` that wraps `Usage:` in `C_BOLD`/`C_RESET`
  from `lib.sh`), so color applies on a TTY.
- **The proxy short-circuits to `cmd-help.sh` for the no-arg case.** See
  the routing in [cli-entry.md](./cli-entry.md).

## Domain dependencies

- `../../docs/cli-help.txt` — the user-facing help text. Edits there are
  picked up automatically; no need to update this script.

## Cross-references

- [cli-entry.md](./cli-entry.md) — owns the proxy routing that points
  `help` / `-h` / `--help` here.
- All sibling `cmd-*.md` files — many subcommands have their own
  `-h` / `--help` flag handled locally (e.g. `cmd-ls.sh`); this script
  covers only the global help.

## When to read the source

- Changing the fallback heredoc → `scripts/cmd-help.sh`.
- Changing the user-facing usage → edit `docs/cli-help.txt` (canonical),
  not this script.
