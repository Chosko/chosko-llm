# Backlog ordering

The backlog and the runbook store both record sequence, and neither honours
it when work is selected. `Preconditions:` is written on every task and read by
nothing that picks a task; a runbook step can only ever be appended. This
feature makes recorded order the order that selection follows, and gives every
store an insertion operation, so a task or a step added late lands where it
belongs rather than at the end. It is the prerequisite of the whole revision
suite: nothing downstream can insert into a sequence the selectors ignore.

## Purpose

Today `next` in `/task-implement` picks the first eligible task by appearance
order in `.claude/TASKS.md`, and `/production-status` names the lowest-numbered
open task as a feature's next action. Both read the id as the order. Because
`/task-add` only appends, a task written late — a bug found mid-feature, a
migration step nobody planned — carries the highest id and is picked last,
however many `Preconditions:` lines name it. The user then has to remember to
run it by number at the right moment, with no automation on their side. The
same shape recurs in runbooks: `/runbook-create --append` puts the new step at
the foot, so a step that belongs between two others is placed by hand or not
at all.

The fix is not a second ordering axis. `Preconditions:` already states the
hard constraint and appearance order already states the priority; the
selectors simply have to read both. Insertion then means placing the new entry
where a reader expects it and writing the edge the selectors follow. This
serves Claude-as-operator, who picks up work through `next`, `all` and
`/production-status`, and the director, who no longer carries the sequence in
their head. It is the mechanism half of the "insert a task at a specific
moment" use case that [pipeline-revision](./pipeline-revision.md) exposes.

## Scope and non-goals

In scope: the selection rule for `next` and `all`; the same rule in
`/production-status`; `--before` / `--after` on `/task-add` for placement plus
edge; `--single` on `/task-add feature=<slug>` to attach one task to a planned
feature; the orphan-task prompt on free-form `/task-add` when `FEATURES.md`
exists; and `--before` / `--after` on `/runbook-create --append`.

Deliberately out:

- **A topological sort or a scheduler.** `all` becomes repeated `next` until
  nothing is eligible. One rule, stated once, no graph algorithm anywhere in a
  prompt.
- **Cross-feature ordering at task level.** Feature-to-feature order is
  `PLAN.md`'s and stays there. A precondition may name any task, but nothing
  here reads `PLAN.md`; the product-workflow decision that `/task-implement`
  does not honour plan order stands.
- **Renumbering.** Task ids and runbook step ids are stable identifiers. An
  insertion never changes an existing id, in either store.
- **Parallel execution or reordering of existing entries.** Insertion adds;
  it does not move what is already there. Moving an existing task is a
  revision, handled by [pipeline-revision](./pipeline-revision.md) through the
  amend files in [owner-amend-arms](./owner-amend-arms.md).
- **Automatic feature write-back.** `--single` attaches a task to a feature
  and says in one line that the feature document was not updated. Updating it
  is the patcher's job, not `/task-add`'s.

## Architecture

Built on the existing markdown-prompt stack per `technical-direction.md`:
every change here is a rule change in a shipped body, and the rules concerned
already have a single home in `skills/task-engine/references/` and
`skills/runbook-run/references/`. Nothing new is installed; four existing
features change behaviour.

### Selection honours preconditions

The `next` selector in `task-engine`'s resolution reference gains one clause:
a task is eligible only when its status is implementable **and** every id on
its `Preconditions:` line resolves to a task whose status is `[DONE]` or
`[SKIP]`. An id that resolves to nothing is ignored, the same tolerance the
iterate guard extends to a hand-edited backlog. `all` is redefined as `next`
applied repeatedly until no task is eligible, which keeps a batch run from
starting a task ahead of the one it depends on and needs no second definition
of eligibility. It is resolved once, up front, by simulating that repetition —
each walk selects the first eligible task not yet selected and treats it as
`[DONE]` for the walks after — which yields the same list repeated `next`
would, while preserving the run's single resolution report and its delegation
count. A batch that ends with implementable tasks still blocked by
unmet preconditions reports them by id, so an unsatisfiable edge is visible
rather than silently skipped.

`/production-status` adopts the same rule for the Next column: the first task
in appearance order whose preconditions are satisfied, replacing
"lowest-numbered". The command already reads `Preconditions:` from the summary
blocks it opens, so no new read is introduced and the never-open-a-body
contract holds. The derivation stays in one place and section 4 still echoes
it.

### Insertion into the backlog

`/task-add` gains two placement flags. `--before <N>` writes the new summary
block immediately above task N's and appends the new id to N's
`Preconditions:`. `--after <N>` writes it immediately below N's and puts N on
the new task's `Preconditions:`. Both flags do two things on purpose: the
position is for the human reading `TASKS.md` top to bottom, the edge is for
the selectors above, and either alone would leave the two disagreeing. A task
with a `Feature:` line placed among another feature's tasks is legal; the
`Feature:` line, not the position, is what reconciliation keys on. The flags
compose with `--short`, `--no-split` and `feature=<slug> --single`; with a
split they apply to the first task of the split and the rest follow it.

### Attaching one task to a planned feature

`/task-add feature=<slug> --single "<description>"` plans exactly one task
against the named feature's document, writes its `Feature:` line, appends its
id to the feature's `Tasks:` line, and runs no reconciliation over the
feature's other tasks. The feature's status is untouched: it was `[PLANNED]`
and one more planned task does not change the design-to-backlog relationship.
The closing report carries one fixed line saying the feature document was not
updated and naming `/pipeline-patch feature=<slug>` as the write-back, so the
drift is announced at the moment it is created rather than discovered later.

### The orphan prompt

On a project with `.claude/FEATURES.md`, a free-form `/task-add` run asks,
inside its existing PHASE 3 approval gate, whether the task belongs to a
feature, listing the slugs and offering none. Answering with a slug takes the
`--single` path above; answering none writes the task exactly as today. No
second gate is added, and a project without a feature index sees no change.
This is where orphaned tasks stop being the default on a project that has
features to attach them to.

### Insertion into a runbook

`/runbook-create --append <name|id>` gains `--before <step>` and
`--after <step>`. Step ids are stable and the new step takes the next unused
id, but it is written at the requested list position; `/runbook-run` already
walks the body top to bottom, so order is list position and the id carries
none — the same rule the roadmap uses for milestones and `TASKS.md` for tasks.
Existing steps' `Depends on:` lines are never rewritten; the new step's are
authored as part of the append. `--from`, `--to` and `--only` keep addressing
steps by id. The schema reference in `skills/runbook-run/references/` records
that ids are not positions, so a reader never infers order from numbering.

## Data and state

No new file and no new field. `Preconditions:` becomes load-bearing rather
than informational; it is unchanged in shape. A runbook body may now carry
step ids out of numeric order, which the schema declares legal. The
`Last runbook number:` counter and `Last task number:` counter keep their
only-ever-increases rule; an insertion consumes the next id exactly as an
append does. Eligibility is derived on every read and stored nowhere.

## Interfaces and contracts

- `/task-implement next` — first eligible task in appearance order whose
  preconditions are all `[DONE]` or `[SKIP]`. `/task-implement all` — `next`
  repeated until none is eligible; blocked implementable tasks named at the
  end.
- `/production-status` — the Next column's `/task-implement <N>` value picks
  `<N>` by the same rule.
- `/task-add [--before <N> | --after <N>]` — placement plus edge. Unknown N
  stops with the usual unknown-task message. The two flags are mutually
  exclusive.
- `/task-add feature=<slug> --single "<description>"` — one attached task,
  no reconciliation, fixed write-back reminder. Mutually exclusive with
  `--short` for the reason `feature=` already is.
- `/task-add` (free-form, `FEATURES.md` present) — the feature question at
  the existing gate.
- `/runbook-create --append <name|id> [--before <step> | --after <step>]` —
  positional insert with a fresh id. Unknown step id reported by listing the
  runbook's steps.

Failure contract: an unresolvable precondition id never blocks selection; a
precondition cycle makes every task on it ineligible and `all` reports them
as blocked rather than looping. Every new flag is inert when absent, so every
existing invocation behaves exactly as today.

## Dependencies

- **[shared-phase-engine](./shared-phase-engine.md)** — the selectors and
  the `Preconditions:` schema live in `task-engine`'s references; this feature
  edits them there and nowhere else.
- **[runbook-suite](./runbook-suite.md)** — the append rules and the step
  schema this feature extends.
- **[plan-readout](./plan-readout.md)** — owns the Next-column derivation
  that changes here.
- Documentation to update when this lands: `README.md`, `docs/reference.md`,
  `.claude/domain/task-workflow.md`, `.claude/domain/product-workflow.md`
  (the read stage), `.claude/domain/features/runbook-suite.md`.

## Open questions

- **Should `/task-list` mark blocked-by-precondition tasks?** It already
  marks `⚠ blocked by <slug>` from the plan. A `(waits on N)` marker from
  preconditions would make the new selection rule visible in the listing. Left
  out until the rule has been used; it is a rendering change, cheap to add.
- **Does `all` with subagents need the eligibility re-evaluated per spawn?**
  Settled: yes, and it already has a home. `/task-implement`'s existing
  BETWEEN TASKS re-read of `TASKS.md` — the same re-read the delegated
  launcher makes before each agent — is the per-spawn re-evaluation point: on
  a run resolved by `all` it re-checks the upcoming task's `Preconditions:`
  there and skips, with one line, a task whose preconditions no longer hold.
  No new read was introduced.
