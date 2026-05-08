# Smoke test: task-add

**Type:** command
**Source:** commands/task-add.md

## Setup

- A project with no `.claude/TASKS.md` (to test creation), or one with
  existing tasks (to test append and renumbering).

## Steps

1. Invoke `/task-add fix the login redirect to preserve the return URL`.
2. Observe the READ phase: agent reports what it's reading (one line).
3. If questions arise (PHASE 2), answer them.
4. Observe the PLAN output: backlog path, proposed number, full draft entry.
5. Confirm with "yes".
6. Observe the WRITE report: task number, file path, any renumbering.

## Expected

- No file is written until explicit approval.
- New task has `Status: [MISSING]` and correct frontmatter sections.
- If backlog didn't exist, `.claude/TASKS.md` is created.
- If inserted mid-list, subsequent task numbers and `Preconditions:` lines
  are updated.
- No git commit is made.

## Notes

- Test the "no questions" fast path by providing a very specific description.
- Test mid-list insertion by specifying a position before the last task.
- Verify silence is not treated as approval (the agent should wait).
