# Delegated runs (one fresh subagent per task)

Read this when DELEGATE is true — a run whose resolved task list holds 2 or
more tasks and the user answered yes to PRE-FLIGHT's delegation question
(or passed `--agents`, or `--parallel`, which implies it), or any run
while orchestrate mode is on and
`--no-agents` was not passed (PRE-FLIGHT step 2b). A single-task run with
the mode off never reads this file.

- Delegation is for context: each task gets its own agent and the full
  window, and the parent keeps only the run-level bookkeeping. Concurrency
  is a second step on the same shape — `--parallel`, § *The scheduler* — and
  changes nothing about what an agent is handed or what it returns.
- The parent is a **launcher**, not an orchestrator: it resolves the task
  list, evaluates the delegation guard from the `TASKS.md` summary blocks it
  has already read, hands every agent the same fixed-size prompt, and
  records six short values per return.
- It never reads the task it is handing over: the agent reads that body
  itself, from a clean window, with the project's navigation layer in front
  of it.

## The scheduler

- Spawn agents with the Agent tool, `subagent_type: "general-purpose"`.
  Handle returns **one at a time**, each followed by the launcher's
  bookkeeping on the base tree (§ *Between delegated tasks*); how many
  agents may be in flight at once is PARALLEL's alone.
- **Without PARALLEL — the default — one agent at a time.** Spawn with
  `run_in_background: false`, block on the result, and do not spawn the
  next agent until the previous one's result is in hand. Every task of such
  a run shares one working tree, one branch and one `.claude/TASKS.md`, so
  two agents would race on status flips, on staging paths and on push;
  several at once is what `--parallel` is for, and the flag is the answer
  to a user who asks for it.
- **Under PARALLEL — up to N in flight, each in its own worktree.** Read
  `../task-engine/references/worktree.md` before the first spawn: the
  worktree, the agent's integration and the landing are that file's, and
  this section states only the launcher's scheduling and its own
  deviations.
  - The task list is still resolved once, up front (`resolution.md`
    § *Selectors*), and the resolution report and the delegation count are
    printed from it.
  - What changes is the list's role: it is not a queue walked in order but
    the **admissible set** — the tasks this run may start — and its order
    is the **priority** among the tasks eligible at the same moment.

The **in-flight set** is the tasks this run spawned whose return it has
not yet landed, held in run memory and nowhere else: a task enters it at
its spawn and leaves it at its landing, and the launcher reads nothing off
git to know it, because the one thing git cannot tell it is which worktrees
are this run's own. Every "in flight" in this file — the count against N,
the in-flight clause of eligibility, the overlap rule's "any task in
flight", a barrier's wait, the end-of-run test — means membership in that
set. The worktree list (`git worktree list --porcelain`) is what the
skip-while-present rule and the other readers of `worktree.md` § *A
worktree is a unit in flight* consult, never what counts: a worktree an
earlier run left behind skips its task with that rule's one line, once per
task per run, and counts toward nothing.

At every **scheduling point** — the start of the run, and each landing —
the launcher:

1. re-reads the base `.claude/TASKS.md` with the Read tool and re-derives
   eligibility for every task in the list with `resolution.md`
   § *Eligibility* exactly as written, its in-flight clause included: a
   task in flight is neither done nor eligible, so a task whose
   `Preconditions:` name one waits for it to **land**, since landing is
   what writes the status this read sees;
2. walks the list in order and, while fewer than N tasks are in flight — no
   bound under `max` — starts each task it may: it creates the worktree per
   `worktree.md` § *Creating the worktree*, the `.git/info/exclude` line
   first, once per run, and spawns the agent with `run_in_background:
   true`, the prompt of § *The agent prompt* carrying PARALLEL and the
   worktree path. On this read it skips a task that is not eligible, a task
   already in flight, a task the overlap rule holds back (below), and a
   task not in flight whose worktree already exists — the skip-while-present
   line of `worktree.md`, printed once per task per run. A skipped task is
   not dropped: it is examined again at the next scheduling point;
3. stops the walk at a barrier (below), and otherwise walks the whole list;
   then waits for the next return.

- An explicit-list task is still never blocked by a precondition that is
  not in flight (`resolution.md` § *Selectors*); one whose precondition is
  in flight waits for it to land, because naming a task chooses that it
  runs, not that it runs before what it depends on.
- The run ends when nothing is in flight and nothing in the list can start:
  a scheduling point that starts nothing with no return left to wait for.
  The end-of-run steps — the feature-completion proposal, the closing
  report — follow as on any run.

### The overlap rule

- Two tasks whose `Files:` lines intersect are never in flight at the same
  time. At each scheduling point, a task whose `Files:` paths intersect
  those of any task in flight is **held back**, whatever N says, with one
  line naming the task it waits on — `Task 24 waits on task 22 (both list
  skills/foo/SKILL.md).` — printed once per task it waits on, not at every
  scheduling point. Re-examine it at the next scheduling point; it may
  start once the task it waited on has landed.
- `Files:` is on the summary block PRE-FLIGHT step 2 already read, so the
  rule costs no read and opens no body. An empty or missing `Files:` holds
  nothing back and is never held back.
- The rule is a safety net under `Preconditions:`, not a second dependency
  graph: two tasks with no edge between them are independent by the
  backlog's own declaration, and the rule only keeps the common cause of a
  rebase conflict — two agents editing one file — from being paid for at
  the landing, where it would cost the integrating agent a resolution.
- Before the intersection is taken, remove from every `Files:` line every
  path the project's `CLAUDE.md` names on its `Parallel-safe files for
  /task-implement:` line (PARALLEL_SAFE, read once at PRE-FLIGHT step 3):
  those are the files whose conflicts the agent's rebase resolves
  mechanically — a version counter, a newest-first changelog — and whose
  presence on every task would otherwise serialise the whole run. No
  marker means no exemption.

### Barriers

- A task the delegation guard keeps in the parent (§ *What stays in the
  parent*) runs in the base tree, in this conversation, and dirties the
  base while it runs; the base must be clean at every landing
  (`worktree.md` § *The two invariants*). Such a task is a **barrier**.
- When the walk reaches a parent-kept task not yet run this run, start
  nothing more, wait for every task in flight to land — handling each
  return as it arrives, questions relayed as usual — and then run the
  parent-kept task exactly as an in-context run does, in the base tree,
  including BETWEEN TASKS step 2's one-line skip when its preconditions do
  not hold on that read. Its commit, park or skip is the next scheduling
  point, and spawning resumes.
- A parent-kept task therefore runs in its list position, never deferred
  to the end, and one that is a precondition of delegated tasks unblocks
  them when it lands `[DONE]`, as it does on a sequential run.

## What stays in the parent

- Which tasks may never be delegated, why, and the announcement that names
  the split before the first task starts are the delegation guard in
  `../task-engine/references/targets.md` § *The delegation guard*.
- Implement those tasks in the parent, in the list's original order,
  exactly as an ordinary in-context run would — `./human-in-loop.md` for a
  `claude+human` / `human` one, SKILL.md's STALE TASKS protocol for an
  explicitly requested `[STALE]` one. The parent reads such a task's body
  in Step 1, as usual.
- Under PARALLEL each is a barrier (§ *The scheduler*): nothing is in flight
  while it runs, and it is never spawned into a worktree.

## What the parent never reads

- **On a delegated run the parent opens no `.claude/tasks/<N>.md` for a
  delegated task, on any path, ever** — not to compose the prompt, not to
  check what the task touches, not to decide whether it may be delegated,
  and not after the agent returns.
- The three fields the delegation guard needs — `Target:`, `Status:` and
  `Feature:` — all live in the task's `TASKS.md` summary block, which
  PRE-FLIGHT step 2 already read once for the whole run, so no body read
  can be justified by the guard.
- One read is bounded and named: under UNATTENDED the pre-ask (SKILL.md
  PRE-FLIGHT) opens each `[PARKED]` task's trailing `## Parking handoff` —
  that section only, before DELEGATE is decided — because the question it
  must list verbatim lives nowhere else. Nothing else in a delegated task's
  body is ever opened here.

## The agent prompt

The prompt is **fixed size** — the same frame every time, with a different
number in it. It does not describe the task, because the parent has not
read the task and will not; the parent's context does not grow with the
batch.

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
   not a closed list, so any flag `/task-implement` gains rides through
   without the prompt growing. They are:
   - NO_COMMIT, NO_PUSH, AUTO_CONFIRM;
   - REVIEW and ROUNDS — whether the run was invoked with `--review`, and
     the round cap. An implementor told REVIEW is true runs the loop from
     `./review-rounds.md` for its own task (see below);
   - REVIEW_MODEL and REVIEW_EFFORT — the `--review-model` and
     `--review-effort` values as the run resolved them, `auto` by default.
     They ride through as **two strings**: the parent resolves nothing and
     measures nothing, because `auto` resolves per task from each task's own
     diff, inside that implementor's own loop;
   - the resolved testing mode — full test mode with the concrete test
     command, or skip-tests mode — so the agent does not redo RESOLVING THE
     TEST RUNNER and does not re-ask the no-test-suite A/B question;
   - the dirty-tree decision (DIRTY_FOLD / DIRTY_FOLD_UNTRACKED) already
     made in PRE-FLIGHT, plus the note that a tree dirtied by this run's own
     earlier tasks is expected, so the agent must not re-run the prompt
     protocol in `../task-engine/references/tree.md`;
   - the run's interaction policy as ARGUMENT PARSING resolved it — carried
     in the flag list as `--attended` or `--unattended`, and stated in the
     prompt under both values, *This run is attended* or *This run is
     unattended*. The agent resolves this handed-down policy, never the
     `CLAUDE.md` line, per `../interaction-engine/references/policy.md`
     § *A parent hands its policy down*. This value alone settles whether
     the agent can ask, not the fact that it is a subagent: a subagent can
     ask, because the launcher can carry an answer.
     - Under attended, a question that genuinely needs the user — an
       acceptance criterion the body and the codebase cannot settle, a
       review round's approval gate — ends the agent's turn under a
       `QUESTIONS FOR USER` heading in the fixed relay block below, options
       and a recommendation included, and the answer comes back in the same
       conversation (§ *The question relay*); the agent never guesses,
       never waits on nothing, and never stops for a question.
     - Under UNATTENDED the agent parks the task instead, per
       `../task-engine/references/parking.md`, and returns `[PARKED]` as
       its terminal status;
   - the held answer for this task — only when the task is `[PARKED]` and
     the parent holds one from the pre-ask or from chat (§ *Between
     delegated tasks* step 2a): one answer, for the one task the prompt
     names, which the agent's Step 1 feeds to the unpark. Under attended
     no answer is held; the agent asks the handoff's question through the
     relay;
   - PARALLEL — only when set — and with it **the worktree path**: the
     absolute path of `.claude/worktrees/task-<N>`, named as the agent's
     repository root for everything it does, with the base branch's name
     and the rule that the push is not the agent's — its Step 7 is
     `../task-engine/references/worktree.md` § *The agent integrates*, and
     it returns naming the base tip it rebased onto. The dirty-tree
     decision in a fresh worktree is always *clean*, and the prompt says so
     in place of DIRTY_FOLD.

   Every one of these is a run-level value, resolved once — the held answer
   and the worktree path are the two per-task values, and each is one line
   — so the flag list is O(1) in the size of the batch, like the rest of
   the prompt.
3. **The instruction to gather its own context**: read the task body,
   CLAUDE.md and `.claude/context/` itself, since it has been given none of
   them. Do not hand it a pre-chewed summary instead.
4. **The return contract**, below.

The whole thing reads roughly:

> Implement task `<n>` from the backlog in `<absolute repo path>` by
> following the `/task-implement` skill's per-task workflow (Steps 1–7) for
> that one task: flip it `[IN PROGRESS]`, implement it, flip it `[DONE]`,
> make its single commit and its single push. *(Under PARALLEL the first
> sentence ends instead: … make its single commit on `wt/task-<n>` in the
> worktree at `<absolute worktree path>` — your repository root for
> everything you do, a checkout of that branch from the base branch
> `<base>` — then rebase `wt/task-<n>` onto the current tip of `<base>`,
> re-verify if the rebase changed anything, and return naming the tip you
> rebased onto. Do not push, and do not pull: the launcher lands and
> pushes.)*
>
> Resolved flags for this run: `<the run's resolved flag list>`.
>
> Read the task body, CLAUDE.md and `.claude/context/` yourself — you have
> not been given them. This run is attended: if something genuinely needs
> the user's decision, end your turn under a `QUESTIONS FOR USER` heading —
> the question, its options with what each costs, your recommendation, and
> for a draft awaiting approval a plain summary of it — the user replies
> `show` to see it whole — and the answer will come back in
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

- When REVIEW rides through in the flag list, **each implementor spawns its
  own reviewer** for its own task: launcher → implementor → reviewer. A
  general-purpose subagent has the `Agent` tool and can spawn a child that
  runs and returns, so batch `--review` needs no fallback and gets none.
- The implementor must honour two properties of the single-task loop:
  - its reviewer also **returns asynchronously** — the Agent call yields an
    id and the report arrives later as a separate notification;
  - it must therefore **not reach its own Step 7** until its reviewer's
    result has actually arrived. An implementor that commits on the
    strength of a spawn call's return value commits unreviewed work and
    reports it as reviewed.
- REVIEW_MODEL and REVIEW_EFFORT are run-level strings in the flag list
  above, and each implementor resolves `auto` against its own task's diff —
  the launcher neither sizes a diff nor picks a model, and opens no task
  body to do either.
- The parent passes the flags through and **never sees a finding**: no
  report, no triage table, no rejection ledger travels up.
  - The return contract is unchanged by `--review` in its first four fields
    — a task whose loop ended in unresolved `BLOCKING` findings comes back
    as a failure with its one-line reason, like any other failure, and
    halts the run.
  - The fifth field carries no finding either: `/follow-ups`' own exclusion
    rule keeps findings out, since a finding is not an unrecorded piece of
    work. The one thing from a loop it does catch is a deferral
    `/task-iterate` noted should become a task, where none was authored.

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

   - At an approval gate the block carries the agent's plain-language
     summary of the draft, per
     `../interaction-engine/references/messages.md`; a `show` reply goes to
     the same agent like any answer, and its next result prints the draft
     and asks again.
   - The round number counts this task's questions, from 1.
2. Wait for the user's answer. Silence, EOF or an unrelated reply is not an
   answer; the run waits.
3. Send the answer to the **same** agent, by its id — never to a fresh one,
   which would have to be re-briefed and would answer differently — and
   wait for its result as for any spawn: blocking on it without PARALLEL,
   as one more return to arrive under it. That result is either another
   question, which repeats this loop with the next round number, or the
   six-field return below.

- Add no fact the parent does not hold and never answer on the user's
  behalf, not even a question that looks easy: the parent never opened the
  task.
- The one thing the parent may add is a fact already in its own row set —
  an earlier task's outcome that answers the question — and it says that
  it is doing so, so the user can see which part of the block came from
  the agent and which from the launcher.
- Under PARALLEL several agents can ask at once, and a relayed question
  stops nothing but its own task: the relay waits on the user, a landing
  does not.
  - Land and bookkeep as usual a return that arrives while a question is
    open, and render a second question in its own block — each block
    carries its task heading, and each answer goes back by agent id.
  - After every relay, print one line naming the agents still waiting on
    the user: `Waiting on you: tasks 22 (round 1), 25 (round 2).`
  - The same channel carries the one rebase-again message of a landing
    (`worktree.md` § *The orchestrator lands*, step 2).
- Under UNATTENDED this case does not occur: the agent parks instead
  (§ *The agent prompt*) and its result is a return with `[PARKED]` as the
  terminal status. A `QUESTIONS FOR USER` result under UNATTENDED is an
  agent that did not follow its prompt, and counts as an ambiguous return
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
   `[PARKED]` task, the bookkeeping commit's hash; under PARALLEL, beside
   it, the base tip the agent rebased onto (`worktree.md` § *The agent
   integrates*, step 5),
4. a one-line failure reason, and only when it failed,
5. **at most three one-line follow-ups**, and only when there are any — a
   parking branch whose delete failed among them, within the three
   (`parking.md` § *The unpark transaction*),
6. **at most three *For the record* lines**, in the shape SKILL.md's THE
   CLOSING REPORT gives that group, and only when there are any.

**The parent accumulates that and nothing else.**
- No diffs, no file lists, no narrative. A deviation worth keeping is one
  bounded line in the sixth field, an agent with more to say says it in the
  failure line, and a task that needs the user's attention is a relayed
  question (attended) or a `[PARKED]` return (UNATTENDED), never a stop.
- The closing report's *For the record* group is those sixth fields,
  attributed to their tasks.

**A `[PARKED]` return is not a failure and does not halt the run.**
- The agent ran the park sequence itself, so the base tree is clean and its
  question is in the task's `## Parking handoff`.
- The parent records the row, prints the returned question under the run's
  next `P<n>` handle exactly as SKILL.md's *Parking at a question* does for
  an in-context task, prints its progress line (§ *Between delegated
  tasks*), and spawns the next agent.
- The closing report lists the task under *Follow-ups* with that question,
  per `../task-engine/references/closing-report.md` — the parent still
  opens no body for it.

**The fifth field applies `/follow-ups`' rules; it does not define its
own.**
- The agent reads that command's own body and applies what it finds there
  to its own session — for a delegated agent, exactly the one task.
- **The agent is told the command's name, never a path to it.** `--local`
  installs a feature into `$PWD/.claude` instead of the global home, so an
  absolute home path would silently miss every `--local` install; and the
  agent is handed a prompt rather than this file, so a relative path has no
  anchor. The name resolves wherever the command actually lives.
- What counts as a follow-up, what is excluded because it is already
  tracked on disk, and how an item is written are all that command's, and
  are **not restated here**.
- **It reads the rules rather than invoking the command.** The rules are
  applied once per run, in the parent's closing report (SKILL.md's CLOSING
  THE RUN), never as a per-task `/follow-ups` call. Where the command is
  missing — a user removed it by hand despite `requires:
  command:follow-ups` — the agent omits the field, reports nothing about
  it, and does not fail the task.
- The field is empty on almost every task: the command's exclusion rule
  does the work, and an agent that did its task and wrote it down has
  nothing that qualifies.
- Two bounds belong to this channel rather than to the command, and only
  these two:
  - **At most three items** — the command imposes no cap; this one protects
    the parent's context and does not redefine a follow-up. An agent with
    more than three unrecorded things did not finish its task.
  - **Omitted entirely when the list is empty**, so the common case costs
    nothing.
- The parent does not act on them, does not judge them and does not ask
  about them mid-run. It records them beside the other four fields and they
  feed exactly one place: the *Follow-ups* group of the closing report,
  `../task-engine/references/closing-report.md`, attributed to their task
  and de-duplicated by action against the run's own items there.
- A follow-up line is the agent's claim, not the parent's finding — the
  parent never opened the task and cannot verify it, so it is never a
  reason to halt the run.

## Between delegated tasks

After each agent returns, and before the next spawn — under PARALLEL,
returns are handled one at a time in arrival order, and each is **landed
first**, per `worktree.md` § *The orchestrator lands*: `git merge --ff-only
wt/task-<N>` onto the base; when the base moved, one rebase-again message
to the same agent and one more fast-forward; the push unless NO_PUSH; then
`git worktree remove` and the safe `git branch -d`. A landing that fails —
a fast-forward refused twice, a safe delete refused — is the task's
failure, worktree kept (§ *Failure*). Then, on the base tree:

1. Re-read `.claude/TASKS.md` with the Read tool; the agent wrote a status
   there and the parent's copy is stale.
   - If the returned task carries a `Feature:` line and landed `[DONE]`,
     apply SKILL.md's FEATURE COMPLETION check here — the same check Step 6
     runs for an in-context task, triggered by this re-read instead. Still
     don't propose anything; that stays batched to the end of the whole
     run.
   - On a run resolved by `all`, this same re-read is where SKILL.md's
     BETWEEN TASKS step 2 re-checks the next task's `Preconditions:`: if
     they no longer hold, skip that task with its one-line report and spawn
     no agent for it, then apply the check to the task after it.
     `Preconditions:` is on the summary block, so the re-check opens no
     body and adds no read. Under PARALLEL this re-read is the scheduling
     point's (§ *The scheduler*), and the re-check is subsumed by it:
     eligibility is re-derived for the whole list on every read.
   - Likewise, under UNATTENDED a next task that is `[PARKED]` with no held
     answer is skipped here with `parking.md` § *The answerer rule*'s one
     line and gets no agent — `Status:` is on the summary block and the
     answers are in run memory, so this too opens no body.
2. Confirm the agent actually did what it claims — the status it reports
   should match the file, and under the default (committing) mode
   `git status --porcelain` should be clean on the base. A `[PARKED]`
   status with a clean tree is consistent: the park sequence ends in a
   bookkeeping commit, and the work-in-progress is on `park/task-<N>`, not
   in the tree. A mismatch is a failure; see below.
2a. Read any chat message that arrived while the agent ran, exactly as
   SKILL.md's BETWEEN TASKS step 2a says for an in-context run: a reply by
   `P<n>` handle to a question printed this run — at the pre-ask or at a
   park — is that task's answer, recorded in run memory, and the task moves
   to the front of the remaining list, so its agent is spawned next, the
   answer in its prompt (§ *The agent prompt*), and unparks it in its own
   Step 1. Reject a reply the parent cannot match with one line, as there.
3. Report one line of progress to the user: "Task 20 done (`abc1234`).
   Starting task 22." — or, for a `[PARKED]` return, "Task 20 parked
   (question 3). Starting task 22." Under PARALLEL the line names what is
   in flight: "Task 20 landed (`abc1234`). In flight: 22, 23. Starting task
   24." — the tasks the scheduling point starts named last, or "Nothing
   more to start." when it starts none.
4. In skip-tests mode, ask "Proceed?" before spawning the next agent,
   unless AUTO_CONFIRM is true or UNATTENDED is true. This prompt belongs
   to the parent — the agent never asks it. Under PARALLEL ask it once per
   scheduling point that starts at least one task, not once per task.

Under PARALLEL the scheduling point follows (§ *The scheduler*).

## Failure

A delegated task that fails halts the run exactly as an in-context failure
does: do not spawn the next agent, do not fix up the failed task's status
behind the agent's back, and report

- which tasks completed (with their commit hashes),
- which task failed and what the agent said about it — under PARALLEL,
  with its worktree path, the record of the work it left behind
  (`worktree.md` § *Failure*),
- which tasks were never started.

Under PARALLEL the halt spawns nothing more, and the tasks already in
flight are allowed to finish and land — each return handled as § *Between
delegated tasks* says, with no scheduling point after it — because
abandoning them would strand committed work in worktrees for no gain. Give
the closing report once nothing is in flight.

- An agent that returns something ambiguous — no status, no commit, an
  unclear report — counts as a failure. Verify rather than assume; the
  parent never saw the work.
- A `QUESTIONS FOR USER` result is neither a failure nor a return
  (§ *The question relay*), and a `[PARKED]` return is not a failure
  (§ *What the agent returns*): only a task that stopped `[IN PROGRESS]`
  halts the run.
