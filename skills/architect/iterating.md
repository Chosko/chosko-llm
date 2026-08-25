# The iterate guard

Read this when PHASE 0 finds that a target feature already has a
`FEATURES.md` entry. It carries the full protocol PHASE 0b summarizes.

## Why the guard exists

Re-architecting a feature changes the spec that tasks were generated from.
Those tasks are already in the backlog, possibly already being implemented.
Without a guard, `/architect` would silently leave behind work that looks
valid and is not — which is worse than either refusing or asking, because
nothing surfaces it.

The guard has exactly one hard refusal and one negotiable case, and the line
between them is whether an implementation is currently in flight.

## Protocol

Run this per target feature that already has an entry.

### 1. Collect the tasks

Read the entry's `Tasks:` line. It is a comma-separated list of task IDs, or
`none`. Look each ID up in `.claude/TASKS.md` and note its `Status:` and
title.

**IDs that resolve to no task are ignored, not an error.** `/task-clean`
normally prunes them from the `Tasks:` line, but a hand-edited backlog must
not break the run. Mention them in passing if it's tidy to do so; do not
stop.

**When nothing resolves** — `Tasks: none`, or every listed ID resolving to no
task, which are the same case and neither of them an error — there is no task
half of the guard to run. Skip steps 2, 3 and 4.1 for this feature: nothing
to list, nothing to refuse on, nothing to ask about, and no write to
`.claude/TASKS.md`. The status half still applies, and it is decided by the
entry's own `Status:`, never by the `Tasks:` line:

| Entry `Status:` | Result |
| --- | --- |
| `[NEW]` | stays `[NEW]` — no tasks ever existed |
| `[ITERATED]` | stays `[ITERATED]` — already iterated, no-op |
| `[PLANNED]` | → `[ITERATED]` |
| `[DONE]` | → `[ITERATED]` |

`Tasks:` cannot be the discriminator here, because `/task-clean` prunes
`[DONE]` and `[SKIP]` IDs out of that line and deliberately leaves `Status:`
alone. A cleaned `[PLANNED]` or `[DONE]` feature therefore looks exactly like
a never-planned `[NEW]` one, and reading `Tasks: none` as "never planned"
would leave it `[DONE]` where the state machine documents `[DONE]` →
`[ITERATED]`. That also strands it: `/task-add feature=<slug>` never targets
a `[DONE]` feature, so the re-architected design would have no route back
into the backlog.

A flip made on this path takes no ask — the guard's ask exists to warn about
tasks that are about to be marked `[STALE]`, and there are none. Write it as
step 4.2 does, name it in PHASE 3's closing report like any other transition,
then continue to PHASE 1.

### 2. Refuse on `[IN PROGRESS]`

If ANY resolved task is `[IN PROGRESS]`, stop the entire run:

> Can't re-architect `<slug>`: task <N> — "<title>" is `[IN PROGRESS]`.
> An implementation is underway against the current design, and changing it
> now would corrupt both the task and the feature. Finish that task, or
> reset its status, then re-run `/architect`.

This refusal has **no override**. Not on the user's insistence, not with a
flag, not "just document it and I'll deal with the task". If the user pushes
back, restate the reason once and hold — the same as any other invariant.
Report it and stop; do not continue to other target features, and do not
write anything.

### 3. Ask on any other non-`[DONE]` task

If there are non-`[DONE]` tasks and none is `[IN PROGRESS]`, present them and
ask:

> Feature `<slug>` already has tasks in the backlog:
>
>   12. [MISSING]  <title>
>   14. [PARTIAL]  <title>
>   15. [STALE]    <title>
>
> Re-architecting may invalidate them — the spec they were written from is
> about to change. If we proceed, I'll mark every one of these `[STALE]`,
> which means "the design moved, this task needs reconciling". They stay in
> the backlog and nothing is deleted; `/task-add feature=<slug>` reconciles
> them afterwards, updating the ones that survive and replacing the ones
> that don't.
>
> A. **Proceed** — re-architect and mark these `[STALE]`.
> B. **Stop** — leave the design and the backlog as they are.

Wait for an explicit answer; silence is not approval. On B, stop the run
without writing anything.

Tasks already `[STALE]` are listed too — they stay `[STALE]`, which is a
no-op flip, and their presence is worth showing because it means a previous
iteration was never reconciled.

### 4. On proceed

Two writes, both narrow:

**4.1 — In `.claude/TASKS.md`**, flip every non-`[DONE]` task in the list to
`[STALE]`. Edit only `Status:` lines. Never create, delete, reorder, or
otherwise edit task entries, and never touch a task's body file.

**4.2 — In `.claude/FEATURES.md`**, set the feature's `Status:` to
`[ITERATED]` if it is currently `[PLANNED]` or `[DONE]`. A feature already
`[ITERATED]` stays `[ITERATED]`, and a `[NEW]` one stays `[NEW]`. This is the
same status rule step 1 applies when nothing resolves — the two paths differ
only in whether 4.1 ran. Re-architecting a `[DONE]` feature is not a special
case: it reaches this guard with its tasks already `[DONE]` or `[SKIP]` — or,
once `/task-clean` has pruned those, with no tasks at all, which is the
common shape and the one step 1 handles — so step 3 above only ever has
`[SKIP]` tasks to list, if any.

`[DONE]` tasks are never touched. Completed work stands regardless of what
the design does afterwards; follow-up work is a new task, not a reopened
one.

Add `.claude/TASKS.md` to `WRITTEN` — under `--commit` it belongs in the same
commit as the architecture, because the two changes only make sense
together.

### 5. Carry it into the report

PHASE 3's closing report must name every task flipped to `[STALE]`, with its
ID and title, and give the reconciliation command:

> Marked stale: 12, 14, 15. Reconcile with `/task-add feature=<slug>`.

A stale task the user does not know about is the exact failure this guard
exists to prevent.

The status transition is reported too, on both paths — including the
no-resolvable-tasks one, where it is the guard's only visible effect
(`[DONE] → [ITERATED]`, with no stale list beneath it and nothing to
reconcile yet).

## What `[STALE]` means downstream

Worth knowing while explaining the flip to the user:

- **Not terminal.** `/task-clean` never prunes `[STALE]` — it is live work
  awaiting reconciliation, not abandoned work.
- **Never picked up silently.** `/task-implement` warns, names the feature, and
  lets the user implement anyway or stop. `all` and `next` skip stale tasks
  rather than deciding for the user.
- **Cleared by reconciliation.** `/task-add feature=<slug>` updates the body
  in place — flipping the task back to `[MISSING]` — when the goal survives
  the design change, or marks it `[SKIP]` with a reason and drafts a
  replacement when it doesn't.

## Re-architecting the document itself

Beyond the guard: on an iterated feature, PHASE 3 **updates the existing
document in place**, keeping its slug and path. Rewrite the sections whose
design changed; leave the rest. Do not create a `<slug>-v2.md`, do not append
a changelog section — the document states the current design, and the history
is in VCS.
