# The status vocabulary

Authority for: the eight status tags and what each means, which are
terminal, which are implementable, how a status argument is accepted, and
the legal transitions.

Extracted verbatim from `/task-add`'s `STATUS TAGS (the only allowed
values, recorded in TASKS.md)`, `/task-list`'s `STATUS TAGS (the only
allowed values)`, `/task-clean`'s `WHICH STATUSES COUNT AS "TERMINAL"`, and
`/task-implement`'s implementable-status list.

---

## The tags

`[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]`, `[IN PROGRESS]`,
`[DONE]`, `[SKIP]`, `[STALE]`. These are the only allowed values.

- `[MISSING]` — behavior not implemented at all. **Default for new tasks.**
- `[STUBBED]` — placeholder/TODO exists but no real implementation.
- `[INCORRECT]` — implemented but diverges from the spec.
- `[PARTIAL]` — implemented in part; some sub-requirements still missing.
- `[IN PROGRESS]` — agent is currently working on it. (Not set by
  `/task-add`.)
- `[DONE]` — implementation has landed. (Not set by `/task-add`.)
- `[SKIP]` — explicitly deferred or abandoned.
- `[STALE]` — the feature document this task was generated from has since
  been re-architected, so the task may no longer match the design. Set by
  `/architect` when it re-architects the originating feature; resolved by
  `/task-add feature=<slug>` reconciliation, which either updates the body
  in place (flipping the task back to `[MISSING]`) or marks it `[SKIP]` and
  drafts a replacement. **Never set by `/task-add` when creating a task.**
  Not terminal — a stale task is live work awaiting reconciliation.

A new task is `[MISSING]` unless the user's description clearly indicates
a different pre-implementation state.

## Terminal

Terminal is `[DONE]` and `[SKIP]`, and only those two. These are the two
statuses that indicate the task no longer needs work. That set is
exhaustive — no other status is terminal, and in particular `[STALE]` is
NOT. Do not add to it.

The non-terminal statuses, and why pruning one is unusual:

- `[IN PROGRESS]` — currently being worked on. Pruning is almost
  certainly a mistake. Confirm twice, the second time with the specific
  tasks listed.
- `[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]` — these mean work
  still remains. Pruning them throws away the spec. If the user really
  wants to discard a task, this is the right command for it, but flag
  the unusual choice in the plan.
- `[STALE]` — the task's originating feature was re-architected, so its
  spec may no longer match the design. This is live work awaiting
  reconciliation, not abandoned work: the normal resolution is
  `/task-add feature=<slug>`, which updates or replaces the task. Never
  prune it by default. If the user names `[STALE]` explicitly, say all
  of that in the plan and confirm before applying.

## Implementable

The implementable statuses are `[MISSING]`, `[STUBBED]`, `[INCORRECT]`,
`[PARTIAL]`.

When a task is requested explicitly by number and its status is `[DONE]`,
`[SKIP]`, or `[IN PROGRESS]`, ask whether to skip or override. If it's
`[STALE]` and was requested explicitly by number, apply the stale protocol
in
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/stale.md`.
A batch selector skips all of those statuses instead of asking — see
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`.

## Accepting a status argument

Accept a status case-insensitively and with or without brackets —
`MISSING`, `missing`, `[MISSING]`, `in progress`, and `[IN PROGRESS]` are
all valid. If the value doesn't match any known status, tell the user the
valid options and stop.

## Transitions

- A status is written only in `.claude/TASKS.md`, never in a body file.
- `[DONE]` is untouchable. Completed work stands regardless of what the
  design did afterwards. Never flip a `[DONE]` task to `[SKIP]`,
  `[STALE]`, `[MISSING]`, or anything else; follow-up work is a NEW task.
- `[STALE]` → `[MISSING]` on an update-in-place reconciliation;
  `[STALE]` → `[SKIP]` when the task is substantially invalidated and a
  replacement is drafted. Both are `/task-add feature=<slug>`'s.
- `[MISSING]`/`[STUBBED]`/`[INCORRECT]`/`[PARTIAL]` → `[IN PROGRESS]` →
  `[DONE]` is `/task-implement`'s per-task path. `[PARTIAL]` is a legal
  terminal outcome there; `[INCORRECT]` is not — it "should not appear on
  a fresh implementation".
- Feature `Status:` values in `.claude/FEATURES.md` are a separate
  vocabulary (`[NEW]`, `[ITERATED]`, `[PLANNED]`, `[DONE]`) and are not
  governed by this file.

---

## Per-consumer notes

- **`/task-list`** — treats the status as a display filter and adds the
  gloss "`[STALE]` means the feature the task was generated from has been
  re-architected since — the task is still live work, but its spec may no
  longer match the design. It is filterable like any other status." It
  renders the tag in a padded column: "The longest tag is `[IN PROGRESS]`
  (13 chars)."
- **`/task-clean`** — treats the status as a prune set. Its default set,
  when no argument is given, is the terminal pair `[DONE]` and `[SKIP]`;
  an explicit argument replaces that set rather than adding to it, and any
  canonical status may be named, with the warnings above. It changes no
  status: it removes whole summary blocks.
- **`/task-add`** — writes `Status:` only when creating a task, and only
  `[MISSING]` unless the description says otherwise. It never sets
  `[IN PROGRESS]`, `[DONE]` or `[STALE]`, and during reconciliation it may
  write `[SKIP]` on a superseded task or flip `[STALE]` back to
  `[MISSING]`.
- **`/task-implement`** — the only consumer that writes `[IN PROGRESS]` and
  `[DONE]`. `[PARTIAL]` is used "only if you discovered a sub-requirement
  during impl that genuinely belongs in a separate task — surface this to
  the user before choosing this status." A run that fails leaves the task
  `[IN PROGRESS]` deliberately, "so the user can see where the run
  stopped."
