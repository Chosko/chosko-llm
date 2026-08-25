---
name: task-implement
version: 1.1.0
type: skill
description: Implement one or more tasks from the project's task backlog end-to-end using a tests-first sequence. On a dirty working tree, prompts the user (proceed-uncommitted / proceed-and-fold-into-commit / commit-first / abort) instead of hard-aborting. Reads the task body as primary context and fans out to CLAUDE.md / .claude/context/ as needed. Supports human-in-the-loop tasks: target claude+human pauses at declared Manual interventions checkpoints and verifies each outcome; target human runs as a guided walkthrough. On Unity projects whose CLAUDE.md declares a Unity MCP plugin and whose mcp__UnityMCP__* tools are connected this session, those checkpoints can instead be driven by Claude in the editor (checking the Console, performing editor actions, then handing the user a verification) — opt-outable per run; when MCP isn't connected the standard manual protocol is used unchanged. Commits and pushes each task separately; pass --no-commit to skip the per-task commits (and pushes), or --no-push to keep committing without pushing. Supports `next` to implement the first eligible task. On a `[STALE]` task — one whose originating feature was re-architected — warns naming the feature and lets the user implement anyway or stop; `all`/`next` skip stale tasks rather than deciding for the user. Honors a `Testing policy for /task-implement: skip-tests|full-tdd|skip-tests-unattended` marker in CLAUDE.md so a project's no-test-suite decision persists across runs instead of being asked every time. In skip-tests mode, pass `-y` to suppress the per-task "Proceed?" confirmation for that run; the `skip-tests-unattended` marker value makes that the default for every run without needing `-y`. On a run resolving to 2+ tasks, offers to implement each task in a fresh subagent so later tasks don't inherit earlier ones' context — agents run one at a time, never in parallel, and `claude+human` / `human` / explicitly-requested `[STALE]` tasks stay in the parent conversation because they need the user present; pass `--agents` / `--no-agents` to pre-answer. On such a run the parent is a launcher: it evaluates the delegation guard from the `TASKS.md` summary blocks alone, never opens a delegated task's body, hands every agent the same fixed-size prompt carrying only the task number and the run's resolved flags, and keeps only the task number, terminal status, commit hash and one-line failure reason each agent returns — so the parent's context no longer grows with the size of the batch. When a `Feature:`-tagged task
lands `[DONE]` and leaves every task for that feature `[DONE]`/`[SKIP]`,
records it as a completion candidate and, once at the very end of the run
(batched across the whole run, never per-task), proposes flipping that
feature's `FEATURES.md` `Status:` from `[PLANNED]` to `[DONE]` — the user
decides, per feature; declined or unnamed slugs stay `[PLANNED]`.
---

# /task-implement
# Global skill: implement one or more tasks from the project's task backlog
# end-to-end, following a tests-first sequence. Commits each task
# separately. No mid-flow confirmation prompts when tests exist; if the
# project has no test suite the flow becomes interactive.
# Usage: /task-implement <task-number> [<task-number> ...]
#        /task-implement all
#        /task-implement next
#        /task-implement <args> --no-commit   (run the tests-first flow, skip commits and pushes)
#        /task-implement <args> --no-push     (commit each task as usual, skip the pushes)
#        /task-implement <args> -y            (skip-tests mode: no per-task Proceed? prompt)
#        /task-implement <args> --agents      (2+ tasks: one fresh subagent per task, sequentially)
#        /task-implement <args> --no-agents   (2+ tasks: run everything in this conversation)
# Examples: /task-implement 12
#           /task-implement 12 13 14
#           /task-implement all
#           /task-implement next
#           /task-implement all --no-commit
#           /task-implement all --no-push
#           /task-implement all -y
#           /task-implement all -y --agents

GOAL
For each requested task, in the order given:
1. Flip status to `[IN PROGRESS]`.
2. Update or write tests to encode the spec.
3. Implement the production change.
4. Run the affected tests and watch them pass.
5. Run the full test suite and watch it pass.
6. Flip status to `[DONE]` (or `[PARTIAL]` / `[INCORRECT]` if appropriate).
7. Commit and push — one commit (and push) per task (skipped under
   `--no-commit`, which leaves each task's changes uncommitted in the
   working tree; the push alone is skipped under `--no-push`).

If any step fails and cannot be resolved by fixing the code, stop the entire
run and report. Do not proceed to subsequent tasks. Do not commit a broken
task. Under `--no-commit`, when the run completes, end with a reminder that
nothing was committed — every task's changes sit in the working tree for the
user to review and commit.

When a completed task carries a `Feature:` line and it was the last task for
that feature to reach `[DONE]`/`[SKIP]`, the run notes the feature as a
completion candidate but proposes nothing until every requested task is
done — once, for the whole batch. See FEATURE COMPLETION below.

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
| `./delegated-runs.md` | DELEGATE is true — the resolved list holds 2+ tasks and the user opted into per-task subagents (or passed `--agents`). Never on a single-task run, nor when the user declined. |

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
true, the run performs the full test sequence and the `Status:` flips but
skips the per-task commit in Step 7 (see that step and BETWEEN TASKS). When
false (the default), each task is committed separately as before.
NO_COMMIT true implies NO_PUSH true — nothing is committed to push.

Also scan for the optional `--no-push` flag. If present, set NO_PUSH = true
and strip it. NO_PUSH only matters when NO_COMMIT is false: it skips the
pull-at-start (PRE-FLIGHT step 5) and each task's re-sync/push in Step 7,
while every task still commits as always.

Also scan for the optional `-y` flag. If present, set AUTO_CONFIRM = true
and strip it. AUTO_CONFIRM only changes behavior in skip-tests mode (see
RESOLVING THE TEST RUNNER and `./no-test-suite.md`): it suppresses the
per-task "Proceed?" confirmation that mode would otherwise ask before each
task. It has no effect in full test mode, which never asks that prompt. A
project whose CLAUDE.md declares `Testing policy for /task-implement:
skip-tests-unattended` sets AUTO_CONFIRM = true for every run without
needing `-y` on the command line; passing `-y` explicitly is redundant but
harmless in that case.

Also scan for the optional `--agents` / `--no-agents` pair and strip
whichever appears. They are mutually exclusive — if both appear, stop with:
`--agents and --no-agents cannot be combined. Pick one.` They pre-answer
PRE-FLIGHT step 2b's delegation question: `--agents` sets DELEGATE = true,
`--no-agents` sets DELEGATE = false, and either way that question is not
asked. With neither flag, DELEGATE is undecided here and step 2b resolves
it. `--agents` on a run that resolves to fewer than 2 tasks is accepted and
ignored — the run stays in-context — rather than being an error.

After stripping the flag, `$ARGUMENTS` is one of:
- A whitespace-separated list of task numbers — implement those tasks in
  the order given.
- The literal token `all` (case-insensitive) — implement every task in the
  backlog whose current status is `[MISSING]`, `[STUBBED]`, `[INCORRECT]`,
  or `[PARTIAL]`, in the order they appear in the file. Skip tasks whose
  status is `[DONE]`, `[SKIP]`, `[IN PROGRESS]`, or `[STALE]`. After
  resolving the list, report it to the user as a one-line summary ("Will
  implement: 3, 7, 12 (5 tasks skipped: 1 DONE, 1 IN PROGRESS, 3 SKIP)")
  and proceed without asking for confirmation — the user already chose
  `all`.
- The literal token `next` (case-insensitive) — find the first task in the
  backlog (by appearance order in TASKS.md) whose status is `[MISSING]`,
  `[STUBBED]`, `[INCORRECT]`, or `[PARTIAL]`, and implement that single
  task. Skip tasks whose status is `[DONE]`, `[SKIP]`, `[IN PROGRESS]`, or
  `[STALE]`. If no eligible task is found, tell the user "No eligible
  tasks found — all tasks are DONE, SKIP, IN PROGRESS, or STALE." and
  stop. Otherwise, report "Next eligible task: <N> — <title>" and proceed
  without asking for confirmation.

`[STALE]` tasks are skipped by `all` and `next` because each one needs a
per-task judgment call (see STALE TASKS below) and a batch run should not
stop to ask. When the resolved list skips any, name them: "Skipped N
stale task(s): 12, 14 — implement them explicitly by number to decide
each one." A stale task requested explicitly by number is not skipped;
it goes through the STALE TASKS protocol.

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

DOCUMENTATION-ONLY TASKS

In full test mode (a project with a real test suite, no skip-tests marker),
Steps 2, 4, and 5 normally run for every task. They are pointless for a task
that touches nothing but documentation, so Step 1 determines — per task,
silently, with no confirmation prompt — whether this task is
documentation-only, using only data already in hand at that point: the
`Files:` field noted in PRE-FLIGHT step 2 and the body just read in Step 1.
This is not a separate re-read pass.

A task is documentation-only when EVERY path in its `Files:` field is a
documentation artifact — `README.md`, `CHANGELOG.md`, `docs/**`, or a
comparable prose/reference file — and NONE is a source file, script, test
file, or a command/skill specification (`commands/*.md`, `skills/**/*.md`,
or the equivalent executable-prompt files in another project). Those look
like markdown but define runtime behavior, so editing them is a code
change, not a documentation change.

If `Files:` is empty, ambiguous, or mixes documentation with any
non-documentation path, the task is a normal code task — never guess in
the direction of skipping tests.

Set DOC_ONLY = true or false for the current task as part of Step 1. When
DOC_ONLY is true, Steps 2, 4, and 5 are skipped for this task exactly as
they are in skip-tests mode — silently, with no confirmation prompt. This
is independent of, and does not change, skip-tests / skip-tests-unattended
mode: when that mode is already active, Steps 2/4/5 are already skipped
for every task, making the DOC_ONLY determination moot.

---

STALE TASKS

`[STALE]` means the feature document this task was generated from has since
been re-architected: the task is live work, but its spec may no longer match
the design. `/architect` sets it; `/task-add feature=<slug>` reconciliation
clears it.

A stale task is implementable here, but only on the user's explicit say-so.
Before doing anything else on such a task, warn:

> Task <N> is `[STALE]`. Feature `<slug>` was re-architected after this task
> was written, so its spec may no longer match the current design — see
> `.claude/domain/features/<slug>.md`. Options:
>
> A. **Implement anyway** — the task still looks right to you.
> B. **Stop** — reconcile the backlog first with
>    `/task-add feature=<slug>`, then re-run.
>
> Which?

Take the feature slug from the task's `Feature:` line in its TASKS.md
summary block; if there is no such line, say the originating feature is
unrecorded and offer the same choice. Wait for an explicit answer —
silence is not approval. On A, proceed through the normal per-task
workflow unchanged. On B, stop the run without flipping any `Status:`; if
other tasks were queued behind this one, say which were not started.

The choice is always the user's: a human can judge whether a superseded
design still applies, and nothing here decides that for them.

---

RESOLVING THE TEST RUNNER

The skill must work on any project. Establish how tests run before doing
anything else:

0. **Testing policy marker (checked first).** Read `CLAUDE.md` if it
   exists and look for a line of the form:
   `Testing policy for /task-implement: skip-tests`,
   `Testing policy for /task-implement: full-tdd`, or
   `Testing policy for /task-implement: skip-tests-unattended`. This is a
   project's own durable declaration and overrides heuristic detection:
   - `skip-tests` → the project has stated it has no automated test
     suite. Read `./no-test-suite.md` and go straight to its skip-tests
     mode, without asking the A/B question.
   - `skip-tests-unattended` → same as `skip-tests`, plus set
     AUTO_CONFIRM = true (as if `-y` had been passed) for the whole run,
     so skip-tests mode's per-task "Proceed?" prompt is also suppressed.
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
and no `skip-tests` marker, do not enter skip-tests mode. Run in full test
mode without per-task confirmations.

---

PRE-FLIGHT CHECKS (before any task)

1. **Working-tree check.** Run `git status --porcelain` once.
   - If output is empty (clean tree — the common path), continue silently.
     Set DIRTY_FOLD = false.
   - If non-empty, read `./dirty-tree.md` and follow its prompt protocol
     before going further. It sets DIRTY_FOLD and DIRTY_FOLD_UNTRACKED,
     which Step 7 consumes, and may halt the run.

2. Use the Read tool to open `.claude/TASKS.md`. Resolve the task list
   per ARGUMENT PARSING above. For each task to be implemented:
   - Confirm a summary block for that task ID exists in TASKS.md.
   - Confirm its status is one of `[MISSING]`, `[STUBBED]`,
     `[INCORRECT]`, `[PARTIAL]`. If it's `[DONE]`, `[SKIP]`, or
     `[IN PROGRESS]` and the user requested it explicitly by number,
     ask whether to skip or override. If it's `[STALE]` and was
     requested explicitly by number, apply the STALE TASKS protocol
     above. (For `all` and `next`, all of these statuses are skipped —
     see ARGUMENT PARSING.)
   - Note its Files, Preconditions, and — when present — `Feature:`
     fields from the summary block. `Feature:` appears only on
     feature-derived tasks; its absence is normal.

   Do NOT read the per-task body files in this preflight step. Each
   `.claude/tasks/<N>.md` is read only when its task becomes the
   current one (Step 1 of the per-task workflow).

   The three fields the delegation guard needs — `Target:`, `Status:` and
   `Feature:` — are all in the summary blocks read right here, once for the
   whole run. So step 2b decides what may be delegated without opening a
   single task body, and on a delegated run it never opens one for a
   delegated task at all (see `./delegated-runs.md`).

2b. **Delegation check.** Only when the resolved list holds 2 or more
   tasks. With fewer than 2, DELEGATE is false, nothing is asked, and the
   run is exactly as it has always been — skip this step entirely.

   If `--agents` or `--no-agents` was passed, DELEGATE is already set;
   don't ask. Otherwise ask once:

   > This run covers <k> tasks. Implement each one in a fresh subagent, so
   > later tasks don't inherit the context of earlier ones? Agents run one
   > after another, never in parallel.
   >
   > A. **Yes** — one agent per task, sequentially.
   > B. **No** — implement everything in this conversation.

   Wait for an explicit answer. Silence, an unclear reply, or EOF means
   B — in-context, the existing behavior. Do not treat a non-answer as
   approval.

   If DELEGATE is true, read `./delegated-runs.md` now and follow it for
   the rest of the run. `claude+human` / `human` tasks and explicitly
   requested `[STALE]` tasks are never delegated — the parent implements
   those in this conversation, and that file governs how the split is
   announced and executed. For every task that IS delegated, the parent
   acts as a launcher: it hands the agent a fixed-size prompt built from
   the run's resolved flags, never reads that task's body, and keeps only
   the four values the agent returns.

3. If the project has a CLAUDE.md, read it — it's small and global.
   Defer reading the broader `.claude/context/` and `.claude/domain/`
   layers until per-task Step 1 indicates a need (see USING THE TASK
   BODY). Don't assume any of these exist.

4. Briefly tell the user what you're about to do — one line per task —
   then start. In full test mode, no per-task confirmation prompt; in
   skip-tests mode, prompt before each task unless AUTO_CONFIRM is true.
   When DELEGATE is true, that summary also says which tasks go to agents
   and which run in this conversation (see `./delegated-runs.md`).

5. **Pull at start.** Unless NO_COMMIT is true (nothing will be committed
   this run, so nothing to push) or the project's CLAUDE.md carries a
   `## VCS` override (non-git — no push step exists there either), run
   `git pull` on the current branch once, before the first task's work
   begins. A conflict stops the run here — report the conflict output and
   tell the user to resolve manually and re-run. This runs once per
   invocation, not once per task; each task's own re-sync happens right
   before that task's push (Step 7).

---

PER-TASK WORKFLOW

For each task, in order.

When DELEGATE is true, this workflow is what each spawned agent performs
for its one task — the parent runs it directly only for the tasks
`./delegated-runs.md` keeps in the parent (`claude+human`, `human`, and
explicitly requested `[STALE]` tasks). The steps themselves are identical
either way; that sameness is the point, so the delegated flow and the
manual flow cannot drift apart. Step 1's body read therefore happens in
whichever session is implementing the task — the agent for a delegated
task, the parent for a task it kept — and never in both.

### Step 1 — Mark IN PROGRESS

If this task's status is `[STALE]`, run the STALE TASKS protocol before
reading anything else, and do not continue unless the user chose to
implement anyway.

Use the Read tool to open `.claude/tasks/<N>.md` for the current task.
Hold its contents in mind for the rest of the per-task workflow.

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

Apply the DOCUMENTATION-ONLY TASKS guidance above to set DOC_ONLY for this
task, using the `Files:` field already noted in PRE-FLIGHT step 2 and the
body just read.

Use the Edit tool to change this task's `Status:` line in
`.claude/TASKS.md` (the summary block) to `[IN PROGRESS]`. The body
file does not contain a Status field, so do not edit it. Do not
commit this change yet — it will be bundled into the task's commit.

### Step 2 — Update tests   [skipped in skip-tests mode, or when Step 1 determined DOC_ONLY]

Use the Read tool to open the test files listed in the task's `Files:`
field on its TASKS.md summary block (or implied by the task's tests
section). Use the Edit tool to add or modify tests to encode the
behavior the task specifies — every assertion the body calls for, plus
regression guards for its acceptance criteria.

If a test file doesn't exist yet but the task expects one, use the Write tool
to create it.

Do NOT touch production code yet.

### Step 3 — Implement

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

### Step 4 — Run the affected tests, watch them pass   [skipped in skip-tests mode, or when Step 1 determined DOC_ONLY]

Run the affected tests. They MUST pass. If they don't, fix the
production code (not the test) and rerun. If after a reasonable attempt
the code still doesn't pass and the spec itself looks wrong, stop and
report — do not weaken the test.

### Step 5 — Run the full test suite   [skipped in skip-tests mode, or when Step 1 determined DOC_ONLY]

Run the full test suite. It MUST pass entirely. If unrelated tests fail,
the change has caused a regression — fix it before continuing. Do not
commit with red tests.

### Step 6 — Mark DONE (or other terminal status)

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

If this task's TASKS.md summary block carries a `Feature: <slug>` line and
the status just written is `[DONE]`, apply the FEATURE COMPLETION check
below before moving to Step 7.

### Step 7 — Commit and push   [skipped in --no-commit mode]

If NO_COMMIT is true, do not commit (or push) this task. Leave all files
modified by this task — including the `.claude/TASKS.md` status flip —
uncommitted in the working tree, and move on to the next task (or the
final report). The changes from each task accumulate uncommitted across
the run; the final report reminds the user that nothing was committed.
Skip the rest of this step.

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

On commit success, report the commit hash. Then, unless NO_PUSH is true or
the project's CLAUDE.md carries a `## VCS` override (non-git), re-sync
(`git pull`) and `git push` per docs/authoring-guide.md's commit-and-push
protocol — once per task, immediately after that task's commit, mirroring
"each task gets exactly one commit" with "each task gets exactly one
push." A pre-push conflict aborts the merge, leaves the local commit
intact, does NOT push, and reports that this task's commit exists locally
but needs a manual sync + push — this halts the run before the next task
starts (treat it like any other Step 7 failure). On push failure
(rejected, no upstream, no remote): report the exact output and stop.
Never retry, never force-push.

---

BETWEEN TASKS

When DELEGATE is true, `./delegated-runs.md` governs what happens between
tasks — it covers the same ground (re-read TASKS.md, progress line,
skip-tests "Proceed?") plus verifying what the returning agent did. Follow
it instead of the list below for delegated tasks; a task the parent
implements itself follows the list as usual.

After committing a task, before starting the next:
1. **In --no-commit mode, skip this dirty-tree check entirely** — the
   previous task's changes are deliberately left uncommitted and will
   accumulate, so a non-empty `git status` is expected, not a surprise.
   Otherwise (the default): run `git status --porcelain`. If non-empty
   (unusual — the previous task's Step 7 should have committed everything
   it changed), apply the same prompt protocol as PRE-FLIGHT CHECKS step 1
   via `./dirty-tree.md` — DIRTY_FOLD set there applies to the upcoming
   task's Step 7. Same rules: silence/EOF/abort halts the run with no
   `Status:` flips.
2. Use the Read tool to re-open `.claude/TASKS.md` fresh. Task IDs are
   stable so numbers will not have moved, but statuses or
   `Preconditions:` lines may have been edited by a parallel
   `/task-add` or `/task-clean` invocation.
3. Briefly report progress: "Task N committed. Starting task M."
4. In skip-tests mode, ask "Proceed?" before starting the next task,
   unless AUTO_CONFIRM is true.

---

FEATURE COMPLETION

Applies only to tasks whose TASKS.md summary block carries a `Feature:
<slug>` line — free-form tasks never trigger this.

When Step 6 lands a task at `[DONE]` and it carries `Feature: <slug>`, check
every other summary block in `.claude/TASKS.md` that carries the same
`Feature: <slug>`. If every one of them is now `[DONE]` or `[SKIP]`, AND
`.claude/FEATURES.md`'s entry for `<slug>` currently reads `Status:
[PLANNED]`, record `<slug>` as a completion candidate in memory for the rest
of the run. This is the only outcome of the check — do not propose anything
yet, and do not re-check a slug already recorded.

A `[PARTIAL]` task never triggers this check, even if it carries a
`Feature:` line. A feature whose `FEATURES.md` status is `[NEW]`,
`[ITERATED]`, or already `[DONE]` never becomes a candidate either — only a
`[PLANNED]` feature can.

This check runs wherever a task's terminal status becomes visible to the
parent: at the end of Step 6 for a task the parent implemented itself, and
during the delegated-run "re-read TASKS.md" step (`./delegated-runs.md`) for
a task a subagent implemented. Either way it's the parent that accumulates
the candidate list across the whole run.

**Propose once, at the very end of the run** — after the last requested
task's Step 7 (or Step 6, under `--no-commit`), never mid-run even on a
many-task batch. If the candidate list is empty, say nothing about this at
all. Otherwise, present every candidate together:

> All tasks for this feature are now `[DONE]`/`[SKIP]`:
>
>   password-auth — Password authentication (tasks 31, 32, 33, 34, 35)
>
> Flip it to `[DONE]` in FEATURES.md?

or, with more than one candidate:

> All tasks for these features are now `[DONE]`/`[SKIP]`:
>
>   password-auth — Password authentication (tasks 31, 32, 33, 34, 35)
>   session-handling — Session handling (tasks 36, 37)
>
> Flip any of these to `[DONE]` in FEATURES.md? Name the slugs, or say
> "all" / "none".

Wait for an explicit answer; silence is not approval and leaves every
candidate `[PLANNED]`. A slug the user declines, or doesn't name, stays
`[PLANNED]` — mention that in the closing report, but don't ask again this
run.

For each slug the user approves, use the Edit tool to change that entry's
`Status:` line in `.claude/FEATURES.md` to `[DONE]`. Nothing else in the
entry changes.

If NO_COMMIT is true, leave the edited `.claude/FEATURES.md` uncommitted
alongside the run's other uncommitted changes, same as Step 7 — skip the
rest of this paragraph. Otherwise, if at least one slug was approved, stage
`.claude/FEATURES.md` and create exactly ONE commit covering every flip
approved this run, even when several features completed in the same batch —
this is separate from, and in addition to, the per-task commits already
made:

```
Mark feature(s) <slug>[, <slug> …] [DONE]
```

Then re-sync (`git pull`) and `git push` per `docs/authoring-guide.md`'s
commit-and-push protocol, exactly as Step 7 does (skipped under
`--no-push`). A pre-push conflict here is handled the same way a Step 7
conflict is: report it, leave the local commit intact, tell the user it
needs a manual sync + push.

A human may flip a feature to `[DONE]` by hand at any time, entirely outside
this skill. This proposal is the only place `/task-implement` itself writes
that status, and it never overwrites a status a human already set —
including a feature a human already marked `[DONE]` by hand, which never
becomes a candidate in the first place (its `FEATURES.md` status is no
longer `[PLANNED]`).

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

A failure inside a delegated task is not a special case: the parent stops
the run without spawning the next agent, and reports which tasks completed
(with hashes), which failed and what the agent said, and which were never
started. See `./delegated-runs.md`.

A Step 7 push failure or pre-push conflict is a distinct case: the task's
commit already succeeded (status legitimately `[DONE]`, changes committed
locally) — only the sync/push step failed. Do not revert the commit or
flip the status back. Stop the entire run the same way, and report that
this task's commit exists locally and needs a manual sync + push before
resuming with the remaining tasks.

DO NOT:
- Weaken a test to make it pass.
- Bundle multiple tasks into one commit.
- Run destructive git operations (`reset --hard`, `clean -f`,
  `checkout .`) without the user's explicit instruction.
- Continue past a failing test with a "todo: fix later" comment.
- Skip the full-suite run at the end of a task in full test mode.
- Auto-scaffold a test suite without the user explicitly choosing
  option A of `./no-test-suite.md`.
- Proceed past a manual-intervention checkpoint on the user's word alone
  when the outcome is checkable — verify it yourself first.
- Make production edits on a `Target: human` task.
- Start a `[STALE]` task without the user explicitly choosing to implement
  it anyway, or pick one up in an `all` / `next` run.
- Write a `Feature:` line into any task. It is `/task-add`'s field; this
  skill only reads it.
- Spawn delegated agents in parallel, or spawn the next one before the
  previous has returned — the tasks share one working tree and branch.
- Delegate a `claude+human` / `human` / `[STALE]` task to an agent, or
  offer delegation at all on a run resolving to fewer than 2 tasks.
- Open `.claude/tasks/<N>.md` in the parent for a task that is being
  delegated — not to size the work, not to write the hand-off prompt, not
  after the agent returns. The guard's three fields come from `TASKS.md`;
  the body belongs to the agent.
- Force-push, retry a failed push, defer a task's push to end-of-run, or
  push unless `--no-push`/`--no-commit` was passed — each task pushes
  immediately after its own commit (Step 7), per
  docs/authoring-guide.md's commit-and-push protocol.
- Propose a `[DONE]` feature flip mid-run, or per-task — FEATURE COMPLETION
  proposals are batched to the very end of the run, always.
- Flip a `FEATURES.md` `Status:` to `[DONE]` without the user naming that
  slug in response to the proposal, or flip any status other than
  `[PLANNED]` → `[DONE]` there.
