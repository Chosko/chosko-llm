# No-test-suite mode

Read this when the project has no test suite at all (no test runner
detectable AND no test directory like `tests/`, `test/`, `__tests__/`,
`spec/`), or when CLAUDE.md declares a `skip-tests` testing policy. The
strict TDD flow cannot run; switch to interactive mode.

0. **If `CLAUDE.md` carries `Testing policy for /task-implement:
   skip-tests`** (see RESOLVING THE TEST RUNNER step 0), skip step 1's A/B
   question entirely. Tell the user once, briefly: "This project's
   CLAUDE.md declares a skip-tests testing policy — implementing without
   tests." Go straight to step 3 (skip-tests mode).

1. Otherwise, tell the user once, up front:

   > This project has no detectable test suite. Without tests, I can't
   > follow the TDD sequence (write failing test → implement → watch it
   > pass). Two options:
   >
   > A. **Set up a test suite now.** I can scaffold one for the project's
   >    language (e.g. pytest for Python, Jest for JS) — installing the
   >    dev dependency, adding a config, and creating a `tests/` directory.
   >    From then on, /task-implement runs in full TDD mode.
   >
   > B. **Skip test phases.** I'll implement each task without writing or
   >    running tests. Each task still gets its own commit, but I'll ask
   >    you to confirm before starting each one — without tests, I can't
   >    self-verify the implementation, so a human review point is
   >    important.
   >
   > Which would you like?

   Suggest option A only when scaffolding is genuinely straightforward for
   the language at hand. If the project's language has no obvious default
   test framework, mention that and let the user direct.

2. Do as the user tells. If they pick A, scaffold the suite first (in its
   own commit, separate from any task), then proceed in full TDD mode.
   If they pick B, proceed in skip-tests mode.

3. **Skip-tests mode** for the rest of the run:
   - Before each task, briefly summarize what you're about to change and
     ask "Proceed?" Wait for explicit approval before editing any file.
   - Skip Steps 2, 3, 5, and 6 of the per-task workflow (anything
     test-related). Steps 1, 4, 7, 8 still run.
   - The commit message should note "(no tests — manual verification
     pending)" in the body so it's visible later.
   - The `all` argument still works in skip-tests mode but the per-task
     confirmation prompts still apply (one per task).

Never auto-scaffold a test suite without the user explicitly choosing
option A.
