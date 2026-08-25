---
name: task-implement
version: 1.3.0
type: skill
description: Implement one or more tasks from the project's task backlog end-to-end using a tests-first sequence. On a dirty working tree, prompts the user (proceed-uncommitted / proceed-and-fold-into-commit / commit-first / abort) instead of hard-aborting. Reads the task body as primary context and fans out to CLAUDE.md / .claude/context/ as needed. Supports human-in-the-loop tasks: target claude+human pauses at declared Manual interventions checkpoints and verifies each outcome; target human runs as a guided walkthrough. On Unity projects whose CLAUDE.md declares a Unity MCP plugin and whose mcp__UnityMCP__* tools are connected this session, those checkpoints can instead be driven by Claude in the editor (checking the Console, performing editor actions, then handing the user a verification) — opt-outable per run; when MCP isn't connected the standard manual protocol is used unchanged. Commits and pushes each task separately; pass --no-commit to skip the per-task commits (and pushes), or --no-push to keep committing without pushing. Supports `next` to implement the first eligible task. On a `[STALE]` task — one whose originating feature was re-architected — warns naming the feature and lets the user implement anyway or stop; `all`/`next` skip stale tasks rather than deciding for the user. Honors a `Testing policy for /task-implement: skip-tests|full-tdd|skip-tests-unattended` marker in CLAUDE.md so a project's no-test-suite decision persists across runs instead of being asked every time. In skip-tests mode, pass `-y` to suppress the per-task "Proceed?" confirmation for that run; the `skip-tests-unattended` marker value makes that the default for every run without needing `-y`. On a run resolving to 2+ tasks, offers to implement each task in a fresh subagent so later tasks don't inherit earlier ones' context — agents run one at a time, never in parallel, and `claude+human` / `human` / explicitly-requested `[STALE]` tasks stay in the parent conversation because they need the user present; pass `--agents` / `--no-agents` to pre-answer. On such a run the parent is a launcher: it evaluates the delegation guard from the `TASKS.md` summary blocks alone, never opens a delegated task's body, hands every agent the same fixed-size prompt carrying only the task number and the run's resolved flags, and keeps only the task number, terminal status, commit hash and one-line failure reason each agent returns — so the parent's context no longer grows with the size of the batch. Pass `--review` (optionally `--rounds N`, default 1) to have each task reviewed before it is committed: after the full test suite and before the status flip, the run spawns `/task-review` as a subagent so the review happens in a context that did not write the code, waits for its findings, and runs `/task-iterate` in the session to triage and apply them — the fixes ride in the task's own single commit, later rounds re-review only what the last iterate changed and only while `BLOCKING` findings remain, rejected findings may not be re-raised, and unresolved `BLOCKING` findings after the last round stop the run with the tree uncommitted and the task `[IN PROGRESS]`; without the flag nothing about the run changes. When a `Feature:`-tagged task
lands `[DONE]` and leaves every task for that feature `[DONE]`/`[SKIP]`,
records it as a completion candidate and, once at the very end of the run
(batched across the whole run, never per-task), proposes flipping that
feature's `FEATURES.md` `Status:` from `[PLANNED]` to `[DONE]` — the user
decides, per feature; declined or unnamed slugs stay `[PLANNED]`.
requires: skill:task-engine
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
#        /task-implement <args> --review      (review each task before committing it)
#        /task-implement <args> --review --rounds N  (up to N review/iterate rounds; default 1)
# Examples: /task-implement 12
#           /task-implement 12 13 14
#           /task-implement all
#           /task-implement next
#           /task-implement all --no-commit
#           /task-implement all --no-push
#           /task-implement all -y
#           /task-implement all -y --agents
#           /task-implement 12 --review
#           /task-implement 12 --review --rounds 3

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

Under `--review`, a review/iterate loop runs between steps 5 and 6, on the
uncommitted tree, so its fixes ride in the task's own single commit — see
`./review-rounds.md`. Without the flag there is no loop and nothing else
about the run changes.

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

SHARED RULES (the `task-engine`)

Six rules this skill shares with the rest of the `task-*` suite have exactly
one authority each, under
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/`:
`resolution.md` (where the backlog lives and how a run resolves its task
list), `status.md` (the status vocabulary), `targets.md` (the `Target:`
values and the delegation guard), `stale.md` (`[STALE]`), `tree.md` (the
dirty-tree protocol) and `commit.md` (commit and push gating). Every one of
them carries a `/task-implement` note holding this skill's own departures.

The sections below cite those files where they apply and state only what is
this skill's own. `requires: skill:task-engine` in the frontmatter is what
guarantees they are installed.

---

SUPPORTING FILES (read on demand — not up front)

This skill's common path is the whole of SKILL.md: a clean working tree, a
project whose test command is already known, and numbered `Target: claude`
tasks. Everything below is loaded only when its branch actually applies.

| Read this file | Exactly when |
| -------------- | ------------ |
| `./test-runner.md`   | Neither CLAUDE.md/README/`.claude/` nor a testing-policy marker names the test command, so you must infer it. |
| `./no-test-suite.md` | The project has no test suite at all, OR CLAUDE.md declares `Testing policy for /task-implement: skip-tests`. |
| `./human-in-loop.md` | The current task's `Target:` is `claude+human` or `human`. |
| `./unity-mcp-checkpoints.md` | A `claude+human`/`human` task where CLAUDE.md carries the `Unity MCP for /task-implement:` marker AND the `mcp__UnityMCP__*` tools are present this session (read after `./human-in-loop.md`, per its gate). |
| `./body-schemas.md`  | The task body does NOT match the current schema (Goal / Acceptance criteria / Decisions / Hints). |
| `./delegated-runs.md` | DELEGATE is true — the resolved list holds 2+ tasks and the user opted into per-task subagents (or passed `--agents`). Never on a single-task run, nor when the user declined. |
| `./review-rounds.md` | REVIEW is true — the run was invoked with `--review`. Read once, after ARGUMENT PARSING and before the first task. Never on a run without the flag. |

Do not read a supporting file speculatively. If none of the conditions
above fire, the run never touches one.

Throughout this skill, Bash / PowerShell are only for running tests and git
commands.

---

ARGUMENT PARSING

Before resolving the task list, scan `$ARGUMENTS` for the flags below and
strip whichever appear; what is left is the task selector.

The `--no-commit` and `--no-push` flags, their mutual exclusion with
`--commit`, and everything they gate are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`.
Here NO_COMMIT true means the run performs the full test sequence and the
`Status:` flips but skips the per-task commit in Step 7 (see that step and
BETWEEN TASKS); false — the default — commits each task separately as
before. NO_PUSH true skips the pull-at-start (PRE-FLIGHT step 5) and each
task's re-sync/push in Step 7 while every task still commits as always.

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

Also scan for the optional `--review` flag and the optional `--rounds N`
pair, and strip whichever appear:

- `--review` sets REVIEW = true. Default false. When it is true, read
  `./review-rounds.md` now — before the first task — and follow it for the
  rest of the run, starting with its availability gate.
- `--rounds N` sets ROUNDS = N, a positive integer; default 1. `--rounds`
  without `--review` stops the run with: `--rounds requires --review.` An
  `N` that is not a positive integer stops too:
  `--rounds needs a positive integer.`

A run without `--review` is the run it has always been: REVIEW is false,
`./review-rounds.md` is never opened, no loop runs, nothing new is asked,
and the output says nothing about reviewing.

After stripping the flags, `$ARGUMENTS` is a whitespace-separated list of
task numbers, the literal token `all`, or the literal token `next`. Those
three selectors — what each resolves to, which statuses a batch selector
skips, the one-line resolution report each prints without asking for
confirmation, the naming of skipped stale tasks, and the empty-argument
stop — are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
§ *Selectors*. This skill is the only consumer that has them, so that
section is written in its words; nothing here departs from it.

A `[STALE]` task requested explicitly by number is not skipped — it goes
through STALE TASKS below.

The human-intervention warning appended to an `all` / `next` resolution
report is
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/targets.md`.

---

LOCATING THE BACKLOG

Backlog resolution follows
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`,
whose `/task-implement` note carries every way this skill departs from it:
the wording of the not-initialised stop, and that the selectors above are
its argument form. Its § *Opening a per-task body file* is the rule that a
body is read only when its task becomes the current one, never in bulk and
never in advance; its § *Where a status flip is written* is why every
`Status:` edit in this skill lands in `.claude/TASKS.md` and never in a
body file.

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

What `[STALE]` means, who sets and clears it, and the implement-anyway /
stop warning to put to the user before touching such a task — including
where the feature slug comes from and what each answer does — are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/stale.md`
§ *Implementing a stale task*. That protocol is this skill's own, quoted
there verbatim, and its `/task-implement` note carries the rest of this
skill's half: the choice is always the user's, a stale task is never
delegated to a subagent, and it is never started without the user
explicitly choosing to implement it anyway.

Run it before reading anything else on a `[STALE]` task, and do not
continue unless the user chose to implement anyway.

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

1. **Working-tree check.** Run the dirty-tree protocol from
   `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/tree.md`:
   `git status --porcelain` once, silent continuation on a clean tree, its
   prompt when the output is non-empty. It sets DIRTY_FOLD and
   DIRTY_FOLD_UNTRACKED, which Step 7 consumes, and may halt the run. That
   file's `/task-implement` note carries this skill's specifics — that the
   check runs twice (here and in BETWEEN TASKS), what `--no-commit` does to
   the second one, and that a delegated agent is handed the decision the
   parent already made and must not re-run the prompt.

2. Use the Read tool to open `.claude/TASKS.md`. Resolve the task list
   per ARGUMENT PARSING above. For each task to be implemented:
   - Confirm a summary block for that task ID exists in TASKS.md.
   - Confirm its status is implementable.
     `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/status.md`
     § *Implementable* is which statuses those are and what to do when a
     task requested explicitly by number carries another one — including
     the `[STALE]` hand-off to STALE TASKS above. (For `all` and `next`,
     all of those statuses are skipped — see ARGUMENT PARSING.)
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
   the rest of the run. Which tasks may never be handed to a subagent is
   the delegation guard in
   `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/targets.md`;
   `./delegated-runs.md` governs how the resulting split is announced and
   executed. For every task that IS delegated, the parent acts as a
   launcher: it hands the agent a fixed-size prompt built from the run's
   resolved flags, never reads that task's body, and keeps only the four
   values the agent returns.

3. If the project has a CLAUDE.md, read it — it's small and global.
   Defer reading the broader `.claude/context/` and `.claude/domain/`
   layers until per-task Step 1 indicates a need (see USING THE TASK
   BODY). Don't assume any of these exist.

4. Briefly tell the user what you're about to do — one line per task —
   then start. In full test mode, no per-task confirmation prompt; in
   skip-tests mode, prompt before each task unless AUTO_CONFIRM is true.
   When DELEGATE is true, that summary also says which tasks go to agents
   and which run in this conversation (see `./delegated-runs.md`).

5. **Pull at start**, per
   `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`
   § *Pull at start* — here that means once per invocation, before the
   first task's work begins, with each task's own re-sync happening right
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

The three `Target:` values and what each means at implementation time —
including announcing a `claude+human` task's checkpoints up front and
running a `human` task as a guided walkthrough — are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/targets.md`
§ *At implementation time*. If the target is `claude+human` or `human`,
read `./human-in-loop.md` now and follow it for the rest of this task; it
carries a gate that decides whether the manual checkpoints can be driven
through Unity MCP (reading `./unity-mcp-checkpoints.md` only when
eligible) — do not check for MCP yourself here; let that file's gate
handle it.

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

### Review rounds   [only when REVIEW is true]

If REVIEW is false — the default — there is nothing here; go straight to
Step 6.

Otherwise run the review/iterate loop from `./review-rounds.md`, which was
read before the first task, on this task's still-uncommitted tree: spawn
`/task-review` as a subagent, **wait for its findings to arrive** (the
Agent call returns an id, not the report), run `/task-iterate` in this
session telling it not to commit, and repeat while `BLOCKING` findings
remain and rounds are left, up to ROUNDS. Do not reach Step 6 or Step 7
until the final round's reviewer result has actually arrived.

Unresolved `BLOCKING` findings after the last round stop the run per
FAILURE HANDLING: the tree stays uncommitted and this task stays
`[IN PROGRESS]`.

### Step 6 — Mark DONE (or other terminal status)

Use the Edit tool to update this task's `Status:` line in
`.claude/TASKS.md`. Which terminal statuses this skill may write, and
when, is
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/status.md` —
its `/task-implement` note carries this skill's half: it is the only
consumer that writes `[IN PROGRESS]` and `[DONE]`, `[PARTIAL]` is used
only for a sub-requirement discovered during implementation that belongs
in a separate task (surface it to the user before choosing that status),
and `[INCORRECT]` never appears on a fresh implementation.

The default is `[DONE]`.

If this task's TASKS.md summary block carries a `Feature: <slug>` line and
the status just written is `[DONE]`, apply the FEATURE COMPLETION check
below before moving to Step 7.

### Step 7 — Commit and push   [skipped in --no-commit mode]

Commit and push gating — the flags, staging by explicit path, how many
commits a unit of work produces, the push protocol, and what to do when a
commit or a push fails — is
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`.
Its `/task-implement` note carries this skill's own specifics: one commit
and one push per task immediately after that task's commit, the commit
message format and its skip-tests parenthetical, exactly what this step
stages, the fold when DIRTY_FOLD is true, both deliberate departures from
the one-commit rule — the `--review` loop's fixes and the FEATURE
COMPLETION flip — and why a push failure here is not an ordinary failure.

If NO_COMMIT is true, do not commit (or push) this task. Leave all files
modified by this task — including the `.claude/TASKS.md` status flip —
uncommitted in the working tree, and move on to the next task (or the
final report). The changes from each task accumulate uncommitted across
the run; the final report reminds the user that nothing was committed.
Skip the rest of this step.

Otherwise (the default), stage this task's own paths, commit once, report
the resulting hash, and — unless NO_PUSH is true — re-sync and push, all
per `commit.md`. DIRTY_FOLD, set by the dirty-tree check, is what decides
whether the pre-existing dirty changes are folded in here; the fold itself
is `tree.md` § *Folding in Step 7*.

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
   Otherwise (the default): run the dirty-tree check again, exactly as
   PRE-FLIGHT CHECKS step 1 did, per `tree.md`. A non-empty result is
   unusual here — the previous task's Step 7 should have committed
   everything it changed — and DIRTY_FOLD set there applies to the
   upcoming task's Step 7.
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
alongside the run's other uncommitted changes, same as Step 7. Otherwise,
if at least one slug was approved, this flip gets its own commit and push —
the second of the two deliberate departures from the one-commit rule that
`commit.md`'s `/task-implement` note records, with the message form it
gives there. Nothing else in the entry changes and no per-task commit is
touched.

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

Unresolved `BLOCKING` findings at the end of a `--review` loop are an
ordinary case of this: the task never reaches Step 6, so its status stays
`[IN PROGRESS]`, its tree stays uncommitted, and the run stops with the
findings reported by id. See `./review-rounds.md`.

A Step 7 push failure or pre-push conflict is a distinct case, and
`commit.md`'s `/task-implement` note is where that distinction is drawn:
the commit already succeeded, so nothing is reverted and no status is
flipped back. Stop the entire run the same way, and report that this
task's commit exists locally and needs a manual sync + push before
resuming with the remaining tasks.

DO NOT:
- Weaken a test to make it pass.
- Bundle multiple tasks into one commit — `commit.md` § *One commit per
  unit of work*.
- Stage with `git add -A`, `git add .`, or `git add -u` outside the
  sanctioned dirty-tree fold, or use any hook-skipping or
  history-rewriting flag — `commit.md` § *Staging* and § *One commit per
  unit of work* forbid both.
- Run destructive git operations (`reset --hard`, `clean -f`,
  `checkout .`) without the user's explicit instruction.
- Continue past a failing test with a "todo: fix later" comment.
- Skip the full-suite run at the end of a task in full test mode.
- Auto-scaffold a test suite without the user explicitly choosing
  option A of `./no-test-suite.md`.
- Proceed past a manual-intervention checkpoint on the user's word alone
  when the outcome is checkable, or make production edits on a
  `Target: human` task — `targets.md` § *At implementation time* forbids
  both.
- Start a `[STALE]` task without the user explicitly choosing to implement
  it anyway, or pick one up in an `all` / `next` run — `stale.md`.
- Write a `Feature:` line into any task. It is `/task-add`'s field; this
  skill only reads it.
- Spawn delegated agents in parallel, or spawn the next one before the
  previous has returned — the tasks share one working tree and branch.
- Delegate a `claude+human` / `human` / `[STALE]` task to an agent —
  `targets.md` § *The delegation guard* — or offer delegation at all on a
  run resolving to fewer than 2 tasks.
- Open `.claude/tasks/<N>.md` in the parent for a task that is being
  delegated — not to size the work, not to write the hand-off prompt, not
  after the agent returns. The guard's three fields come from `TASKS.md`;
  the body belongs to the agent.
- Force-push, retry a failed push, defer a task's push to end-of-run, or
  push unless `--no-push`/`--no-commit` was passed — `commit.md`
  § *The push protocol* and its `/task-implement` note.
- Propose a `[DONE]` feature flip mid-run, or per-task — FEATURE COMPLETION
  proposals are batched to the very end of the run, always.
- Flip a `FEATURES.md` `Status:` to `[DONE]` without the user naming that
  slug in response to the proposal, or flip any status other than
  `[PLANNED]` → `[DONE]` there.
- Make a separate commit for a `--review` round's fixes, or let
  `/task-iterate` commit or push inside a round — `commit.md`'s
  `/task-implement` note is where that rule lives, and it is the one a
  later editor is most likely to "fix" into symmetry.
- Treat the review subagent's Agent call as though it returned the findings,
  or reach Step 6 or Step 7 before the round's reviewer result has actually
  arrived. The call returns an id; the report arrives later, separately.
- Run the review in this session instead of a subagent — fresh context is
  the mechanism, not a detail.
- Accept `--rounds` without `--review`, or skip the review silently when
  either `task-review` or `task-iterate` is unavailable.
