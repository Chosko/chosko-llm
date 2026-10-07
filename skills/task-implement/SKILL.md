---
name: task-implement
version: 1.13.0
type: skill
description: Implement one or more tasks from the project's backlog end-to-end — tests first, status flipped in TASKS.md, one commit and one push per task, with optional review rounds and per-task subagents; `--unattended` parks a task at a question instead of halting the run. Use it once a task is written; stage 6 of the pipeline: turns a task body into code, the last stage.
requires: skill:task-engine, skill:interaction-engine, command:follow-ups
---

# /task-implement
# Global skill: implement one or more tasks from the project's task backlog
# end-to-end, following a tests-first sequence, flipping each task's `Status:`
# in `TASKS.md` to `[IN PROGRESS]` and then `[DONE]`. Commits and pushes each
# task separately. No mid-flow confirmation prompts when tests exist; if the
# project has no test suite the flow becomes interactive. Honours a
# `Testing policy for /task-implement: skip-tests|full-tdd|skip-tests-unattended`
# marker in CLAUDE.md. On a dirty working tree prompts (proceed-uncommitted /
# fold-into-commit / commit-first / abort) instead of aborting. `next` and
# `all` pick a task only once every task its `Preconditions:` names is
# `[DONE]` or `[SKIP]`, and skip `[STALE]` tasks; a task named by number is
# never blocked, and a `[STALE]` one is warned about first. Target
# `claude+human` pauses at declared Manual interventions checkpoints, target
# `human` runs as a guided walkthrough; a checkpoint a connected tool can
# perform can be driven through that tool. On 2+
# tasks offers one fresh subagent per task, sequentially; under orchestrate
# mode delegates every run, one task included. Under `--review`
# each task is reviewed by `/task-review` in a subagent and corrected by
# `/task-iterate` before its single commit; unresolved `BLOCKING` findings
# after the last round stop the run with the task `[IN PROGRESS]`. When a
# `Feature:`-tagged task completes its feature, proposes flipping its
# `FEATURES.md` `Status:` from `[PLANNED]` to `[DONE]` once, at the end of
# the run, and flips it unasked under `unattended`. Under the `unattended`
# interaction policy — `--unattended`, a policy handed down, or the
# `CLAUDE.md` line; `--attended` overrides it — a question about the work
# parks the task (`[PARKED]`, its
# work-in-progress on `park/task-<N>`) and the run continues; the run's
# `[PARKED]` tasks are pre-asked at launch unless `--skip-parked`, and a
# parked question is answered by its `P<n>` handle in chat. Every run ends with one
# closing report — For the record, then one Follow-ups list whose numbers are
# the reply handle and which applies `/follow-ups`' rules without invoking it.
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
#        /task-implement <args> --review --review-model <name>|same|auto   (reviewer's model; default auto)
#        /task-implement <args> --review --review-effort shallow|standard|deep|same|auto  (reviewer's read budget; default auto)
#        /task-implement <args> --unattended  (park a task at a question instead of halting; pre-ask the list's parked tasks first)
#        /task-implement <args> --unattended --skip-parked  (no pre-ask; a parked task with no answer is skipped)
#        /task-implement <args> --attended    (every gate waits, whatever CLAUDE.md says)
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
#           /task-implement 12 --review --review-model sonnet
#           /task-implement 12 --review --review-model same
#           /task-implement all --review --review-effort shallow
#           /task-implement all --unattended
#           /task-implement all --unattended --skip-parked

GOAL
For each requested task, in the order given:
1. Flip status to `[IN PROGRESS]`.
2. Update or write tests to encode the spec.
3. Implement the production change.
4. Run the affected tests and watch them pass.
5. Run the full test suite and watch it pass.
6. Flip status to `[DONE]` (or `[PARTIAL]` / `[INCORRECT]` if appropriate).
7. Commit and push — one commit (and push) per task, skipped under
   `--no-commit`, the push alone under `--no-push`.

Under `--review`, a review/iterate loop runs between steps 5 and 6, on the
uncommitted tree, so its fixes ride in the task's own single commit — see
`./review-rounds.md`.

Under UNATTENDED a question about the work parks the task instead of
halting the run — see PARKED TASKS.

A step that fails and cannot be resolved by fixing the code stops the whole
run — see FAILURE HANDLING. A completed task carrying a `Feature:` line may
make its feature a completion candidate — see FEATURE COMPLETION. However the
run ends, its last act is the closing report — see THE CLOSING REPORT and
CLOSING THE RUN.

$ARGUMENTS

---

SHARED RULES (the `task-engine`)

Eleven rules this skill shares with the rest of the `task-*` suite have
exactly one authority each, under
`../task-engine/references/`:
`resolution.md` (where the backlog lives and how a run resolves its task
list), `status.md` (the status vocabulary), `targets.md` (the `Target:`
values and the delegation guard), `stale.md` (`[STALE]`), `tree.md` (the
dirty-tree protocol), `commit.md` (commit and push gating),
`review-budget.md` (the review cost controls behind `--review-model` /
`--review-effort`), `testing-policy.md` (the testing-policy marker and how
the test runner is resolved), `tests-first.md` (the tests-first sequence,
Steps 2–5), `closing-report.md` (the closing report) and `parking.md` (task
parking under the `unattended` policy — read only on the condition
SUPPORTING FILES gives). Every one of them carries a `/task-implement` note
holding this skill's own departures.

The sections below cite those files where they apply and state only what is
this skill's own. `requires: skill:task-engine` in the frontmatter is what
guarantees they are installed.

---

SUPPORTING FILES (read on demand — not up front)

This skill's common path is the whole of SKILL.md plus the interaction
engine's `policy.md`, `messages.md` and `mode.md` and the task engine's
`testing-policy.md`, `tests-first.md` and `closing-report.md`: a clean
working tree, a project whose test command is already known, and numbered
`Target: claude` tasks.
Everything else below is loaded only when its branch actually applies.

| Read this file | Exactly when |
| -------------- | ------------ |
| `../interaction-engine/references/policy.md` | Every run, at ARGUMENT PARSING, to resolve the interaction policy. |
| `../interaction-engine/references/messages.md` | Every run, before its first question, gate or closing report. |
| `../interaction-engine/references/gates.md` | UNATTENDED is true (read at ARGUMENT PARSING). Never on an attended run. |
| `../task-engine/references/testing-policy.md` | Every run, at RESOLVING THE TEST RUNNER. |
| `../task-engine/references/tests-first.md` | Every task, at Step 2 (Step 3 when Steps 2, 4 and 5 are skipped). |
| `../task-engine/references/closing-report.md` | Every run, at THE CLOSING REPORT. |
| `../task-engine/references/test-runner.md` | Neither CLAUDE.md/README/`.claude/` nor a testing-policy marker names the test command, so you must infer it. |
| `../task-engine/references/no-test-suite.md` | The project has no test suite at all, OR CLAUDE.md declares `Testing policy for /task-implement: skip-tests`. |
| `./human-in-loop.md` | The current task's `Target:` is `claude+human` or `human`. |
| `./body-schemas.md`  | The task body does NOT match the current schema (Goal / Acceptance criteria / Decisions / Hints). |
| `../interaction-engine/references/mode.md` | Every run without `--no-agents`, at PRE-FLIGHT step 2b, to know whether orchestrate mode is on. |
| `./delegated-runs.md` | DELEGATE is true — the resolved list holds 2+ tasks and the user opted into per-task subagents (or passed `--agents`), or orchestrate mode is on (PRE-FLIGHT step 2b). Never otherwise on a single-task run, nor when the user declined or passed `--no-agents`. |
| `./review-rounds.md` | REVIEW is true — the run was invoked with `--review`. Read once, after ARGUMENT PARSING and before the first task. Never on a run without the flag. |
| `../task-engine/references/parking.md` | UNATTENDED is true (read at ARGUMENT PARSING, where its refusals apply), OR any task in the resolved list is `[PARKED]` (read at PRE-FLIGHT step 2). Never otherwise — an attended run that meets no parked task never opens it. |

Do not read a supporting file speculatively — if none of the conditions above
fires, the run never touches one.

Throughout this skill, Bash / PowerShell are only for running tests and git
commands.

---

ARGUMENT PARSING

Before resolving the task list, scan `$ARGUMENTS` for the flags below and
strip whichever appear; what is left is the task selector.

The `--commit`, `--no-commit` and `--no-push` flags, the mutual exclusion
of the first two, and everything they gate are
`../task-engine/references/commit.md`.
Here NO_COMMIT true means the run performs the full test sequence and the
`Status:` flips but skips the per-task commit in Step 7 (see that step and
BETWEEN TASKS); false — the default — commits each task separately. NO_PUSH
true skips the pull-at-start (PRE-FLIGHT step 5) and each task's re-sync/push
in Step 7 while every task still commits.

Also scan for the optional `-y` flag. If present, set AUTO_CONFIRM = true
and strip it. AUTO_CONFIRM only changes behavior in skip-tests mode (see
RESOLVING THE TEST RUNNER and
`../task-engine/references/no-test-suite.md`): it suppresses the
per-task "Proceed?" confirmation that mode would otherwise ask before each
task. It has no effect in full test mode, which never asks that prompt. A
`skip-tests-unattended` policy marker sets it for a whole run without the
flag — `testing-policy.md` step 0 — and `-y` passed as well is
redundant but harmless, never an error.

Also scan for the optional `--agents` / `--no-agents` pair and strip
whichever appears. They are mutually exclusive — if both appear, stop with:
`--agents and --no-agents cannot be combined. Pick one.` They pre-answer
PRE-FLIGHT step 2b's delegation question: `--agents` sets DELEGATE = true,
`--no-agents` sets DELEGATE = false, and either way that question is not
asked. With neither flag, DELEGATE is undecided here and step 2b resolves
it. `--agents` on a run that resolves to fewer than 2 tasks is accepted and
ignored — the run stays in-context, unless orchestrate mode is on (step
2b) — rather than being an error.

Also scan for the optional `--review` flag and the optional `--rounds N`
pair, and strip whichever appear:

- `--review` sets REVIEW = true. Default false. When it is true, read
  `./review-rounds.md` now — before the first task — and follow it for the
  rest of the run, starting with its availability gate.
- `--rounds N` sets ROUNDS = N, a positive integer; default 1. `--rounds`
  without `--review` stops the run with: `--rounds requires --review.` An
  `N` that is not a positive integer stops too:
  `--rounds needs a positive integer.`
- `--review-model <name>` sets REVIEW_MODEL; default `auto`. Its value is a
  model name or one of the two reserved words `same` and `auto`. **Any name
  is accepted verbatim** — there is no local allow-list, so a name this skill
  does not recognise is passed through to the Agent tool, which rejects a
  typo better than a hardcoded list that would refuse a model that works
  (`review-budget.md` § *Model names are not validated locally*).
  `--review-model` without `--review` stops the run with:
  `--review-model requires --review.`
- `--review-effort <level>` sets REVIEW_EFFORT; default `auto`. Legal values
  are exactly `shallow`, `standard`, `deep`, `same` and `auto`. Any other
  value stops the run with: `--review-effort must be one of: shallow,
  standard, deep, same, auto.` `--review-effort` without `--review` stops
  the run with: `--review-effort requires --review.`

Both `--review-*` flags are strings here and nothing more: what their values
mean, how `auto` resolves, and what each effort level permits the reviewer to
read are
`../task-engine/references/review-budget.md`,
which `./review-rounds.md` reads when REVIEW is true. Parsing resolves
neither, and this skill restates neither the `auto` tier table nor the read
budget anywhere — a second copy is a copy that will drift. With REVIEW false,
the default, neither value is ever resolved or used, `./review-rounds.md` is
never opened, no loop runs, nothing new is asked, and the output says nothing
about reviewing.

Also scan for the optional `--attended`, `--unattended` and `--skip-parked`
flags and strip whichever appear. The run's interaction policy resolves from
the first two, a policy handed down by the parent run and the project's
`CLAUDE.md`, per `../interaction-engine/references/policy.md`, which also
holds their argument errors; read `CLAUDE.md` here if it has not been read
yet. UNATTENDED is true when the policy resolves to `unattended`; under
`attended`, nothing in this skill changes.

`--skip-parked` sets SKIP_PARKED = true and suppresses PRE-FLIGHT step 2a's
pre-ask, for a launch no human sees — a routine, a scheduler, an
orchestrator that is itself a subagent; `--skip-parked` on a run whose
policy is not `unattended` stops the run with:
`--skip-parked requires --unattended.`

When UNATTENDED is true:

- read `../task-engine/references/parking.md` now and apply its
  § *Refusals* before anything else, to a policy that came from the flag
  or from the parent: `--unattended` beside `--no-commit` stops the run,
  and so does a project whose `CLAUDE.md` carries a `## VCS` override
  (`commit.md`) — the parking branch is the mechanism and there is no
  equivalent there — each with the one-line message that section gives. A
  policy from the `CLAUDE.md` line is never refused: the run goes on, and a
  question that would park stops it instead, per
  `../interaction-engine/references/gates.md` § *A run that does not
  commit*.
- read `../interaction-engine/references/gates.md`; the class tag on each
  of this skill's gates applies.
- every prompt this run can raise that has a default takes it when it goes
  unanswered — a contract the session runs under, such as a runbook step's
  OPERATING RULES, answers it first — per `parking.md` § *Prompts with a
  default*, each value taken being one *For the record* line; the one prompt with none, an ambiguous test runner,
  aborts the run (`testing-policy.md` step 2). Only a question about
  the work parks a task, and only inside the per-task workflow (PER-TASK
  WORKFLOW § *Parking at a question*).

After stripping the flags, `$ARGUMENTS` is a whitespace-separated list of
task numbers, the literal token `all`, or the literal token `next`. Those
three selectors — what each resolves to, the eligibility clause the batch
selectors honour, which statuses and which blocked tasks a batch selector
skips, the one-line resolution report each prints without asking for
confirmation, the naming of skipped stale tasks, and the empty-argument
stop — are
`../task-engine/references/resolution.md`
§ *Selectors*.

The human-intervention warning appended to an `all` / `next` resolution
report is
`../task-engine/references/targets.md`.

---

LOCATING THE BACKLOG

Backlog resolution follows
`../task-engine/references/resolution.md`,
whose `/task-implement` note carries every way this skill departs from it:
the wording of the not-initialised stop, that the selectors above are its
argument form, and the precondition re-check in BETWEEN TASKS step 2. Its § *Opening a per-task body file* is the rule that a
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
right files — not a checklist.

**Consequential edits are in scope.** An edit that only makes a passage
agree with a change already approved — by the task body, a user reply or a
gate — and changes no meaning beyond it is this task's to make, in whatever
file owns the passage, in this task's commit, whether or not the file is on
`Files:`; it is never asked about and never left as a follow-up, and it is
reported under *For the record* (THE CLOSING REPORT). That is how a Hint
naming a document another pipeline command owns is edited: for the design
change the body's `## Decisions` records as agreed and the points it records
as settled, every passage stating the old design is updated. A passage whose
update would introduce new meaning in an owned document stays untouched and
goes under *Follow-ups* as a precise follow-up — the command, the anchor and
the passages, `/architect amend feature=<slug> "<change>"` — never a vague
pointer at the owner.

If the body carries sections that do not match that schema — a `Context
bundle` / `Implementation steps` pair, or the older `Description` /
`Required reading` / `Out of scope` set — read `./body-schemas.md` for how
to treat it.

---

DOCUMENTATION-ONLY TASKS

In full test mode (a project with a real test suite, no skip-tests marker),
Steps 2, 4, and 5 normally run for every task. They are pointless for a task
that touches nothing but documentation, so Step 1 sets DOC_ONLY per task —
silently, with no confirmation prompt — from data already in hand at that
point: the `Files:` field noted in PRE-FLIGHT step 2 and the body just read.
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

When DOC_ONLY is true, Steps 2, 4, and 5 are skipped for this task exactly
as they are in skip-tests mode. In that mode they are already skipped for
every task, so the determination is moot there.

---

STALE TASKS

What `[STALE]` means, who sets and clears it, and the implement-anyway /
stop warning to put to the user before touching such a task — including
where the feature slug comes from and what each answer does — are
`../task-engine/references/stale.md`
§ *Implementing a stale task*. That protocol is this skill's own, quoted
there verbatim, and its `/task-implement` note carries the rest of this
skill's half: the choice is always the user's, and a stale task is never
delegated to a subagent.

Run it before reading anything else on a `[STALE]` task, and do not
continue unless the user explicitly chose to implement it anyway.

---

PARKED TASKS

What `[PARKED]` means, the one event that parks a task, the handoff and the
branch a park leaves behind, the park sequence, the unpark transaction, when
an unpark is attempted and the two refusals are
`../task-engine/references/parking.md`.
Its `/task-implement` note names the rest as this skill's own, and this body
is where each lives: the `--unattended` flag and UNATTENDED's resolution
(ARGUMENT PARSING), the pre-ask (PRE-FLIGHT step 2a), the park and the
unpark inside the workflow (PER-TASK WORKFLOW), the chat handle and the
in-memory answers (BETWEEN TASKS step 2a). On a delegated run the agent
parks and the launcher records the `[PARKED]` return — or, under attended,
relays the agent's question instead — per `./delegated-runs.md`.

Read it on the condition SUPPORTING FILES gives — never on an attended run
that meets no `[PARKED]` task.

---

RESOLVING THE TEST RUNNER

Before anything else, establish how tests run, per
`../task-engine/references/testing-policy.md` — the
`Testing policy for /task-implement:` marker first, then project
convention, then inference, then the no-test-suite branch, and which tests
count as affected. Its `/task-implement` note carries this skill's half.

---

PRE-FLIGHT CHECKS (before any task)

1. **Working-tree check.** Run the dirty-tree protocol from
   `../task-engine/references/tree.md`:
   `git status --porcelain` once, silent continuation on a clean tree, its
   prompt when the output is non-empty. It sets DIRTY_FOLD and
   DIRTY_FOLD_UNTRACKED, which Step 7 consumes, and may halt the run. That
   file's `/task-implement` note carries this skill's specifics — that the
   check runs twice (here and in BETWEEN TASKS), what `--no-commit` does to
   the second one, and that a delegated agent is handed the decision the
   parent already made and must not re-run the prompt.

2. Use the Read tool to open `.claude/TASKS.md`. Resolve the task list
   per ARGUMENT PARSING above. For each task to be implemented:
   - Confirm a summary block for that task ID exists in TASKS.md. An ID
     requested by number that has none is archived and terminal, per
     `resolution.md` § *The archive*. Stop the run before any task starts,
     without opening anything:

     > Task <N> is not in `.claude/TASKS.md` — it has been archived. Its
     > body would be at `.claude/tasks/archive/<N>.md`; ask to read it if
     > you want it. An archived task is not implemented again — follow-up
     > work is a new task (`/task-add`).

     Open that file only if the user then asks to read it, and never
     re-implement the task. `all` and `next` resolve from blocks that
     exist, so they never meet such an ID.
   - Confirm its status is implementable.
     `../task-engine/references/status.md`
     § *Implementable* is which statuses those are and what to do when a
     task requested explicitly by number carries another one — including
     the `[STALE]` hand-off to STALE TASKS above and the `[PARKED]` unpark
     of PARKED TASKS below. (For `all` and `next`, the other statuses are
     skipped — see ARGUMENT PARSING.) A `[PARKED]` task stays in the
     resolved list under either policy: whether an answerer exists is
     decided when it is reached (Step 1), after the pre-ask, and a task
     with none is skipped there with one line. If any resolved task is
     `[PARKED]`, read `../task-engine/references/parking.md` now.
   - Note its Files, Preconditions, and — when present — `Feature:`
     fields from the summary block. `Feature:` appears only on
     feature-derived tasks; its absence is normal.

   This is the one read of the summary blocks for the whole run, and it is
   what makes step 2b free: the three fields the delegation guard needs —
   `Target:`, `Status:` and `Feature:` — are all here. So nothing about
   delegation is decided by opening a body, and on a delegated run the
   parent opens `.claude/tasks/<N>.md` for a delegated task on no path ever
   — not to size the work, not to write the hand-off prompt, not after the
   agent returns (see `./delegated-runs.md`).

2a. **Pre-ask.** Only when UNATTENDED is true and SKIP_PARKED is false;
   otherwise skip this step — an attended run asks each parked task's
   question when it reaches the task (Step 1), after the user has seen the
   earlier tasks' outcomes. With no `[PARKED]` task in the resolved list,
   nothing is printed.

   Otherwise, after the resolution report, open the trailing `## Parking
   handoff` of each `[PARKED]` task's body — for its `Parked:` and
   `Question:` lines only, the body's one pre-flight read — and print one
   block, one item per parked task in list order, each under its handle:

   > Some tasks in this run stopped earlier on a question. Answer each by
   > its handle (`P1: Q1a, Q2b`), or `skip P2` / `skip all`:
   >
   > P1. Add the session timeout — stopped while implementing
   >     (task 42, parked 2026-09-23 at Step 3)
   >     <its `Question:`, verbatim and multi-line, options included>
   > P2. Add the login form — its draft waits for approval, which only a
   >     run you watch can give, with the draft in front of you; skip-only
   >     here (task 47, parked 2026-09-23 at the review round)

   Wait for a reply. Each answer is held in run memory for its task and fed
   to the unpark in Step 1 — nothing on disk changes, so a run that dies
   loses them and the next launch asks again. An `approval gate` item is
   listed skip-only, per `parking.md` § *The unpark transaction*; an answer
   to one is rejected with one line and records nothing. Silence, EOF or an
   unrelated reply is `skip all` — the value `--skip-parked` gives. Nothing
   parks here: a pre-flight prompt has no current task.

   The `P<n>` handles are the run's question handles, one sequence for the
   whole run: a task parked later in this run takes the next unused handle,
   and BETWEEN TASKS reads replies against them. Any reply that names the
   handle and leaves no doubt which answer goes to which `Q<n>` is accepted
   (`parking.md` § *The one event that parks*).

2b. **Delegation check.** If `--no-agents` was passed, DELEGATE is
   already false; don't ask. Otherwise, when orchestrate mode is on — the
   check in `../interaction-engine/references/mode.md` — DELEGATE is true
   for any resolved list, a single task included, and nothing is asked.

   With the mode off, this step runs only when the resolved list holds 2 or
   more tasks. With fewer than 2, DELEGATE is false, nothing is asked and
   the run stays in-context — skip the rest of this step.

   If `--agents` was passed, DELEGATE is already set; don't ask. Otherwise
   ask once:

   > This run covers <k> tasks. Implement each one in a fresh subagent, so
   > later tasks don't inherit the context of earlier ones? Agents run one
   > after another, never in parallel.
   >
   > A. **Yes** — one agent per task, sequentially.
   > B. **No** — implement everything in this conversation.

   Wait for an explicit answer. Silence, an unclear reply, or EOF means
   B — in-context. Do not treat a non-answer as approval.

   If DELEGATE is true, read `./delegated-runs.md` now and follow it for
   the rest of the run. Which tasks may never be handed to a subagent is
   the delegation guard in
   `../task-engine/references/targets.md`;
   `./delegated-runs.md` governs how the resulting split is announced and
   executed, what the fixed-size agent prompt carries, and what each agent
   returns.

3. If the project has a CLAUDE.md, read it — it's small and global.
   Defer reading the broader `.claude/context/` and `.claude/domain/`
   layers until per-task Step 1 indicates a need (see USING THE TASK
   BODY). Don't assume any of these exist.

4. Briefly tell the user what you're about to do — one line per task —
   then start. When DELEGATE is true, that summary also says which tasks
   go to agents and which run in this conversation (see
   `./delegated-runs.md`).

5. **Pull at start**, per
   `../task-engine/references/commit.md`
   § *Pull at start* — here that means once per invocation, before the
   first task's work begins, with each task's own re-sync happening right
   before that task's push (Step 7).

---

PER-TASK WORKFLOW

For each task, in order.

When DELEGATE is true, this workflow is what each spawned agent performs
for its one task — the parent runs it directly only for the tasks
`./delegated-runs.md` keeps in the parent (`claude+human`, `human`, and
explicitly requested `[STALE]` tasks). The steps are identical either way,
so the delegated flow and the manual flow cannot drift apart, and Step 1's
body read happens in whichever session is implementing the task, never in
both.

### Parking at a question   [only when UNATTENDED is true]

A question about the work — an acceptance criterion this task cannot settle
from the body and the codebase, a `--review` round's approval gate — is put
to the user under attended, and the run waits; a delegated agent puts it to
its launcher under `QUESTIONS FOR USER`, and the launcher relays it
(`./delegated-runs.md` § *The question relay*). Under UNATTENDED it parks the
task instead: run the park sequence from `parking.md`, the step reached
being the one the handoff's `Parked:` names, the question recorded verbatim
there and printed in chat under the next `P<n>` handle (PRE-FLIGHT step
2a). The base tree is clean afterwards, so go to BETWEEN TASKS as if the
task had committed, and continue with the next task.

### Step 1 — Mark IN PROGRESS

If this task's status is `[STALE]`, run the STALE TASKS protocol before
reading anything else.

If this task's status is `[PARKED]`, decide the answerer first, per
`parking.md` § *The answerer rule*: an attended session, or an answer held
for this task from the pre-ask or a chat reply (BETWEEN TASKS). With none —
which only an UNATTENDED run can meet — skip the task with that section's
one line and go to BETWEEN TASKS: no branch is touched and no commit is
made. A held `skip` is the same skip. With an answerer, run the unpark
transaction from `parking.md`; once it succeeds, read the body as below,
flip the status as below, remove the `## Parking handoff` section from the
body, and continue this workflow at the step `Parked:` names, the answer in
hand — both edits ride in Step 7's commit, which stages the body file on
this one path (`commit.md`). A cherry-pick conflict follows `parking.md`
§ *The unpark transaction*: under UNATTENDED the task stays `[PARKED]` and
is skipped after the bookkeeping commit; under attended the run halts and
asks how to merge.

Use the Read tool to open `.claude/tasks/<N>.md` for the current task.
Hold its contents in mind for the rest of the per-task workflow.

The three `Target:` values and what each means at implementation time —
including announcing a `claude+human` task's checkpoints up front and
running a `human` task as a guided walkthrough — are
`../task-engine/references/targets.md`
§ *At implementation time*. If the target is `claude+human` or `human`,
read `./human-in-loop.md` now and follow it for the rest of this task; it
decides whether a tool connected this session drives a checkpoint.

Apply the body schema guidance from USING THE TASK BODY above, and
DOCUMENTATION-ONLY TASKS to set DOC_ONLY for this task.

Use the Edit tool to change this task's `Status:` line in
`.claude/TASKS.md` (the summary block) to `[IN PROGRESS]`. Do not
commit this change yet — it will be bundled into the task's commit.

### Steps 2–5 — Tests first, implement, run the suite

Follow `../task-engine/references/tests-first.md` for this task — Step 2
updates the tests, Step 3 implements, Step 4 runs the affected tests and
Step 5 the full suite, with Steps 2, 4 and 5 skipped as that file says. Its
`/task-implement` note says what the specification, the declared files and
"documentation-only" are here.

On a `claude+human` or `human` task, apply the checkpoint protocol from
`./human-in-loop.md` at each checkpoint's trigger point during Step 3.

### Review rounds   [only when REVIEW is true]

If REVIEW is false — the default — there is nothing here; go straight to
Step 6.

Otherwise run the review/iterate loop from `./review-rounds.md`, which was
read before the first task, on this task's still-uncommitted tree: spawn
`/task-review` as a subagent, **wait for its findings to arrive** (the
Agent call returns an id, not the report), run `/task-iterate` in this
session telling it not to commit, and repeat while `BLOCKING` findings
remain and rounds are left, up to ROUNDS. Do not reach Step 6 or Step 7
until the final round's reviewer result has actually arrived. Unresolved
`BLOCKING` findings after the last round stop the run — see FAILURE
HANDLING.

### Step 6 — Mark DONE (or other terminal status)

Use the Edit tool to update this task's `Status:` line in
`.claude/TASKS.md`. Which terminal statuses this skill may write, and
when, is
`../task-engine/references/status.md` —
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
`../task-engine/references/commit.md`.
Its `/task-implement` note carries this skill's own specifics: one commit
and one push per task immediately after that task's commit, the commit
message format and its skip-tests parenthetical, exactly what this step
stages, the fold when DIRTY_FOLD is true, both deliberate departures from
the one-commit rule — the `--review` loop's fixes and the FEATURE
COMPLETION flip — and why a push failure here is not an ordinary failure.

If NO_COMMIT is true, do not commit (or push) this task. Leave all files
modified by this task — including the `.claude/TASKS.md` status flip —
uncommitted in the working tree, and move on to the next task (or the
closing report); each task's changes accumulate uncommitted across the run.
Skip the rest of this step.

Otherwise (the default), stage this task's own paths, commit once, report
the resulting hash, and — unless NO_PUSH is true — re-sync and push, all
per `commit.md`. DIRTY_FOLD, set by the dirty-tree check, is what decides
whether the pre-existing dirty changes are folded in here; the fold itself
is `tree.md` § *Folding in Step 7*.

A task unparked from a branch ends with that branch's deletion, after this
step's commit and push — `parking.md` § *The unpark transaction*, step 4.

---

BETWEEN TASKS

When DELEGATE is true, `./delegated-runs.md` governs what happens between
tasks — it covers the same ground (re-read TASKS.md, chat answers, progress
line, skip-tests "Proceed?") plus verifying what the returning agent did.
Follow it instead of the list below for delegated tasks; a task the parent
implements itself follows the list as usual. Step 2a is the parent's under
either: the chat is the launcher's own, and an answered task's agent is
spawned next.

After committing — or, under UNATTENDED, parking or skipping — a task,
before starting the next:
1. Run the dirty-tree check again, exactly as PRE-FLIGHT CHECKS step 1 did,
   per `tree.md`; DIRTY_FOLD set there applies to the upcoming task's
   Step 7. **In --no-commit mode, skip this check entirely** — the previous
   task's changes are deliberately left uncommitted and will accumulate, so
   a non-empty `git status` is expected, not a surprise.
2. Use the Read tool to re-open `.claude/TASKS.md` fresh. Task IDs are
   stable so numbers will not have moved, but statuses or
   `Preconditions:` lines may have been edited by a parallel
   `/task-add` or `/task-clean` invocation — or a task earlier in this run
   may have landed `[PARTIAL]` rather than `[DONE]`. So on a run whose list
   was resolved by `all`, re-check the upcoming task's `Preconditions:`
   against this re-read, per clause 2 of `resolution.md` § *Eligibility*.
   If they no longer hold, skip the task with one line — "Skipping task 14
   — its preconditions no longer hold (waits on 12)." — and apply this step
   to the task after it. The re-check uses only the file this step already
   re-reads. An explicit-number list is never re-checked: a task requested
   by number is never blocked by a precondition.
2a. Read any chat message that arrived since the previous task started. A
   reply by `P<n>` handle to a question printed this run — at the pre-ask
   or at a park — or one naming that question's task, is the task's answer:
   record it in run memory and move the task to the front of the remaining
   list, so Step 1 unparks it next. Any other message is ordinary
   conversation, and the run continues. A reply naming a handle this run
   never printed, a second answer to a question already answered, or an
   answer to an `approval gate` item is rejected with one line and records
   nothing — the set is `parking.md` § *The answerer rule*'s, and the first
   answer wins. A pre-ask `skip` holds no answer, so a later reply by that
   number is the question's first.
3. Briefly report progress: "Task N committed. Starting task M." — or, for
   a task that did not commit, "Task N parked (question 3). Starting task
   M." / "Task N skipped — parked, no answer held. Starting task M."
4. In skip-tests mode, ask "Proceed?" before starting the next task,
   unless AUTO_CONFIRM is true or UNATTENDED is true —
   `../task-engine/references/no-test-suite.md`.
   Gate class: `confirmation`.

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
`Feature:` line. Only a `[PLANNED]` feature can become a candidate: one
whose `FEATURES.md` status is `[NEW]`, `[ITERATED]` or already `[DONE]`
never does — including a feature a human marked `[DONE]` by hand, which
they may do at any time, entirely outside this skill. This proposal is the
only place `/task-implement` itself writes that status, and it never
overwrites a status a human already set.

This check runs wherever a task's terminal status becomes visible to the
parent: at the end of Step 6 for a task the parent implemented itself, and
during the delegated-run "re-read TASKS.md" step (`./delegated-runs.md`) for
a task a subagent implemented. Either way it's the parent that accumulates
the candidate list across the whole run.

**A nested run never proposes** — under a delegated agent, or a runbook
step whose prompt ends with `OPERATING RULES`, the proposal belongs to the
outermost run. A runbook step names each candidate in its `DONE` report, one
line; a delegated agent names none — the launcher derives them from `TASKS.md`.

**Propose once, at the very end of the run** — after the last requested
task's Step 7 (or Step 6, under `--no-commit`), never mid-run even on a
many-task batch. If the candidate list is empty, say nothing about this at
all. Gate class: `confirmation` — under UNATTENDED the proposal passes on
its own: every candidate is approved, flipped and committed as below, and
the closing report names the commit. Otherwise, present every candidate
together:

> Every task of Password authentication is now done or skipped, so the
> feature itself is finished. Mark it done in the feature list?
> (password-auth, tasks 31–35)

or, with more than one candidate:

> Every task of these features is now done or skipped:
>
>   Password authentication (password-auth, tasks 31–35)
>   Session handling (session-handling, tasks 36–37)
>
> Mark them done in the feature list — all, none, or the ones you name?

Wait for an explicit answer; silence is not approval and leaves every
candidate `[PLANNED]`. A slug the user declines, or doesn't name, stays
`[PLANNED]` — mention that in the closing report, but don't ask again this
run.

For each slug the user approves, use the Edit tool to change that entry's
`Status:` line in `.claude/FEATURES.md` to `[DONE]`. Nothing else in the
entry changes and no per-task commit is touched.

If NO_COMMIT is true, leave the edited `.claude/FEATURES.md` uncommitted
alongside the run's other uncommitted changes, same as Step 7. Otherwise,
if at least one slug was approved, this flip gets its own commit and push —
the second of the two deliberate departures from the one-commit rule that
`commit.md`'s `/task-implement` note records, with the message form it
gives there.

---

THE CLOSING REPORT

Every run ends with one closing report — at completion, at a failure halt
and at a stop the user asked for alike. Its two groups, *For the record* and
*Follow-ups*, their shapes, the empty-group form and the numbering as the
reply handle are
`../task-engine/references/closing-report.md`;
its `/task-implement` note carries this skill's own items, the review-pair
line, the `P<n>` handles of parked tasks, the order after FEATURE
COMPLETION and how the report is rendered under `--agents`.

---

CLOSING THE RUN

**The closing report is the last thing a run does**, and its *Follow-ups*
group is where the `/follow-ups` command's rules are applied — **once per
run, never per task** — inside the report, not as a call after it. The
command is never invoked: its body is read by name and its rules applied to
the run's reading, so what they yield folds into one list with the run's own
items, under one numbering. What counts as a follow-up, what is excluded and
how an item is written are that body's alone, restated neither here nor in
`./delegated-runs.md`.

The report comes **after** the FEATURE COMPLETION proposal, never before.
That proposal can itself leave something unresolved — a slug the user
declined stays `[PLANNED]` — and a list drawn before it would miss exactly
that.

It is given at every point a run stops, not only at completion: after the
last task in the run, whatever the run resolved to (`<N>...`, `all`, `next`);
at a failure halt, per FAILURE HANDLING — including a `--review` loop that
ended with unresolved `BLOCKING` findings; and when the user asks to stop
between tasks. A single-task run is not a special case: the end of the one
task is the end of the run.

**Under `--agents`.** The parent's reading covers the per-agent result
reports it already collects — the six-field returns in `./delegated-runs.md`
— as well as its own conversation. It opens nothing new to do it. A
`[PARKED]` return is not a failure halt: the run goes on to its last task and
the report comes at the end as usual.

The fifth field is what makes that reading worth anything: before returning,
each agent reads the `/follow-ups` command's own body — given the command's
**name and never a path** — and applies its rules to its own session without
invoking it, handing back at most three items; where the command is
unavailable it skips the field silently instead of failing. Fold the lines it
does return into the *Follow-ups* group, attributed to the task they came
from. They are the agent's claim and the parent never saw the work, so pass
them through as stated — do not re-word them into a judgement the parent
cannot support, and do not drop one because it looks unlikely. Most tasks
return none; that is the field working, not failing.

The rest of the group still comes from the launcher's own conversation — the
delegation split, tasks skipped for unmet preconditions, failure lines,
declined feature slugs. When a listed follow-up that came from a delegated
agent is executed or planned, forwarding it to that same agent
is often the convenient thing to do, and is allowed. Judgement, not a rule —
this is not a new relay protocol.

**It changes no bookkeeping.** The report adds no commit and flips no status.
It is printed after every per-task commit and after any FEATURE COMPLETION
commit, so it never dirties a tree the run just cleaned and never touches the
one-commit-per-task rule.

**When `/follow-ups` is not installed, the group holds the run's own items
only, silently.** The frontmatter keeps `requires: command:follow-ups` — the
rules must be installed to be read — so the dependency helpers install it
alongside this skill; a user who removed it by hand gets no message and no
error. An absent optional rule set is not a run failure.

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
- Then give the closing report, its *Follow-ups* group included, per
  CLOSING THE RUN.

A failure inside a delegated task is not a special case: the parent stops
the run without spawning the next agent, and reports as `./delegated-runs.md`
§ *Failure* says.

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

A park that cannot make its branch — a leftover branch it cannot delete,
the push refused — is a Step 7 failure of that kind, per `parking.md` § *The park
sequence*: task `[IN PROGRESS]`, tree intact, run stopped. A parked task
is not a failure — in this conversation or as a delegated agent's
`[PARKED]` return, which the launcher records before spawning the next
agent — and neither is an unpark whose cherry-pick conflicts: it rolls
back, and Step 1 says what each policy does next.

DO NOT:
- Run destructive git operations (`reset --hard`, `clean -f`,
  `checkout .`) without the user's explicit instruction.
- Write a `Feature:` line into any task. It is `/task-add`'s field; this
  skill only reads it.
