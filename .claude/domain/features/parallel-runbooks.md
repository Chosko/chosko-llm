# Parallel runbooks

Runbook steps scheduled by their dependency graph instead of their list
position. A runbook authored for it declares a `Parallelism:` in its header,
or a run asks for one with `/runbook-run --parallel <N|max>`; under either,
`/runbook-run` keeps up to N steps in flight at once — every step whose
`Depends on:` is satisfied, under `max` — each in its own worktree per
[worktree-isolation](./worktree-isolation.md), and lands them as they return.
Without a header line and without the flag nothing changes: one step at a
time, in list order, as today.

## Purpose

A runbook already records the real constraint between its steps:
`Depends on:` exists "so a deadlock is detectable", and `/runbook-create`
asks the author which steps must precede which. What it does not do is act
on that record — steps run one after another whatever the graph says, for
the two reasons `/runbook-run` names: one question stream for the user, and
one body file two agents would race on. The second reason is the shared tree
and goes with `worktree-isolation`; the first is a readability cost the
director may choose to pay. This feature lets a runbook whose graph is honest
be run as a graph, so a night's work that is three independent chains takes
one chain's time.

It serves the director, who hands off a tree of work and gets it back as fast
as its longest branch, and Claude as the author who now has a reason to
record every edge rather than relying on position. It restates no part of
[runbook-suite](./runbook-suite.md); it names the contracts there that gain
a branch under parallelism and what that branch does.

## Scope and non-goals

In scope: the header line and the flag; what the graph means under
parallelism and what list order still means; the refusal that keeps a hidden
ordering constraint from being violated; the authoring duty `/runbook-create`
gains; each step in its worktree; which steps are barriers; the resume signal
and the commit cadence under concurrency; the ripple into the readers.

Deliberately out:

- **A per-step `parallel` marker.** `Depends on:` already records which steps
  must wait; a tag saying a step may run alongside others would be the same
  fact written a second time, and the second copy is the one that drifts.
  Under parallelism a step with no edge to another is independent of it by
  the runbook's own declaration.
- **Inferring edges.** No reading of prompts to guess what they touch. The
  graph is the author's, written at authoring time and amended through
  `/pipeline-revise`.
- **Parallelism under `--inline`.** The inline session is the one executor;
  `--inline` beside `--parallel` is an argument error.
- **Nested runbooks.** Still refused, unchanged.
- **Parallel runs of one runbook.** Still forbidden: ONE RUN PER RUNBOOK
  stands, with a new resume signal.
- **A scheduler for the step prompts' own work.** A step whose prompt is
  `/task-implement all --parallel 3` gets its parallelism from
  [parallel-task-runs](./parallel-task-runs.md), inside its own worktree;
  this feature schedules steps, not what steps do.

## Architecture

Built on the repo's existing shape per `technical-direction.md`. The change
lands in `skills/runbook-run/` — its arguments and subagent contract, and
the scheduling itself in `references/parallel.md`, read only when the
parallelism resolves above one (`.claude/context/runbook-run.md` and its two
continuation files) — in `commands/runbook-create.md`, whose parallel duty is
`references/parallel-authoring.md`, read only for a parallel runbook, and in
one line each of the readers. A sequential run loads neither file. It adds no CLI surface and no script.

### The header line and the flag

`Parallelism: <N|max>` joins the header beside `Execution policy:`, under the
same rules: optional, absent means 1, authored by `/runbook-create` only when
the user asks for a parallel runbook and never by default, never rewritten by
a run, and any value other than an integer of 2 or more or the word `max` is
an argument error at run time. `/runbook-run --parallel <N|max>` overrides it
for one run; `--parallel 1` forces a sequential run of a runbook whose header
says otherwise. The run's resolved parallelism is one more value in step 1's
resolution, beside the execution policy.

### The graph is the schedule

Under a parallelism above one, selection changes from *the first step in list
order whose dependencies are `[x]`* to *every step in list order whose
dependencies are `[x]`, while fewer than N are in flight*. Two things carry
over exactly: a dependency satisfied by the `Archive:` line stays satisfied,
and `[P]`, `[!]` and `[~]` steps keep the meanings selection gives them. One
thing is added, the same reading `parallel-task-runs` adds to its clause: **a
step in flight is neither done nor selectable**, and a step depending on it
waits for it to land — landing is what writes `[x]` to the body the next
re-read sees.

List order keeps one job: priority among steps selectable at the same moment,
so an author's "do this first" still holds where the graph allows both
orders. It stops being an ordering constraint, which is the whole change.

`--from`, `--to` and `--only` bound the range as they do today, re-applied
against each re-read. `--steps N` counts landed steps.

### The refusal that protects a hidden order

`Sequencing:` is the header line for a *why* that position and `Depends on:`
cannot show — "1–4 all edit the same file". That is precisely an ordering
constraint the graph does not carry, and a parallel run would violate it
silently. So the two are mutually exclusive: `/runbook-create` never writes
`Parallelism:` into a header that has a `Sequencing:` line, and `/runbook-run
--parallel` on a runbook whose header carries `Sequencing:` is an argument
error naming the line and the two ways out — carry the constraint into the
graph through `/pipeline-revise`, or run sequentially. A runbook authored for
parallelism has nothing `Sequencing:` could say, because every constraint it
has is an edge.

### Authoring for parallelism

When the user asks `/runbook-create` for a parallel runbook, the question
"which steps must precede which, and why" is asked exhaustively rather than
as a check on the list: for every pair the author might order, either an
edge is written or the two are declared independent, and the gate's step
table states that every step without an edge is independent of every step
not reachable from it. `--append` onto a runbook with a `Parallelism:` line
writes the new steps' edges under the same duty. The header line is written
exactly where `Execution policy:` is.

### Each step in its worktree

The orchestrator creates the step's worktree per `worktree-isolation` before
it spawns, and the spawned prompt's preamble names the directory as the
repository root. A `WORKTREE RULES` block, pasted after OPERATING RULES only
under a parallelism above one, carries a `<WORKTREE>` placeholder and the
rules: work only in that directory, and the remote is the orchestrator's,
so an invoked skill's pull and push of the base are skipped as under
`--no-push` and the work is committed as usual, with the one exception
`task-engine`'s `parking.md` states — a skill that parks pushes its own
`park/task-<N>`, the branch another machine needs to unpark; before `DONE`,
integrate as the protocol says.
The block is fixed text filled per step like the others, so the contract
stays a contract, and a sequential run never pastes it: its prompts, and its
skills' own pull and push, are those of a runbook with no `Parallelism:`.

On `DONE` the orchestrator lands the step — fast-forward, the one
rebase-again message to the same agent where needed, push, remove — and then
writes the marker and the `Done:` line and commits them, as today. The
`Done:` line's sha and diffstat come from the agent's report, unchanged. On a
`QUESTIONS FOR USER` result the relay runs as today; other steps in flight go
on landing meanwhile, and each relay block already carries its step heading.
On a `[P]` under `unattended`, the park is bookkeeping only, as today, and the
step's worktree is removed once its agent has left the tree clean of its own
changes — the rule the contract already states.

### Barriers

A `Needs: agent+human` or `Needs: human` step is work with the user present,
in the project the user is looking at — the base tree, not a worktree. It is
a **barrier**: when it is the next selectable step in list order, nothing
more is spawned, every step in flight lands, the step runs in the base tree
exactly as today, and spawning resumes after its commit. The base stays clean
at every landing, and the suite a human-involving step may run never sees a
worktree.

### The resume signal and the commit cadence

Today `[~]` is never committed, and that is what makes it the resume signal:
a `[~]` present locally beside `[RUNNING]` in the index means this tree is the
one that was interrupted. Under parallelism the body carries `[~]` for the
steps still in flight when a landed step's `[x]` is committed, so the one
commit per landed step would have to wait until nothing is in flight — the
end of the run, under `max` — or capture `[~]`. It captures it. **Under a
parallelism above one, `[~]` may be committed**, and the resume signal moves
to the thing that is still local and never pushed: **`[RUNNING]` in the index
plus a `wt/runbook-<id>-step-<n>` worktree on this machine** is the whole
resume signal, and a `[~]` found with no worktree behind it is a step an
interrupted run left behind, reported and re-run as today. Nothing else in
the cadence changes: one commit per landed step, exactly the body and the
index, pushed per the protocol; a step's own commits land before its
bookkeeping commit, so they still sit beside it.

### Ripple

Kept to a line each. `/runbook-describe` prints the `Parallelism:` line with
the header, marks every `[~]` step as in flight and, on a runbook carrying
`Parallelism:`, prints one line counting the steps with `Depends on: none`,
so the assertion that the graph is honest can be judged without opening a
prompt; `/runbook-list` is
unchanged, since the index gains no line; `/runbook-clean` sweeps the
worktrees of `[x]` steps and of the runbooks it archives; `/pipeline-check`
gains one probe — a header carrying both `Parallelism:` and `Sequencing:` —
and no worktree probe, since git across machines makes it noise; the routing
rows of `/runbook-run` and `/runbook-create` list the flag and the line.

## Data and state

- **`Parallelism: <N|max>`** in the runbook header — optional, authored,
  never rewritten by a run.
- **`[~]`** on a step heading — now committable under parallelism, same
  meaning.
- **`.claude/worktrees/runbook-<id>-step-<n>/`** and **`wt/runbook-<id>-step-<n>`**
  — per `worktree-isolation`, present while the step is in flight or failed.
- **In memory only:** the resolved parallelism, the set of steps in flight,
  and the base tip each was created from.

The index gains nothing: `Steps:` counts `[x]` as before, and a running
runbook is `[RUNNING]` as before.

## Interfaces and contracts

```
/runbook-run <runbook>                        header Parallelism: or 1
/runbook-run <runbook> --parallel 3           up to three steps in flight
/runbook-run <runbook> --parallel max         every selectable step at once
/runbook-run <runbook> --parallel 1           sequential, overriding the header
/runbook-run <runbook> --parallel 3 --inline  argument error
/runbook-run <runbook> --parallel 3           argument error while the header has Sequencing:
/runbook-create ... (asked for a parallel runbook)   writes Parallelism:, never beside Sequencing:
```

| Contract today | Under a parallelism above one |
|---|---|
| Select the first step whose dependencies are `[x]` | Select every such step, in list order, up to N |
| Steps sequential, always | Steps concurrent where the graph allows; list order is priority |
| One subagent at a time | Up to N; returns handled one at a time |
| Step agent works in the base tree | Step agent works in its worktree; the orchestrator lands |
| `[~]` never committed; `[RUNNING]` + local `[~]` resumes | `[~]` may be committed; `[RUNNING]` + local worktree resumes |
| Deadlock: steps remain, none selectable, none `[P]` | Same test, taken when nothing is in flight |
| `Needs:` steps run in list order | Same, as barriers |

Failure contract: a `[!]` step halts spawning as today; steps in flight land
first, then the index is `[FAILED]` with `Failed at:` naming the failed step,
and the report names each in-flight step that landed after the failure. A
header value outside the allowed set, `--parallel` beside `--inline`, or
`--parallel` on a `Sequencing:` runbook are argument errors, numbered after
the ninth.

## Dependencies

- [worktree-isolation](./worktree-isolation.md) — the tree per step, the
  agent's integration, the landing, the resume property of a local worktree,
  the sweep; and `requires: skill:task-engine` on `/runbook-run`, which that
  feature adds.
- [runbook-suite](./runbook-suite.md) — the schema, the markers, selection,
  the subagent contract, the relay and the cadence this extends.
- [runbook-inline](./runbook-inline.md) — the mode this refuses to combine
  with.
- [unattended-parking](./unattended-parking.md) — `[P]` under concurrency,
  bookkeeping only, unchanged.
- [parallel-task-runs](./parallel-task-runs.md) — not required; the
  composition a step's prompt may ask for.
- [pipeline-engine](./pipeline-engine.md) — one probe and two routing rows,
  guarded by `check-routing.sh`.

## Open questions

- **The depth budget.** A step whose prompt is `/task-implement --parallel`
  nests orchestrator → step agent → task agents → reviewers, one level past
  the verified bound. The spawn relay is the answer where an agent cannot
  spawn; whether a relayed child can itself run tasks in parallel, or that
  step runs its tasks sequentially, is to be probed, not assumed.
- **Runbooks authored before this feature.** Their graphs were written with
  position doing part of the work. The `Sequencing:` refusal catches the
  authors who wrote the *why* down; for the rest, `--parallel` is the user's
  assertion that the graph is honest, judged on `/runbook-describe`'s count
  of edge-less steps.
