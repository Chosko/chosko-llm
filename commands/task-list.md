---
name: task-list
version: 0.6.0
type: command
description: Print the project's task backlog as a compact summary, optionally filtered by status. Marks human-in-the-loop tasks (target claude+human or human) with a ⚠ so the user can see which tasks need them present, marks [STALE] tasks whose originating feature was re-architected, and shows the Feature: slug on feature-derived tasks. When the project has a .claude/PLAN.md, groups tasks by milestone in plan order — resolving each task's Feature: slug through the plan — and flags tasks whose feature is blocked with the blocker's name; with no plan, output is exactly what it has always been. Read-only — reads TASKS.md, and PLAN.md plus FEATURES.md when a plan exists, never the per-task body files.
requires: skill:task-engine
---

# /task-list
# Global command: print the project's task backlog as a compact summary,
# optionally filtered by status. Read-only — never modifies any file. Reads
# `.claude/TASKS.md`, plus `.claude/PLAN.md` and `.claude/FEATURES.md` when
# the project has a production plan; the per-task body files under
# `.claude/tasks/` are NOT opened by this command.
# Usage: /task-list
#        /task-list <STATUS>
# Examples: /task-list
#           /task-list MISSING
#           /task-list IN PROGRESS
#           /task-list DONE

GOAL
Give the user a quick, scannable view of the task backlog. This is a
diagnostic / orientation command — it must not write, edit, or commit
anything. If `$ARGUMENTS` provides a status filter, only show tasks with
that status.

$ARGUMENTS

---

LOCATING THE BACKLOG

Backlog resolution follows
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`,
whose `/task-list` note carries every way this command departs from it: the
wording of the not-initialised stop, the no-writes / no-shell guarantee, and
the ban on opening anything under `.claude/tasks/`.

The plan probe below is this command's own; nothing in the engine covers it.

After `.claude/TASKS.md`, probe for `.claude/PLAN.md`. If it is absent —
the normal state of most projects — this command behaves in **every**
respect exactly as it always has: no grouping, no blocker flags, no extra
reads, and **no message about a missing plan**. Say nothing about it at
all. Skip the PLAN-AWARE GROUPING section below entirely and render the
flat list.

If it is present, also read `.claude/FEATURES.md` (a plan with no feature
index is treated as no plan) and follow PLAN-AWARE GROUPING. Both files
are read-only, like `TASKS.md`.

---

STATUS TAGS AND THE FILTER

The status vocabulary, and how a status argument is accepted, are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/status.md`. Its
`/task-list` note carries what this command adds: the `[STALE]` gloss and the
padded status column.

Here a status is a display filter and nothing else — `$ARGUMENTS` is never a
task selector, and this command writes no status anywhere.

---

PLAN-AWARE GROUPING (only when `.claude/PLAN.md` exists)

Everything in this section is skipped when there is no plan. It adds
grouping and one marker; it changes nothing else — not the status tags,
not the filter, not the summary line's shape.

**What to read from `PLAN.md`:**

- Each `## <milestone-slug> — <title>` block, **in plan order, top to
  bottom** — that order is the report's group order. Take its `Status:`
  (`[PLANNED]` / `[ACTIVE]` / `[SHIPPED]`) and its ordered `Features:`
  list (comma-separated slugs, or the literal `none`).
- The `## Unscheduled` block's `Features:` list.
- The one flat `## Dependencies` list at the end of the document, whose
  lines read `- <slug>: depends on <slug>, <slug>`. There is no
  `Depends:` line on a feature block; do not look for one.

**Resolving a task to a milestone.** Take the task's `Feature:` slug and
find the milestone whose `Features:` list contains it. That milestone is
the task's group.

- A task with **no `Feature:` line** — every free-form task — groups
  under a trailing `Unplanned` heading.
- A `Feature:` line naming a slug that **no milestone's `Features:` list
  contains** — including a slug sitting in `Unscheduled`, and a slug the
  plan does not mention at all — groups under that same trailing
  `Unplanned` heading.
- A milestone with no tasks in the (filtered) output gets no heading.
  Do not print empty groups.

**Blocked-ness** uses exactly the rule `/production-status` uses; the two
commands share the rule, not an implementation. A feature is **blocked**
when some dependency edge pointing at it originates from a feature that
is **not** `[DONE]` in `FEATURES.md`, and **not** `[PLANNED]` with **all**
of its tasks `[DONE]` or `[SKIP]` in `TASKS.md`. A feature with no incoming
edges is never blocked. An edge naming a slug that resolves to no feature is
ignored rather than treated as a blocker — fail open, so a hand-edited
plan cannot flag the whole backlog.

Every task whose feature is blocked carries `⚠ blocked by <slug>`,
naming the blocking feature (or features, comma-separated). Tasks whose
feature is not blocked, and tasks with no `Feature:` line, carry nothing.

**Rendering the groups.** One heading per non-empty milestone, in plan
order, then the trailing unplanned group:

```
m1-mvp — Minimum viable product   [ACTIVE]

  12. [DONE]         Title
  13. [MISSING]      Title  [session-handling]

Unplanned

  4.  [MISSING]      Title
```

The per-task line is rendered exactly as WORKFLOW step 3 describes,
including the padding, and indented under its heading. The filter of
WORKFLOW step 2 is applied **before** grouping, so it works within
groups, and the summary line of step 4 is unchanged and counts the whole
(filtered) output rather than being repeated per group.

---

WORKFLOW

1. Read `.claude/TASKS.md` and parse it exactly as
   `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
   § *Parsing the index* describes. `/task-list` uses every field named
   there, and displays the `Last task number: N` header value in the
   summary line so the user can see the highest ID ever assigned, even
   when pruned.

2. Apply the filter if `$ARGUMENTS` is non-empty. Match on the status
   tag.

3. Render output as a single compact block. One line per task:

   ```
   N.  [STATUS]      Title
   ```

   - Pad the status column so titles align. The longest tag is
     `[IN PROGRESS]` (13 chars).
   - Preserve the original task IDs — they are stable, do NOT
     renumber for display. IDs aren't sequential, so unfenced `N.`
     lines get renumbered by markdown renderers. Print the actual
     output (steps 3-5) inside one fenced code block to keep it literal.
   - If the task's target is `claude+human` or `human`, append
     `⚠ <target>` after the title (before any deps annotation) so
     human-in-the-loop tasks are visible at a glance. Target `claude`
     gets no marker.
   - If the task has a `Feature:` line, append `[<slug>]` after the
     title (after any `⚠ <target>` marker, before the staleness marker
     and the deps annotation) so the task's origin is visible. Tasks
     with no `Feature:` line get nothing.
   - If the status is `[STALE]`, append `⚠ stale` at the end of the
     line, after the deps annotation. The status column already shows
     `[STALE]`, but the marker keeps it visible in the same scan as the
     human-in-the-loop `⚠` — a stale task is the one status that needs
     the user to act (reconcile it, or decide it still applies).
   - If a task has non-`none` preconditions, append `(deps: 3, 7)`
     before any staleness marker.
   - If the project has a `PLAN.md` and the task's feature is blocked,
     append `⚠ blocked by <slug>` at the very end of the line. Without a
     `PLAN.md` this marker never appears.

   **Marker order** — everything after the title, left to right, so the
   lines stay scannable no matter which markers a task happens to have:

   ```
   N.  [STATUS]      Title  ⚠ <target>  [<slug>]  (deps: 3, 7)  ⚠ stale  ⚠ blocked by <slug>
   ```

   Omit any marker that does not apply; never reorder them, and never
   drop one to make room for another.

4. If the project has a `PLAN.md`, group the (filtered) lines under
   milestone headings per PLAN-AWARE GROUPING above. With no `PLAN.md`,
   print the lines as one flat block, exactly as always.

5. After the per-task lines, print a one-line summary, inside the same
   fenced code block:

   ```
   <N> tasks shown — MISSING: 4, IN PROGRESS: 1, DONE: 12, SKIP: 1   (last task number: 17)
   ```

   Include only the status counts that are non-zero. If a filter was
   applied, the summary reflects only the filtered subset and notes the
   filter:

   ```
   3 tasks shown (filter: MISSING)   (last task number: 17)
   ```

   The `last task number` annotation is informational — it tells the
   user the next ID `/task-add` will assign is `last + 1`. Include it
   in both filtered and unfiltered output.

6. If the filter matches zero tasks, say so explicitly: "No tasks with
   status [MISSING]." Do not print an empty table, and do not print
   milestone headings with nothing under them.

DO NOT:
- Open any file under `.claude/tasks/`. The body files exist for
  `/task-implement`; `/task-list` is purely an index reader.
- Open the source files referenced by tasks.
- Open feature documents under `.claude/domain/features/`, or the
  roadmap. Grouping needs `PLAN.md`, `FEATURES.md` and `TASKS.md` and
  nothing else.
- Say anything at all about a missing `.claude/PLAN.md`. On a project
  with no plan the output is byte-for-byte what it has always been — a
  silent no-op, not a warning, not a suggestion to run
  `/production-plan`.
- Reorder milestones by anything other than their position in `PLAN.md`,
  or reorder tasks within a group by anything other than their ID.
- Suggest next actions, recommend which task to start, or comment on
  staleness. Just list.
- Write, edit, or commit anything.
- Truncate long titles. If a title is unusually long, let it overflow
  the column.
