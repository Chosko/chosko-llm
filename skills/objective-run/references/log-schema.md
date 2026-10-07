# The objective log

Authority for: where an objective run's log lives, how its id is formed, and
every section the log holds. Read by `/objective-run` whenever it writes or
re-reads a log. The run's behaviour — when each section is written and what
the run does with it — is `../SKILL.md`; this file describes the artifact.

---

## The store

```
.claude/objectives/<YYYY-MM-DD>-<slug>.md
```

Committed every round; the log is the source of truth for the run.

The file name without `.md` is the run's **id**, the argument
`/objective-run <id>` resumes. `<YYYY-MM-DD>` is the day the run started.
`<slug>` is the objective in kebab-case, at most five words. A slug already
taken that day takes `-2`, `-3`, … — the first free one.

## The shape

```
# Objective: <the objective, one line>

Status: running
Started: 2026-10-07 14:02
Limits: max-time 2h, max-rounds 3

## Objective

<the objective exactly as given, every line>

## Criteria

### C1. <one checkable statement>
Check: <how it is checked — a command, a file to read, a test name>
Verdict: not met — <evidence>

### C2. <statement>
Check: <how>
Verdict: unchecked
Parked: P1

## Rounds

### Round 1 — 2026-10-07 14:10 — progress
Worker: a1b2c3d — <one-line summary of the work>
Checker: C1 met — <evidence>; C2 not met — <evidence>

## Parked questions

### P1 — at the criteria — C2
<the question, verbatim and multi-line, options and recommendation included>

## Docs to update

none
```

## The fields

- **`Status:`** — exactly one of `running`, `done`, or
  `stopped: <reason>`, the reason in one clause (`stopped: max-time 2h
  passed`, `stopped: 3 rounds without progress`).
- **`Started:`** — the first invocation's start, `YYYY-MM-DD HH:MM`.
- **`Limits:`** — `max-time <duration>` or `max-time none`, and
  `max-rounds <N>`. Written at the start and never changed.
- **`## Objective`** — the objective verbatim.
- **`## Criteria`** — one `### C<n>.` per criterion, numbered from 1 and
  never renumbered, each with:
  - `Check:` — how a checker establishes it, concrete enough to run without
    judgement;
  - `Verdict:` — `unchecked` until the first checker verdict, then `met —
    <evidence>` or `not met — <evidence>`, the latest verdict only (the
    rounds hold the history);
  - `Parked: P<n>` — present only while the criterion waits on that parked
    question.
- **`## Rounds`** — one `### Round <k> — <YYYY-MM-DD HH:MM> — <progress | no
  progress>` per round, in order, each with:
  - `Worker:` — the worker's commit sha(s) and a one-line summary;
    `parked P<n>` when it asked a question instead; or `failed — <reason>`
    when it committed nothing;
  - `Checker:` — every criterion's verdict and evidence, `C<n> met|not met —
    <evidence>`, separated by `; `, or `no verdict — <reason>`; or `skipped`
    when the worker committed nothing;
  - `Left uncommitted:` — the paths the worker left dirty, present only when
    there are any.
- **`## Parked questions`** — one `### P<n> — <round <k> | at the criteria> —
  <the criterion or the work it holds up>` per question, the handle sequence
  shared with the run's chat, each holding the question verbatim with its
  options and recommendation; once answered, a final line
  `Answer: <the answer as given> (<YYYY-MM-DD>)`. `none` when empty.
- **`## Docs to update`** — one bullet per stale passage,
  `- <path> § <section> — <what no longer holds> (round <k>)`, or `none`.
  Filled as rounds land; never acted on by the run itself.
