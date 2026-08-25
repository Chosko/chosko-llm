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
integration in `/task-implement`, how the loop behaves in a batch run, and the
cost controls over the spawned reviewer — the `--review-model` /
`--review-effort` flags, the deterministic `auto` resolution behind their
defaults, the read budget that backs the effort axis, and the rule that the
reviewer never re-runs the tests the implementer already ran.

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
- **A reasoning-effort knob.** `--review-effort` caps what the reviewer
  *reads*, not how hard it thinks. The Agent tool exposes `model` and nothing
  else; reasoning effort comes from an agent definition, which is an asset
  kind this repo does not ship. Said plainly here rather than implied away by
  a flag name — see *Review cost controls* below.
- **Cost controls on a manual review.** `--review-model` and
  `--review-effort` are `/task-implement` flags. A hand-typed `/task-review`
  runs in the user's own session, on the model they chose; a flag that
  re-specified it would be specifying the session they are already sitting
  in. Same reasoning that settled `--rounds`.
- **Cost controls on `/task-iterate`.** It runs in the session that holds the
  tree, never as a subagent, so there is no spawn to parameterise.
- **A runbook-level review setting.** A runbook step is free text and already
  carries whatever flags its author typed; the runbook's own `Model:` header
  governs the step agent, not the reviewer that agent spawns. The runbook
  suite needs no schema change for this.

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

**Tests are never run.** `/task-review` invokes no test command, in any
mode. `/task-implement`'s tests-first sequence already ran the affected tests
and then the full suite, and the review loop only starts on a green one — so
a passing suite is an input the reviewer is handed, not a fact it re-derives.
Re-running it pays twice for the same answer and is the single largest
avoidable cost in a review. Reading test *files* as source is unchanged and
still required by the Pre-Report Gate. Where the project runs in skip-tests
mode nothing ran, the reviewer is told so, and a criterion that depends on
runtime behaviour is reported `unverifiable` — a verdict the report schema
already carries — rather than becoming a reason to run something.

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

### Review cost controls

A reviewer spawned with no `model:` inherits the parent. An Opus implementer
therefore spawns an Opus reviewer, at whatever effort the parent is running,
for every task in a batch — the loop's dominant cost, and one nothing in the
original design let the user see, let alone choose.

Two flags on `/task-implement`, each taking a name or one of two reserved
words:

```
--review-model  <name> | same | auto        default auto
--review-effort shallow | standard | deep | same | auto    default auto
```

`same` means *the implementer's*: on model it omits `model:` from the Agent
call so the child inherits the parent — the original behaviour, now
nameable rather than merely default; on effort it omits the budget block, so
the reviewer reads unbounded as it always did. Both flags require `--review`
and stop the run without it, in the shape `--rounds` already uses.

Model names pass **verbatim** to the Agent tool. There is no local allow-list:
the model roster changes faster than this repo ships, and a hardcoded list
would refuse a model that works, which is a worse failure than the tool's own
rejection of a typo. `/runbook-run --model` already behaves this way.

**The protocol lives in `task-engine`**, at
`skills/task-engine/references/review-budget.md` — the tier table, the budget
table, and the resolution rules, stated once. `/task-implement`'s
`review-rounds.md` reads it to resolve and pass; `/task-review` reads it to
honour. Neither restates it. This is the shared-phase-engine rule applied to
a rule with two consumers, and it is why `/task-review` gains
`requires: skill:task-engine`, which it does not carry today.

**`auto` is deterministic, not a judgement.** It resolves from four signals
the implementer already holds when the loop starts, costing no extra read:
lines changed and files changed from the round's own diff, the count of
acceptance-criteria bullets from the task body read in Step 1, and whether
the diff touches any non-`.md` file — the executable-surface test that
separates a prompt edit from a code change. First matching row wins:

| Tier | Fires when | model | budget |
| --- | --- | --- | --- |
| heavy | executable **and** (>= 400 lines, or >= 8 files, or >= 12 criteria) | `opus` | `deep` |
| light | not executable **and** < 150 lines **and** <= 3 files | `sonnet` | `shallow` |
| standard | everything else | `sonnet` | `standard` |

`auto` never selects `haiku`. Per-criterion verdicts are judgement work, and a
reviewer that misses a finding costs more than one that costs more. `haiku`
remains valid when named explicitly.

Resolution happens **per task, not per run** — each task's own diff decides —
which is what keeps a batch O(1): the parent passes two strings through and
each implementor measures its own work.

**The budget is a table of permissions, not an adjective.** Two classes of
read, treated differently:

The **navigation layer is never counted and is permitted in full at every
tier**: `CLAUDE.md` and its chain, `.claude/context/INDEX.md` and the rows for
the files in the diff, the task body, and the feature document named by the
task's `Feature:` line. Those reads exist precisely to make source reads
unnecessary; metering them would push a capped reviewer past the index and
into source, which is the expensive path. Charging for the cheap answer to
"what do I need to read" inverts the incentive the context layer was built to
create.

**Source and test files beyond the diff are counted** — distinct files, not
reads; re-opening a counted file is free.

| | shallow | standard | deep |
| --- | --- | --- | --- |
| Navigation layer | full, uncounted | full, uncounted | full, uncounted |
| Source/test files beyond the diff | 0 | 15 | unbounded |
| Whole-file reads | no — hunks plus 40 lines of context | yes | yes |
| Callers and imports of changed symbols | no | direct only | transitive |
| Tests covering the diff | only those in the diff | yes | yes |
| Per-criterion verdicts | from the diff alone; the rest `unverifiable` | full | full |
| Test command | never | never | never |

shallow sits at zero because that is its whole identity, and the consequence
is the design's load-bearing property: **a reviewer forbidden to read callers
answers "no" to Pre-Report Gate question 3, which the gate already says
demotes the finding one severity or drops it.** A cheap review therefore
becomes automatically more *conservative*, never more confident-and-wrong.
The budget rides the gate that already exists rather than adding a second
one, and no finding gets cheaper to assert by spending less to check it.

15 is a ceiling against a repo sweep, not a working budget — it is set not to
bind on an ordinary task. Because that is a guess, **a cap that actually binds
must be reported**: the reviewer stops investigating, reports the remaining
criteria under the gate as usual, and says in one line that the cap bound. A
silent cap cannot be retuned; a loud one produces the evidence to retune it
within a few runs.

The resolved pair is reported once per task alongside the round summary —
`Review: sonnet / standard (auto — 210 lines, 4 files, code)` — so `auto` is
auditable rather than magic.

### Integration with `/task-implement`

New flag `--review [--rounds N]`, plus `--review-model` and `--review-effort`
from *Review cost controls* above. Default off; a run without `--review`
behaves exactly as today. Placement in the existing step sequence:

```
Step 3  Implement
Step 5  Full test suite
        ── --review: loop starts here, tree uncommitted ──
        spawn /task-review as a subagent          (fresh context)
        collect structured findings
        run /task-iterate in this session          (no commit)
        repeat while blocking findings and rounds remain
        ── loop ends, tree corrected, still uncommitted ──
Step 6  Terminal status flip
Step 7  Commit and push                            (one commit, includes fixes)
```

The loop sits **before Step 6**, not between Steps 6 and 7. When it ends with
unresolved `BLOCKING` findings the run halts, and a halted run leaves the task
`[IN PROGRESS]` — which is what `/task-implement`'s failure handling already
specifies. Flipping to `[DONE]` first and halting afterwards would leave the
backlog claiming work that was never accepted.

The review runs as a **subagent** because fresh context is the mechanism, not a
detail — a reviewer that watched the code being written will rationalise it.
The iterate runs in the **main session** because it edits, and its edits must
land in the tree Step 7 commits.

The spawn prompt carries two more things than it originally did, for eight in
total: the **test-suite state** — green under the project's resolved testing
policy, or skip-tests so nothing ran — and the **budget block**, omitted
entirely when the effort resolved to `same`. The Agent call carries `model:`
unless the model resolved to `same`, in which case it is omitted and the child
inherits, as before.

**In batch mode**, `--review` propagates to each implementor subagent, which
spawns its own reviewer. The parent launcher passes the flag through and never
sees a finding. The two cost-control flags ride the same path with no
structural change: the launcher's hand-off already declares its resolved-flag
list open-ended, and because `auto` resolves per task from each task's own
diff, the parent passes two strings and measures nothing. The launcher still
never opens a task body.

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
/task-implement <args> --review --review-model sonnet    pin the reviewer's model
/task-implement <args> --review --review-model same      inherit the implementer's
/task-implement <args> --review --review-effort shallow  pin the read budget
```

Both skills need full frontmatter, `version: 0.1.0`. Root `VERSION` minor bump.
The cost-control change is a further minor on `task-review`, `task-implement`
and `task-engine`, with `/task-review` gaining `requires: skill:task-engine`.

Hard contracts:

- `/task-review` mutates nothing: no edit to a source file, test file, task
  body, `TASKS.md` status or `FEATURES.md` entry, and no `git` or `gh` command
  that changes a file, an index, a ref, a remote or a pull request. The one
  exception is the report itself — a manual run may opt into
  `.claude/reviews/<task>-R<round>.md`, and a run spawned by
  `/task-implement --review` writes nothing at all. That file is a transient
  artifact the user owns and deletes; nothing reads it back automatically.
- `/task-iterate` never invents findings; it only triages what it was given.
- Neither skill opens a PR.
- Under `--review`, exactly one commit per task.
- **`/task-review` never invokes a test command**, under any budget, any
  testing policy and either invocation path. This is part of its read-only
  contract, not a budget setting, and no tier relaxes it.
- The budget caps source and test reads only. **No tier ever caps or forbids
  the navigation layer**, and no finding is admissible that a tier's own
  limits prevented the reviewer from checking — the Pre-Report Gate resolves
  that, unchanged.
- `--review-model` and `--review-effort` require `--review`, exactly as
  `--rounds` does.

## Dependencies

- **`gh`** for PR mode only. Local and branch modes need only `git`. Absence of
  `gh` degrades to a clear error on PR input, never a silent fallback.
- **[task-implement-launcher](./task-implement-launcher.md)** — not required,
  but the batch propagation path is cleanest once the launcher change lands,
  because the flag is then part of a fixed-size handoff rather than an
  already-large one.
- **[shared-phase-engine](./shared-phase-engine.md)** — `task-engine` holds
  the review-budget protocol, so `/task-review` declares
  `requires: skill:task-engine` and installing it now pulls the engine in.
  `/task-implement` already declares it. Acceptable because `--review`'s
  availability gate already demands both skills be present; noted because it
  is a real change to what installing `task-review` alone does.
- Claude Code's built-in `/code-review`, referenced rather than reimplemented.

## Open questions

- ~~**Subagent nesting depth.**~~ **Resolved.** A subagent has the `Agent` tool
  and can spawn a child that runs and returns; probed directly on 2026-08-24.
  Batch `--review` ships. The async-return constraint this surfaced is recorded
  in the architecture section above and is binding on the implementor's body.
- ~~**What counts as "the base" in branch mode.**~~ **Resolved**, as proposed
  and as shipped: branch mode defaults to the repository's own default branch
  (`git symbolic-ref refs/remotes/origin/HEAD`, falling back to
  `git remote show origin`, then to whichever of `master` / `main` exists —
  both or neither stops and asks), and `base=<ref>` overrides it. An override
  that does not resolve stops the run rather than silently falling through to
  the default.
- **The `auto` tier thresholds are unvalidated.** 400 lines, 8 files, 12
  criteria, 150 lines, 3 files — defensible, and guesses. They live in one
  table in one file and are cheap to retune, but they decide real spend from
  the first run. The bound-cap report is the instrument for retuning the file
  cap; the tier boundaries have no equivalent signal yet, and getting one may
  be worth a follow-up.
- **`auto` as the default changes the behaviour of a shipped flag.** A run
  passing `--review` today gets an Opus reviewer; afterwards it gets Sonnet
  unless the diff is heavy. That is the point of the change, and it is still a
  behaviour change to an existing flag — it belongs in the `CHANGELOG` bullet
  in those words, and `--review-model same` is the documented way back.
- **Acceptance criteria are prose.** Task bodies write them as bullets, not as
  a structured, individually-addressable list. Per-criterion verdicts therefore
  depend on the reviewer parsing prose consistently. Tightening the task schema
  would fix this properly and is out of scope here — noted as a candidate
  follow-up.
- ~~**Does `--rounds` belong on `/task-review` too?**~~ **Decided: no**, and
  shipped that way. It is a `/task-implement` flag; `/task-review` has none. A
  manual review produces one report and the user decides what to do with it —
  the loop belongs to the run that owns the tree and the commit. Revisit only
  if the manual loop proves annoying in practice.
