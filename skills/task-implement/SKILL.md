---
name: task-implement
version: 0.11.0
type: skill
description: Implement one or more tasks from the project's task backlog end-to-end using a TDD-style sequence. On a dirty working tree, prompts the user (proceed-uncommitted / proceed-and-fold-into-commit / commit-first / abort) instead of hard-aborting. Reads the task body as primary context and fans out to CLAUDE.md / .claude/context/ as needed. Warns (but proceeds) when implementing a target:local task. Supports human-in-the-loop tasks: target claude+human pauses at declared Manual interventions checkpoints and verifies each outcome; target human runs as a guided walkthrough. On Unity projects whose CLAUDE.md declares a Unity MCP plugin and whose mcp__UnityMCP__* tools are connected this session, those checkpoints can instead be driven by Claude in the editor (checking the Console, performing editor actions, then handing the user a verification) — opt-outable per run; when MCP isn't connected the standard manual protocol is used unchanged. Commits each task separately; pass --no-commit to skip the per-task commits. Supports `next` to implement the first eligible task. Honors a `Testing policy for /task-implement: skip-tests|full-tdd` marker in CLAUDE.md so a project's no-test-suite decision persists across runs instead of being asked every time.
---

# /task-implement
# Global skill: implement one or more tasks from the project's task backlog
# end-to-end, following a strict TDD-style sequence. Commits each task
# separately. No mid-flow confirmation prompts when tests exist; if the
# project has no test suite the flow becomes interactive.
# Usage: /task-implement <task-number> [<task-number> ...]
#        /task-implement all
#        /task-implement next
#        /task-implement <args> --no-commit   (run the TDD flow, skip commits)
# Examples: /task-implement 12
#           /task-implement 12 13 14
#           /task-implement all
#           /task-implement next
#           /task-implement all --no-commit

GOAL
For each requested task, in the order given:
1. Flip status to `[IN PROGRESS]`.
2. Update or write tests to encode the spec.
3. Run the affected tests and watch them fail.
4. Implement the production change.
5. Re-run the affected tests and watch them pass.
6. Run the full test suite and watch it pass.
7. Flip status to `[DONE]` (or `[PARTIAL]` / `[INCORRECT]` if appropriate).
8. Commit — one commit per task (skipped under `--no-commit`, which leaves
   each task's changes uncommitted in the working tree).

If any step fails and cannot be resolved by fixing the code, stop the entire
run and report. Do not proceed to subsequent tasks. Do not commit a broken
task. Under `--no-commit`, when the run completes, end with a reminder that
nothing was committed — every task's changes sit in the working tree for the
user to review and commit.

$ARGUMENTS

---

SUPPORTING FILES (read on demand — not up front)

This skill's common path is the whole of SKILL.md: a clean working tree, a
project whose test command is already known, and numbered `Target: claude`
tasks. Everything below is loaded only when its branch actually applies.

| Read this file | Exactly when |
| -------------- | ------------ |
| `./dirty-tree.md`    | `git status --porcelain` is non-empty in PRE-FLIGHT step 1. |
| `./test-runner.md`   | Neither CLAUDE.md/README/`.claude/` nor a testing-policy marker names the test command, so you must infer it. |
| `./no-test-suite.md` | The project has no test suite at all, OR CLAUDE.md declares `Testing policy for /task-implement: skip-tests`. |
| `./human-in-loop.md` | The current task's `Target:` is `claude+human` or `human`. |
| `./unity-mcp-checkpoints.md` | A `claude+human`/`human` task where CLAUDE.md carries the `Unity MCP for /task-implement:` marker AND the `mcp__UnityMCP__*` tools are present this session (read after `./human-in-loop.md`, per its gate). |
| `./body-schemas.md`  | The task body does NOT match the current schema (Goal / Acceptance criteria / Decisions / Hints). |

Do not read a supporting file speculatively. If none of the conditions
above fire, the run never touches one.

Throughout this skill, Bash / PowerShell are only for running tests and git
commands.

---

ARGUMENT PARSING

Before resolving the task list, scan `$ARGUMENTS` for the optional
`--no-commit` flag. If present, set NO_COMMIT = true and strip it; the
remainder is the task selector. `--commit` and `--no-commit` are mutually
exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.` When NO_COMMIT is
true, the run performs the full TDD sequence and the `Status:` flips but
skips the per-task commit in Step 8 (see that step and BETWEEN TASKS). When
false (the default), each task is committed separately as before.

After stripping the flag, `$ARGUMENTS` is one of:
- A whitespace-separated list of task numbers — implement those tasks in
  the order given.
- The literal token `all` (case-insensitive) — implement every task in the
  backlog whose current status is `[MISSING]`, `[STUBBED]`, `[INCORRECT]`,
  or `[PARTIAL]`, in the order they appear in the file. Skip tasks whose
  status is `[DONE]`, `[SKIP]`, or `[IN PROGRESS]`. After resolving the
  list, report it to the user as a one-line summary ("Will implement: 3,
  7, 12 (5 tasks skipped: 1 DONE, 1 IN PROGRESS, 3 SKIP)") and proceed
  without asking for confirmation — the user already chose `all`.
- The literal token `next` (case-insensitive) — find the first task in the
  backlog (by appearance order in TASKS.md) whose status is `[MISSING]`,
  `[STUBBED]`, `[INCORRECT]`, or `[PARTIAL]`, and implement that single
  task. Skip tasks whose status is `[DONE]`, `[SKIP]`, or `[IN PROGRESS]`.
  If no eligible task is found, tell the user "No eligible tasks found —
  all tasks are DONE, SKIP, or IN PROGRESS." and stop. Otherwise, report
  "Next eligible task: <N> — <title>" and proceed without asking for
  confirmation.

If `$ARGUMENTS` is empty, tell the user the usage and stop.

For `all` and `next`, after resolving the list, check each resolved task's
`Target:` field in its TASKS.md summary block. If any resolved task is
`claude+human` or `human`, append a warning to the resolution report:
"Task(s) <IDs> require human intervention — the run will pause and need
you present." These tasks cannot run unattended.

---

LOCATING THE BACKLOG

The backlog index lives at `.claude/TASKS.md`. Per-task body content
lives at `.claude/tasks/<N>.md` — one file per task ID.

If `.claude/TASKS.md` does not exist, tell the user "No backlog file
found — run /task-setup to initialize it, then /task-add to create
tasks." and stop. Do NOT create anything.

Read TASKS.md first to find the summary block for each requested task
(number, title, Status, Files, Preconditions). For each task you are
about to implement, read its `.claude/tasks/<N>.md` body file when you
need its spec — not before. Do NOT bulk-read every body file up front:
open each one only at the moment its task becomes the current one. If the
body file for a task you intend to implement is missing, stop and report
— the task is corrupt and the user should investigate.

Status flips happen in `.claude/TASKS.md` only — the per-task body
file does not store Status, Files, or Preconditions, so do not edit
the body file when changing status.

---

USING THE TASK BODY

The current body schema is **Goal / Acceptance criteria / Decisions /
Hints**. Read the body, then navigate CLAUDE.md, `.claude/context/`,
`.claude/domain/`, and source files as needed. The body provides the
spec; the project's context layer provides conventions and patterns.
Use judgment about how much to read — the body's Hints point to the
right files.

If the body carries sections that do not match that schema — a `Context
bundle` / `Implementation steps` pair, or the older `Description` /
`Required reading` / `Out of scope` set — read `./body-schemas.md` for how
to treat it.

In all cases: use judgment, not a checklist.

---

RESOLVING THE TEST RUNNER

The skill must work on any project. Establish how tests run before doing
anything else:

0. **Testing policy marker (checked first).** Read `CLAUDE.md` if it
   exists and look for a line of the form:
   `Testing policy for /task-implement: skip-tests` or
   `Testing policy for /task-implement: full-tdd`. This is a project's
   own durable declaration and overrides heuristic detection:
   - `skip-tests` → the project has stated it has no automated test
     suite. Read `./no-test-suite.md` and go straight to its skip-tests
     mode, without asking the A/B question.
   - `full-tdd` → the project has stated it does have a test suite, even
     if no runner is auto-detectable. Never enter no-test-suite mode;
     continue at step 1 to resolve the actual test command.
   - No marker found → continue to step 1.
1. If a CLAUDE.md, README.md, or `.claude/` context file specifies a test
   command, use it. Project conventions beat heuristics. **On the common
   path this resolves the runner and you are done here.**
2. Otherwise, read `./test-runner.md` and infer the runner from the
   project's files. If it is still ambiguous after that, ask the user
   before starting any task.
3. If the project has no test suite at all (no runner inferable AND no
   test directory like `tests/`, `test/`, `__tests__/`, `spec/`), read
   `./no-test-suite.md` and follow it.

For "affected tests", prefer running just the test file(s) listed in the
task's `Files:` field. If that's not feasible, fall back to running tests
by keyword/marker matching the task's subject. The full suite is always
run at the end of each task regardless.

If the project HAS a test suite (runner found OR test directory present)
and no `skip-tests` marker, do not enter skip-tests mode. Run in full TDD
mode without per-task confirmations.

---

PRE-FLIGHT CHECKS (before any task)

1. **Working-tree check.** Run `git status --porcelain` once.
   - If output is empty (clean tree — the common path), continue silently.
     Set DIRTY_FOLD = false.
   - If non-empty, read `./dirty-tree.md` and follow its prompt protocol
     before going further. It sets DIRTY_FOLD and DIRTY_FOLD_UNTRACKED,
     which Step 8 consumes, and may halt the run.

2. Use the Read tool to open `.claude/TASKS.md`. Resolve the task list
   per ARGUMENT PARSING above. For each task to be implemented:
   - Confirm a summary block for that task ID exists in TASKS.md.
   - Confirm its status is one of `[MISSING]`, `[STUBBED]`,
     `[INCORRECT]`, `[PARTIAL]`. If it's `[DONE]`, `[SKIP]`, or
     `[IN PROGRESS]` and the user requested it explicitly by number,
     ask whether to skip or override. (For `all`, these statuses are
     silently skipped — see ARGUMENT PARSING.)
   - Note its Files and Preconditions fields from the summary block.

   Do NOT read the per-task body files in this preflight step. Each
   `.claude/tasks/<N>.md` is read only when its task becomes the
   current one (Step 1 of the per-task workflow).

3. If the project has a CLAUDE.md, read it — it's small and global.
   Defer reading the broader `.claude/context/` and `.claude/domain/`
   layers until per-task Step 1 indicates a need (see USING THE TASK
   BODY). Don't assume any of these exist.

4. Briefly tell the user what you're about to do — one line per task —
   then start. In full TDD mode, no per-task confirmation prompt; in
   skip-tests mode, prompt before each task.

---

PER-TASK WORKFLOW

For each task, in order:

### Step 1 — Mark IN PROGRESS

Use the Read tool to open `.claude/tasks/<N>.md` for the current task.
Hold its contents in mind for the rest of the per-task workflow.

If the body's second line reads `Target: local`, emit this note before
proceeding (no confirmation prompt — just continue):

> Note: this task was written for a local LLM (Target: local) —
> implementing with Claude anyway.

If the target is `claude+human` or `human`, read `./human-in-loop.md`
now and follow it for the rest of this task. For `claude+human`,
announce the manual-intervention checkpoints up front — a one-line
summary per checkpoint — so the user knows where the run will pause and
what they'll be asked to do. For `human`, state that this task runs as a
guided walkthrough and confirm the user is ready to start.
`./human-in-loop.md` carries a gate that decides whether the manual
checkpoints can be driven through Unity MCP (reading
`./unity-mcp-checkpoints.md` only when eligible) — do not check for MCP
yourself here; let that file's gate handle it.

Apply the body schema guidance from USING THE TASK BODY above.

Use the Edit tool to change this task's `Status:` line in
`.claude/TASKS.md` (the summary block) to `[IN PROGRESS]`. The body
file does not contain a Status field, so do not edit it. Do not
commit this change yet — it will be bundled into the task's commit.

### Step 2 — Update tests   [skipped in skip-tests mode]

Use the Read tool to open the test files listed in the task's `Files:`
field on its TASKS.md summary block (or implied by the task's tests
section). Use the Edit tool to add or modify tests to encode the
behavior the task specifies — every assertion the body calls for, plus
regression guards for its acceptance criteria.

If a test file doesn't exist yet but the task expects one, use the Write tool
to create it.

Do NOT touch production code yet.

### Step 3 — Run the affected tests, watch them fail   [skipped in skip-tests mode]

Run the test runner against the affected test file(s). The new/updated
tests MUST fail (or error). If they pass already, the test isn't asserting
what the task intends — fix the test before moving on.

If existing tests in the same file fail unexpectedly (i.e. unrelated to
your new assertions), stop and report — something is wrong with the
baseline.

### Step 4 — Implement

Use the Read tool to open each file before editing it. Use the Edit tool to
make targeted changes; use the Write tool only when creating a new file from
scratch. Modify only the files listed in `Files:` plus genuine collateral
(imports, type hints, fixture updates). If you find yourself touching files
not listed, pause and explain why — surface the surprise rather than
expanding scope silently.

Follow the project's existing code style. Don't add comments, error
handling, or abstractions beyond what the task requires.

On a `claude+human` or `human` task, apply the checkpoint protocol from
`./human-in-loop.md` at each checkpoint's trigger point.

### Step 5 — Run the affected tests, watch them pass   [skipped in skip-tests mode]

Re-run the affected tests. They MUST pass. If they don't, fix the
production code (not the test) and rerun. If after a reasonable attempt
the code still doesn't pass and the spec itself looks wrong, stop and
report — do not weaken the test.

### Step 6 — Run the full test suite   [skipped in skip-tests mode]

Run the full test suite. It MUST pass entirely. If unrelated tests fail,
the change has caused a regression — fix it before continuing. Do not
commit with red tests.

### Step 7 — Mark DONE (or other terminal status)

Use the Edit tool to update this task's `Status:` line in
`.claude/TASKS.md`:
- `[DONE]` — implementation matches the spec.
- `[PARTIAL]` — landed, but some sub-requirements remain. Use only if
  you discovered a sub-requirement during impl that genuinely belongs in
  a separate task — surface this to the user before choosing this
  status.
- `[INCORRECT]` should not appear on a fresh implementation; do not use
  here.

The default is `[DONE]`.

### Step 8 — Commit   [skipped in --no-commit mode]

If NO_COMMIT is true, do not commit this task. Leave all files modified by
this task — including the `.claude/TASKS.md` status flip — uncommitted in
the working tree, and move on to the next task (or the final report). The
changes from each task accumulate uncommitted across the run; the final
report reminds the user that nothing was committed. Skip the rest of this
step.

Otherwise (the default):

If DIRTY_FOLD is false (the common case — clean tree, or the user chose
"proceed" on a dirty tree), stage only the files modified by this task,
including the `.claude/TASKS.md` status flip, by explicit path
(`git add -- <path> <path>`). The per-task body file at
`.claude/tasks/<N>.md` is typically NOT modified during implementation —
do not include it in the commit unless you genuinely changed it (e.g.
corrected a stale description after discovering the spec was wrong).

If DIRTY_FOLD is true, fold the pre-existing dirty changes into this
commit as described in `./dirty-tree.md` (which you will already have
read — DIRTY_FOLD can only be true if the tree was dirty).

Create a single commit. Commit message format follows the repo's
existing style — read the last few `git log` entries first. If there's
no established style, use:

```
Task <N>: <task title>

<one-paragraph summary of what changed>
```

In skip-tests mode, append a parenthetical note to the body:
`(no tests — manual verification pending)`.

Do NOT use `--no-verify`, `--amend`, `--no-gpg-sign`, or skip any hooks
unless the user explicitly asked for it. If a pre-commit hook fails,
investigate and fix the underlying issue, then create a NEW commit (do
not amend).

Each task gets exactly one commit. Never bundle multiple tasks into one
commit, even when several were requested in the same invocation.

---

BETWEEN TASKS

After committing a task, before starting the next:
1. **In --no-commit mode, skip this dirty-tree check entirely** — the
   previous task's changes are deliberately left uncommitted and will
   accumulate, so a non-empty `git status` is expected, not a surprise.
   Otherwise (the default): run `git status --porcelain`. If non-empty
   (unusual — the previous task's Step 8 should have committed everything
   it changed), apply the same prompt protocol as PRE-FLIGHT CHECKS step 1
   via `./dirty-tree.md` — DIRTY_FOLD set there applies to the upcoming
   task's Step 8. Same rules: silence/EOF/abort halts the run with no
   `Status:` flips.
2. Use the Read tool to re-open `.claude/TASKS.md` fresh. Task IDs are
   stable so numbers will not have moved, but statuses or
   `Preconditions:` lines may have been edited by a parallel
   `/task-add` or `/task-clean` invocation.
3. Briefly report progress: "Task N committed. Starting task M."
4. In skip-tests mode, ask "Proceed?" before starting the next task.

---

FAILURE HANDLING

If any step fails in a way you cannot resolve:
- Do not commit a broken task.
- Do not flip the status to `[DONE]`.
- Leave the task's status in `.claude/TASKS.md` as `[IN PROGRESS]` so
  the user can see where the run stopped.
- Stop the entire run — do not start subsequent tasks.
- Report clearly what failed, what you tried, and what the user might
  want to do next (revert with `git restore`, fix manually, edit the
  task spec).

DO NOT:
- Skip the "watch tests fail" step in full TDD mode. It's the proof that
  the test exercises the gap.
- Weaken a test to make it pass.
- Bundle multiple tasks into one commit.
- Run destructive git operations (`reset --hard`, `clean -f`,
  `checkout .`) without the user's explicit instruction.
- Continue past a failing test with a "todo: fix later" comment.
- Skip the full-suite run at the end of a task in full TDD mode.
- Auto-scaffold a test suite without the user explicitly choosing
  option A of `./no-test-suite.md`.
- Proceed past a manual-intervention checkpoint on the user's word alone
  when the outcome is checkable — verify it yourself first.
- Make production edits on a `Target: human` task.
