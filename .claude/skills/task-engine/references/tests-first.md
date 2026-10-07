# The tests-first sequence

Authority for: the four steps that turn a specification into a verified
change — update the tests, implement, run the affected tests, run the full
suite — what each may touch, and when a failing test stops the work.

Extracted verbatim from `/task-implement`'s PER-TASK WORKFLOW Steps 2–5. The
step numbers are that skill's own labels, kept so every citation of "Step 3"
or "Step 5" still lands. The specification is whatever the run implements
against — a task body, or a spec file — and its *declared files* are the
files it names as its scope.

Steps 2, 4 and 5 are skipped in skip-tests mode (`./no-test-suite.md`) and
when the change is documentation-only; Step 3 always runs.

---

## Step 2 — Update tests

Use the Read tool to open the test files the specification declares (or
implies in its tests section). Use the Edit tool to add or modify tests to
encode the behavior the specification states — every assertion it calls for,
plus regression guards for its acceptance criteria.

If a test file doesn't exist yet but the specification expects one, use the
Write tool to create it.

Do NOT touch production code yet.

## Step 3 — Implement

Use the Read tool to open each file before editing it. Use the Edit tool to
make targeted changes; use the Write tool only when creating a new file from
scratch. Modify only the declared files plus genuine collateral (imports,
type hints, fixture updates). If you find yourself touching files not
declared, pause and explain why — surface the surprise rather than expanding
scope silently.

Follow the project's existing code style. Don't add comments, error
handling, or abstractions beyond what the specification requires.

## Step 4 — Run the affected tests, watch them pass

Run the affected tests (`./testing-policy.md` § *Affected tests*). They MUST
pass. If they don't, fix the production code (not the test) and rerun. If
after a reasonable attempt the code still doesn't pass and the spec itself
looks wrong, stop and report — do not weaken the test, and never continue
past a failing test with a "todo: fix later" comment.

## Step 5 — Run the full test suite

Run the full test suite. It MUST pass entirely. If unrelated tests fail,
the change has caused a regression — fix it before continuing. Do not
commit with red tests.

---

## Per-consumer notes

- **`/task-implement`** — runs the four steps per task, between Step 1 (mark
  `[IN PROGRESS]`) and its review rounds and Step 6. The specification is
  the task body; the declared files are the `Files:` field on its TASKS.md
  summary block. "Documentation-only" is its DOC_ONLY, set in Step 1 by
  DOCUMENTATION-ONLY TASKS.
