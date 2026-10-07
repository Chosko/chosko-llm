# Features: quick-implement

## Overview

Covers `/quick-implement`, the path beside the backlog: one change from
conversation to commit, no `TASKS.md` entry.

- `skills/quick-implement/` — `SKILL.md` plus two supporting files, read
  every run: `spec.md` (the spec file `.claude/specs/<YYYY-MM-DD>-<slug>.md`
  — the task body schema plus a `## Drift` section, slug from the title, a
  same-day collision taking `-2`; written after the gate, staged in the
  implementation commit, deleted only by `/pipeline-revise --catch-up`) and
  `drift-check.md` (grep the domain layer, context layer, `CLAUDE.md` and
  README for the spec's identifiers, files and terms, read only the hit
  sections, classify each hit *settles* / *diverges* per `task-engine`'s
  `design-change.md`; divergences listed at the gate, never blocking).
  Declares `requires: skill:task-engine, skill:interaction-engine,
  command:follow-ups`. The run, in order: the dirty-tree check (`tree.md`)
  before anything else, then pull; the spec conversation (goal, criteria,
  decisions, hints; `feature=<slug>` reads that feature document) with the
  drift check, the size judgement and the testing-policy resolution
  (`testing-policy.md`, its questions asked at the gate, gate approval
  standing in for skip-tests `Proceed?`); ONE gate — `confirmation` with no
  open question, `design` otherwise, a `design` gate stopping an unattended
  run since there is no task to park; a spec too big for one commit stops
  there with a `/task-add` pointer, nothing written; the spec written; Steps
  2–5 of `tests-first.md`; under `--review [--rounds N]` its own short loop —
  `/task-review spec=<path>` in a fresh subagent (told the `/task-implement
  --review` spawn statement the reviewer keys on, budget per
  `review-budget.md` `auto`), wait, `/task-iterate spec=<path>` in session
  with the in-run assertion — since `task-implement`'s `review-rounds.md` is
  another skill's private file; one commit of change plus spec and push per
  `commit.md` (no `--no-commit` / `--no-push`; a failed commit leaves both
  staged and stops); the closing report per `closing-report.md`, its
  follow-ups `/architect amend` for a diverging feature-document point and
  `/pipeline-revise --catch-up <spec>` for the rest. Never writes `TASKS.md`
  or `FEATURES.md`. Under orchestrate mode (`interaction-engine`'s
  `mode.md`, checked at step 2): step 2 runs in one fresh subagent whose
  questions the session relays, returning spec, drift hits, size judgement,
  testing policy and open questions, the gate staying in the session; step
  5's implementation is split into areas by the `orchestrate-mode` skill's
  rules, named never pathed, area agents committing nothing; still one
  commit.

## Public API

- `/quick-implement "<change>" [feature=<slug>] [--review [--rounds N]] [--attended | --unattended]`.
  Its `routing.md` row: consumes the conversation, the drift-check sections
  and the testing-policy marker; produces code, tests and the spec file;
  owns the spec file; amend `—`.
- Otherwise [feature-contract.md](./feature-contract.md) § Public API.

## Internal patterns

- None beyond [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- `../domain/features/quick-implement.md` — the design: purpose, non-goals,
  the run, the spec lifecycle, the checks it shares through `task-engine`.

## Cross-references

- [task-engine.md](./task-engine.md) — the shared checks it reads.
- [orchestrate-mode.md](./orchestrate-mode.md) — the area split step 5 uses
  under the mode.
- [task-review-iterate.md](./task-review-iterate.md) — `spec=<path>` on the
  review pair.
- [pipeline-revise.md](./pipeline-revise.md) — `--catch-up`, which deletes
  the spec; [pipeline-readers.md](./pipeline-readers.md) — L14, a spec still
  present.

## When to read the source

- Changing the run, the gate or the review loop → `skills/quick-implement/SKILL.md`.
- Changing the spec format or lifecycle → `skills/quick-implement/spec.md`;
  the drift search → `skills/quick-implement/drift-check.md`.
