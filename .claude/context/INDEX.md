# Context index

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
| [cli-entry.md](./cli-entry.md) | Bootstrap (`install.sh`/`uninstall.sh`) and the `bin/chosko-llm` proxy that dispatches subcommands. |
| [shared-lib.md](./shared-lib.md) | `scripts/lib.sh` — logging, frontmatter, path resolution, semver, validation. Sourced by every subcommand. |
| [cmd-ls.md](./cmd-ls.md) | `scripts/cmd-ls.sh` — list features with installed/latest versions; `--installed` / `--available` filters. |
| [cmd-add.md](./cmd-add.md) | `scripts/cmd-add.sh` — install a feature into `$CLAUDE_HOME`; refuses if already installed. |
| [cmd-rm.md](./cmd-rm.md) | `scripts/cmd-rm.sh` — uninstall a feature from `$CLAUDE_HOME`. |
| [cmd-update.md](./cmd-update.md) | `scripts/cmd-update.sh` — re-copy a feature (or `--all`); installs if missing. |
| [cmd-upgrade.md](./cmd-upgrade.md) | `scripts/cmd-upgrade.sh` — `git pull` the managed clone and refresh the proxy. |
| [cmd-help.md](./cmd-help.md) | `scripts/cmd-help.sh` — print `docs/cli-help.txt` or fallback help. |
| [features.md](./features.md) | Shipped artifacts under `commands/`, `skills/`, and `tests/smoke/`; cross-refs to the authoring guide. |

## Conventions

- Source references use repo-root-relative paths and fully qualified names,
  e.g. `scripts/lib.sh::resolve_feature`.
- Cross-references to sibling context files use relative links (`./other.md`).
- Cross-references to canonical docs use `../../`-prefixed paths.
