# Smoke test: task-clean

**Type:** command
**Source:** commands/task-clean.md

## Setup

- A `.claude/TASKS.md` with tasks in mixed statuses including at least one
  `[DONE]` and one `[SKIP]`.

## Steps

1. Invoke `/task-clean` (no arguments).
2. Observe the PLAN output: tasks to remove, renumbering map, precondition
   references to update.
3. Confirm with "yes".
4. Inspect the file: pruned tasks gone, survivors renumbered, precondition
   references updated.

## Expected

- No file is written during PHASE 1.
- Only `[DONE]` and `[SKIP]` tasks are removed by default.
- Renumbering is contiguous starting from 1.
- `Preconditions:` lines referencing removed tasks become `none`; those
  referencing renumbered tasks use the new numbers.
- No git commit is made.

## Notes

- Test `/task-clean DONE` (explicit single status).
- Test `/task-clean DONE SKIP` (explicit multi-status — same as default).
- Test pruning `[IN PROGRESS]` — agent should warn and confirm twice.
- Verify "No tasks to prune." message when nothing matches.
