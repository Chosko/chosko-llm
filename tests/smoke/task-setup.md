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

## PHASE — OFFER COMMIT scenarios

These scenarios mirror the four canonical commit-prompt cases from
`tests/smoke/task-add.md`, plus two cases specific to `/task-setup`'s
idempotent re-run behavior.

### 9. Commit-yes on fresh init

1. Run `/task-setup` on a fresh project (per scenario 1).
2. After the report step, observe the prompt:
   `Scaffolding written (<N> file(s)). Commit them now? [y/N]` followed
   by a bullet list of the paths just written.
3. Answer `y`.
4. Verify a single new commit exists with headline
   `Initialize task backlog scaffolding`.
5. Run `git show --stat HEAD` and verify it lists exactly the files
   `/task-setup` wrote — no others.
6. Verify `git status` is clean.

### 10. Commit-no on fresh init

1. Run `/task-setup` on a fresh project.
2. At the commit prompt, answer `n` (or just press enter).
3. Verify all scaffolding files are written to disk but unstaged
   (`git status` shows them as untracked / modified).
4. No new commit appears in `git log`.
5. The agent reports `Skipped commit. Files left unstaged.`

### 11. Dirty-tree safety

1. Pre-create an unrelated modified file in the working tree (e.g.
   `echo "junk" >> README.md`). Do NOT stage it.
2. Run `/task-setup` end-to-end and answer `y` at the commit prompt.
3. Verify the new commit lists ONLY the files `/task-setup` wrote —
   the dirty `README.md` change is still in the working tree,
   unstaged, untouched.

### 12. Pre-commit hook failure

1. Install a pre-commit hook that always exits non-zero (e.g. a
   `.git/hooks/pre-commit` that runs `exit 1`).
2. Run `/task-setup` end-to-end and answer `y` at the commit prompt.
3. Verify the commit fails. The agent surfaces the hook output.
4. Verify the agent does NOT retry, does NOT use `--no-verify`, and
   does NOT amend any prior commit.
5. Verify the scaffolding files remain on disk; the user is told and
   left to fix the hook.

### 13. Idempotent re-run skips the prompt

1. Re-run `/task-setup` on the fully initialized project from
   scenario 8.
2. Verify NO commit prompt appears at all — the command exits after
   `Backlog already initialized.`
3. Verify `git status` is unchanged from before the re-run.

### 14. Partial re-run prompts only for the regenerated file(s)

1. Starting from a fully initialized project, delete only
   `.claude/TASKS.md` and commit the deletion (or leave it dirty —
   the test is about what `/task-setup` stages).
2. Re-run `/task-setup`.
3. Observe the commit prompt advertising exactly one file written:
   `.claude/TASKS.md`.
4. Answer `y`.
5. Verify the resulting commit contains ONLY `.claude/TASKS.md` —
   no other artifacts (which were not regenerated this run) appear
   in `git show --stat HEAD`.

## Expected (cross-cutting)

- Stub `TASKS.md` has `Last task number: 0` and no task entries.
- Both prompt files are the static templates verbatim; no
  project-specific interpolation.
- Re-invocation on a fully initialized project writes nothing AND
  does not prompt for a commit.
- A user-edited prompt or non-stub wrapper is never overwritten.
- Wrapper scripts always have the executable bit set.
- `/task-setup` never commits without explicit user approval at the
  commit prompt; silence/EOF is treated as `n`.
- The commit (when approved) stages ONLY the files `/task-setup`
  wrote during the run — never `git add -A`/`-u`/`.`.
