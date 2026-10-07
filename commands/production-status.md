---
name: production-status
version: 0.3.3
type: command
description: Report what to build next by joining PLAN.md, FEATURES.md and TASKS.md — the active milestone, its features in plan order with the one action each needs, the ready set and the recommended next feature. Use it when deciding what to pick up; the pipeline's read side, spanning every stage and entering none.
---

# /production-status
# Global command: answer what should I build next. Joins `.claude/PLAN.md`,
# `.claude/FEATURES.md`, `.claude/TASKS.md` and
# `.claude/domain/product-roadmap.md`, and prints the milestone's features
# with the one action each needs, the ready set, the single recommended next
# feature, blocked features with their blocker, coverage gaps, unplanned
# features and the remaining milestones. Read-only.
# Usage: /production-status
#        /production-status --task-ids
#        /production-status milestone=<slug>
#        /production-status milestone=<slug> --task-ids
# Examples: /production-status
#           /production-status milestone=m2-teams
#           /production-status --task-ids

GOAL
Report the state of the production plan and name the one feature to start
next.

- Read every fact verbatim from one of the four inputs or derive it from
  their join. Store, cache and write back nothing.
- Report work; never select or start it. Name the next ready feature and
  stop: do not draft its tasks or run `/task-add` or `/task-implement`.
  `/task-add feature=<slug>` and `/task-implement` are how work actually
  begins.
- Write, edit, create or commit nothing — no status flips, no reordering, no
  cached answer, no `PLAN.md` fix for an inconsistency this run reported.
  `/production-plan` is the only writer in this layer.
- Derive readiness, the Next field, coverage and every task rollup on every
  read; store or cache none of them anywhere. Recomputing is what keeps
  readiness from being wrong about a task someone just finished.
- Never rank features by anything other than their position in `Features:`,
  or invent a priority, size, estimate, date or percentage.

$ARGUMENTS

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for:

- `--task-ids` — set TASK_IDS = true and strip it. It switches the per-feature
  task rollup from counts per status to naming each task ID.
- `milestone=<slug>` — set MILESTONE = the slug and strip it. It scopes
  sections 1, 2, 3, 4 and 5 of the report to that milestone instead of the
  active one.

For anything else in `$ARGUMENTS`, say in one line that it is not a
recognized argument and carry on with the default report. Never refuse over
this command's own arguments.

---

READING THE INPUTS

- Run no shell command of any kind — no `git`, `ls`, `grep` or anything
  else. This command performs no writes and needs no shell.
- Open no file under `.claude/tasks/`, `.claude/tasks/archive/` included.
  `TASKS.md` carries everything needed, exactly as in `/task-list`; know an
  archived task by its absence from `TASKS.md`, never by looking.
- Open no feature document under `.claude/domain/features/`. Read
  `product-design.md` only for its section headings, for section 6's
  coverage check.
- Read these four files, all **read-only**:

| File | What it supplies |
| --- | --- |
| `.claude/PLAN.md` | Milestone membership, order, `Status:`, and the flat `## Dependencies` edge list. |
| `.claude/FEATURES.md` | Per-feature `Status:` and `Tasks:` IDs. |
| `.claude/TASKS.md` | Per-task `Status:` and `Preconditions:`, for the rollup, the readiness rule and the Next field — and, by an ID's absence, which of a feature's tasks are archived. |
| `.claude/domain/product-roadmap.md` | `Goal:` and `Exit criteria:`, echoed for the reported milestone. |

**`PLAN.md`'s schema** — parse it, never rewrite it:

- Header lines `Roadmap:` and `Last reconciled:` (informational only — see
  STALENESS below).
- One `## <milestone-slug> — <title>` block per milestone, **in plan order,
  top to bottom**, each carrying:
  - `Status:` — exactly one of `[PLANNED]`, `[ACTIVE]`, `[SHIPPED]`;
  - an optional derived `Covers:` line naming `product-design.md` sections;
  - an **ordered** `Features:` list — comma-separated slugs, or the literal
    `none`. The order is the priority; look for no other priority field.
- A `## Unscheduled` block with `Features:` and nothing else.
- One flat `## Dependencies` list at the end: `- <slug>: depends on <slug>,
  <slug>`. A feature block has no `Depends:` line; do not look for one.

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

**`[DONE]` features.** Never compute readiness for a `[DONE]` feature — it
is finished, not ready to start. Report it plainly in section 2 and never in
the ready set (3), as the recommended next feature (4), or in the blocked
list (5). It still satisfies every dependency edge a *dependent* feature
points at it.

**Every feature that is NOT `[DONE]`** is **ready** when **every**
dependency edge pointing at it originates from a feature that is either:

- `[DONE]` in `FEATURES.md`, or
- `[PLANNED]` **and** has all of its tasks `[DONE]`, `[SKIP]` or archived in
  `TASKS.md`. An archived ID (see the rollup below) is terminal, so it
  counts as resolved here, exactly as `[DONE]` and `[SKIP]` do.

Then:

- A feature with no dependency edges is ready.
- Everything else is **blocked**. Always name a blocked feature together with
  what blocks it — every unsatisfied dependency, with why it is unsatisfied
  (`[NEW]` in `FEATURES.md`, `[ITERATED]`, or `[PLANNED]` with N tasks not
  yet `[DONE]`/`[SKIP]`). A blocked list that does not name the blocker is a
  dead end and is not acceptable output.
- A dependency edge naming a slug that resolves to no feature is a **plan
  inconsistency**: report it, and treat the dependent feature as **ready**.
  Fail open — a hand-edited plan must never make this report claim there is
  nothing to do.

**The task rollup** for a feature comes from its `FEATURES.md` `Tasks:` line,
looked up in `TASKS.md`:

- Default: counts per status, e.g. `4 tasks — DONE: 2, MISSING: 1, STALE: 1`.
  IDs absent from `TASKS.md` add one more value to the same line,
  `archived: N`, and count toward its total:
  `6 tasks — DONE: 2, MISSING: 1, archived: 3`.
- With `--task-ids`: name each task ID with its status instead, e.g.
  `tasks: 41 [DONE], 42 [DONE], 43 [MISSING], 44 [STALE]`. Name an absent ID
  with `[archived]`: `tasks: 41 [archived], 42 [DONE], 43 [MISSING]`.
- A task ID that resolves to no entry in `TASKS.md` is archived and
  terminal, per `task-engine`'s `references/resolution.md` § *The archive*
  — named as the rule's home, not as a file this command opens. This
  command's deviation: *report* such an ID rather than ignoring it, from its
  absence alone — never probe `.claude/tasks/archive/` or open a file in it.
  `archived` is not a status — it is none of the eight tags, no `Status:`
  field ever holds it, and it is written in lowercase so it never reads as
  one.
- **Zero tasks** — a literal `Tasks: none`, and only that — splits on the
  feature's `FEATURES.md` status. A `Tasks:` line whose every ID is absent
  is not a zero-task case: render `archived: N` (or its `[archived]` IDs)
  like any other rollup.
  - `[DONE]` or `[PLANNED]` → `-`. A feature only reaches either state after
    `/task-add feature=<slug>` has run, so `Tasks: none` there means the
    backlog was cleaned before task archiving, when `/task-clean` dropped
    completed IDs from the line instead of archiving them — not that
    planning never happened. Never say `no tasks yet` on such a feature.
  - any other status (`[NEW]`, `[ITERATED]`) → `no tasks yet` — and that,
    and only that, is the signal that `/task-add feature=<slug>` has not
    run.

  Both halves apply under `--task-ids` unchanged: a `[DONE]`/`[PLANNED]`
  feature with zero tasks renders `-` there too, never an empty ID list.

**The Next field** is section 2's last field, derived per feature from its
`FEATURES.md` status, its task rollup and its readiness. It names the one
concrete action to take on the feature rather than restating readiness, and
is exactly one of the six values below.

An archived ID is terminal, so it counts as resolved throughout: wherever a
value below speaks of a task that is not `[DONE]`/`[SKIP]`, an archived one
is never meant. It never keeps a feature from `flip to [DONE] in
FEATURES.md`, and it is never the `<N>` in `/task-implement <N>`.

- `-` — the feature is `[DONE]`. Compute nothing for it, readiness
  included; there is no next action on a finished feature.
- `/task-add feature=<slug>` — the feature is `[NEW]` or `[ITERATED]`.
  Print it even when the feature is blocked: planning is never blocked by a
  dependency, and re-planning through `/task-add` is exactly what an
  `[ITERATED]` feature needs.
- `flip to [DONE] in FEATURES.md` — the feature is `[PLANNED]` and has no
  task that is not `[DONE]`, `[SKIP]` or archived — an all-archived
  `Tasks:` line and the zero-task case included. It is a suggestion for the
  user to make that edit by hand; never act on it — this command never
  edits `FEATURES.md`. Print it even when the feature is blocked — there is
  no work left for a dependency to block.
- `/task-implement <N>` — the feature is `[PLANNED]`, has at least one task
  that is not `[DONE]`/`[SKIP]`, is **not** blocked, and at least one such
  task has its preconditions satisfied. `<N>` is the feature's first task,
  in appearance order in `TASKS.md`, that is not `[DONE]`, `[SKIP]` or
  archived and whose `Preconditions:` are all `[DONE]` or `[SKIP]`; ignore a
  precondition id resolving to no task. That is the precondition half of the
  eligibility clause whose authority is `task-engine`'s
  `references/resolution.md` § *Selectors* — named here as the rule's home,
  not as a file this command opens. This bullet states fully the part this
  field needs, and `Preconditions:` comes from the summary blocks already
  read, so the Next field adds no read.
- `blocked by <slug>[, <slug>]` — the feature is `[PLANNED]`, has at least
  one task that is not `[DONE]`/`[SKIP]`, but the feature **is** blocked;
  name every unsatisfied dependency. Check feature blockedness first: a
  blocked feature shows this value whatever its tasks' preconditions say.
  It is the only feature-level status that suppresses the action, because
  `/task-implement` is the only suggested action a dependency can actually
  block.
- `waits on task <id>[, <id>]` — the feature is `[PLANNED]`, has at least
  one task that is not `[DONE]`/`[SKIP]`, and is **not** blocked, but every
  such task has an unmet precondition, so there is no `<N>` to name. Name
  the unmet precondition ids of the feature's first such task in appearance
  order. Those are the ids to finish first, and a reader following them one
  hop at a time reaches the task that can start — unless the edges form a
  cycle, which `/task-implement all` reports as blocked.

The Next field changes only section 2's presentation; sections 3, 4 and 5
are built from readiness itself.

---

OUTPUT — eight sections, in this order

**1. The milestone.** Its slug, title and `Status:`. Echo its `Goal:` and its
`Exit criteria:` verbatim from the matching milestone block in
`.claude/domain/product-roadmap.md`. Omit both headings entirely when there
is no roadmap or the roadmap has no block with that slug — do not invent
them, and do not warn twice.

**2. Its features, in plan order.** Render a **markdown table**, one row per
feature, in the milestone's `Features:` order, since that order is the
priority. The columns are `#`, `Feature`, `Status`, `Tasks`, `Next`, in that
order and under those headings — not a bullet list, not a numbered list, not
a padded plain-text block:

| # | Feature | Status | Tasks | Next |
| --- | --- | --- | --- | --- |
| 1 | `<slug>` | `[PLANNED]` | 4 tasks — DONE: 2, MISSING: 2 | `/task-implement 43` |
| 2 | `<slug>` | `[NEW]` | no tasks yet | `/task-add feature=<slug>` |
| 3 | `<slug>` | `[DONE]` | 5 tasks — DONE: 5 | - |
| 4 | `<slug>` | `[PLANNED]` | 3 tasks — DONE: 1, MISSING: 2 | blocked by `<slug>` |
| 5 | `<slug>` | `[PLANNED]` | - | flip to `[DONE]` in `FEATURES.md` |
| 6 | `<slug>` | `[PLANNED]` | 2 tasks — MISSING: 2 | waits on task 38 |

- Each row carries its `FEATURES.md` status, its task rollup, and its
  **Next** value — per **The Next field** under READINESS above, which is
  the authority on which of its six values a row gets.
- A `[DONE]` row carries `-` in `Next`, never an empty cell.
- A slug in `Features:` with no `FEATURES.md` entry keeps its row and its
  plan position, carries `-` in `Status`, `Tasks` and `Next`, and is named as
  a plan inconsistency in one line under the table.
- Under `--task-ids` the `Tasks` column holds the ID list instead of the
  counts; the table is otherwise unchanged.
- `Features: none` → say the milestone has no features and that `/architect`
  has not run its `Covers:` slices yet.

**3. The ready set.** Every ready feature in this milestone, in plan
order — never a `[DONE]` one.

- Empty because everything is blocked → say so, and say what the nearest
  blocker is.
- Empty because every otherwise-ready feature in the milestone is already
  `[DONE]` → say that instead: nothing left to plan in this milestone, and
  point at `/production-plan` in case it's ready to propose `[SHIPPED]`.

**4. The recommended next feature** — the **first ready feature in plan
order** from the set in section 3, exactly one, named on its own with its
task rollup and the same **Next** value section 2 gave it.

- Echo that Next value; never recompute it here. The rule under READINESS is
  the report's only place a next action is derived — a second derivation
  would contradict section 2 on the very features this report exists to be
  right about.
- Never recommend more than one feature.
- If section 3 is empty, say there is nothing to recommend right now,
  echoing whichever of the two reasons section 3 gave.
- Start nothing here.

**5. Blocked features.** Every blocked feature in this milestone, each with
every unsatisfied dependency and why it is unsatisfied.

**6. Coverage gaps.** Plan-wide, not scoped by `milestone=`. Two kinds, both
derived:

- Milestones whose `Features:` is `none` — roadmap slices nothing has been
  architected for. This is outstanding `/architect` work; name the milestone
  and its `Covers:` sections.
- `product-design.md` sections that no milestone's `Covers:` line names, when
  a roadmap exists. Omit this half entirely when there is no roadmap.

**7. Unplanned features.** Also plan-wide. Every `FEATURES.md` slug that
appears in no milestone's `Features:` list and not in `Unscheduled` either,
plus everything sitting in `Unscheduled`. Name them and point at
`/production-plan`. Empty → say the plan covers every architected feature.

**8. Remaining milestones**, one line each: slug, title, `Status:`, and how
many features it holds. Every milestone in plan order other than the one
reported in section 1.

---

STALENESS — structural, never temporal

- The staleness signal is a `FEATURES.md` slug missing from `PLAN.md`, which
  section 7 reports. That is the whole of it.
- Never compare `Last reconciled:` against file modification times, against
  today's date, or against anything else. It is informational only: compute
  nothing from it and never treat it as an expiry. Echoing it as a plain fact
  in the header is fine; drawing a conclusion from it is not.

---

FAILURE CONTRACT — degradation, never refusal

A read-only report must never be the thing that stops a session. Degrade and
carry on in every one of these:

| Situation | Behaviour |
| --- | --- |
| No `.claude/PLAN.md` | Say the project has no plan and point at `/production-plan`. Stop there — there is nothing to join. Do NOT create the file. |
| No `.claude/FEATURES.md` | Say so, report the plan's structure (milestones, order, edges) with no feature statuses or rollups, and point at `/domain-setup` + `/architect`. |
| No roadmap | Omit `Goal:` and `Exit criteria:` and the design-section half of section 6. Report everything else normally. One line, no warning ceremony. |
| No `.claude/TASKS.md` | Features report with no task rollup, and every feature with satisfied dependencies is ready. Section 2's table keeps all five columns, with an empty `Tasks` cell on every row and an empty `Next` cell on `[PLANNED]` features, whose next action cannot be derived without task statuses; every other status keeps its `Next` value. |
| No `[ACTIVE]` milestone | Report the first `[PLANNED]` one and say none is active. |
| More than one `[ACTIVE]` | Report the first in plan order, name both, call it a plan inconsistency. |
| Dependency edge naming an unknown slug | Report the inconsistency and treat the dependent feature as ready. Fail open. |
| A `Features:` slug with no `FEATURES.md` entry | Report the inconsistency, keep its row in the plan order, `-` in `Status`, `Tasks` and `Next`. |
| `PLAN.md` present but with no milestones | Report `Unscheduled` and sections 6–8 only, and say no milestone is planned. |

The only stop other than "no `PLAN.md`" is an unknown `milestone=<slug>`.
