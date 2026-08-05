# Delegated runs (one fresh subagent per task)

Read this when DELEGATE is true — i.e. a run whose resolved task list holds
2 or more tasks, and the user answered yes to PRE-FLIGHT's delegation
question (or passed `--agents`). A single-task run never reads this file.

The point is context, not concurrency: implementing several tasks in one
conversation leaves task 1's reading, diffs, and test output loaded while
task 3 works. Delegating each task to its own agent gives every task the
full window, and the parent keeps only the run-level bookkeeping.

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

## The agent prompt

The agent starts cold. Everything the parent already resolved must be in
its prompt, or the agent will re-ask questions the user has answered — or
worse, stall waiting for an answer nobody sees. Include:

- The absolute repo path, and an instruction to work in it.
- The task ID, and that it must implement exactly that one task by
  following the `/task-implement` skill's per-task workflow (Steps 1–7)
  for it — its own `[IN PROGRESS]` flip, its own implementation, its own
  `[DONE]` flip, its own single commit, and its own push.
- The resolved flags: NO_COMMIT, NO_PUSH, AUTO_CONFIRM.
- The resolved testing mode — full test mode with the concrete test
  command, or skip-tests mode — so the agent does not redo RESOLVING THE
  TEST RUNNER and does not re-ask the no-test-suite A/B question.
- The dirty-tree decision (DIRTY_FOLD / DIRTY_FOLD_UNTRACKED) already made
  in PRE-FLIGHT, and that a working tree dirtied by this run's own earlier
  tasks is expected — the agent must not re-run `./dirty-tree.md`'s prompt
  protocol.
- That it is running non-interactively: it cannot ask the user anything.
  If it hits something that genuinely needs a human decision, it must stop
  and report that, rather than guess or wait.
- That it must report back: the final status it wrote, the commit hash (or
  that nothing was committed under NO_COMMIT), and any surprise worth the
  user's attention.

## Between delegated tasks

After each agent returns, and before the next spawn:

1. Re-read `.claude/TASKS.md` with the Read tool. The agent wrote a status
   there and the parent's copy is stale.
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
