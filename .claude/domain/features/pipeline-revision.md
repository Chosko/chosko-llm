# Pipeline revision

Two surfaces for changing, inserting into or removing from already-planned
work, at two costs. `/pipeline-patch` is a thin command for a change that
touches exactly one artifact owner: it walks the indexes, loads that owner's
amend arm, executes it and runs the scoped lint. `pipeline-revise` is a heavy
explicit skill for everything else: it walks the impact in both directions,
may open bodies to verify, proposes a tiered plan behind one gate, and then
either actuates the plan in the session or writes it as a runbook. Both leave
every write to the artifact's owner. Neither is triggered automatically.

## Purpose

A design decision or a planned task changes after planning more often than a
first-time pipeline admits. Today that change is a costly exception: each
affected artifact needs its own command run, each run has its own gate, and
the user carries the sequence and the risk of forgetting a step. The real
cost is the forgotten step, which stays silent until an implementer builds
against a stale task or a plan orders a dependency after the thing that needs
it.

This feature makes the amendment a legitimate request with a proportional
cost. A small change pays for one small file and one gate. A structural change
pays for an impact analysis, a verification pass and however many owner runs
it needs, but pays once, in one conversation, with one question stream. The
"insert a task at a specific moment" case is the motivating example: attach
the task, place it, write back the feature document, insert the runbook step,
and confirm the lint is clean, in one run. Serves the director, who describes
the change once, and Claude-as-operator, who executes it without inventing a
sequence.

## Scope and non-goals

In scope: the patch command with its single-owner rule and refuse gate; the
revise skill with its branches, tiers, impact walk, verification bracket and
two actuation modes; deletion semantics; the boundary between the two.

Deliberately out:

- **Writing any artifact directly.** Both surfaces execute owners' amend arms
  or invoke owner commands. Neither owns a line in any index; the
  who-writes-what table gains no row.
- **Automatic triggering.** Both are explicit. The auto-triggered surface is
  [pipeline-suggest](./pipeline-suggest.md), which only points here.
- **Parallel actuation.** Steps run one at a time, in the session, for the
  same reasons the runbook orchestrator gives: one question stream, one
  writer per file.
- **Replacing the first-time pipeline.** A revision is still costlier per
  unit than planning correctly once. The feature makes it one session instead
  of four, not free.
- **Physical deletion.** A live task is `[SKIP]` with a reason; a feature's
  entry stays with its tasks skipped and its edges dropped by
  `/production-plan`'s reconciliation; a runbook step is struck. Removal of
  terminal entries remains `/task-clean`'s and `/runbook-clean`'s explicit
  act.
- **Rewriting the design document's history.** A revision that changes a
  product-design decision goes through `/product-design`'s amend arm, which
  already deletes rather than appends.

## Architecture

Built on the existing markdown-prompt stack per `technical-direction.md`.
Both surfaces read the engine from [pipeline-engine](./pipeline-engine.md)
and the arms from [owner-amend-arms](./owner-amend-arms.md), declared through
`requires:`.

### The patch command

`commands/pipeline-patch.md`, a single command file, thin by contract. It probes, reuses or prints the
verdict line, and walks the graph from the anchor the user named — a feature
slug, a task id or a runbook step — reading only the indexes. It then counts
the owners the change would touch. Exactly one, among feature document, task
and runbook step, and none of the structural signals present: load that
owner's amend arm, execute it including its gate, run the lint scoped to the
anchor, report. Anything else: one line naming `/pipeline-revise` with the
reason, and stop. The structural signals are fixed and few: more than one
owner, a dependency edge changing, scope added that no task covers, a deletion
that crosses artifacts, a reorder of existing entries. The refuse rule is a
count and a checklist, not a judgement, so the command stays cheap to run and
cheap to predict.

The command declares `requires:` on the engine and on every skill whose amend
arm it may load. That makes installing the patcher pull in the owners, which
is correct: a patcher with no owner to delegate to has nothing to do.

### The revise skill

`skills/pipeline-revise/`, a skill folder: a short body in `SKILL.md` and one
flat supporting file per branch — `amend.md`, `insert.md`, `delete.md` and
`reorder.md`. The body probes, walks the graph from the anchor or from the free-form description,
and classifies the request into one branch — amend, insert, delete or
reorder — loading only that branch's file. Each branch file carries the
impact walk's direction rules, the owner sequence and the tier logic for its
kind of change.

**Impact walk, both directions.** Top-down from a design section or feature
document to the tasks, plan edges and runbook steps that depend on it;
bottom-up from a task to the feature document that promised it, when the task
carries a `Feature:` whose slug resolves. Unlike the patcher, the reviser may
open bodies, scoped by the anchor: the target artifact, the tasks whose
`Preconditions:` name it or whose `Files:` overlap, the runbook steps that
name it. Never a bulk read.

**Tiers, one gate.** The proposal names the tier — editorial, local or
structural — the artifacts touched, the owner steps in order and the lint
findings the change will create or clear. The editorial question is always
asked, never inferred. The user confirms once; nothing is written before.

**Verification bracket.** The scoped lint runs before the proposal, so the
plan starts from the true state, and again after actuation, and the report
shows the difference. This is the step that makes the downstream cost
visible at revision time rather than at implementation time. The reviser also
reads the successor tasks' bodies where an insertion or deletion changed a
precondition, to confirm the sequence still reads as a sequence — the check
nothing automated performs today.

**Actuation.** Three or fewer owner steps run in the session, sequentially,
each through its owner's amend arm or command with the owner's own gate
intact, the user present for each. Four or more offer a choice: run them in
the session anyway, or write them as a runbook through `/runbook-create` and
stop. The runbook is offered, never assumed; `/runbook-create` is detected at
run time and the offer is omitted when it is absent, the same optional
delegation the council gate uses. The reviser never writes a runbook itself.

**Deletion.** The delete branch maps removal onto the existing vocabularies:
`[SKIP]` with reason for a task, struck for a runbook step, `[SKIP]` on every
task plus a `/production-plan` run to drop edges for a feature. History is
never lost from a live index.

### The boundary between the two

The patcher is the reviser's single-owner branch shipped as a separate,
cheaper unit. They share the engine, the arms and the lint. A patch that
discovers it is structural does not escalate silently; it stops and names the
reviser. A revise that turns out to be single-owner still runs, at its own
cost; the user chose the heavier tool.

## Data and state

No new stored state. The tier, the touched set and the owner sequence exist
only in the proposal at the gate. What persists is written by owners in the
existing vocabularies: `[STALE]`, `[ITERATED]`, `[SKIP]`, `Preconditions:`,
`Tasks:`, struck steps, a runbook when the user asked for one. Provenance is
the commits each owner step makes and the runbook's `Done:` lines; no change
ledger is introduced.

## Interfaces and contracts

- `/pipeline-patch <anchor> "<change>" [--commit] [--no-push]` — anchor is
  `feature=<slug>`, `task=<N>` or `runbook=<name|id> step=<n>`. Single owner
  or refuse. `--commit` / `--no-push` are forwarded to the amend arm it
  executes; it makes no commit of its own.
  `requires: skill:pipeline-engine, skill:architect, skill:task-engine,
  skill:runbook-run`.
- `/pipeline-revise [<anchor>] "<change>" [--commit] [--no-push]` — anchor
  optional when the description resolves one; branch chosen by
  classification; one gate; in-session actuation or runbook offer at four or
  more steps. `requires: skill:pipeline-engine` plus the owner skills the
  patcher requires.
- Hard contracts: neither surface writes a line an owner owns; the patcher
  never opens a body; the reviser opens bodies only within the anchor's
  scope; the editorial question is always asked; the runbook is never written
  without the user's choice; the lint runs before and after every revise.

Failure contract: an anchor that resolves to nothing stops by listing what
exists; a patch refused for structure names the signal; an owner arm that
refuses, such as a touched `[IN PROGRESS]` task, stops the sequence at that
step with earlier steps' writes intact and reported, never rolled back;
`/runbook-create` absent removes the runbook offer and says nothing.

## Dependencies

- **[backlog-ordering](./backlog-ordering.md)** — insertion primitives the
  insert branch composes.
- **[pipeline-engine](./pipeline-engine.md)** — probes, graph, routing, lint.
- **[owner-amend-arms](./owner-amend-arms.md)** — every write both surfaces
  make goes through an arm or an owner command.
- **[runbook-suite](./runbook-suite.md)** — optional target of the four-or-
  more-steps offer.
- **[production-plan](./production-plan.md)** — reconciliation the delete
  branch invokes to drop edges.
- Documentation to update when this lands: `README.md`, `docs/reference.md`,
  `.claude/domain/product-workflow.md` (a new revision section and the
  who-writes-what note that the surfaces own nothing),
  `.claude/domain/task-workflow.md`.

## Open questions

- **Should the reviser use subagents for in-session actuation?** The runbook
  orchestrator's subagent contract would give each owner step a clean context
  at the cost of relaying every gate. Start in-session; revisit if three-step
  revisions prove to bloat the conversation.
- **Is a reorder branch worth shipping first?** Decided: it shipped with the
  first increment, as `reorder.md`. Because a move is expressed as
  skip-and-insert, the branch is thin — it composes `delete.md` and
  `insert.md` and adds only its boundary against amend, its fixed structural
  tier and its reason wording.
- **Where does a revision that changes a roadmap milestone go?** Through
  `/product-roadmap`'s own revision path, sequenced by the reviser like any
  other owner run; whether that needs its own branch is undecided.
