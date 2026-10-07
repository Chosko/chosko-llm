# Review rounds (`--review` / `--rounds N`)

- Read this when REVIEW is true — the run was invoked with `--review`.
- Read it once, after ARGUMENT PARSING and before the first task starts, so
  its availability gate can stop the run before any status is flipped.
- A run without `--review` never opens this file and has no gate, no
  prompt, no loop, and no mention of any of it in the output.
- The loop wires two skills into the per-task workflow: `/task-review`
  audits the task's own diff against its acceptance criteria and returns
  structured findings; `/task-iterate` triages them, applies what survives,
  and records why the rest did not — all without a second commit.

## The availability gate

- Before the first task, check that `/task-review` and `/task-iterate` are
  both available in this session.
- If either is missing, stop the run right there — before any
  `[IN PROGRESS]` flip, before any implementation — and say so:

> `--review` needs both the `task-review` and the `task-iterate` skills, and
> at least one of them is not available in this session. Install them with
> `chosko-llm add skill:task-review skill:task-iterate`, then re-run.

- Name which of the two is missing when you can tell.
- Never silently skip the review and run as if `--review` had not been
  passed: a run that reports it implemented a task is a different claim
  from a run that reports it implemented and reviewed one.
- **Keep this gate a runtime check, not a `requires:` declaration.**
  `requires:` is unconditional and resolved at install time; `--review` is
  opt-in and off by default, so declaring `requires: skill:task-review,
  skill:task-iterate` in SKILL.md's frontmatter would force every
  `/task-implement` user to install two skills most of them never invoke.
  Do not move it to the frontmatter, which carries only the unconditional
  `requires: skill:task-engine`.

## Where the loop sits

After Step 5 (the full test suite,
`../task-engine/references/tests-first.md`) and **before** Step 6 (the
terminal status flip), on the uncommitted tree.

```
Step 3  Implement
Step 5  Full test suite
        ── loop starts here, tree uncommitted ──
        spawn /task-review as a subagent           (fresh context)
        wait for its result to arrive
        run /task-iterate in this session          (no commit)
        repeat while blocking findings and rounds remain
        ── loop ends, tree corrected, still uncommitted ──
Step 6  Terminal status flip
Step 7  Commit and push                            (one commit, includes the fixes)
```

- Steps 6 and 7 are otherwise unchanged, so Step 7's single commit carries
  the review's fixes as part of the task.
- In skip-tests mode Steps 2, 4 and 5 are skipped as usual and the loop
  starts after Step 3.
- The loop sits before Step 6, not between 6 and 7: a loop that ends with
  unresolved `BLOCKING` findings halts the run with the task
  `[IN PROGRESS]`, per FAILURE HANDLING. Flipping to `[DONE]` first would
  leave the backlog claiming work that was never accepted.

## Resolving the reviewer's model and read budget

- ARGUMENT PARSING hands this loop two strings, REVIEW_MODEL and
  REVIEW_EFFORT, each a name, `same`, or `auto` — the default for both.
- Their values, the deterministic `auto` tier table behind those defaults,
  the read budget behind the effort axis, and the reporting rules that keep
  both auditable are `../task-engine/references/review-budget.md`. Read it
  once, here, at the same point this file is read. **It is the single
  authority and neither table is restated here** — resolve against the
  file, not against a remembered copy of it.
- Resolve the pair **per task, at the top of each round**, never once for
  the run. `auto` costs no extra read — its four signals are already in
  hand when the loop starts:
  - lines changed and files changed from *the round's own diff* (round 1's
    whole uncommitted diff, a later round's narrower re-review scope);
  - the count of acceptance-criteria bullets in the task body read in
    Step 1;
  - whether that diff touches any non-`.md` file.
  Measure the diff, never the repository.
- Take a value that is not `auto` as given: `same` carries the meaning
  `review-budget.md` gives it on each axis, and use any other model name
  verbatim without checking it against a list.
- The two resolved values feed exactly two places, both below: the model
  decides whether the Agent call carries `model:`, and the effort decides
  whether the spawn prompt carries a budget block.

## The review runs as a subagent, and that is the mechanism

- Each round spawns `/task-review` with the Agent tool, `subagent_type:
  "general-purpose"`. Never optimise this away or run the review in this
  session: **fresh context is the whole point** — a reviewer handed only
  the diff and the task body has to read the code as written.

The spawn prompt carries exactly eight things:

1. the repository's absolute path;
2. the task number, so `/task-review` is invoked with `task=<n>` and does
   not have to guess which task the diff implements;
3. the diff scope for this round — round 1 is the whole uncommitted diff
   (`git diff HEAD`, local mode); later rounds are only the hunks the
   previous `/task-iterate` changed, named explicitly;
4. the round number, so the findings carry `R<round>-<n>` ids;
5. from round 2 on, the previous rounds' **rejection ledger**, verbatim as
   `/task-iterate` returned it;
6. the statement that it was spawned by `/task-implement --review`, which
   selects `/task-review`'s spawned output destination;
7. **the test-suite state** — that the full suite is green under the
   project's resolved testing policy, or that the run is in skip-tests mode
   and nothing ran. The reviewer runs no test command under any budget, so
   it is handed this rather than re-deriving it; in skip-tests mode it is
   also what tells the reviewer to report a criterion that depends on
   runtime behaviour as `unverifiable` rather than treating the gap as a
   reason to run something;
8. **the budget block** — the resolved effort level and the reads that level
   permits, as `review-budget.md` states them. **Omitted entirely when the
   effort resolved to `same`**: no block, no mention of budgets, and the
   reviewer reads unbounded.

- The **Agent call** carries `model:` set to the resolved model — the one
  place REVIEW_MODEL is consumed. **Unless it resolved to `same`, in which
  case `model:` is omitted from the call** and the child inherits the
  implementer's model.
- `subagent_type: "general-purpose"` is unchanged either way.

## The spawned reviewer returns asynchronously — this is binding

- **The Agent call yields an agent id immediately. The reviewer's findings
  arrive later, as a separate notification, and are never the tool call's
  return value.**
- Each round must **wait for that notification** before it invokes
  `/task-iterate`, and the run must **not reach Step 6 or Step 7 until the
  final round's reviewer result has actually arrived**.
- Never write, predict or summarise a result that has not arrived; if the
  user asks in the meantime, say the reviewer is still running.
- Never treat the spawn call's return value as the findings: that runs
  `/task-iterate` on an agent id and commits **unreviewed work while
  reporting that it reviewed it**, invisibly.

## Iterate runs here, never as a subagent

- When the round's findings have arrived, invoke the `/task-iterate` skill
  in **this** session — the one holding the working tree. Its edits have to
  land in the tree Step 7 commits, within this session's knowledge of what
  changed.
- Tell it, explicitly, in the invocation:

> You are running inside a `/task-implement --review` round; do not commit
> or push.

- `/task-iterate` requires that assertion from its caller and never infers
  the mode. Without it, it applies its standalone rules and commits,
  breaking one-commit-per-task.
- Pass it the round's findings and the task number, and read back the three
  things it returns: the triage summary, the rejection ledger, and the
  explicit yes/no on whether any `BLOCKING` findings remain unresolved.
- That last field is what the loop reads to decide whether another round is
  warranted — take it as stated, never infer it from the summary above it.

## Loop control

- **`N = 1` (the default).** One review, one iterate, stop. No re-review, no
  gating on what the iterate left behind.
- **`N ≥ 2`.** After the iterate, re-review and repeat, bounded by two rules
  that both apply:
  - the loop continues **only while `BLOCKING` findings remain
    unresolved** — a round that ends with none ends the loop, however many
    rounds are left;
  - it stops at `N` rounds regardless.
- `IMPORTANT` and `ADVISORY` findings are reported in the round that found
  them and are never re-raised. Nothing in this loop blocks on an advisory
  finding, and no round is spent chasing one.
- **Re-review scope.** Rounds after the first review **only the hunks the
  previous iterate changed**, not the whole diff again: untouched code was
  already reviewed.

## Sticky rejections travel between rounds

- A finding rejected in round *k* travels into round *k+1* as **binding
  context** and may not be re-raised there.
- It may be *escalated* only on evidence the earlier round did not have — a
  new caller, a test that now fails, a line the iterate just introduced —
  and the escalation must name that evidence. Restating the original claim
  more forcefully is not evidence.
- **No round counter substitutes for this rule**: a bound stops the
  argument, it does not settle it.
- Pass the ledger into every later round's spawn prompt, whole.

## Reporting the resolved pair

- Report the pair **once per task**, as its own *For the record* line in
  the closing report, in the shape `review-budget.md` documents rather than
  that group's fixed one:

```
Review: sonnet / standard (auto — 210 lines, 4 files, code)
```

- The parenthetical carries the evidence for whichever axis resolved from
  `auto` — the measurements that picked the tier.
- Report an axis the user pinned as the value they gave, with no invented
  justification behind it.
- One line, once, whatever the round count; the per-finding detail still
  belongs to `/task-iterate`'s output.

## When the loop ends

- **No unresolved `BLOCKING` findings.** Continue to Step 6 normally. The
  rounds run and the triage outcome become one *For the record* line in the
  closing report — the per-finding detail belongs to `/task-iterate`'s
  output, not to the run's summary.
- **Unresolved `BLOCKING` findings after the last round** (the cap was hit,
  or the last round's iterate deferred, rejected or abandoned a blocking
  finding). Stop the entire run per FAILURE HANDLING: report the unresolved
  findings by id with their claims, leave the working tree exactly as it is
  (uncommitted), leave the task `[IN PROGRESS]`, and hand back to the user.
  Do **not** flip to `[DONE]` and do **not** commit. In a multi-task run, do
  not start the next task.

## Composing with the other flags

- **`--no-commit`.** The loop runs in full and Step 7 is skipped: the
  corrected tree is left uncommitted along with the rest of the run's work.
- **`--no-push`.** No interaction — the task commits as usual, including the
  fixes, and is not pushed.
- **Commit count.** Unchanged by this loop. How many commits a reviewed task
  produces, and why `/task-iterate` commits nothing inside a round, are
  `../task-engine/references/commit.md`'s
  `/task-implement` note.
- **Batch runs.** `--review`, `--rounds N`, `--review-model` and
  `--review-effort` ride through to each implementor agent as part of the
  run's resolved flags; the implementor spawns its own reviewer and resolves
  the pair from its own task's diff. The parent passes two strings and
  measures nothing. See `./delegated-runs.md`.
