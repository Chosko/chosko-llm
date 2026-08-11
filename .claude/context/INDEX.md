# Context index

Layout: flat

Last updated: 2026-08-11

Nav layer for `chosko-llm`. Read this first, then files relevant to task. Open source files only when context file's **When to read the source** section say necessary.

Canonical project docs live outside this folder, stay authoritative:
- `../../CLAUDE.md` — hard rules, authoring entry-point.
- `../../README.md` — user-facing overview.
- `../../docs/authoring-guide.md` — frontmatter/versioning truth.
- `../../docs/cli-help.txt` — CLI help text shipped to users.

## Files

| File | Covers |
| --- | --- |
| [cli-entry.md](./cli-entry.md) | Bootstrap (`install.sh`/`uninstall.sh`), `bin/chosko-llm` proxy dispatch subcommands, daily auto-upgrade hook. |
| [shared-lib.md](./shared-lib.md) | `scripts/lib.sh` — logging, colors, frontmatter, path resolution, claude-md sections, statusline prompt, auto-upgrade state, validation. Sourced by every subcommand. |
| [cmd-ls.md](./cmd-ls.md) | `scripts/cmd-ls.sh` — list features w/ installed/latest versions; `--installed` / `--available` filters; TTY footer hints. |
| [cmd-show.md](./cmd-show.md) | `scripts/cmd-show.sh` — inspect one feature (versions, status, description, body/diff); handle local-only. |
| [cmd-add.md](./cmd-add.md) | `scripts/cmd-add.sh` — install feature (command/skill/claude-md/statusline, or `--all`) into `$CLAUDE_HOME`; refuse if already installed. |
| [cmd-rm.md](./cmd-rm.md) | `scripts/cmd-rm.sh` — uninstall feature (command/skill/claude-md/statusline) from `$CLAUDE_HOME`. |
| [cmd-update.md](./cmd-update.md) | `scripts/cmd-update.sh` — re-copy feature (or version-aware `--all`); install if missing. |
| [cmd-upgrade.md](./cmd-upgrade.md) | `scripts/cmd-upgrade.sh` — `git pull` managed clone, refresh proxy; `--enable-auto`/`--disable-auto` toggle. |
| [cmd-channel.md](./cmd-channel.md) | `scripts/cmd-channel.sh` — point managed clone at branch ('channel') to test unmerged work; no-arg show current, `--list` show available, `<branch>` switch + refresh proxy. |
| [cmd-export.md](./cmd-export.md) | `scripts/cmd-export.sh` — package repo's Claude config into Markdown file or zip via `select_export_files`; output dir from `export_dir_path`. |
| [cmd-help.md](./cmd-help.md) | `scripts/cmd-help.sh` — print `docs/cli-help.txt` or fallback help. |
| [cmd-task-impl.md](./cmd-task-impl.md) | `scripts/cmd-task-impl.sh` — external-LLM (aider+Ollama) orchestrator of 7-step task-implement flow for current project. |
| [lib-task-external.md](./lib-task-external.md) | `scripts/lib-task-external.sh` — project-scoped backlog parse/mutate/guard helpers beneath `cmd-task-impl.sh`. |
| [features.md](./features.md) | Shipped artifacts under `commands/`, `skills/`, `claude-md/`, `statusline/`; frontmatter contract incl. optional `replaces:`; cross-refs to authoring guide. |

## Domain

Product and rules knowledge — what the product is, why it is built this way — lives in its own layer and is indexed there, not here: [../domain/INDEX.md](../domain/INDEX.md).

## Conventions

- `Layout: flat` under the title declares this layer's shape: one index, every context file beside it. Deliberate — thirteen files, no unit seams worth a router. Read the marker, never infer the layout. Restructuring is `/context-convert`'s job, not a hand edit.
- Source references use repo-root-relative paths + fully qualified names, e.g. `scripts/lib.sh::resolve_feature`.
- Cross-references to sibling context files use relative links (`./other.md`).
- Cross-references to canonical docs use `../../`-prefixed paths.