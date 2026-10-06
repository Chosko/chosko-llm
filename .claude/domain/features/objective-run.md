# Objective run

`/objective-run "<objective>"` works toward one stated objective in rounds
until it is met or a limit is reached: it first turns the objective into
checkable success criteria, then each round a fresh worker does one piece of
work and commits, and a fresh checker marks every criterion met or not met
with evidence. A committed progress log records every round, so a run
survives the session that started it and resumes where it stopped.

## Purpose

Some work is not a task list but an outcome — "the importer handles every
fixture", "the docs build with no warnings" — where the next piece of work
is only clear once the last one has landed. Doing that by hand means a
person re-reading the state and choosing the next step each time; doing it
in one long session means a context that fills with every attempt. Running
it as rounds of fresh subagents, judged against criteria fixed up front,
gives the person an unattended loop with a clear stopping rule and an
auditable record.

## Scope and non-goals

In scope: the command and its limits; criteria definition; the worker and
checker rounds; the progress log and resuming; parking; the documentation
follow-ups.

Deliberately out:

- **A Stop hook** (`objective-guard` or any other) enforcing the time cap.
  The cap is checked by the run itself, between rounds.
- **`--for`** as the time flag; it is `--max-time`.
- **Area splitting under orchestrate-mode.** Each round already delegates;
  the run does not split rounds into areas.
- **Editing documentation as it goes.** Documentation that lags is recorded
  and proposed as follow-ups, not edited by the run.
- **A backlog entry.** Objective runs are not tasks; no `TASKS.md` write.

## Architecture

Built on the repo's existing shape per `technical-direction.md`: a markdown
skill whose runtime is Claude Code and its subagent spawning.
`skills/objective-run/` holds `SKILL.md` and a reference for the log
schema. It reuses `/runbook-run`'s subagent contract and parking, and the
review-round loop shape of `/task-implement --review`, by citation.

### Criteria — the only gate

The run starts by turning the objective into a short list of checkable
success criteria, each with how it is checked. That list is the run's one
gate: shown as a plain summary per the interaction policy, and passing on
its own (class 1) when the objective is already clear enough that the
criteria add nothing a reader would dispute. A criterion that needs a
decision from the user parks in the run's log under `unattended` — the run
has its own parking (below) — and waits for the user under `attended`.

### Rounds

Each round:

1. **Worker** — a fresh subagent, briefed with the objective, the criteria
   and their latest verdicts, and the log's round summaries, does one piece
   of work toward an unmet criterion and commits it. Its brief carries
   `/runbook-run`'s operating rules (the `DONE` line, the spawn relay, the
   commit report).
2. **Checker** — a fresh subagent marks each criterion met or not met,
   with evidence (a command's output, a file, a test name). It edits
   nothing.
3. **Log** — the round's entry and the criteria verdicts are written to the
   log and committed.

The loop is the review-round shape: work, independent check, decide whether
another round is warranted.

### Stopping

The run stops when:

- every criterion is met;
- `--max-time` has passed — checked with `date` between rounds; a round
  that has started always finishes;
- `--max-rounds N` consecutive rounds made no progress — no criterion moved
  from not met to met; `N` is 3 when the flag is not passed.

The stop reason is written to the log.

### Questions

A worker that needs a decision parks it: the question is recorded in the
log's parked list, verbatim with its options, that piece of work is set
aside, and the next round picks other work. Parking is the run's own
mechanism, following `/runbook-run`'s step parking — the log is the store,
as the runbook body is for a step. Under every policy the closing report
asks the parked questions together, last, in plain language; an answer
given on resume unparks them.

### Documentation follow-ups

The log has a *Docs to update* section, filled as changes land with the
documents and sections each round's change made stale. The closing report
proposes them as follow-ups: `/architect amend` where a design changed,
`/pipeline-revise --catch-up` for editorial catch-up.

### Resuming

`/objective-run <id>` with no objective resumes the log with that id: it
re-reads the criteria, verdicts and parked questions, and starts the next
round. A finished or stopped log reports its outcome and starts nothing.

## Data and state

- **Progress log** — `.claude/objectives/<id>.md`, `<id>` being
  `<YYYY-MM-DD>-<slug>`. Holds: the objective; the criteria, each with its
  check and latest verdict and evidence; the limits and the start time; one
  entry per round (the worker's commit and summary, the checker's verdicts);
  parked questions; *Docs to update*; the status — running, done, or
  stopped with its reason. Committed every round; the source of truth for
  the run.
- **Commits** — one per worker round, one log commit per round.
- **In memory only:** the elapsed-time reading, the no-progress count
  (re-derived from the log on resume).

## Interfaces and contracts

```
/objective-run "<objective>" [--max-time <duration>] [--max-rounds <N, default 3>]
/objective-run <id>          resume an unfinished run
```

Failure contract: a worker that fails to commit, or a checker that cannot
produce a verdict, ends the round as no progress and is recorded; a failed
log commit stops the run; an unknown `<id>` names the existing logs and
stops; a malformed duration is an argument error.

## Dependencies

- [interaction-policy](./interaction-policy.md) — the criteria gate's
  class, the report and question rules; objective runs are one of the
  parking mechanisms that policy names.
- [runbook-suite](./runbook-suite.md) and
  [unattended-parking](./unattended-parking.md) — the subagent contract and
  the step parking the run reuses.
- [task-peer-review](./task-peer-review.md) — the review-round loop shape.
- [quick-implement](./quick-implement.md) — `/pipeline-revise --catch-up`,
  the editorial follow-up the report proposes.
- [orchestrate-mode](./orchestrate-mode.md) — the exemption from area
  splitting.

