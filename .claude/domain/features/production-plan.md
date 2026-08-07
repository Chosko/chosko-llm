# Production plan

The production plan is the product's WHEN at the feature level: which
low-level feature belongs to which milestone, in what order, and after what.
A `/production-plan` skill writes it into `.claude/PLAN.md`, a third index
beside `TASKS.md` and `FEATURES.md`, and reconciles it as features are
architected and milestones progress.

## Purpose

The roadmap says which outcomes come in which order. It does not say which
architected features that implies, whether they can be built yet, or which
one to start. Those are feature-level facts, and today they exist nowhere:
`FEATURES.md` carries no ordering, and the dependency prose in each feature
document is read by nobody.

This feature turns that prose into a graph, assigns features to milestones,
orders them, and refuses the two arrangements that cannot be built —
dependency cycles, and a feature scheduled before something it needs. Its
reader is the director asking what to build next; its consumer is
[plan-readout](./plan-readout.md). See
[product-design.md § Roadmap and planning](../product-design.md).

## Scope and non-goals

In scope: the `PLAN.md` schema, the skill that writes and reconciles it,
milestone inheritance, dependency edges, ordering and cycle validation,
milestone status, and the derived coverage report.

Deliberately out:

- **Priority as a separate axis.** A feature's priority is its position in its
  milestone's ordered feature list. A `P0`/`P1` label alongside an ordered
  list is a second ordering that will contradict the first.
- **Dates, estimates, and progress percentages.** As in
  [product-roadmap](./product-roadmap.md).
- **Storing anything derivable.** Readiness, coverage and per-feature task
  rollups are computed at read time by
  [plan-readout](./plan-readout.md), never persisted.
- **Writing `FEATURES.md`, `TASKS.md`, feature documents, or the roadmap.**
  This skill is the sole writer of `PLAN.md` and reads everything else.
- **Plan awareness in `/task-add`, `/task-implement`, or the bash CLI.**
  Explicitly deferred; see open questions.
- **Task-level ordering.** `Preconditions:` already covers it and is
  unaffected.

## Architecture

Built on the stack recorded in
[technical-direction.md](../technical-direction.md): a markdown prompt over
markdown indices. The two indices it reads are described in
[task-workflow.md](../task-workflow.md) and
[product-workflow.md](../product-workflow.md).

**The skill**, `/production-plan`, is a member of the authoring family:
nothing committed unless `--commit` is passed, `--no-push` commits without
pushing. It gates on `FEATURES.md` existing and points at `/domain-setup`
when it does not. A roadmap is **not** required — without one, every feature
lands in `Unscheduled` and dependency ordering still works, so a project can
get sequencing without roadmap ceremony.

Four responsibilities, in order:

**1. Milestone inheritance.** For each entry in `FEATURES.md`, read its
`Source:` line. A milestone parenthetical — written by
[slice-aware-architecture](./slice-aware-architecture.md) — places the
feature in that milestone directly. This is a lookup, not an inference:
because `/architect` architects one slice at a time, every feature carries
the milestone of the slice it came from. Features with no parenthetical, and
`Source: prompt` features, start in `Unscheduled` until placed by hand.

An explicit placement in a different milestone **overrides** the
parenthetical, for genuine business change. Overrides are reported plainly at
the approval gate — never silently applied — but they are not gated or
refused, because the roadmap makes no completeness claim for anything to
violate.

**2. Dependency edges.** Feature documents propose, `PLAN.md` records. The
skill reads each document's `## Dependencies` section, proposes the edge set
in machine-readable form, the user confirms, and `PLAN.md` stores it. Prose
stays the human-facing statement; the edge list is the parsable projection.
Drift between them is resolved by re-running the skill, the same
reconciliation pattern `/task-add feature=<slug>` already uses.

**3. Validation.** Two invariants, both enforced before writing:

- **Ordering.** Within a milestone, the `Features:` list must be a
  topological order of the edges restricted to it. A dependency living in a
  *later* milestone is refused outright — it cannot be satisfied by the time
  it is needed.
- **Cycles.** Reported as the actual cycle path, and refused. No override
  flag: a cycle is not a judgement call.

**4. Reconciliation.** A re-run diffs the plan against the current
`FEATURES.md` and roadmap and presents everything behind one approval gate,
matching `/task-add`'s single-gate convention:

| Situation | Action |
| --- | --- |
| Feature in `FEATURES.md`, absent from the plan | Proposed for placement — its `Source:` milestone, or `Unscheduled`. |
| Slug in the plan, gone from `FEATURES.md` | Reported and dropped. A hand-deleted feature must not break the run. |
| Feature is `[ITERATED]` | Its document's dependencies are re-read and the edge diff proposed. |
| Milestone in the roadmap, absent from the plan | Added, in roadmap order. |
| Milestone in the plan, gone from the roadmap | Reported, kept, and flagged — hand edits are tolerated, not silently reverted. |

## Data and state

One index, `.claude/PLAN.md`, versioned with the project and sole-written by
this skill. It sits at `.claude/` root rather than inside `domain/` for the
same reason `FEATURES.md` does: it indexes work items, while the knowledge it
indexes lives in the domain layer.

```
# Plan

Roadmap: .claude/domain/product-roadmap.md
Last reconciled: <date>

---

## <milestone-slug> — <title>

Status: [PLANNED]
Covers: product-design.md § <section>, product-design.md § <section>
Features: <ordered feature slugs>

---

## Unscheduled

Features: <slugs with no milestone yet>

## Dependencies

- <slug>: depends on <slug>, <slug>
```

- **`Features:`** is ordered, and the order *is* the priority.
- **`Covers:`** is **derived** — rewritten every run from the roadmap's own
  `Covers:` lines — so it cannot drift. It is present for readability, not as
  a source of truth.
- **`Dependencies`** is one flat edge list rather than a `Depends:` line per
  feature. Two reasons: it keeps `PLAN.md` from becoming a second index keyed
  by feature slug, and it puts every edge in one place, where a cycle is
  visible.
- **`Last reconciled:`** is informational only. Nothing computes from it; the
  staleness signal is a `FEATURES.md` slug missing from the plan, which
  [plan-readout](./plan-readout.md) reports.

**Milestone status** is the third status vocabulary in the pipeline and is
kept deliberately small:

| Status | Meaning |
| --- | --- |
| `[PLANNED]` | Scheduled, not started. |
| `[ACTIVE]` | Being built now. At most one milestone at a time. |
| `[SHIPPED]` | Delivered. Terminal. |

`[SHIPPED]` is *proposed* by the skill only when every feature in the
milestone is `[PLANNED]` in `FEATURES.md` and all of their tasks are `[DONE]`
or `[SKIP]`, and it is always confirmed by the user rather than applied
automatically. It can never reopen — follow-up work is always a new
milestone, the same discipline that makes `[DONE]` terminal for tasks and
`[PLANNED]` → `[NEW]` illegal for features.

The status lives here rather than in the roadmap because the roadmap holds
intent and this index holds state — the same split as `product-design.md`
versus `FEATURES.md`, and it keeps one writer per artifact.

## Interfaces and contracts

**Consumes:**

- `FEATURES.md` — slugs, `Status:`, `Source:` with its milestone
  parenthetical, and `Tasks:`. Read-only.
- Feature documents' `## Dependencies` sections. Read-only.
- `product-roadmap.md` — milestone slugs, order, and `Covers:`. Read-only,
  optional.
- `TASKS.md` — task statuses, for the `[SHIPPED]` proposal only. Read-only.

**Exposes:** the `PLAN.md` schema, consumed by
[plan-readout](./plan-readout.md).

**Failure contract:**

- No `FEATURES.md` → refuse, point at `/domain-setup`.
- No features at all → write nothing, say so.
- Cycle detected → report the cycle path, refuse to write, ask the user to
  break it.
- Dependency in a later milestone → report both features and their
  milestones, refuse to write.
- More than one `[ACTIVE]` milestone → report and ask which one is meant.
- Slug in a dependency edge that resolves to no feature → report and drop
  the edge, as `/architect`'s iterate guard ignores unresolvable task IDs.
- `--commit` with nothing changed → make no commit and say so.

## Dependencies

- [product-roadmap](./product-roadmap.md) — milestone slugs, order, and
  `Covers:` lines. Soft: without a roadmap the skill still runs, with
  everything in `Unscheduled`.
- [slice-aware-architecture](./slice-aware-architecture.md) — the `Source:`
  milestone parenthetical. Hard for automatic inheritance; without it every
  feature must be placed by hand.
- **`FEATURES.md` and the feature documents** — `/architect`'s existing
  output, read-only.
- **`TASKS.md`** — read-only, for the `[SHIPPED]` proposal.
- No external dependencies.

## Open questions

- **Whether `chosko-llm task-impl` should honour plan order.** Deferred by
  decision, with no trigger set — recorded in the same register as the
  local-install-drift note in [product-design.md](../product-design.md).
  Doing it means parsing `PLAN.md` from bash with awk and sed, in the largest
  script in the repo, under the no-new-dependencies rule.
- **Whether `/task-add feature=<slug>` should warn when a feature's
  dependencies are unsatisfied.** Deferred on the same terms.
- **Whether the edge list should be derivable rather than stored.** Storing
  confirmed edges is what allows an edge the documents do not state; deriving
  them on every run would remove drift entirely. The confirm-and-store choice
  buys expressiveness at the price of a reconciliation step.
- **How a milestone with no features should be reported.** Today it is a
  coverage gap meaning `/architect` has not run on its slices yet, which is
  useful information rather than an error — but it is indistinguishable from
  a milestone that was written and then emptied.
