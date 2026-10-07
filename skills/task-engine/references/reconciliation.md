# Reconciliation

Authority for: how a re-planning run applies reconciliation to the tasks a
feature already generated — classify every one, present each call with a
reason, and apply the approved plan and nothing beyond it.

Extracted verbatim from `/task-add`'s `RECONCILIATION` section and its
PHASE 4 feature-case step 3. The four-way classification itself, the
standing preference for update-in-place over skip-and-replace, and the rule
that `[DONE]` is untouchable are `./stale.md` § *Clearing it*, cited here and
not copied.

---

## Why it runs

A re-planning run must not append blindly — that reliably produces
overlapping work.

## Classifying

Classify EVERY existing task the feature generated — not a sample, not the
`[STALE]` ones only — per `./stale.md` § *Clearing it*, and present the
classification at the run's gate with a one-line reason each, so the user can
overrule any call inside the same approval.

Render it like this:

```
RECONCILIATION — feature <slug> has 5 existing tasks

  12. [DONE]     <title>
      → untouched. Completed work; the new design doesn't change it.
  13. [MISSING]  <title>
      → untouched. Still valid — the interface it builds is unchanged.
  14. [STALE]    <title>
      → body updated in place, back to [MISSING]. The goal survives; the
        component it targets was renamed and its contract narrowed.
  15. [MISSING]  <title>
      → [SKIP] ("superseded: the design no longer has a separate cache
        layer"), replaced by new task <N+2> below.
  16. [PARKED]   <title>
      → [SKIP] ("superseded: the endpoint it was parked on no longer
        exists; branch park/task-16 deleted"), replaced by new task <N+3>
        below. Its parked question is moot under the new design.
```

## Applying the approved plan

Apply the approved reconciliation, and nothing beyond it:

- Rewrite the body of each task classified "update in place", and flip a
  `[STALE]` one back to `[MISSING]` in TASKS.md. A `[PARKED]` one is
  rewritten above its `## Parking handoff` and stays `[PARKED]`.
- Set each "substantially invalidated" task's `Status:` to `[SKIP]`, and
  record the one-line reason from the plan in its body so a later reader
  knows why. The replacement task is written as a new task. A `[PARKED]`
  one's `park/task-<N>` branch is deleted, local and remote, as `./stale.md`
  § *Clearing it* says.
- Touch nothing on a task classified "untouched", and nothing at all on a
  `[DONE]` task.

---

## Per-consumer notes

- **`/task-add`** — the only feature that applies it. The tasks it
  classifies are those PHASE 1b read; the classification is rendered in
  PHASE 3, before the new drafts; PHASE 4 feature-case step 3 applies it, and
  the parked branch delete is the one git command that phase runs before
  PHASE 5.
