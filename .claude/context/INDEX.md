# Context index

Last updated: 2026-06-05

Navigation layer for `chosko-llm`. Read this first, then the files relevant to
your task. Open source files only when a context file's **When to read the
source** section says it's necessary.

Canonical project docs live outside this folder and remain authoritative:
- `../../CLAUDE.md` — hard rules and authoring entry-point.
- `../../README.md` — user-facing overview.
- `../../docs/authoring-guide.md` — frontmatter/versioning truth.
- `../../docs/cli-help.txt` — CLI help text shipped to users.

## Files

| File | Covers |
| --- | --- |
| [cli-entry.md](./cli-entry.md) | Bootstrap (`install.sh`/`uninstall.sh`), the `bin/chosko-llm` proxy that dispatches subcommands, and the daily auto-upgrade hook. |
| [shared-lib.md](./shared-lib.md) | `scripts/lib.sh` — logging, colors, frontmatter, path resolution, claude-md sections, auto-upgrade state, validation. Sourced by every subcommand. |
| [cmd-ls.md](./cmd-ls.md) | `scripts/cmd-ls.sh` — list features with installed/latest versions; `--installed` / `--available` filters; TTY footer hints. |
| [cmd-show.md](./cmd-show.md) | `scripts/cmd-show.sh` — inspect one feature (versions, status, description, body/diff); handles local-only. |
| [cmd-add.md](./cmd-add.md) | `scripts/cmd-add.sh` — install a feature (command/skill/claude-md, or `--all`) into `$CLAUDE_HOME`; refuses if already installed. |
| [cmd-rm.md](./cmd-rm.md) | `scripts/cmd-rm.sh` — uninstall a feature (command/skill/claude-md) from `$CLAUDE_HOME`. |
| [cmd-update.md](./cmd-update.md) | `scripts/cmd-update.sh` — re-copy a feature (or version-aware `--all`); installs if missing. |
| [cmd-upgrade.md](./cmd-upgrade.md) | `scripts/cmd-upgrade.sh` — `git pull` the managed clone, refresh the proxy; `--enable-auto`/`--disable-auto` toggles. |
| [cmd-help.md](./cmd-help.md) | `scripts/cmd-help.sh` — print `docs/cli-help.txt` or fallback help. |
| [cmd-task-impl.md](./cmd-task-impl.md) | `scripts/cmd-task-impl.sh` — external-LLM (aider+Ollama) orchestrator of the 8-step task-implement flow for the current project. |
| [features.md](./features.md) | Shipped artifacts under `commands/`, `skills/`, `claude-md/`, and `tests/smoke/`; cross-refs to the authoring guide. |

## Domain

| File | Covers |
| --- | --- |
| [../domain/task-workflow.md](../domain/task-workflow.md) | Dual-LLM task workflow: Claude Code authors via `/task-add`, qwen2.5-coder:14b via aider implements. Body schema, body↔TASKS.md split, static implement-prompt artifact. |
| [../domain/context-workflow.md](../domain/context-workflow.md) | Navigation context layer under `.claude/context/`: six-section per-file schema, INDEX.md `Last updated` anchor, four `/context-update` modes. |

## Conventions

- Source references use repo-root-relative paths and fully qualified names,
  e.g. `scripts/lib.sh::resolve_feature`.
- Cross-references to sibling context files use relative links (`./other.md`).
- Cross-references to canonical docs use `../../`-prefixed paths.
