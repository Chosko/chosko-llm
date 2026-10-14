# Parallel runs

Read once, in step 1, when the parallelism resolves above one; a sequential
run never opens this file. It amends SKILL.md for the whole run — where a
section here speaks, it wins over the section it names.

Read `../../task-engine/references/worktree.md` beside it, once. The unit
there is `runbook-<id>-step-<n>`, the base is the branch this run was launched
on, checked out in this tree, and this session is its one writer. That file
owns the worktree, the agent's integration, the landing, the two invariants,
the in-flight signal and failure; this file states only the scheduling and
this skill's own departures.

The contracts of WHAT THIS SKILL READS AND WRITES hold, with one addition:
run the git of the worktree protocol — creating, landing and removing each
step's worktree. It changes no tracked file.

---

## Scheduling (steps 2–3)

- **A scheduling point** is the start of the run and each landing. Step 2's
  re-read happens there, and step 3 selects from it.
- **Select every** step in list order — whatever its id — whose marker is
  `[ ]`, `[~]` or `[!]` and whose every `Depends on:` step is `[x]`, while
  fewer than N steps are in flight; no bound under `max`. List order is
  priority among the steps selectable at the same moment.
- **In flight** means spawned by this run and not yet landed. A step in
  flight is neither done nor selectable, and a step depending on it waits
  for it to land: landing writes the `[x]` the next re-read sees.
- Every bullet of step 3 holds — the `Archive:` rule, `[!]` re-run with its
  failure kept, `[P]` passed over or asked — with two readings added:
  - a `[~]` step whose worktree exists and which this run did not spawn is
    skipped with the one line of `worktree.md` § *A worktree is a unit in
    flight*, once per step per run, and examined again at the next scheduling
    point;
  - a `[~]` step with no worktree behind it is the interrupted step step 3
    describes: report it and re-run it.
- Take the deadlock test, the end branch and the out-of-range stop **only when
  nothing is in flight**. A selection that picks nothing while something is in
  flight waits for the next return (step 6).
- `--from`, `--to` and `--only` apply unchanged against each re-read.
  `--steps N` counts landed steps: spawn nothing once the landed and in-flight
  steps together number N, so the N-th landing ends the run (step 8).

**A barrier.** A `Needs: agent+human` or `Needs: human` step is work with the
user present, in the base tree. When it is the next selectable step in list
order, spawn nothing more:

1. land every step in flight — steps 6–8 for each return in turn, with no
   scheduling point after any of them;
2. run the step in the base tree exactly as a sequential run does — marked,
   spawned without a worktree and without `WORKTREE RULES`, awaited, handled
   and committed;
3. resume spawning at the scheduling point after its commit.

## Mark and spawn (steps 4–5)

- Mark every step the scheduling point selected `[~]` before the first of
  them is spawned.
- Before each spawn, create the step's worktree per `worktree.md`
  § *Creating the worktree*, then spawn with `run_in_background: true`. Its
  preamble names the worktree's absolute path as the repository root, with
  the base branch's name beside it, and nothing about the other steps in
  flight. After OPERATING RULES, paste `WORKTREE RULES` from
  `./subagent-contract.md`, `<WORKTREE>` that path; a relay child the step
  requests gets the same block with the same path.
- A worktree that cannot be created skips its step with that section's one
  line, and the next selected step is spawned.
- Up to N steps are then in flight, each writing in its own tree, while the
  body file stays this session's alone.

## Wait and handle (steps 6–7)

- Wait for the **next** result, whichever step's it is, and handle that one
  while the others run on. A spawn's return value, a progress notification
  and another step's result are none of them this step's result.
- Handle returns **one at a time**, in arrival order.
- **`DONE`** — land the step per `worktree.md` § *The orchestrator lands*
  before anything in THE FOUR RESULT CASES § *On `DONE`*. The base tree's
  only uncommitted files then are the body and the index, which no step's
  agent touches, so the fast-forward meets nothing it would overwrite. Then
  do the bookkeeping exactly as on a sequential run.
- **`QUESTIONS FOR USER`** stops nothing but its own step. Land and bookkeep
  as usual a return that arrives while a question is open. Each relay block
  carries its step heading, each answer goes back by agent id, and after
  every relay print one line naming the steps still waiting on the user —
  `Waiting on you: steps 4 (round 1), 6 (round 2).` The one rebase-again
  message of a landing goes through the same channel.
- **The fifth row** (`unattended`) is unchanged, and the step's worktree goes
  with it: `git worktree remove` and the safe `git branch -d`, since OPERATING
  RULES had the agent leave the tree clean of its own changes before asking.
  A `[P]` step keeps no worktree and re-runs whole in a fresh one once
  answered.
- **A failure** halts spawning, not the steps already in flight:
  1. mark the failed step `[!]` with its `Done:` line and commit as usual;
  2. land each remaining return as it arrives — steps 6–8 for each, with no
     scheduling point after any of them — since abandoning them would strand
     committed work in worktrees; a second failure among them is marked `[!]`
     the same way;
  3. once nothing is in flight, set the index to `[FAILED]` with `Failed at:`
     naming the first failed step, commit, halt and report.

  The failed step keeps its worktree (`worktree.md` § *Failure*).

## Commit and loop (step 8)

- The re-read after a commit is the next scheduling point: step 3 selects
  every step that may now start, step 5 spawns them, step 6 waits.
- The three ends of step 8 are reached only when nothing is in flight.
- A landed step's commit **may capture `[~]`** for the steps still in flight
  — the alternative is one commit at the end of the run — and is still one
  commit per landed step, staging exactly the two files (COMMIT CADENCE).

## Resume (ONE RUN PER RUNBOOK)

A run whose parallelism was above one may have committed its `[~]`, so its
resume signal is the worktree:

> `[RUNNING]` in the index **plus** a `wt/runbook-<id>-step-<n>` worktree on
> this machine is the whole resume signal.

A committed `[~]` with neither signal behind it is a run in flight elsewhere,
and `[RUNNING]` blocks.

## Everything else

- **CHAT OUTPUT.** Print the progress line once per spawn, `k` and `x`
  counting the steps landed plus every step in flight, the one now starting
  included. At a step's end print `Step 4 landed (abc1234). In flight: 5, 6.
  Starting step 7.` — the steps the scheduling point starts named last — or
  `Nothing more to start.` when it starts none.
- **The Stop-hook reply.** Subagent WIP covers any of the spawns in flight.
- **THE SPAWN RELAY.** The agents at work are the steps' own, each idle while
  its own child runs. Never spawn a child while its caller is still working,
  and never two children for one caller at once.
- **THE CLOSING REPORT.** A failed step's line names its worktree path; one
  run-level line names each in-flight step that landed after the failure; a
  step left `[~]` names its worktree path when one exists, to finish by hand
  or remove.
