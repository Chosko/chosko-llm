# architect progress — parallel-task-runs

Resume aid for an interrupted `/architect` run. Not a feature document.

## Input

Free-form prompt: let the pipeline work on several tasks at once, handling
worktrees and merges. Resolved to one target, slug `parallel-task-runs`,
`Source: product-design.md § Task backlog`. No `FEATURES.md` entry exists;
no iterate guard. Stack exists (`technical-direction.md`): bash + markdown
skills, git. Council not installed in this session — gate silent.

## Covered so far

- Inputs read: domain index, product design, technical direction, FEATURES,
  task-workflow, task-implement + delegation context files, launcher and
  unattended-parking feature docs, `delegated-runs.md`, `commit.md`,
  `tree.md`, `resolution.md`, `parking.md`, routing row of `/task-implement`.
- Shape proposed to the user (PHASE 1 questions + PHASE 2 shape in one
  message), awaiting confirmation.

## Decisions proposed (not yet confirmed)

- Scope: `/task-implement` only; runbook steps stay sequential.
- Flag `--parallel <N>` (N ≥ 2), implies `--agents`; refuses `--no-agents`,
  `--no-commit`, non-git VCS.
- One git worktree per delegated task at `.claude/worktrees/task-<N>` on
  branch `wt/task-<N>`, excluded via `.git/info/exclude`.
- The agent authors and integrates (commit on its branch, rebase onto the
  base tip, retest when the base moved); the launcher lands (ff-only merge
  into base, push) and is the only writer of the base branch.
- Scheduling: eligibility re-derived on the base `TASKS.md` after every
  landing; in-flight tasks count as neither done nor eligible; `Files:`
  overlap serialises; a CLAUDE.md marker names files exempt from the
  overlap rule; parent-kept tasks are barriers.
- In-flight = the worktree exists; statusline and dashboard gain that probe.
- Failure keeps the worktree, reports its path, never respawns the task
  while the worktree exists; `/task-clean` sweeps worktrees of terminal
  tasks.

## Open questions so far

- Whether to split into two documents (worktree protocol vs scheduler).
- Exact exemption marker wording.
