# Review rounds (`--review` / `--rounds N`)

Read this when REVIEW is true — i.e. the run was invoked with `--review`.
Read it once, after ARGUMENT PARSING and before the first task starts, so
its availability gate can stop the run before any status is flipped. A run
without `--review` never opens this file and behaves exactly as it always
has: no gate, no prompt, no loop, no mention of any of it in the output.

The loop wires two other skills into the per-task workflow. `/task-review`
audits the task's own diff against that task's acceptance criteria and
returns structured findings; `/task-iterate` triages those findings, applies
what survives, and records why the rest did not. Between them a task gets
implemented, reviewed by a context that did not write it, and corrected —
without leaving the run and without gaining a second commit.

## The availability gate

Both skills must be available in this session. Before the first task, check
that `/task-review` and `/task-iterate` are both present. If either is
missing, stop the run right there — before any `[IN PROGRESS]` flip, before
any implementation — and say so:

> `--review` needs both the `task-review` and the `task-iterate` skills, and
> at least one of them is not available in this session. Install them with
> `chosko-llm add skill:task-review skill:task-iterate`, then re-run.

Name which of the two is missing when you can tell. Never silently skip the
review and run as if `--review` had not been passed: a run that reports it
implemented a task is a different claim from a run that reports it
implemented and reviewed one.

**This gate is deliberately a runtime check, not a `requires:` declaration.**
`requires:` is unconditional and resolved at install time; `--review` is
opt-in and off by default. Declaring `requires: skill:task-review,
skill:task-iterate` in SKILL.md's frontmatter would force every
`/task-implement` user to install two skills most of them never invoke, and
would change install behaviour. A gate is the right mechanism for an optional
dependency — do not "finish the job" by moving it to the frontmatter, which
carries only the unconditional `requires: skill:task-engine`.

## Where the loop sits

After Step 5 (the full test suite) and **before** Step 6 (the terminal
status flip), on the uncommitted tree.

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

Steps 6 and 7 are otherwise unchanged, and Step 7's single commit therefore
carries the review's fixes as part of the task. In skip-tests mode Steps 2,
4 and 5 are skipped as usual and the loop simply starts after Step 3.

Sitting before Step 6 rather than between 6 and 7 is deliberate. When the
loop ends with unresolved `BLOCKING` findings the run halts, and a halted
run leaves the task `[IN PROGRESS]` — which is exactly what FAILURE HANDLING
already specifies. Flipping to `[DONE]` first and halting afterwards would
leave the backlog claiming work that was never accepted.

## The review runs as a subagent, and that is the mechanism

Each round spawns `/task-review` with the Agent tool, `subagent_type:
"general-purpose"`. This is not an implementation detail to be optimised
away by a later editor: **fresh context is the whole point.** A reviewer
that watched the code being written has the author's reasoning in its
window and will rationalise what it finds; a reviewer handed only the diff
and the task body has to read the code as written. Running the review in
this session would produce a report that agrees with the implementation.

The spawn prompt carries exactly six things:

1. the repository's absolute path;
2. the task number, so `/task-review` is invoked with `task=<n>` and does
   not have to guess which task the diff implements;
3. the diff scope for this round — round 1 is the whole uncommitted diff
   (`git diff HEAD`, local mode); later rounds are only the hunks the
   previous `/task-iterate` changed, named explicitly;
4. the round number, so the findings carry `R<round>-<n>` ids;
5. from round 2 on, the previous rounds' **rejection ledger**, verbatim as
   `/task-iterate` returned it;
6. the statement that it was spawned by `/task-implement --review`, so it
   returns its structured report to the caller and writes nothing to disk.

## The spawned reviewer returns asynchronously — this is binding

**The Agent call yields an agent id immediately. The reviewer's findings
arrive later, as a separate notification, and are never the tool call's
return value.**

So each round must **wait for that notification** before it invokes
`/task-iterate`, and the run must **not reach Step 6 or Step 7 until the
final round's reviewer result has actually arrived**. Never write, predict
or summarise a result that has not arrived; if the user asks in the
meantime, say the reviewer is still running.

The reason this is stated so bluntly: the obvious way to write this loop is
to treat the spawn call's return value as the findings. A body written that
way runs `/task-iterate` on an agent id, finds nothing to triage, and
commits **unreviewed work while reporting that it reviewed it** — a failure
that is invisible in the output, because a run that reviewed nothing looks
exactly like a run that found nothing. (Probed directly on 2026-08-24.)

## Iterate runs here, never as a subagent

When the round's findings have arrived, invoke the `/task-iterate` skill in
**this** session — the one holding the working tree. Its edits have to land
in the tree Step 7 commits; a subagent's would land in the same tree but
outside this session's knowledge of what it changed.

Tell it, explicitly, in the invocation:

> You are running inside a `/task-implement --review` round; do not commit
> or push.

`/task-iterate` requires that assertion from its caller and never infers the
mode. Without it, it applies its standalone rules and commits — which is
precisely the one-commit-per-task breakage this loop is built to avoid.

Pass it the round's findings and the task number, and read back the three
things it returns: the triage summary, the rejection ledger, and the
explicit yes/no on whether any `BLOCKING` findings remain unresolved. That
last field is what the loop reads to decide whether another round is
warranted — take it as stated, never infer it from the summary above it.

## Loop control

**`N = 1` (the default).** One review, one iterate, stop. No re-review, no
gating on what the iterate left behind. This is the common case.

**`N ≥ 2`.** After the iterate, re-review and repeat, bounded by two rules
that both apply:

- the loop continues **only while `BLOCKING` findings remain unresolved** —
  a round that ends with none ends the loop, however many rounds are left;
- it stops at `N` rounds regardless.

`IMPORTANT` and `ADVISORY` findings are reported in the round that found
them and are never re-raised. Nothing in this loop blocks on an advisory
finding, and no round is spent chasing one.

**Re-review scope.** Rounds after the first review **only the hunks the
previous iterate changed**, not the whole diff again. Untouched code was
already reviewed; re-reading it re-finds advisory noise that was already
dismissed.

## Sticky rejections travel between rounds

A finding rejected in round *k* travels into round *k+1* as **binding
context** and may not be re-raised there. It may be *escalated* only on
evidence the earlier round did not have — a new caller, a test that now
fails, a line the iterate just introduced — and the escalation must name
that evidence. Restating the original claim more forcefully is not
evidence.

This is what keeps the loop from ping-ponging between a stubborn reviewer
and a compliant iterator, and **no round counter substitutes for it**: a
bound stops the argument, it does not settle it. Pass the ledger into every
later round's spawn prompt, whole.

## When the loop ends

- **No unresolved `BLOCKING` findings.** Continue to Step 6 normally. Report
  the rounds run and the triage outcome in one or two lines — the per-finding
  detail belongs to `/task-iterate`'s output, not to the run's summary.
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
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`'s
  `/task-implement` note.
- **Batch runs.** `--review` and `--rounds N` ride through to each
  implementor agent as part of the run's resolved flags; the implementor
  spawns its own reviewer. See `./delegated-runs.md`.
