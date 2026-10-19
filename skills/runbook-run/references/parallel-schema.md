# A parallel runbook

The schema of a runbook whose header carries `Parallelism:`, amending
`./runbook-schema.md` for that runbook only. Read by a feature that finds the
line in a body — `/runbook-run`, `/runbook-create`, `/runbook-describe` — and
by `./parallel.md` and `./parallel-authoring.md`. A reader that does not find
the line never opens this file, and a runbook without it is exactly
`./runbook-schema.md`.

---

## The header line

- **`Parallelism:`** — an integer of 2 or more, or `max` (case-insensitive):
  how many steps a run keeps in flight at once, each in its own worktree
  (`../../task-engine/references/worktree.md`), scheduled by `Depends on:`.
  `max` means no bound. Absent means 1: one step at a time, in list order.
- Written directly after `Execution policy:`, by `/runbook-create` only
  (`./parallel-authoring.md`), on a new runbook — never on an append, and
  never rewritten by a run. `/runbook-run --parallel <N|max>` and
  `--no-parallel` override it for one run (`./parallel.md`).
- Any other value is an **argument error at run time**.
- **Never beside `Sequencing:`.** That line records an ordering constraint
  the graph does not carry, which a parallel run would violate silently; a
  parallel runbook carries every ordering constraint as `Depends on:` edges.

## A step

- **`Depends on:` is the only ordering constraint** under a parallelism above
  one: a step runs once every step it names is `[x]`, alongside whatever else
  is selectable, and a step with no edge to another is independent of it by
  the runbook's own declaration.
- **List position is priority** among the steps selectable at the same
  moment, not an order.

## The `[~]` marker

A run whose parallelism is above one **may commit `[~]`**: a landed step's
commit carries `[~]` for the steps still in flight. Its resume signal is
`[RUNNING]` in the index plus a `wt/runbook-<id>-step-<n>` worktree on this
machine; a `[~]` with no worktree behind it is a step an interrupted run left
behind.

---

## Per-consumer notes

- **`/runbook-describe`** renders a body carrying the line as a parallel
  runbook, and every other body exactly as its own body says:
  - end the header line with `Parallelism: <value>`, as the body holds it;
  - close the header region with one line counting the steps present whose
    `Depends on:` is `none` — `Independent: 4 of 7 steps (Depends on:
    none)` — an archived id counting in neither number;
  - tag each `[~]` step `in flight`, last on its line, and name `[~]` "in
    flight" in the closing count. Never check for a worktree behind it — the
    command runs no shell.
