# Smoke test: refactor-codebase

**Type:** command
**Source:** commands/refactor-codebase.md

## Setup

- A project with a green test suite (the command refuses to run if the
  baseline is red or absent).
- Working tree clean (`git status` shows nothing) so the resulting diff
  is purely the refactor.
- At least one source file with extractable hardcoded vocabulary OR over
  300 lines OR visible duplication, so the command has something to do.

## Steps

1. Invoke `/refactor-codebase` with no arguments.
2. Observe PREPARATION: agent runs the test suite, reads
   `.claude/context/INDEX.md` (if present), and produces a written plan
   with risk grades. Agent STOPS and waits for approval.
3. Reject the plan with a small revision request; observe the agent
   re-reports a revised plan instead of writing code.
4. Approve the plan. Observe Phase 1 → Phase 5 in order, with a test-suite
   run between phases.
5. Re-run with `/refactor-codebase scope=<name> focus=constants` and
   observe that only files matching the scope are read and only Phase 1
   executes.

## Expected

- No code is written before user approval of the plan.
- HIGH-risk items are flagged separately at the end of the plan.
- The test suite is run at the start, between every phase, and at the end.
- A red suite at any gate halts further phases.
- Phase 3 splits run one file at a time, each followed by a test run.
- Phase 5 updates `.claude/context/` files whose covered source changed;
  domain files under `.claude/domain/` are NOT modified.
- FINAL REPORT lists files modified/created/deleted, before/after line
  counts for files that changed >20%, and any deferred HIGH-risk items.
- `scope=` matches basenames without path/extension (e.g. `main` →
  `src/main.py`).
- `focus=` restricts which phases execute; omitted concerns are skipped.

## Frontmatter check

- `commands/refactor-codebase.md` has `name: refactor-codebase`,
  `version` set, `type: command`, and a `description`.
- After running `chosko-llm update` in a managed clone,
  `chosko-llm ls --available` lists `refactor-codebase` with the correct
  version.
