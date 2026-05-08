---
name: task-clean
version: 0.1.1
type: command
description: Prune tasks in a terminal status from the project's task backlog, renumber survivors, and update precondition references.
---

# /task-clean
# Global command: prune tasks in a terminal status from the project's task
# backlog, renumber the remaining tasks, and update any precondition
# references. Always reports the plan and asks for explicit confirmation
# before writing.
# Usage: /task-clean
#        /task-clean <STATUS> [<STATUS> ...]
# Examples: /task-clean
#           /task-clean DONE
#           /task-clean DONE SKIP

GOAL
Remove tasks that are finished or abandoned so the backlog stays focused on
work that still needs doing. Renumber the survivors so the list is
contiguous, and rewrite every `Preconditions:` reference that pointed at a
removed-or-renumbered task. Always confirm with the user before writing.

$ARGUMENTS

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to an existing file;
  use the Write tool only when creating a new file from scratch. Never use
  shell redirection, `tee`, `Set-Content`, `Out-File`, or any shell
  mechanism to write files.
- Bash / PowerShell are not needed by this command at all.

---

LOCATING THE BACKLOG FILE

Search order:
1. `.claude/TASKS.md`
2. `TASKS.md`
3. `docs/TASKS.md`

If none exist, tell the user and stop. Do NOT create the file.

---

WHICH STATUSES COUNT AS "TERMINAL"

Default (when `$ARGUMENTS` is empty): `[DONE]` and `[SKIP]`. These are the
two statuses that indicate the task no longer needs work — done means the
code landed, skip means the user has decided not to do it.

If `$ARGUMENTS` lists one or more status tags (case-insensitive, brackets
optional), use that explicit set instead. Accept any of the canonical
statuses (`[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]`,
`[IN PROGRESS]`, `[DONE]`, `[SKIP]`) but warn if the user is asking to
prune a non-terminal status:

- `[IN PROGRESS]` — currently being worked on. Pruning is almost certainly
  a mistake. Confirm twice, the second time with the specific tasks listed.
- `[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]` — these mean work
  still remains. Pruning them throws away the spec. If the user really
  wants to discard a task, this is the right command for it, but flag the
  unusual choice in the plan.

If the user passes a tag that isn't one of the canonical statuses, list
the valid options and stop.

---

PHASE 1 — REPORT (no file writes)

1. Use the Read tool to open the backlog file. Parse every task entry —
   number, title, status, `Preconditions:` line.

2. Identify the tasks whose status matches the prune set. If there are none,
   tell the user "No tasks to prune." and stop.

3. Compute the renumbering map. After removing the matched tasks, the
   survivors are renumbered to a contiguous sequence starting at 1 (or at
   whatever the file's first task number currently is — match the
   existing convention; most files start at 1). Build a mapping
   `old_number → new_number` for the survivors.

4. Find every `Preconditions:` line that references either:
   - A pruned task number → that reference will be REMOVED from the
     precondition list. If removing it leaves the list empty, the line
     becomes `Preconditions: none`.
   - A renumbered task → that reference will be REWRITTEN to the new
     number.

5. Render the plan:

   ```
   PLAN — task-clean

   Backlog file: <path>
   Pruning statuses: [DONE], [SKIP]   (or whatever set applies)

   Tasks to remove (N):
     3.  [DONE]  Title …
     7.  [DONE]  Title …
     12. [SKIP]  Title …

   Renumbering: <none | "tasks 4→3, 5→4, 6→5, 8→6, 9→7, 10→8, 11→9, 13→10">

   Precondition references to update (M):
     Task 8 (was 11): Preconditions "3, 7" → "none"
     Task 10 (was 13): Preconditions "12" → "none"
     ...

   Anything in [IN PROGRESS]? <yes/no — if yes, list them as a heads-up
   so the user notices unfinished work before pruning around it>
   ```

   End with a single explicit prompt: **"Apply?"**

   Wait for the user. If they ask to change the prune set or exclude
   specific tasks, re-render the plan after the change. Do NOT proceed to
   PHASE 2 without an explicit approval ("yes", "go", "apply", or
   similar). Silence is not approval.

---

PHASE 2 — APPLY (only after explicit approval)

1. Use the Edit tool to remove the matched task entries from the file,
   including the `---` separator that precedes each one. Preserve the
   file's overall formatting (two-space indentation, blank lines between
   tasks).

2. Use the Edit tool to renumber the survivors per the mapping. The number
   appears once per task on its title line (`N. <title>`).

3. Use the Edit tool to rewrite every `Preconditions:` line per the plan.
   After rewriting, use Grep to re-check the file for any reference to a
   now-nonexistent number and confirm no stale references remain.

4. Report to the user:
   - Number of tasks removed.
   - Number of tasks renumbered.
   - Number of `Preconditions:` lines rewritten.
   - Final task count.

DO NOT:
- Write to the backlog file during PHASE 1.
- Touch tasks whose status is not in the prune set.
- Change task content other than its number and (when needed) its
  `Preconditions:` line.
- Commit. This command does not touch git — the user decides whether to
  commit the cleanup as its own change.
