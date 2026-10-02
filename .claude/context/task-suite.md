# Features: task suite

## Overview

Covers the backlog's shipped artifacts: the `task-*` commands and skills and
the `task-engine` reference library they read. Feature kinds:
[features.md](./features.md); the frontmatter contract every one of them
follows: [feature-contract.md](./feature-contract.md).

- [task-backlog.md](./task-backlog.md) — `commands/task-setup.md`,
  `skills/task-clean/`, `commands/task-list.md`.
- [task-engine.md](./task-engine.md) — `skills/task-engine/`.
- [task-add.md](./task-add.md) — `commands/task-add.md`.
- [task-implement.md](./task-implement.md) — `skills/task-implement/`:
  common path, supporting files, parking, testing, `[STALE]`, preconditions.
- [task-implement-delegation.md](./task-implement-delegation.md) —
  `skills/task-implement/`: delegated runs, commits, closing report.
- [task-implement-review.md](./task-implement-review.md) —
  `skills/task-implement/`: `--review` rounds.
- [task-review-iterate.md](./task-review-iterate.md) — `skills/task-review/`,
  `skills/task-iterate/`.

## Public API

Each feature's contract is its bullet in its file's § Overview (listed above). Frontmatter,
`description` contract and loading-control keys:
[feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- None of their own: [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- `../domain/task-workflow.md` — backlog schema and the author/implementer
  split.
- Frontmatter schema: [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds.
- [feature-contract.md](./feature-contract.md) — frontmatter contract, the
  home-path guard.
- [pipeline.md](./pipeline.md) — the pipeline stages that feed `/task-add`
  and the `pipeline-engine` library beside `task-engine`.
- [runbook-suite.md](./runbook-suite.md) — the runbook suite, which shares
  `/task-implement`'s execution policy.

## When to read the source

- [features.md](./features.md) § When to read the source.
