# Worktree isolation

Authority for: the unit of work and the two names derived from it, how the
orchestrator creates a unit's worktree, how the unit's agent integrates its
work onto the base branch, how the orchestrator lands it, the two invariants
that make landings safe, a worktree as the in-flight signal, eligibility
while a unit is in flight, what a failure leaves behind, and parking inside a
worktree.

Authored in the engine — no feature ever carried a copy of it. Read only
through `/task-implement`'s `parallel-runs.md` and `/runbook-run`'s
`references/parallel.md`, when a run's parallelism is above one; a
sequential run never opens this file and works in the base tree. The one
always-read mention is the rebase exception in `./commit.md`, citing here.
The sweep of finished units' worktrees is `./worktree-sweep.md`.

A **base** is the branch the run was launched on, checked out in the
orchestrator's own tree. A **unit** is one task or one runbook step. The
protocol takes one unit and one base and knows nothing about the other units
in flight: which units run together, how many and in what order is each
orchestrator's own scheduling.

---

## The unit, its worktree and its branch

The orchestrator names the unit: `task-<N>` for a task, `runbook-<id>-step-<n>`
for a runbook step. From that name two names are derived, and nothing else:

- the worktree directory `.claude/worktrees/<unit>`, under the project root;
- the branch `wt/<unit>`.

Both are derived, never recorded — the same rule as `park/task-<N>`. Git's
own worktree list is the registry; no file of this product duplicates it.

## Creating the worktree

Immediately before spawning the unit's agent, create the worktree from the
current tip of the base, on a fresh `wt/<unit>` branch:

```
git worktree add -b wt/<unit> .claude/worktrees/<unit> <base>
```

Before the first worktree of a run is created, add the line
`.claude/worktrees/` to `.git/info/exclude` unless it is already there —
idempotent, and git's own machine-local configuration rather than a state of
this product. The directory sits under `.claude/` because per-project working
state already lives there, a path inside the project needs no permission the
agent lacks, and the worktree's `.git` file keeps git from recursing into it.

When the worktree cannot be created — the path exists, or the branch
exists — skip the unit with one line naming the path (§ *A worktree is a
unit in flight*).

Hand the agent the directory as the repository root for everything it does,
and one rule beside it: the base's push is not the agent's. That is all the
prompt gains — one path per unit, like the unit's number. Hand on unchanged
the values already resolved — NO_PUSH, the testing mode, UNATTENDED — and
the dirty-tree decision as *clean*: the agent never runs the prompt of
`./tree.md` in a fresh worktree.

## The agent integrates

Execute the unit's work in the worktree exactly as in the base tree — a
task's per-task workflow, a step's prompt under its operating rules — with
one change, at the point where the unit would push:

1. **Commit on `wt/<unit>`**, as many commits as the unit's own rules make:
   one for a task, whatever the step's prompt makes for a step.
2. **Rebase `wt/<unit>` onto the current tip of the base.** The base is
   local; nothing is fetched, since the orchestrator keeps it current.
3. **A conflict is resolved by re-applying the unit's own intent on top of
   what landed** — a version counter bumped again from the new value, an
   entry added again at the top of a newest-first log, a status flip re-made
   on a block another unit's flip now sits beside — never by keeping one
   side whole. The agent that did the work is the one that knows its intent,
   which is why integration is the agent's and not the orchestrator's. A
   rebase the agent cannot complete is the unit's failure (§ *Failure*).
4. **When the rebase changed anything** — the base had moved — **re-verify**:
   the affected and full test runs in full test mode, the step's own
   verification for a step. A unit that passed on the old base has not passed
   on the new one.
5. **Return, naming the base tip it rebased onto.**

The agent never pushes the base branch, never touches it and never leaves
the worktree. The one branch it pushes is its own `park/task-<N>`, under
`./parking.md` § *The park sequence*, unless NO_PUSH: that branch is private
to the task, touches no base branch and races with no other unit, and its
push is what lets another machine unpark. A skill the unit invokes commits
as usual; its pull-at-start, pre-push re-sync and push of the base
are the orchestrator's, so the agent skips them exactly as a run under
`--no-push` does — the park branch's push excepted — and says so once.

Rebasing `wt/<unit>` rewrites nobody's history: the branch is private to the
unit, unpushed, and exists for this one landing. `./commit.md` records it as
this protocol's departure from its no-rebase rule.

## The orchestrator lands

On the agent's return, under the second invariant below, land the unit in this
order:

1. **Fast-forward only.** Merge `wt/<unit>` into the base with
   `git merge --ff-only wt/<unit>`, no other strategy. It succeeds exactly
   when the base tip is still the one the agent rebased onto.
2. **When it is not** — another unit landed while this agent was finishing —
   send the **same agent** one message: the base is at this tip, rebase again
   and return. The agent repeats steps 2–5 of § *The agent integrates*; the
   orchestrator fast-forwards again. At most one round per landing, because
   returns are handled one at a time and nothing but the orchestrator moves
   the base; a fast-forward refused twice is a failure (§ *Failure*).
3. **Push** the base per `./commit.md` § *The push protocol* — the pre-push
   re-sync and the push — unless NO_PUSH. A push failure after a landing is
   that protocol's: the commit exists locally and needs a manual sync, and
   the run stops.
4. **Remove** the worktree and delete the branch with the safe delete:
   `git worktree remove .claude/worktrees/<unit>` then
   `git branch -d wt/<unit>`. The safe delete refuses a branch not reachable
   from the base, so a refusal here is a landing that did not happen: it
   fails the unit, worktree kept. It is the protocol's own consistency check.

Then do the orchestrator's own bookkeeping for the unit, exactly as in a
sequential run (§ *Per-consumer notes*).

## The two invariants

Two invariants are the whole safety argument:

- **The base has one writer** — the orchestrator — so landings cannot race.
- **At every landing the base tree holds no change to a file the unit
  touched**, so a fast-forward never meets a local change it would
  overwrite. The orchestrator's own uncommitted bookkeeping in files no unit
  touches — a runbook body and its index — may stay; bookkeeping in a file
  the unit touched is committed first, then the unit lands.

## A worktree is a unit in flight

A `wt/<unit>` worktree exists exactly while its unit is in flight, or after
its unit failed. Nothing else records that, and git's worktree list — read
with `git worktree list --porcelain` — is what every reader consults: the
orchestrators, the status line, the dashboard and the pruners.

A run never starts a unit whose worktree already exists, under every
selector: it reports the path in one line — "Skipping task 42 — a worktree
exists at `.claude/worktrees/task-42`." — and goes on. The two ways out are
finishing the work in that worktree by hand or removing it.

A task's `[IN PROGRESS]` flip is made in the worktree's copy of `TASKS.md`,
and the base copy never shows it. Worktrees are local to the machine and never
pushed, so a worktree present on this machine means *this* tree is the one
that was interrupted.

## Eligibility while a unit is in flight

A unit in flight is neither done nor eligible: it is not selected again, and
a unit whose `Preconditions:` (or `Depends on:`) name it stays blocked until
it **lands**, not merely until it is spawned, because landing is what writes
the status the next read sees. Nothing else in `./resolution.md`
§ *Eligibility* changes, and nothing is stored in an index: the in-flight set
is the orchestrator's own — the units this run spawned and not yet landed,
held in run memory — and eligibility is still derived on every read. Git's
worktree list is what the skip-while-present rule above reads, never what
counts toward the set.

## Failure

A unit that fails — its own failure, a rebase it could not complete, a
fast-forward refused twice, a safe delete refused — keeps its worktree, with
the unit's uncommitted or unlanded work inside it and, for a task, its
`[IN PROGRESS]` flip. The run reports the worktree's path. Nothing on the base
records the failure: the worktree's presence is the record, and the
skip-while-present rule above is what keeps the next run from implementing
over it.

## Parking inside a worktree

The park and unpark sequences of `./parking.md` run in the worktree unchanged,
with `wt/<unit>` as the base of the bookkeeping commit:

- steps 1 and 2 make the `park/task-<N>` branch from the worktree's head; the
  agent pushes it unless NO_PUSH — the exception § *The agent integrates*
  names — and § *The unpark transaction*, step 4, deletes it local and remote
  the same way;
- step 3 checks `wt/<unit>` back out and step 4 commits the bookkeeping on
  it; that commit lands like any other and is pushed from the base by the
  orchestrator, and the worktree is removed with that landing;
- the unpark cherry-picks onto the head of whatever tree the task is then
  running in.

---

## Per-consumer notes

- **`/task-implement`** — the unit is `task-<N>`; the agent runs the per-task
  workflow Steps 1–7 in the worktree, the `[IN PROGRESS]` flip of Step 1 in
  the worktree's copy of `TASKS.md`, the `--review` loop inside the worktree
  before the task's one commit, and that commit on `wt/task-<N>`. Re-verify
  is the affected and full test runs in full test mode. Its bookkeeping after
  a landing is the between-tasks re-read of `TASKS.md`; a failed task's
  closing-report row names the worktree path.
- **`/runbook-run`** — the unit is `runbook-<id>-step-<n>`; the step's agent
  works in the worktree under its operating rules, commits whatever the
  step's prompt makes on `wt/<unit>`, and re-verifies with the step's own
  verification. The `[~]` marker stays in the base body, since only the
  orchestrator writes that file; its bookkeeping after a landing is the
  marker, the `Done:` line and their commit. A step parked under `unattended`
  is bookkeeping in the base body only, its agent having left the worktree
  clean of its own changes.
