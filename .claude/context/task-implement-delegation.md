# Features: task-implement delegated runs and closing

## Overview

Covers `/task-implement`'s delegated runs, per-task commits, the
feature-completion proposal and the closing report. Starts in
[task-implement.md](./task-implement.md); `--review` rounds in
[task-implement-review.md](./task-implement-review.md). The rest of the
suite: [task-suite.md](./task-suite.md).

- `skills/task-implement/`, continued from [task-implement.md](./task-implement.md):
  On run resolving to 2+ tasks, offers
  to implement each task in fresh subagent so later tasks don't inherit
  earlier ones' context — the point is context; concurrency is a second
  step on the same shape (`--parallel`, below) and changes nothing an agent
  is handed or returns. Each agent owns its
  task's status flips and commit, while `claude+human` / `human` /
  explicitly requested `[STALE]` tasks stay in parent conversation
  since need user present. `--agents` / `--no-agents`
  pre-answer prompt; single-task runs never see it. Under orchestrate mode
  (`interaction-engine`'s `mode.md`, checked at PRE-FLIGHT step 2b)
  DELEGATE is true for every run, one task included, nothing asked; only
  `--no-agents` turns it off; the delegation guard unchanged. `--parallel`
  implies `--agents`.
  **One agent at a time** (`delegated-runs.md` § *One agent at a time*), the
  default: `run_in_background: false`, parent blocks on each before spawning
  the next, every task in the base tree (shared tree, branch, `TASKS.md`
  would race), each agent pushing its own commit. **Under PARALLEL**
  everything below lives in `parallel-runs.md`, read only when `--parallel`
  is passed — its § *The flag* at ARGUMENT PARSING, the parallel-safe marker
  at PRE-FLIGHT step 3 — and amending `delegated-runs.md`, which carries one
  hook line; a run without the flag loads none of it. **The scheduler**
  (`parallel-runs.md` § *The scheduler*), `task-engine`'s `worktree.md` read
  before the first spawn (worktree, integration, landing are its; the file
  states scheduling only): resolved list still resolved once up front, report and delegation
  count printed from it, but it is the **admissible set**, its order the
  **priority** among tasks eligible at the same moment. At every
  **scheduling point** — run start, each landing — the launcher re-reads
  base `TASKS.md`, re-derives eligibility per `resolution.md` § Eligibility
  with its in-flight clause (a task in flight is neither done nor eligible;
  a dependent waits for it to **land**, since landing writes the status the
  read sees). The **in-flight set** = the tasks this run spawned and not
  yet landed, run memory only, nothing read off git — every "in flight" in
  the file (count against N, eligibility clause, overlap rule, barrier
  wait, end-of-run test) means membership in it; the worktree list is what
  the skip-while-present rule and the other readers consult, never what
  counts. Then walks the list in order while fewer than N in flight (no
  bound under `max`), creating each worktree per `worktree.md` (the
  `.git/info/exclude` line once per run) and spawning with
  `run_in_background: true`; skips a task not eligible, in flight, held
  back by the overlap rule, or not in flight with a worktree already there
  (skip-while-present line, once per task per run, counts toward nothing)
  — skipped is not dropped, re-examined next point; stops the walk at a
  barrier. Explicit
  task never blocked by a precondition not in flight; one in flight is
  waited on. Run ends when nothing in flight and nothing can start.
  **Overlap rule** (§ *The overlap rule*): two tasks whose `Files:`
  intersect are never in flight together — the later **held back** whatever
  N says, one line naming the task it waits on (`Task 24 waits on task 22
  (both list …)`), printed once per task waited on, re-examined next point;
  `Files:` on the summary block, so no read; empty/missing `Files:` holds
  nothing back and is never held back. Safety net under `Preconditions:`,
  not a second graph. PARALLEL_SAFE paths (the `Parallel-safe files for
  /task-implement:` marker, PRE-FLIGHT step 3) removed from every `Files:`
  line before the intersection — version counter, newest-first changelog,
  whose conflicts the rebase resolves mechanically; no marker, no exemption.
  **Barriers** (§ *Barriers*): a parent-kept task dirties the base, which
  must be clean at every landing, so when the walk reaches one the launcher
  starts nothing more, waits for everything in flight to land (returns
  handled, questions relayed), runs it in the base tree as an in-context run
  would (BETWEEN TASKS step 2's skip included), and its commit/park/skip is
  the next scheduling point — list position kept, never deferred to the
  end, never spawned into a worktree. On such run parent
  is **launcher**, not orchestrator: evaluates delegation guard
  (`Target:`, `Status:`, `Feature:`) from `TASKS.md` summary blocks
  PRE-FLIGHT step 2 already read, so never opens `.claude/tasks/<N>.md`
  for delegated task on any path; hands every agent same fixed-size
  prompt — task number + repo's absolute path + run's resolved flags
  (open list, not closed set: NO_COMMIT/NO_PUSH/AUTO_CONFIRM, resolved
  testing mode w/ concrete test command, DIRTY_FOLD /
  DIRTY_FOLD_UNTRACKED, the resolved policy as `--attended`/`--unattended`,
  stated in the prompt under both values — attended: a question ends the
  agent's turn under `QUESTIONS FOR USER` and the launcher relays it in the
  runbook's fixed block, an approval gate as a plain summary with `show`
  fetching the draft, answer sent back to the same agent; unattended: the agent
  parks and returns `[PARKED]` with its question, recorded, never a halt —
  plus a held answer for a `[PARKED]` task, and under PARALLEL the flag
  plus the absolute worktree path named as the agent's repository root,
  the base branch, the rule that the push is the launcher's — Step 7 is
  `worktree.md` § *The agent integrates* — and *clean* in place of
  DIRTY_FOLD; the held answer and the worktree path are the two one-line
  per-task values, prompt still O(1)) + instruction to read
  body, CLAUDE.md, context layer itself; keeps exactly six values per
  return, the last two optional (task number, terminal status, commit hash or
  nothing-committed — under PARALLEL beside it the base tip rebased onto —
  one-line failure reason only on failure, at most
  three follow-ups, omitted when empty, which is almost every task, and at
  most three *For the record* lines). Under PARALLEL several agents can ask
  at once; a relay stops only its own task — a return arriving while a
  question is open is landed and bookkept, a second question gets its own
  block, answers go back by agent id — and after every relay one line names
  the agents still waiting (`Waiting on you: tasks 22 (round 1), …`); the
  same channel carries a landing's rebase-again message. **Between
  delegated tasks** under PARALLEL each return is **landed first** per
  `worktree.md` § *The orchestrator lands* — `git merge --ff-only
  wt/task-<N>`, one rebase-again round to the same agent when the base
  moved, push unless NO_PUSH, `git worktree remove` + safe `git branch -d`;
  a landing that fails (fast-forward refused twice, delete refused) is the
  task's failure, worktree kept — then the base-tree steps: re-read
  `TASKS.md` (the scheduling point's read, the `all` re-check subsumed by
  it), confirm status and a clean base, chat replies by `P<n>`, progress
  line naming what is in flight (`Task 20 landed (abc1234). In flight: 22,
  23. Starting task 24.` / `Nothing more to start.`), skip-tests `Proceed?`
  once per scheduling point that starts a task; then the scheduling point.
  **Failure**: nothing more spawned, tasks in flight finish and land with no
  scheduling point after, report once nothing is in flight, the failed
  task's row naming its worktree path. The
  field applies `/follow-ups`' rules, **not a format of its own** — the agent
  reads that command's own body and applies what is there; what counts, what
  is excluded and how an item is written are that command's and are
  deliberately not restated in either `delegated-runs.md` or SKILL.md,
  leaving only the cap and the omit-when-empty to the channel. **Named, never
  pathed** (`../../docs/authoring-guide.md` § "Asking whether a feature is
  installed: name it"): the agent is handed a prompt rather than a file and
  has no anchor to resolve a relative path against, so the command's
  **name** is what resolves in both scopes.
  **Reads the rules, never invokes the command** — invoking would be the
  per-task call the DO NOT list forbids, and a read degrades where an
  invocation would not: no file to read means skip the field silently, the
  same rule the closing report follows, never a failed task. The lines feed
  the report's *Follow-ups* group and nothing else, and the parent neither acts on nor
  verifies one. Prompt O(1) in batch size and in task size, so the
  parent's context does not grow with the batch; tasks the parent keeps
  get their body read in Step 1. Commits each task
  separately; `--no-commit` runs full sequence but skips
  per-task commits, leaving every task's changes uncommitted. When a
  `Feature:`-tagged task lands `[DONE]` and leaves every task for that
  feature `[DONE]`/`[SKIP]`, records it as a completion candidate; once, at
  the very end of the run (batched across the whole run, never per-task),
  proposes flipping each candidate's `FEATURES.md` `Status:` from
  `[PLANNED]` to `[DONE]` in a plain-language question — user decides per
  feature, one commit covers every flip approved; a `confirmation` gate, so
  under `unattended` every candidate flips unasked. A nested run (delegated
  agent, `/runbook-run` step) never proposes: names candidates in its closing report, outermost run
  asks. THE CLOSING REPORT (rule in `task-engine`'s `closing-report.md`,
  this skill's own items in its note): two groups, **For the record** (one line each,
  `<what deviated> — <why> — <resolved by whom>`) then **Follow-ups** — last,
  nearest the prompt — one numbered list, `1.`/`2.`/…, any length: the run's
  own items (unresolved `BLOCKING` finding, task left `[IN PROGRESS]`, owner
  follow-up with anchor, precondition that no longer held, declined slug,
  every task parked or skipped-unanswered with its `Question:` verbatim) plus
  what `/follow-ups`' rules yield applied to the run's reading, de-duplicated
  by action with the command form kept; the number is the reply handle,
  restarting at 1 per report, a lone item still numbered, and a number naming
  a parked task's question is its answer for the next run; an empty group
  prints `none`. Under `--agents` the sixth field feeds *For the record*, the
  fifth and each `[PARKED]` return's question feed *Follow-ups*. Consequential edits — a passage brought into agreement with an
  approved change, no meaning added — are in scope in any file, same commit,
  reported For the record; new meaning in an owned document goes under
  Follow-ups as a precise `/architect amend` follow-up.

## Public API

- Each feature's contract is its text in § Overview. Frontmatter,
  `description` contract and loading-control keys:
  [task-suite.md](./task-suite.md) § Public API.

## Internal patterns

- [task-suite.md](./task-suite.md) § Internal patterns.

## Domain dependencies

- [task-suite.md](./task-suite.md) § Domain dependencies.

## Cross-references

- [task-suite.md](./task-suite.md) — the task-suite hub and its file list.
- [task-implement.md](./task-implement.md),
  [task-implement-review.md](./task-implement-review.md) — the rest of
  `/task-implement`.
- [task-engine.md](./task-engine.md) — the reference library it reads.

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
