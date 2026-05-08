# Smoke test: task-implement

**Type:** command
**Source:** commands/task-implement.md

## Setup

- A project with a test suite (e.g. pytest) and a `.claude/TASKS.md`
  containing at least one `[MISSING]` task with `Files:` and `### Tests`
  sections.
- Working tree must be clean (`git status` shows nothing).

## Steps

1. Invoke `/task-implement <N>` for a specific task number.
2. Observe pre-flight: agent reports task title and plan (one line per task).
3. Observe PHASE sequence: status → `[IN PROGRESS]`, tests written, tests
   fail, production code changed, tests pass, full suite passes, status →
   `[DONE]`, commit created.

## Expected

- Task status flips to `[IN PROGRESS]` before any production code changes.
- New/updated tests fail before the implementation is written.
- All tests pass after implementation.
- Exactly one commit per task, named after the task.
- Task status is `[DONE]` in the final commit.
- No `--no-verify` or `--amend` flags used.

## Notes

- Test `/task-implement all` to verify batch mode and progress reporting.
- Verify that a failing test stops the run without committing.
- On a project without a test suite, verify the interactive mode prompt
  appears and both options (scaffold / skip) work as described.
