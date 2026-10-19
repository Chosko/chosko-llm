# The worktree sweep

Authority for: removing the `.claude/worktrees/<unit>` worktrees and
`wt/<unit>` branches (`./worktree.md` names them) that a parallel run left
behind for finished units — when the sweep runs, what it lists, which units
are finished, its plan section, its removal, its report and its flags.

Authored in the engine — no feature ever carried a copy of it. Read by
`/task-clean` and `/runbook-clean` only when `.claude/worktrees/` exists; a
project that never ran in parallel never opens this file and pays no git call
for it. These rules are the whole sweep: never open `./worktree.md` for it.

---

## When it runs

- Only when `.claude/worktrees/` exists — the consumer's one Glob, no shell.
- Never when the project's `CLAUDE.md` carries a `## VCS` section: a
  parallel run needs git, so no worktree of this product exists there.
- Skipped, the sweep adds no plan section, no step and no report line, and
  says nothing about itself.

## What it lists

- `git worktree list --porcelain` entries whose path is
  `.claude/worktrees/<unit>` or whose branch is `wt/<unit>`, and
  `git branch --list 'wt/<prefix>*'` — the consumer's units only (§ *Per
  consumer*). Nothing is on the remote, and nothing is listed there.
- A unit is **finished** as § *Per consumer* says. Any other unit keeps its
  worktree, unlisted: it may hold the only copy of the work.

## Plan, removal and report

- The consumer's plan gains one section, omitted when the list is empty:

  ```
  Worktrees to remove (W):
    .claude/worktrees/<unit>   wt/<unit>   <why it is finished>
  ```

- A plan holding only this section is not empty: the consumer's "nothing to
  prune" stop does not fire, and the plan holds only the sweep.
- Remove each listed worktree after the consumer's one **"Apply?"**, beside
  its other removals: `git worktree remove .claude/worktrees/<unit>`, then
  the safe `git branch -d wt/<unit>`. A failure is a *Follow-ups* item naming
  the path and the command — never fatal, never retried.
- The consumer's report names what the sweep removed, what failed and what it
  left in place.

## Flags and commits

The sweep is local throughout and changes no tracked file. It runs whole
under `--no-commit` and `--no-push` — its listing, removes and deletes join
the consumer's shell use there — adds nothing to the commit, and a run that
only sweeps commits nothing.

---

## Per consumer

- **`/task-clean`** — units `task-<N>`, prefix `wt/task-`. Finished: task N
  is `[DONE]` or `[SKIP]`, or has no summary block (archived and terminal,
  `./resolution.md` § *The archive*), as PHASE 1 read `TASKS.md`. The list
  is made in PHASE 1 step 2 beside the park-branch sweep's; the removal is
  PHASE 2 step 7.
- **`/runbook-clean`** — units `runbook-<id>-step-<n>`, prefix
  `wt/runbook-`. Finished: runbook `<id>` is in the set STAGE 1 resolved for
  removal, or its body holds step `<n>` as `[x]` (an `Archive:` id
  included) — the one reason to open a body this command is not deleting. A
  worktree whose runbook or step no longer exists is left in place and named
  in the report. The list is made at the end of STAGE 1; the removal follows
  the deletions in STAGE 3; the index backfill is still written only on a run
  that deletes a runbook.
