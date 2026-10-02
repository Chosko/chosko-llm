# Features: task-implement review rounds

## Overview

Covers `/task-implement --review`: the review/iterate loop, its flags and
the reviewer spawn. Starts in [task-implement.md](./task-implement.md),
continued in [task-implement-delegation.md](./task-implement-delegation.md).
The rest of the suite: [task-suite.md](./task-suite.md).

- `skills/task-implement/`, continued from [task-implement-delegation.md](./task-implement-delegation.md):
  `--review` (with optional `--rounds N`, default 1) runs a review/iterate
  loop per task. Availability gate first: both `task-review` and
  `task-iterate` must be present in the session or the run stops BEFORE any
  `[IN PROGRESS]` flip — never silently skipped, since "implemented" and
  "implemented and reviewed" are different claims. `--rounds` without
  `--review` errors (`--rounds requires --review.`); a non-positive integer
  errors (`--rounds needs a positive integer.`).
  Two cost-control flags steer the spawned reviewer, both defaulting to
  `auto` and both erroring without `--review` in the same shape `--rounds`
  uses: `--review-model <name>|same|auto` (`--review-model requires
  --review.`) and `--review-effort shallow|standard|deep|same|auto`
  (`--review-effort requires --review.`, plus a value check naming the five
  legal levels). Model names pass VERBATIM to the Agent tool — no local
  allow-list, since a hardcoded roster would refuse a model that works.
  The pair resolves **per task, at the top of each round**, never once per
  run, from that round's own diff plus the criteria count already in hand,
  which is what keeps a batch O(1); the two values feed exactly two places —
  the model decides whether the Agent call carries `model:` (omitted on
  `same`, so the child inherits), the effort decides whether the spawn
  prompt carries a budget block (omitted on `same`, so the reviewer reads
  unbounded). Neither the tier table nor the budget table is restated in the
  skill: `task-engine`'s `references/review-budget.md` is their single
  authority and `review-rounds.md` reads it. Loop sits after Step 5 and
  **before Step 6**, on the uncommitted tree — before, not between 6 and 7,
  so a halt on unresolved findings leaves the task `[IN PROGRESS]` rather
  than `[DONE]`-and-halted. Each round spawns `/task-review` as a
  **subagent** (`subagent_type: general-purpose`) — fresh context is the
  mechanism, not an optimizable detail — with an eight-item prompt (repo path,
  `task=<n>`, this round's diff scope, round number, prior rejection ledger
  from round 2 on, and the statement that it was spawned by
  `/task-implement --review`, which selects `/task-review`'s spawned output
  destination rather than restating its rule, the test-suite
  state — green under the resolved policy, or skip-tests and nothing ran,
  handed in because the reviewer runs no test command itself — and the
  budget block, omitted entirely when the effort resolved to `same`). That spawn
  returns **asynchronously**: the call yields an agent id and the findings
  arrive later as a separate notification, so the round waits for them and
  Steps 6/7 are unreachable until the final round's result has actually
  arrived — treating the call's return value as the findings would commit
  unreviewed work while reporting it reviewed. `/task-iterate` then runs in
  **this** session (its edits must land in the tree Step 7 commits), told
  explicitly it is inside a round and must not commit. Loop continues only
  while `BLOCKING` findings remain unresolved and only up to `ROUNDS`; later
  rounds re-review only the hunks the last iterate changed; rejections are
  sticky across rounds. Unresolved `BLOCKING` after the last round stops the
  whole run per FAILURE HANDLING (tree uncommitted, task `[IN PROGRESS]`, no
  next task). Exactly one commit per task either way — the fixes ride in the
  task's own commit, never a second one. In a delegated run REVIEW/ROUNDS
  plus REVIEW_MODEL/REVIEW_EFFORT
  ride through the fixed-size hand-off prompt as two more strings and each
  implementor spawns
  its own reviewer, measuring its own diff (launcher → implementor →
  reviewer; the launcher measures nothing); no finding travels up to the
  parent through the return contract: `/follow-ups`' exclusion rule keeps a
  finding out of the fifth field, a finding not being an unrecorded piece
  of work. What its reading does catch is a deferral
  `/task-iterate` noted should become a task and that never did.

## Public API

- Each feature's contract is its text in § Overview. Frontmatter,
  `description` contract and loading-control keys:
  [task-suite.md](./task-suite.md) § Public API.

## Internal patterns

- [task-suite.md](./task-suite.md) § Internal patterns.

## Domain dependencies

- [task-suite.md](./task-suite.md) § Domain dependencies.

## Cross-references

- [task-suite.md](./task-suite.md) — the task-suite hub and its file list.
- [task-implement.md](./task-implement.md),
  [task-implement-delegation.md](./task-implement-delegation.md) — the rest
  of `/task-implement`.
- [task-review-iterate.md](./task-review-iterate.md) — the two skills each
  round runs.
- [task-engine.md](./task-engine.md) — `references/review-budget.md`.

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
