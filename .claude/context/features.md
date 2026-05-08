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
- `commands/context-build.md` — introduces a navigation context layer.
- `commands/context-update.md` — refreshes an existing context layer.
- No skills yet (`skills/` contains only `.gitkeep`).

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
