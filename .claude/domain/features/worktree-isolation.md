# Worktree isolation

A shared protocol under which a unit of work — a task under `/task-implement`,
a step under `/runbook-run` — is executed in its own git worktree on its own
branch, integrated onto the base branch by the agent that did the work, and
landed onto the base by the orchestrating session with a fast-forward. It is
what lets two units run at the same time without sharing a working tree, a
branch or a staging area, and it is the mechanism both
[parallel-task-runs](./parallel-task-runs.md) and
[parallel-runbooks](./parallel-runbooks.md) are built on.

## Purpose

Both run-level skills of the [Task backlog](../product-design.md#task-backlog)
forbid concurrency for one stated reason: every unit of a run shares one
working tree, one branch and one index file, so two agents would race on
status flips, on staging and on push. The prohibition is correct for a shared
tree. This feature removes the sharing instead of the prohibition: each unit
gets a tree of its own, and the only thing the units still share — the base
branch — has exactly one writer.

It serves Claude as the operator of a long run, which gains throughput in
proportion to how independent the work is, and the director, who sees the
run finish in a fraction of the time with the same one-commit-per-unit
record. It changes nothing about what a unit does: the per-task workflow and
the step prompt execute exactly as they do today, in a different directory.

## Scope and non-goals

In scope: creating a worktree for a unit and removing it; how the unit's
agent integrates its work onto the moving base; how the orchestrator lands it
and pushes; what a worktree's existence means to every reader; what happens
when a unit fails, parks or is interrupted; the sweep of leftover worktrees;
and the one line each the status line and the dashboard gain.

Deliberately out:

- **Deciding what runs in parallel.** Which units may run together, how many,
  and in what order is each orchestrator's scheduling, in its own feature
  document. This protocol takes a unit and a base and knows nothing about
  the other units in flight.
- **Pushing from inside a worktree.** An agent never pushes to the base
  branch. The base is checked out in the orchestrator's tree, so a push into
  it from a worktree is refused by git under `--no-push` anyway; keeping the
  push in the orchestrator makes the local and the remote path the same
  path.
- **Merge commits.** A unit lands as a fast-forward of its rebased branch,
  so the history stays linear and a task still produces exactly one commit.
  A merge commit per unit would be a second commit describing the first.
- **A lock, a registry or a state file.** The worktree is the record of a
  unit in flight; git's own worktree list is the registry.
- **Worktrees for a sequential run.** A run with no concurrency works in the
  base tree as it always has. The protocol is loaded only by a run that
  asked for parallelism.
- **Non-git projects.** A project whose `CLAUDE.md` maps git to another VCS
  has no worktree to offer; a run asking for parallelism there is refused by
  the orchestrator, as `--unattended` already is.

## Architecture

Built on the repo's existing shape per `technical-direction.md`: shipped
markdown skills whose runtime is Claude Code, and git as the only mechanism.
The protocol is one reference file under `skills/task-engine/references/`
(`.claude/context/task-engine.md`), read by `/task-implement` and
`/runbook-run` only when a run resolved to a parallelism above one, exactly
the load discipline `parking.md` follows. `/runbook-run` declares
`requires: skill:task-engine` to read it, so `chosko-llm add` installs the
engine first and `rm` refuses to remove it while the orchestrator is installed
(`.claude/domain/features/shared-phase-engine.md`). No CLI surface and no
script are added.

### The unit, its worktree and its branch

A **unit** is one task or one runbook step, named by its orchestrator:
`task-<N>` for a task, `runbook-<id>-step-<n>` for a step. From that name the
protocol derives two deterministic names and nothing else: the worktree
directory `.claude/worktrees/<unit>` under the project root, and the branch
`wt/<unit>`. Both are derived, never recorded — the same rule as
`park/task-<N>`.

The orchestrator creates the worktree from the current tip of the base branch
on a fresh `wt/<unit>` branch, immediately before it spawns the unit's agent,
and hands the agent the directory as the repository root for everything it
does. The directory sits under `.claude/` because that is where per-project
working state already lives (`.claude/sessions/`, `.claude/reviews/`), because
a path inside the project needs no permission the agent does not already
have, and because the worktree's `.git` file keeps git from recursing into it.
The first run that creates one adds `.claude/worktrees/` to
`.git/info/exclude`, idempotently: git's own machine-local configuration, not
a state file of this product.

### The agent integrates

The agent executes the unit's work in the worktree exactly as it would in the
base tree — the per-task workflow Steps 1–7, or the step's prompt under
OPERATING RULES — with one change at the point where the unit would push:

1. commit on `wt/<unit>`, as many commits as the unit's own rules make — one
   for a task, whatever a step's prompt makes for a step;
2. rebase `wt/<unit>` onto the current tip of the base branch. The base is
   local; nothing is fetched, since the orchestrator keeps it current;
3. when the rebase met a conflict, resolve it by **re-applying the unit's own
   intent on top of what landed** — a version counter bumped again from the
   new value, an entry added again at the top of a newest-first log, a status
   flip re-made on a block another unit's flip sits next to — never by keeping
   one side whole. The agent that did the work is the one that knows its
   intent, which is why integration is the agent's and not the
   orchestrator's;
4. when the rebase changed anything — the base had moved — re-verify: the
   affected and full test runs in full test mode, the step's own verification
   for a step. A unit that passed its tests on the old base has not passed
   them on the new one;
5. return, naming the base tip it rebased onto.

The agent never pushes, never touches the base branch and never leaves the
worktree. Skills the unit invokes keep their default commit behaviour; their
pull-at-start, pre-push re-sync and push are the orchestrator's, so the agent
skips them as a run under `--no-push` does, and says so once.

Rebasing `wt/<unit>` is not rewriting anyone else's history: the branch is
private to the unit, unpushed, and exists for this one landing. `commit.md`
records that as this protocol's deviation from its never-rebase rule.

### The orchestrator lands

On the agent's return the orchestrator, whose base tree is clean, lands the
unit in this order:

1. **Fast-forward only** — merge `wt/<unit>` into the base with no other merge
   strategy allowed. It succeeds exactly when the base tip is still the one
   the agent rebased onto.
2. **When it is not** — another unit landed while this agent was finishing —
   send the **same agent** one message: the base is at this tip, rebase again
   and return. The question relay already addresses an agent by id and sends
   it an answer; this is that channel carrying one more kind of message. The
   agent repeats steps 2–5 above; the orchestrator fast-forwards again. At
   most one round per landing, because the orchestrator processes returns
   one at a time and is the only thing that moves the base.
3. **Push** the base, following the commit-and-push protocol's re-sync and
   push, unless the run is under `--no-push`.
4. **Remove** the worktree and delete `wt/<unit>` with the safe delete — the
   one that refuses a branch not reachable from the base. A refusal here is a
   landing that did not happen and halts the unit as a failure; it is the
   protocol's own consistency check, costing nothing.

Then the orchestrator does its own bookkeeping for the unit — re-reading
`TASKS.md`, or writing the step's marker and `Done:` line and committing
them — exactly as it does today.

Two invariants follow and are the whole safety argument. **The base branch
has one writer**, the orchestrator, so landings cannot race. **The base tree
is clean at every landing**, so a fast-forward never meets a local change it
would overwrite; an orchestrator whose own bookkeeping is dirty when a unit
touched the same files commits that bookkeeping first, then lands.

### A worktree is a unit in flight

A `wt/<unit>` worktree exists exactly while its unit is in flight, or after
its unit failed. Nothing else records that:

- The `[IN PROGRESS]` flip a task makes in Step 1 is made in the worktree's
  copy of `TASKS.md`, and the base copy never shows it — as today, where the
  flip is never committed and lives only in the dirty tree of the machine
  running it. A `[~]` step marker stays in the base body as the orchestrator
  writes it, since only the orchestrator writes that file.
- The status line and the dashboard, which today read `[IN PROGRESS]` off the
  working tree's `TASKS.md`, gain one probe each: the worktree list, read
  with git's porcelain form, names every unit in flight. One line in each
  renderer (`.claude/domain/features/pipeline-statusline.md`,
  `.claude/domain/features/pipeline-dashboard.md`).
- A run never starts a unit whose worktree already exists: it reports the
  path and skips the unit, under every selector. The two ways out are
  finishing the work in that worktree by hand or removing it.

### Failure, parking and interruption

- **Failure.** The worktree stays, with the unit's uncommitted or unlanded
  work and, for a task, its `[IN PROGRESS]` flip inside it. The run reports
  the path. Nothing on the base records the failure, exactly as today nothing
  committed records a task that stopped `[IN PROGRESS]`; the worktree's
  presence is the record, and the skip-while-present rule above is what
  keeps the next run from re-implementing over it.
- **Parking** (`parking.md`) composes unchanged, read in the worktree: the
  `park/task-<N>` branch is made from the worktree's head with the one
  work-in-progress commit, the bookkeeping commit is made on `wt/<unit>` and
  lands like any other commit, and the worktree is removed with it. The
  unpark cherry-picks in whatever tree the task is then running in.
- **Interruption.** An orchestrator that dies leaves worktrees behind. They
  are local to the machine and never pushed, so a worktree present on this
  machine means *this* tree is the one that was interrupted — the property
  the runbook resume signal relies on
  ([parallel-runbooks](./parallel-runbooks.md)).
- **Sweep.** `/task-clean` removes every `wt/task-<N>` worktree and branch
  whose task is `[DONE]` or `[SKIP]`, beside its `park/task-*` sweep;
  `/runbook-clean` removes every `wt/runbook-<id>-step-<n>` whose step is
  `[x]`, or whose runbook it is archiving. A worktree whose unit is not
  finished is never swept — it may be the only copy of the work.

## Data and state

- **`.claude/worktrees/<unit>/`** — a linked git worktree, present while the
  unit is in flight or failed; machine-local, excluded from the index through
  `.git/info/exclude`, never committed and never pushed.
- **`wt/<unit>`** — the unit's branch, created from the base tip at spawn,
  rebased by the agent, deleted at landing with the safe delete. Local only.
- **In memory only:** the base tip each in-flight unit was created from and
  the tip its agent last rebased onto, held by the orchestrator for its
  progress lines.

The source of truth is git throughout: which units are in flight is the
worktree list, whether a unit landed is reachability of `wt/<unit>` from the
base, and no file of this product duplicates either.

## Interfaces and contracts

What the protocol expects from an orchestrator: a unit name, a clean base
tree at every landing, one landing at a time, and the four flags it already
resolves (NO_PUSH, the testing mode, UNATTENDED, and the dirty-tree decision,
which in a fresh worktree is always *clean*). What the orchestrator's agent
prompt gains is one line: the worktree path as the repository root, and the
rule that the push is not the agent's. The fixed-size agent prompt of
[task-implement-launcher](./task-implement-launcher.md) stays O(1): one path
per unit, like the task number.

What it exposes: the worktree list as the in-flight signal, read by the status
line, the dashboard and the skip-while-present rule.

Failure contract: a worktree that cannot be created (the path exists, the
branch exists) skips the unit with one line naming the path; a rebase the
agent cannot complete is the unit's failure, worktree kept, reported with its
path; a fast-forward refused twice is a failure of the same kind; a push
failure after a landing is the commit-and-push protocol's — the base commit
exists locally and needs a manual sync, the run stops; a sweep that cannot
remove a worktree leaves it and names it in *Follow-ups*, never halting.

## Dependencies

- [task-implement-launcher](./task-implement-launcher.md) — the fixed-size
  prompt that carries the worktree path; the launcher's between-tasks
  re-read, which becomes the landing's bookkeeping.
- [unattended-parking](./unattended-parking.md) — the park and unpark
  sequences, executed in a worktree unchanged.
- [task-peer-review](./task-peer-review.md) — the review loop runs inside
  the worktree, before the unit's commit, as before Step 7 today.
- [shared-phase-engine](./shared-phase-engine.md) — the reference file's
  home, and the `requires:` field `/runbook-run` gains.
- [task-archive](./task-archive.md) — `/task-clean`'s sweep, which gains the
  worktrees beside the branches.
- [pipeline-statusline](./pipeline-statusline.md),
  [pipeline-dashboard](./pipeline-dashboard.md) — the in-flight probe.
- git 2.5 or later, for linked worktrees — any git this product already runs
  on.

## Open questions

- **Skills that pull or push inside a unit.** The agent is told the remote is
  the orchestrator's and skips those steps as under `--no-push`. Whether every
  committing skill a unit can invoke honours that from a sentence in its
  conversation, or whether one needs its `--no-push` flag typed — which the
  subagent contract forbids adding — is to be confirmed when the OPERATING
  RULES line is written.
- **Test runners that scan the whole tree.** A full suite run in the base
  tree would collect files under `.claude/worktrees/`. The barrier rules of
  both orchestrators keep base-tree work and worktrees from coexisting, so
  the case should not arise; whether an exclude line in the project's test
  configuration is still worth writing is for implementation to judge.
