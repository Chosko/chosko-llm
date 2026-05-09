---
name: task-setup
version: 0.4.0
type: command
description: Initialize the project's task backlog — creates .claude/TASKS.md, the .claude/tasks/ directory, and the external-LLM wiring under .claude/external/ (implement-prompt, tests-prompt, run-affected-tests.sh, run-full-tests.sh), then optionally commits the newly written scaffolding.
---

# /task-setup
# Global command: initialize the project's task backlog. Creates the
# `.claude/TASKS.md` index file, the `.claude/tasks/` directory where
# per-task body files live, and the external-LLM wiring under
# `.claude/external/` — two static prompt templates plus two thin
# test-runner wrapper scripts that the `chosko-llm task-impl`
# orchestrator invokes. Idempotent: a re-run leaves existing artifacts
# untouched and only creates the missing ones.
# Usage: /task-setup

GOAL
Create the artifacts that the rest of the task-* workflow assumes:
1. `.claude/TASKS.md` — the lightweight index (one summary block per task,
   plus a counter for the highest task number ever assigned).
2. `.claude/tasks/` — the directory where each task's full body lives in
   `<N>.md` (one file per task ID).
3. `.claude/external/implement-prompt.md` — the static prompt template
   that an external LLM (target: qwen2.5-coder:14b via aider) is fed
   when implementing the production change for a task. Travels with the
   project via git so a teammate can clone-and-run.
4. `.claude/external/tests-prompt.md` — the analogous prompt for the
   test-writing pass. The orchestrator runs aider with this prompt
   first, so tests get written/extended before any production code is
   touched.
5. `.claude/external/run-affected-tests.sh` — a thin wrapper that runs
   the project's test runner against a set of test files passed on the
   command line. Inferred from project files at `/task-setup` time.
6. `.claude/external/run-full-tests.sh` — a thin wrapper that runs the
   project's full test suite. Same inference path as (5).

The orchestrator (`chosko-llm task-impl`) invokes (5) and (6) — it does
no test-runner detection of its own. Project-specific knowledge stays
in the project.

This command is the gate for `/task-add` (artifacts 1 + 2) and for
`chosko-llm task-impl` (artifacts 3 + 4 + 5 + 6). Either gate refuses to
run until its required artifacts exist.

After the artifacts are in place and reported, the command offers to
commit whatever it just wrote (PHASE — OFFER COMMIT below). The offer
is skipped entirely on a fully-idempotent re-run that wrote nothing.

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Write tool to create new files. Never use shell
  redirection, `tee`, `Set-Content`, or `Out-File`.
- Bash / PowerShell are used for two narrow purposes:
  - Filesystem prep: creating directories (`mkdir -p .claude/tasks`,
    `mkdir -p .claude/external`) and setting the executable bit on the
    wrapper scripts (`chmod +x …`).
  - The optional commit phase (PHASE — OFFER COMMIT below): exactly
    `git status --porcelain`, `git add -- <path> <path>`, and
    `git commit`. No other phases shell out.

---

WORKFLOW

Each artifact is checked individually and created only if missing.
Never overwrite an existing artifact without explicit user confirmation
— re-running `/task-setup` on a partially or fully initialized project
must be idempotent.

Throughout the run, maintain a `WRITTEN` list of paths actually written
or overwritten this invocation. Each successful Write / `mkdir -p` (when
the directory did not previously exist) appends to it; idempotent
no-ops do not. `WRITTEN` drives PHASE — OFFER COMMIT below.

1. **Probe every artifact:**
   - `.claude/TASKS.md` — use the Read tool; "file not found" means it
     does not exist.
   - `.claude/tasks/` — use Glob `.claude/tasks/*` or list it.
   - `.claude/external/implement-prompt.md` — use the Read tool.
   - `.claude/external/tests-prompt.md` — use the Read tool.
   - `.claude/external/run-affected-tests.sh` — use the Read tool.
   - `.claude/external/run-full-tests.sh` — use the Read tool.

2. **Create whichever are missing:**
   - If `.claude/TASKS.md` is missing, use the Write tool to create it
     with this exact stub content:

     ```
     # Tasks

     Last task number: 0
     ```

     No trailing task entries. The first task added will sit below this
     header.

   - If `.claude/tasks/` is missing, create it (`mkdir -p .claude/tasks`).

   - If `.claude/external/implement-prompt.md` is missing, create the
     parent directory if needed (`mkdir -p .claude/external`) then use
     the Write tool to write the template. The exact content to write is
     the literal block in the **EXTERNAL IMPLEMENT-PROMPT TEMPLATE**
     section below — write it verbatim, no edits, no project-specific
     interpolation.

   - If `.claude/external/tests-prompt.md` is missing, write the
     literal block in the **EXTERNAL TESTS-PROMPT TEMPLATE** section
     verbatim.

   - For the wrapper scripts (`run-affected-tests.sh` /
     `run-full-tests.sh`): if either is missing, run the **TEST RUNNER
     INFERENCE** procedure below. The procedure produces either a real
     wrapper pair or — when the project has no detectable test runner
     and the user chooses skip-tests mode — a no-op stub pair. Either
     way, both scripts get the executable bit set (`chmod +x`).

3. **Report to the user:**
   - For each artifact: created (with path) or already present.
   - If everything already existed, say "Backlog already initialized."
   - If anything was created, hint at usable next steps:
     - `/task-add` is usable once artifacts 1 + 2 exist.
     - `chosko-llm task-impl <N>` is usable once artifacts 3 + 4 + 5 +
       6 exist (and the wrappers are real, not stubs — or the user has
       deliberately chosen skip-tests mode).
   - If the wrapper scripts were written as no-op stubs, say so
     explicitly so the user knows skip-tests mode is in effect.

4. **Continue to PHASE — OFFER COMMIT.**

---

PHASE — OFFER COMMIT (optional, requires explicit approval)

The files just written by step 2 are a natural, self-contained commit.
This phase asks the user whether to capture them now, then either does
so or leaves them unstaged. It runs after the report step in step 3.

1. **If `WRITTEN` is empty**, skip this phase entirely — no prompt, no
   output beyond the existing report. A fully idempotent re-run that
   produced "Backlog already initialized." must not display a commit
   prompt.

2. **Otherwise, print exactly one prompt:**

   > Scaffolding written (<N> file(s)). Commit them now? [y/N]

   followed by a bulleted list of the paths in `WRITTEN`, one per line.

3. **Interpret the answer:**
   - **Explicit yes** (`y`, `yes`, `commit`, `go`): proceed to step 4.
   - **Anything else** (no, blank line, EOF, an unrelated reply,
     silence): print `Skipped commit. Files left unstaged.` and stop.
     Do not stage, do not commit. The user can commit by hand later.

4. **On yes**, stage exactly the paths in `WRITTEN` and create one
   commit:

   ```
   git add -- <path1> <path2> ...      # exactly the entries of WRITTEN
   git commit -m "Initialize task backlog scaffolding" \
              -m "$(cat <<'EOF'
   - <path1>
   - <path2>
   ...
   EOF
   )"
   ```

   Use a HEREDOC for the multi-line body, listing each `WRITTEN` path
   as a bullet. Drop the second `-m` entirely if `WRITTEN` has only
   one path — the headline alone is enough.

5. **On success**, report the resulting commit hash to the user
   (`git rev-parse --short HEAD`).

6. **On failure** (e.g. pre-commit hook rejects the commit): surface
   the exact failure output to the user. Do NOT retry, do NOT amend,
   do NOT use `--no-verify` or any hook-skipping flag. The files
   remain in whatever state git left them (typically still staged);
   tell the user that and let them decide.

This phase stages ONLY the paths in `WRITTEN`. It must not run
`git add -A`, `git add .`, `git add -u`, or anything that could pull
in unrelated dirty files from the working tree.

---

TEST RUNNER INFERENCE

Determine how this project runs its tests, then write the two wrapper
scripts. Inference uses the same heuristics as `/task-implement`'s
LOCATING THE TEST RUNNER section. In order:

1. **Project convention beats heuristics.** If a `CLAUDE.md`, `README.md`,
   or `.claude/` context file specifies a test command, use it.
2. **Infer from project files:**
   - `pytest.ini`, `pyproject.toml` with `[tool.pytest.ini_options]`, or
     `setup.cfg` with `[tool:pytest]` → `pytest`. Prefer
     `.venv/Scripts/python.exe -m pytest` on Windows or
     `.venv/bin/python -m pytest` on POSIX if a venv exists.
   - `package.json` with a `test` script → `npm test` (or `pnpm test` /
     `yarn test` if the lockfile indicates it).
   - `Cargo.toml` → `cargo test`.
   - `go.mod` → `go test ./...`.
   - `Gemfile` with rspec → `bundle exec rspec`.
   - Otherwise, scan for a `Makefile` target named `test` → `make test`.
3. If still ambiguous, ask the user before writing the wrappers.

Once the test command is known, write `run-affected-tests.sh` so it
invokes the runner against the test files passed on its command line
(e.g. `pytest "$@"`, `npm test -- "$@"`, `cargo test "$@"`, etc.), and
write `run-full-tests.sh` so it invokes the runner with no arguments
(`pytest`, `npm test`, `cargo test`, `go test ./...`, …).

**No-test-suite handling.** If no test runner can be inferred AND no
test directory (`tests/`, `test/`, `__tests__/`, `spec/`) exists, the
project has no test suite. Prompt the user once:

> This project has no detectable test suite. Two options:
>
> A. **Halt.** Don't write the wrapper scripts. Set up a test suite
>    (or have me scaffold one), then re-run `/task-setup`.
>    `chosko-llm task-impl` will refuse to run without the wrappers.
>
> B. **Skip tests.** Write no-op stub wrappers. The orchestrator
>    detects the stubs and runs in skip-tests mode: skips the
>    test-write / test-fail / test-pass / full-suite steps, requires
>    per-task confirmation, and appends `(no tests — manual
>    verification pending)` to commit messages.
>
> Which would you like?

If the user picks **A**, do not write the wrapper scripts and report
the artifacts left missing.

If the user picks **B**, write both scripts as no-op stubs that exit 0
with a clear message. The stubs MUST contain the literal sentinel
comment line:

```
# CHOSKO_TASK_IMPL_STUB
```

The orchestrator uses that sentinel to detect skip-tests mode at
runtime. Suggested stub body:

```bash
#!/usr/bin/env bash
# CHOSKO_TASK_IMPL_STUB
# Generated by /task-setup in skip-tests mode. Replace this script with
# a real test-runner invocation once the project has a test suite, then
# re-run /task-setup to regenerate.
echo "[skip-tests] no test suite configured for this project" >&2
exit 0
```

**Re-running with newly-added tests.** If the existing wrappers carry
the `# CHOSKO_TASK_IMPL_STUB` sentinel but the project now has a
detectable test runner (the user added one since the last
`/task-setup`), prompt before overwriting:

> The existing wrapper scripts are skip-tests stubs, but I now detect a
> <runner> setup in this project. Replace the stubs with real wrappers?
> [y/N]

On `y`, overwrite both stubs with the inferred real wrappers. On `n`,
leave them alone.

**Wrappers that are not stubs are never overwritten** — once the user
has a real wrapper, treat it as theirs to edit.

---

INDEX FILE FORMAT (for reference — `/task-add` and `/task-clean` are
the writers)

```
# Tasks

Last task number: <N>

---

## <N>. <Title>

Status: [MISSING]
Files: <comma-separated files>
Preconditions: <comma-separated task numbers, or "none">

---

## <M>. <Title>
...
```

The `Last task number` line tracks the highest ID ever assigned. It only
ever increases — `/task-clean` removes survivors but never decrements it.
That guarantees task numbers are stable IDs across the project's lifetime.

PER-TASK BODY FILE FORMAT (for reference — `/task-add` writes these,
`/task-implement` reads them, and an external LLM consumes them
directly via aider)

`.claude/tasks/<N>.md`:

```
# Task <N> — <Title>

## Description
<Plain prose explanation …>

### Files to modify
<Comma-separated list, identical to the `Files:` field in the task's
TASKS.md summary block. The output surface — what an implementer will
edit. Replicated here so an external LLM fed only this body file knows
what to touch.>

### Required reading
<Bulleted list of `path:line-range — why` entries the implementer
should `/add` to aider before editing.>

### Relevant snippets
<Optional. 5–30 line excerpts of central, non-obvious code, prefixed
with `path:line` origins.>

### Conventions to follow
<Bulleted list of project rules (drawn from CLAUDE.md and the relevant
context layer).>

### Out of scope
<Bulleted list of things the implementer must NOT do — explicit
guardrails.>

### Root cause
<Optional. Bugfixes when non-obvious.>

### Behavior change
<Concrete rules.>

### Doc updates
<Optional. Required when behavior changes touch a documented surface.>

### Tests
<Test files / smoke checklists and assertions.>

### Definition of done
- <Bullets.>
- Full test suite passes.
```

The per-task file is self-contained — an external LLM fed only this
file plus `.claude/external/implement-prompt.md` should have enough
context to implement. The tracking metadata that DOES NOT live in the
body is `Status:` and `Preconditions:` — those describe the task's
place in the backlog, not its implementation, and live only in
`TASKS.md`. `Files:` is intentionally duplicated as `### Files to
modify` because it's part of the implementation contract.

---

EXTERNAL IMPLEMENT-PROMPT TEMPLATE

Write this exact content (everything between the BEGIN and END markers,
not including the markers themselves) to
`.claude/external/implement-prompt.md` when the artifact is missing:

```
=== BEGIN external/implement-prompt.md ===
# Implement-prompt for external LLMs

You are an engineer implementing one task from this project's task
backlog. You are running inside aider with file-read, repo-map, and
file-edit (SEARCH/REPLACE) tools.

## Inputs

- The task body file at `.claude/tasks/<N>.md` (provided as a `--read`
  context). Sections you should expect: Description, Files to modify,
  Required reading, Relevant snippets (optional), Conventions to
  follow, Out of scope, Behavior change, Tests, Definition of done.
- The project's CLAUDE.md and any context/domain layer it cites.

## Procedure

1. Read the task body in full. Description and Behavior change tell
   you what to build; "Files to modify" is the output surface.
2. For every entry in "Required reading", `/add` the file to aider's
   context before you start editing.
3. Skim CLAUDE.md if you have not already; honor every rule under
   "Conventions to follow".
4. Implement the change one file at a time, only touching files in
   "Files to modify" (plus genuine collateral such as imports or
   fixture updates). Stop at any rule under "Out of scope".
5. Add or extend the test files / smoke checklists named under
   "Tests".
6. Verify every bullet under "Definition of done" is observable.
7. If the project has an automated test suite, run it; all tests must
   pass before you consider the task complete.

## Output discipline

- Use aider SEARCH/REPLACE diff blocks. No speculative refactors.
- Do not modify files outside "Files to modify" without explanation.
- Do not change the task body file (`.claude/tasks/<N>.md`) or
  `.claude/TASKS.md` — those are managed by `/task-add` and
  `/task-implement`, not by the implementer.

## Stop conditions

If any of the following hold, stop and report rather than proceeding:
- The task body is ambiguous on a decision you cannot defer.
- A file listed in "Required reading" is missing.
- A test that you did not introduce starts failing.
- A change you must make falls outside "Files to modify" and you
  cannot justify it as collateral.
=== END external/implement-prompt.md ===
```

---

EXTERNAL TESTS-PROMPT TEMPLATE

Write this exact content (everything between the BEGIN and END markers,
not including the markers themselves) to
`.claude/external/tests-prompt.md` when the artifact is missing:

```
=== BEGIN external/tests-prompt.md ===
# Tests-prompt for external LLMs

You are an engineer writing or extending the TEST FILES for one task
from this project's task backlog. You are running inside aider with
file-read, repo-map, and file-edit (SEARCH/REPLACE) tools.

This is the TEST-WRITING pass — it runs BEFORE any production code is
modified. A separate pass (driven by implement-prompt.md) will make the
tests pass afterward.

## Inputs

- The task body file at `.claude/tasks/<N>.md` (provided as a `--read`
  context). Sections you should expect: Description, Files to modify,
  Required reading, Relevant snippets (optional), Conventions to
  follow, Out of scope, Behavior change, Tests, Definition of done.
- The project's CLAUDE.md and any context/domain layer it cites.

## Procedure

1. Read the task body in full. The "Tests" section is the contract you
   must encode; "Definition of done" tells you which behaviors deserve
   a regression guard.
2. For every entry in "Required reading", `/add` the file to aider's
   context before editing.
3. Identify the test files among "Files to modify" — anything under
   `tests/`, `test/`, `__tests__/`, `spec/`, or matching `*_test.*` /
   `*.test.*` / `*Test.*`.
4. Add or extend ONLY those test files. Encode every assertion the
   "Tests" section names, plus the regression guards implied by
   "Definition of done".
5. Use the project's existing test style and helpers — match what is
   already in the file.

## Output discipline

- Edit ONLY test files. Do not touch production code in this pass.
- Do not weaken or remove existing tests.
- Do not modify the task body file (`.claude/tasks/<N>.md`) or
  `.claude/TASKS.md` — those are managed by `/task-add` and the
  task-impl orchestrator, not by the implementer.

## Stop conditions

If any of the following hold, stop and report rather than proceeding:
- The "Tests" section is ambiguous on a decision you cannot defer.
- A file listed in "Required reading" is missing.
- The task lists no test files at all under "Files to modify".
=== END external/tests-prompt.md ===
```

---

DO NOT:
- Create any task entries — `/task-setup` only creates the empty
  scaffolding. The first task is added by `/task-add`.
- Overwrite an existing `TASKS.md`, any `.claude/tasks/<N>.md` file,
  an existing `.claude/external/implement-prompt.md`, or an existing
  `.claude/external/tests-prompt.md`. These files may have been edited
  by the user; never clobber them.
- Overwrite a non-stub wrapper script (`run-affected-tests.sh` /
  `run-full-tests.sh`). Stubs (carrying the `# CHOSKO_TASK_IMPL_STUB`
  sentinel) may be replaced with real wrappers, but only after
  confirming with the user.
- Modify the prompt template contents per project — they are static,
  project-agnostic templates. Project-specific guidance lives in
  CLAUDE.md and the context/domain layer, which the prompts already
  tell the external LLM to consult.
- Auto-scaffold a test framework. If the project has no test suite,
  ask the user (option A vs B) — never install pytest/jest/etc. on
  your own.
- Use `git add -A`, `git add .`, or `git add -u` in the commit phase —
  only the paths in `WRITTEN` (the files this run actually created or
  overwrote) may be staged.
- Use `--amend`, `--no-verify`, `--no-gpg-sign`, or any other
  hook-skipping or commit-rewriting flag. If a pre-commit hook fails,
  surface it and let the user fix it.
- Push, branch, tag, or otherwise touch shared/visible git state.
- Commit without an explicit yes at the commit prompt. Silence is not
  approval. If `WRITTEN` is empty, do not even prompt.
