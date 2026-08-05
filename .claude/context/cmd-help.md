# cmd-help

## Overview

`scripts/cmd-help.sh` print CLI usage. Default: cat `docs/cli-help.txt` from managed clone; missing → fall back small inline heredoc.

## Public API

CLI:
- `chosko-llm help` — also reachable via `chosko-llm`, `-h`, `--help`
  (proxy `bin/chosko-llm` route all these here).

Exit code: 0.

Side effects: print stdout. No filesystem writes.

## Internal patterns

- **Two sources for help text:** shipped `docs/cli-help.txt` primary source. Inline heredoc minimal fallback, used only when someone deleted/moved that file in managed clone (lists core subcommands incl. `task-impl`). Keep two in rough sync, but `.txt` file canonical, user-visible help.
- **`Usage:` headings bolded.** Both paths pipe through
  `_bold_usage_headings` (`sed` wrap `Usage:` in `C_BOLD`/`C_RESET`
  from `lib.sh`), color apply on TTY.
- **Proxy short-circuits to `cmd-help.sh` for no-arg case.** See
  routing in [cli-entry.md](./cli-entry.md).

## Domain dependencies

- `../../docs/cli-help.txt` — user-facing help text. Edits there picked up automatically; no need update this script.

## Cross-references

- [cli-entry.md](./cli-entry.md) — own proxy routing pointing
  `help` / `-h` / `--help` here.
- All sibling `cmd-*.md` files — many subcommands have own
  `-h` / `--help` flag handled locally (e.g. `cmd-ls.sh`); this script
  covers only global help.

## When to read the source

- Change fallback heredoc → `scripts/cmd-help.sh`.
- Change user-facing usage → edit `docs/cli-help.txt` (canonical),
  not this script.