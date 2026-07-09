---
name: refactor-tests
version: 0.2.1
type: command
description: Split oversized test files into smaller, focused files — runs the test suite before and after each split to keep the baseline green. Pass --commit to commit the splits; default leaves them uncommitted.
---

# /refactor-tests
# Global command: finds test files exceeding a configurable line threshold and
# splits them into smaller, focused files. No renaming, deduplication, import
# sorting, or constants extraction — splitting only.
#
# Usage — split all oversized test files (default threshold: 300 lines):
#   /refactor-tests
#
# Usage — use a custom line threshold:
#   /refactor-tests threshold=200
#
# Usage — commit the splits when done (default leaves them uncommitted):
#   /refactor-tests --commit

$ARGUMENTS

---

GOAL

Split test files that exceed the configured line threshold into smaller,
focused files, relocating tests without altering their signatures, fixture
references, or imports. The test suite must stay green throughout.

---

ARGUMENT PARSING

Parse `$ARGUMENTS` for an optional `threshold=<N>` key-value pair
(e.g. `threshold=200`). If absent, use 300.

Also parse the optional `--commit` flag: if present, set COMMIT = true.
`--commit` and `--no-commit` are mutually exclusive — if both appear, stop
with: `--commit and --no-commit cannot be combined. Pick one.` When COMMIT
is false (the default), the run leaves its splits uncommitted, exactly as
before. Any other arguments are ignored.

---

STEP 1 — ESTABLISH A GREEN BASELINE

Detect and run the project's test suite (follow the same heuristics as
`/task-implement`: check CLAUDE.md first, then infer from project files —
pytest, npm test, cargo test, go test, etc.).

If no test suite is detectable, stop and report:
> No test suite found. `/refactor-tests` requires a runnable test suite to
> verify splits do not break anything. Set up a test suite first.

If the suite is red, stop and report:
> Baseline is red — fix the failing tests before running `/refactor-tests`.
> Output: <test runner output>

Do NOT proceed until a green baseline is confirmed.

---

STEP 2 — SCAN FOR OVERSIZED TEST FILES

Scan the repository for test files exceeding the threshold (from STEP 1's
argument parsing). A "test file" is any file whose name matches common
test-file patterns for the detected language (e.g. `test_*.py`, `*_test.py`,
`*.test.js`, `*.spec.ts`, files under `tests/`, `test/`, `__tests__/`,
`spec/`).

For each candidate, record its path and exact line count.

If no files exceed the threshold, report:
> Nothing to split — no test files exceed <threshold> lines. Exiting cleanly.

and stop.

---

STEP 3 — PROPOSE AND CONFIRM

Present the list of oversized files in a table:

```
File                          Lines
------------------------------  -----
tests/test_auth.py              512
tests/test_orders.py            387
```

Then ask:
> Proceed with splitting these <N> file(s)? [y/N]

Wait for explicit confirmation. If the user answers anything other than
`y` or `yes` (case-insensitive), stop without modifying any file.

---

STEP 4 — SPLIT, ONE FILE AT A TIME

For each confirmed file, in the order listed:

1. **Plan the split.** Identify natural responsibility boundaries within
   the file (e.g. a large test file covering authentication AND billing
   can split into `test_auth.py` and `test_billing.py`). Aim for files
   under the threshold after the split. Do NOT create more than the
   minimum number of new files needed to bring all fragments under the
   threshold.

2. **Relocate tests.** Move test functions / test classes into the new
   file(s). Preserve every signature, fixture reference, import, and
   parametrize decorator exactly as written — this is a pure relocation.
   Update imports in the new files to match what was in the original.

3. **Remove relocated tests from the original.** If all tests in the
   original have been relocated, delete the original file entirely. If
   some tests remain below the threshold, keep the trimmed original.

4. **Run the test suite.** If the suite is red, stop immediately and
   report:
   > Split of <filename> produced a red suite — stopping. No further
   > files will be touched.
   > Output: <test runner output>
   
   Do NOT proceed to the next file. Leave the repo in whatever state the
   split produced — the user must review and decide how to proceed.

5. **Report the split.** Print a one-line summary:
   > Split <original> → <new-file-1> (<N> tests), <new-file-2> (<M> tests)

---

STEP 5 — FINAL REPORT

After all files are processed (or after a stop), print:

```
/refactor-tests complete
  Files split:   N
  Files skipped: 0  (already under threshold after earlier splits)
  Suite status:  green
```

If the run stopped early due to a red suite, replace "Suite status: green"
with "Suite status: RED — stopped at <filename>".

---

STEP 6 — COMMIT (only when `--commit` was passed)

If COMMIT is false (the default), do nothing here — the splits are left
uncommitted for the user to review. This is the default behavior and is
unchanged.

If COMMIT is true:

1. If no files were split (STEP 2 found nothing, or the user declined at
   STEP 3), make no commit. Say so and stop.
2. If the run STOPPED EARLY on a red suite, make NO commit — the repo is
   in a half-split state the user must review. Say so and stop.
3. Otherwise, after a green final suite, stage EXACTLY the test files this
   run touched — every new file created, every trimmed original, and
   (using `git add -- <path>`, which also records deletions) every
   original that was deleted. Build the path list explicitly from the
   per-split reports; never use a catch-all (`git add -A` / `git add .` /
   `git add -u`).
4. Commit once: `git commit -m "Split oversized test files"`.
5. On success, report the commit hash (`git rev-parse --short HEAD`).
6. On failure (e.g. a pre-commit hook rejects the commit): surface the
   exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.

---

INVARIANTS

- Tests are relocated verbatim. No signature changes, no logic changes.
- A split that produces a red suite halts the entire run.
- The command never touches non-test files.
- The command never performs renaming, deduplication, import sorting, or
  constants extraction — those concerns belong to `/refactor-codebase`.
