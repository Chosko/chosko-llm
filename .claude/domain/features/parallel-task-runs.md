# Parallel task runs

An opt-in parallel mode for `/task-implement`'s delegated runs, under which
the launcher keeps up to N tasks in flight at once — or, under `max`, every
task that is eligible — each in its own worktree per
[worktree-isolation](./worktree-isolation.md), and lands them onto the base
branch one at a time as they return. A project opts in with a `CLAUDE.md`
line `Parallel policy: <N|max>`; a run opts in or out with
`--parallel <N|max>` / `--no-parallel`. A run that does not resolve parallel
is one agent at a time, in the base tree, and loads none of this feature's
rules.

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

In scope: the policy line, the flags and their refusals; the scheduler —
which task starts when, and how many; the overlap rule that keeps two tasks off the same files, with
its project-level exemption; what the parent's own tasks do to the schedule;
the landing, the progress lines and the closing report under concurrency.

Deliberately out:

- **Parallelism without `--agents`.** An in-context run is one conversation
  and cannot implement two tasks at once. A parallel run implies `--agents`,
  and `--no-agents` beside the flag is an argument error.
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
  take the outcome they take on a sequential run — kept in the parent,
  skipped with one line — and are never spawned into a worktree.
- **A merge strategy.** How a task's work reaches the base is
  `worktree-isolation`'s, not this document's.
- **Parallel by default.** A project that sets no `Parallel policy:` line is
  sequential; nothing guesses parallelism from the shape of the backlog.

## Architecture

Built on the repo's existing shape per `technical-direction.md`. The change
lands in `skills/task-implement/`: a short "Parallel flags" hook in SKILL.md's
argument parsing and one in `delegated-runs.md`, and everything else — the
resolution of PARALLEL, its refusals, the scheduler — in `parallel-runs.md`
(`.claude/context/task-implement-delegation.md`). The scheduling reading of
eligibility lives in `task-engine`'s `worktree.md` § *Eligibility while a
unit is in flight*, beside the rest of the protocol, so `resolution.md`
carries nothing for it. `/project-setup` offers the policy line. It adds no
CLI surface and no script.

### What a sequential run pays

A project that does not opt in pays for this feature only its words in the
skill description and the hook lines; every protocol file — `parallel-runs.md`,
`worktree.md` — is read on demand. The hook opens `parallel-runs.md` only
when `--parallel` was passed, or when neither flag was, the run is top-level
and the project's `Parallel policy:` line is other than `off`. That is why
the opt-in is a project line and not a default: the cost of the rules falls
only on the runs that use them.

### Resolving PARALLEL

One value per run, first match wins: `--no-parallel` → off;
`--parallel <N|max>` → that value; the project's `CLAUDE.md` line
`Parallel policy: off | <N> | max` (N ≥ 2, case-insensitive) → that value;
nothing → off. `max` means no bound. A nested run — a delegated agent, a
subagent, a run under OPERATING RULES or INLINE RULES — reads only the flag,
so a project's opt-in never makes a step's or an agent's own run parallel.
`--parallel` beside `--no-parallel` is an argument error.

On, PARALLEL implies `--agents`, so the delegation question is never asked.
**A value from the flag** is refused, each with one line: `--no-agents` (one
conversation cannot run two tasks); `--no-commit` (a landing is made of
commits, as parking is); a `CLAUDE.md` mapping git to another VCS (no
worktree exists there); and N below 2 or a value outside the set. **A value
from the line** is never refused, because the project chose it once and a
run that happens to pass `--no-commit` must not fail for it: under the first
three conditions the run stays sequential with one line,
`Parallel policy ignored for this run: <condition>.` A malformed line value
stops the run. Parallelism on a run that resolves to a single task is a
silent no-op: there is nothing to run beside it.

Every other flag composes unchanged and rides through the agent prompt —
`--review`, `--unattended`, `-y`, `--no-push`.

### The scheduler

`all` is still resolved once, up front, by `resolution.md`'s simulation, and
the resolution report and the delegation count are still printed from it.
What changes is what the launcher does with the list: it is no longer a
queue walked in order but the set of tasks this run may start, and the order
in which they were selected is the priority among tasks that are eligible at
the same moment.

At every **scheduling point** — the start of the run, and each landing — the
launcher re-reads the base `TASKS.md`, as it already does between tasks, and
re-derives eligibility with `resolution.md`'s clause exactly as written, read
as `worktree.md` § *Eligibility while a unit is in flight* says: **a task in
flight is neither done nor eligible**. The in-flight set is the tasks this run spawned and not yet
landed, in run memory; the worktree list is what the skip-while-present rule
reads, so a worktree an earlier run left behind skips its task and counts
toward nothing. It then starts tasks from the resolved list, in list order,
while fewer than N are in flight (no bound under `max`), skipping each task
that is not eligible on this read, that is in flight, that is held back by
the overlap rule below, or that is not in flight and whose worktree already
exists. A task skipped here is not dropped: it is re-examined at the next
scheduling point. The run ends when nothing is in flight and nothing in the
list can start.

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
in its `CLAUDE.md`, beside the `Testing policy for /task-implement:` marker
and read the same way; `/project-setup` asks for it as a follow-up when the
parallel policy it writes is not `off`:

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
unblocks them when it is done.

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
them as never started.

### Failure

A delegated task's failure halts the run as on a sequential run: no further task is
spawned. Tasks already in flight are allowed to finish and land — abandoning
them would strand committed work in worktrees for no gain — and the closing
report then names which tasks completed, which failed and what the
agent said, and which were never started.

## Data and state

Nothing is added to any index. The in-flight set is the tasks this run
spawned and not yet landed, in run memory; the worktree list is what the
skip-while-present rule reads. The schedule is derived at every scheduling
point from the base `TASKS.md` and held in memory only, with the resolved
list, N, and the overlap exemptions read once from `CLAUDE.md` at
pre-flight. The project's opt-in is the `Parallel policy:` line, read at
argument parsing. `Files:` and `Preconditions:` keep their shape and gain a second
reader each.

## Interfaces and contracts

```
/task-implement all --parallel 3                 up to three agents in flight
/task-implement all --parallel max               every eligible task at once
/task-implement all                              the Parallel policy: line's value, else sequential
/task-implement all --no-parallel                sequential, whatever the line says
/task-implement 12 14 15 --parallel 2            an explicit list, same rules
/task-implement all --parallel 3 --review --unattended
/task-implement all --parallel 1                 argument error: N must be 2 or more
/task-implement all --parallel 3 --no-agents     argument error
/task-implement all --parallel 3 --no-commit     argument error
/task-implement all --parallel 3                 argument error on a non-git VCS
/task-implement all --parallel 3 --no-parallel   argument error
/task-implement all --no-commit                  under Parallel policy: 3, sequential with one line
```

| Sequential run | Parallel run |
|---|---|
| Agents spawned one at a time, parent blocks on each | Up to N in flight; returns handled one at a time as they arrive |
| Each agent works in the base tree | Each agent works in `.claude/worktrees/task-<N>` |
| Each agent commits and pushes its task | Each agent commits and integrates; the launcher lands and pushes |
| `all`'s list is walked in order | `all`'s list is the admissible set; eligibility re-derived at every landing |
| Parent-kept tasks run in list order | Same, as barriers: nothing in flight while they run |
| A failure spawns nothing more | Same; tasks in flight land first |

The agent prompt gains two run-level values — PARALLEL and the unit's
worktree path — and stays O(1) in the batch. The explicit-list selector is
never blocked by a precondition; under a parallel run an explicit
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
  carries the flags and the two markers, guarded by `check-routing.sh`.
- `/project-setup` — offers the `Parallel policy:` line (default off) and,
  when it is not off, the parallel-safe marker; the skill declares both under
  `project-policy:`, guarded by `check-setup.sh`.

## Open questions

None. With several agents in flight under `attended`, each relay block
carries its task heading, the answer goes back by agent id, and one line
after every relay names the agents still waiting on the user.
