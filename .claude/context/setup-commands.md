# Features: setup commands

## Overview

Covers the project-initialization commands. Feature
kinds: [features.md](./features.md); the frontmatter contract every one of
them follows: [feature-contract.md](./feature-contract.md).

- `commands/project-setup.md` — interactive first-time project init
  wizard. Two phases: GATHER phase collects every choice upfront (VCS
  detection, CLAUDE.md seeding from pasted source, AGENTS.md, task backlog,
  domain layer, context layer, testing policy on every project — none /
  `full-tdd` / `skip-tests` / `skip-tests-unattended` — interaction policy,
  claude-md sections and hook), EXECUTE phase applies them in
  fixed order.
  **Authoring command — makes NO commits by default.** Writes own
  artifacts (CLAUDE.md project-info section synthesized from user-pasted
  material only; `## VCS` section mapping git→`cm` for non-git VCS like
  Plastic SCM — add, commit, status, rev-parse, diff, log, mv, rm, show,
  branch rows — after which it warns in one line that a non-git VCS
  disables parking; `## Tasks implementation` section carrying the chosen
  testing-policy line, plus editor dirty-tree noise bullets on Unity
  projects; `Interaction policy: unattended` line when chosen, nothing for
  the `attended` default; AGENTS.md), installs the picked claude-md
  sections (`editing-discipline`, required by `/doc-consolidate`,
  `git-commit-style`, `tool-usage-policy`) and the
  `remote-session-protocol` hook with `chosko-llm add --local` — relaying
  the hook's `settings.json` wiring prompt, never editing it — then runs
  heavy sub-commands last —
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
  Final report suggests `/product-design` and `/architect` when the
  domain layer was set up. What it must offer is checked by
  `scripts/check-setup.sh` ([feature-contract.md](./feature-contract.md)
  § Public API).
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
  `/architect`. Carries no copy of the `FEATURES.md` entry schema — cites
  `/architect`'s `feature-doc-template.md` relatively and declares
  `requires: skill:architect`. **Authoring command — leaves scaffolding uncommitted
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
