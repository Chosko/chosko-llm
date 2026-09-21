# Pipeline revision

One surface for changing, inserting into or removing from already-planned
work. `pipeline-revise` is an explicit skill that takes a change set — one
change or many — classifies each item, walks its impact in both directions,
may open bodies to verify, merges the items into one ordered owner sequence,
decides in advance everything an owner would decide by rule, and shows the
whole thing once as a numbered plan behind one gate before running it. Every
write is left to the artifact's owner. It is never triggered automatically.

## Purpose

A design decision or a planned task changes after planning more often than a
first-time pipeline admits, and it rarely changes alone. Without this feature
that change is a costly exception: each affected artifact needs its own
command run, each run has its own gate, and the user carries the sequence and
the risk of forgetting a step. The real cost is the forgotten step, which
stays silent until an implementer builds against a stale task or a plan orders
a dependency after the thing that needs it.

This feature makes the amendment a legitimate request with a proportional
cost. A wording fix pays for one owner step behind one gate. A structural
change, or a list of a dozen of them, pays for an impact analysis, a
verification pass and however many owner runs it needs, but pays once, in one
conversation, with one question stream. The "insert a task at a specific
moment" case is the motivating example: attach the task, place it, write back
the feature document, insert the runbook step, and confirm the lint is clean,
in one run. Serves the director, who describes the change once, and
Claude-as-operator, who executes it without inventing a sequence.

## Scope and non-goals

In scope: the change set and its split into items; the four branches with
their impact walks, tiers and owner sequences; the merge into one sequence;
the decisions taken at plan time and the headless / gated step distinction;
the one plan gate with its reply grammar and per-step deferral; the
verification bracket; the closing follow-up gate; deletion semantics.

Deliberately out:

- **Writing any artifact directly.** The skill executes owners' amend arms or
  invokes owner commands. It owns no line in any index; the who-writes-what
  table gains no row.
- **Automatic triggering.** It is explicit. The auto-triggered surface is
  [pipeline-suggest](./pipeline-suggest.md), which only points here.
- **Parallel actuation.** Steps run one at a time, in the session, for the
  same reasons the runbook orchestrator gives: one question stream, one
  writer per file.
- **A second, cheaper surface.** A single-owner change is the same skill with
  one item: one branch file read, one owner step, one gate. Splitting that
  into its own command would duplicate the anchor rules, the arms and the lint
  to save a file read.
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

Built on the existing markdown-prompt stack per `technical-direction.md`. It
reads the engine from [pipeline-engine](./pipeline-engine.md) and the arms
from [owner-amend-arms](./owner-amend-arms.md), declared through `requires:`,
which names every owner whose arm a step may drive — the engine, `architect`,
`task-engine`, `runbook-run`, `product-design`, `production-plan` and
`product-roadmap`. Installing the reviser pulls in the owners, which is
correct: a reviser with no owner to delegate to has nothing to do.

### The skill

`skills/pipeline-revise/`, a skill folder: a short body in `SKILL.md` and one
flat supporting file per branch — `amend.md`, `insert.md`, `delete.md` and
`reorder.md`. The body probes, splits the argument into items, resolves each
item's anchor, classifies each into one branch — amend, insert, delete or
reorder — and loads the branch file of every kind its items need, each once.
Each branch file carries the impact walk's direction rules, the owner sequence
and the tier logic for its kind of change.

**A change set, not a change.** The argument is free-form text describing
however many changes, or a numbered list in the shape `/follow-ups` prints,
which is one item per number. Free-form text is split at the changes it
describes, and the split is said back at the gate for the user to correct. An
anchor argument — a feature slug, a task id, a runbook step — applies to every
item that names no artifact of its own; an item may also anchor on a roadmap
milestone, which only an item's own text can name. This is what makes the
"here are eleven follow-ups from a design conversation" case one run instead
of eleven.

**Impact walk, both directions.** Top-down from a design section or feature
document to the tasks, plan edges and runbook steps that depend on it;
bottom-up from a task to the feature document that promised it, when the task
carries a `Feature:` whose slug resolves. Bodies are opened within each item's
scope: the target artifact, the tasks whose `Preconditions:` name it or whose
`Files:` overlap, the runbook steps that name it, and whatever an owner's arm
reads to make a decision the plan is about to make for it. Never a bulk read.
Every node is visited once across the whole set, so an artifact two items
reach is one entry in the plan.

**One sequence.** The items' owner steps merge: two items reaching the same
artifact become one step, several sections of one feature document one
`/architect amend`, every roadmap edit one `/product-roadmap amend`, and so
on per owner. The order is upstream first across items — design, feature
documents, task amends, removals, task insertions with `/task-add`'s
reconciliation, the plan, then runbook strikes, facts and insertions — with a
step whose input is an earlier step's output placed after it. No downstream
step is ever written against a state a later step changes.

**Decisions at plan time.** Every decision an owner's arm makes by a closed
rule over its own reads is made in the proposal and shown on its step: the
editorial classification `/architect amend` would reach, the drafted task
fields, the struck step's id and reason, the drafted design, roadmap and plan
edits. Such a step is tagged **headless** — it runs with the decision carried
in, asks nothing, and its arm writes without a second gate when the draft
matches its own. The exception is `/task-add`, the one owner whose work is
drafting: its create and reconcile steps are tagged **GATED**, carry one
`Will ask:` line naming what their own gate will ask, and sort last wherever
the order allows, so every headless write lands before the first stop. This
is what turns a revision from a chain of gates into one gate: the analysis is
paid once, up front, where the user can see all of it at the same time.

**Tiers.** Each item's branch still judges how far its sequence reaches —
editorial (the one step that writes the anchored artifact), local (plus the
entries that merely cite it), structural (everything the walk reached) —
editorial only when the change is wording only, nothing downstream changes
meaning, and the editorial sequence is that one step. Insert, delete and
reorder are never editorial. Only a borderline wording-versus-meaning
classification stays open, and it is asked at the plan gate in
`/architect amend`'s own question form, with the answer carried into the step.

**One gate, and it always waits.** Nothing is written before it, by the skill
or by any arm it drives. It carries the verdict line, the items as split with
their branch and anchor, the artifacts touched and the ones judged untouched
so a call can be overruled, the numbered owner steps with their tag,
invocation, what each writes, the decision each carries or its `Will ask:`
line, the lint findings each clears or creates, and any architect question
still open. The reply edits the plan by number — run it, drop steps, move a
step below another, defer a step to a runbook, answer an open question, or
stop — and any edit re-renders the plan at the same gate. Deferral is per
step: a deferred step is appended to a runbook, self-contained, carrying every
decision taken at the gate, which is what lets a long plan be half run and
half scheduled without splitting the analysis.

**Verification bracket.** The scoped lint runs before the proposal, so the
plan starts from the true state, and again after actuation, and the report
shows the difference. This is the step that makes the downstream cost visible
at revision time rather than at implementation time. The reviser also reads
the successor tasks' bodies where an insertion or deletion changed a
precondition, to confirm the sequence still reads as a sequence — the check
nothing automated performs today.

**Actuation.** Steps run in the session, one at a time, sequentially, a
headless step through its owner's arm by path and a gated step through the
owner's command with that owner's own gate intact. A step an earlier step's
outcome made moot is dropped with a line saying why; no step is added after
the gate. Deferred steps go to `/runbook-create --append` once the in-session
steps have run; the reviser never writes a line of the runbook itself.

**The closing follow-up gate.** Execution surfaces things the plan could not
hold: a task `/task-add` created that no open runbook has a step for, a
successor that no longer reads as a sequence, a lint finding created, a
feature an owner named for reconciliation that no step ran. These go to a
second gate in the same numbered shape with the same reply grammar, skipped
when nothing arose. Without it, either the skill writes past its own gate or
the follow-up is left to a report nobody re-reads; this keeps the rule that
nothing is written without a reply while still closing the loop in the same
session.

**Deletion.** The delete branch maps removal onto the existing vocabularies:
`[SKIP]` with reason for a task, struck for a runbook step, `[SKIP]` on every
task plus a `/production-plan` run to drop edges for a feature. History is
never lost from a live index.

## Data and state

No new stored state. The tiers, the touched set and the owner sequence exist
only in the proposal at the gate. What persists is written by owners in the
existing vocabularies: `[STALE]`, `[ITERATED]`, `[SKIP]`, `Preconditions:`,
`Tasks:`, struck steps, a runbook when a step was deferred to one. Provenance
is the revision's one commit and the runbook's `Done:` lines; no change ledger
is introduced.

## Interfaces and contracts

- `/pipeline-revise "<change set>" [--no-commit] [--no-push]` — the general
  form: one item or many, each anchored by the text or by the argument.
- `/pipeline-revise <anchor> "<change>" [--no-commit] [--no-push]` — the same
  run with one item; anchor is `feature=<slug>`, `task=<N>` or
  `runbook=<id|name|id-name> step=<n>`, and an item's own text may name a
  roadmap milestone instead.
- One gate, always waiting; steps sequential and in-session; per-step
  deferral to a runbook. Every owner step runs uncommitted; the revision lands
  as one commit, made at the end.
  `requires: skill:pipeline-engine, skill:architect, skill:task-engine,
  skill:runbook-run, skill:product-design, skill:production-plan,
  skill:product-roadmap`.
- Hard contracts: it writes no line an owner owns; bodies are opened only
  within an item's scope; every decision an arm makes by a closed rule is made
  at plan time and shown, a headless step therefore asking nothing and a gated
  step announcing at the gate what it will ask; the editorial classification
  carried to an `/architect amend` step — decided at plan time, or the user's
  reply when the arm's rule left it ambiguous — is applied there without a
  prompt when the arm's findings agree and confirmed when they disagree; a
  runbook is never written without the user's reply; the lint runs before and
  after every run; nothing on the closing gate is written without the reply.

Failure contract: an anchor that resolves to nothing, or an item that names
no artifact at all, stops the whole run by listing what exists; a step whose
owner is not installed stops before the gate; an owner arm that refuses, such
as a touched `[IN PROGRESS]` task, stops the sequence at that step with
earlier steps' writes intact and reported, never rolled back, and left
uncommitted; `/runbook-create` absent makes a deferral an error naming it and
re-renders the plan.

## Dependencies

- **[backlog-ordering](./backlog-ordering.md)** — insertion primitives the
  insert branch composes.
- **[pipeline-engine](./pipeline-engine.md)** — probes, graph, routing, lint.
- **[owner-amend-arms](./owner-amend-arms.md)** — every write it makes goes
  through an arm or an owner command.
- **[runbook-suite](./runbook-suite.md)** — optional target of a deferred
  step.
- **[production-plan](./production-plan.md)** — reconciliation the delete
  branch invokes to drop edges.
- Documentation to update when this lands: `README.md`, `docs/reference.md`,
  `.claude/domain/product-workflow.md` (the revision section and the
  who-writes-what note that the surface owns nothing),
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
- **Where does a revision that changes a roadmap milestone go?** Decided: a
  milestone is an anchor of its own, named in an item's text and resolved
  against `product-roadmap.md`, and every roadmap edit in a change set merges
  into one `/product-roadmap amend` step sequenced ahead of the feature
  documents. It needs no branch of its own — a milestone line is an amend.
