# Smoke test: task-implement

**Type:** command
**Source:** commands/task-implement.md

## Setup

- A project with a test suite (e.g. pytest), a `.claude/TASKS.md`
  with at least one `[MISSING]` task summary block, and a matching
  `.claude/tasks/<N>.md` body file containing `## Description`,
  `### Tests`, and `### Definition of done` sections.
- Working tree must be clean (`git status` shows nothing).

## Steps

1. Invoke `/task-implement <N>` for a specific task number.
2. Observe pre-flight: agent reports task title and plan (one line per task).
3. Observe PHASE sequence: status → `[IN PROGRESS]`, tests written, tests
   fail, production code changed, tests pass, full suite passes, status →
   `[DONE]`, commit created.

## Expected

- Task status flips to `[IN PROGRESS]` in `.claude/TASKS.md` (NOT in
  the body file) before any production code changes.
- The agent reads `.claude/tasks/<N>.md` only when its task becomes
  current — body files for not-yet-started tasks should not be opened
  in the preflight step.
- New/updated tests fail before the implementation is written.
- All tests pass after implementation.
- Exactly one commit per task (default, no `--no-commit`), named after the
  task. The commit includes the TASKS.md status flip but does NOT include the
  `.claude/tasks/<N>.md` body file unless it was genuinely modified.
- Task status is `[DONE]` in `.claude/TASKS.md` in the final commit.
- No `--no-verify` or `--amend` flags used.
- With `--no-commit`, the full TDD sequence runs and statuses still flip to
  `[DONE]`, but NO per-task commit is made — every task's changes accumulate
  uncommitted in the working tree, and the run ends reminding the user.

## Dirty-tree (4-way prompt) scenarios

### Clean tree (regression)

1. Working tree is clean. Run `/task-implement <N>`.
2. No dirty-tree prompt fires; the normal flow runs end to end.

### Dirty tree → proceed, leave uncommitted

1. Modify a tracked file unrelated to task `<N>` (do not stage).
2. Run `/task-implement <N>`. Observe the 4-way prompt listing the
   dirty file. Answer `1` (proceed).
3. No warning is printed (nothing will be folded).
4. After Step 8, `git show --stat HEAD` includes ONLY the task's own
   files. `git status --porcelain` still shows the unrelated file dirty,
   untouched, exactly as before the run.

### Dirty tree → proceed, commit together

1. Modify a tracked file unrelated to task `<N>`. Do not stage.
2. Run `/task-implement <N>`. Answer `2` (include).
3. If the porcelain output included untracked files, expect
   `Also fold untracked files into the task's commit? [y/N]` — answer
   `n` for this scenario (no untracked files needed).
4. Observe a one-line warning that Step 8 will stage these pre-existing
   changes together with the task's own changes.
5. After Step 8, `git show --stat HEAD` includes BOTH the task's files
   AND the unrelated dirty file in the same commit. `git status` is
   clean afterward.

### Dirty tree → proceed, commit together (with untracked)

1. Modify a tracked file AND create a new untracked file (both
   unrelated to task `<N>`).
2. Run `/task-implement <N>`. Answer `2` (include). When asked
   `Also fold untracked files into the task's commit? [y/N]`, answer `y`.
3. After Step 8, `git show --stat HEAD` includes the task's files, the
   tracked dirty file, AND the untracked file (now tracked) — all in
   the one task commit.

### Dirty tree → commit first (tracked only)

1. Modify a tracked file unrelated to task `<N>`. Do not stage.
2. Run `/task-implement <N>`. Answer `3` (commit).
3. Supply a commit message at the prompt. If asked about untracked,
   answer `n`.
4. Verify ONE pre-task commit appears with that message and only the
   tracked dirty file. Then the task runs and produces its OWN
   separate commit (`Task <N>: …`).

### Dirty tree → commit first (with untracked)

1. Modify a tracked file AND create a new untracked file (both
   unrelated to task `<N>`).
2. Run `/task-implement <N>`. Answer `3` (commit). Supply a message.
   When asked about untracked, answer `y`.
3. Verify the pre-task commit contains both the tracked-modified
   file and the untracked file (now tracked). The task's own commit
   follows separately.

### Dirty tree → abort

1. Modify a tracked file. Run `/task-implement <N>` and answer `4`
   (abort).
2. Verify no `Status:` flip happened in `.claude/TASKS.md`, no
   commit was made, and the dirty file is left exactly as-is.
3. Repeat with silence / EOF instead of `4` — same outcome.

### Pre-commit hook failure on commit-first

1. Install a pre-commit hook that exits non-zero.
2. With a tracked file dirty, run `/task-implement <N>` and answer
   `3` (commit). Supply a message.
3. Verify the commit fails. The agent surfaces the hook output, does
   NOT retry, does NOT use `--no-verify`, does NOT amend.
4. Verify the run halts before any task work begins —
   `.claude/TASKS.md` is unchanged, no task commit appears.

### Between-tasks dirty

1. Run `/task-implement <N> <M>` for two consecutive tasks. Contrive
   a scenario where the working tree is dirty between tasks (e.g. a
   file written by Step 4 of `<N>` was deliberately not staged at
   Step 8 — adjust the spec or simulate by hand).
2. Observe the same 4-way prompt fires before task `<M>` starts, and
   that choosing "include" here only folds into task `<M>`'s commit
   (task `<N>`'s commit is already made and unaffected).

## `--no-commit` mode

1. On a clean tree, run `/task-implement <N> <M> --no-commit` for two tasks.
2. Observe each task runs the full TDD sequence and its status flips to
   `[DONE]`, but Step 8 makes NO commit.
3. Critically: the between-tasks dirty-tree prompt does NOT fire before task
   `<M>` — the accumulating uncommitted changes from `<N>` are expected.
4. After the run, `git log` has no new commits and `git status` shows all
   tasks' changes (including the `[DONE]` flips) uncommitted. The final
   report reminds the user nothing was committed.
5. Run `/task-implement <N> --commit --no-commit`: the command stops with
   "`--commit and --no-commit cannot be combined. Pick one.`" and does
   nothing.
6. Modify a tracked file, then run `/task-implement <N> --no-commit`.
   Observe the dirty-tree prompt is 3-way (no "include" option — there's
   no task commit to fold into): `[1] proceed`, `[2] commit`,
   `[3] abort`.

## `next` — first eligible task

1. Set up a backlog where tasks 1 and 2 are `[DONE]`, task 3 is
   `[MISSING]`, and task 4 is `[MISSING]`. Working tree must be clean.
2. Run `/task-implement next`.
3. Observe the agent reports "Next eligible task: 3 — <title>" and
   implements only task 3 — not task 4.
4. Verify exactly one commit for task 3. Task 4 status is unchanged.

## Testing policy marker

### `skip-tests` marker

1. Use a project with no automated test runner and add
   `Testing policy for /task-implement: skip-tests` to its `CLAUDE.md`.
2. Run `/task-implement <N>` for an eligible task.
3. Observe the agent does NOT ask the A/B (scaffold vs. skip) question —
   it prints a brief note that CLAUDE.md declares a skip-tests policy and
   goes straight into skip-tests mode.
4. Observe the per-task "Proceed?" confirmation still fires before the
   task starts, exactly as regular skip-tests mode does.

### `full-tdd` marker

1. Use a project with an actual test runner (e.g. pytest) but no `tests/`
   directory name the heuristic recognizes, and add
   `Testing policy for /task-implement: full-tdd` to its `CLAUDE.md`.
2. Run `/task-implement <N>`.
3. Observe NO-TEST-SUITE MODE is skipped entirely — no A/B question — and
   the run proceeds to LOCATING THE TEST RUNNER to resolve the actual
   test command (asking the user only if that command itself is
   ambiguous).

### No marker (regression)

1. On a project whose `CLAUDE.md` has no `Testing policy for
   /task-implement:` line, run `/task-implement <N>` with no detectable
   test suite.
2. Verify the original A/B prompt still fires, unchanged from before this
   marker existed.

### `next` — nothing eligible

1. Set up a backlog where all tasks are `[DONE]`, `[SKIP]`, or
   `[IN PROGRESS]`.
2. Run `/task-implement next`.
3. Observe the message "No eligible tasks found — all tasks are DONE,
   SKIP, or IN PROGRESS." and that no commit was made and no status
   line changed.

---

## `target: local` warning

1. Create or edit a task body so its second line reads `Target: local`.
2. Run `/task-implement <N>` for that task.
3. Observe a one-line note: "this task was written for a local LLM
   (Target: local) — implementing with Claude anyway."
4. Verify implementation proceeds normally — no confirmation prompt,
   no blocking.
5. Verify the note does NOT appear for a task with `Target: claude` or
   no `Target:` line.

---

## Human-in-the-loop: `target: claude+human` checkpoints

1. Author a task with `Target: claude+human` and a `## Manual
   interventions` section containing at least two checkpoints with
   filesystem-verifiable outcomes (e.g. "create a prefab named Foo" →
   `Assets/.../Foo.prefab` must exist).
2. Run `/task-implement <N>`. Observe Step 1 announces all checkpoints
   up front (one line each).
3. When implementation reaches the first checkpoint's trigger point,
   observe the run pauses and walks the user through the manual step
   with concrete, current paths/names — it does not continue on its own.
4. Confirm having done the step WITHOUT actually doing it. Observe
   Claude verifies independently, reports exactly what is missing
   (e.g. the promised file does not exist), and re-guides — it does NOT
   proceed on the user's word alone.
5. Actually perform the step and confirm. Observe verification passes
   and implementation continues to the next checkpoint / the rest of
   the flow.
6. Verify an explicit user override ("skip the check, move on") lets the
   run continue past a failed verification, and the final report records
   the override.
7. Run `/task-implement all` (or `next`) with a `claude+human` task in
   the resolved list. Observe the resolution report warns that those
   tasks need the user present.

### Inconsistent body guard

8. Author a body with `Target: claude+human` but NO `## Manual
   interventions` section. Run `/task-implement <N>` and verify the run
   stops with a clear inconsistency report instead of implementing.

## Human-in-the-loop: `target: human` guided walkthrough

1. Author a task with `Target: human` and a `## Manual interventions`
   section covering the whole job.
2. Run `/task-implement <N>`. Observe the walkthrough announcement and a
   readiness check, then step-by-step guidance with the same
   pause → confirm → verify loop.
3. Verify Claude makes NO production edits during the task (inspect the
   diff: only `.claude/TASKS.md` bookkeeping is Claude's), while it may
   still run read-only checks and test commands.
4. After the final step verifies, observe the status flip to `[DONE]`
   and the Step 8 commit of the user's changes (unless `--no-commit`).

---

## Notes

- Test `/task-implement all` to verify batch mode and progress reporting.
- Verify that a failing test stops the run without committing.
- On a project without a test suite, verify the interactive mode prompt
  appears and both options (scaffold / skip) work as described.
- **Context discipline (v0.3+ bodies, qualitative).** Run
  `/task-implement <N>` against a task whose body uses the v0.3+
  schema (contains `### Files to modify`, `### Required reading`,
  `### Conventions to follow`, `### Out of scope`). Inspect the
  agent's tool-call trace and confirm it leaned on the body's
  Required reading / Conventions / Out of scope content rather than
  bulk-reading every file under `.claude/context/` reflexively. Some
  context reads are fine — the test is qualitative ("reduced, not
  zero"), not strict. The implementation must still land and commit
  cleanly.
- **Older-body fallback.** Run `/task-implement <N>` against a body
  that lacks the v0.3+ sections (e.g. a fixture with only Description
  / Tests / Definition of done). The agent should fall back to
  consulting CLAUDE.md and the context layer normally and still
  produce a passing implementation + commit.
