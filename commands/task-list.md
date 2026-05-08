---
name: task-list
version: 0.1.1
type: command
description: Print the project's task backlog as a compact summary, optionally filtered by status. Read-only.
---

# /task-list
# Global command: print the project's task backlog as a compact summary,
# optionally filtered by status. Read-only — never modifies any file.
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

TOOL DISCIPLINE

Use the Read tool to open the backlog file — never `cat`, `type`,
`Get-Content`, or any shell command for file reads. This command performs
no writes; Bash and PowerShell are not needed at all.

---

LOCATING THE BACKLOG FILE

Search order:
1. `.claude/TASKS.md`
2. `TASKS.md`
3. `docs/TASKS.md`

If none exist, tell the user "No backlog file found. Use /task-add to create
one." and stop. Do NOT create the file.

---

STATUS TAGS (the only allowed values)

`[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]`, `[IN PROGRESS]`,
`[DONE]`, `[SKIP]`.

If the user passes a filter, accept it case-insensitively and with or without
brackets — `MISSING`, `missing`, `[MISSING]`, `in progress`, and
`[IN PROGRESS]` are all valid. If the filter doesn't match any known status,
tell the user the valid options and stop.

---

WORKFLOW

1. Use the Read tool to open the backlog file. Parse each task entry — they
   are numbered, indented two spaces, and separated by `---` lines. For each
   task extract:
   - Number
   - Title (the text after `N.` on the title line)
   - Status (the value on the `Status:` line, including its brackets)
   - Preconditions (the value on the `Preconditions:` line)

2. Apply the filter if `$ARGUMENTS` is non-empty. Match on the status tag.

3. Render output as a single compact block. One line per task:

   ```
   N.  [STATUS]      Title
   ```

   - Pad the status column so titles align. The longest tag is
     `[IN PROGRESS]` (13 chars).
   - Preserve the original task numbers — do NOT renumber for display.
   - If a task has non-`none` preconditions, append `(deps: 3, 7)` at the
     end of the line so the user can see the dependency chain at a glance.

4. After the per-task lines, print a one-line summary:

   ```
   <N> tasks shown — MISSING: 4, IN PROGRESS: 1, DONE: 12, SKIP: 1
   ```

   Include only the status counts that are non-zero. If a filter was applied,
   the summary reflects only the filtered subset and notes the filter:

   ```
   3 tasks shown (filter: MISSING)
   ```

5. If the filter matches zero tasks, say so explicitly: "No tasks with
   status [MISSING]." Do not print an empty table.

DO NOT:
- Open the source files referenced by tasks. This command is purely a
  backlog reader — it does not verify task accuracy or current state.
- Suggest next actions, recommend which task to start, or comment on
  staleness. Just list.
- Write, edit, or commit anything.
- Truncate long titles. If a title is unusually long, let it overflow the
  column — alignment is best-effort, not strict.
