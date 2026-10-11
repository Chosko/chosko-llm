# Parallel task runs

A `--parallel <N|max>` mode for `/task-implement`'s delegated runs, under
which the launcher keeps up to N tasks in flight at once — or, under `max`,
every task that is eligible — each in its own worktree per
[worktree-isolation](./worktree-isolation.md), and lands them onto the base
branch one at a time as they return. Without the flag nothing changes: one
agent at a time, in the base tree, as today.

## Purpose

A batch `/task-implement all --agents` over a backlog of independent tasks
spends most of its wall-clock time waiting on one agent while the others
could already be working. The backlog already records what actually
constrains the order — `Preconditions:` — and the batch selectors already
honour it; what forced the agents into single file was the shared tree, not
the dependencies. With the tree per task provided by `worktree-isolation`,
the launcher can run every task whose preconditions are met and let the
graph, not the list, decide the pace.

The feature serves the [Task backlog](../product-design.md#task-backlog) flow
end to end: the director launches a long run and gets it back sooner, Claude
as operator keeps the one-commit-per-task record, and nothing a task does
changes. It restates no part of [task-implement-launcher](./task-implement-launcher.md):
the launcher stays a launcher, and the fixed-size prompt gains one path.

## Scope and non-goals

In scope: the flag and its refusals; the scheduler — which task starts when,
and how many; the overlap rule that keeps two tasks off the same files, with
its project-level exemption; what the parent's own tasks do to the schedule;
the landing, the progress lines and the closing report under concurrency.

Deliberately out:

- **Parallelism without `--agents`.** An in-context run is one conversation
  and cannot implement two tasks at once. `--parallel` implies `--agents`,
  and `--no-agents` beside it is an argument error.
- **Changing the delegation guard.** `human`, `claude+human` and explicitly
  requested `[STALE]` tasks still stay in the parent, for the reasons
  `targets.md` gives; this feature only says when they run.
- **A dependency graph beyond `Preconditions:`.** No new field, no inferred
  edges. Two tasks with no edge between them are independent by the
  backlog's own declaration, and the overlap rule below is a safety net under
  that declaration, not a second graph.
- **Reading a task body to predict conflicts.** The parent opens no body, on
  any path, ever — the launcher's hard contract. Everything the scheduler
  needs is on the summary block.
- **Parallel `[STALE]`, human or parked-without-answer work.** Those tasks
  take the outcome they take today — kept in the parent, skipped with one
  line — and are never spawned into a worktree.
- **A merge strategy.** How a task's work reaches the base is
  `worktree-isolation`'s, not this document's.

## Architecture

Built on the repo's existing shape per `technical-direction.md`. The change
lands in `skills/task-implement/` — its argument parsing and
`delegated-runs.md` (`.claude/context/task-implement-delegation.md`) — and in
`task-engine`'s `resolution.md`, which gains the scheduling reading of its own
eligibility clause. It adds no CLI surface and no script.

### The flag

`--parallel <N>` with N ≥ 2, or `--parallel max`, case-insensitive. It sets
PARALLEL in the run's resolved flags and implies `--agents`, so the delegation
question is never asked. Refused, each with one line: `--no-agents` (one
conversation cannot run two tasks); `--no-commit` (a landing is made of
commits, as parking is); a `CLAUDE.md` mapping git to another VCS (no
worktree exists there); and N below 2, since one is the sequential run and
has no flag. `--parallel` on a run that resolves to a single task is a silent
no-op: there is nothing to run beside it.

Every other flag composes unchanged and rides through the agent prompt as it
does today — `--review`, `--unattended`, `-y`, `--no-push`.

### The scheduler

`all` is still resolved once, up front, by `resolution.md`'s simulation, and
the resolution report and the delegation count are still printed from it.
What changes is what the launcher does with the list: it is no longer a
queue walked in order but the set of tasks this run may start, and the order
in which they were selected is the priority among tasks that are eligible at
the same moment.

At every **scheduling point** — the start of the run, and each landing — the
launcher re-reads the base `TASKS.md`, as it already does between tasks, and
re-derives eligibility with `resolution.md`'s clause exactly as written, with
one reading added for concurrency: **a task in flight is neither done nor
eligible**. It then starts tasks from the resolved list, in list order, while
fewer than N are in flight (no bound under `max`), skipping each task that is
not eligible on this read, that is in flight, that is held back by the
overlap rule below, or whose worktree already exists. A task skipped here is
not dropped: it is re-examined at the next scheduling point. The run ends
when nothing is in flight and nothing in the list can start.

`Preconditions:` is therefore the whole graph. A task whose precondition is in
flight waits for that task to land, not merely to be spawned, because landing
is what writes `[DONE]` to the base `TASKS.md` the next read sees. The
between-tasks re-check of an `all` run — a precondition that no longer holds
— is subsumed: eligibility is re-derived on every read anyway.

### The overlap rule

Two tasks whose `Files:` lines intersect are not run at the same time: when
one is in flight, the other is held back until it lands, whatever N says.
`Files:` is on the summary block, so the rule costs no read. It is a safety
net under the backlog's declaration of independence — two tasks editing one
file are the common way a rebase meets a conflict, and a conflict avoided is
cheaper than one resolved — not a second dependency graph: an empty or
missing `Files:` holds nothing back.

A project can exempt files whose conflicts the integrating agent resolves
mechanically — a version counter, a newest-first changelog — with one marker
in its `CLAUDE.md`, beside the existing
`Testing policy for /task-implement:` marker and read the same way:

```
Parallel-safe files for /task-implement: VERSION, CHANGELOG.md
```

Paths on that line are removed from every `Files:` line before the
intersection is taken. The marker exists because in a repository where every
shipped change bumps a version file, every task lists it, and without the
exemption the rule would serialise the whole run; the resolving rule in
`worktree-isolation` — re-apply your intent on top of what landed — is what
makes those files safe to exempt. No marker means no exemption.

### Barriers

A task the delegation guard keeps in the parent runs in the base tree, in the
conversation, and dirties the base tree while it runs. The base must be clean
at every landing, so such a task is a **barrier**: when the scheduler's next
task in list order is parent-kept, it starts nothing more, waits for every
task in flight to land, runs the parent-kept task exactly as an in-context run
does, and only then resumes spawning. Parent-kept tasks therefore run in
their list position relative to what they wait on, never silently deferred
to the end, and a `human` task that is a precondition of five delegated tasks
unblocks them when it is done, as it does today.

### Landing and bookkeeping

Each agent's return is handled as `worktree-isolation` § *The orchestrator
lands* says — fast-forward, the one rebase-again message to the same agent
where needed, push, remove — then the launcher's between-tasks steps run
unchanged on the base: re-read `TASKS.md`, confirm the status the agent
reported, apply the feature-completion check, read chat replies by `P<n>`
handle, print the progress line. Returns arrive asynchronously and are
handled one at a time, in arrival order; a question relayed from one agent
does not stop another agent's landing, since the relay waits on the user and
the landing does not.

The progress line names what is in flight: *Task 20 landed (`abc1234`). In
flight: 22, 23. Starting task 24.* The six-field return contract is unchanged,
the feature-completion proposal stays batched to the end of the run, and the
closing report keeps its two groups; a failed task's row names its worktree
path, and a run that ended with tasks still waiting on a failed one names
them as never started, as today.

### Failure

A delegated task's failure halts the run as it does today: no further task is
spawned. Tasks already in flight are allowed to finish and land — abandoning
them would strand committed work in worktrees for no gain — and the closing
report then names, as today, which tasks completed, which failed and what the
agent said, and which were never started.

## Data and state

Nothing is added to any index. The in-flight set is the worktree list; the
schedule is derived at every scheduling point from the base `TASKS.md` and
held in memory only, with the resolved list, N, and the overlap exemptions
read once from `CLAUDE.md` at pre-flight. `Files:` and `Preconditions:` keep
their shape and gain a second reader each.

## Interfaces and contracts

```
/task-implement all --parallel 3                 up to three agents in flight
/task-implement all --parallel max               every eligible task at once
/task-implement 12 14 15 --parallel 2            an explicit list, same rules
/task-implement all --parallel 3 --review --unattended
/task-implement all --parallel 1                 argument error: N must be 2 or more
/task-implement all --parallel 3 --no-agents     argument error
/task-implement all --parallel 3 --no-commit     argument error
/task-implement all --parallel 3                 argument error on a non-git VCS
```

| Contract today | Under `--parallel` |
|---|---|
| Agents spawned one at a time, parent blocks on each | Up to N in flight; returns handled one at a time as they arrive |
| Each agent works in the base tree | Each agent works in `.claude/worktrees/task-<N>` |
| Each agent commits and pushes its task | Each agent commits and integrates; the launcher lands and pushes |
| `all`'s list is walked in order | `all`'s list is the admissible set; eligibility re-derived at every landing |
| Parent-kept tasks run in list order | Same, as barriers: nothing in flight while they run |
| A failure spawns nothing more | Same; tasks in flight land first |

The agent prompt gains two run-level values — PARALLEL and the unit's
worktree path — and stays O(1) in the batch. The explicit-list selector is
never blocked by a precondition, as today; under `--parallel` an explicit
task whose precondition is in flight still waits for it to land, because
naming a task chooses that it runs, not that it runs before what it depends
on.

## Dependencies

- [worktree-isolation](./worktree-isolation.md) — the tree per task, the
  agent's integration, the landing, the in-flight signal and the sweep.
- [task-implement-launcher](./task-implement-launcher.md) — the launcher
  shape this schedules on; its no-body-read contract is what makes the
  overlap rule read `Files:` and nothing else.
- [backlog-ordering](./backlog-ordering.md) — `Preconditions:` as the
  load-bearing constraint the scheduler reads.
- [unattended-parking](./unattended-parking.md) — a `[PARKED]` return under
  concurrency is recorded and the next scheduling point runs; the pre-ask and
  the `P<n>` handles are unchanged.
- [pipeline-engine](./pipeline-engine.md) — the `/task-implement` routing row
  gains the flag, guarded by `check-routing.sh`.

## Open questions

- **The exemption marker's name.** `Parallel-safe files for /task-implement:`
  is the proposal; the final wording is settled when the marker is written
  beside the testing-policy one, so the two read alike.
- **Interleaved questions under `attended`.** With several agents in flight,
  two can ask at once; each relay block already carries its task heading and
  the answer goes back by agent id, so nothing new is needed. Whether to
  print a line naming the agents still waiting on the user is a readability
  call for implementation.
