---
name: task-list
version: 0.6.4
type: command
description: Print the project's task backlog as a compact summary, optionally filtered by status — marking tasks that need a human present, tasks gone stale and tasks parked on a question, and grouping by milestone when the project has a plan. Use it to see what is open before picking, adding or pruning a task.
requires: skill:task-engine
---

# /task-list
# Global command: print the project's task backlog as a compact summary,
# optionally filtered by status. Marks human-in-the-loop tasks (target
# claude+human or human) with a ⚠, marks [STALE] tasks whose originating
# feature was re-architected and [PARKED] tasks waiting on an answer, and
# shows the `Feature:` slug on feature-derived tasks. With a `.claude/PLAN.md`, groups tasks by milestone
# in plan order and flags tasks whose feature is blocked with the blocker's
# name; without one, output is the flat list. Read-only — never modifies any
# file. Reads `.claude/TASKS.md`, plus `.claude/PLAN.md` and
# `.claude/FEATURES.md` when the project has a production plan; the per-task
# body files under `.claude/tasks/` are NOT opened by this command.
# Usage: /task-list
#        /task-list <STATUS>
# Examples: /task-list
#           /task-list MISSING
#           /task-list IN PROGRESS
#           /task-list PARKED
#           /task-list DONE

GOAL
- Give the user a quick, scannable view of the task backlog.
- This is a diagnostic / orientation command: it must not write, edit, or
  commit anything.
- If `$ARGUMENTS` provides a status filter, show only tasks with that status.

$ARGUMENTS

---

LOCATING THE BACKLOG

- Resolve the backlog per `../skills/task-engine/references/resolution.md`.
  Its `/task-list` note carries every way this command departs from it: the
  wording of the not-initialised stop, the no-writes / no-shell guarantee,
  and the ban on opening anything under `.claude/tasks/` — `/task-list` is
  purely an index reader.
- After `.claude/TASKS.md`, probe for `.claude/PLAN.md`. This probe is this
  command's own; nothing in the engine covers it.
  - **Absent** (the normal state of most projects): skip PLAN-AWARE
    GROUPING entirely — no grouping, no blocker flags, no extra reads —
    and render the flat list. Say nothing at all about the missing plan:
    a silent no-op, not a warning, not a suggestion to run
    `/production-plan`.
  - **Present**: also read `.claude/FEATURES.md` and follow PLAN-AWARE
    GROUPING. Treat a plan with no feature index as no plan.
- Read `PLAN.md` and `FEATURES.md` read-only, like `TASKS.md`.

---

STATUS TAGS AND THE FILTER

- The status vocabulary, and how a status argument is accepted, are
  `../skills/task-engine/references/status.md`. Its `/task-list` note
  carries what this command adds: the `[STALE]` gloss, the `[PARKED]`
  marker and the padded status column.
- A status is a display filter and nothing else: `$ARGUMENTS` is never a
  task selector, and this command writes no status anywhere.

---

WORKFLOW

1. Read `.claude/TASKS.md` and parse it exactly as
   `../skills/task-engine/references/resolution.md`
   § *Parsing the index* describes. Use every field named there. Display
   the `Last task number: N` header value in the summary line so the user
   can see the highest ID ever assigned, even when pruned.

2. If `$ARGUMENTS` is non-empty, apply the filter: match on the status
   tag.

3. Render output as a single compact block, one line per task:

   ```
   N.  [STATUS]      Title
   ```

   - Pad the status column so titles align. Of the nine tags the longest
     is `[IN PROGRESS]` (13 chars); `[PARKED]` fits the same column.
   - Preserve the original task IDs — they are stable; do NOT renumber
     for display.
   - Print the actual output (steps 3-5) inside one fenced code block to
     keep it literal: IDs aren't sequential, so markdown renderers
     renumber unfenced `N.` lines.
   - Never truncate long titles. If a title is unusually long, let it
     overflow the column.
   - Append these markers after the title, each only when it applies:
     - `⚠ <target>` — when the task's target is `claude+human` or
       `human`, so human-in-the-loop tasks are visible at a glance.
       Target `claude` gets no marker.
     - `[<slug>]` — when the task has a `Feature:` line, so the task's
       origin is visible. Tasks with no `Feature:` line get nothing.
     - `(deps: 3, 7)` — when the task has non-`none` preconditions.
     - `⚠ stale` — when the status is `[STALE]`, even though the status
       column already shows it: a stale task needs the user to act.
     - `⚠ parked` — when the status is `[PARKED]`, in the same slot as
       `⚠ stale`. A task is never both stale and parked, so the slot holds
       one marker.
     - `⚠ blocked by <slug>` — at the very end of the line, when the
       project has a `PLAN.md` and the task's feature is blocked (see
       PLAN-AWARE GROUPING). Without a `PLAN.md` this marker never
       appears.

   **Marker order** — everything after the title, left to right, so the
   lines stay scannable no matter which markers a task happens to have:

   ```
   N.  [STATUS]      Title  ⚠ <target>  [<slug>]  (deps: 3, 7)  ⚠ stale | ⚠ parked  ⚠ blocked by <slug>
   ```

   Omit any marker that does not apply; never reorder them, and never
   drop one to make room for another.

4. If the project has a `PLAN.md`, group the (filtered) lines under
   milestone headings per PLAN-AWARE GROUPING below. With no `PLAN.md`,
   print the lines as one flat block.

5. After the per-task lines, print a one-line summary inside the same
   fenced code block:

   ```
   <N> tasks shown — MISSING: 4, IN PROGRESS: 1, DONE: 12, SKIP: 1   (last task number: 17)
   ```

   - Include only the status counts that are non-zero.
   - Include the `last task number` annotation in both filtered and
     unfiltered output. It is informational: it tells the user the next
     ID `/task-add` will assign is `last + 1`.
   - If a filter was applied, the summary reflects only the filtered
     subset and notes the filter:

   ```
   3 tasks shown (filter: MISSING)   (last task number: 17)
   ```

6. If the filter matches zero tasks, say so explicitly: "No tasks with
   status [MISSING]." Do not print an empty table, and do not print
   milestone headings with nothing under them.

---

PLAN-AWARE GROUPING (only when `.claude/PLAN.md` exists)

Skip this whole section when there is no plan. It adds grouping and one
marker; it changes nothing else — not the status tags, not the filter, not
the summary line's shape.

**What to read from `PLAN.md`:**

- Each `## <milestone-slug> — <title>` block, **in plan order, top to
  bottom** — that order is the report's group order. Take its `Status:`
  (`[PLANNED]` / `[ACTIVE]` / `[SHIPPED]`) and its ordered `Features:`
  list (comma-separated slugs, or the literal `none`).
- The `## Unscheduled` block's `Features:` list.
- The one flat `## Dependencies` list at the end of the document, whose
  lines read `- <slug>: depends on <slug>, <slug>`. There is no
  `Depends:` line on a feature block; do not look for one.

**Resolving a task to a milestone.**

- Take the task's `Feature:` slug and find the milestone whose `Features:`
  list contains it. That milestone is the task's group.
- Group under a trailing `Unplanned` heading:
  - a task with **no `Feature:` line** — every free-form task;
  - a task whose `Feature:` slug **no milestone's `Features:` list
    contains** — including a slug sitting in `Unscheduled`, and a slug the
    plan does not mention at all.
- Give a milestone with no tasks in the (filtered) output no heading. Do
  not print empty groups.

**Blocked-ness** — exactly the rule `/production-status` uses; the two
commands share the rule, not an implementation.

- A feature is **blocked** when some dependency edge pointing at it
  originates from a feature that is **not** `[DONE]` in `FEATURES.md`, and
  **not** `[PLANNED]` with **all** of its tasks `[DONE]` or `[SKIP]` in
  `TASKS.md`.
- A feature with no incoming edges is never blocked.
- Ignore an edge naming a slug that resolves to no feature rather than
  treating it as a blocker (fail open).
- Every task whose feature is blocked carries `⚠ blocked by <slug>`,
  naming the blocking feature (or features, comma-separated). Tasks whose
  feature is not blocked, and tasks with no `Feature:` line, carry nothing.

**Rendering the groups.**

One heading per non-empty milestone, in plan order, then the trailing
unplanned group:

```
m1-mvp — Minimum viable product   [ACTIVE]

  12. [DONE]         Title
  13. [MISSING]      Title  [session-handling]

Unplanned

  4.  [MISSING]      Title
```

- Render each per-task line exactly as WORKFLOW step 3 describes,
  including the padding, indented under its heading.
- Apply the filter of WORKFLOW step 2 **before** grouping, so it works
  within groups.
- Print the summary line once, unchanged: it counts the whole (filtered)
  output rather than being repeated per group.
- Order milestones only by their position in `PLAN.md`, and tasks within a
  group only by their ID.

---

DO NOT:
- Open the source files referenced by tasks.
- Open feature documents under `.claude/domain/features/`, or the
  roadmap. Grouping needs `PLAN.md`, `FEATURES.md` and `TASKS.md` and
  nothing else.
- Suggest next actions, recommend which task to start, or comment on
  staleness or a parked question. Just list.
