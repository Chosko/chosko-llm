# Delegated runs (one fresh subagent per task)

Read this when DELEGATE is true — i.e. a run whose resolved task list holds
2 or more tasks, and the user answered yes to PRE-FLIGHT's delegation
question (or passed `--agents`). A single-task run never reads this file.

The point is context, not concurrency: implementing several tasks in one
conversation leaves task 1's reading, diffs, and test output loaded while
task 3 works. Delegating each task to its own agent gives every task the
full window, and the parent keeps only the run-level bookkeeping.

That only works if the parent stays small too. On a delegated run the parent
is a **launcher**, not an orchestrator: it resolves the task list, evaluates
the delegation guard from the `TASKS.md` summary blocks it has already read,
hands every agent the same fixed-size prompt, and records four short values
per return. It never reads the task it is handing over. A parent that read
each body to compose an accurate hand-off would spend exactly the context
the delegation exists to save, and the agent is about to read that body
properly anyway, from a clean window, with the project's navigation layer in
front of it.

## Sequential, never parallel

Spawn ONE agent at a time and wait for it to finish before spawning the
next. Every task in the run shares one working tree, one branch, and one
`.claude/TASKS.md`; concurrent agents would race on status flips, on
staging paths, and on push. There is no parallel mode and none is offered
— if the user asks for one, explain the shared-tree constraint.

Use the Agent tool with `subagent_type: "general-purpose"` and
`run_in_background: false` (the parent must block on the result). Do not
spawn the next agent until the previous one's result is in hand.

## What stays in the parent

Not every task can be delegated. The parent implements these itself, in
the list's original order, exactly as an ordinary in-context run would:

- **`claude+human` and `human` tasks.** `./human-in-loop.md` requires the
  implementer to pause at each checkpoint, explain the manual step in a
  turn that ends with no tool call, and wait for the user's free-text
  confirmation. A subagent cannot hold that conversation with the user.
- **`[STALE]` tasks requested explicitly by number.** SKILL.md's STALE
  TASKS protocol asks the user to choose implement-anyway or stop; that
  question is the parent's, and a task the user chooses to implement then
  runs in-context.

So a delegated run is usually mixed. Before the first task starts, say so
plainly — name the IDs and why:

> Delegating tasks 20, 22 to fresh agents (one at a time). Tasks 21, 23
> run here in this conversation: 21 is `claude+human` and 23 is `[STALE]`,
> and both need you present.

Never delegate silently and never let the user discover the split from the
output.

## What the parent never reads

**On a delegated run the parent opens no `.claude/tasks/<N>.md` for a
delegated task, on any path, ever.** Not to compose the prompt, not to check
what the task touches, not to decide whether it may be delegated, and not
after the agent returns. The three fields the delegation guard needs —
`Target:`, `Status:` and `Feature:` — all live in the task's `TASKS.md`
summary block, which PRE-FLIGHT step 2 already read once for the whole run,
so the guard costs nothing per task and no body read can be justified by it.

The tasks the parent keeps are the exception that proves the shape: a
`claude+human`, `human` or explicitly requested `[STALE]` task is not
delegated, so the parent implements it itself and reads its body in Step 1,
exactly as an ordinary in-context run does. That path is unchanged. A task
handed to an agent never gets its body opened here.

## The agent prompt

The prompt is **fixed size** — the same frame every time, with a different
number in it. It does not describe the task, because the parent has not read
the task and will not. A fifty-task batch composes this prompt fifty times
and the parent's context does not grow with the batch.

It carries four things:

1. **The task number**, plus the repo's absolute path and the instruction to
   implement exactly that one task by following the `/task-implement`
   skill's per-task workflow (Steps 1–7) — its own `[IN PROGRESS]` flip, its
   own implementation, its own `[DONE]` flip, its own single commit, its own
   push.
2. **The run's resolved flags** — every run-level decision PRE-FLIGHT
   already made, so the agent does not re-resolve them, does not re-ask a
   question the user has answered, and does not stall waiting for an answer
   nobody sees. Pass *the run's resolved flags*, whatever they are; this is
   not a closed list, so any flag `/task-implement` gains later rides
   through without the prompt growing. Today they are:
   - NO_COMMIT, NO_PUSH, AUTO_CONFIRM;
   - REVIEW and ROUNDS — whether the run was invoked with `--review`, and
     the round cap. An implementor told REVIEW is true runs the loop from
     `./review-rounds.md` for its own task (see below);
   - the resolved testing mode — full test mode with the concrete test
     command, or skip-tests mode — so the agent does not redo RESOLVING THE
     TEST RUNNER and does not re-ask the no-test-suite A/B question;
   - the dirty-tree decision (DIRTY_FOLD / DIRTY_FOLD_UNTRACKED) already
     made in PRE-FLIGHT, plus the note that a tree dirtied by this run's own
     earlier tasks is expected, so the agent must not re-run
     `./dirty-tree.md`'s prompt protocol;
   - the notice that it runs non-interactively: it cannot ask the user
     anything, and if it hits something that genuinely needs a human
     decision it must stop and report that rather than guess or wait.

   Every one of these is a run-level value, resolved once — so the flag list
   is O(1) in the size of the batch, exactly like the rest of the prompt.
3. **The instruction to gather its own context**: read the task body,
   CLAUDE.md and `.claude/context/` itself, since it has been given none of
   them. This is not a hardship — the agent has the same project a user
   typing `/task-implement <n>` by hand would have, and `.claude/context/`
   is precisely the precomputed answer to "what do I need to read". Handing
   it a pre-chewed summary instead pays for that layer twice.
4. **The return contract**, below.

The whole thing reads roughly:

> Implement task `<n>` from the backlog in `<absolute repo path>` by
> following the `/task-implement` skill's per-task workflow (Steps 1–7) for
> that one task: flip it `[IN PROGRESS]`, implement it, flip it `[DONE]`,
> make its single commit and its single push.
>
> Resolved flags for this run: `<the run's resolved flag list>`.
>
> Read the task body, CLAUDE.md and `.claude/context/` yourself — you have
> not been given them. You are running non-interactively and cannot ask the
> user anything; if something genuinely needs a human decision, stop and
> report it.
>
> Report back only: the task number, the terminal status you wrote, the
> commit hash (or that nothing was committed), and — only if it failed — a
> one-line reason.

## Review rounds inside a delegated task

When REVIEW rides through in the flag list, **each implementor spawns its own
reviewer** for its own task: launcher → implementor → reviewer. That depth
was confirmed to work on 2026-08-24 — a general-purpose subagent has the
`Agent` tool and can spawn a child that runs and returns — so batch
`--review` needs no fallback and gets none.

Two properties of the single-task loop carry over unchanged, and the
implementor must honour both:

- the implementor's reviewer also **returns asynchronously** — the Agent call
  yields an id and the report arrives later as a separate notification;
- an implementor must therefore **not reach its own Step 7** until its
  reviewer's result has actually arrived. An implementor that commits on the
  strength of a spawn call's return value commits unreviewed work and reports
  it as reviewed.

The parent's side of this is deliberately empty. It passes the flags through
and **never sees a finding**: no report, no triage table, no rejection ledger
travels up. The four-field return contract below is unchanged by `--review` —
a task whose loop ended in unresolved `BLOCKING` findings comes back as a
failure with its one-line reason, like any other failure, and halts the run.

## What the agent returns, and what the parent keeps

The return contract is exactly four things:

1. the task number,
2. the terminal status it wrote to `.claude/TASKS.md`,
3. the commit hash — or, under NO_COMMIT, that nothing was committed,
4. a one-line failure reason, and only when it failed.

The parent accumulates that and nothing else. No diffs, no file lists, no
narrative, no "surprises worth mentioning" — an agent with something to say
says it in the failure line, and a task that needs the user's attention is a
task that stopped. After a fifty-task run the parent holds fifty short rows.

## Between delegated tasks

After each agent returns, and before the next spawn:

1. Re-read `.claude/TASKS.md` with the Read tool. The agent wrote a status
   there and the parent's copy is stale. If the returned task carries a
   `Feature:` line and landed `[DONE]`, apply SKILL.md's FEATURE COMPLETION
   check here — same check Step 6 runs for an in-context task, just
   triggered by this re-read instead. Still don't propose anything; that
   stays batched to the end of the whole run.
2. Confirm the agent actually did what it claims — the status it reports
   should match the file, and under the default (committing) mode
   `git status --porcelain` should be clean. A mismatch is a failure; see
   below.
3. Report one line of progress to the user: "Task 20 done (`abc1234`).
   Starting task 22."
4. In skip-tests mode, ask "Proceed?" before spawning the next agent,
   unless AUTO_CONFIRM is true. This prompt belongs to the parent — the
   agent never asks it.

## Failure

A delegated task that fails halts the run exactly as an in-context failure
does: do not spawn the next agent, do not fix up the failed task's status
behind the agent's back, and report

- which tasks completed (with their commit hashes),
- which task failed and what the agent said about it,
- which tasks were never started.

An agent that returns something ambiguous — no status, no commit, an
unclear report — counts as a failure. Verify rather than assume; the
parent never saw the work.
