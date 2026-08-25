# CLAUDE.md — chosko-llm

## Navigation

Two navigation layers, separate jobs:

- **Codebase structure** — which file implements what: read [.claude/context/INDEX.md](.claude/context/INDEX.md) first on any task on this codebase. Then read only context files relevant to task. Open source files (under `scripts/`, `bin/`, `install.sh`, `uninstall.sh`, etc.) only when relevant context file's **When to read the source** section says needed.
- **Product and domain knowledge** — what this product is, how its features are designed, and why the architecture is what it is: read [.claude/domain/INDEX.md](.claude/domain/INDEX.md), then only the domain files relevant to your task.

## About

Repo ships global Claude Code **commands** and **skills**, plus small shell CLI (`chosko-llm`) installing them into `~/.claude/` on any machine. Two roles, same git repo:

- **Working repo** — wherever user develops. Features authored, committed here.
- **Managed clone** at `~/.chosko-llm/` — created by `install.sh`. `chosko-llm` proxy at `~/bin/chosko-llm` reads from this clone. Never edit direct.

CLI is proxy: `~/bin/chosko-llm` parses subcommand, execs `~/.chosko-llm/scripts/cmd-<sub>.sh`. CLI logic ships via `git pull` (`chosko-llm upgrade`), not re-running `install.sh`.

## Authoritative references

- **Design rules** — see [README.md](README.md) and design rules embedded in repo history (versioning, copy-not-symlink, env overrides `CHOSKO_LLM_HOME` / `CLAUDE_HOME`, idempotency).
- **Authoring** — [docs/authoring-guide.md](docs/authoring-guide.md) is source of truth for frontmatter schema, naming, versioning. "docs/ is authoring-time-only" note load-bearing: `docs/` never installed to `~/.claude/`, so shipped command/skill body must never tell executing agent to read `docs/` path at runtime.
- **Task workflow** — [.claude/domain/task-workflow.md](.claude/domain/task-workflow.md) explains author/implementer split (Claude Code authors via `/task-add`, implements via `/task-implement`) and per-task body schema. Read when touching any `task-*` command or body schema.
- **Context workflow** — [.claude/domain/context-workflow.md](.claude/domain/context-workflow.md) explains navigation context layer under `.claude/context/`: why exists, three skills (`/context-build`, `/context-update`, `/context-convert`), six-section per-file schema, `Layout:` marker + flat vs. nested layout, `INDEX.md` `Last updated` anchor (per-leaf when nested), four `/context-update` modes. Read when touching any of those skills or context-file schema.
- **Refactor workflow** — [.claude/domain/refactor-workflow.md](.claude/domain/refactor-workflow.md) explains philosophy + invariants behind `/refactor-codebase`: behaviour preservation, plan-first approval gate, five focus concerns, `scope=` semantics, phase ordering. Read when touching `/refactor-codebase` or extending phase model.
- **Product workflow** — [.claude/domain/product-workflow.md](.claude/domain/product-workflow.md) explains product pipeline, stages 0–6 (`/domain-setup` → `/product-design` → `/product-roadmap` → `/architect` → `/production-plan` → `/task-add` → `/task-implement`), plus read side `/production-status` + milestone grouping in `/task-list`: document set, `FEATURES.md` schema + feature state machine, `product-roadmap.md` milestones + `Source:` milestone parenthetical, `PLAN.md` schema + `[PLANNED]`/`[ACTIVE]`/`[SHIPPED]`, `[STALE]` task status + `Feature:` line, iterate guard, reconciliation protocol. Read when touching those commands or feature/task/plan schemas.
  **This repo itself uses only `FEATURES.md` + `TASKS.md`** — no `PLAN.md`, no `product-roadmap.md`, no milestones. It is tooling, not a product; never generate them here.

## Hard rules

- Every feature — command (`commands/<name>.md`), skill (`skills/<name>/SKILL.md`), claude-md (`claude-md/<name>.md`), statusline (`statusline/<name>.sh`), hook (`hooks/<name>.sh`) — needs YAML frontmatter: `name`, `version`, `type`, `description`. Files missing `version` rejected by `cmd-add` / `cmd-update`. Hooks additionally need `event:` (and may carry `matcher:`); `.sh` kinds keep their frontmatter in a bash no-op heredoc after the shebang.
- Filesystem = source of truth. No lockfile. `ls --installed` walks `~/.claude/`; `ls --available` walks `~/.chosko-llm/`.
- Install mode: **copy**, never symlink. Edits in working repo don't reach `~/.claude/` until user runs `chosko-llm update`.
- All scripts honor `CHOSKO_LLM_HOME` and `CLAUDE_HOME`. Don't hardcode `~/.chosko-llm` or `~/.claude` in new code — use helpers in `scripts/lib.sh`.
- Every script under `scripts/` starts with `set -euo pipefail`, sources `lib.sh`.

## Testing

Testing policy for /task-implement: skip-tests-unattended

No test suite by design. Ships markdown prompts + thin shell wrappers; changes verified by reading diff + running CLI against real clone.

## Versioning

- Bump root `VERSION` file on **every shipped change** — features, CLI behavior, scripts. It's repo-level version `install.sh` reports; if never moves, reported version drifts from reality.
- **Project documentation is exempt.** Change confined to `README.md`, `docs/`, `.claude/domain/`, `.claude/context/` or `CLAUDE.md` itself bumps no `VERSION` and gets no `CHANGELOG` entry — nothing user receives behaves differently. Boundary: shipped feature's own body (`commands/*.md`, `skills/*/SKILL.md`, `claude-md/*.md`, `statusline/*.sh`, `hooks/*.sh`) is **not** documentation — it's product, bumps as always even though it's markdown.
- Semver bump: **patch** for fixes, **minor** for new feature/command/skill, **major** for breaking CLI surface change.
- Root `VERSION` distinct from per-feature `version:` frontmatter on command/skill (versions that one feature for `cmd-add` / `cmd-update`). Bumping feature frontmatter doesn't replace bumping `VERSION`; feature change bumps both.
- **`VERSION` bump without matching `CHANGELOG.md` section is incomplete change.** New section goes on top, `## <version> — <YYYY-MM-DD>`, short user-facing bullets. Converse holds too: **change that doesn't bump `VERSION` gets no `CHANGELOG` entry** — artifacts exempt from the bump (next bullet) never get one. Schema + ordering rule in [docs/authoring-guide.md](docs/authoring-guide.md) § Versioning. Run `./scripts/check-changelog.sh` after bumping — silent on success, non-zero when top section doesn't match `VERSION`.
- **One exception, narrow: skills under this repo's own `.claude/skills/`.** Repo-local development tooling — no `version:` frontmatter, invisible to every CLI verb, installed nowhere. Change confined to them does **not** bump root `VERSION`: bumping for file no user receives corrupts meaning of version `install.sh` reports. Rest of `.claude/` — context layer, domain layer, backlog — unaffected, bumps as usual.

## When asked to add new feature

1. Decide the kind. Commands = single `.md` files; skills = folders with `SKILL.md` + optional supporting files; claude-md = a section injected into a CLAUDE.md; statusline = a status-bar `.sh` (global-only); hook = a `.sh` Claude Code runs on a hook event (local-only — it must be committed to the repo it governs).
2. Create file (or folder + `SKILL.md`) under `commands/` or `skills/` with full frontmatter. `name` MUST match filename/folder name (kebab-case).
3. Start new features at `version: 0.1.0`. See authoring guide for bump rules.
4. Tell user working-repo verification path: `cd` into clone where `install.sh` already ran, then `./bin/chosko-llm ls --available` should list new feature w/ correct version.

## When asked to change CLI behavior

CLI logic lives in `bin/chosko-llm` (proxy only — keep minimal) and `scripts/cmd-*.sh`. Shared helpers in `scripts/lib.sh`. Changes ride to users via `chosko-llm upgrade`; users needn't re-run `install.sh` unless `bin/chosko-llm` itself changed in way that broke pre-existing proxies — then document in commit.

## Things to avoid

- New dependencies (yq, jq, python). Keep everything POSIX-ish bash w/ awk/sed/grep. `parse_frontmatter` in `lib.sh` intentionally minimal.
- Symlink-based install modes. User explicitly chose copy semantics.
- Lockfiles or state files. Filesystem + frontmatter is state.