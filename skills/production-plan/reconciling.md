# Reconciling an existing plan

Read this when PHASE 0 finds that `.claude/PLAN.md` already exists. It
carries the full re-run protocol PHASE 1 step 5 summarizes.

## Why reconciliation exists

- `/architect` adds features and flips them to `[ITERATED]`;
  `/product-roadmap` adds, reorders and removes milestones. Neither writes
  `PLAN.md`, so the plan drifts, and a re-run is how it catches up.
- Start from the existing plan and propose a **diff**, never a blank page.
  Rebuilding from scratch would throw away the two things only the plan
  holds: the **ordering** inside each milestone, and the **confirmed edges**
  that the feature documents do not state.

## The five situations

Work through all five before presenting anything. They compose: one run
routinely hits several.

### 1. A feature in `FEATURES.md` that the plan does not have

**Propose it for placement.**

- Take its milestone from the `Source:` parenthetical if it has one;
  otherwise it goes to `Unscheduled` — exactly the inheritance rule a first
  run applies.
- Propose a position in the target milestone's `Features:` list consistent
  with its edges.
- Read its document's `## Dependencies` section to propose its edges too.
- Say how many such features there are: a slug in `FEATURES.md` and not in
  the plan is the plan's real staleness signal.

### 2. A slug in the plan that is gone from `FEATURES.md`

**Report it and drop it.**

- Remove it from its milestone's `Features:` list.
- Remove every `## Dependencies` line that names it — both the line it owns
  and its appearances in other features' lines.
- Name each dropped slug and each edge that went with it, so a deletion the
  user did not intend is visible rather than silent.

### 3. A feature whose `FEATURES.md` status is `[ITERATED]`

**Re-read its document's `## Dependencies` section and propose the edge
diff** — its design moved after tasks were planned from it.

- Propose only the delta: edges the prose now implies that the plan does
  not have, and edges the plan has that the prose no longer supports. Let
  the user confirm each direction.
- Do not silently replace the feature's edge set: a stored edge the
  documents never stated is legitimate, and wholesale replacement would
  delete it.
- Never write to the feature document, and never touch the feature's
  `Status:` — `[ITERATED]` is `/architect`'s field and `/task-add` is what
  clears it.

### 4. A milestone in the roadmap that the plan does not have

**Add it, in roadmap order** — at the position the roadmap gives it, not
appended at the end: a milestone the roadmap inserts between two others
belongs between them here too.

- It arrives `[PLANNED]`, with `Covers:` derived from the roadmap's own
  `Covers:` lines and `Features: none` until something is placed in it.
- A milestone with no features is not an error (usually `/architect` has
  not run on its slices yet). Report it as a warning and move on.

### 5. A milestone in the plan that is gone from the roadmap

**Report it, keep it, and flag it.**

- Do not delete it and do not move its features to `Unscheduled` — it may
  still be the one being built.
- Flag it plainly: name the milestone, say the roadmap no longer lists it,
  and say the remedy is either re-running `/product-roadmap` to restore it
  or moving its features elsewhere here.
- Keep it where it already sits in the plan, after the milestones the
  roadmap does order, and leave its `Covers:` line off — there is nothing
  left to derive it from.

## What reconciliation never does

- **It never writes anything but `.claude/PLAN.md`.** Not `FEATURES.md`, not
  `TASKS.md`, not a feature document, not the roadmap. Everything above is a
  proposal about the plan, however clearly some other document looks wrong.
- **It never re-derives an ordering the user set.** An existing `Features:`
  order is kept unless an edge makes it invalid or the user changes it.
- **It never resets a milestone's `Status:`.** A `[SHIPPED]` milestone stays
  shipped even if its features changed underneath it; an `[ACTIVE]` one stays
  active until the user says otherwise.
- **It never adds a second approval gate.** Everything found here is folded
  into PHASE 1's proposal and confirmed at PHASE 2's single gate, the same
  way `/task-add feature=<slug>` presents its reconciliation alongside its
  new drafts.

## After the diff

- Run PHASE 2's validation on the reconciled proposal exactly as on a first
  run: cycles and later-milestone dependencies refuse, whether the offending
  edge is new this run or has been in the plan since it was written — a
  plan valid yesterday can be invalid today because a milestone moved.
- Rewrite `Last reconciled:` to today's date whenever PHASE 3 writes. It is
  informational only — nothing reads it back, and no behaviour changes
  because of how old it is.
