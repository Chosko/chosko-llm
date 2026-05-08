# Smoke test: task-list

**Type:** command
**Source:** commands/task-list.md

## Setup

- A `.claude/TASKS.md` with tasks in several different statuses, plus
  per-task body files under `.claude/tasks/`. Note the
  `Last task number:` value before running.

## Steps

1. Invoke `/task-list` (no arguments).
2. Observe tabular output: one line per task with number, status, title.
3. Observe summary line with counts per non-zero status.

## Expected

- Output is read-only — no files modified, no git activity.
- Only `.claude/TASKS.md` is read; verify (e.g. via tool transcript)
  that no file under `.claude/tasks/` is opened.
- Task IDs displayed match TASKS.md exactly — no renumbering for
  display.
- Status column is padded to align titles (longest tag:
  `[IN PROGRESS]`).
- Tasks with non-`none` preconditions show `(deps: N, M)`.
- Summary line lists only non-zero status counts and includes the
  `(last task number: N)` annotation.

## Notes

- Test `/task-list MISSING` (filtered view) — summary should note the filter.
- Test `/task-list IN PROGRESS` (two-word status, case-insensitive).
- Test a filter that matches zero tasks — should print explicit "No tasks"
  message, not an empty table.
- Test an invalid status tag — agent should list valid options and stop.
