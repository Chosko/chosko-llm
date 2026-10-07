# Branch: amend — something that exists changes

Read this when `./SKILL.md`'s CLASSIFY chose amend. With `./SKILL.md` it is
the whole branch: a consumer that has read both can execute an amend end to
end.

- Add no read beyond the anchor scope `./SKILL.md` step 4 fixes.
- Write nothing yourself — every step below names, by path, the arm it
  delegates to.

---

## Applies when

Something that already exists changes, and nothing is added, removed or
moved:

- a design decision in `product-design.md`;
- a milestone's lines in `product-roadmap.md`;
- a section of a feature document;
- a task's body or summary fields;
- a `Preconditions:` edge added to or dropped from a task that stays where
  it is;
- a fact about a pending runbook step, or a step's prompt — which
  `step-amend.md` turns into a strike and a corrected insert itself, and
  which is still one amend here.

A change that moves an entry is `./reorder.md`'s; one that makes a new
entry is `./insert.md`'s; one that ends an entry is `./delete.md`'s.

## Impact walk

Walk over `graph.md`'s edges, named by id.

**Top-down** — from a milestone, a design section or a feature document:

- a milestone → the design sections its `Covers:` slices name, and from each
  as below. A change to a `Goal:`, `Exit criteria:` or `Rationale:` line
  alone reaches nothing downstream and is the roadmap step by itself;
- a design section → every feature whose `Source:` names it (E1), and each
  one's document (E2);
- a feature document → the tasks carrying that `Feature:` — the live ids on
  its `Tasks:` line (E3a); the `PLAN.md` edges naming the slug (E5); and the
  runbook steps naming the slug or one of its task ids — every open runbook
  is a candidate (E7), confirmed within `./SKILL.md`'s body scope.

**Bottom-up** — from a task:

- Up to the feature document that promised it, when its `Feature:` slug
  resolves in `.claude/FEATURES.md` (E3b, then E2).
  - **A `Feature:` slug that resolves to nothing, or no `Feature:` line at
    all, stops the upward walk**: treat the task as free-form and amend it
    on its own; that is not an error.
  - An unresolved slug still surfaces — as the lint bracket's finding, not
    as a walk failure.
- Forward to the tasks whose `Preconditions:` name it (E4), when the change
  alters what the task delivers — they build on it.
  - **From each such task, continue exactly as from the anchor**: up to that
    task's own feature document when its `Feature:` slug resolves in
    `.claude/FEATURES.md` (E3b, then E2) — a missing or unresolved slug stops
    it there, as for the anchor and for the same reason — then forward again
    from it (E4).
  - Do not walk from a successor whose basis does not change: this
    bullet's condition applies at every hop, not just the first.

**From a runbook step**: read the step's prompt in the body the anchor
already opened, go up to the tasks and features it names, and continue from
each as above.

Visit every node once. Do not walk a second time from a task or feature
document already reached — this terminates the walk on a backlog whose
edges rejoin.

**A feature document reached this way is named, not opened.**

- It comes from the index lines the walk has already read — the task's
  `Feature:` and that entry's `Doc:` — and enters the proposal as a step 2
  entry of the owner sequence below, like the anchor's own document.
- Whether it really needs a change is `/architect amend`'s to judge when its
  arm opens it, and that arm may answer **Stop**; a step that turns out to
  change nothing is the accepted cost of catching one that does.
- `./SKILL.md` step 4's body scope is unchanged by this — it lists the
  bodies this branch may open, and a reached document is not one of them.

## Owner sequence

Fixed, and upstream first, so no downstream step is written against a state
a later step changes. A step is in the sequence when the walk reached its
artifact and the tier keeps it; the order never changes.

1. **A design decision** — `/product-design amend "<change>"`, executed
   from its arm, `../product-design/amend.md`, by path. On a design process
   that is not complete the arm refuses — an owner refusing, under
   `./SKILL.md`'s failure contract. **A milestone's lines** —
   `/product-roadmap amend "<change>"`, executed from its arm,
   `../product-roadmap/amend.md`, by path — take the same position, after
   the design decision and before every feature document.
2. **Each feature document** — `/architect amend feature=<slug> "<change>"`,
   executed from its arm, `../architect/amend.md`, by path. One step per
   feature, in `.claude/FEATURES.md` order. Never the full `/architect`:
   the arm's precision guard stales only the tasks the change touches,
   where the blanket guard would stale every one.
3. **The tasks** — one of two forms per feature, selected at plan time from
   the classification step 2 carries (`./SKILL.md` step 6) and rendered as
   one step. A step 2 that turns out to stale differently from its carried
   classification makes the rendered form moot, and `./SKILL.md` step 8
   drops it with one line.
   - **(a) Per-task amends** — each task's body and summary fields through
     `../task-engine/references/amend.md`, one step per task, in
     `.claude/TASKS.md` appearance order. Add or drop a `Preconditions:`
     edge here, on the dependent's own line, the drop narrated in its
     `## Decisions` — that arm's rule. Use this form when step 2 stales
     nothing and leaves the feature's `Status:` unchanged, and always for a
     task with no feature step 2 ran.
   - **(b) Reconciliation** — one owner step,
     `/task-add feature=<slug> "<annotation>"`, the reconciliation run. Use
     this form when step 2 stales any task, or moves the feature to
     `[ITERATED]` for scope no existing task covers.
     - Reconciliation is the one clearer of `[STALE]` —
       `task-engine/references/stale.md` § *Clearing it*: it rewrites each
       stale body in place, skips-and-replaces one whose goal no longer
       survives, drafts tasks for the added scope and returns the feature to
       `[PLANNED]`. So under (b) **no per-task amend runs for a task step 2
       staled**: its new body is reconciliation's to write.
     - A task step 2 did **not** stale whose own summary fields or body must
       still change — a `Preconditions:` edge on its own line, say — keeps
       its per-task amend, and that amend runs **before** the reconciliation
       step: reconciliation classifies every task the feature generated as
       its summary block and body stand when it reads them, and drafts new
       tasks against the edges it finds.

   The same selection rule is `./insert.md` § *When step 1 leaves the
   feature `[ITERATED]`*'s.

   **Facts the document does not carry.** A change often states things no
   feature document holds — implementation notes such as which files to
   touch, a decision spanning two tasks. Step 2 does not write them, and
   reconciliation reads the document, not this conversation. So:
   - the gate lists them under step 3;
   - form (b) forwards them verbatim as the reconciliation's free-form text
     — which in feature mode narrows or annotates the scope, and is no new
     input — and the step's `Step <i>/<k>` line names each one as an item to
     check at `/task-add`'s own gate, in the bodies it drafts or rewrites;
   - under form (a) they ride the per-task amends that need them.

   **What staling does.** A `[STALE]` task is not blocked:
   `../task-engine/references/stale.md` § *Implementing a stale task* — it
   is implementable on the user's explicit say-so; a single-task
   `/task-implement` run warns and asks, and the batch selectors skip it.
   Where the gate states step 2's staling, say so in those terms; never
   imply a stale task cannot be implemented.
4. **Each runbook step** — through
   `../runbook-run/references/step-amend.md`, one step per runbook step: a
   dated `Context:` fact, or, for a wrong prompt, that file's strike and
   corrected insert.

The `PLAN.md` lines the walk reaches are named in the proposal and written
by no step here. When the change moves a feature's `## Dependencies`, the
report names `/production-plan amend "<the edge that moved>"` as the
follow-up.

## Tier

- **Editorial** — all three hold: the change is wording only; nothing
  downstream changes meaning — no status moves, no edge, no `Files:`, no
  scope; and the sequence is the one step that writes the anchored
  artifact.
- **Local** — one artifact plus the entries that merely name it: the
  anchored artifact's step, plus one step for each entry that names it
  without depending on what changed — a runbook step's `Context:` fact, a
  task's `## Hints` citing a changed section. No status moves and no edge
  changes, so step 3, when present, is form (a).
- **Structural** — the scope changes, or a downstream entry's contract
  changes: what a task delivers, its `Files:`, an edge. The full sequence
  the walk reached, steps 1 to 4, step 3 in the form step 2's carried
  classification selects. A `Preconditions:` edge added or dropped is
  always structural.

Judge the tier for the proposal — editorial only when all three hold,
otherwise local or structural. The tier decides how long the sequence is.

Whether a feature's editorial classification is decided at plan time or
asked at the gate is `./SKILL.md` step 6's rule, applying
`../architect/amend.md` § 4 over the touched set and the scope call:

- a `Preconditions:` edge added or dropped, a `Files:` change or a scope
  change classifies the amend not editorial, and all three editorial
  conditions above classify it editorial — either way without asking;
- only a borderline wording-versus-meaning amend is asked, in that arm's own
  form, and the answer is carried into the step;
- editorial runs the editorial sequence; not editorial, the judged tier's.

## Verification

- When the amend added or dropped a `Preconditions:` edge, `./SKILL.md`
  step 9's successor read applies: after actuation, read the bodies of the
  tasks on both ends of each changed edge and confirm the sequence still
  reads as one.
- Any other amend changes no precondition; the scoped lint is the whole
  bracket.

## Outcomes

No new status value.

- Under step 3's form (a): the owners' existing writes — a rewritten
  section or body, a dated `Context:` bullet, a struck step.
- Under form (b): `/architect amend` writes `[STALE]` on the tasks it
  touched and `[ITERATED]` on the feature; the reconciliation step then
  returns the feature to `[PLANNED]` and each staled task to `[MISSING]` —
  or `[SKIP]` with a replacement drafted — each `/task-add`'s own write.
  When the sequence stops before that step, `[STALE]` and `[ITERATED]` are
  what it leaves.
- Nothing else.

## Never

- Write anything itself, or replace a step's arm with a direct edit.
- Run `/task-add` to change a single existing task. `/task-add
  feature=<slug>` reconciliation is allowed only as step 3's form (b), after
  step 2 staled a task or moved the feature to `[ITERATED]`.
- Write a task's `Preconditions:` anywhere but on its own line, through step
  3's arm.
