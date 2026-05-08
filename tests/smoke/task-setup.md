# Smoke test: task-setup

**Type:** command
**Source:** commands/task-setup.md

## Setup

- A project with no `.claude/TASKS.md`, no `.claude/tasks/` directory,
  and no `.claude/external/` directory (fully fresh state).

## Scenarios

### 1. Fresh project with a detectable test runner (pytest)

Setup: project has a `pytest.ini` (or pyproject.toml with pytest
config) and a `tests/` directory. No `.claude/` artifacts yet.

1. Invoke `/task-setup`.
2. Inspect the filesystem: `.claude/TASKS.md` exists; `.claude/tasks/`
   exists as an empty directory; `.claude/external/` contains
   `implement-prompt.md`, `tests-prompt.md`,
   `run-affected-tests.sh`, `run-full-tests.sh`.
3. Open `.claude/TASKS.md` and verify it contains the header
   `# Tasks` and the line `Last task number: 0`, and nothing else.
4. Open `.claude/external/implement-prompt.md` and verify it contains
   the role line ("You are an engineer implementing one task ..."),
   the Procedure section, the Output discipline section, and the Stop
   conditions section.
5. Open `.claude/external/tests-prompt.md` and verify it scopes the
   model to "test files only" and includes its own Stop conditions
   section.
6. Open both wrapper scripts. They should be executable and invoke
   `pytest` (e.g. `pytest "$@"` and `pytest`). Neither should contain
   the `# CHOSKO_TASK_IMPL_STUB` sentinel.

### 2. Fresh project with no detectable test runner — choose halt (A)

Setup: project has no test runner config, no `tests/` /`test/` /
`__tests__/` / `spec/` directory.

1. Invoke `/task-setup`.
2. Observe the no-test-suite prompt offering options A or B.
3. Choose **A** (halt).
4. Inspect `.claude/external/`: `implement-prompt.md` and
   `tests-prompt.md` are present, but neither wrapper script is
   written.
5. Run `chosko-llm task-impl <N>` (assuming a task exists). Observe a
   refusal pointing at `/task-setup`.

### 3. Fresh project with no detectable test runner — choose stubs (B)

1. Invoke `/task-setup`.
2. Choose **B** (skip-tests stubs).
3. Inspect `.claude/external/run-affected-tests.sh` and
   `run-full-tests.sh`. Each contains the literal sentinel comment
   `# CHOSKO_TASK_IMPL_STUB` and exits 0 with a message on stderr.
4. Both stubs are executable.

### 4. Re-running on a partially initialized project

- Delete only `.claude/tasks/` (leave everything else). Re-invoke
  `/task-setup` — only the directory is recreated.
- Delete only `.claude/TASKS.md`. Re-invoke — only the index file is
  recreated.
- Delete only `.claude/external/implement-prompt.md`. Re-invoke —
  only that file is recreated; tests-prompt and the wrappers are left
  alone.
- Delete only `.claude/external/run-affected-tests.sh`. Re-invoke —
  only that wrapper is regenerated (using whichever inference path
  the rest of the project supports).

### 5. Upgrading stubs to real wrappers

Setup: project initialized via scenario 3 (skip-tests stubs). The
user has since added a test runner (e.g. installed pytest and added a
`pytest.ini`).

1. Re-invoke `/task-setup`.
2. Observe the prompt: "The existing wrapper scripts are skip-tests
   stubs, but I now detect a pytest setup … Replace the stubs with
   real wrappers? [y/N]".
3. Answer `y`. Both wrappers are overwritten with real pytest
   wrappers; the `# CHOSKO_TASK_IMPL_STUB` sentinel is gone.
4. Re-run scenario 5 but answer `n` instead. Verify the stubs are
   left intact.

### 6. User-edited prompt files are never clobbered

1. Manually edit `.claude/external/implement-prompt.md` (e.g. add a
   custom note at the bottom). Re-invoke `/task-setup`. The edit is
   preserved.
2. Same for `.claude/external/tests-prompt.md`.

### 7. User-edited (non-stub) wrappers are never clobbered

1. Manually edit `run-full-tests.sh` to add a custom flag (so it no
   longer carries the stub sentinel — it never did). Re-invoke
   `/task-setup`. The edit is preserved; no overwrite, no prompt.

### 8. Idempotency on a fully set-up project

1. After scenario 1 succeeds, immediately re-invoke `/task-setup`.
2. Observe "Backlog already initialized" (or equivalent). No file is
   modified, no git commit is created.

## Expected (cross-cutting)

- Stub `TASKS.md` has `Last task number: 0` and no task entries.
- Both prompt files are the static templates verbatim; no
  project-specific interpolation.
- Re-invocation on a fully initialized project writes nothing.
- A user-edited prompt or non-stub wrapper is never overwritten.
- Wrapper scripts always have the executable bit set.
- No git commit is made by `/task-setup` itself.
