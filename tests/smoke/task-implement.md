# Smoke test: task-implement

**Type:** command
**Source:** commands/task-implement.md

## Setup

- A project with a test suite (e.g. pytest), a `.claude/TASKS.md`
  with at least one `[MISSING]` task summary block, and a matching
  `.claude/tasks/<N>.md` body file containing `## Description`,
  `### Tests`, and `### Definition of done` sections.
- Working tree must be clean (`git status` shows nothing).

## Steps

1. Invoke `/task-implement <N>` for a specific task number.
2. Observe pre-flight: agent reports task title and plan (one line per task).
3. Observe PHASE sequence: status → `[IN PROGRESS]`, tests written, tests
   fail, production code changed, tests pass, full suite passes, status →
   `[DONE]`, commit created.

## Expected

- Task status flips to `[IN PROGRESS]` in `.claude/TASKS.md` (NOT in
  the body file) before any production code changes.
- The agent reads `.claude/tasks/<N>.md` only when its task becomes
  current — body files for not-yet-started tasks should not be opened
  in the preflight step.
- New/updated tests fail before the implementation is written.
- All tests pass after implementation.
- Exactly one commit per task, named after the task. The commit
  includes the TASKS.md status flip but does NOT include the
  `.claude/tasks/<N>.md` body file unless it was genuinely modified.
- Task status is `[DONE]` in `.claude/TASKS.md` in the final commit.
- No `--no-verify` or `--amend` flags used.

## Notes

- Test `/task-implement all` to verify batch mode and progress reporting.
- Verify that a failing test stops the run without committing.
- On a project without a test suite, verify the interactive mode prompt
  appears and both options (scaffold / skip) work as described.
- **Context discipline (v0.3+ bodies, qualitative).** Run
  `/task-implement <N>` against a task whose body uses the v0.3+
  schema (contains `### Files to modify`, `### Required reading`,
  `### Conventions to follow`, `### Out of scope`). Inspect the
  agent's tool-call trace and confirm it leaned on the body's
  Required reading / Conventions / Out of scope content rather than
  bulk-reading every file under `.claude/context/` reflexively. Some
  context reads are fine — the test is qualitative ("reduced, not
  zero"), not strict. The implementation must still land and commit
  cleanly.
- **Older-body fallback.** Run `/task-implement <N>` against a body
  that lacks the v0.3+ sections (e.g. a fixture with only Description
  / Tests / Definition of done). The agent should fall back to
  consulting CLAUDE.md and the context layer normally and still
  produce a passing implementation + commit.
