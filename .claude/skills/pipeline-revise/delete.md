# Branch: delete — an entry stops being work

Read this when `./SKILL.md`'s CLASSIFY chose delete. Together with
`./SKILL.md` it is the whole branch: a consumer that has read both can execute
a deletion end to end. It writes nothing itself — every step below names, by
path, the arm it delegates to.

---

## Applies when

A live task, a pending runbook step or a whole feature is to stop being work.
There are three shapes, one per kind of entry, and each maps removal onto a
vocabulary that already exists. None of them removes anything. An entry that
is to run somewhere else instead is `./reorder.md`'s.

## Impact walk

Over `graph.md`'s edges, named by id.

- **Forward** — to the successors whose `Preconditions:` name the removed id
  (E4); each such edge is dropped. For a feature, that means the successors
  of every task being skipped that lie outside the feature. Also forward to
  the open runbooks whose steps run the removed task or name the removed
  feature (E7).
- **Upward** — to the feature document that promised the deleted scope (E3b,
  then E2), so that it stops promising work nobody will do. A task with no
  resolvable `Feature:` has no upward walk. A feature's removal walks no
  further up: its entry and the design section its `Source:` names stay as
  they are.

## Owner sequence

Upstream first. A step is in the sequence when the walk reached its artifact
and the tier keeps it.

**A task.**

1. **The promise** — `/architect amend feature=<slug> "<withdraw the promise>"`,
   executed from `${CLAUDE_HOME:-$HOME/.claude}/skills/architect/amend.md` by
   path, when the feature document promises the deleted scope.
2. **The removal** — `Status: [SKIP]` with a dated reason in the task's
   `## Decisions`, through
   `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/amend.md`
   § *Deleting a live task*.
3. **Each successor's edge** — dropped through the same reference, on the
   successor's own `Preconditions:` line. The drop is named in that task's
   `## Decisions`, and the reason given there names the deletion, so a later
   reader can see why the precondition vanished.
4. **Each runbook step that runs the task** — struck, as below.

**A runbook step.** The strike alone: marker `[x]` with a `Done:` line opening
`struck — <reason>` and no commit sha, through
`${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/step-amend.md`
§ *Strike*. A step is never deleted and never renumbered.

**A feature.** `[SKIP]` on every one of its live tasks — step 2 for each, in
`.claude/TASKS.md` order — then step 3 for their successors outside the
feature, step 4 for the runbook steps naming the slug or its tasks, and last a
`/production-plan` run given the removal as its free-form context, whose
reconciliation drops the plan edges naming the slug, at its own gate. The
feature's `.claude/FEATURES.md` entry stays, with its ids intact: an entry
whose tasks are all `[SKIP]` and whose edges are dropped is inert, and
nothing that was planned — or why — is erased. The lint after reports it as
L11, a `[PLANNED]` feature whose work has all resolved; its `Status:` stays
its owners' to set, since no feature status means *removed* and this branch
invents none.

**Physical removal is never performed here.** Removing a summary block from
the backlog stays `/task-clean`'s explicit act over terminal statuses —
`[SKIP]` is what makes a task eligible for it — and deleting a runbook stays
`/runbook-clean`'s.

**`[DONE]` work is never reopened, re-statused or removed**, in any of the
three shapes: a `[DONE]` task is not skipped, a step already `[x]` or `[!]` is
not struck, and a feature's `[DONE]` tasks stand while its live ones are
skipped. Each arm refuses the first two itself; this branch never proposes
them.

## Tier

- **Local** — deleting a task no other entry names: no successor, no runbook
  step, no promise in its feature document beyond the task itself. Step 2
  alone.
- **Structural** — a deletion that crosses artifacts, or that drops an edge.
  The full sequence the walk reached.

Under the gate's A, the sequence keeps only the removal itself — step 2, or
the strike — and the gate shows the L4 findings that leaving the successors'
edges in place will create.

## Verification

When the deletion dropped an edge, `./SKILL.md` step 9's successor read
applies: after actuation, read the bodies of the successor tasks whose
`Preconditions:` lost an edge, and confirm the sequence still reads as a
sequence — nothing a successor's body relies on was delivered only by the
removed task.

## Outcomes

No new status value and no change ledger. A deletion's provenance is the
`[SKIP]` and its dated reason in `## Decisions`, the struck step's `Done:`
line, and the commits the owner steps make. Nothing else records it, and
nothing needs to.

## Never

- Write anything itself, or replace a step's arm with a direct edit.
- Remove a summary block, a body, a feature entry, a runbook step or a
  runbook; renumber a task or a step.
- Touch a `[DONE]` task or a step already `[x]` or `[!]`.
- Drop a plan edge by hand: `/production-plan` is invoked, not imitated.
