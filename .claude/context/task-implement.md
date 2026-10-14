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
  protocol `stale.md`, the dirty-tree check `tree.md`, PRE-FLIGHT step 5
  plus Step 7 `commit.md`, and — read every run, as part of the common path
  — RESOLVING THE TEST RUNNER `testing-policy.md`, Steps 2–5
  `tests-first.md` (kept as one PER-TASK WORKFLOW heading citing it, with the
  `claude+human` checkpoint hook at Step 3) and THE CLOSING REPORT
  `closing-report.md`, each kept as a heading and a citation. `task-engine`'s
  `test-runner.md` (runner must be inferred; mirrors task-setup's table) and
  `no-test-suite.md` are read only when their branch fires, and so are four
  supporting files of its own — `human-in-loop.md`, `body-schemas.md`
  (non-current body schema), `delegated-runs.md` (2+-task run user delegated to subagents,
  or `--agents` / `--parallel` passed),
  and `review-rounds.md` (`--review` passed; read once after argument
  parsing, before the first task, never otherwise) — plus `task-engine`'s
  `parking.md`, read at ARGUMENT PARSING when UNATTENDED is true or at
  PRE-FLIGHT step 2 when a resolved task is `[PARKED]`, never on an attended
  run that meets no parked task, and `parallel-runs.md`, read at ARGUMENT
  PARSING only when `--parallel` is passed. **`--parallel <N|max>`**: the
  body only strips the pair and reads `parallel-runs.md`, whose § *The flag*
  holds the value rules (`N` ≥ 2, `max` case-insensitive and unbounded),
  PARALLEL and DELEGATE = true (step 2b asks nothing), the four one-line
  refusals (`--no-agents`, `--no-commit`, a `CLAUDE.md` mapping another VCS,
  a bad `N`), the silent no-op on a one-task run, and the PRE-FLIGHT step 3
  read of the `Parallel-safe files for /task-implement: <path>, <path>`
  marker into PARALLEL_SAFE, whose one reader is its overlap rule. That file
  names `task-engine`'s `worktree.md`, read before the first spawn; the rest
  — scheduler, worktree per task, landing — is
  [task-implement-delegation.md](./task-implement-delegation.md). In a
  worktree Step 7 is `worktree.md` § *The agent integrates* — one bullet in
  the body, read by the delegated agent the prompt names its worktree.
  Also declares `requires: command:follow-ups`: its CLOSING THE RUN section
  applies that command's rules — the body read by name, never invoked — as
  the *Follow-ups* group of the closing report, once per run, after the
  feature-completion proposal, at a user-requested stop between tasks and at
  a failure halt too, reading the per-agent returns under `--agents`, adding
  no commit; with the command absent the group holds the run's own items
  only, silently. **`--attended` / `--unattended`** (PARKED TASKS; the
  interaction policy, resolved per [interaction-engine.md](./interaction-engine.md)
  `policy.md` — flag or handed-down policy, then the `CLAUDE.md`
  `Interaction policy:` line, then `attended`, under which nothing changes):
  UNATTENDED is true when it resolves to `unattended`. Refusals: `parking.md`
  § Refusals, for a flag or handed-down policy only — a `CLAUDE.md` policy
  is never refused, a question then stops instead of parking. Under it
  `gates.md` is read; the feature-done proposal and skip-tests `Proceed?` are
  `confirmation` gates and pass on their own; every other prompt with a
  default takes it (delegation → no, dirty tree → abort, …), each a *For the
  record* line; an ambiguous test runner and the no-test-suite A/B question
  stop the run. A question about the work —
  inside the per-task workflow only — runs `parking.md`'s park sequence,
  question printed under the run's next `P<n>` handle, on to BETWEEN
  TASKS. PRE-FLIGHT step 2a
  **pre-asks**: one block of every `[PARKED]` task, each under its `P<n>` handle, in the resolved
  list with its `Question:` verbatim — the one pre-flight body read, handoff
  section only — answered by handle (`P1: Q1a, Q2b`) or `skip` / `skip P<n>` / `skip all`,
  approval-gate items skip-only, answers held in run memory; silence is `skip
  all`; `--skip-parked` (requires the policy to resolve to `unattended`) suppresses it. BETWEEN
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
  still Claude's). When a tool connected this session can perform a
  checkpoint's manual step (discovered from the live tool set, no server
  named), `human-in-loop.md` asks once per task whether Claude performs
  the checkpoints (user verifies) or the user does (Claude verifies) — a
  real decision under the interaction policy; under automatic Claude
  reads the tool's console after a compile, waits out reloads, and
  re-queries every outcome, a step the tool cannot perform falling back
  to the standard manual protocol. Honors `Testing policy for /task-implement:
  skip-tests|full-tdd|skip-tests-unattended` marker in project's
  CLAUDE.md (checked before heuristic test-suite detection; the rule and its
  `project-policy:` declaration live in `task-engine`) so
  no-test-suite decision persists across runs instead of re-asked
  each time; the `Parallel-safe files for /task-implement:` marker beside
  it is read the same way, under `--parallel` only (above), and declared
  in this skill's own frontmatter as `project-policy: line:Parallel-safe
  files for /task-implement=` — free-form, so no values. In skip-tests mode, per-task "Proceed?" confirmation can
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
  adding no read; an explicit-number list is never re-checked. Under
  `--parallel` that re-check is subsumed: the scheduler re-derives the whole
  clause, in-flight reading included, on every read of the base `TASKS.md`.

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
- [pipeline-dashboard.md](./pipeline-dashboard.md) — the opt-in dashboard: the
  ARGUMENT PARSING paragraph for `--dashboard` / `--no-dashboard` is the one
  passage naming it; the launching session follows it, never a delegated
  agent, a subagent or a run a runbook step launched (`--inline` included).

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
