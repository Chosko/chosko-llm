# `[STALE]`

Authority for: what `[STALE]` means, who sets it and who clears it, how the
originating feature is found, and how each `task-*` feature treats a stale
task.

Extracted verbatim from `/task-implement`'s `STALE TASKS`, `/task-add`'s
`[STALE]` status bullet and its `RECONCILIATION` table, `/task-clean`'s
`[STALE]` warning, and `/task-list`'s `[STALE]` gloss.

---

## What it means

`[STALE]` means the feature document this task was generated from has since
been re-architected: the task is live work, but its spec may no longer match
the design. `/architect` sets it; `/task-add feature=<slug>` reconciliation
clears it.

It is **not terminal**. A stale task is live work awaiting reconciliation,
not abandoned work.

## Detecting it and finding the feature

The task's own `Status:` line in `.claude/TASKS.md` carries the tag. The
feature it came from is the slug on the task's `Feature:` line in the same
summary block; if there is no such line, the originating feature is
unrecorded.

`.claude/FEATURES.md` is the index that resolves that slug: its entry for
the feature carries the `Status:`, the `Tasks:` line listing the IDs the
feature generated, and the `Doc:` line naming the feature document —
conventionally `.claude/domain/features/<slug>.md`. `/architect` writes
`[STALE]` onto exactly those `Tasks:` IDs when it re-architects the feature,
which is why the tag and the index agree.

## Implementing a stale task

A stale task is implementable, but only on the user's explicit say-so.
Before doing anything else on such a task, warn:

> Task <N> is `[STALE]`. Feature `<slug>` was re-architected after this task
> was written, so its spec may no longer match the current design — see
> `.claude/domain/features/<slug>.md`. Options:
>
> A. **Implement anyway** — the task still looks right to you.
> B. **Stop** — reconcile the backlog first with
>    `/task-add feature=<slug>`, then re-run.
>
> Which?

Take the feature slug from the task's `Feature:` line in its TASKS.md
summary block; if there is no such line, say the originating feature is
unrecorded and offer the same choice. Wait for an explicit answer —
silence is not approval. On A, proceed through the normal per-task
workflow unchanged. On B, stop the run without flipping any `Status:`; if
other tasks were queued behind this one, say which were not started.

The choice is always the user's: a human can judge whether a superseded
design still applies, and nothing here decides that for them.

A batch selector (`all` / `next`) skips stale tasks rather than asking,
because each one needs a per-task judgment call and a batch run should not
stop to ask — see
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`.

## Clearing it

Reconciliation classifies EVERY existing task the feature generated:

| Situation | Action |
| --- | --- |
| Still valid under the new design | Left untouched. No edit at all. |
| Needs minor change, and is `[STALE]` or `[MISSING]` | Body updated in place. A `[STALE]` task flips back to `[MISSING]`. |
| Substantially invalidated | Marked `[SKIP]` with a reason, and a replacement task drafted. |
| `[DONE]` | Never modified, skipped, or reopened. |

**Prefer update-in-place.** Whenever the task's goal survives the design
change, rewriting the body is cheaper than skip-and-replace: nothing has
been implemented yet, and the backlog stays free of dead `[SKIP]` entries
that future readers have to interpret. Reserve skip-and-replace for tasks
whose goal no longer survives at all.

Which of the two applies is a judgment call about how much of the task
remains — the criteria above are the criteria; there is no mechanical rule
and no line count. State the reason for each call so the user can overrule
it in the same approval.

**`[DONE]` is untouchable.** Completed work stands regardless of what the
design did afterwards. If the new design needs more from an area a `[DONE]`
task covered, that is a NEW task, not a reopened one. Never flip a `[DONE]`
task to `[SKIP]`, `[STALE]`, `[MISSING]`, or anything else.

## Never pruned by default

The normal resolution is `/task-add feature=<slug>`, which updates or
replaces the task. Never prune it by default. If the user names `[STALE]`
explicitly, say all of that in the plan and confirm before applying. Never
add `[STALE]` to a default prune set, or treat it as terminal anywhere.

---

## Per-consumer notes

- **`/task-list`** — reads it only. `[STALE]` "is filterable like any other
  status", and a stale task carries a trailing `⚠ stale` marker: "The
  status column already shows `[STALE]`, but the marker keeps it visible in
  the same scan as the human-in-the-loop `⚠` — a stale task is the one
  status that needs the user to act (reconcile it, or decide it still
  applies)." It never comments on staleness beyond that marker.
- **`/task-clean`** — never prunes it by default and warns as above when it
  is named explicitly.
- **`/task-add`** — the clearer. Reconciliation runs only on a
  `feature=<slug>` run whose feature has a non-`none` `Tasks:` line, and it
  never sets `[STALE]` when creating a task.
- **`/task-implement`** — the protocol above is its own, and it is
  deliberate that the choice is put to a human: a stale task is never
  delegated to a subagent (see `targets.md`), and it is never started
  without the user explicitly choosing to implement it anyway.
- **`/architect`** — the only writer of `[STALE]`. It is not a `task-*`
  feature and does not read this engine; it is named here because the tag
  is meaningless without it.
