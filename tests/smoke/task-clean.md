# Smoke test: task-clean

**Type:** command
**Source:** commands/task-clean.md

## Setup

- A `.claude/TASKS.md` with tasks in mixed statuses including at least
  one `[DONE]` and one `[SKIP]`. Each task has a corresponding
  `.claude/tasks/<N>.md` body file. Note the current
  `Last task number` value before running.

## Steps

1. Invoke `/task-clean` (no arguments).
2. Observe the PLAN output: tasks to remove (with their body file
   paths), the explicit "Renumbering: NONE" line, and precondition
   references to update.
3. Confirm with "yes".
4. Inspect the file: pruned summary blocks gone, survivors keep their
   original task IDs, precondition references to pruned tasks dropped.
5. Inspect `.claude/tasks/`: body files for the pruned tasks are
   deleted; survivors' body files untouched.
6. Open `.claude/TASKS.md` and verify the `Last task number:` line is
   unchanged from before the run.
7. Observe that a git commit is made automatically after the apply step
   — no additional prompt or confirmation is shown.
8. Run `git log --oneline -1` and confirm the commit message follows the
   pattern `task-clean: remove tasks <N>[, <M>, …]` and that the commit
   hash was reported inline by the command.

## Expected

- No file is written or deleted during PHASE 1.
- Only `[DONE]` and `[SKIP]` tasks are removed by default.
- Surviving tasks keep their original IDs (no renumbering).
- The `Last task number:` counter is NEVER decremented, even if the
  highest-numbered task was pruned.
- `.claude/tasks/<N>.md` body files for pruned tasks are deleted.
- `Preconditions:` lines that referenced removed tasks have those
  references dropped (or become `none` if the list is now empty).
- A git commit is made automatically after PHASE 2 — no extra prompt
  or confirmation is needed.
- The commit message follows the pattern `task-clean: remove tasks …`.
- Only `.claude/TASKS.md` and the deleted body file paths are staged —
  no unrelated working-tree changes are included.

## Notes

- Test `/task-clean DONE` (explicit single status).
- Test `/task-clean DONE SKIP` (explicit multi-status — same as
  default).
- Test pruning `[IN PROGRESS]` — agent should warn and confirm twice.
- Verify "No tasks to prune." when nothing matches.
- After pruning, run `/task-add` and confirm the new task gets ID
  `Last + 1` (i.e. a fresh ID, not a recycled one).
- Verify that a pre-commit hook failure surfaces the raw error and
  leaves the files staged but uncommitted, rather than retrying or
  using `--no-verify`.
