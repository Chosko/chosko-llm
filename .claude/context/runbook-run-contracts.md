# Features: runbook-run — output and contracts

## Overview

Covers `skills/runbook-run/`'s chat contract, closing report, commit
convention, Stop-hook reply, hard contracts, range bounds and depth budget.
The rest of the bullet: [runbook-run.md](./runbook-run.md) and
[runbook-run-loop.md](./runbook-run-loop.md).

- `skills/runbook-run/`, continued from [runbook-run-loop.md](./runbook-run-loop.md) § Overview:
  **Chat contract**: quiet between steps — a progress line at each step's
  spawn / execution-phase start (`Step <n> running. Current run progress
  (<k>/<m>). Total runbook progress (<x>/<y>).`; `k` = steps this run
  finished + the one starting, `m` = every selectable step in range capped by
  `--steps N`, fixed at launch, `x/y` = the index's `Steps:` counter at launch,
  `x` raised by this run's finished steps + the one starting; parked/failed
  steps add nothing; full definitions in CHAT OUTPUT) and one line at its end
  (`Step 4 done (abc1234). Starting step 5.`, or the failure line), no
  narration of spawn/wait/classify/`Done:`/commit, the progress line the only
  status line on a forced mid-step turn, relayed questions,
  spawn-relay lines and the one-line `Follow-up: <item>` printed when a
  follow-up arises mid-run (`follow-ups-resolve` § DURING A RUNBOOK RUN) never
  suppressed — with the **closing report as the record of
  the run**, printed the same at completion, at a bound, at the end branch
  and at a failure halt; a parked step's question under its handle is never
  suppressed, like a relayed block; nothing extra read for it; no opt-out
  flag. THE CLOSING
  REPORT: the same two groups `/task-implement` closes in. **For the record**:
  one line per executed step in list order,
  `<step n> — <outcome, commit sha and diffstat> — <what changed in one line;
  decision or wrong premise flagged; questions relayed and their answers>`,
  then any run-level deviation on one line; each drawn from the `Done:` line
  and the step report already in hand. **Follow-ups** (numbered `1.`/`2.`/…, any length — the reply handle,
  restarting at 1 per report, a number naming a parked step's question being
  its answer): the feature completion
  candidates the step reports named plus one flip question asked once after
  the run, a failed step with its reason, a step left `[~]` to resume, every
  step left `[P]` with its question verbatim and the steps waiting on it, the
  steps outside the range / `--steps` count / never started, and what
  `/follow-ups`' rules yield applied to the run's reading, de-duplicated by
  action with the command form kept. An empty group prints `none`. When the user
  resolved or approved follow-ups mid-run, the group is that working list in
  its two-section shape (Approved, then Awaiting approval, the run's own items
  folded into the second), and after the report the approved items execute
  under `follow-ups-resolve` — conversation after the run, so no commit and no
  status flip of the report's own; a `FEATURES.md` flip is a delegated item.
  **Commit convention: one commit per completed step**, staging exactly the
  runbook (its `File:` path; both old and new path on the step that migrated
  it) and the index, then push; `--no-commit`/`--no-push` usual meanings.
  `[~]` is deliberately NEVER committed — its presence in a tree is the resume
  signal and the same-tree exception to one-run-per-runbook (`[RUNNING]` in the
  index blocks a second run otherwise; no lock file, no timestamp, no staleness
  heuristic); by commit time a marker is `[x]`, `[!]` or `[P]`, a parked
  step's commit its one commit for the run, an unpark a bookkeeping commit of
  its own. **The Stop-hook reply** (under COMMIT CADENCE) is the cost of that
  choice, paid down: a cloud sandbox's Stop hook exits 2 on any dirty tree, and
  an in-flight step is dirty by design, so the block lands at every step start
  and every relayed question. It cannot be cleared from inside the run — the
  harness runs the script after the model stops — but the script's own
  `stop_hook_active` recursion guard makes it **one forced turn per fire, not a
  loop**, and that turn is model-produced and so reachable by instruction. The
  rule: when the only dirty files are the runbook and the index the orchestrator
  itself just wrote, reply with the literal `stop hook ignored on runbook WIP`, no tool call, no
  explanation, and end the turn. Condition is **the orchestrator's own writes,
  never a `git status`** — it set `[~]` one step ago, so it needs no inspection,
  the avoided tool call is the bigger saving, and anything else dirty falls
  through to normal handling, which preserves the real forgotten-commit check.
  Second case, spawned mode only: while a spawned step is in flight (spawned,
  result not yet arrived) reply `stop hook ignored on subagent WIP` whatever is
  dirty; `--inline` keeps the runbook-WIP case alone. `task-engine`'s
  `tree.md` itself knows nothing of runbooks.
  Lives in THIS body, not a global `claude-md`: `Stop` fires for the main
  session (a subagent's is `SubagentStop`), which is the orchestrator holding
  this skill, so it costs zero resident tokens in every non-runbook session.
  Hard contracts (the reads/writes,
  does-no-work and subagent-result ones are **default-mode contracts**; `--inline`
  is their one opt-in exception, executing every selected step in the session
  itself, refused beside `--relay-spawns` or `--model` — see
  `.claude/domain/features/runbook-inline.md`): steps are **always sequential** (never parallel,
  even when declared independent — one question stream, and two agents would
  race on `Done:` lines); it **writes exactly two files** and does none of the
  work itself; **no step is ticked before its subagent's result arrives**; it
  reads only `CLAUDE.md`, the runbook and the index — **never a step's task
  body or named document, not even to compose the prompt**, whose
  orchestrator-written parts 1–4 restate nothing the step will read itself
  (preamble = navigation instruction + runbook name + step number, plus the
  `--relay-spawns` sentence) — and **does not review** a
  step's diff or commit; **no step invokes `/runbook-run`** (nested runbooks
  refused at spawn time). `--from N`/`--to N`/`--only N` narrow selection but
  never weaken `Depends on:` — one model, not three (`--only N` **is**
  `--from N --to N`; naming `--only` beside either bound is an error, as is a
  `--to` naming a step listed above the `--from` step — nine argument errors
  in all, the last three `--attended` with `--unattended`, `--skip-parked`
  without `--unattended`, and a header `Execution policy:` value outside the
  two words). The bounds name steps
  **by id** and cut the list **at those steps' positions**, so a range is
  always the stretch of steps the run walks. Bounds are re-applied against the
  body re-read each step, so a step appended mid-run inside the range runs and
  a bound naming a step not yet in the body is not an error. Reaching a `--to` bound is **not** completion: the
  index goes back to `[PENDING]` unless the whole runbook is `[x]`.
  `--steps N` runs at most N steps **executed in this run** (a step counts once
  its result reached step 8 as `DONE`; `[x]` steps never count), composes with
  `--from` only (error beside `--to`/`--only`, or with a non-positive-integer
  value), never weakens `Depends on:`, and reaching the count stops the run
  exactly like a `--to` bound (back to `[PENDING]` unless all `[x]`). Depth
  budget stated plainly in the body: orchestrator +
  step agent leaves one confirmed level **where nesting works at all** (depth 3
  confirmed locally; a cloud subagent cannot spawn, and depth 4 was never
  probed anywhere) — with the spawn relay, a step wanting its own subagent
  needs no third level.

## Public API

- [runbook-suite.md](./runbook-suite.md) § Public API.

## Internal patterns

- [runbook-suite.md](./runbook-suite.md) § Internal patterns.

## Domain dependencies

- [runbook-suite.md](./runbook-suite.md) § Domain dependencies.

## Cross-references

- [runbook-suite.md](./runbook-suite.md) — the runbook suite's hub, and its
  family-wide cross-references.
- [runbook-run.md](./runbook-run.md) — store, reference files and
  dependencies.
- [runbook-run-loop.md](./runbook-run-loop.md) — execution policy, handles,
  ids, the step loop, parking and the spawn relay.

## When to read the source

- [runbook-suite.md](./runbook-suite.md) § When to read the source.
