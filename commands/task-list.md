---
name: task-list
version: 0.3.1
type: command
description: Print the project's task backlog as a compact summary, optionally filtered by status. Marks human-in-the-loop tasks (target claude+human or human) with a ⚠ so the user can see which tasks need them present. Read-only — reads only TASKS.md, never the per-task body files.
---

# /task-list
# Global command: print the project's task backlog as a compact summary,
# optionally filtered by status. Read-only — never modifies any file. Reads
# only `.claude/TASKS.md`; the per-task body files under `.claude/tasks/`
# are NOT opened by this command.
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

This command performs no writes and needs no shell at all. Do NOT open any
file under `.claude/tasks/` — TASKS.md already contains everything
`/task-list` needs.

The backlog index lives at `.claude/TASKS.md`. If it does not exist,
tell the user "No backlog file found. Run /task-setup to initialize it,
then /task-add to create the first task." and stop. Do NOT create the
file.

---

STATUS TAGS (the only allowed values)

`[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]`, `[IN PROGRESS]`,
`[DONE]`, `[SKIP]`.

If the user passes a filter, accept it case-insensitively and with or
without brackets — `MISSING`, `missing`, `[MISSING]`, `in progress`, and
`[IN PROGRESS]` are all valid. If the filter doesn't match any known
status, tell the user the valid options and stop.

---

WORKFLOW

1. Use the Read tool to open `.claude/TASKS.md`. Parse:
   - The `Last task number: N` header value — display it in the
     summary line so the user can see the highest ID ever assigned,
     even when pruned.
   - Each summary block. Extract:
     - Number (from the `## N. Title` line)
     - Title (the text after `N.`)
     - Status (the value on the `Status:` line, including its brackets)
     - Target (the value on the `Target:` line; treat a missing line
       as `claude`)
     - Preconditions (the value on the `Preconditions:` line)

2. Apply the filter if `$ARGUMENTS` is non-empty. Match on the status
   tag.

3. Render output as a single compact block. One line per task:

   ```
   N.  [STATUS]      Title
   ```

   - Pad the status column so titles align. The longest tag is
     `[IN PROGRESS]` (13 chars).
   - Preserve the original task IDs — they are stable, do NOT
     renumber for display.
   - If the task's target is `claude+human` or `human`, append
     `⚠ <target>` after the title (before any deps annotation) so
     human-in-the-loop tasks are visible at a glance. Targets `claude`
     and `local` get no marker.
   - If a task has non-`none` preconditions, append `(deps: 3, 7)` at
     the end of the line.

4. After the per-task lines, print a one-line summary:

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

5. If the filter matches zero tasks, say so explicitly: "No tasks with
   status [MISSING]." Do not print an empty table.

DO NOT:
- Open any file under `.claude/tasks/`. The body files exist for
  `/task-implement`; `/task-list` is purely an index reader.
- Open the source files referenced by tasks.
- Suggest next actions, recommend which task to start, or comment on
  staleness. Just list.
- Write, edit, or commit anything.
- Truncate long titles. If a title is unusually long, let it overflow
  the column.
