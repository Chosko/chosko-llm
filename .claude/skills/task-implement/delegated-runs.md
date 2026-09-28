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
hands every agent the same fixed-size prompt, and records six short values
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

Not every task can be delegated. Which ones may never be, why, and the
announcement that names the split before the first task starts are the
delegation guard in
`../task-engine/references/targets.md`
§ *The delegation guard*.

The parent implements those tasks itself, in the list's original order,
exactly as an ordinary in-context run would — `./human-in-loop.md` for a
`claude+human` / `human` one, SKILL.md's STALE TASKS protocol for an
explicitly requested `[STALE]` one.

## What the parent never reads

**On a delegated run the parent opens no `.claude/tasks/<N>.md` for a
delegated task, on any path, ever.** Not to compose the prompt, not to check
what the task touches, not to decide whether it may be delegated, and not
after the agent returns. The three fields the delegation guard needs —
`Target:`, `Status:` and `Feature:` — all live in the task's `TASKS.md`
summary block, which PRE-FLIGHT step 2 already read once for the whole run,
so the guard costs nothing per task and no body read can be justified by it.
One read is bounded and named: under UNATTENDED the pre-ask (SKILL.md
PRE-FLIGHT) opens each `[PARKED]` task's trailing `## Parking handoff` — that
section only, before DELEGATE is decided — because the question it must list
verbatim lives nowhere else. Nothing else in a delegated task's body is ever
opened here.

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
   - REVIEW_MODEL and REVIEW_EFFORT — the `--review-model` and
     `--review-effort` values as the run resolved them, `auto` by default.
     They ride through as **two strings**: the parent resolves nothing and
     measures nothing, because `auto` resolves per task from each task's own
     diff, inside that implementor's own loop. A fifty-task batch therefore
     costs the parent two strings, not fifty measurements — the same O(1)
     property the rest of this prompt has;
   - the resolved testing mode — full test mode with the concrete test
     command, or skip-tests mode — so the agent does not redo RESOLVING THE
     TEST RUNNER and does not re-ask the no-test-suite A/B question;
   - the dirty-tree decision (DIRTY_FOLD / DIRTY_FOLD_UNTRACKED) already
     made in PRE-FLIGHT, plus the note that a tree dirtied by this run's own
     earlier tasks is expected, so the agent must not re-run the prompt
     protocol in
     `../task-engine/references/tree.md`;
   - UNATTENDED — the run's execution policy as ARGUMENT PARSING resolved
     it. When it is true the prompt says so in the one sentence that
     declares the run unattended, which is what makes the agent's own
     UNATTENDED true; when false the prompt says the run is attended.
     Whether the agent can ask is settled by this value alone, not by the
     fact that it is a subagent: a subagent can ask, because the launcher
     can carry an answer. Under attended, a question that genuinely needs
     the user — an acceptance criterion the body and the codebase cannot
     settle, a review round's approval gate — ends the agent's turn under a
     `QUESTIONS FOR USER` heading in the fixed relay block below, options
     and a recommendation included, and the answer comes back in the same
     conversation (§ *The question relay*); the agent never guesses, never
     waits on nothing, and never stops for a question. Under UNATTENDED the
     agent parks the task instead, per
     `../task-engine/references/parking.md`, and returns `[PARKED]` as its
     terminal status;
   - the held answer for this task — only when the task is `[PARKED]` and
     the parent holds one from the pre-ask or from chat (§ *Between
     delegated tasks* step 2a): one answer, for the one task the prompt
     names, which the agent's Step 1 feeds to the unpark. Under attended
     no answer is held; the agent asks the handoff's question through the
     relay.

   Every one of these is a run-level value, resolved once — the held answer
   is the one per-task value, and it is one line — so the flag list is O(1)
   in the size of the batch, exactly like the rest of the prompt.
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
> not been given them. This run is attended: if something genuinely needs
> the user's decision, end your turn under a `QUESTIONS FOR USER` heading —
> the question, its options with what each costs, your recommendation, and
> any draft awaiting approval verbatim — and the answer will come back in
> this conversation; never guess and never answer it yourself. *(Under
> UNATTENDED, instead: This run is unattended: a question about the work
> parks the task per `task-engine`'s `parking.md` and you return `[PARKED]`
> as its terminal status.)* Do not propose flipping a feature to `[DONE]`
> in FEATURES.md — the launcher proposes at the end of the run.
>
> When the task is finished, read the `/follow-ups` command's own body — it
> states what counts as a follow-up, what is excluded, and how an item is
> written — and apply its rules to this session, keeping at most three items.
> Do not invoke the command. If it is not available to you, skip this and
> report nothing for it.
>
> Report back only: the task number, the terminal status you wrote (for
> `[PARKED]`, followed by the handoff's `Question:` verbatim), the commit
> hash (or that nothing was committed), — only if it failed — a one-line
> reason, that list, omitted entirely when it is empty, and at most
> three *For the record* lines — `<what deviated> — <why> — <resolved by
> whom>`: a criterion overshot, a wrong premise in the body, a consequential
> edit outside `Files:` — omitted entirely when there are none.

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

The cost-control flags need no structural change here. REVIEW_MODEL and
REVIEW_EFFORT are run-level strings in the flag list above, and each
implementor resolves `auto` against its own task's diff — so the launcher
neither sizes a diff nor picks a model, and it still opens no task body to do
either.

The parent's side of this is deliberately empty. It passes the flags through
and **never sees a finding**: no report, no triage table, no rejection ledger
travels up. The return contract below is unchanged by `--review` in its first
four fields — a task whose loop ended in unresolved `BLOCKING` findings comes
back as a failure with its one-line reason, like any other failure, and halts
the run. The fifth field does not reopen that door, and needs no rule here to
stop it: `/follow-ups`' own exclusion rule already does, since a finding is not
an unrecorded piece of work. The one thing from a loop that its reading does
catch is a deferral `/task-iterate` noted should become a task, where none was
authored — an unwritten task, not a finding.

## The question relay

**The launcher relays; it does not answer.** An agent's result that opens
with `QUESTIONS FOR USER` is not a return — the task is still in progress
inside that agent, whose context is intact — and the parent handles it
before anything else:

1. Render the question in the fixed relay block — `/runbook-run`'s shape
   with a task heading, so the user reads one form of question from every
   run-level skill:

   ```
   Task 42 — Add the login form — the agent is asking (round 1):

     <the question in one or two lines>

     a) <option> — <what it costs>
     b) <option> — <what it costs>

   Recommendation: (b), because <one line>.
   ```

   At an approval gate the draft follows the block **verbatim and
   unabridged** — a summarized draft cannot be approved, and an approval
   given against a summary approves something the user never saw. The
   round number counts this task's questions, from 1.
2. Wait for the user's answer. Silence, EOF or an unrelated reply is not an
   answer; the run waits.
3. Send the answer to the **same** agent, by its id — never to a fresh one,
   which would have to be re-briefed and would answer differently — and
   block on its result as for any spawn. That result is either another
   question, which repeats this loop with the next round number, or the
   six-field return below.

The parent adds no fact it does not hold and never answers on the user's
behalf, not even a question it finds easy: it never opened the task and is
in no position to. The one thing it may add is a fact already in its own
row set — an earlier task's outcome that answers the question — and it says
that it is doing so, so the user can see which part of the block came from
the agent and which from the launcher.

Under UNATTENDED this case does not occur: the agent parks instead
(§ *The agent prompt*) and its result is a return with `[PARKED]` as the
terminal status. A `QUESTIONS FOR USER` result under UNATTENDED is an agent
that did not follow its prompt, and counts as an ambiguous return
(§ *Failure*).

## What the agent returns, and what the parent keeps

The return contract is exactly six things, the last two optional:

1. the task number,
2. the terminal status it wrote to `.claude/TASKS.md` — `[DONE]`,
   `[PARTIAL]`, or under UNATTENDED `[PARKED]`, followed in that one case
   by the handoff's `Question:` verbatim, options included: the agent's
   own chat print of it (`parking.md` § *The park sequence*) reaches no
   user from a subagent, so the return is how the question gets to the
   parent's handle print and to the closing report,
3. the commit hash — or, under NO_COMMIT, that nothing was committed; for a
   `[PARKED]` task, the bookkeeping commit's hash,
4. a one-line failure reason, and only when it failed,
5. **at most three one-line follow-ups**, and only when there are any,
6. **at most three *For the record* lines**, in the shape SKILL.md's THE
   CLOSING REPORT gives that group, and only when there are any.

The parent accumulates that and nothing else. No diffs, no file lists, no
narrative — a deviation worth keeping is one bounded line in the sixth
field, an agent with more to say says it in the failure line, and a task
that needs the user's attention is a relayed question (attended) or a
`[PARKED]` return (UNATTENDED), never a stop. After a fifty-task run the
parent holds fifty short rows, and its closing report's *For the record*
group is those sixth fields, attributed to their tasks.

**A `[PARKED]` return is not a failure and does not halt the run.** The
agent ran the park sequence itself, so the base tree is clean and its
question is in the task's `## Parking handoff`; the parent records the row,
prints the returned question under the run's next `P<n>` handle exactly as
SKILL.md's *Parking at a question* does for an in-context task, prints its
progress line (§ *Between delegated tasks*), and spawns the next agent. The
closing report lists the task under *Follow-ups* with that question, per
SKILL.md's THE CLOSING REPORT — the parent still opens no body for it.

**The fifth field applies `/follow-ups`' rules; it does not define its own.**
The agent reads that command's own body and applies what it finds there to its
own session — which, for a delegated agent, is exactly the one task.

**The agent is told the command's name, never a path to it.** `--local`
installs a feature into `$PWD/.claude` instead of the global home, so a body
that named the command by an absolute home path would silently miss every
`--local` install and report no follow-ups on a project that has the command.
A path relative to this body would resolve in both scopes, but the agent is
handed a prompt rather than this file, so it has no anchor to resolve one
against. The name is what resolves wherever the command actually lives. What counts as a follow-up, what is excluded because it
is already tracked on disk, and how an item is written are all that command's,
and are **not restated here**: a second copy is a copy that will drift, and
this file is not its authority.

**It reads the rules rather than invoking the command**, for two reasons.
Invoking it would be a per-task `/follow-ups` call — the rules are applied
once per run, in the parent's closing report (SKILL.md's CLOSING THE RUN).
And a read degrades where an invocation would not: `requires:
command:follow-ups` means the command is normally installed, but a user who
removed it by hand leaves the agent nothing to read, and the rule there is
the same silent skip the closing report makes — omit the field, report
nothing about it, and do not fail the task. An absent optional field is not a
failed task.

That is also why the field is empty on almost every task: the command's
exclusion rule does the work, and an agent that did its task and wrote it down
has nothing that qualifies.

Two bounds belong to this channel rather than to the command, and only these
two. **At most three items** — the command imposes no cap, and this one exists
to protect the parent's context, not to redefine a follow-up; an agent with
more than three unrecorded things did not finish its task. **Omitted entirely
when the list is empty**, so the common case costs nothing and a fifty-task run
still holds fifty short rows.

The parent does not act on them, does not judge them and does not ask about
them mid-run. It records them beside the other four fields and they feed
exactly one place: the *Follow-ups* group of the closing report, SKILL.md's
THE CLOSING REPORT, attributed to their task and de-duplicated by action
against the run's own items there. A follow-up line is the agent's claim, not
the parent's finding — the parent never opened the task and is in no position
to verify it, which is also why it is never a reason to halt the run.

## Between delegated tasks

After each agent returns, and before the next spawn:

1. Re-read `.claude/TASKS.md` with the Read tool. The agent wrote a status
   there and the parent's copy is stale. If the returned task carries a
   `Feature:` line and landed `[DONE]`, apply SKILL.md's FEATURE COMPLETION
   check here — same check Step 6 runs for an in-context task, just
   triggered by this re-read instead. Still don't propose anything; that
   stays batched to the end of the whole run. On a run resolved by `all`,
   this same re-read is where SKILL.md's BETWEEN TASKS step 2 re-checks the
   next task's `Preconditions:`: if they no longer hold, skip that task with
   its one-line report and spawn no agent for it, then apply the check to
   the task after it. `Preconditions:` is on the summary block, so the
   re-check opens no body and adds no read. Likewise, under UNATTENDED a
   next task that is `[PARKED]` with no held answer is skipped here with
   `parking.md` § *The answerer rule*'s one line and gets no agent —
   `Status:` is on the summary block and the answers are in run memory, so
   this too opens no body.
2. Confirm the agent actually did what it claims — the status it reports
   should match the file, and under the default (committing) mode
   `git status --porcelain` should be clean. A `[PARKED]` status with a
   clean tree is consistent: the park sequence ends in a bookkeeping
   commit, and the work-in-progress is on `park/task-<N>`, not in the
   tree. A mismatch is a failure; see below.
2a. Read any chat message that arrived while the agent ran, exactly as
   SKILL.md's BETWEEN TASKS step 2a says for an in-context run: a reply by
   `P<n>` handle to a question printed this run — at the pre-ask or at a
   park — is that task's answer, recorded in run memory, and the task moves
   to the front of the remaining list, so its agent is spawned next, the
   answer in its prompt (§ *The agent prompt*), and unparks it in its own
   Step 1. A reply the parent cannot match is rejected with one line, as
   there.
3. Report one line of progress to the user: "Task 20 done (`abc1234`).
   Starting task 22." — or, for a `[PARKED]` return, "Task 20 parked
   (question 3). Starting task 22."
4. In skip-tests mode, ask "Proceed?" before spawning the next agent,
   unless AUTO_CONFIRM is true or UNATTENDED is true. This prompt belongs
   to the parent — the agent never asks it.

## Failure

A delegated task that fails halts the run exactly as an in-context failure
does: do not spawn the next agent, do not fix up the failed task's status
behind the agent's back, and report

- which tasks completed (with their commit hashes),
- which task failed and what the agent said about it,
- which tasks were never started.

An agent that returns something ambiguous — no status, no commit, an
unclear report — counts as a failure. Verify rather than assume; the
parent never saw the work. A `QUESTIONS FOR USER` result is neither a
failure nor a return (§ *The question relay*), and a `[PARKED]` return is
not a failure (§ *What the agent returns*): only a task that stopped
`[IN PROGRESS]` halts the run.
