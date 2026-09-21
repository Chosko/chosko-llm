# `/production-plan amend` — reconcile the plan for one described change

Read this when ARGUMENT PARSING recognised the `amend "<change>"` form, once
PHASE 0's gate has passed and the pull-at-start has run. It carries the whole
arm: a consumer that has read only this file — `/production-plan` itself, or
a pipeline revision surface reading it by path — can execute it end to end;
where a rule lives in another file in this folder, this file cites it by
path and restates nothing it owns.

The arm is `./reconciling.md`'s diff, narrowed to what one change reaches:
it reconciles `PLAN.md` against `FEATURES.md` and the feature documents for
the milestones and edges the change names, validates as every run does, and
writes. A change that reaches the whole plan is a full run's.

---

## Inputs

- `<change>` — the quoted text after `amend`: what changed and where it
  lands — a feature to place, move or unschedule; an edge to add, drop or
  re-point; a milestone whose status moves.
- `--commit`, `--no-commit`, `--no-push` — unchanged in meaning; see
  *Committing*.
- **A draft, optionally**, when a revision surface runs this arm: the plan
  diff it drafted at plan time, in the shape of § 3. See § *The gate*.

It reads `.claude/PLAN.md`; the `.claude/FEATURES.md` entries of the features
the change names; the `## Dependencies` section of each of their `Doc:`
documents; and `.claude/domain/product-roadmap.md` only when the change
moves a feature between milestones. Every one is read-only. A missing
`PLAN.md` stops the arm — `No plan to amend; run /production-plan to build
one.` — with nothing written.

## 1. Pin the change

The change names the features, edges or milestones it moves. The arm's scope
is those and nothing more:

- **a feature** — its placement (`Features:` of one milestone, or
  `## Unscheduled`) and its position in that list; when the change removes
  or unschedules it, every `## Dependencies` line naming it as well;
- **an edge** — one `## Dependencies` line, added, dropped or re-pointed;
- **a milestone's `Status:`** — `[PLANNED]`, `[ACTIVE]` or `[SHIPPED]`.

A change that names none of these, or that reads as "reconcile everything",
is refused:

> This change can't be pinned to named features, edges or milestones of
> `PLAN.md`. Name them, or re-run `/production-plan` for a full
> reconciliation.

## 2. Draft the diff

For the pinned scope only, apply `./reconciling.md`'s situations as they
arise — a feature to place, a slug that is gone, a feature whose `Status:`
is `[ITERATED]` and whose edges may have moved, a milestone the roadmap no
longer has — and draft the resulting diff to `PLAN.md`: the `Features:` lines
that change, the `## Dependencies` lines that change, the `Status:` line
that changes. Everything outside the pinned scope stays as it is, an
ordering the user set included.

Then validate the resulting plan exactly as `SKILL.md` PHASE 2 does on a
full run: a cycle anywhere in the edge set, or a dependency on a feature in
a later milestone, refuses with the plan unchanged and no override; within
each milestone the change touched, `Features:` must remain a topological
order of the edges among its features, fixed with the user or refused,
never written wrong; a dependency on an `Unscheduled` feature is a warning,
carried into the report.

## 3. The gate

One message: the diff, line by line, before → after, with each validation
warning beneath it. Then:

- **With no draft passed in** — wait for an explicit approval. Silence, an
  unclear reply or EOF writes nothing.
- **With a draft passed in** — compare it with the diff § 2 produced from
  the same reads. When they match, write without waiting: the consumer's
  gate already approved this diff. When they differ, render the difference
  as the gate and wait.

## 4. Write

Write the diff to `.claude/PLAN.md`, rewrite `Last reconciled:` to today's
date, and add the path to `WRITTEN`. Nothing else, ever: not `FEATURES.md`,
not `TASKS.md`, not a feature document, not the roadmap.

## 5. Report

```
Amended PLAN.md: <what moved — feature → milestone, edge added/dropped, status → value>[; warning: <unscheduled dependency>].
```

When `WRITTEN` is non-empty and the run committed nothing, end with an
explicit reminder that nothing was committed.

## Committing

Under `/production-plan amend`, `SKILL.md`'s COMMIT AND PUSH applies to
`WRITTEN` unchanged. A consumer that executes this file by path commits
under its own rules; § 4's path is what it stages.

---

## Never

- Reconcile outside the pinned scope, re-derive an ordering the user set, or
  reset a milestone's `Status:` the change did not name.
- Write past a cycle or a later-milestone dependency; there is no override.
- Write anything but `.claude/PLAN.md`.
- Wait at the gate when a passed-in draft matches, or write on a passed-in
  draft that does not.
