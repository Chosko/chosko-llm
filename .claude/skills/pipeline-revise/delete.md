# Branch: delete — an entry stops being work

Read this when `./SKILL.md`'s CLASSIFY chose delete. With `./SKILL.md` it is
the whole branch: a consumer that has read both can execute a deletion end
to end. Write nothing yourself — every step below names, by path, the arm it
delegates to.

---

## Applies when

A live task, a pending runbook step or a whole feature is to stop being
work. None of the three shapes, one per kind of entry, removes anything:
each maps removal onto an existing vocabulary. An entry
that is to run somewhere else instead is `./reorder.md`'s.

## Impact walk

Walk over `graph.md`'s edges, named by id.

- **Forward** — to the successors whose `Preconditions:` name the removed id
  (E4); each such edge is dropped. For a feature, these are the successors
  of every task being skipped that lie outside the feature. Also forward to
  the open runbooks whose steps run the removed task or name the removed
  feature (E7).
  - **From each successor whose edge is dropped, and whose basis is thereby
    withdrawn, continue upward as from the anchor**: to that task's own
    feature document when its `Feature:` slug resolves (E3b, then E2),
    stopping there on a missing or unresolved slug exactly as below.
  - Where the dropped edge is immediately replaced by one carrying the same
    spec — a reorder, which composes this walk with `./insert.md`'s, per
    `./reorder.md` — nothing is withdrawn; do not continue from that
    successor.
  - Visit every node once. A document reached this way is named from index
    lines and enters the owner sequence as a step 1 entry — never opened
    here, exactly as for the anchor's own.
- **Upward** — to the feature document that promised the deleted scope (E3b,
  then E2).
  - A task with no resolvable `Feature:` has no upward walk.
  - A feature's removal walks no further up: its entry and the design
    section its `Source:` names stay as they are.

## Owner sequence

Upstream first. A step is in the sequence when the walk reached its
artifact and the tier keeps it.

**A task.**

1. **The promise** — `/architect amend feature=<slug> "<withdraw the promise>"`,
   executed from `../architect/amend.md` by path, when the feature document
   promises the deleted scope.
2. **The removal** — `Status: [SKIP]` with a dated reason in the task's
   `## Decisions`, through `../task-engine/references/amend.md`
   § *Deleting a live task*.
3. **Each successor's edge** — dropped through the same reference, on the
   successor's own `Preconditions:` line. Name the drop in that task's
   `## Decisions`, with a reason naming the deletion.
4. **Each runbook step that runs the task** — struck, as below.

**A runbook step.** The strike alone: marker `[x]` with a `Done:` line
opening `struck — <reason>` and no commit sha, through
`../runbook-run/references/step-amend.md` § *Strike*. Never delete or
renumber a step.

**A feature.**

- `[SKIP]` on every one of its live tasks — step 2 for each, in
  `.claude/TASKS.md` order;
- then step 3 for their successors outside the feature;
- step 4 for the runbook steps naming the slug or its tasks;
- last, `/production-plan amend "<the removal>"`, executed from its arm,
  `../production-plan/amend.md`, by path, which drops the plan edges naming
  the slug and unschedules it, with the diff drafted at plan time carried
  in. Never drop a plan edge by hand: `/production-plan` is invoked, not
  imitated.

The feature's `.claude/FEATURES.md` entry stays, with its ids intact: an
entry whose tasks are all `[SKIP]` and whose edges are dropped is inert. The lint after reports it as
L11, a `[PLANNED]` feature whose work has all resolved; its `Status:` stays
its owners' to set, since no feature status means *removed* and this branch
invents none.

**Physical removal is never performed here.** Never remove a summary block,
a body, a feature entry, a runbook step or a runbook, and never renumber a
task or a step. Removing a summary block from the backlog stays
`/task-clean`'s explicit act over terminal statuses — `[SKIP]` is what makes
a task eligible for it — and deleting a runbook stays `/runbook-clean`'s.

**`[DONE]` work is never reopened, re-statused or removed**, in any of the
three shapes: a `[DONE]` task is not skipped, a step already `[x]` or `[!]`
is not struck, and a feature's `[DONE]` tasks stand while its live ones are
skipped. Each arm refuses the first two itself; this branch never proposes
them.

## Tier

- **Local** — deleting a task no other entry names: no successor, no
  runbook step, no promise in its feature document beyond the task itself.
  Step 2 alone.
- **Structural** — a deletion that crosses artifacts, or that drops an edge.
  The full sequence the walk reached.

Neither tier is editorial, so the gate
classifies it not editorial without asking the question, per `./SKILL.md`
step 6: the `Classified:` line names the removed entry, and under structural
the artifacts it crosses or the edge it drops.

## Verification

When the deletion dropped an edge, `./SKILL.md` step 9's successor read
applies: after actuation, read the bodies of the successor tasks whose
`Preconditions:` lost an edge, and confirm the sequence still reads as a
sequence — nothing a successor's body relies on was delivered only by the
removed task.

## Outcomes

No new status value and no change ledger. A deletion's provenance is the
`[SKIP]` and its dated reason in `## Decisions`, the struck step's `Done:`
line, and the revision's one commit; nothing else records it.

## Never

- Write anything itself, or replace a step's arm with a direct edit.
