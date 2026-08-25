---
name: task-review
version: 0.2.0
type: skill
description: Audit a diff against the acceptance criteria of the task that produced it and report structured findings. Three input forms — no argument reviews the uncommitted working tree, a branch name reviews that branch against the repository's default branch or an explicit base=<ref>, and a PR number or URL reviews that pull request through gh. Every finding passes a confidence gate before it is written: report only what is held at 80% confidence or better, citing a file:line and naming a concrete failure mode, with severities BLOCKING / IMPORTANT / ADVISORY and an unmet acceptance criterion always BLOCKING. The task is resolved from task=<n>, the branch name, the PR title, or the most recently modified .claude/tasks file, and an unresolvable task stops the run rather than degrading into a generic code review. A review that reports no findings is a valid, complete result. Read-only — it edits no source, test, task or status file, runs no mutating command, opens no pull request, and writes at most the opt-in .claude/reviews/<task>-R<round>.md report a manual run asked for. It also invokes no test command, in any mode, under any budget, under any testing policy and on either invocation path: a green suite is an input its caller hands it, and where the caller reports skip-tests mode it says nothing ran and reports a criterion depending on runtime behaviour as unverifiable rather than re-deriving it. A run spawned by /task-implement --review may carry a budget block naming a read tier (shallow / standard / deep); the skill honours it from task-engine's references/review-budget.md, which is why it declares requires: skill:task-engine — the navigation layer is read in full and never counted at any tier, only distinct source and test files beyond the diff count against the cap, and a cap that actually binds is reported in one line. An invocation with no budget block — a manual run, or a spawn whose effort resolved to same — reads unbounded, exactly as before.
requires: skill:task-engine
---

# /task-review
# Global skill: audit a diff against the acceptance criteria of the task that
# produced it, and report structured findings. Read-only. One reviewer, one
# pass, no fan-out.
# Usage: /task-review                        (review uncommitted changes)
#        /task-review <branch>               (review a branch against its base)
#        /task-review <branch> base=<ref>    (override the base)
#        /task-review <pr-number|pr-url>     (review a GitHub PR)
#        /task-review <args> task=<n>        (pin the task explicitly)
# Examples: /task-review
#           /task-review feature/password-auth
#           /task-review feature/password-auth base=develop
#           /task-review 214
#           /task-review https://github.com/acme/app/pull/214 task=118

GOAL
Take a diff and the task that produced it, and answer one question: **does
this do what the task said it would?** Report what fails, in a form another
agent or a human can act on — a stable id, a severity, a `file:line`, the
claim, the failure scenario, and a suggested fix — plus a verdict per
acceptance criterion and one overall verdict.

Finding nothing wrong is a correct outcome. This skill has no quota.

---

## WHY THIS EXISTS BESIDE `/code-review`

Claude Code ships `/code-review`, and it reviews a diff well. This skill is
not a replacement and does not reimplement it. The difference is the task:
generic code review asks *is this good code*; this asks *does this satisfy
task 118's acceptance criteria*. That is the only reason to run it.

So: where the two overlap — style, idiom, generic correctness sweeps — defer
to the built-in and say so in the report rather than duplicating its work.
Spend the effort here on the criteria, which nothing else checks.

---

## SUPPORTING FILES (read on demand — not up front)

The common path is the whole of this file: no argument, a working tree with
uncommitted changes, and a task resolved from `.claude/tasks/`. That path
never opens a supporting file.

| Read this file | Exactly when |
| -------------- | ------------ |
| `./remote-diffs.md` | The argument (after stripping `task=` and `base=`) is non-empty — it names a branch, a PR number, or a PR URL. |
| `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/review-budget.md` | The invocation carries a **budget block** naming a read tier. A manual run carries none, and neither does a spawn whose effort resolved to `same`. |

A local manual run loads neither. Do not read either speculatively.

---

## SHELLING OUT

This skill uses the shell **only** for read-only inspection: `git diff`,
`git log`, `git branch`, `git symbolic-ref`, `gh pr diff`, `gh pr view`,
`gh api` reads, and `gh --version`. It runs no command that changes a file,
an index, a ref, a remote, or a pull request. If a step seems to need a
mutating command, the step is wrong — stop and report instead.

A **test command is not on that list either**, mutating or not: see THE
READ-ONLY CONTRACT.

---

## ARGUMENT PARSING

Scan the argument string for two `key=value` tokens and strip whichever
appear, in any order and any position:

- `task=<n>` — pin the task explicitly. `<n>` must be a bare integer;
  anything else is an error, stop and say so.
- `base=<ref>` — override the base for branch mode. Meaningful only in
  branch mode; on a local or PR run, say it was ignored and continue.

What remains, trimmed, is the **input**:

| Input | Mode | Diff source |
| --- | --- | --- |
| *(empty)* | local | `git diff HEAD` — uncommitted changes |
| a branch name | branch | `git diff <base>...<branch>` |
| a PR number or a PR URL | pr | `gh pr diff <N>` |

Branch and PR mode are both resolved in `./remote-diffs.md`. Read it now if
the input is non-empty, and follow it for diff acquisition; then return here
for everything from RESOLVING THE TASK onward, which is identical in all
three modes.

In local mode, run `git diff HEAD`. If it is empty, there is nothing to
review: say so and stop — do not fall back to reviewing the last commit, a
branch, or the whole file set.

---

## RESOLVING THE TASK

The task's acceptance criteria are the standard the diff is measured
against. Resolve the task in this order, taking the first that yields a
`.claude/tasks/<n>.md` that exists:

1. **`task=<n>`** — explicit, always wins.
2. **The branch name** — a number in it (`feature/118-dual-llm`, `task-118`,
   `118-dual-llm`) names the task.
3. **The PR title** — pr mode only; a leading `Task <n>:` or a bare number.
4. **The most recently modified `.claude/tasks/*.md`** — the weakest signal,
   so state which file was picked and why in the report header.

If none of the four resolves, **stop**:

> I could not work out which task this diff implements. Re-run with
> `task=<n>` — reviewing a diff against nothing in particular is what
> `/code-review` already does better.

Do not proceed with a generic code review instead. Checking the diff against
a task's acceptance criteria is this skill's entire reason to exist; a run
without one would ship the weaker product under the stronger name.

Read the resolved body at `.claude/tasks/<n>.md` and extract its
**Acceptance criteria** section. Each bullet is one criterion, addressed
individually in the report. Read the body's Decisions and Hints too — a
criterion often only makes sense with the decision behind it — and read
whatever the diff touches: the callers, the imports, the tests, the project's
`CLAUDE.md` and its `.claude/context/` entries for the files in the diff.

---

## THE READ BUDGET

A run spawned by `/task-implement --review` may carry a **budget block** naming
a read tier — `shallow`, `standard` or `deep`. When it does, read
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/review-budget.md`
and honour the tier it names. That file is the single authority for what each
tier permits and **none of its tables is restated here**: read it, rather than
reconstructing it from the block or from memory.

**No budget block means no budget.** A manual run carries none, and neither
does a spawn whose effort resolved to `same`. Read unbounded, exactly as this
skill did before budgets existed. Never assume a tier that was not named.

Two rules hold at every tier, and belong here because this is where the reading
happens:

- **The navigation layer is read in full and never counted** — `CLAUDE.md` and
  its chain, `.claude/context/INDEX.md` and the rows for the files in the diff,
  the task body, and the feature document its `Feature:` line names. Only
  distinct **source and test files beyond the diff** count against the cap, and
  re-opening one already counted is free.
- **A cap that actually binds is reported.** Stop investigating, report the
  remaining criteria under the gates below exactly as usual, and say in one
  line that the cap bound and at which tier. A silent cap cannot be retuned.

Under `shallow` that cap is zero, so callers and imports cannot be read at all.
State that plainly instead of working around it: an unread caller is an honest
**no** to Pre-Report Gate question 3, and the gate below already demotes or
drops a finding on that answer. That is the intended behaviour — a cheap review
is a more conservative one, never a more confident-and-wrong one. **No second
gate is added for the budget**, and no finding becomes admissible because the
tier was too narrow to check it.

---

## THE REVIEW GATES

These are gates, not advice. Each one is a filter a finding must pass to be
written down at all.

**Confidence.** Report only findings held at **80% confidence or better**.
Below that, the finding does not go in the report — not as a hedge, not as a
question, not as an "it may be worth checking".

**The Pre-Report Gate.** Before writing any finding, answer all four:

1. Can I cite the exact line?
2. Can I name the concrete failure mode — the input, the state, and the bad
   outcome?
3. Have I read the callers, the imports and the tests?
4. Is the severity defensible?

Any **no** or **unsure** downgrades the finding one severity or drops it.
Answer the questions honestly; the gate is worthless applied retroactively to
a finding already written.

**A BLOCKING finding requires proof** — all three of:

- the snippet, quoted;
- the failure scenario, concretely;
- why the guards already in the code do not catch it.

Missing any one of the three, demote it. A BLOCKING finding that cannot show
its work is an IMPORTANT finding with confidence, at best.

**Zero findings is a valid review.** State the result plainly and stop. A
reviewer under implicit pressure to justify its invocation will invent
findings, and inventions cost more than they save — they consume an iterate
round, they train the next round to argue, and they bury the real finding
when one exists. "No findings; all criteria met" is a complete review.

---

## SEVERITY

Exactly three tiers. Do not invent a fourth, and do not qualify one.

| Severity | Covers |
| --- | --- |
| `BLOCKING` | Bugs, data loss, security holes, or an **unmet acceptance criterion**. |
| `IMPORTANT` | Missing coverage, real quality problems that are not defects. |
| `ADVISORY` | Suggestions. Reported once, in the round that found them, never re-reviewed. |

**An unmet acceptance criterion is always BLOCKING**, whatever its size.
Checking the criteria is the point of reading the task; a criterion the diff
does not satisfy is the one failure this skill exists to catch.

---

## THE REPORT

Every finding carries a stable id `R<round>-<n>` — round number, then the
finding's position in that round: `R1-1`, `R1-2`, `R2-1`. The ids are how
`/task-iterate` references a finding and how a rejection stays rejected
across rounds, so they must not be renumbered between rounds.

Each finding:

```
R1-3  BLOCKING  scripts/cmd-add.sh:142
  Claim:    <the problem, one sentence>
  Scenario: <input, state, and the bad outcome that follows>
  Fix:      <what to change; one or two sentences>
```

The report as a whole:

- a header naming the mode, the diff source, the resolved task and how it was
  resolved, and the round number;
- **a verdict per acceptance criterion** — `met`, `not met`, or
  `unverifiable` (the diff neither satisfies nor contradicts it; say what
  would settle it). Quote or paraphrase each criterion so the verdict is
  readable without the task body open;
- the findings, BLOCKING first;
- **one line of overall verdict.**

A `not met` criterion must have a BLOCKING finding pointing at it, and every
BLOCKING finding about a criterion must appear in that criterion's verdict.
The two halves of the report agree or one of them is wrong.

---

## OUTPUT DESTINATION

Branch on how this run was invoked:

- **Spawned by `/task-implement --review`** — the invocation says so, and
  supplies the round number and any previous-round context. Return the
  structured report to the caller and **write nothing to disk**. The parent
  is the only consumer; a file would be state nobody reads.
- **Invoked manually** — the round number is 1 unless the caller gave one.
  Ask once, before writing the report:

  > Report in chat only, or in chat and a file at
  > `.claude/reviews/<task>-R<round>.md`?

  Reply mapping, pinned: chat only → chat; chat and a file → file. Silence,
  an unclear answer, or EOF means **chat only** — the default. On `file`,
  create `.claude/reviews/` if it is absent and write the same report there
  as well as reporting it in chat. That file is a transient artifact the user
  owns and deletes; nothing in this repo reads it back automatically.

Ask that question exactly once per run, never per finding, and never in a
spawned run.

---

## LATER ROUNDS

A first round reviews the whole diff. When the caller supplies previous-round
context — the hunks the last `/task-iterate` changed, plus the rejection
ledger — two rules replace the default behaviour:

- **Scope.** Review **only the hunks that iterate changed**, not the whole
  diff again. Untouched code was already reviewed; re-reading it re-finds
  advisory noise that was already dismissed.
- **Sticky rejections.** A finding rejected in an earlier round **may not be
  re-raised**. It may be *escalated* only on evidence that round did not have
  — a new caller, a test that now fails, a line the iterate introduced — and
  the escalation must name that evidence. Restating the original claim more
  forcefully is not evidence.

`IMPORTANT` and `ADVISORY` findings from an earlier round are also never
re-raised; they were reported in the round that found them.

This skill has no `--rounds` flag. A manual review produces one report and
the user decides what to do with it; the loop belongs to `/task-implement`.

---

## THE READ-ONLY CONTRACT

This skill **writes nothing** except the `.claude/reviews/` report a manual
run explicitly opted into, and mutates nothing at all:

- no edit to any source file, test file, task body, `TASKS.md` status,
  `FEATURES.md` entry, or any other project document;
- no `git add`, `commit`, `checkout`, `stash`, `push`, or any other command
  that changes the repository;
- no `gh pr create`, `gh pr comment`, `gh pr review`, `gh pr merge`, or any
  other write through `gh`. Replying on PR threads is `/task-iterate`'s job.

It reads a PR; it never opens one.

**And it runs no tests.** This skill invokes **no test command** — in any mode,
under any budget, under any testing policy, and on either invocation path. No
tier relaxes it, because it is a clause of this contract rather than a budget
setting. `/task-implement` already ran the affected tests and then the full
suite, and the review loop only starts on a green one, so a passing suite is an
input the caller hands over, not a fact to re-derive; re-running it pays twice
for the same answer and is the single largest avoidable cost in a review.
Reading test **files** as source is a different thing entirely: unchanged, still
required by Pre-Report Gate question 3, and governed by the budget table.

Where the caller reports **skip-tests** mode, nothing ran. Say so, and report
any criterion that depends on runtime behaviour as `unverifiable` — the verdict
the report schema already carries — naming what would settle it. An untested
runtime is never a reason to run something.

---

DO NOT:
- Report a finding below 80% confidence, or one that failed the Pre-Report
  Gate, in any softened form.
- Manufacture a finding because the review would otherwise be empty.
- Mark a BLOCKING finding without the snippet, the scenario, and the reason
  the existing guards miss it.
- Spawn dimension reviewers, or any subagent at all. One reviewer, one pass —
  five more agents finding the same bug is the token cost this repo exists to
  avoid.
- Proceed without a resolved task, or degrade into a generic code review.
- Interpolate a raw PR argument into a shell command (see
  `./remote-diffs.md`).
- Fall back from PR mode to local or branch mode when `gh` is missing.
- Re-raise a finding an earlier round rejected.
- Edit anything, or run any mutating git or `gh` command.
- Run a test command, in any mode, under any budget, or under any testing
  policy — including to fill the gap a skip-tests run leaves.
- Admit a finding the tier's own limits prevented you from checking, or read
  past a cap instead of reporting that it bound.
- Renumber finding ids between rounds.
