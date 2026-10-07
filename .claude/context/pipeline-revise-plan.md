# Features: pipeline-revise — plan, gate and actuation

## Overview

Covers the second half of the `pipeline-revise` entry: merge, order, plan-time
decisions, tiers, the gate and its reply grammar, actuation, the branch owner
sequences, the closing follow-up gate, the failure contract and the commit.
The first half: [pipeline-revise.md](./pipeline-revise.md). The rest of the
pipeline family: [pipeline.md](./pipeline.md).

- `skills/pipeline-revise/` (continued from
  [pipeline-revise.md](./pipeline-revise.md) § Overview) —
  **Merge**: two items reaching one artifact become one step — several
  sections of one feature doc one `/architect amend` naming them all, several
  docs one multi-slug run, every roadmap edit one `/product-roadmap amend`,
  every plan edit one `/production-plan amend`, every design edit one
  `/product-design amend`, one runbook's inserts one `/runbook-create
  --append`. **Order** upstream first across items: design → feature docs →
  task amends → removals → task insertions and `/task-add` reconciliation →
  plan → runbook strikes, facts, insertions; a step consuming an earlier
  step's output follows it whatever the kinds say. **Decide at plan time**:
  every decision an owner's arm makes by a closed rule over its reads is
  taken in the proposal and shown on its step — `/architect amend`'s
  editorial classification (per `../architect/amend.md` § 4 over the touched
  set and the scope call), the drafted task fields and body sections, a
  struck id + reason or dated `Context:` fact, the drafted design / roadmap /
  plan edits — and that step is tagged **headless**: runs with the decision
  carried in, asks nothing, the arm writing without a second gate when the
  draft matches its own. `/task-add` create and reconcile, the one owner whose
  work is drafting, are tagged **GATED** with one `Will ask:` line and sort
  LAST wherever the order allows, so every headless write lands before the
  first stop. A reconciliation step is conditional and shows its evidence
  (`because step 1 stales 12, 14`; none rendered when the carried
  classification is editorial for every feature); an id unknown until a step
  runs is a placeholder (`<id from step 5>`) in every later step. Tiers
  editorial / local / structural set a sequence's length, judged by the
  branch file (`reorder.md` fixed structural; `insert.md` structural when it
  adds scope, local when the doc already promises it; `delete.md` local only
  for a task nothing else names — insert/delete/reorder never editorial);
  only a borderline wording-vs-meaning architect classification stays open.
  ONE gate, written to [interaction-engine.md](./interaction-engine.md)
  `messages.md`; nothing written before it by the skill or any arm: a
  verdict line; one plain sentence per change, numbered as the owner steps
  (what it changes and why, identifiers last; what a gated step will ask; a
  carried decision in words); step 5's findings only when there are any;
  then any still-open architect question in that arm's ambiguous form, last,
  with at most a one-line shortcut hint. The item split, classifications,
  touched/untouched entries, the owner-step table with invocations and
  headless/GATED tags, and the drafts stay internal — `show` (or
  `show <n>`) prints them. Gate class `confirmation` when no question is
  open (under `unattended` it passes on its own, as on `go`), `design`
  otherwise (under `unattended` the run stops there, nothing written); the
  policy is handed down to every owner it drives. Reply grammar: `go`; `all but <n>[, <m>]`;
  `<n> as runbook step` (the step deferred self-contained, carrying its
  invocation, anchor, change and every decision taken here, to a named
  runbook, the session's runbook, or a new one `/runbook-create` writes —
  `all as runbook steps` defers the plan); `<n> after <m>`; a letter for an
  open architect question or an overruled touched/untouched call or tier;
  `stop`. Anything but `go`/`stop` applies the edit and re-shows only the
  changed lines at the SAME gate; a dropped step drops its dependents, named; silence, unclear reply
  or EOF is `stop`. Actuation: sequential in the session, never parallel,
  never subagents; a headless step runs its arm by path with the decision
  carried in, a gated step runs its owner's command with that owner's gate
  intact; a step an earlier outcome made moot is dropped with a line, none
  added after the gate; deferred steps go to `/runbook-create --append` (or
  `/runbook-create <name>`) with `--no-commit` once the in-session steps have
  run — the skill writes no line of the runbook. Branch owner sequences:
  amend = `/product-design`'s amend arm → `/architect amend` per feature →
  tasks in two forms (task-engine `amend.md` per task when step 2 stales
  nothing; one `/task-add feature=<slug>` reconciliation when it stales or
  moves the feature `[ITERATED]`, unstaled tasks' own amends first, doc-less
  facts as its annotation) → `step-amend.md` per step; insert = `/architect
  amend` for new scope → `/task-add feature=<slug> --single --before/--after`
  (or the reconciliation form when step 1 leaves the feature `[ITERATED]`) →
  successors' `Preconditions:` via the task arm → `/runbook-create --append
  --before/--after`; delete = withdraw the promise → `[SKIP]` + dated reason →
  successors' edges dropped with the reason → steps struck, and for a feature
  every live task `[SKIP]` plus a `/production-plan` run, entry kept (lint
  then reports L11); reorder = skip-and-insert, new id at the new place, no
  renumber. **Closing follow-up gate** after actuation: what execution
  surfaced and the plan did not hold — a created task no open runbook running
  its feature has a step for, a successor no longer reading as a sequence, a
  lint finding created, a feature an owner named for reconciliation that no
  step ran — one plain sentence each, numbered, the question last, same
  reply grammar, gate class `design`, skipped when nothing arose, nothing
  written without the reply. The lint bracket prints failures only — findings
  created or left unchanged. Failure
  contract: an owner refusing (touched `[IN PROGRESS]`, `[DONE]`, a
  `[RUNNING]` position) or a gated owner's gate answered stop stops the
  sequence there, earlier writes kept and reported, NEVER rolled back, the
  after-lint still runs; a missing owner stops before the gate; absent
  `/runbook-create` makes `as runbook step` an error shown at the same gate. Write
  set empty — no line, no file, no report on disk; no status value, no change
  ledger. Owns the run's commit (COMMITTING, per `commit.md`): commits +
  pushes by default, `--no-commit` / `--no-push`, `--commit` a no-op; pull
  once at start after every item resolves; every owner step uncommitted
  (`/task-add`, `/product-design`, `/product-roadmap`, `/production-plan`,
  `/runbook-create` incl. `--append`, `/architect` always get `--no-commit`;
  by-path arms run with no commit; no owner pulls or pushes); after the
  closing gate, ONE commit of the union of reported writes — a runbook
  written for deferred steps included — subject = the `Revised <items> items
  — …` line. No commit on a stop before the gate, `stop` at either gate, a
  sequence stopped part-way (left uncommitted on purpose, every path listed),
  an empty write, or `--no-commit`.

## Public API

- See [pipeline.md](./pipeline.md) § Public API.

## Internal patterns

- See [pipeline.md](./pipeline.md) § Internal patterns.

## Domain dependencies

- See [pipeline.md](./pipeline.md) § Domain dependencies.

## Cross-references

- [pipeline.md](./pipeline.md) — the pipeline family hub.
- [pipeline-revise.md](./pipeline-revise.md) — the first half of this entry.
- [architect.md](./architect.md), [pipeline-planning.md](./pipeline-planning.md),
  [product-design.md](./product-design.md) — the owners whose amend arms the
  owner steps drive.

## When to read the source

- See [pipeline.md](./pipeline.md) § When to read the source.
