# Features: setup commands

## Overview

Covers the project-initialization commands. Feature
kinds: [features.md](./features.md); the frontmatter contract every one of
them follows: [feature-contract.md](./feature-contract.md).

- `commands/project-setup.md` — interactive first-time project init
  wizard. Two phases: GATHER phase collects every choice upfront (VCS
  detection, CLAUDE.md seeding from pasted source, AGENTS.md, task backlog,
  domain layer, context layer), EXECUTE phase applies them in
  fixed order.
  **Authoring command — makes NO commits by default.** Writes own
  artifacts (CLAUDE.md project-info section synthesized from user-pasted
  material only, `## VCS` section mapping git→`cm` for non-git VCS like
  Plastic SCM, `## Tasks implementation` section on Unity projects
  covering editor dirty-tree noise and optional skip-tests
  testing-policy marker, and AGENTS.md), then runs heavy sub-commands last —
  `/task-setup` (leaves scaffolding uncommitted by default), then
  `/domain-setup` (Step 5b — deliberately BEFORE context layer, since
  `/context-build`'s DOMAIN DEPENDENCIES sections link to domain files; its
  GATHER step detects existing `.claude/domain/` and offers indexing docs
  already there), then
  `/context-build` (most context-hungry, gated step, and the wizard always
  invokes it in its default FLAT layout — never `nested`). By default
  everything, including
  sub-commands' output, left uncommitted for user review and commit
  in one pass — `../../docs/authoring-guide.md` § Commit-and-push
  convention. With `--commit` it
  commits own artifacts first, then runs sub-commands with `--commit`
  so each commits own output. VCS detection decides whether to inject
  VCS-mapping section (and, under `--commit`, which VCS commits target).
- `commands/domain-setup.md` — initializes domain knowledge layer, same
  way `/task-setup` initializes backlog: `.claude/domain/`,
  `.claude/domain/features/`, `.claude/domain/INDEX.md` whose
  `| File | Covers |` table matches context INDEX's shape,
  `.claude/FEATURES.md` stub (a `.claude/` root sibling of `TASKS.md`,
  since it indexes work items — feature *documents* live in
  domain layer), and CLAUDE.md pointer at domain index that composes
  with `/context-build`'s context-layer pointer instead of replacing it.
  Idempotent, probe-per-artifact; on project with hand-written domain
  docs indexes them (heading + opening paragraph → "Covers" cell)
  rather than writing empty index. Creates layer and nothing in it —
  design documents and feature entries belong to `/product-design` and
  `/architect`. **Authoring command — leaves scaffolding uncommitted
  by default; `--commit` stages exactly `WRITTEN` paths in one commit.**
## Public API

- None beyond [feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- None beyond [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- None beyond [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds and the rest of the shipped
  inventory; [feature-contract.md](./feature-contract.md) — the frontmatter
  contract these features follow.

## When to read the source

- None beyond [features.md](./features.md) § When to read the source.
