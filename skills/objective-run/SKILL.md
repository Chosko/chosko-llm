---
name: objective-run
version: 0.1.0
type: skill
description: Work toward one stated objective in rounds — checkable success criteria first, then each round a fresh worker subagent does one piece of work and commits and a fresh checker marks every criterion met or not met with evidence — until all are met or a time or no-progress limit stops it, recorded in a committed log a later session resumes. Use it for an outcome, not a task list.
requires: skill:interaction-engine, skill:runbook-run
---

# /objective-run
# Global skill: turn one objective into checkable criteria (the run's one
# gate), then loop — worker subagent, checker subagent, log commit — until
# every criterion is met, --max-time has passed, or --max-rounds consecutive
# rounds made no progress. A worker's question is parked in the log and the
# next round picks other work. The log at .claude/objectives/<id>.md lets a
# later session resume a running run and collects the documentation the run
# made stale, which the closing report proposes as follow-ups.
# Usage: /objective-run "<objective>" [--max-time <duration>] [--max-rounds <N>]
#        /objective-run <id>                       (resume a running run)
#        /objective-run <args> --attended | --unattended
# Examples: /objective-run "the importer passes every fixture under tests/fixtures/"
#           /objective-run "the docs build with no warnings" --max-time 2h
#           /objective-run "the CLI help matches docs/reference.md" --max-rounds 5
#           /objective-run 2026-10-07-importer-passes-every-fixture

GOAL
Reach the objective with fresh contexts doing the work, an independent check
judging it against criteria fixed up front, and a committed record of every
round:

1. Parse the arguments and check the tree.
2. Draft the criteria and pass the gate — or, on resume, re-read the log.
3. Run rounds until a stop condition holds.
4. Give the closing report.

---

SUPPORTING FILES (read on demand)

| Read this file | Exactly when |
| -------------- | ------------ |
| `./references/log-schema.md` | Every run, before the log is first written or re-read. |
| `../interaction-engine/references/policy.md` | Every run, at ARGUMENTS. |
| `../interaction-engine/references/messages.md` | Every run, before the gate or the first question. |
| `../interaction-engine/references/gates.md` | The policy resolved to `unattended`. |
| `../runbook-run/references/subagent-contract.md` | Each time a worker, a checker or a relay child is spawned. |
| `../runbook-run/references/parking.md` | The run parks or unparks a question. |

---

ARGUMENTS

Strip these, in any position:

- `--max-time <duration>` — a positive whole number of minutes or hours,
  `45m`, `2h`, or both, `1h30m`. Anything else stops with
  `--max-time needs a duration such as 45m, 2h or 1h30m.` Without it the run
  has no time limit.
- `--max-rounds <N>` — a positive integer, default 3: the run stops after
  `N` consecutive rounds without progress. Anything else stops with
  `--max-rounds needs a positive integer.`
- `--attended` / `--unattended` — the interaction policy, resolved per
  `../interaction-engine/references/policy.md`, which holds their argument
  errors.

What is left is either an id or an objective. A single token shaped
`<YYYY-MM-DD>-<slug>` is an **id**: a log at
`.claude/objectives/<id>.md` resumes (RESUME); with none, stop, naming the
logs that exist under `.claude/objectives/` (or saying there are none) and
`/objective-run "<objective>"` to start one. A resume beside `--max-time` or
`--max-rounds` stops with `A resumed run uses the limits in its log — drop
--max-time and --max-rounds.` Anything else is the **objective**, in the
user's words; an empty one stops with
`State the objective: /objective-run "<objective>".`

There is no `--no-commit` and no `--no-push`: a log that is not committed and
pushed cannot be resumed from another session.

Record the invocation's start with `date +%s` once parsing succeeds; it is
what `--max-time` counts from, on a new run and on a resume alike.

---

THE TREE

Run `git status --porcelain` once and hold the paths it lists as
**pre-existing**. They are not the run's: every commit the run makes stages
by explicit path, and each worker's brief names them as paths it must not
touch or stage. A worker whose skill puts the dirty-tree prompt over them
parks it, as OPERATING RULES direct; a clean tree at the start avoids that.
Then pull, per step 1 of `/runbook-run`'s commit-and-push
protocol (its COMMIT CADENCE); a conflict stops the run there.

---

THE CRITERIA — THE RUN'S ONE GATE

On a new run, before any work:

1. Ground the objective: read the project's `CLAUDE.md` and the navigation
   files it points to for the area the objective names, then only the source
   needed to make each criterion concrete.
2. Draft a short list of criteria — usually two to six — each one checkable
   statement with its `Check:`: a command and what its output must show, a
   file and what it must contain, a test name that must pass. A reviewer must
   be able to mark each met or not met without judgement.
3. A criterion that cannot be settled without a decision from the user
   carries that question, labelled `Q1`, `Q2`, …, its options `a`, `b`, …,
   and a recommendation.
4. Show the gate: a plain summary per
   `../interaction-engine/references/messages.md` § *Output* — the objective
   in one line, each criterion with its check in one line, the limits — and
   end with any criterion questions, then **"Start the run?"** A `show` reply
   prints the full draft.

Gate class: `confirmation` (`../interaction-engine/references/gates.md`).
Under `attended` it waits for an explicit approval; silence is not approval,
a change asked for is applied and the gate shown again, a refusal writes
nothing, and the criterion questions are answered here. Under `unattended` it
passes on its own: each criterion question becomes a parked question
(QUESTIONS AND PARKING) and its criterion is marked `Parked:`.

Then write the log per `./references/log-schema.md` — `Status: running`, the
limits, the criteria `unchecked` — commit it as `Objective <id>: start`,
staging only the log, and push (COMMITS). Under `unattended`, print the gate's
summary now, naming that commit.

---

THE ROUNDS

Before each round, check the stop conditions in order; the first that holds
ends the loop:

1. **Every criterion is met** → `Status: done`.
2. **`--max-time` has passed** — `date +%s` minus the invocation's start
   exceeds the limit → `Status: stopped: max-time <duration> passed`. A round
   that has started always finishes; the check runs only between rounds.
3. **`N` consecutive rounds made no progress** →
   `Status: stopped: <N> rounds without progress`.
4. **Every unmet criterion waits on a parked question** → the loop ends with
   `Status: running` unchanged: there is nothing to work on until an answer
   comes, and `/objective-run <id>` resumes once one does.

A stop writes its status to the log, committed as `Objective <id>: <done |
stopped>` (COMMITS). Then the closing report.

Each round has three parts. Its shape is that of `/task-implement --review`'s
review rounds — work, an independent check, a decision whether another round
is warranted — and the loop stated here is the whole of this run's.

### 1. The worker

Spawn a fresh subagent. Its prompt, in this order:

- **Preamble.** Read the project's `CLAUDE.md` and follow its navigation
  instructions as written — each layer's index, then only the files this work
  needs. Name the run (`objective <id>`) and the round. State
  *This run is unattended: a question about the work parks this round's work,
  and a skill you invoke reads it as unattended too.* — under every policy,
  because a worker's question is parked under every policy.
- **The objective**, verbatim, and **the criteria** with their latest
  verdicts and evidence, from the log.
- **The rounds so far** — each round's `Worker:` and `Checker:` lines from
  the log, nothing more.
- **Set aside** — the parked questions and the criteria they hold up: not to
  be worked on or worked around.
- **Context** — for each answered question, a bullet
  `- <date> unparked with answer: <the answer>` beside the question it
  answers, the form OPERATING RULES read as the answer to a question an
  invoked skill asks again.
- **Not yours** — the pre-existing paths and any `Left uncommitted:` paths of
  earlier rounds: never touched, never staged.
- **The task.** Do one piece of work toward one unmet criterion that is not
  parked, and commit it by explicit path. Edit no documentation; instead add
  a line `Docs to update:` to the report naming each document and section the
  change made stale, or `none`.
- **OPERATING RULES**, verbatim from
  `../runbook-run/references/subagent-contract.md`, last, with `<RUNBOOK>` as
  `objective-<id>`, `<N>` as the round number and `<FILE>` as the log path.

Wait for its result — the spawn returns an id, never the result. Classify the
returned turn on its marker:

- **`DONE` naming a commit** — the round goes on to the checker. Append the
  report's `Docs to update:` passages to the log's *Docs to update*.
- **`SPAWN REQUEST`** — spawn the child, classify its turn and reply to the
  same worker as `/runbook-run`'s THE SPAWN RELAY does, one child at a time
  with `RELAY CHILD RULES` ahead of OPERATING RULES, then classify the
  worker's next turn here. A relay child that reports failure or misses its
  result file twice, or a request past that section's round cap, ends the
  round instead: `no progress`, recorded `failed — relay: <reason>`, the
  worker not resumed.
- **`QUESTIONS FOR USER`** — park it (QUESTIONS AND PARKING). The round is
  `no progress` and its checker is skipped.
- **Anything else** — a `DONE` with no commit, a reported failure, an
  unmarked turn — the round is `no progress`, its checker skipped and the
  worker's reason recorded as `failed — <reason>`.

After every worker, run `git status --porcelain`: paths dirty now that were
not before are the worker's leftovers, recorded on the round's
`Left uncommitted:` line and never discarded.

### 2. The checker

Spawn a fresh subagent that edits nothing. Its prompt: the same preamble; the
objective; every criterion with its `Check:`; the round's worker commit(s);
the instruction to run every criterion's check — parked ones included — and
return one line per criterion, `C<n>: met|not met — <evidence>`, the
evidence a command's output, a `file:line` or a test name; then OPERATING
RULES as for the worker.

Wait for its result. Each criterion it gave a verdict replaces that
criterion's `Verdict:`. A checker that returns no verdict line at all — a
failure, a question, an unmarked turn — leaves every verdict as it was and
the round `no progress`; a criterion it skipped keeps its old verdict.

### 3. The log

Write the round's entry and the new verdicts per
`./references/log-schema.md`, mark it `progress` when at least one criterion
moved from not met or unchecked to met, and `no progress` otherwise, commit it as `Objective <id>: round <k>`, staging only the log, and push
(COMMITS). Then read any chat message that arrived during the round
(QUESTIONS AND PARKING) and check the stop conditions again.

---

QUESTIONS AND PARKING

A worker's question is parked under every policy, and so is a criterion
question at an unattended gate. The log is the store, as the runbook body is
for a step; the handles, the chat block and the unpark follow `/runbook-run`'s
step parking, `../runbook-run/references/parking.md`:

- **Park.** Add the question to the log's *Parked questions*, verbatim with
  its options and recommendation, under the run's next `P<n>` handle, and
  mark the criterion it holds up `Parked: P<n>`. Print it in chat in that
  file's block form — one plain lead line saying what stopped and why, the
  question last. The work is set aside: the next round picks other work.
- **Answer.** A chat reply by a handle printed this run, read between
  rounds, unparks it: write the `Answer:` line, clear the criterion's
  `Parked:`, and commit as `Objective <id>: unpark P<n>`. The next worker's
  brief carries the answer with the criterion. The rejections are that
  file's § *The rejections*.
- **On resume** — parked questions without an answer are asked together
  before the first round under `attended`, and each answer unparks as above;
  under `unattended` they are printed in one block and the rounds go on,
  every one still answerable by its handle.

---

RESUME

`/objective-run <id>` re-reads the log: the objective, the criteria and their
verdicts, the limits, the parked questions and the rounds. The no-progress
count is the number of consecutive `no progress` rounds at the end of
`## Rounds`.

- `Status: done` or `stopped: …` — report the outcome, the round count and
  the criteria met, and start nothing.
- `Status: running` — run THE TREE, ask or print the parked questions
  (QUESTIONS AND PARKING), then continue THE ROUNDS with the next round
  number.

---

COMMITS

- One commit per worker round — the worker's own.
- One log commit per round, plus `start`, each unpark and the final status,
  each staging only the log, by explicit path.
- Each log commit is pushed per `/runbook-run`'s commit-and-push protocol
  (COMMIT CADENCE): pre-push re-sync, push, never a retry or a force-push;
  under a `CLAUDE.md` `## VCS` override, only the commit runs.
- **A log commit that fails stops the run** at once, the log left as written,
  with the failure output. A push that fails or conflicts stops the run the
  same way: the commit exists locally and needs a manual sync and push before
  `/objective-run <id>` resumes.

The run writes nothing outside the log: no `TASKS.md`, no `FEATURES.md`, no
documentation.

---

THE CLOSING REPORT

The run's last act, at every end — done, stopped, waiting on answers, or a
failure — per `../interaction-engine/references/messages.md`: the outcome and
its reason, the rounds run, the criteria met out of the total, the log's id
and any commit that matters to the reader. Then two groups:

- **For the record** — one line per item, `<what deviated> — <why> —
  <resolved by whom>`: a criterion question parked at an unattended gate, a
  worker's leftovers, a regression a checker saw (met to not met). `none`
  when empty.
- **Follow-ups** — one numbered list, the numbers the reply handle:
  - for each *Docs to update* passage in a feature document whose design the
    run changed, `/architect amend feature=<slug> "<the change>"`, naming the
    passages;
  - for the rest of *Docs to update*, one `/pipeline-revise --catch-up
    "<what landed>"`;
  - when the run is still `running`, `/objective-run <id>` to resume it;
  - **last**, every unanswered parked question together, under its `P<n>`
    handle, in plain language per § *Questions*, verbatim with its options —
    a reply by the handle is recorded as an answer while the session is open.
