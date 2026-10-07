# Branch: catch-up — the documentation follows code that has landed

Read this when `./SKILL.md` was invoked with `--catch-up`. Together with
`./SKILL.md` it is the whole branch: a consumer that has read both can run a
catch-up end to end. It writes nothing itself — every step below names, by
path or command, the arm or owner it delegates to — except the one deletion
`./SKILL.md`'s WRITE SET grants this branch: the spec file it was given.

The other four branches change planned work. This one changes no plan: the
code already does what the amended text will say, so the documentation is
brought up to date with it.

---

## Applies when

A change has already landed in the code — from a `/quick-implement` spec
(`.claude/specs/<YYYY-MM-DD>-<slug>.md`), or described free-form — and the
documents that describe its area still state the old behaviour, or leave open
what the change settled.

**Its items.** A catch-up's items are the points where a document lags the
landed change, not the user's change set:

- from a spec, every bullet of its `## Drift` section, plus each document the
  spec's `## Hints` and the landed diff touch that `## Drift` does not list;
- from a free-form description, the points the impact walk below finds.

Each point is one of two kinds, the design-change check's
(`../task-engine/references/design-change.md` § *Enumeration*):

- **settled** — the document left the matter open, or states it in words the
  code now carries out differently only in detail, and the code decided it.
  It is editorial: the amended text says what the code does.
- **a design break** — the document states a design the code does not follow
  on purpose, or a live task's contract (its summary block, `Files:` or what
  it delivers) depends on the passage. It is not editorial, and it is never
  amended without the user's answer.

A spec's `## Drift` bullet carries its kind already: a `settles` bullet is a
settled point; a `diverges` bullet is a design break when the code departs
from the document on purpose or a live task's contract depends on the
passage, and a settled point otherwise.

## Impact walk

Over `graph.md`'s edges, as `./amend.md` § *Impact walk* walks them, from each
point's document: a feature document's tasks (E3a), the runbook steps naming
its slug or task ids (E7), and, bottom-up from a design break, the feature
document a live task belongs to (E3b, then E2). Bodies are opened within
`./SKILL.md` step 4's scope, and, beyond it, the spec file and the landed
diff the spec names.

The walk also records which files the landed change touched, for the
context-layer step below.

## Owner sequence

Upstream first, as `./amend.md` § *Owner sequence* orders it:

1. **A design decision** — `/product-design amend`, from its arm by path.
2. **Each feature document** — `/architect amend feature=<slug> "<change>"`,
   executed from `../architect/amend.md` by path, with the classification
   **editorial** carried in for every settled point
   (`../architect/amend.md` § *A classification carried from
   `/pipeline-revise`*). No task is marked stale for a point the code
   settled. Should the arm's own findings classify it not editorial, its
   stricter-applies rule stands, and the point is a design break after all —
   named in the report.
3. **The tasks** — only a task whose `## Hints` cite a passage the amend
   rewrote, through `../task-engine/references/amend.md`; never
   reconciliation for a settled point.
4. **Each runbook step** — a dated `Context:` fact through
   `../runbook-run/references/step-amend.md`, where an open step names what
   the change settled.
5. **The context layer** — when `.claude/context/` exists and the landed
   change touched files a context file describes: `/context-update
   --no-commit`, always the plan's last step. Skipped when no context layer
   exists or none of its files describes a touched file. Whether
   `context-update` is installed is asked by name, not read off the probe;
   when it is not, the step becomes a report follow-up instead.

A lagging point in `CLAUDE.md` or `README.md` has no owner step here: it is
named in the report as a follow-up, with the passage.

**A design break is a question at the gate**, one per break, in plain words:
what the design says, what the code does instead, and the two answers:

- **a. Accept the code** — amend the design to say what the code does. The
  point takes `./amend.md`'s ordinary path at the tier that branch judges,
  `/architect amend` running with no carried classification, so its own
  rule decides what it stales.
- **b. Keep the design** — insert a task that brings the code back. The point
  takes `./insert.md`'s ordinary path, with the break as the new task's
  goal.

The answer's steps join the plan in their place in the order above; until
then they are conditional on it.

## Tier

Editorial for every settled point — the sequence is the steps that write the
lagging documents, and nothing downstream changes meaning. A design break's
answer takes the tier its branch judges.

## Verification

`./SKILL.md` step 9's scoped lint is the bracket. When a design break's answer
inserted a task, `./insert.md` § *Verification* applies to it.

## Outcomes

The owners' existing writes — rewritten sections, dated `Context:` bullets,
refreshed context files — and the spec file deleted. A design break answered
**b** adds what `./insert.md` adds. No new status value, and no `[STALE]` for
a settled point.

**The spec.** The run's one commit (`./SKILL.md` COMMITTING) deletes the spec
it was given: `git rm` on that path, staged with the owners' writes. A
sequence that stops part-way, a `stop`, or `--no-commit` leaves the spec where
it is — its presence is what says the catch-up has not landed. A free-form
catch-up has no spec to delete.

## Never

- Mark a task stale, or run reconciliation, for a point the code settled.
- Amend a design break without the user's answer, or pick its answer.
- Delete a spec other than the one the run was given, or delete it outside
  the run's commit.
- Edit code: the code is the fixed side of a catch-up.
