# Features: objective-run

## Overview

Covers `/objective-run`, which works toward one stated objective in rounds
of fresh subagents until checkable criteria are met or a limit stops it.

- `skills/objective-run/` — `SKILL.md` plus `references/log-schema.md` (the
  log `.claude/objectives/<YYYY-MM-DD>-<slug>.md`, whose name minus `.md` is
  the run's id, a same-day slug collision taking `-2`, `-3`, …; `Status:`
  `running` / `done` / `stopped: <reason>`, `Started:`, `Limits:`, the
  objective verbatim, criteria `C<n>` each with `Check:`, latest `Verdict:`
  and an optional `Parked: P<n>`, one entry per round — `Worker:`,
  `Checker:`, optional `Left uncommitted:` — parked questions with their
  `Answer:` once given, *Docs to update*). Declares
  `requires: skill:interaction-engine, skill:runbook-run`. The run: argument
  parsing (`--max-time` as `45m` / `2h` / `1h30m`, a malformed one an
  argument error; `--max-rounds N`, default 3; a lone `<YYYY-MM-DD>-<slug>`
  token is an id, an unknown one naming the existing logs; a resume refuses
  both limit flags), `date +%s` taken as the invocation's start; the tree
  read once, its dirty paths held as pre-existing and never staged, then
  pull; ONE gate — the criteria, each with its check, as a plain summary,
  tagged `confirmation`, waiting under `attended` (criterion questions
  answered there), passing under `unattended` (those questions parked, the
  summary printed naming the `Objective <id>: start` commit). Each round: a
  worker subagent (preamble always declaring the run unattended, since a
  worker's question parks under every policy; objective, criteria and
  verdicts, round lines, set-aside parked work, answers as
  `unparked with answer:` `Context:` bullets, paths not its own, one piece
  of work toward an unmet unparked criterion committed by explicit path, no
  documentation edits but a `Docs to update:` report line; OPERATING RULES
  from `runbook-run`'s `subagent-contract.md` with `<RUNBOOK>` =
  `objective-<id>`, `<N>` = round, `<FILE>` = the log), its `SPAWN REQUEST`
  served as `/runbook-run`'s spawn relay does, a relay failure, second miss
  or cap ending the round as `failed — relay: <reason>`; a read-only checker
  subagent giving `C<n>: met|not met — <evidence>` for every criterion; the
  log entry committed as `Objective <id>: round <k>` and pushed. A round is
  `progress` when a criterion moved to met; a worker that commits nothing or
  a checker with no verdict makes it `no progress`. Stops, checked between
  rounds only: every criterion met (`done`); `--max-time` past, counted from
  this invocation's start; `N` consecutive no-progress rounds (re-derived
  from the log on resume); every unmet criterion parked, which leaves the
  log `running` for a resume. Parking follows `runbook-run`'s
  `parking.md`: `P<n>` handles shared with the chat, an answer by handle
  between rounds committed as `Objective <id>: unpark P<n>`; on resume
  unanswered questions are asked under `attended`, printed under
  `unattended`. A done or stopped log reports and starts nothing. A failed
  log commit or push stops the run. Writes nothing but the log and the
  workers' commits: no `TASKS.md`, `FEATURES.md` or documentation, no
  `--no-commit` / `--no-push`, no area split under orchestrate mode.

## Public API

- `/objective-run "<objective>" [--max-time <duration>] [--max-rounds <N>] [--attended | --unattended]`;
  `/objective-run <id>` resumes a `running` log.
- Closing report: outcome, rounds, criteria met; *For the record*; one
  numbered *Follow-ups* list — `/architect amend feature=<slug> "<change>"`
  for a feature design the run changed, one `/pipeline-revise --catch-up
  "<what landed>"` for the rest of *Docs to update*, `/objective-run <id>`
  while still running, and the unanswered parked questions last under their
  `P<n>` handles.
- Otherwise [feature-contract.md](./feature-contract.md) § Public API.

## Internal patterns

- None beyond [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- `../domain/features/objective-run.md` — the design: purpose, non-goals,
  criteria, rounds, stopping, parking, docs follow-ups, resume.
- `../domain/features/interaction-policy.md` — objective runs as one of the
  parking mechanisms.

## Cross-references

- [interaction-engine.md](./interaction-engine.md) — the policy, the gate
  class and the message rules it cites.
- [runbook-run.md](./runbook-run.md) — `subagent-contract.md` and
  `parking.md`, which it cites; [runbook-run-loop.md](./runbook-run-loop.md)
  — the spawn relay it serves workers by.
- [task-implement-review.md](./task-implement-review.md) — the review-round
  shape its loop is named after.
- [orchestrate-mode.md](./orchestrate-mode.md) — the exemption from area
  splitting.

## When to read the source

- Changing the gate, the rounds, stopping, parking or resume →
  `skills/objective-run/SKILL.md`.
- Changing a log field or the id → `skills/objective-run/references/log-schema.md`.
