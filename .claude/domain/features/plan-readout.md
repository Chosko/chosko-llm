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
   rollup from `TASKS.md`, and its readiness.
3. The **ready set** — features whose dependencies are all finished.
4. The single recommended next feature: the first ready feature in plan
   order.
5. **Blocked** features, each named with what blocks it, so a blocked list is
   actionable rather than a dead end.
6. **Coverage gaps** — roadmap slices with no architected features, which is
   outstanding `/architect` work — and `product-design.md` sections no
   milestone covers.
7. **Unplanned features** — `FEATURES.md` slugs absent from `PLAN.md`.
8. Remaining milestones, one line each.

**Readiness** is the only real computation. A feature is ready when every
dependency edge pointing at it originates from a feature that is `[PLANNED]`
in `FEATURES.md` with all of its tasks `[DONE]` or `[SKIP]`. A feature with
no dependencies is ready. Everything else is blocked, named with its blocker.
Derived on every read, never stored — which also means it can never be wrong
about a task someone just finished.

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
- No roadmap → milestone goals and exit criteria are omitted; everything else
  reports normally.
- No `TASKS.md` → features report with no task rollup, and every feature with
  satisfied dependencies is ready.
- No active milestone → report the first `[PLANNED]` one and say that none is
  active.
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

- **Whether `/production-status` and `/task-list` should stay two commands.**
  They read overlapping data and their outputs will look similar under
  milestone grouping. Merging them behind a flag is the alternative; kept
  separate for now because one reports features and the other reports tasks,
  and the registers are different.
- **How much of a task rollup belongs in a feature line.** Counts per status
  are compact but lossy; naming each task is precise and long. Left to
  implementation.
- **Whether the report should flag a milestone whose exit criteria look
  unmeetable.** This is where [product-roadmap](./product-roadmap.md)'s
  dropped exit-criteria check would land if it is ever wanted — as a derived
  observation in a read-only report rather than a gate in a writer, which is
  a better home for it.
