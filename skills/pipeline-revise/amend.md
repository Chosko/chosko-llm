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
  change alters what the task delivers — they build on it.

From a runbook step, the walk reads the step's prompt in the body the anchor
already opened, goes up to the tasks and features it names, and continues
from each as above.

## Owner sequence

Fixed, and upstream first. A step is in the sequence when the walk reached
its artifact and the tier keeps it; the order never changes.

1. **A design decision** — `/product-design`'s amend arm,
   `${CLAUDE_HOME:-$HOME/.claude}/skills/product-design/resuming.md` § 6,
   reached by re-running `/product-design` on a completed design process and
   choosing its amend arm. On a process that is not complete the arm is not
   offered — an owner refusing, under `./SKILL.md`'s failure contract.
2. **Each feature document** — `/architect amend feature=<slug> "<change>"`,
   executed from its arm,
   `${CLAUDE_HOME:-$HOME/.claude}/skills/architect/amend.md`, by path. One
   step per feature, in `.claude/FEATURES.md` order. Never the full
   `/architect`: the arm's precision guard stales only the tasks the change
   touches, where the blanket guard would stale every one.
3. **Each task** — its body and summary fields through
   `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/amend.md`,
   one step per task, in `.claude/TASKS.md` appearance order. A
   `Preconditions:` edge is added or dropped here, on the dependent's own
   line, the drop narrated in its `## Decisions` — that arm's rule.
4. **Each runbook step** — through
   `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/step-amend.md`,
   one step per runbook step: a dated `Context:` fact, or, for a wrong prompt,
   that file's strike and corrected insert.

**Why upstream first.** No downstream step is written against a state a
later step changes. A task amended before the feature document that governs
it would be amended against a promise about to move — and the task arm's own
second check would route the change to `/architect amend` anyway. A task that
step 2 stales is still amended in step 3 when its body must say something
new; the task arm never clears the tag, so it stays `[STALE]`, and the report
names `/task-add feature=<slug>` as what clears it.

The `PLAN.md` lines the walk reaches are named in the proposal and written by
no step here. When the change moves a feature's `## Dependencies`, the report
names `/production-plan` as the follow-up.

## Tier

- **Editorial** — wording only; nothing downstream changes meaning. The
  sequence is the one step that writes the anchored artifact.
- **Local** — one artifact plus the entries that merely name it: the anchored
  artifact's step, plus one step for each entry that names it without
  depending on what changed — a runbook step's `Context:` fact, a task's
  `## Hints` citing a changed section. No status moves and no edge changes.
- **Structural** — the scope changes, or a downstream entry's contract
  changes: what a task delivers, its `Files:`, an edge. The full sequence the
  walk reached, steps 1 to 4. A `Preconditions:` edge added or dropped is
  always structural.

The branch judges local or structural for the proposal. The tier decides how
long the sequence is; it never decides whether the gate is asked. Under the
gate's A the sequence is the editorial one; under B, the judged tier's.

## Verification

When the amend added or dropped a `Preconditions:` edge, `./SKILL.md` step 9's
successor read applies: after actuation, read the bodies of the tasks on both
ends of each changed edge and confirm the sequence still reads as one. Any
other amend changes no precondition, and the scoped lint is the whole
bracket.

## Outcomes

No new status value. What an amend leaves is `[STALE]` on the tasks
`/architect amend` touched, `[ITERATED]` on a feature it moved, and the
owners' existing writes — a rewritten section or body, a dated `Context:`
bullet, a struck step. Nothing else.

## Never

- Write anything itself, or replace a step's arm with a direct edit.
- Run the full `/architect` for a feature document, or a `/task-add` run to
  change an existing task.
- Write a task's `Preconditions:` anywhere but on its own line, through step
  3's arm.
- Reorder the owner sequence, or run a downstream step before an upstream one.
- Read beyond `./SKILL.md`'s anchor scope.
