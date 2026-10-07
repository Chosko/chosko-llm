# Features: orchestrate mode

## Overview

Covers `/orchestrate-mode`, a conversation-scoped mode in which the session
never edits code and turns every change request into a batch of per-area
subagents.

- `skills/orchestrate-mode/` — `SKILL.md` plus three supporting files read on
  demand: `brief.md` (the eight-part area brief in fixed order — read
  `CLAUDE.md`; the handoff path, read first, rewritten last; the owner's note
  verbatim; constraints; off limits; shared-file discipline — exact-string
  edits, no whole-file write or stream edit, re-read and retry once then
  report the unmatched string; the project's quick check, no staging; the
  report shape), `handoff.md` (`.claude/sessions/pending/agent-<area>.md`
  before the first `/session-save`, `.claude/sessions/<stem>/agent-<area>.md`
  after; owned files, constants, owner rules, rejected-by-owner list,
  verification recipe, pitfalls; current state only, ~120 lines, rewritten at
  the end of every task, retiring agents write theirs, rebuilt from owned code
  when missing or stale; the orchestrator passes the path, never reads it) and
  `failures.md` (the six-row failures table). Declares
  `requires: skill:interaction-engine`.
- `SKILL.md`: on / `<notes>` (first request) / `--off`, each one line; the
  mode holds until `--off` or the conversation ends and a context summary
  keeps `orchestrator mode: on`; whether it is on is `interaction-engine`'s
  `mode.md`. Triage: a change of any size is a batch, a question is answered
  inline, no actionable note gets `Nothing to act on.` Limits: reads only
  `CLAUDE.md`, `.claude/context/INDEX.md` and the touched areas' context
  files; never edits code, drives a single-instance tool or reads a
  transcript; asks only when two readings lead to different code. Areas own
  disjoint files or named regions; same region → one area in sequence; an
  unplaceable or two-way note goes to the user while the rest launch.
  Launch: independent areas in one message, shared regions serialised, at
  most one single-instance-tool owner per batch; `opus` default, `fable` only
  for hard work with the brief saying why, `--model` overrides the batch.
  After the batch: the quick check once; proof captures only when the owner
  is away or asks, made by the area agent owning the single-instance tool;
  report per `messages.md`; asks once whether to iterate or check in when
  batches converge. Check-in: one commit per area, one at a time, only the
  orchestrator stages, a shared file rides with the area that changed it
  most, then `/session-save`; a `confirmation` gate. The Option 3 boundary:
  areas only for free-form requests and `/quick-implement`'s implementation
  step; `/task-implement` runs with `--agents`; `/runbook-run` unchanged;
  `/task-add`, `/architect`, `/pipeline-revise` and `/quick-implement`'s spec
  phase run in one fresh subagent whose questions are relayed; each command
  keeps its commit rule; `/objective-run` not split. The NEVER list closes
  the body. Not a pipeline-engine consumer: no routing row.

## Public API

- `/orchestrate-mode [<notes>] [--model <m>]`, `/orchestrate-mode --off`;
  the context-summary line `orchestrator mode: on`.
- Otherwise [feature-contract.md](./feature-contract.md) § Public API.

## Internal patterns

- None beyond [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- `../domain/features/orchestrate-mode.md` — the design.

## Cross-references

- [interaction-engine.md](./interaction-engine.md) — `mode.md`, the check
  every affected command cites.
- [task-implement-delegation.md](./task-implement-delegation.md) — delegation
  on by default under the mode; [quick-implement.md](./quick-implement.md) —
  the subagent spec phase and the area split;
  [pipeline.md](./pipeline.md) — `pipeline-suggest` silent under the mode.
- [session-handoff.md](./session-handoff.md) — `/session-save` moves the
  handoffs, `/session-resume`, `/session-list` and `/session-describe` list
  the areas.

## When to read the source

- Changing triage, limits, launch, check-in or the boundary →
  `skills/orchestrate-mode/SKILL.md`; the brief → `brief.md`; handoff paths or
  schema → `handoff.md`; the failures table → `failures.md`.
