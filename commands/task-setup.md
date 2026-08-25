---
name: task-setup
version: 2.0.0
type: command
description: Initialize the project's task backlog — creates .claude/TASKS.md, the .claude/tasks/ directory, and the project's test-dispatch convention under .claude/external/ (run-affected-tests.sh, run-full-tests.sh). Authoring command — leaves everything uncommitted for review by default; pass --commit to commit (and push) the scaffolding, or --commit --no-push to commit without pushing.
---

# /task-setup
# Global command: initialize the project's task backlog. Creates the
# `.claude/TASKS.md` index file, the `.claude/tasks/` directory where
# per-task body files live, and the project's test-dispatch convention
# under `.claude/external/` — two thin test-runner wrapper scripts that
# give the project one stable way to run its affected and full test
# suites. Idempotent: a re-run leaves existing artifacts untouched and
# only creates the missing ones.
# Usage: /task-setup                     (leaves the scaffolding uncommitted)
# Usage: /task-setup --commit            (commit and push the scaffolding this run wrote)
# Usage: /task-setup --commit --no-push  (commit locally, skip the push)

GOAL
Create the artifacts that the rest of the task-* workflow assumes:
1. `.claude/TASKS.md` — the lightweight index (one summary block per task,
   plus a counter for the highest task number ever assigned).
2. `.claude/tasks/` — the directory where each task's full body lives in
   `<N>.md` (one file per task ID).
3. `.claude/external/run-affected-tests.sh` — a thin wrapper that runs
   the project's test runner against a set of test files passed on the
   command line. Inferred from project files at `/task-setup` time.
4. `.claude/external/run-full-tests.sh` — a thin wrapper that runs the
   project's full test suite. Same inference path as (3).

Artifacts 3 and 4 are the project's **test-dispatch convention**: one
stable pair of entry points for running its affected and full test
suites, so project-specific runner knowledge stays in the project
instead of being re-derived by whatever tool needs it. They travel with
the project via git. Nothing in the `task-*` suite invokes them
automatically — `/task-implement` resolves the test command itself and
never reads them — but a project that wires its own scripts, CI or
CLAUDE.md to them has one place to change when the runner changes.

This command is the gate for `/task-add` (artifacts 1 + 2), which
refuses to run until those exist.

By default this is a pure authoring command: it writes the scaffolding and
leaves everything uncommitted in the working tree, matching `/context-build`
and the other authoring commands. The user reviews and commits when ready.
Passing `--commit` opts in to committing exactly what this run wrote, then
pushing per docs/authoring-guide.md's commit-and-push protocol (see
PHASE — COMMIT below); `--commit --no-push` commits without pushing.

This command shells out for exactly two things: filesystem prep (`mkdir -p`
for `.claude/tasks` and `.claude/external`, `chmod +x` on the wrapper
scripts) and, ONLY when `--commit` is passed, the pull/commit/push
sequence. Without `--commit`, it runs NO git/VCS command.

---

WORKFLOW

Before anything else, parse $ARGUMENTS for the optional `--commit` flag.
If present, set COMMIT = true. When COMMIT is false (the default), the run
leaves its scaffolding uncommitted.

Also parse the optional `--no-push` flag; if present, set NO_PUSH = true.
NO_PUSH only matters when COMMIT is true: it skips the pull-at-start /
re-sync / push steps of the commit-and-push protocol
(docs/authoring-guide.md) while still committing as always. When COMMIT is
false, there is nothing to push regardless of NO_PUSH.

If COMMIT is true and the project's CLAUDE.md does not carry a `## VCS`
override (non-git), pull at start per the commit-and-push protocol: run
`git pull` on the current branch before any artifact is checked. A conflict
stops the run here — report the conflict output and tell the user to
resolve manually and re-run.

Each artifact is checked individually and created only if missing.
Never overwrite an existing artifact without explicit user confirmation
— re-running `/task-setup` on a partially or fully initialized project
must be idempotent.

Throughout the run, maintain a `WRITTEN` list of paths actually written
or overwritten this invocation. Each successful Write / `mkdir -p` (when
the directory did not previously exist) appends to it; idempotent
no-ops do not. `WRITTEN` drives the final report in step 3 and the
optional commit in PHASE — COMMIT.

1. **Probe every artifact:**
   - `.claude/TASKS.md` — use the Read tool; "file not found" means it
     does not exist.
   - `.claude/tasks/` — use Glob `.claude/tasks/*` or list it.
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

   - For the wrapper scripts (`run-affected-tests.sh` /
     `run-full-tests.sh`): if either is missing, create the parent
     directory if needed (`mkdir -p .claude/external`) then run the
     **TEST RUNNER INFERENCE** procedure below. The procedure produces
     either a real wrapper pair or — when the project has no detectable
     test runner and the user chooses skip-tests mode — a no-op stub
     pair. Either way, both scripts get the executable bit set
     (`chmod +x`).

3. **Report to the user:**
   - For each artifact: created (with path) or already present.
   - If everything already existed, say "Backlog already initialized."
   - If anything was created, hint at usable next steps:
     - `/task-add` is usable once artifacts 1 + 2 exist.
     - The test-dispatch wrappers (artifacts 3 + 4) are usable directly
       once written, unless they are no-op stubs.
   - If the wrapper scripts were written as no-op stubs, say so
     explicitly so the user knows skip-tests mode is in effect.
   - If `WRITTEN` is non-empty and `--commit` was NOT passed, close with an
     explicit reminder that nothing was committed — the scaffolding is left
     in the working tree for the user to review and commit when ready.

4. **Continue to PHASE — COMMIT.**

---

PHASE — COMMIT AND PUSH (only when `--commit` was passed)

If COMMIT is false (the default), do nothing here — the scaffolding is
left uncommitted. This is the default behavior and is unchanged.

If COMMIT is true:

1. If `WRITTEN` is empty (a fully idempotent re-run that wrote nothing),
   make no commit (and no push). Say so and stop — no empty commit.
2. Otherwise, stage EXACTLY the paths in `WRITTEN` and commit them:

   ```
   git add -- <path1> <path2> ...      # exactly the entries of WRITTEN
   git commit -m "Initialize task backlog scaffolding"
   ```

   Stage ONLY the entries of `WRITTEN`. Never use `git add -A`,
   `git add .`, or `git add -u`.
3. On commit success, report the commit hash (`git rev-parse --short HEAD`).
   Then, unless NO_PUSH is true or this project's CLAUDE.md carries a
   `## VCS` override, re-sync (`git pull`) and `git push` per
   docs/authoring-guide.md's commit-and-push protocol.
4. On commit failure (e.g. a pre-commit hook rejects the commit): surface
   the exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.
5. On push failure (rejected, no upstream, no remote) or a pre-push
   conflict: surface the exact output. Never retry, never force-push. The
   commit exists locally; tell the user it needs a manual sync + push.

---

TEST RUNNER INFERENCE

> **MIRRORED COPY** — the runner-inference heuristics below are duplicated in
> `skills/task-implement/test-runner.md`. Any edit here must be mirrored
> there.

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
>
> B. **Skip tests.** Write no-op stub wrappers that exit 0, so anything
>    wired to the test-dispatch convention keeps working while the
>    project has no suite.
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

The sentinel is what marks a wrapper as a stub rather than a real
dispatcher — this command's own re-run check below reads it, and
downstream projects already carry it on disk. Suggested stub body:

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
Feature: <slug>          ← optional; only on feature-derived tasks

---

## <M>. <Title>
...
```

The `Last task number` line tracks the highest ID ever assigned. It only
ever increases — `/task-clean` removes survivors but never decrements it.
That guarantees task numbers are stable IDs across the project's lifetime.

The `Feature:` line is optional and appears ONLY on tasks generated from a
feature document by `/task-add feature=<slug>`. Free-form tasks carry no
`Feature:` line at all — its absence is how the two are told apart.

PER-TASK BODY FILE FORMAT (for reference — `/task-add` writes these and
`/task-implement` reads them)

`.claude/tasks/<N>.md`:

```
# Task <N> — <Title>

Target: claude

## Goal
<One paragraph: what and why.>

## Acceptance criteria
- <Verifiable outcome.>
- <…>

## Decisions
<Only present when non-obvious choices were made during authoring — by
the user or by Claude. Each bullet: the choice and a brief why. Omit
the section entirely when no contested calls exist; its absence is
meaningful.>

## Manual interventions
<Only present when Target is claude+human or human — numbered
checkpoints an agent must pause at for a human to perform in an
external tool, each ending in a verifiable outcome. See
commands/task-add.md's TARGET VALUES & MANUAL INTERVENTIONS section.>

## Hints
<Required. Always present. File paths the implementer should touch:
edit targets, test files, documentation, collateral files. Write
"none" explicitly only when nothing collateral genuinely exists.>
- <path/to/file>
- <…>
```

See commands/task-add.md for the full schema, including `--short` mode's
reduced Goal-only body.

The tracking metadata that DOES NOT live in the
body is `Status:`, `Preconditions:`, and `Feature:` — those describe
the task's place in the backlog, not its implementation, and live only
in `TASKS.md`. `Files:` is intentionally duplicated inside `## Hints`
because it's part of the implementation contract.

---

DO NOT:
- Create any task entries — `/task-setup` only creates the empty
  scaffolding. The first task is added by `/task-add`.
- Overwrite an existing `TASKS.md` or any `.claude/tasks/<N>.md` file.
  These files may have been edited by the user; never clobber them.
- Overwrite a non-stub wrapper script (`run-affected-tests.sh` /
  `run-full-tests.sh`). Stubs (carrying the `# CHOSKO_TASK_IMPL_STUB`
  sentinel) may be replaced with real wrappers, but only after
  confirming with the user.
- Auto-scaffold a test framework. If the project has no test suite,
  ask the user (option A vs B) — never install pytest/jest/etc. on
  your own.
- Run any git/VCS command UNLESS `--commit` was passed. By default
  `/task-setup` writes scaffolding and leaves everything uncommitted —
  committing is the user's job. With `--commit`, make exactly one commit
  of the `WRITTEN` paths, then push per the commit-and-push protocol unless
  `--no-push` was passed; never force-push, retry a failed push, branch,
  tag, or use hook-skipping flags, and never stage with a catch-all
  (`git add -A`/`.`/`-u`).
