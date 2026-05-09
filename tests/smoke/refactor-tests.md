# Smoke test: refactor-tests

**Type:** command
**Source:** commands/refactor-tests.md

## Setup

- A project with a runnable test suite (any language with a detectable runner).
- Working tree clean (`git status` shows nothing) so the diff is purely the splits.

---

## Scenario A — green baseline, at least one oversized test file

### Setup
- Ensure at least one test file exceeds 300 lines (or use `threshold=<N>` with
  a lower value to match a shorter file during testing).
- Confirm the test suite passes before invoking.

### Steps

1. Invoke `/refactor-tests`.
2. Observe STEP 1: agent runs the test suite and confirms a green baseline.
3. Observe STEP 2: agent scans for test files over 300 lines.
4. Observe STEP 3: agent displays a table of oversized files with line counts
   and asks for confirmation.
5. Respond `y` to confirm.
6. Observe STEP 4: agent splits each file one at a time, running the test suite
   after each split.
7. Observe STEP 5: final report is printed.

### Expected

- The proposal table shows each oversized file with its line count.
- No files are modified before the user confirms in STEP 3.
- Each split relocates test functions/classes verbatim (signatures and fixture
  references unchanged).
- The test suite is run after each individual split.
- The final report lists files split and confirms suite status: green.
- No non-test files are touched.

---

## Scenario B — red baseline

### Setup
- Introduce a deliberately failing test (or break an existing one) before
  invoking.

### Steps

1. Invoke `/refactor-tests`.
2. Observe STEP 1: agent runs the test suite and gets a red result.

### Expected

- The command stops immediately after the baseline run.
- The agent reports the red baseline and includes the failing test output.
- No files are scanned, proposed, or modified.

---

## Scenario C — no oversized test files

### Setup
- Ensure all test files are under 300 lines (or invoke with
  `threshold=10000` to guarantee no file matches).

### Steps

1. Invoke `/refactor-tests threshold=10000`.
2. Observe STEP 2: agent scans and finds no oversized test files.

### Expected

- The agent reports "Nothing to split — no test files exceed 10000 lines.
  Exiting cleanly."
- No confirmation prompt is shown.
- No files are modified.

---

## Frontmatter check

- `commands/refactor-tests.md` has `name: refactor-tests`, `version: 0.1.0`,
  `type: command`, and a one-line `description`.
- After running `chosko-llm update` in a managed clone,
  `chosko-llm ls --available` lists `refactor-tests  command  —  0.1.0`.

## Notes

- Verify that the `threshold=` argument is respected: use `threshold=50` on a
  project with medium-sized test files to confirm smaller files are included in
  the scan.
- Confirm the command never touches production source files, only test files.
- Check that a mid-run red suite (after a split) halts the run and leaves the
  partially split state in place for manual review.
