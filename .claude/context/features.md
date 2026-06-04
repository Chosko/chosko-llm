# Features (commands & skills)

The artifacts this repo *ships*. The CLI exists to install and update them.

## Overview

Three locations, all keyed by feature name (kebab-case):

- `commands/<name>.md` — a single markdown file with YAML frontmatter. The
  body is the prompt Claude Code runs when the user invokes `/<name>`.
- `skills/<name>/SKILL.md` — a folder containing `SKILL.md` plus any
  supporting files. The folder is copied recursively on install.
- `tests/smoke/<name>.md` — a manual checklist for verifying the feature
  still works after edits. Format documented in
  `tests/smoke/README.md`.

Currently shipped:
- `commands/project-setup.md` — interactive first-time project initialization
  wizard. Two phases: a GATHER phase that collects every choice upfront (VCS
  detection, CLAUDE.md seeding from pasted source, AGENTS.md, task backlog,
  context layer), and an EXECUTE phase that applies them in a fixed order.
  **Pure authoring command — makes NO commits.** It writes its own artifacts
  (CLAUDE.md project-info section synthesized from user-pasted material only,
  a `## VCS` section mapping git→`cm` for non-git VCS like Plastic SCM, and
  AGENTS.md), then runs the heavy sub-commands last — `/task-setup` (which
  leaves its scaffolding uncommitted by default) then `/context-build` (the most context-hungry,
  gated command, run last so it can't strand the earlier steps). Everything,
  including the sub-commands' output, is left uncommitted for the user to
  review and commit in one pass — matching the other authoring commands
  (`/context-build`, `/context-update`, `/task-enrich`, `/refactor-*`). VCS
  detection exists only to decide whether to inject the VCS-mapping section;
  project-setup never runs a VCS command itself, so it is VCS-agnostic.
- `commands/context-build.md` — introduces a navigation context layer.
- `commands/context-update.md` — refreshes an existing context layer, then
  auto-commits the context files it updated (explicit paths only; no commit
  when nothing changed). Joins the auto-committing group with `/task-add`
  and `/task-clean`.
- `commands/task-setup.md` — initialize the backlog: `.claude/TASKS.md`
  stub, `.claude/tasks/` directory, and `.claude/external/implement-prompt.md`
  (the static system prompt fed to an external LLM via aider). Required
  before `/task-add`. Idempotent — re-runs only fill in missing artifacts
  and never overwrite an edited implement-prompt. **Pure authoring command —
  runs no git command; leaves its scaffolding uncommitted for the user to
  review.**
- `commands/task-add.md` — plan and append a new task conversationally:
  writes a summary block to `.claude/TASKS.md` and a thin body file at
  `.claude/tasks/<N>.md`. The default body schema (target: claude) contains
  Goal, Acceptance criteria, Decisions (when applicable), and Hints. With
  `--enrich`, produces an enriched body (target: local) in one shot by
  reading `/task-enrich` for format guidance. Refuses if `/task-setup` has
  not run. Auto-commits the two written files.
- `commands/task-clean.md` — prune terminal-status tasks. Removes summary
  blocks AND deletes the matching body files. Never renumbers — task IDs
  are stable across the project's lifetime; the `Last task number`
  counter never decreases. After applying, commits the changes
  automatically (`.claude/TASKS.md` + deleted body files).
- `commands/task-implement.md` — implement backlog tasks end-to-end with
  TDD. Reads each task's body file from `.claude/tasks/<N>.md` only when
  needed and treats it as the primary context source when the v0.3+
  schema is present (Files to modify / Required reading / Conventions
  to follow / Out of scope) — only fans out to CLAUDE.md and the
  context layer when the body doesn't cover what's needed. Older
  bodies trigger the previous "consult context layer" fallback. Status
  flips happen in `.claude/TASKS.md`.
- `commands/task-list.md` — print the backlog as a compact read-only
  summary. Reads only `.claude/TASKS.md`; never opens the body files.
- `commands/task-enrich.md` — expand a thin (`target: claude`) task body
  into an enriched self-contained body (`target: local`) for a local LLM
  implementer. Appends `## Context bundle` and `## Implementation steps`
  sections; updates `Target:` to `local`. Does not commit.

## Public API (per-feature contract)

Every feature file requires a complete frontmatter block:
```yaml
---
name: <kebab-case>          # MUST match filename / folder name
version: <semver>           # required; install refuses without it
type: command | skill
description: <one line>
---
```

See `../../docs/authoring-guide.md` for the canonical spec, including the
semver bump rules.

## Internal patterns

- **Filename = folder name = `name` field.** A mismatch breaks `update --all`
  because `cmd-ls`/`cmd-update` iterate filesystem entries while resolution
  by user input goes via `name`. The authoring guide flags this as a common
  mistake.
- **Skills are folders, not single files.** A bare `skills/foo.md` is
  ignored by every script. See `feature_kind` in
  [shared-lib.md](./shared-lib.md).
- **Smoke tests bump alongside `version`.** The test file is named for the
  feature's `name` frontmatter, not its filename, although the two should
  always match (see above).
- **No state file.** Versions live in frontmatter; what's installed is
  whatever exists under `$CLAUDE_HOME`. See `../../CLAUDE.md` hard rules.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter schema, naming rules,
  semver bump table. Canonical.
- `../../CLAUDE.md` — hard rules: every feature has frontmatter; filesystem
  is the source of truth; copy-not-symlink; `cmd-add` / `cmd-update` reject
  files missing `version`.
- `tests/smoke/README.md` — smoke test file format.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `parse_frontmatter`,
  `require_versioned_source`, and the path helpers that locate features.
- [cmd-add.md](./cmd-add.md), [cmd-update.md](./cmd-update.md),
  [cmd-rm.md](./cmd-rm.md), [cmd-ls.md](./cmd-ls.md) — the verbs that
  operate on these artifacts.

## When to read the source

- Authoring or modifying a specific feature → the relevant
  `commands/<name>.md` or `skills/<name>/SKILL.md`. The body content is
  outside the scope of this navigation layer; it's prompt material for
  Claude Code, not project source.
- Adding/removing a frontmatter field → `../../docs/authoring-guide.md` plus
  `parse_frontmatter` in `scripts/lib.sh` (see
  [shared-lib.md](./shared-lib.md)).
- Changing the smoke-test format → `tests/smoke/README.md`.
