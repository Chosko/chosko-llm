# Owner amend arms

Each pipeline artifact has exactly one writer, and today most writers know
only one way to write: run the whole command. Changing one paragraph of a
feature document means a full `/architect` conversation; changing one task
body has no command at all. This feature gives each owner a small, standalone
amend file — the rules for a targeted change, kept in the owner's folder and
readable by path — so a surgical edit costs one small file instead of a whole
skill body, while the one-writer-per-artifact invariant stays intact.

## Purpose

The revision surfaces in [pipeline-revision](./pipeline-revision.md) need to
change planned units without either loading a whole owner or reimplementing
its guards. Loading a whole owner is the cost the cheap surface exists to
avoid; reimplementing a guard is a second copy that drifts, and a skipped
guard is precisely the silent drift the suite is built to prevent. The way out
is the pattern `task-engine` already proved: the rule lives in one file in the
owner's folder, and a consumer reads that file by path. Here the file is the
owner's amend arm.

`/product-design` already has one — the "amend a decision" arm in its
resuming file. `/production-plan` and `/product-roadmap` are already
reconciliation-first and need none. Three owners lack one: `/architect` for
feature documents, the task suite for a single task, and the runbook suite for
a single step. Serves Claude-as-operator, who executes the arm, and the
director, who gets a precision guard in place of a blanket one.

## Scope and non-goals

In scope: an `amend` mode for `/architect` with a precision iterate guard; a
single-task amend reference in `task-engine`; a single-step amend reference in
`runbook-run`'s references; and the rule that an amend file is complete on its
own, so a consumer executes it without opening the owner's body.

Deliberately out:

- **New writers.** Every amend file is owned by the artifact's existing owner
  and lives in its folder. The patcher and the reviser execute it; they do not
  own it. The who-writes-what table in the product workflow gains no row.
- **Amend arms for `/production-plan`, `/product-roadmap` or
  `/product-design`.** The first two are already diff-and-propose on every
  run; the third has its arm. The routing table records where each owner's
  amend entry is, and that is enough.
- **Editing `[DONE]` work.** No amend arm reopens a done task or rewrites a
  ticked runbook step. Follow-up work is a new task or a new step, as today.
- **Deciding editorial versus semantic.** The arm asks, every time. The user
  chose to be asked rather than trust a classification.

## Architecture

Built on the existing markdown-prompt stack per `technical-direction.md`. Each
amend arm is a supporting file in an already-shipped skill folder, reached
through the folder's existing `requires:` relationships; no new install unit
appears.

### `/architect amend`

A new argument form, `amend feature=<slug> "<change>"`, dispatches to a new
supporting file beside the skill's other on-demand files. The arm skips the
clarify and architecture phases entirely: the change is described, not
designed. It reads the feature document, applies the described change to the
sections it names, and then runs a **precision iterate guard** in place of the
blanket one:

- For every task on the feature's `Tasks:` line that is not `[DONE]` or
  `[SKIP]`, classify it as touched or untouched by the change, from its
  summary block alone — title and `Files:` against the sections that changed.
  A body is opened only when the summary block cannot decide.
- A touched task that is `[IN PROGRESS]` refuses the amendment, exactly as
  the full guard would; an untouched `[IN PROGRESS]` task does not, which is
  the precision the blanket guard lacks.
- One gate presents the change, the touched set and the proposed status
  outcome, and asks whether the change is editorial. On proceed, `[STALE]` is
  written on touched tasks only.
- The feature flips to `[ITERATED]` when any task was staled or when the
  change adds scope no existing task covers; an editorial change leaves the
  status as it was. The legal transitions are unchanged; the arm only chooses
  among them with finer evidence.

The arm writes what the full skill writes and nothing more: the feature
document, `FEATURES.md` status, `TASKS.md` status lines, and the design
document when the change belongs upstream. It does not write a progress
marker; an amendment is one gate long and has nothing to resume.

### Single-task amend

A new reference file in `task-engine` owns the rules for changing one existing
task: which body sections may be rewritten and which summary-block fields may
change; that `Preconditions:` may be rewritten to add or drop an edge and that
a dropped edge is named in the task's `## Decisions`; that deleting a live
task means `[SKIP]` with a reason, never removal, because physical removal is
`/task-clean`'s act over terminal statuses; and that `Feature:` may be added
to an orphan task but never changed on a feature-derived one, since the
feature's `Tasks:` line is the other half of that link and must move with it.
The file also states what a consumer must check before writing: the task is
not `[IN PROGRESS]`, and the change does not alter what the task's feature
document promises, which is the reviser's cue to route through
`/architect amend` instead.

### Single-step amend

A new reference file beside the runbook schema owns the rules for changing one
step in an unfinished runbook: a step may be struck, which marks it skipped
rather than deleting it and records why; a step may be inserted, which is the
positional append that [backlog-ordering](./backlog-ordering.md) adds; a
step's `Context:` may gain facts; a step's prompt block is immutable, the
existing rule, so a step whose prompt is wrong is struck and a corrected one
inserted. A `[RUNNING]` runbook accepts inserts after the current step and
nothing before it.

### What makes an arm consumable

Each arm names its inputs, its single gate, exactly what it writes and its
closing report line, so that a consumer that has read only the arm can execute
it end to end. The arm cites the owner's other references by path where a
rule already lives there, and states nothing that any other file states — the
same one-authority discipline the engines follow.

## Data and state

No new stored state. The arms are prose. The precision guard's touched set is
derived at the gate and never written down; what persists is the resulting
`[STALE]` and `[ITERATED]` markers, which already exist. A struck runbook step
uses the existing step-marker vocabulary rather than a new one.

## Interfaces and contracts

- `/architect amend feature=<slug> "<change>" [--commit] [--no-push]` —
  one gate, precision guard, same `WRITTEN` discipline as the full skill.
  Unknown slug stops by listing the slugs that exist. A `[NEW]` feature is
  amended with no guard at all, having no tasks.
- The single-task amend reference — read by path from `task-engine`; the
  consumer is `/pipeline-patch` or `pipeline-revise`, never the user directly.
- The single-step amend reference — read by path from `runbook-run`'s
  references; same consumers.
- Hard contracts: an arm never writes a line another owner owns; an arm never
  touches `[DONE]` or `[SKIP]` work; the touched classification opens a task
  body only when the summary block cannot decide; the editorial question is
  asked on every amendment.

Failure contract: a change that the arm cannot scope to named sections is
refused with a pointer to the full skill; a touched `[IN PROGRESS]` task
refuses with the task named; a hand-edited backlog whose `Tasks:` ids
resolve to nothing is tolerated exactly as the full guard tolerates it.

## Dependencies

- **[backlog-ordering](./backlog-ordering.md)** — the positional runbook
  insert the step arm uses.
- **[pipeline-engine](./pipeline-engine.md)** — the routing table records
  each owner's amend entry; the precision gate may run the scoped lint.
- **[shared-phase-engine](./shared-phase-engine.md)** and
  **[runbook-suite](./runbook-suite.md)** — the reference folders the two
  new files join.
- **[slice-aware-architecture](./slice-aware-architecture.md)** — the
  on-demand supporting-file pattern in `/architect` that the amend arm
  follows.
- Documentation to update when this lands: `README.md`, `docs/reference.md`,
  `.claude/domain/product-workflow.md` (iterate guard section gains the
  precision variant), `.claude/domain/task-workflow.md`,
  `.claude/domain/features/runbook-suite.md`.

## Open questions

- **How coarse is `Files:` as evidence?** A task whose `Files:` line names a
  whole directory will be classified touched by almost any change. If that
  proves common the guard will open bodies more often than intended, and the
  cure may be more specific `Files:` lines at authoring time rather than a
  smarter classifier.
- **Should `/architect amend` accept a free-form change with no section
  names?** Refusing keeps the arm surgical; accepting makes it the full skill
  with fewer questions. Start by refusing.
