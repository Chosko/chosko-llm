# Reconciling an existing plan

Read this when PHASE 0 finds that `.claude/PLAN.md` already exists. It
carries the full re-run protocol PHASE 1 step 5 summarizes.

## Why reconciliation exists

The plan is a projection of two documents that keep moving underneath it.
`/architect` adds features and flips them to `[ITERATED]`; `/product-roadmap`
adds, reorders and removes milestones. Neither writes `PLAN.md`, and neither
should: one writer per artifact is what keeps the pipeline's documents from
contending for the same lines.

So the plan drifts, and a re-run is how it catches up. The alternative —
rebuilding it from scratch every run — would throw away the two things the
plan holds that nothing else does: the **ordering** inside each milestone,
and the **confirmed edges** that the feature documents do not state.

Reconciliation therefore starts from the existing plan and proposes a
**diff**, never a blank page.

## The five situations

Work through all five before presenting anything. They compose: one run
routinely hits several.

### 1. A feature in `FEATURES.md` that the plan does not have

**Propose it for placement.** Its milestone comes from the `Source:`
parenthetical if it has one, and is `Unscheduled` if it does not — exactly
the inheritance rule a first run applies. Propose a position in the target
milestone's `Features:` list consistent with its edges, and read its
document's `## Dependencies` section to propose its edges too.

This is the ordinary case: it is what happens every time `/architect` runs.
It is also the plan's real staleness signal — a slug in `FEATURES.md` and not
in the plan means the plan has not caught up. Say how many there are.

### 2. A slug in the plan that is gone from `FEATURES.md`

**Report it and drop it.** Remove it from its milestone's `Features:` list,
and remove every `## Dependencies` line that names it — both the line it owns
and its appearances in other features' lines.

A hand-deleted feature must not break the run, and must not leave an edge
pointing at nothing. Name each dropped slug and each edge that went with it,
so a deletion the user did not intend is visible rather than silent.

### 3. A feature whose `FEATURES.md` status is `[ITERATED]`

**Re-read its document's `## Dependencies` section and propose the edge
diff.** `[ITERATED]` means the design moved after tasks were planned from it,
so its dependencies are the ones most likely to have changed.

Propose only the delta — edges the prose now implies that the plan does not
have, and edges the plan has that the prose no longer supports — and let the
user confirm each direction. Do not silently replace the feature's edge set:
a stored edge the documents never stated is legitimate (that is the whole
reason edges are confirmed and stored), and wholesale replacement would
delete it.

Never write to the feature document, and never touch the feature's
`Status:` — `[ITERATED]` is `/architect`'s field and `/task-add` is what
clears it.

### 4. A milestone in the roadmap that the plan does not have

**Add it, in roadmap order** — at the position the roadmap gives it, not
appended at the end, since order is list position and a milestone inserted
between two others belongs between them here too.

It arrives `[PLANNED]`, with `Covers:` derived from the roadmap's own
`Covers:` lines and `Features: none` until something is placed in it. A
milestone with no features is not an error: it usually means `/architect` has
not run on its slices yet. Report it as a warning and move on.

### 5. A milestone in the plan that is gone from the roadmap

**Report it, keep it, and flag it.** Do not delete it and do not move its
features to `Unscheduled`.

Hand edits are tolerated, not silently reverted, and a milestone the roadmap
dropped may still be the one being built. Flag it plainly — name the
milestone, say the roadmap no longer lists it, and say the remedy is either
re-running `/product-roadmap` to restore it or moving its features
elsewhere here. Because it has no roadmap position, keep it where it already
sits in the plan, after the milestones the roadmap does order, and leave its
`Covers:` line off — there is nothing left to derive it from.

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

PHASE 2's validation runs on the reconciled proposal exactly as it does on a
first run — cycles and later-milestone dependencies refuse, whether the
offending edge is new this run or has been in the plan since it was written.
A plan that was valid yesterday can be invalid today because a milestone
moved; catching that is the point.

`Last reconciled:` is rewritten to today's date whenever PHASE 3 writes. It
is informational only — nothing reads it back, and no behaviour changes
because of how old it is.
