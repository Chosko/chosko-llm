---
name: task-implement
version: 0.5.1
type: command
description: Implement one or more tasks from the project's task backlog end-to-end using a TDD-style sequence. On a dirty working tree, prompts the user (proceed / commit-first / abort) instead of hard-aborting. Reads the task body as primary context and fans out to CLAUDE.md / .claude/context/ as needed. Warns (but proceeds) when implementing a target:local task. Commits each task separately. Supports `next` to implement the first eligible task.
---

# /task-implement
# Global command: implement one or more tasks from the project's task backlog
# end-to-end, following a strict TDD-style sequence. Commits each task
# separately. No mid-flow confirmation prompts when tests exist; if the
# project has no test suite the flow becomes interactive.
# Usage: /task-implement <task-number> [<task-number> ...]
#        /task-implement all
#        /task-implement next
# Examples: /task-implement 12
#           /task-implement 12 13 14
#           /task-implement all
#           /task-implement next

GOAL
For each requested task, in the order given:
1. Flip status to `[IN PROGRESS]`.
2. Update or write tests to encode the spec.
3. Run the affected tests and watch them fail.
4. Implement the production change.
5. Re-run the affected tests and watch them pass.
6. Run the full test suite and watch it pass.
7. Flip status to `[DONE]` (or `[PARTIAL]` / `[INCORRECT]` if appropriate).
8. Commit — one commit per task.

If any step fails and cannot be resolved by fixing the code, stop the entire
run and report. Do not proceed to subsequent tasks. Do not commit a broken
task.

$ARGUMENTS

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to an existing file;
  use the Write tool only when creating a new file from scratch. Never use
  shell redirection, `tee`, `Set-Content`, `Out-File`, or any shell
  mechanism to write files.
- Bash / PowerShell are only for running tests and git commands.

---

ARGUMENT PARSING

`$ARGUMENTS` is one of:
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
need the Description, Behavior change, Doc updates, Tests, or
Definition of done sections — not before. Do NOT bulk-read every body
file up front: open each one only at the moment its task becomes the
current one. If the body file for a task you intend to implement is
missing, stop and report — the task is corrupt and the user should
investigate.

Status flips happen in `.claude/TASKS.md` only — the per-task body
file does not store Status, Files, or Preconditions, so do not edit
the body file when changing status.

---

USING THE TASK BODY

Body files use one of two schemas:

**Current schema (Goal / Acceptance criteria / Decisions / Hints):**
Read the body, then navigate CLAUDE.md, `.claude/context/`,
`.claude/domain/`, and source files as needed. The body provides the
spec; the project's context layer provides conventions and patterns.
Use judgment about how much to read — the body's Hints point to the
right files.

**Enriched schema (same as above + Context bundle / Implementation steps):**
The body is self-contained. Use the embedded context and steps as the
primary working material. Reach for the context layer only when something
contradicts or significantly extends what the body provides.

**Older schema (Description / Required reading / Conventions to follow /
Out of scope / Tests / Definition of done):**
Treat the body as a high-quality starting point per the old conventions.
Fall back to the context layer when the body is insufficient.

In all cases: use judgment, not a checklist.

---

LOCATING THE TEST RUNNER

The command must work on any project. Detect the test runner before doing
anything else:

1. If a CLAUDE.md, README.md, or `.claude/` context file specifies a test
   command, use it. Project conventions beat heuristics.
2. Otherwise, infer from project files:
   - `pytest.ini` / `pyproject.toml` with `[tool.pytest.ini_options]` /
     `setup.cfg` with `[tool:pytest]` → `pytest`. Prefer
     `.venv/Scripts/python.exe -m pytest` on Windows or
     `.venv/bin/python -m pytest` on POSIX if a venv exists.
   - `package.json` with a `test` script → `npm test` (or `pnpm test` /
     `yarn test` if a lockfile indicates it).
   - `Cargo.toml` → `cargo test`.
   - `go.mod` → `go test ./...`.
   - `Gemfile` with rspec → `bundle exec rspec`.
   - Other: scan for a `Makefile` target named `test` → `make test`.
3. If still ambiguous, ask the user before starting any task.

For "affected tests", prefer running just the test file(s) listed in the
task's `Files:` field. If that's not feasible, fall back to running tests
by keyword/marker matching the task's subject. The full suite is always
run at the end of each task regardless.

---

NO-TEST-SUITE MODE

If the project has no test suite at all (no test runner detectable AND no
test directory like `tests/`, `test/`, `__tests__/`, `spec/`), the strict
TDD flow cannot run. Switch to interactive mode:

1. Tell the user once, up front:

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

If the project HAS a test suite (test runner found OR test directory
present), do not enter skip-tests mode. Run in full TDD mode without
per-task confirmations.

---

PRE-FLIGHT CHECKS (before any task)

1. **Working-tree check (3-way prompt on dirty tree).** Run
   `git status --porcelain` once.
   - If output is empty (clean tree), continue silently.
   - If non-empty, list the dirty files to the user (truncated to the
     first 20 entries with a `(+N more)` tail when there are more) and
     prompt:

     ```
     Working tree has uncommitted changes. Choose:
       [1] proceed   — run the task anyway (changes will be mixed into the task's commit)
       [2] commit    — commit the current changes first, then run the task
       [3] abort     — stop now, leave everything as-is
     ```

   Wait for an explicit typed answer. Accept `1`/`proceed`,
   `2`/`commit`, or `3`/`abort` (case-insensitive). EOF, an empty
   line, an unrelated reply, or silence is treated as **abort**.

   - **On 1 (proceed):** print a one-line warning that "Step 8
     (Commit) will include these unrelated changes in this task's
     commit", then continue. The current branch's risk profile becomes
     the user's choice.
   - **On 2 (commit):** ask `Commit message?` and read the answer.
     Accept either a single line or a multi-line answer terminated by
     an empty line. Then:
       1. Stage tracked dirty files: `git add -u`.
       2. If the porcelain output included untracked files, list them
          and ask `Also include untracked? [y/N]`. On explicit yes,
          stage them by listing each path explicitly
          (`git add -- <path1> <path2> …`); on anything else, leave
          them unstaged.
       3. Create one commit using the user's message via HEREDOC
          (`git commit -m "$(cat <<'EOF'\n…\nEOF\n)"`).
       4. If the commit fails (e.g. pre-commit hook), surface the
          failure to the user, do NOT retry, do NOT use `--no-verify`,
          do NOT amend, and halt the run before any task work begins.
       5. On success, continue to step 2 of the pre-flight checks.
   - **On 3 (abort) / silence / EOF:** stop. Do not flip any
     `Status:` line, do not stage, do not commit. The user is left
     exactly where they started.

   Notes:
   - `.gitignore`-excluded files are ignored as today
     (`git status --porcelain` already respects gitignore).
   - The commit path (option 2) NEVER stages untracked files without
     explicit user opt-in, and NEVER uses `git add -A`/`-u .`/`.` in
     a way that would catch the user's untracked files implicitly.

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
   current one (Step 2 of the per-task workflow).

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

Apply the body schema guidance from USING THE TASK BODY above.

Use the Edit tool to change this task's `Status:` line in
`.claude/TASKS.md` (the summary block) to `[IN PROGRESS]`. The body
file does not contain a Status field, so do not edit it. Do not
commit this change yet — it will be bundled into the task's commit.

### Step 2 — Update tests   [skipped in skip-tests mode]

Use the Read tool to open the test files listed in the task's `Files:`
field on its TASKS.md summary block (or implied by the `### Tests`
section of `.claude/tasks/<N>.md`). Use the Edit tool to add or
modify tests to encode the behavior the task specifies — every
assertion in `### Tests`, plus regression guards in `Definition of
done`.

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

### Step 8 — Commit

Stage all files modified by this task, including the `.claude/TASKS.md`
status flip. The per-task body file at `.claude/tasks/<N>.md` is
typically NOT modified during implementation — do not include it in
the commit unless you genuinely changed it (e.g. corrected a stale
description after discovering the spec was wrong).

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
1. Run `git status --porcelain`. If non-empty (unusual — the previous
   task's Step 8 should have committed everything it changed), apply
   the same 3-way prompt as PRE-FLIGHT CHECKS step 1: proceed,
   commit, or abort. Same rules: silence/EOF/abort halts the run with
   no `Status:` flips.
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
  option A.
