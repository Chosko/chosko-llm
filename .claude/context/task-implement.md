# Features: task-implement

## Overview

Covers `/task-implement`'s common path, supporting files, unattended
parking, body reading, human-in-the-loop tasks, testing policy, `[STALE]`
handling and `Preconditions:`. Continued in
[task-implement-delegation.md](./task-implement-delegation.md) (delegated
runs, commits, feature completion, the closing report) and
[task-implement-review.md](./task-implement-review.md) (`--review` rounds).
The rest of the suite: [task-suite.md](./task-suite.md).

- `skills/task-implement/` — implements backlog tasks end-to-end with
  tests-first sequence. `SKILL.md` carries common path (clean
  tree, known test runner, numbered `target: claude` task) and declares
  `requires: skill:task-engine` —
  backlog resolution and selectors reference
  `references/resolution.md`, implementable/terminal statuses `status.md`,
  `Target:` handling and the delegation guard `targets.md`, the STALE
  protocol `stale.md`, the dirty-tree check `tree.md`, and PRE-FLIGHT step 5
  plus Step 7 `commit.md`. Seven supporting files are read only when their
  branch fires — `test-runner.md` (runner must
  be inferred; mirrors task-setup's table), `no-test-suite.md`,
  `human-in-loop.md`, `unity-mcp-checkpoints.md` (Unity-MCP-driven
  checkpoints), `body-schemas.md`
  (non-current body schema), `delegated-runs.md` (2+-task run user delegated to subagents),
  and `review-rounds.md` (`--review` passed; read once after argument
  parsing, before the first task, never otherwise) — plus `task-engine`'s
  `parking.md`, read at ARGUMENT PARSING when UNATTENDED is true or at
  PRE-FLIGHT step 2 when a resolved task is `[PARKED]`, never on an attended
  run that meets no parked task.
  Also declares `requires: command:follow-ups`: its CLOSING THE RUN section
  applies that command's rules — the body read by name, never invoked — as
  the *Follow-ups* group of the closing report, once per run, after the
  feature-completion proposal, at a user-requested stop between tasks and at
  a failure halt too, reading the per-agent returns under `--agents`, adding
  no commit; with the command absent the group holds the run's own items
  only, silently. **`--unattended`** (PARKED TASKS; the `unattended`
  execution policy, `attended` the default under which nothing changes):
  UNATTENDED is true when the flag was passed OR the conversation declares
  the run unattended — the one sentence a runbook step's preamble or a
  delegated-agent prompt carries; a merely *non-interactive* notice is not
  that. Refusals: `parking.md` § Refusals. Under it every prompt with a default takes it
  (delegation → no, dirty tree → abort, `Proceed?` → yes, …), each a *For the
  record* line; an ambiguous test runner aborts. A question about the work —
  inside the per-task workflow only — runs `parking.md`'s park sequence,
  question printed under the run's next `P<n>` handle, on to BETWEEN
  TASKS. PRE-FLIGHT step 2a
  **pre-asks**: one block of every `[PARKED]` task, each under its `P<n>` handle, in the resolved
  list with its `Question:` verbatim — the one pre-flight body read, handoff
  section only — answered by handle (`P1: Q1a, Q2b`) or `skip` / `skip P<n>` / `skip all`,
  approval-gate items skip-only, answers held in run memory; silence is `skip
  all`; `--skip-parked` (requires `--unattended`) suppresses it. BETWEEN
  TASKS step 2a reads chat replies by handle, records the answer and moves
  the task to the front; a number never printed or a second answer is
  rejected with one line. Step 1 on a `[PARKED]` task decides the answerer
  (an attended session, or a held answer): none → skipped with one line, no
  branch touched; else the unpark transaction, handoff removed, resumed at
  the step named, both edits riding in Step 7's commit; a cherry-pick
  conflict leaves it `[PARKED]` (skipped after a bookkeeping commit under
  UNATTENDED, halt-and-ask under attended). A park that cannot make its
  branch is a Step 7 failure; a parked task never is.
  Reads each task's body file from `.claude/tasks/<N>.md` only when
  needed, treats it as primary context source — only fans out to
  CLAUDE.md and context layer when body doesn't cover what's
  needed. Status flips happen in `.claude/TASKS.md`. Human-in-the-loop
  tasks: on
  `target: claude+human` pauses at each `## Manual interventions`
  checkpoint, walks user through manual step, independently
  verifies outcome before continuing; on `target: human` task runs
  as guided walkthrough (no production edits by Claude, bookkeeping
  still Claude's). When project declares Unity MCP plugin
  (`Unity MCP for /task-implement:` marker in CLAUDE.md) and
  `mcp__UnityMCP__*` tools connected this session, `human-in-loop.md`'s
  gate reads `unity-mcp-checkpoints.md` instead: Claude checks Unity
  Console after compilation, performs editor actions itself, rewrites
  each checkpoint into verification step — opt-outable per run, no-op
  (standard manual protocol) when MCP not connected. Honors `Testing policy for /task-implement:
  skip-tests|full-tdd|skip-tests-unattended` marker in project's
  CLAUDE.md (checked before heuristic test-suite detection) so
  no-test-suite decision persists across runs instead of re-asked
  each time. In skip-tests mode, per-task "Proceed?" confirmation can
  be suppressed with `-y` flag for single run, or permanently via
  `skip-tests-unattended` marker value. On `[STALE]` task
  warns naming originating feature and offers implement-anyway or stop
  (`all` / `next` skip stale tasks, report them, rather than deciding
  for user). `next` / `all` honour `Preconditions:` per `resolution.md`'s
  eligibility clause — `all` orders its list so nothing starts ahead of
  what it waits on and names blocked tasks by id; on a run resolved by
  `all`, BETWEEN TASKS step 2 (and `delegated-runs.md`'s between-agents
  re-read, which then spawns no agent for it) re-checks the upcoming task's
  `Preconditions:` and skips it with one line when they no longer hold,
  adding no read; an explicit-number list is never re-checked.

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
- [task-implement-delegation.md](./task-implement-delegation.md),
  [task-implement-review.md](./task-implement-review.md) — the rest of
  `/task-implement`.
- [task-engine.md](./task-engine.md) — the reference library it reads.

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
