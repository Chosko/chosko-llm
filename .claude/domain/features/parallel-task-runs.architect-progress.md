# architect progress — parallel-task-runs

Resume aid for an interrupted `/architect` run. Not a feature document.

## Input

Free-form prompt: let the pipeline work on several tasks at once, handling
worktrees and merges; extended by the user to runbooks (steps scheduled by
their dependency graph) and to `--parallel max`. `Source: product-design.md
§ Task backlog`. No `FEATURES.md` entry exists for any target; no iterate
guard. Stack exists (`technical-direction.md`): bash + markdown skills, git.
Council not installed in this session — gate silent.

## Covered so far

- Inputs read: domain index, product design, technical direction, FEATURES,
  task-workflow, task-implement + delegation context files, launcher and
  unattended-parking feature docs, `delegated-runs.md`, `commit.md`,
  `tree.md`, `resolution.md`, `parking.md`, routing row of `/task-implement`,
  `/runbook-run`'s execution loop, spawned prompt, result cases, one-run
  rule, depth budget, commit cadence, step markers, OPERATING RULES,
  `/runbook-create`'s sequencing questions.
- First shape proposed; user answered: runbooks in scope via the
  `Depends on:` graph; `--parallel max`; the agent that arrives second
  integrates what landed while it worked.
- Second shape proposed as a three-document split, awaiting confirmation.

## Decisions proposed (not yet confirmed)

- Three low-level features: `worktree-isolation` (shared protocol),
  `parallel-task-runs` (`/task-implement --parallel <N|max>`),
  `parallel-runbooks` (`Parallelism:` header, `/runbook-run --parallel`).
- Worktree protocol home: `task-engine/references/worktree.md`;
  `/runbook-run` gains `requires: skill:task-engine`.
- One worktree per unit of work at `.claude/worktrees/<unit>` on branch
  `wt/<unit>`, excluded via `.git/info/exclude`.
- The agent authors and integrates (commit on its branch, rebase onto the
  base tip, re-verify when the base moved, resolve conflicts by re-applying
  its intent); the launcher lands (ff-only into base, push) and is the only
  writer of the base branch; a non-ff landing relays "rebase again" to the
  same agent.
- In-flight = the worktree exists; statusline and dashboard gain that probe;
  it is also the runbook resume signal under parallel, where `[~]` may be
  committed.
- Tasks: eligibility re-derived on the base `TASKS.md` after every landing;
  `Files:` overlap serialises, a CLAUDE.md marker exempts files; parent-kept
  tasks are barriers.
- Runbooks: `Depends on:` is the only ordering constraint under parallel,
  list order the priority; `Parallelism:` header exclusive with
  `Sequencing:`; `--parallel` refused while `Sequencing:` is present;
  `Needs:` steps are barriers; `/runbook-create` authors the full graph when
  asked for a parallel runbook.
- Failure keeps the worktree, reports its path, never respawns while it
  exists; `/task-clean` and `/runbook-clean` sweep worktrees of finished
  units.

## Open questions so far

- Exact wording of the exemption marker.
- Depth budget for `/task-implement --parallel` inside a runbook step.
