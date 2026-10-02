# Features: runbook pruners

## Overview

Covers the runbook suite's two pruners: `commands/runbook-clean.md` and
`commands/runbook-prune.md`. The family hub:
[runbook-suite.md](./runbook-suite.md).

- `commands/runbook-clean.md` — pruning, `/task-clean`'s plan-and-confirm
  shape, except that it deletes: runbooks have no archive.
  `requires: skill:runbook-run` for the status vocabulary and block shape. Three
  stages: resolve (no arg = every `[DONE]`; `<id|name|id-name>` arguments,
  by the schema's rule = exactly those,
  and a named non-`[DONE]` runbook is refused BY NAME with its actual status,
  never silently skipped) → plan and confirm (name, created date, steps done/total, both paths;
  empty plan says so and stops) → remove and commit (delete each body at its
  block's `File:` path, printed verbatim in the plan, a legacy `<name>.md`
  included — never renames, never reads `body-migration.md`; remove
  index blocks incl. surrounding `---` rules, stage exactly those paths). An
  unknown name aborts the whole run **before anything is deleted**. Only
  `[DONE]` is eligible — narrower than `/task-clean`, which also takes `[SKIP]`;
  runbooks have no second terminal status. No `--force`, no status argument
  widening the set: a `[FAILED]` runbook is flipped by hand first, one visible
  committed edit. **Commit convention: cleanup** — commits and pushes by
  default (a deletion left uncommitted is the change most likely to be lost, and
  the confirm gate already served as the review pass); `--no-commit`/`--no-push`
  opt out.
- `commands/runbook-prune.md` — the other pruner, and the pair to
  `/runbook-clean`: **clean removes finished runbooks, prune removes finished
  steps from one live runbook**. `requires: skill:runbook-run` for the body
  schema, the markers and the two header fields, none of them restated in the
  body. Takes **exactly one** runbook as `<id|name|id-name>` (the schema's
  resolution rule); no step argument, no `--all`, no `--force` — the set is
  every `[x]` step in the named runbook, struck steps included, and `[ ]`, `[~]`
  and `[!]` are never touched. Refuses a `[RUNNING]` runbook and any body
  holding a `[~]` step (the body decides, not the index); `[PENDING]`,
  `[FAILED]` and `[DONE]` are all prunable, and `[FAILED]` is where it helps
  most. Nothing to prune says so and stops without a prompt. Writes exactly two
  files — the body at its block's `File:` path, verbatim, never migrated — and
  `.claude/RUNBOOKS.md`, where the one line it touches is `Steps:`. Removes each
  `[x]` step whole (heading through prompt fence) and records its id on the
  header's `Archive:` line, ascending, extended rather than replaced; a
  surviving `Depends on:` naming a pruned step is **left exactly as it is**,
  which is what `Archive:` is for. **Never touches `Last step number:`** on a
  body that has one — up or down — so pruning the highest-numbered step is
  legal.
  Both derived values (`Archive:`, `Steps:`) and the backfill are computed in
  STAGE 1 and printed in STAGE 2's plan with their previous values beside them,
  ending in **"Apply?"** — nothing is written before an explicit answer, and a
  step the user rescues re-renders the whole plan. A prune may legally empty a
  body of steps; the file and its index block stay (removal is
  `/runbook-clean`'s). **Commit convention: cleanup** — commits and pushes by
  default, `--no-commit`/`--no-push` opt out, the plan gate serving as the
  review pass.

## Public API

- [runbook-suite.md](./runbook-suite.md) § Public API.

## Internal patterns

- [runbook-suite.md](./runbook-suite.md) § Internal patterns.

## Domain dependencies

- [runbook-suite.md](./runbook-suite.md) § Domain dependencies.

## Cross-references

- [runbook-suite.md](./runbook-suite.md) — the runbook suite's hub, and its
  family-wide cross-references.
- [runbook-run.md](./runbook-run.md) — the schema both commands cite.

## When to read the source

- [runbook-suite.md](./runbook-suite.md) § When to read the source.
