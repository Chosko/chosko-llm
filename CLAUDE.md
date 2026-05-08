# CLAUDE.md — chosko-llm

## Navigation

For any task involving this codebase, start by reading
[.claude/context/INDEX.md](.claude/context/INDEX.md). Then read only the
context files relevant to your task. Open source files (under `scripts/`,
`bin/`, `install.sh`, `uninstall.sh`, etc.) only when the relevant context
file's **When to read the source** section indicates it is necessary.

## About

This repo ships global Claude Code **commands** and **skills**, plus a small
shell CLI (`chosko-llm`) that installs them into `~/.claude/` on any machine.
There are two roles for the same git repo:

- **Working repo** — wherever the user develops. Features are authored and
  committed here.
- **Managed clone** at `~/.chosko-llm/` — created by `install.sh`. The
  `chosko-llm` proxy at `~/bin/chosko-llm` reads from this clone. Never edit it
  directly.

The CLI is a proxy: `~/bin/chosko-llm` parses the subcommand and execs
`~/.chosko-llm/scripts/cmd-<sub>.sh`. So CLI logic ships via `git pull`
(`chosko-llm upgrade`), not by re-running `install.sh`.

## Authoritative references

- **Design rules** — see [README.md](README.md) and the design rules embedded
  in this repo's history (versioning, copy-not-symlink, env overrides
  `CHOSKO_LLM_HOME` / `CLAUDE_HOME`, idempotency).
- **Authoring** — [docs/authoring-guide.md](docs/authoring-guide.md) is the
  source of truth for frontmatter schema, naming, and versioning.

## Hard rules

- Every command (`commands/<name>.md`) and every skill (`skills/<name>/SKILL.md`)
  has YAML frontmatter with `name`, `version`, `type`, `description`. Files
  missing `version` will be rejected by `cmd-add` / `cmd-update`.
- The filesystem is the source of truth. There is no lockfile. `ls --installed`
  walks `~/.claude/`; `ls --available` walks `~/.chosko-llm/`.
- Install mode is **copy**, never symlink. Edits in the working repo do not
  reach `~/.claude/` until the user runs `chosko-llm update`.
- All scripts honor `CHOSKO_LLM_HOME` and `CLAUDE_HOME`. Don't hardcode
  `~/.chosko-llm` or `~/.claude` in new code — use the helpers in
  `scripts/lib.sh`.
- Every script under `scripts/` starts with `set -euo pipefail` and sources
  `lib.sh`.

## When asked to add a new feature

1. Decide command vs. skill. Commands are single `.md` files; skills are
   folders with a `SKILL.md` and optional supporting files.
2. Create the file (or folder + `SKILL.md`) under `commands/` or `skills/`
   with full frontmatter. `name` MUST match the filename / folder name
   (kebab-case).
3. Start at `version: 0.1.0` for new features. See the authoring guide for
   bump rules.
4. Add a smoke-test checklist at `tests/smoke/<name>.md`.
5. Tell the user the working-repo verification path:
   `cd` into a clone where `install.sh` has already run, then
   `./bin/chosko-llm ls --available` should list the new feature with `[new]`.

## When asked to change CLI behavior

CLI logic lives in `bin/chosko-llm` (proxy only — keep it minimal) and
`scripts/cmd-*.sh`. Shared helpers belong in `scripts/lib.sh`. Changes ride
to users via `chosko-llm upgrade`; users do not need to re-run `install.sh`
unless `bin/chosko-llm` itself changed in a way that broke pre-existing
proxies — in that case, document it in the commit.

## Things to avoid

- Adding new dependencies (yq, jq, python). Keep everything POSIX-ish bash
  with awk/sed/grep. `parse_frontmatter` in `lib.sh` is intentionally minimal.
- Symlink-based install modes. The user has explicitly chosen copy semantics.
- Lockfiles or state files. The filesystem and frontmatter are the state.
