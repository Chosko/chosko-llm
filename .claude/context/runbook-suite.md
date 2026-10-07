# Features: runbook suite

## Overview

Covers the runbook asset kind's shipped artifacts — the `runbook-*` commands
and skills — plus `follow-ups` and `follow-ups-resolve`. Feature kinds:
[features.md](./features.md); the frontmatter contract every one of them
follows: [feature-contract.md](./feature-contract.md).

Each feature's bullet lives in its own file:

- [runbook-run.md](./runbook-run.md) — `skills/runbook-run/`: store,
  reference files and dependencies.
- [runbook-run-loop.md](./runbook-run-loop.md) — `skills/runbook-run/`:
  execution policy, handles, ids, the step loop, parking, the spawn relay.
- [runbook-run-contracts.md](./runbook-run-contracts.md) —
  `skills/runbook-run/`: chat contract, closing report, commits, Stop-hook
  reply, hard contracts, bounds.
- [runbook-create.md](./runbook-create.md) — `commands/runbook-create.md`.
- [runbook-readers.md](./runbook-readers.md) — `commands/runbook-list.md`,
  `commands/runbook-describe.md`.
- [runbook-pruners.md](./runbook-pruners.md) — `commands/runbook-clean.md`,
  `commands/runbook-prune.md`.
- [follow-ups.md](./follow-ups.md) — `skills/runbook-suggest/`,
  `commands/follow-ups.md`, `skills/follow-ups-resolve/`.

## Public API

Each feature's contract is its bullet in its file's § Overview (listed above). Frontmatter,
`description` contract and loading-control keys:
[feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- [feature-contract.md](./feature-contract.md) § Internal patterns.
- The interaction policy: `/runbook-run`, `/runbook-create`,
  `/runbook-clean`, `/runbook-prune` and `follow-ups-resolve` declare
  `requires: skill:interaction-engine` and accept `--attended` /
  `--unattended` ([interaction-engine.md](./interaction-engine.md)).
  `confirmation`: `/runbook-create`'s gate and the step-amend gate.
  `destructive`: `/runbook-clean` and `/runbook-prune`. `design`:
  `follow-ups-resolve`'s list approval. `/runbook-run` parks a step;
  relays and contracts carry a plain summary of a draft, never the draft,
  with `show` fetching it.

## Domain dependencies

- `../domain/features/runbook-suite.md` — the runbook asset kind and its
  artifacts.
- Frontmatter schema: [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds.
- [feature-contract.md](./feature-contract.md) — frontmatter contract, the
  home-path guard.
- [task-implement.md](./task-implement.md) — `/task-implement`, the other runner of
  the execution policy.
- [pipeline.md](./pipeline.md) — `pipeline-engine`'s `RUNBOOKS.md` edges and
  `pipeline-revise`'s runbook steps.

## When to read the source

- [features.md](./features.md) § When to read the source.
