# Parallel runs (`--parallel <N|max>`, `Parallel policy:`)

Read at ARGUMENT PARSING by SKILL.md's parallel hook — `--parallel` passed,
or a `Parallel policy:` line other than `off` on a top-level run — to resolve
PARALLEL and its refusals; follow the rest only when PARALLEL is set on a run
that resolves to 2 or more tasks. A run the hook does not fire for never
opens this file. It amends SKILL.md and `./delegated-runs.md` for the whole
run — where a section here speaks, it wins over the section it names.

Read `../task-engine/references/worktree.md` before the first spawn. The unit
there is `task-<N>`; that file owns the worktree, the agent's integration, the
landing, the two invariants, the in-flight signal and failure. This file
states only the launcher's scheduling and its own departures.

---

## Resolving PARALLEL

- **Sources, first match wins:** `--no-parallel` → off; `--parallel <N|max>`
  → that value; the project's `CLAUDE.md` line `Parallel policy: <value>` —
  `off`, an integer of 2 or more, or `max` (case-insensitive) — → that
  value; nothing → off. `max` means no bound. The line is the project's
  opt-in, offered by `/project-setup`, default off; a nested run reads only
  the flag (SKILL.md's hook).
- `--parallel` beside `--no-parallel` stops the run with:
  `--parallel and --no-parallel cannot be combined. Pick one.`
- On, PARALLEL is that value and DELEGATE = true: one conversation cannot
  implement two tasks at once, so it implies `--agents` and PRE-FLIGHT step
  2b asks nothing.
- **A value from the flag** is refused, each with one line:
  - beside `--no-agents`: `--parallel and --no-agents cannot be combined.`
  - beside `--no-commit`: `--parallel and --no-commit cannot be combined.` —
    a landing is made of commits;
  - on a project whose `CLAUDE.md` maps git to another VCS (a `## VCS`
    section): `--parallel needs git — this project's CLAUDE.md maps another
    VCS.`;
  - `N` below 2, or neither an integer nor `max`: `--parallel needs an
    integer of 2 or more, or max.`
- **A value from the line** is never refused: on any of the first three
  conditions above the run stays sequential, with one line —
  `Parallel policy ignored for this run: <condition>.` — and nothing else in
  this file applies. A line value outside the set stops the run with:
  `Parallel policy: in CLAUDE.md needs off, an integer of 2 or more, or max.`
- Accept and ignore PARALLEL, silently, on a run that resolves to a single
  task.
- Every other flag composes unchanged and rides through the agent prompt.

**The parallel-safe marker.** At PRE-FLIGHT step 3, look in `CLAUDE.md`, once,
for a line `Parallel-safe files for /task-implement: <path>, <path>` and set
PARALLEL_SAFE to its comma-separated paths, each relative to the repository
root as a `Files:` line writes them. Its one reader is § *The overlap rule*.
No marker means no file is exempt.

## The scheduler

- The task list is still resolved once, up front, and the resolution report
  and the delegation count are printed from it. Its role changes: it is the
  **admissible set** — the tasks this run may start — and its order is the
  **priority** among the tasks eligible at the same moment.
- **In flight** means spawned by this run and not yet landed, held in run
  memory: a task enters the set at its spawn and leaves it at its landing.
  Every "in flight" below — the count against N, eligibility, the overlap
  rule, a barrier's wait, the end-of-run test — means membership in that set.
  Git's worktree list is what the skip-while-present rule reads, never what
  counts: a worktree an earlier run left behind skips its task with
  `worktree.md`'s one line, once per task per run, and counts toward nothing.

At every **scheduling point** — the start of the run, and each landing:

1. Re-read the base `.claude/TASKS.md` and re-derive eligibility for every
   task in the list per `../task-engine/references/resolution.md`
   § *Eligibility*, read as `worktree.md` § *Eligibility while a unit is in
   flight* says. This subsumes BETWEEN
   TASKS step 2's precondition re-check.
2. Walk the list in order and, while fewer than N tasks are in flight — no
   bound under `max` — start each task you may: create its worktree per
   `worktree.md` § *Creating the worktree*, then spawn its agent with
   `run_in_background: true` and the prompt of § *The agent prompt* below.
   Skip a task that is not eligible, in flight, held back by the overlap rule,
   or not in flight with a worktree already present. A skipped task is
   examined again at the next scheduling point.
3. Stop the walk at a barrier (below); otherwise walk the whole list, then
   wait for the next return.

- An explicit-list task is still never blocked by a precondition that is not
  in flight; one whose precondition is in flight waits for it to land.
- The run ends when nothing is in flight and nothing in the list can start.
  FEATURE COMPLETION and the closing report follow as on any run.
- In skip-tests mode, ask "Proceed?" once per scheduling point that starts at
  least one task, not once per task.

### The overlap rule

- Never keep two tasks whose `Files:` lines intersect in flight together. At
  each scheduling point, hold back a task whose `Files:` paths intersect those
  of a task in flight, whatever N says, with one line naming the task it waits
  on — `Task 24 waits on task 22 (both list skills/foo/SKILL.md).` — once per
  task it waits on. It may start once that task has landed.
- First remove the PARALLEL_SAFE paths from every `Files:` line. An empty or
  missing `Files:` holds nothing back and is never held back.
- The rule is a safety net under `Preconditions:`, not a second dependency
  graph: it keeps two agents from editing one file, the common cause of a
  rebase conflict at the landing.

### Barriers

A task the delegation guard keeps in the parent runs in the base tree and
dirties it, and at every landing the base may hold no change a fast-forward
would overwrite (`worktree.md` § *The two invariants*). When the walk reaches one not yet run this run:

1. start nothing more, and land every task in flight — handling each return
   as it arrives, questions relayed as usual;
2. run the parent-kept task exactly as an in-context run does, in the base
   tree, BETWEEN TASKS step 2's one-line skip included;
3. its commit, park or skip is the next scheduling point.

A parent-kept task therefore runs in its list position and never in a
worktree.

## The agent prompt

The flag list carries PARALLEL and, with it, **the worktree path**: the
absolute path of `.claude/worktrees/task-<N>`, named as the agent's repository
root, with the base branch's name. The dirty-tree decision is always *clean*.
The prompt's first sentence ends instead:

> … make its single commit on `wt/task-<n>` in the worktree at `<absolute
> worktree path>` — your repository root for everything you do, a checkout of
> that branch from the base branch `<base>` — then integrate it as the
> `task-engine` skill's `references/worktree.md` § *The agent integrates*
> says, and return naming the base tip you rebased onto. Do not push, and do
> not pull: the launcher lands and pushes.

The return's third field names, beside the commit hash, the base tip the agent
rebased onto. In the agent, PER-TASK WORKFLOW Step 7 is `worktree.md`
§ *The agent integrates*: its push is the launcher's.

## Returns, questions and landings

- Handle returns one at a time, in arrival order. Land each one first, per
  `worktree.md` § *The orchestrator lands*; a landing that fails is the task's
  failure. Then run § *Between delegated tasks* on the base tree, then the
  scheduling point.
- A relayed question stops nothing but its own task: wait for its result as
  one more return to arrive. Land and bookkeep as usual a return that arrives
  while a question is open, render a second question in its own block, send
  each answer back by agent id, and after every relay print one line naming
  the agents still waiting on the user: `Waiting on you: tasks 22 (round 1),
  25 (round 2).` The one rebase-again message of a landing goes through the
  same channel.
- The progress line names what is in flight: "Task 20 landed (`abc1234`). In
  flight: 22, 23. Starting task 24." — the tasks the scheduling point starts
  named last, or "Nothing more to start." when it starts none.

## Failure

- A failed task halts spawning. Let the tasks already in flight finish and
  land — each return handled as above, with no scheduling point after it — so
  no committed work is stranded in a worktree; give the closing report once
  nothing is in flight.
- A failed task keeps its worktree (`worktree.md` § *Failure*), and its row
  in the failure report and in the closing report names that path.
