---
name: production-status
version: 0.1.0
type: command
description: Report what to build next by joining PLAN.md, FEATURES.md and TASKS.md — the active milestone with its roadmap goal and exit criteria, its features in plan order with their task rollup and readiness, the ready set, the single recommended next feature, blocked features named with their blocker, coverage gaps, features missing from the plan, and the remaining milestones. Readiness and coverage are derived on every read. Read-only — writes nothing, runs no shell, and never opens a file under .claude/tasks/.
---

# /production-status
# Global command: answer the question the planning layer exists to answer —
# what should I build next. Joins `.claude/PLAN.md` (milestones, order,
# dependency edges), `.claude/FEATURES.md` (each feature's design/backlog
# state) and `.claude/TASKS.md` (the work), plus
# `.claude/domain/product-roadmap.md` for the active milestone's goal and
# exit criteria. Read-only — never modifies, creates or commits any file,
# and never opens a file under `.claude/tasks/`.
# Usage: /production-status
#        /production-status --task-ids
#        /production-status milestone=<slug>
#        /production-status milestone=<slug> --task-ids
# Examples: /production-status
#           /production-status milestone=m2-teams
#           /production-status --task-ids

GOAL
Report the state of the production plan and name the one feature to start
next. Every fact is either read verbatim from one of the four inputs or
derived from their join; nothing is stored, cached, or written back.

This command **reports** work — it does not select or start it. It names the
next ready feature and stops there. `/task-add feature=<slug>` and
`/task-implement` are how work actually begins.

$ARGUMENTS

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for:

- `--task-ids` — set TASK_IDS = true and strip it. It switches the per-feature
  task rollup from counts per status to naming each task ID.
- `milestone=<slug>` — set MILESTONE = the slug and strip it. It scopes
  sections 1, 2, 3, 4 and 5 of the report to that milestone instead of the
  active one.

Anything else in `$ARGUMENTS` is not a recognized argument. Say so in one
line and carry on with the default report — this command never refuses over
its own arguments.

---

READING THE INPUTS

This command performs no writes and needs no shell at all. Do NOT run `git`,
`ls`, `grep`, or any other command. Do NOT open any file under
`.claude/tasks/` — `TASKS.md` carries everything needed, exactly as in
`/task-list`.

Read these four files, all **read-only**:

| File | What it supplies |
| --- | --- |
| `.claude/PLAN.md` | Milestone membership, order, `Status:`, and the flat `## Dependencies` edge list. |
| `.claude/FEATURES.md` | Per-feature `Status:` and `Tasks:` IDs. |
| `.claude/TASKS.md` | Per-task `Status:`, for the rollup and the readiness rule. |
| `.claude/domain/product-roadmap.md` | `Goal:` and `Exit criteria:`, echoed for the reported milestone. |

**`PLAN.md`'s schema**, which this command parses and never rewrites:

- Header lines `Roadmap:` and `Last reconciled:`. `Last reconciled:` is
  informational only — see STALENESS below.
- One `## <milestone-slug> — <title>` block per milestone, **in plan order,
  top to bottom**, each carrying `Status:` (exactly one of `[PLANNED]`,
  `[ACTIVE]`, `[SHIPPED]`), an optional derived `Covers:` line naming
  `product-design.md` sections, and an **ordered** `Features:` list —
  comma-separated slugs, or the literal `none`. The order is the priority;
  there is no other priority field to look for.
- A `## Unscheduled` block with `Features:` and nothing else.
- One flat `## Dependencies` list at the end: `- <slug>: depends on <slug>,
  <slug>`. There is no `Depends:` line on a feature block; do not look for
  one.

---

THE MILESTONE BEING REPORTED

- With `milestone=<slug>`, report that milestone. If no milestone block in
  `PLAN.md` has that slug, stop, listing the slugs that do exist — matching
  `/task-add feature=<slug>`'s unknown-slug behavior:

  > No milestone `<slug>` in `.claude/PLAN.md`. Available: `<slug-a>`,
  > `<slug-b>`, `<slug-c>`.

  This is the command's only stop.
- With no `milestone=`, report the milestone whose `Status:` is `[ACTIVE]`.
- No `[ACTIVE]` milestone → report the first `[PLANNED]` one in plan order,
  and say in one line that no milestone is active.
- More than one `[ACTIVE]` → report the first in plan order, name both, and
  say the plan is inconsistent and `/production-plan` resolves it.

---

READINESS (derived on every read, never stored)

A feature is **ready** when **every** dependency edge pointing at it
originates from a feature that is `[PLANNED]` in `FEATURES.md` **and** has
all of its tasks `[DONE]` or `[SKIP]` in `TASKS.md`.

- A feature with no dependency edges is ready.
- Everything else is **blocked**, and is always named together with what
  blocks it — every unsatisfied dependency, with why it is unsatisfied
  (`[NEW]` in `FEATURES.md`, `[ITERATED]`, or `[PLANNED]` with N tasks not
  yet `[DONE]`/`[SKIP]`). A blocked list that does not name the blocker is a
  dead end and is not acceptable output.
- A dependency edge naming a slug that resolves to no feature is a **plan
  inconsistency**: report it, and treat the dependent feature as **ready**.
  Failing open is deliberate — a hand-edited plan must never make this report
  claim there is nothing to do.
- Never store this anywhere. It is recomputed on every run, which is what
  keeps it from being wrong about a task someone just finished.

**The task rollup** for a feature comes from its `FEATURES.md` `Tasks:` line,
looked up in `TASKS.md`:

- Default: counts per status, e.g. `4 tasks — DONE: 2, MISSING: 1, STALE: 1`.
- With `--task-ids`: name each task ID with its status instead, e.g.
  `tasks: 41 [DONE], 42 [DONE], 43 [MISSING], 44 [STALE]`.
- `Tasks: none` → `no tasks yet` — and that is the signal that
  `/task-add feature=<slug>` has not run.
- A task ID that resolves to no entry in `TASKS.md` is ignored, not an error.

---

OUTPUT — eight sections, in this order

**1. The milestone.** Its slug, title and `Status:`. Echo its `Goal:` and its
`Exit criteria:` verbatim from the matching milestone block in
`.claude/domain/product-roadmap.md`. Omit both headings entirely when there
is no roadmap or the roadmap has no block with that slug — do not invent
them, and do not warn twice.

**2. Its features, in plan order.** One line each, in the milestone's
`Features:` order, since that order is the priority:

```
1. <slug>            [PLANNED]   4 tasks — DONE: 2, MISSING: 2    ready
2. <slug>            [NEW]       no tasks yet                     blocked by <slug>
```

Each carries its `FEATURES.md` status, its task rollup, and its readiness. A
slug in `Features:` with no `FEATURES.md` entry is reported as a plan
inconsistency on its own line and carries no status or rollup.
`Features: none` → say the milestone has no features and that `/architect`
has not run its `Covers:` slices yet.

**3. The ready set.** Every ready feature in this milestone, in plan order.
Empty → say so, and say what the nearest blocker is.

**4. The recommended next feature** — the **first ready feature in plan
order**, exactly one, named on its own with its task rollup. If it has no
tasks yet, say the next step is `/task-add feature=<slug>`. If it already has
tasks, say the next step is `/task-implement`. Nothing is started here.

**5. Blocked features.** Every blocked feature in this milestone, each with
every unsatisfied dependency and why it is unsatisfied.

**6. Coverage gaps.** Two kinds, both derived:

- Milestones whose `Features:` is `none` — roadmap slices nothing has been
  architected for. This is outstanding `/architect` work; name the milestone
  and its `Covers:` sections.
- `product-design.md` sections that no milestone's `Covers:` line names, when
  a roadmap exists. Omit this half entirely when there is no roadmap.

This section is plan-wide, not scoped by `milestone=`.

**7. Unplanned features** — every `FEATURES.md` slug that appears in no
milestone's `Features:` list and not in `Unscheduled` either, plus everything
sitting in `Unscheduled`. Name them and point at `/production-plan`. Also
plan-wide. Empty → say the plan covers every architected feature.

**8. Remaining milestones**, one line each: slug, title, `Status:`, and how
many features it holds. Every milestone in plan order other than the one
reported in section 1.

---

STALENESS — structural, never temporal

The staleness signal is a `FEATURES.md` slug missing from `PLAN.md`, which
section 7 reports. That is the whole of it.

Do NOT compare `Last reconciled:` against file modification times, against
today's date, or against anything else. It is informational only, nothing
computes from it, and no report may treat it as an expiry. Echoing it as a
plain fact in the header is fine; drawing a conclusion from it is not.

---

FAILURE CONTRACT — degradation, never refusal

A read-only report must never be the thing that stops a session. Every one of
these degrades and carries on:

| Situation | Behaviour |
| --- | --- |
| No `.claude/PLAN.md` | Say the project has no plan and point at `/production-plan`. Stop there — there is nothing to join. Do NOT create the file. |
| No `.claude/FEATURES.md` | Say so, report the plan's structure (milestones, order, edges) with no feature statuses or rollups, and point at `/domain-setup` + `/architect`. |
| No roadmap | Omit `Goal:` and `Exit criteria:` and the design-section half of section 6. Report everything else normally. One line, no warning ceremony. |
| No `.claude/TASKS.md` | Features report with no task rollup, and every feature with satisfied dependencies is ready. |
| No `[ACTIVE]` milestone | Report the first `[PLANNED]` one and say none is active. |
| More than one `[ACTIVE]` | Report the first in plan order, name both, call it a plan inconsistency. |
| Dependency edge naming an unknown slug | Report the inconsistency and treat the dependent feature as ready. Fail open. |
| A `Features:` slug with no `FEATURES.md` entry | Report the inconsistency, keep it in the plan order, no status or rollup. |
| `PLAN.md` present but with no milestones | Report `Unscheduled` and sections 6–8 only, and say no milestone is planned. |

The only stop other than "no `PLAN.md`" is an unknown `milestone=<slug>`.

---

DO NOT:
- Write, edit, create or commit anything — no status flips, no reordering, no
  cached answer, no `PLAN.md` fix for an inconsistency this run reported.
  `/production-plan` is the only writer in this layer.
- Run any shell command of any kind, including `git`.
- Open any file under `.claude/tasks/`. `TASKS.md` carries everything needed.
- Open feature documents under `.claude/domain/features/`, or
  `product-design.md` beyond its section headings for section 6's coverage
  check.
- Store or cache readiness, coverage or a task rollup anywhere. They are
  derived on every read, deliberately.
- Recommend more than one next feature, rank features by anything other than
  their position in `Features:`, or invent a priority, size, estimate, date
  or percentage. Priority is position in the list.
- Start the recommended work, draft its tasks, or run `/task-add` or
  `/task-implement`. Reporting is where this command ends.
- Treat `Last reconciled:` as a staleness signal.
- Refuse over a missing roadmap, a missing `TASKS.md`, an empty milestone, an
  unresolvable edge, or a slug the plan and the index disagree about. Every
  one of those is a reported observation.
