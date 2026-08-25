# Plan readout

The read side of the planning layer. A `/production-status` command joins
`PLAN.md`, `FEATURES.md` and `TASKS.md` and answers the question the plan
exists to answer — what should I build next — while `/task-list` gains
milestone grouping so the backlog can be read through the plan. Both write
nothing.

## Purpose

A plan nobody reads changes no decisions. `PLAN.md` holds milestones, order
and dependency edges; `FEATURES.md` holds each feature's design/backlog
state; `TASKS.md` holds the actual work. The useful answer lives in the join
of all three and in none of them alone: a feature is workable when it is in
the active milestone, its dependencies are finished, and its tasks exist.

This feature computes that answer and reports it. It is the payoff of the
other three. See
[product-design.md § Roadmap and planning](../product-design.md).

## Scope and non-goals

In scope: the `/production-status` read-only view, the readiness computation
behind it, the unplanned-feature staleness signal, and milestone-aware
grouping in `/task-list`.

Deliberately out:

- **Writing anything.** No status flips, no reordering, no commits. Every
  writer in this layer is [production-plan](./production-plan.md).
- **Storing the derived answer.** Readiness, coverage and task rollups are
  recomputed on every read. Filesystem is the state.
- **Selecting work automatically.** It reports the next ready feature; it does
  not start it. Plan-aware `/task-add` and `/task-implement` are deferred —
  see [production-plan](./production-plan.md)'s open questions.
- **Opening task body files.** `/task-list` reads only `TASKS.md` today and
  that stays true; `/production-status` follows the same rule.
- **Any behaviour change to `/task-list` on projects with no plan.**

## Architecture

Built on the stack recorded in
[technical-direction.md](../technical-direction.md): markdown prompts, no
code. The command being extended is described in
[`.claude/context/features.md`](../../context/features.md).

**`/production-status`** is a command, not a skill — a thin read-only
reporter with no conversation and no supporting files, exactly the register
`/task-list` occupies. Its output, in order:

1. The active milestone: slug, title, `Goal:` and `Exit criteria:` echoed
   from the roadmap.
2. Its features in plan order, each with its `FEATURES.md` status, its task
   rollup from `TASKS.md`, and a **Next** field — the one concrete action the
   feature needs, rather than a restatement of its readiness.
3. The **ready set** — features whose dependencies are all finished, never
   one that's itself `[DONE]` already.
4. The single recommended next feature: the first ready feature in plan
   order (so, from the same set — never `[DONE]`), carrying the same **Next**
   value section 2 gave it — echoed, never derived a second time here.
5. **Blocked** features, each named with what blocks it, so a blocked list is
   actionable rather than a dead end.
6. **Coverage gaps** — roadmap slices with no architected features, which is
   outstanding `/architect` work — and `product-design.md` sections no
   milestone covers.
7. **Unplanned features** — `FEATURES.md` slugs absent from `PLAN.md`.
8. Remaining milestones, one line each.

**The zero-task rollup splits on the feature's status.** A feature with no
tasks renders `-` when it is `[DONE]` or `[PLANNED]` — a feature only reaches
either state after `/task-add feature=<slug>` has run, so zero tasks there
means the completed ones were pruned, not that planning never happened.
`no tasks yet`, with its `/task-add feature=<slug>` gloss, is kept for `[NEW]`
and `[ITERATED]`, where it is the true signal that planning has not run.

**Two arguments**, settled at implementation. `--task-ids` switches the task
rollup from counts per status to naming each task ID — counts keep a
milestone's feature list scannable, which is the command's whole register, and
the flag recovers precision without a second command. The zero-task split above
holds under it unchanged: a `[DONE]`/`[PLANNED]` feature renders `-` there too,
never an empty ID list. `milestone=<slug>`
scopes sections 1–5 to a named milestone rather than the active one, and an
unknown slug is the report's only stop besides a missing `PLAN.md`, listing
the available slugs exactly as `/task-add feature=<slug>` does. The split
follows the existing convention: `key=value` for a named target, `--flag` for
a boolean.

**Readiness** is the only real computation, and it's never computed for a
`[DONE]` feature — finished, not pending, so it's reported plainly in
section 2 and skipped by the ready set, the blocked list and the
recommendation, though it still satisfies edges pointing at it from
dependents. For every other feature: ready when every dependency edge
pointing at it originates from a feature that is `[DONE]` in `FEATURES.md`,
or `[PLANNED]` with all of its tasks `[DONE]` or `[SKIP]`. A feature with no
dependencies is ready. Everything else is blocked, named with its blocker.
Derived on every read, never stored — which also means it can never be wrong
about a task someone just finished. How it is derived is untouched by the Next
field: readiness is still what sections 3, 4 and 5 are built from, and one of
the three inputs the Next value is derived from. Only section 2's presentation
of it changed — from displaying readiness to displaying the action it implies.

**The staleness signal is structural, not temporal.** Rather than comparing
`Last reconciled:` against file modification times — which needs state this
product does not keep — the report simply names every `FEATURES.md` slug
missing from `PLAN.md` and points at `/production-plan`. A plan that has
fallen behind says so by having gaps.

**`/task-list` grouping.** When `PLAN.md` exists, the backlog groups by
milestone, resolving each task's `Feature:` line through the plan; tasks whose
feature is blocked carry a flag naming the blocker, alongside the existing
`⚠ <target>`, `[<slug>]` and `⚠ stale` markers. Tasks with no `Feature:`
line — every free-form task — group under a trailing unplanned heading. With
no `PLAN.md`, the command's output is byte-for-byte what it is today: a
silent no-op, not a warning.

## Data and state

No storage of its own. Nothing written, nothing cached, no state file.

The join is by slug, across three indices:

| Source | What it supplies |
| --- | --- |
| `PLAN.md` | Milestone membership, order, status, dependency edges. |
| `FEATURES.md` | Per-feature `Status:` and `Tasks:` IDs. |
| `TASKS.md` | Per-task `Status:`, and `Feature:` for `/task-list` grouping. |
| `product-roadmap.md` | `Goal:` and `Exit criteria:`, echoed for the active milestone. |

Every fact reported is either read verbatim from one of these or derived from
their join. The design keeps no third representation of anything.

## Interfaces and contracts

**Consumes** `PLAN.md`, `FEATURES.md`, `TASKS.md` and `product-roadmap.md`,
all read-only.

**Exposes** terminal output only. No file, no exit-code contract beyond
success, nothing another feature parses — deliberately, so the report's shape
stays free to change.

**Failure contract**, and the whole of it is degradation rather than
refusal — a read-only report must never be the thing that stops a session:

- No `PLAN.md` → `/production-status` says the project has no plan and points
  at `/production-plan`. `/task-list` behaves exactly as today.
- No `FEATURES.md` → report the plan's structure — milestones, order, edges —
  with no feature statuses or rollups, and point at `/domain-setup` and
  `/architect`. `/task-list` treats a plan with no feature index as no plan,
  since it could compute neither a group's blockers nor anything else the
  grouping adds.
- No roadmap → milestone goals and exit criteria are omitted; everything else
  reports normally.
- No `TASKS.md` → features report with no task rollup, and every feature with
  satisfied dependencies is ready.
- No active milestone → report the first `[PLANNED]` one and say that none is
  active.
- More than one `[ACTIVE]` milestone → report the first in plan order, name
  them all, and call it a plan inconsistency `/production-plan` resolves.
  Unlike `/production-plan`, which asks, a read-only report cannot ask.
- An unknown `milestone=<slug>` → stop, listing the milestone slugs that do
  exist. This and a missing `PLAN.md` are the only two stops in the command.
- A dependency edge naming an unknown slug → report it as a plan
  inconsistency and treat the feature as ready rather than permanently
  blocked. Failing open matters here: a hand-edited plan must not make the
  report claim there is nothing to do.
- A `Feature:` line naming a slug absent from the plan → group the task under
  unplanned, and name it in the unplanned list.

## Dependencies

- [production-plan](./production-plan.md) — the `PLAN.md` schema, including
  the edge-list format and the milestone status vocabulary. Hard: there is
  nothing to read without it.
- [product-roadmap](./product-roadmap.md) — `Goal:` and `Exit criteria:` for
  the active milestone. Soft; their absence only omits a heading.
- **`/task-list`** — an existing shipped command this feature extends. Carries
  a version bump on it.
- **`FEATURES.md` and `TASKS.md`** — existing indices, read-only.
- No external dependencies.

## Open questions

Reviewed against what shipped in `commands/production-status.md` and
`commands/task-list.md`. One question was settled by the implementation and is
recorded as settled; the other two are restated with what shipping made
concrete.

- **How much of a task rollup belongs in a feature line.** Settled as
  **counts per status by default, `--task-ids` to name each task**. Counts
  keep a milestone's feature list scannable, which is the whole register the
  command occupies, and the flag recovers precision without a second command
  or a second output shape to maintain. Nothing here stays open — the two
  granularities the question weighed are both available, and choosing between
  them is now the reader's call rather than the design's.
- **Whether `/production-status` and `/task-list` should stay two commands.**
  Still open, and shipping made its cost concrete rather than hypothetical:
  the readiness rule is now stated **twice**, once in each command body, and
  the two statements must be kept in step by hand. That duplication was
  chosen deliberately — these are markdown prompts, and a third file holding
  one paragraph of logic costs more to read than the paragraph does to repeat
  — but it is exactly the kind of drift a merge would remove. The trigger to
  revisit: the two definitions diverging in practice, or a third reader
  needing the same rule. Until then they stay separate, because one reports
  features in plan order and the other reports tasks in ID order, and the
  registers are different.
- **Whether the report should flag a milestone whose exit criteria look
  unmeetable.** Still open, and untouched by this implementation: the exit
  criteria are echoed verbatim in section 1 and nothing is derived from them.
  This is still where [product-roadmap](./product-roadmap.md)'s dropped
  exit-criteria check would land if it is ever wanted — as a derived
  observation in a read-only report rather than a gate in a writer, which is
  a better home for it. What shipping clarified is the shape it would take:
  another derived section beside coverage gaps, computed on every read, with
  no state added anywhere.
