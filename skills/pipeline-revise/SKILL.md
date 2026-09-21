---
name: pipeline-revise
version: 1.0.0
type: skill
description: Revise already-planned work — a set of changes to feature documents, tasks, plan edges and runbook steps — through the owners of every artifact they reach, as one numbered plan behind one gate. Use it for any change to work that is already planned, from one wording fix to a list of amendments, deletions, insertions and reorders.
requires: skill:pipeline-engine, skill:architect, skill:task-engine, skill:runbook-run, skill:product-design, skill:production-plan, skill:product-roadmap
---

# /pipeline-revise
# Global skill: carry a change set — one change or many, free-form or a
# pasted numbered list — to already-planned work through every artifact it
# reaches, by classifying each item, walking its impact over the index
# graph, merging the items into one ordered owner sequence, deciding at plan
# time everything an owner's arm decides by a closed rule over its reads,
# and showing the whole thing once as a numbered plan. The gate always
# waits; the reply edits the plan by number — go, all but N, N as runbook
# step, N after M, stop. Steps tagged headless run their owner's arm with
# the decision carried in and ask nothing; steps tagged GATED (/task-add)
# announce at the gate what their owner will ask. Runs /pipeline-check
# before the plan and after the sequence; what execution surfaces beyond
# the plan is put to one closing follow-up gate in the same shape, never
# written on its own. Writes nothing itself. Removal is [SKIP] or a struck
# step, never physical deletion. One commit at the end holds the whole
# revision; a sequence that stops part-way commits nothing.
# Usage: /pipeline-revise "<change set>" [--no-commit] [--no-push]
#        /pipeline-revise <anchor> "<change>" [--no-commit] [--no-push]
#        anchor: feature=<slug> | task=<N> | runbook=<id|name|id-name> step=<n>
# Examples: /pipeline-revise task=42 "Hints: point at the new loader"
#           /pipeline-revise "drop the contact URL from the user-agent (source-inventory, line 178); delete task 214; strike runbook 3 step 9"
#           /pipeline-revise "1. /architect amend feature=a,b: … 2. delete task 214 3. move exit criterion 160 to m3"

GOAL
A design decision or a planned task changes after planning, and it rarely
changes alone. Without this skill every affected artifact needs its own
command run and its own gate, and the user carries the sequence — and the
risk of the forgotten step. This skill carries it instead: it takes every
change at once, finds what each reaches, orders the owners that must write
them, shows the whole plan once, and runs it.

The heavy half is analysis. The writing is always the owners'.

$ARGUMENTS

---

THE ENGINE AND THE OWNERS

What this skill knows about the pipeline as a whole is `pipeline-engine`'s,
read by path:

- `../pipeline-engine/references/probes.md` — the probe, its verdict line
  and the reuse rule;
- `../pipeline-engine/references/graph.md` — the edges between the indexes,
  and **the impact walk's only traversal input**;
- `../pipeline-engine/references/routing.md` — which owner each line belongs
  to, and, in its Amend column, the arm a revision routes through;
- `../pipeline-engine/references/lint.md` — the findings the verification
  bracket compares.

Every write goes through an owner: the amend arm `routing.md`'s Amend column
names, executed by path, or the owner's own command. The branch files name
each by path at the step that uses it. This skill restates no probe, no
edge, no finding and no arm's rule.

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `./amend.md` | An item changes something that exists and adds, removes or moves nothing — a `Preconditions:` change that moves no entry included. |
| `./insert.md` | An item makes a new task or runbook step exist at a position — with the scope its feature document must newly promise, when it must. |
| `./delete.md` | An item ends a live task, a pending runbook step or a whole feature. |
| `./reorder.md` | An item moves an existing task or runbook step to another position. |

A run reads the branch file of every kind its items classify into, each
once, and never one no item needs. All four share one schema — the same
seven sections in the same order: *Applies when*, *Impact walk*, *Owner
sequence*, *Tier*, *Verification*, *Outcomes*, *Never* — so this file refers
to a section of "the branch file" without caring which one is open.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--no-commit` flag (COMMIT = false), the
optional `--no-push` flag (NO_PUSH = true) and the optional `--commit` flag,
and strip all three. COMMIT is true unless `--no-commit` is passed;
`--no-commit` implies NO_PUSH. `--commit` is accepted and changes nothing.
`--commit` and `--no-commit` together stop the run with:
`--commit and --no-commit cannot be combined. Pick one.` What each flag does
is COMMITTING.

Then scan for an anchor in one of three forms, and strip it:

- `feature=<slug>`
- `task=<N>`
- `runbook=<id|name|id-name> step=<n>`

What remains is the **change set**, as one quoted string. An empty change
set stops with: `/pipeline-revise needs the change to make, e.g. /pipeline-revise task=42 "Hints: point at the new loader".`

**Items.** The change set is one or more items. A numbered list — the shape
`/follow-ups` prints, one `<n>.` per line, each a command form or a
sentence — is one item per number. Free-form text is split into items at
the changes it describes: each distinct thing to change, insert, delete or
move is one item, and a sentence naming two is two. An anchor argument
applies to every item that names no artifact of its own; an item that names
one uses its own. Say the items back, numbered, in the gate; the split is
the user's to correct there.

---

WORKFLOW

**1. Probe.** Run the probe from `probes.md`, or reuse a verdict line
already in the conversation where that file's reuse rule allows. The
verdict line is also where step 6 reads which owners are installed.

**2. Resolve each item's anchor.** Per item, in order:

- `feature=<slug>` — an entry in `.claude/FEATURES.md`. None, or no feature
  index at all, stops: `No feature <slug> in .claude/FEATURES.md. Available: <slug>, <slug>.`
- `task=<N>` — a summary block `## <N>.` in `.claude/TASKS.md`. An id at or
  below `Last task number:` with no block is archived and terminal, per
  `../task-engine/references/resolution.md` § *The archive*; one above it was
  never assigned. Either way stop, say which, and list the live tasks, id
  and title.
- `runbook=<id|name|id-name> step=<n>` — the runbook resolved by
  `../runbook-run/references/runbook-schema.md` § *Resolving a runbook
  argument*; one that does not resolve stops listing the runbooks in
  `.claude/RUNBOOKS.md`. The step by id in its body — the item's target
  artifact, read here; an unknown id stops listing the runbook's steps.
- **A milestone** — named in the item (`m3`, `m3-teams`, an exit criterion
  quoted from it) — resolves to a `##` block in
  `.claude/domain/product-roadmap.md`; none stops listing the milestones.
  This anchor has no argument form: only an item names it.

An item with no anchor argument and none named in its text stops the whole
run before the gate, naming that item and the four anchor forms, and
listing what exists. Never pick between two. A stop here writes nothing.

**Pull at start.** Once every item resolves, and before any walk, pull once
for the whole run per COMMITTING — skipped under `--no-commit` or
`--no-push`.

**3. Classify each item.** Put each item into exactly one branch, testing
in this order; the first that matches wins:

1. **reorder** — an existing task or runbook step is to run at a different
   position;
2. **delete** — a live task, a pending runbook step or a whole feature is to
   stop being work;
3. **insert** — a new task or runbook step is to exist;
4. **amend** — anything else that changes what exists, a milestone line and
   a `Preconditions:` change that moves no entry included.

Read each branch file the items need, once. Render `Item <i>: <branch> —
<anchor>` for every item in the gate.

**4. Walk each item's impact.** From its anchor, along `graph.md`'s edges
and no other traversal, in the directions its branch file's *Impact walk*
gives. Index lines come first: every entry the walk reaches is named from an
index line. Bodies are opened within one scope per item, stated here and
never widened:

- **the target artifact** — the anchored feature's `Doc:` document (with the
  `product-design.md` section its `Source:` names, when the change lands in a
  design decision), the anchored task's `.claude/tasks/<N>.md`, the anchored
  runbook's body, or the roadmap;
- **the tasks whose `Preconditions:` name it or whose `Files:` overlap** —
  for a task anchor, the tasks naming `<N>` and those sharing a path with its
  `Files:`; for a feature anchor, the same for each of its live task ids;
- **the runbook steps that name it** — each open runbook `graph.md` E7 names
  as a candidate, opened through E6 only to find the steps naming the
  anchor's slug or one of its task ids;
- **what a headless owner's arm reads to decide** — step 6 makes each
  arm's decision from the reads that arm names, so those reads are in scope
  here: for `/architect amend`, the `.claude/TASKS.md` summary blocks of the
  feature's tasks and a task body only when its block cannot decide.

Every node is visited once across the whole change set: an artifact two
items reach is one entry in the proposal.

**5. Lint — before.** Run `/pipeline-check` scoped to the union of the
items' features — one `/pipeline-check feature=<slug>` per feature reached,
or `/pipeline-check` unscoped when any item anchors on a runbook or a
milestone, or names a task whose `Feature:` does not resolve. When
`/pipeline-check` is not installed, evaluate `lint.md` directly over the
indexes and keep the findings whose identifier is an anchor or an entry a
walk reached, rendered from their templates unchanged. Keep the findings:
step 9 compares against them.

**6. Propose.** Build the plan from the branch files, then merge, order and
decide.

*Merge.* The owner steps of every item, as one set. Two items that reach
the same artifact become one step: several sections of one feature document
are one `/architect amend feature=<slug>` naming them all; several feature
documents are one `/architect amend feature=<a>,<b>` run; several edits to
one task are one task amend; every roadmap edit is one `/product-roadmap
amend`, every plan edit one `/production-plan amend`, every design-decision
edit one `/product-design amend`; the runbook steps of one runbook are one
`/runbook-create --append` when they insert, and one step each when they
strike or add a `Context:` fact.

*Order.* Upstream first, as every branch file orders its own sequence, and
across items: design decision, then feature documents, then task amends,
then removals (`[SKIP]`), then task insertions and `/task-add`
reconciliation, then the plan, then runbook strikes, facts and insertions.
A step whose input is another step's output — a runbook step for a task an
earlier step creates — comes after it, whatever the kinds say. The user
moves steps at the gate; the plan states this order once.

*Decide.* Every decision an owner's arm makes by a closed rule over its
reads is made here, from the reads step 4 put in scope, and shown on its
step:

- `/architect amend` — the editorial classification per feature, by
  `../architect/amend.md` § 4's clear-or-ambiguous rule over the touched set
  and the scope call; an ambiguous feature is asked **at this gate**, in that
  arm's question form, and the answer is carried in;
- a task amend — the drafted fields and body sections, per
  `../task-engine/references/amend.md`;
- a runbook strike, `Context:` fact or insert — the struck id and reason,
  the dated fact, or the step's prompt, per
  `../runbook-run/references/step-amend.md`;
- the design, roadmap and plan arms — the drafted edit, per
  `../product-design/amend.md`, `../product-roadmap/amend.md` and
  `../production-plan/amend.md`.

Such a step is tagged **headless**: it runs with the decision carried in
and asks nothing. A `/task-add` create or reconcile step — the one owner
whose work is drafting — is tagged **GATED** with one `Will ask:` line
naming what it will ask (approve the drafted bodies; the design-change
question; the orphan question). Gated steps sort last wherever the order
above allows, so every headless write lands before the first stop.

A reconciliation step is conditional and shows its evidence: `because step
1 stales 12, 14`, or `because step 1 adds scope no task covers`; when step
1's carried classification is editorial for every feature, no reconciliation
step is rendered. An id unknown until a step runs is a placeholder in every
later step that needs it: `<id from step 5>`.

Before rendering, every owner a step needs must be installed — read off the
verdict line's `installed` field. A step whose owner is missing stops the
run here, before the gate and before any write:

> Can't revise: step <i> needs `<owner>`, which is not installed. Install it
> with `chosko-llm add`, then re-run.

**7. The gate.** One message, and it always waits. It carries:

1. the verdict line;
2. the items, numbered as split, each with its branch, anchor and the tier
   its branch file judged — `Item 2: delete — task=214 — structural`;
3. the touched artifacts — each entry a walk reached, with the edge or the
   body read that reached it — and, one line each, the entries examined and
   judged untouched, so a call can be overruled;
4. the owner steps, numbered, in order, each on the shape
   `<n>. <owner> — <headless | GATED> — <invocation or arm path> — writes: <what>`,
   followed by the decision carried (`Classified: editorial — …`, the draft
   in before → after form, the struck id and reason) or the `Will ask:`
   line, and the lint findings it clears or creates;
5. the lint — step 5's findings in scope;
6. any architect question still open, in `../architect/amend.md` § 4's
   ambiguous form, one per feature.

Then wait for the reply. The reply grammar:

- `go` — run the plan as rendered;
- `all but <n>[, <m>]` — drop those steps and run the rest;
- `<n> as runbook step` — defer step n: it is appended, as one
  self-contained step carrying its invocation, anchor, change and every
  decision taken here, to the runbook the reply names, or to the runbook
  this session is running, or, naming none, to a new runbook
  `/runbook-create` creates from the deferred steps; `all as runbook
  steps` defers the whole plan;
- `<n> after <m>` — move step n below step m;
- a letter for an open architect question (`a: A`), or an overruled
  touched/untouched call or tier, as the arm's own reply rules allow;
- `stop` — write nothing.

Any reply but `go` and `stop` re-renders the plan at the same gate, with
the edit applied, and waits again. A step the reply drops that another step
depends on drops that step too, named. Silence, an unclear reply or EOF is
`stop`. Nothing is written before `go`, by this skill or by any arm it
drives.

**8. Actuate.** Run the steps one at a time, in order — never in parallel,
never in a subagent. Before each, one line: `Step <i>/<k> — <owner>:
<invocation>`. A headless step executes its arm from its file by path, with
the decision carried in: `/architect amend` receives the classification per
feature, `../architect/amend.md` § 4 *A classification carried from
`/pipeline-revise`*; the design, roadmap and plan arms receive the draft, and
write without a gate when it matches theirs; the task and runbook arms
receive their drafted content. A gated step runs its owner's command as the
user would invoke it, with the owner's own gate asked exactly as the owner
asks it. Every step runs without committing, per COMMITTING. After each, its
closing line, as the owner writes it.

A later step that an earlier step's outcome made moot — a reconciliation
whose `/architect amend` staled nothing after all — is dropped with one line
saying why. A step is never added after the gate; what execution surfaces
goes to step 10.

*Deferred steps.* Once the in-session steps have run, invoke
`/runbook-create --append <runbook> --after <step>` (or `/runbook-create
<name>` for a new runbook) with the deferred steps as its follow-up list,
in plan order, each prompt self-contained, and `--no-commit`.
`/runbook-create`'s own gate decides what is written; this skill writes no
line of the runbook.

**9. Lint — after, and verify.** Run step 5's scoped `/pipeline-check`
again — also when the sequence stopped part-way, so the report shows the
state it left. Report the difference: findings cleared, findings created,
findings unchanged.

Where an insertion or a deletion changed a precondition, read the successor
tasks' bodies afterwards — the tasks whose `Preconditions:` gained or lost
an id — and confirm the sequence still reads as a sequence. The branch
file's *Verification* says when this applies.

**10. The closing follow-up gate.** What execution surfaced and the plan
did not hold: a task a `/task-add` step created that no open runbook
running its feature has a step for; a successor that no longer reads as a
sequence; a lint finding step 9 reports as created; a feature an owner's
closing line names for reconciliation that no step ran. When there is
nothing, skip this step. Otherwise render the items numbered, in step 7's
step shape with a proposed owner step each, and wait, with step 7's reply
grammar: `go` runs them here, one at a time as step 8 does; `<n> as runbook
step` defers; `all but`; `stop` leaves them to the report. Nothing on this
list is written without the reply. When anything ran here, step 9's scoped
check runs once more afterwards, and the difference step 12 reports is
measured from that run.

**11. Commit.** When the sequence completed — a step dropped as moot or by
the reply still counts as completed — and at least one step wrote, the
runbook `/runbook-create` wrote for deferred steps included, make the
revision's one commit and push, per COMMITTING, the report line below as
the subject. A sequence that stopped part-way, a run that wrote nothing, or
`--no-commit` makes no commit.

**12. Report.**

```
Revised <items> items — <run>/<k> owner steps run, <d> deferred, <m> dropped.
```

then each step's closing line, the lint difference (`Lint: cleared <n>
(<L-ids>), created <n> (<L-ids>), unchanged <n>.`), the sequence check's
result, the follow-ups the closing gate left to the report, and every
follow-up an owner named that no step covered. Then the commit hash. When
anything was written and no commit was made — `--no-commit`, or a sequence
that stopped part-way — list every path written so far and end with an
explicit reminder that nothing was committed.

---

COMMITTING

This skill owns the run's commit. A revision is one unit of work, so it
lands as exactly one commit, made at the end — never one per owner step.
Commit and push gating is `../task-engine/references/commit.md`.

- **Pull at start** — once per run, after every item resolves and before
  the walks (WORKFLOW step 2), unless `--no-commit` or `--no-push`. A
  conflict stops the run there, nothing written.
- **Every owner step runs uncommitted.** A command owner — `/task-add`,
  `/runbook-create` (`--append` included) — always receives `--no-commit`,
  whatever its own default. An arm executed by path — `architect`'s
  `amend.md`, `product-design`'s, `product-roadmap`'s and
  `production-plan`'s `amend.md`, `task-engine`'s `references/amend.md`,
  `runbook-run`'s `references/step-amend.md` — is executed with no commit.
  No owner step pulls or pushes.
- **One commit.** After the closing follow-up gate, stage exactly the union
  of the paths the owner steps reported writing — a runbook `/runbook-create`
  wrote for deferred steps included — by explicit path, and commit once, the
  `Revised …` report line as the subject. Then re-sync and push per
  `commit.md`'s push protocol, the push skipped under `--no-push`. Report
  the hash.
- **No commit** on a stop before the gate, `stop` at either gate, a
  sequence that stops part-way (an owner refuses, or its gate is answered
  stop), a run that wrote nothing, or `--no-commit`. A partial sequence is
  left uncommitted on purpose: every commit holds a complete revision, and
  step 9 already reports the state the stopped sequence left.

---

WRITE SET

Closed, and empty: this skill writes no line any owner owns, and no file of
its own — no index line, no body, no runbook, no report on disk. Every write
in a run is an owner step's, through an arm or an owner command, after the
gate. Its commit stages only those writes.

---

FAILURE CONTRACT

- **An item whose anchor resolves to nothing** stops the whole run by
  listing what exists (step 2). Nothing is written.
- **A step whose owner is not installed** stops before the gate (step 6).
  Nothing is written.
- **An owner that refuses** — a touched `[IN PROGRESS]` task, a `[DONE]`
  task, a position on a `[RUNNING]` runbook its arm will not take — or a
  user who answers stop at a gated owner's own gate, **stops the sequence at
  that step.** Earlier steps' writes stay intact, uncommitted, and are
  reported path by path, **never rolled back**; the steps not run are
  listed; step 9 still runs; nothing is committed.
- **`/runbook-create` absent** makes `as runbook step` an error naming it;
  the plan is re-rendered.
