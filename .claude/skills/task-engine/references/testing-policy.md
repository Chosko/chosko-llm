# Testing-policy resolution

Authority for: the `Testing policy for /task-implement:` marker and its three
values, and how a run that changes code establishes how the project's tests
run — the marker first, then project convention, then inference, then the
no-test-suite branch — and which tests count as affected.

Extracted verbatim from `/task-implement`'s `RESOLVING THE TEST RUNNER`. The
marker keeps its `/task-implement` wording so that every `CLAUDE.md` already
declaring it keeps working, whichever feature reads it.

---

## Resolving the test runner

The run must work on any project. Establish how tests run before doing
anything else:

0. **Testing policy marker (checked first).** Read `CLAUDE.md` if it
   exists and look for a line of the form:
   `Testing policy for /task-implement: skip-tests`,
   `Testing policy for /task-implement: full-tdd`, or
   `Testing policy for /task-implement: skip-tests-unattended`. This is a
   project's own durable declaration and overrides heuristic detection:
   - `skip-tests` → the project has stated it has no automated test
     suite. Read `./no-test-suite.md` and go straight to its skip-tests
     mode, without asking the A/B question.
   - `skip-tests-unattended` → same as `skip-tests`, plus set
     AUTO_CONFIRM = true for the whole run, so skip-tests mode's
     "Proceed?" prompt is also suppressed.
   - `full-tdd` → the project has stated it does have a test suite, even
     if no runner is auto-detectable. Never enter no-test-suite mode;
     continue at step 1 to resolve the actual test command.
   - No marker found → continue to step 1.
1. If a CLAUDE.md, README.md, or `.claude/` context file specifies a test
   command, use it. Project conventions beat heuristics. **On the common
   path this resolves the runner and you are done here.**
2. Otherwise, read `./test-runner.md` and infer the runner from the
   project's files. If it is still ambiguous after that, ask the user
   before starting any work — or, under the `unattended` policy, abort the
   run with one line naming the ambiguity: this is the one prompt with no
   default, and nothing has started that could park (`./parking.md`
   § *Prompts with a default*).
3. If the project has no test suite at all (no runner inferable AND no
   test directory like `tests/`, `test/`, `__tests__/`, `spec/`), read
   `./no-test-suite.md` and follow it. A project that has one — runner
   found OR test directory present — and carries no `skip-tests` marker
   never enters skip-tests mode: it runs in full test mode, without
   confirmations.

## Affected tests

For "affected tests", prefer running just the test file(s) the change
names. If that's not feasible, fall back to running tests by keyword/marker
matching the change's subject. The full suite is always run at the end of
each unit of work regardless.

---

## Per-consumer notes

- **`/task-implement`** — resolves it once per run, before PRE-FLIGHT. The
  `skip-tests-unattended` value sets AUTO_CONFIRM as if `-y` had been
  passed, suppressing skip-tests mode's per-task "Proceed?" prompt. The
  affected test files are those listed in the task's `Files:` field, the
  subject is the task's, and the full suite runs at the end of each task.
  The step-2 abort reads UNATTENDED.
