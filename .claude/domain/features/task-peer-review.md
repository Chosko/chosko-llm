# Task peer review

A review-and-iterate loop for implemented work. `/task-review` audits a diff
against the task that produced it and returns structured findings;
`/task-iterate` triages those findings, applies what survives triage, and
records why the rest were rejected; `/task-implement --review` wires the two
together so a task can be implemented, reviewed by a fresh context, and
corrected without leaving the run.

## Purpose

The loop already exists — it is performed by hand. Implement a task, open a PR,
open a fresh session to review that PR, return to the implementing session to
read the comments and fix what is worth fixing. Every step works. The cost is
that it is manual, the fresh-context step depends on the human remembering why
it must be fresh, and the "fix what's worth fixing" judgement happens silently
in someone's head with no record of what was rejected or why.

Automating it naively makes it worse, not better. A reviewer that must justify
its invocation invents findings; an iterator that fixes everything it is told
converges on whatever the reviewer said last. The two rules that make this
feature work are borrowed from ECC's `code-reviewer` agent and are load-bearing:
**zero findings is a valid review**, and **a finding must cite a line and name a
concrete failure mode or it is dropped**.

## Scope and non-goals

In scope: the two commands, their three input forms, the finding schema, the
triage contract, the sticky-rejection rule, the `--review` / `--rounds`
integration in `/task-implement`, and how the loop behaves in a batch run.

Deliberately out:

- **Replacing Claude Code's built-in `/code-review`.** It reviews a diff well
  and is already installed. `/task-review` exists because it does something the
  built-in structurally cannot: check the diff **against the task's acceptance
  criteria**. Generic code review asks "is this good code"; this asks "does this
  do what task 118 said it would". Where the two overlap, defer to the built-in
  and say so rather than reimplementing it.
- **A reviewer fan-out.** ECC's `/review-pr` spawns six dimension reviewers and
  dedupes. One reviewer, one pass. Five more agents to find the same bugs is
  the token cost this repo exists to avoid.
- **Opening pull requests.** `/task-review` reads a PR; it never creates one.
  PR creation stays manual or moves to a separate feature later.
- **Blocking on findings.** Nothing in this loop refuses to finish. Advisory
  findings are reported and dropped; unresolved blocking findings after the
  last round stop the loop and hand back to the user, uncommitted.
- **Reviewing anything but a diff.** No whole-file audits, no repo sweeps.

## Architecture

Both are skills (`skills/task-review/`, `skills/task-iterate/`), not commands:
each has real branching over three input forms, a multi-step protocol, and — for
review — a reference file worth splitting out.

### `/task-review`

**Three input forms**, resolved from the argument:

| Argument | Mode | Diff source |
|---|---|---|
| *(none)* | local | `git diff HEAD` — uncommitted changes |
| a branch name | branch | `git diff <base>...<branch>` |
| a PR number or URL | pr | `gh pr diff <N>` |

PR input is sanitised before it reaches a shell, adopting ECC's `orch-review`
rule verbatim: accept a bare integer, or the trailing number of a
`https://github.com/<owner>/<repo>/pull/<N>` URL; reject anything else and
stop. The raw argument is never interpolated into a command.

**Task context.** The skill resolves the task the diff belongs to — from an
explicit `task=<n>`, from the branch name, from the PR title, or from the most
recently modified `.claude/tasks/*.md` — reads its body, and pulls out the
acceptance criteria. This is the differentiator; without it the skill has no
reason to exist alongside `/code-review`.

**The review gates**, adopted from ECC's `code-reviewer`:

- Report only findings held at **≥80% confidence**.
- **Pre-Report Gate** — four questions answered before any finding is written;
  any "no" or "unsure" downgrades or drops it: can I cite the exact line; can I
  name the concrete failure mode (input, state, bad outcome); have I read the
  callers, imports and tests; is the severity defensible.
- **Blocking findings require proof** — the snippet, the failure scenario, and
  why existing guards do not already catch it. Cannot produce all three:
  demote.
- **Zero findings is a valid review.** Stated explicitly in the skill body,
  because a reviewer under implicit pressure to produce output will produce it.

**Severity**, three tiers: `BLOCKING` (bugs, data loss, security, or an
unmet acceptance criterion), `IMPORTANT` (missing coverage, real quality
problems), `ADVISORY` (suggestions; reported once, never re-reviewed).
Acceptance-criteria failures are always BLOCKING — that is the point of reading
the task.

**Output.** Findings carry stable ids so `/task-iterate` can reference them and
rejections can stick across rounds: `R<round>-<n>`, e.g. `R1-3`. Each finding is
id, severity, `file:line`, the claim in one sentence, the failure scenario, and
a suggested fix. The report also carries a per-criterion verdict — met, not
met, or unverifiable — and a one-line overall verdict.

**Output destination** depends on how the skill was invoked:

- **Spawned by `/task-implement --review`** — structured output only, returned
  to the parent. Nothing is written to disk. The parent is the only consumer
  and a file would be state nobody reads.
- **Invoked manually** — the skill asks once: report in chat only, or also
  write to `.claude/reviews/<task>-R<round>.md`. Chat-only is the default. The
  file, if written, is a transient artifact the user owns and deletes.

### `/task-iterate`

Takes the same three input forms, plus findings from one of: the review
subagent's structured output, a `.claude/reviews/` file, or — in PR mode —
the PR's review comments read via `gh`.

**Triage is mandatory and explicit.** Every finding is assigned exactly one of:

| Verdict | Meaning | Requires |
|---|---|---|
| `fix` | valid, will be corrected now | — |
| `defer` | valid, but out of scope for this task | a follow-up task number, or a note that one should be authored |
| `reject` | not valid | a one-line reason |

This is the step currently done silently. Forcing a written verdict per finding
is the whole point: it makes "fix what's worth fixing" auditable, and it
produces the rejection ledger the next round depends on.

**Then**: apply the fixes, re-run affected tests where a suite exists, and — in
PR mode — reply on each thread acted on and resolve those addressed, leaving
rejected threads open for the human.

**Committing** differs by caller, and this is a deliberate departure worth
naming. Invoked standalone, `/task-iterate` commits and pushes its changes, as
specified. Invoked inside `/task-implement --review`, it commits nothing —
it leaves the corrected tree for `/task-implement`'s existing Step 7, so the
task still produces **exactly one commit**. Letting iterate commit inside the
run would give a task an implementation commit and a separate fix commit for
work that was never separately reviewed by a human, breaking the one-commit-per-
task contract the skill already holds.

### The loop

Controlled by `--rounds N`, default `1`.

**N = 1** — one review, one iterate, stop. No re-review. This is the default and
the common case; nothing below applies.

**N ≥ 2** — after iterate, re-review and repeat, under two constraints:

- **Severity gate.** The loop continues only while `BLOCKING` findings remain.
  `IMPORTANT` and `ADVISORY` are reported in the round that found them and are
  never re-raised.
- **Bound.** Stop at N rounds regardless. On cap-hit: stop, report unresolved
  blocking findings, leave the tree as it is, hand to the user.

**Sticky rejections.** A finding rejected in round *k* travels into round *k+1*
as binding context and **may not be re-raised**, only escalated — and only with
evidence the earlier round did not have. Without this the loop ping-pongs
between a stubborn reviewer and a compliant iterator, and no round counter
fixes that. In PR mode the rejection replies on the threads serve as the same
ledger.

**Re-review scope.** Rounds after the first review only the hunks the previous
iterate changed, not the whole diff. Re-reviewing untouched code re-finds
advisory noise already dismissed.

### Integration with `/task-implement`

New flag `--review [--rounds N]`. Default off; a run without it behaves exactly
as today. Placement in the existing step sequence:

```
Step 3  Implement
Step 5  Full test suite
        ── --review: loop starts here, tree uncommitted ──
        spawn /task-review as a subagent          (fresh context)
        collect structured findings
        run /task-iterate in this session          (no commit)
        repeat while blocking findings and rounds remain
        ── loop ends, tree corrected, still uncommitted ──
Step 7  Commit and push                            (one commit, includes fixes)
```

The review runs as a **subagent** because fresh context is the mechanism, not a
detail — a reviewer that watched the code being written will rationalise it.
The iterate runs in the **main session** because it edits, and its edits must
land in the tree Step 7 commits.

**In batch mode**, `--review` propagates to each implementor subagent, which
spawns its own reviewer. The parent launcher passes the flag through and never
sees a finding.

This nests subagents one level deeper than the skill does today —
launcher → implementor → reviewer. **That depth was verified empirically before
this document was written**: a general-purpose subagent has the `Agent` tool
available and successfully spawned a child that ran and returned. Batch
`--review` is therefore in scope for this slice.

One constraint follows from how it returns. A spawned agent comes back
**asynchronously** — the call yields an id immediately and the result arrives
later as a separate notification, not as the tool call's return value. The
implementor's body must be written to wait for its reviewer's result rather than
reading it inline, and must not proceed to Step 7 until it has arrived. A body
that assumes a synchronous return will commit unreviewed work.

`--no-commit` and `--review` compose: the loop runs, Step 7 is skipped, the
corrected tree is left uncommitted.

## Data and state

No persistent state. Findings live in the review subagent's return value, or in
a transient `.claude/reviews/` file the user opted into and owns. The rejection
ledger lives in the loop's own context for the duration of the run, and in PR
comment threads where a PR exists.

Nothing is added to `TASKS.md`, `FEATURES.md`, or `PLAN.md`. A deferred finding
becomes a task through the existing `/task-add`, not through a side channel.

## Interfaces and contracts

```
/task-review                        review uncommitted changes
/task-review <branch>               review a branch against its base
/task-review <pr-number|pr-url>     review a GitHub PR
/task-review <args> task=<n>        pin the task explicitly

/task-iterate                       triage + fix findings for uncommitted changes
/task-iterate <branch|pr>           same, for a branch or PR
/task-iterate <args> --no-push      commit without pushing

/task-implement <args> --review               review each task after implementing
/task-implement <args> --review --rounds 3    up to 3 review/iterate rounds
```

Both skills need full frontmatter, `version: 0.1.0`. Root `VERSION` minor bump.

Hard contracts:

- `/task-review` writes nothing to the working tree and runs no command that
  mutates. Read-only, always.
- `/task-iterate` never invents findings; it only triages what it was given.
- Neither skill opens a PR.
- Under `--review`, exactly one commit per task.

## Dependencies

- **`gh`** for PR mode only. Local and branch modes need only `git`. Absence of
  `gh` degrades to a clear error on PR input, never a silent fallback.
- **[task-implement-launcher](./task-implement-launcher.md)** — not required,
  but the batch propagation path is cleanest once the launcher change lands,
  because the flag is then part of a fixed-size handoff rather than an
  already-large one.
- Claude Code's built-in `/code-review`, referenced rather than reimplemented.

## Open questions

- ~~**Subagent nesting depth.**~~ **Resolved.** A subagent has the `Agent` tool
  and can spawn a child that runs and returns; probed directly on 2026-08-24.
  Batch `--review` ships. The async-return constraint this surfaced is recorded
  in the architecture section above and is binding on the implementor's body.
- **What counts as "the base" in branch mode.** `master` is the project default
  but a stacked branch wants its parent. Proposal: default to the repo's default
  branch, allow `base=<ref>`.
- **Acceptance criteria are prose.** Task bodies write them as bullets, not as
  a structured, individually-addressable list. Per-criterion verdicts therefore
  depend on the reviewer parsing prose consistently. Tightening the task schema
  would fix this properly and is out of scope here — noted as a candidate
  follow-up.
- **Does `--rounds` belong on `/task-review` too?** As specified it is a
  `/task-implement` flag. A manual `/task-review` produces one report and the
  user decides. Leaving it that way unless the manual loop proves annoying.
