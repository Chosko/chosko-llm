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
  earlier ones' context; agents spawned one at a time, never
  parallel (shared working tree, branch, `TASKS.md`), each owning own
  task's status flips, commit, push, while `claude+human` / `human` /
  explicitly requested `[STALE]` tasks stay in parent conversation
  since need user present. `--agents` / `--no-agents`
  pre-answer prompt; single-task runs never see it. Under orchestrate mode
  (`interaction-engine`'s `mode.md`, checked at PRE-FLIGHT step 2b)
  DELEGATE is true for every run, one task included, nothing asked; only
  `--no-agents` turns it off; the delegation guard unchanged. On such run parent
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
  plus a held answer for a `[PARKED]` task) + instruction to read
  body, CLAUDE.md, context layer itself; keeps exactly six values per
  return, the last two optional (task number, terminal status, commit hash or
  nothing-committed, one-line failure reason only on failure, at most
  three follow-ups, omitted when empty, which is almost every task, and at
  most three *For the record* lines). The
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
