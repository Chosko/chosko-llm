# Branch: amend — something that exists changes

Read this when `./SKILL.md`'s CLASSIFY chose amend. Together with `./SKILL.md`
it is the whole branch: a consumer that has read both can execute an amend
end to end. It adds no read of its own beyond the anchor scope `./SKILL.md`
step 4 fixes, and it writes nothing itself — every step below names, by path,
the arm it delegates to.

---

## Applies when

Something that already exists changes, and nothing is added, removed or
moved: a design decision in `product-design.md`, a section of a feature
document, a task's body or summary fields, a `Preconditions:` edge added to or
dropped from a task that stays where it is, a fact about a pending runbook
step, or a step's prompt — which `step-amend.md` turns into a strike and a
corrected insert itself, and which is still one amend here.

A change that moves an entry is `./reorder.md`'s; one that makes a new entry
is `./insert.md`'s; one that ends an entry is `./delete.md`'s.

## Impact walk

Over `graph.md`'s edges, named by id.

**Top-down** — from a design section or a feature document:

- a design section → every feature whose `Source:` names it (E1), and each
  one's document (E2);
- a feature document → the tasks carrying that `Feature:` — the live ids on
  its `Tasks:` line (E3a); the `PLAN.md` edges naming the slug (E5); and the
  runbook steps naming the slug or one of its task ids — every open runbook is
  a candidate (E7), confirmed within `./SKILL.md`'s body scope.

**Bottom-up** — from a task:

- to the feature document that promised it, when its `Feature:` slug resolves
  in `.claude/FEATURES.md` (E3b, then E2). **A `Feature:` slug that resolves
  to nothing, or no `Feature:` line at all, stops the upward walk**: the task
  is treated as free-form and amended on its own, and that is not an error. An
  unresolved slug still surfaces — as the lint bracket's finding, not as a
  walk failure;
- and forward to the tasks whose `Preconditions:` name it (E4), when the
  change alters what the task delivers — they build on it. **From each such
  task the walk continues exactly as it did from the anchor**: up to that
  task's own feature document when its `Feature:` slug resolves in
  `.claude/FEATURES.md` (E3b, then E2) — a missing or unresolved slug stops
  it there, as for the anchor and for the same reason — and then forward
  again from it (E4). A successor whose basis does not change is not walked
  from: the condition on this bullet applies at every hop, not just the
  first.

Every node is visited once. A task or feature document the walk has already
reached is not walked from a second time, which is what terminates the walk
on a backlog whose edges rejoin.

A feature document reached this way is **named, not opened**. It comes from
the index lines the walk has already read — the task's `Feature:` and that
entry's `Doc:` — and enters the proposal as a step 2 entry of the owner
sequence below, like the anchor's own document. Whether it really needs a
change is `/architect amend`'s to judge when its arm opens it, and that arm
may answer **Stop**; a step that turns out to change nothing is the accepted
cost of catching one that does. `./SKILL.md` step 4's body scope is unchanged
by this — it lists the bodies this branch may open, and a reached document is
not one of them.

From a runbook step, the walk reads the step's prompt in the body the anchor
already opened, goes up to the tasks and features it names, and continues
from each as above.

## Owner sequence

Fixed, and upstream first. A step is in the sequence when the walk reached
its artifact and the tier keeps it; the order never changes.

1. **A design decision** — `/product-design`'s amend arm,
   `../product-design/resuming.md` § 6,
   reached by re-running `/product-design` on a completed design process and
   choosing its amend arm. On a process that is not complete the arm is not
   offered — an owner refusing, under `./SKILL.md`'s failure contract.
2. **Each feature document** — `/architect amend feature=<slug> "<change>"`,
   executed from its arm,
   `../architect/amend.md`, by path. One
   step per feature, in `.claude/FEATURES.md` order. Never the full
   `/architect`: the arm's precision guard stales only the tasks the change
   touches, where the blanket guard would stale every one.
3. **The tasks** — in one of two forms per feature, both rendered at the
   gate, because which one runs depends on step 2's answer, which the gate
   cannot know:
   - **(a) Per-task amends** — each task's body and summary fields through
     `../task-engine/references/amend.md`,
     one step per task, in `.claude/TASKS.md` appearance order. A
     `Preconditions:` edge is added or dropped here, on the dependent's own
     line, the drop narrated in its `## Decisions` — that arm's rule. The
     form when step 2 stales nothing and leaves the feature's `Status:`
     unchanged, and always the form for a task with no feature step 2 ran.
   - **(b) Reconciliation** — one owner step,
     `/task-add feature=<slug> "<annotation>"`, the reconciliation run. The
     form when step 2 stales any task, or moves the feature to `[ITERATED]`
     for scope no existing task covers. Reconciliation is the one clearer of
     `[STALE]` — `task-engine/references/stale.md` § *Clearing it* — and it
     rewrites each stale body in place, skips-and-replaces one whose goal no
     longer survives, drafts tasks for the added scope and returns the
     feature to `[PLANNED]`. So under (b) **no per-task amend runs for a task
     step 2 staled**: its new body is reconciliation's to write.
     A task step 2 did **not** stale whose own summary fields or body must
     still change — a `Preconditions:` edge on its own line, say — keeps its
     per-task amend, and that amend runs **before** the reconciliation step.
     Reconciliation classifies every task the feature generated as its
     summary block and body stand when it reads them, and drafts new tasks
     against the edges it finds; run first, the amend hands it the final
     state, where run after it would edit a backlog reconciliation has
     already re-planned and shown at its gate.

   Step 2's outcome selects the form at actuation, per feature; the user saw
   both at the gate — the precedent is `./insert.md` § *When step 1 leaves the
   feature `[ITERATED]`*.

   **Facts the document does not carry.** A change often states things no
   feature document holds — implementation notes such as which files to
   touch, a decision spanning two tasks. Step 2 does not write them, and
   reconciliation reads the document, not this conversation. So the gate lists
   them under step 3, form (b) forwards them verbatim as the reconciliation's
   free-form text — which in feature mode narrows or annotates the scope, and
   is no new input — and the step's `Step <i>/<k>` line names each one as an
   item to check at `/task-add`'s own gate, in the bodies it drafts or
   rewrites. Under form (a) they ride the per-task amends that need them.

   **What staling does.** A `[STALE]` task is not blocked:
   `../task-engine/references/stale.md`
   § *Implementing a stale task* — it is implementable on the user's explicit
   say-so; a single-task `/task-implement` run warns and asks, and the batch
   selectors skip it. Where the gate states step 2's staling, it says so in
   those terms and never implies a stale task cannot be implemented.
4. **Each runbook step** — through
   `../runbook-run/references/step-amend.md`,
   one step per runbook step: a dated `Context:` fact, or, for a wrong prompt,
   that file's strike and corrected insert.

**Why upstream first.** No downstream step is written against a state a
later step changes. A task amended before the feature document that governs
it would be amended against a promise about to move — and the task arm's own
second check would route the change to `/architect amend` anyway. A task that
step 2 stales is not amended task by task: the task arm never clears the tag,
so amending it would do reconciliation's work behind a second gate and still
leave it `[STALE]`. Step 3's form (b) runs reconciliation instead, which
rewrites the staled bodies, clears the tag and drafts tasks for the added
scope, in one owner step.

The `PLAN.md` lines the walk reaches are named in the proposal and written by
no step here. When the change moves a feature's `## Dependencies`, the report
names `/production-plan` as the follow-up.

## Tier

- **Editorial** — wording only; nothing downstream changes meaning. The
  sequence is the one step that writes the anchored artifact.
- **Local** — one artifact plus the entries that merely name it: the anchored
  artifact's step, plus one step for each entry that names it without
  depending on what changed — a runbook step's `Context:` fact, a task's
  `## Hints` citing a changed section. No status moves and no edge changes,
  so step 3, when present, is form (a).
- **Structural** — the scope changes, or a downstream entry's contract
  changes: what a task delivers, its `Files:`, an edge. The full sequence the
  walk reached, steps 1 to 4, with step 3 rendered in both forms wherever
  step 2 runs for the task's feature. A `Preconditions:` edge added or dropped
  is always structural.

The branch judges the tier for the proposal, and judges **editorial** only when
all three hold: the change is wording only; nothing downstream changes meaning
— no status moves, no edge, no `Files:`, no scope; and the sequence A leaves
equals the sequence B runs, the one step that writes the anchored artifact.
When any one fails it judges local or structural, as above. The tier decides how
long the sequence is. Whether the editorial question is asked is `./SKILL.md`
step 7's rule over these findings: a `Preconditions:` edge added or dropped, a
`Files:` change or a scope change classifies the amend not editorial, and all
three editorial conditions above classify it editorial — either way without
asking. Only a borderline wording-versus-meaning amend is asked, and then the
judged tier is the letter the gate marks: editorial marks A, local or
structural marks B. Editorial runs the editorial sequence; not editorial, the
judged tier's.

## Verification

When the amend added or dropped a `Preconditions:` edge, `./SKILL.md` step 9's
successor read applies: after actuation, read the bodies of the tasks on both
ends of each changed edge and confirm the sequence still reads as one. Any
other amend changes no precondition, and the scoped lint is the whole
bracket.

## Outcomes

No new status value. Under step 3's form (a), what an amend leaves is the
owners' existing writes — a rewritten section or body, a dated `Context:`
bullet, a struck step. Under form (b), `/architect amend` writes `[STALE]` on
the tasks it touched and `[ITERATED]` on the feature, and the reconciliation
step then returns the feature to `[PLANNED]` and each staled task to
`[MISSING]` — or `[SKIP]` with a replacement drafted — each `/task-add`'s own
write. When the sequence stops before that step, `[STALE]` and `[ITERATED]`
are what it leaves. Nothing else.

## Never

- Write anything itself, or replace a step's arm with a direct edit.
- Run the full `/architect` for a feature document.
- Run `/task-add` to change a single existing task. `/task-add
  feature=<slug>` reconciliation is allowed only as step 3's form (b), after
  step 2 staled a task or moved the feature to `[ITERATED]`.
- Amend, task by task, a task step 2 staled, or run a per-task amend after
  the reconciliation step of the same feature.
- Write a task's `Preconditions:` anywhere but on its own line, through step
  3's arm.
- Reorder the owner sequence, or run a downstream step before an upstream one.
- Read beyond `./SKILL.md`'s anchor scope.
