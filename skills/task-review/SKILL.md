---
name: task-review
version: 0.5.1
type: skill
description: Audit a diff against the acceptance criteria of the task that produced it and report structured findings, each cited to a file:line with a BLOCKING, IMPORTANT or ADVISORY severity. Use it on an uncommitted tree, a branch or a pull request before the work is accepted; /task-implement's review rounds spawn it as a fresh-context reviewer.
requires: skill:task-engine
project-policy: vcs:branch, vcs:diff, vcs:log
---

# /task-review
# Global skill: audit a diff against the acceptance criteria of the task that
# produced it, and report structured findings. One reviewer, one pass, no
# fan-out. Every finding passes a confidence gate — 80% or better, a
# file:line and a concrete failure mode — an unmet acceptance criterion is
# always BLOCKING, and stratification in a rules document (history in the
# body, a duplicate statement, an old sentence left beside its replacement)
# is a finding; no findings is a valid, complete result. The task
# resolves from task=<n>, the branch name, the PR title or the most recently
# modified .claude/tasks file — or spec=<path> names a spec file to audit
# against instead, with no fallback — and an unresolvable task stops the run
# rather than degrading into a generic code review. Read-only — edits no
# source, test, task or status file, runs no mutating command and never a
# test command (a green suite is an input its caller hands it; in skip-tests
# mode a runtime-dependent criterion is reported unverifiable), opens no pull
# request, and writes at most the opt-in .claude/reviews/<task>-R<round>.md
# (or <spec-stem>-R<round>.md) report a manual run asked for, or the result
# file a spawned run's rules name as its return channel. A spawn from /task-implement --review may
# carry a budget block naming a read tier (shallow / standard / deep),
# honoured from task-engine's references/review-budget.md; with no block it
# reads unbounded.
# Usage: /task-review                        (review uncommitted changes)
#        /task-review <branch>               (review a branch against its base)
#        /task-review <branch> base=<ref>    (override the base)
#        /task-review <pr-number|pr-url>     (review a GitHub PR)
#        /task-review <args> task=<n>        (pin the task explicitly)
#        /task-review <args> spec=<path>     (audit against a spec file instead of a task)
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

- Finding nothing wrong is a correct outcome. This skill has no quota.
- Run as one reviewer, in one pass. Spawn no dimension reviewers and no
  subagent at all — five more agents finding the same bug is the token cost
  this repo exists to avoid.

---

## WHY THIS EXISTS BESIDE `/code-review`

- Claude Code's built-in `/code-review` asks *is this good code*; this skill
  asks *does this satisfy task 118's acceptance criteria*. It neither replaces
  nor reimplements `/code-review`.
- Where the two overlap — style, idiom, generic correctness sweeps — defer to
  the built-in and say so in the report instead of duplicating its work.
- Spend the effort on the criteria, which nothing else checks.

---

## SUPPORTING FILES (read on demand — not up front)

The common path — no argument, a working tree with uncommitted changes, a
task resolved from `.claude/tasks/` — is the whole of this file and opens no
supporting file.

| Read this file | Exactly when |
| -------------- | ------------ |
| `./remote-diffs.md` | The argument (after stripping `task=`, `spec=` and `base=`) is non-empty — it names a branch, a PR number, or a PR URL. |
| `../task-engine/references/review-budget.md` | The invocation carries a **budget block** naming a read tier. A manual run carries none, and neither does a spawn whose effort resolved to `same`. |

A local manual run loads neither. Do not read either speculatively.

---

## SHELLING OUT

- Use the shell **only** for read-only inspection: `git diff`, `git log`,
  `git branch`, `git symbolic-ref`, `gh pr diff`, `gh pr view`, `gh api`
  reads, and `gh --version`.
- Run no command that changes a file, an index, a ref, a remote, or a pull
  request. If a step seems to need a mutating command, the step is wrong —
  stop and report instead.
- A **test command is not on that list either**, mutating or not: see THE
  READ-ONLY CONTRACT.

---

## ARGUMENT PARSING

1. Strip whichever of these three `key=value` tokens appear, in any order and
   any position:
   - `task=<n>` — pin the task explicitly. `<n>` must be a bare integer;
     anything else is an error: stop and say so.
   - `spec=<path>` — audit against a spec file instead of a task body
     (RESOLVING THE TASK). `task=` and `spec=` together stop the run with:
     `task= and spec= cannot be combined. Pick one.`
   - `base=<ref>` — override the base for branch mode. Meaningful only in
     branch mode; on a local or PR run, say it was ignored and continue.
2. What remains, trimmed, is the **input**. Pick the mode from it:

   | Input | Mode | Diff source |
   | --- | --- | --- |
   | *(empty)* | local | `git diff HEAD` — uncommitted changes |
   | a branch name | branch | `git diff <base>...<branch>` |
   | a PR number or a PR URL | pr | `gh pr diff <N>` |

3. Acquire the diff:
   - **Non-empty input (branch or PR mode):** read `./remote-diffs.md` now
     and follow it for diff acquisition; then return here for everything
     from RESOLVING THE TASK onward, which is identical in all three modes.
   - **Local mode:** run `git diff HEAD`. If it is empty, there is nothing to
     review: say so and stop. Do not fall back to reviewing the last commit,
     a branch, or the whole file set.

---

## RESOLVING THE TASK

The task's acceptance criteria are the standard the diff is measured against.

1. Resolve the task in this order, taking the first that yields a task body
   at `.claude/tasks/<n>.md`, or a spec file, that exists:
   1. **`task=<n>` or `spec=<path>`** — explicit, always wins. A `spec=` run
      reads that file in place of a task body and never falls back to the
      steps below: a path that does not exist stops the run with
      `No spec file at <path>.`
   2. **The branch name** — a number in it (`feature/118-dual-llm`,
      `task-118`, `118-dual-llm`) names the task.
   3. **The PR title** — pr mode only; a leading `Task <n>:` or a bare number.
   4. **The most recently modified `.claude/tasks/*.md`** — the weakest
      signal, so state which file was picked and why in the report header.
      Exclude `.claude/tasks/archive/` from the search: an archived task is
      terminal, per
      `../task-engine/references/resolution.md`
      § *The archive*.
2. If none of the four resolves, **stop**:

   > I could not work out which task this diff implements. Re-run with
   > `task=<n>` — reviewing a diff against nothing in particular is what
   > `/code-review` already does better.

   Do not proceed with a generic code review instead: a run without a task's
   acceptance criteria would ship the weaker product under the stronger name.
3. Read the resolved body at `.claude/tasks/<n>.md` — or the spec file — and
   extract its **Acceptance criteria** section. Each bullet is one criterion,
   addressed individually in the report.
   - A spec carries the same `## Goal`, `## Acceptance criteria`,
     `## Decisions` and `## Hints` sections as a task body and is read
     exactly as one. It has no summary block, so skip any lookup that needs
     one — the feature document a `Feature:` line names.
4. Read the body's Decisions and Hints too — a criterion often only makes
   sense with the decision behind it.
5. Subject to THE READ BUDGET below, read whatever the diff touches: the
   callers, the imports, the tests, the project's `CLAUDE.md` and its
   `.claude/context/` entries for the files in the diff. The navigation layer
   in that list is never capped; the callers, imports and tests are, and
   under `shallow` the cap on them is zero.

---

## THE READ BUDGET

- A run spawned by `/task-implement --review` may carry a **budget block**
  naming a read tier — `shallow`, `standard` or `deep`. When it does, read
  `../task-engine/references/review-budget.md`
  and honour the tier it names. That file is the single authority for what
  each tier permits and **none of its tables is restated here**: read it
  rather than reconstructing it from the block or from memory.
- **No budget block means no budget.** A manual run carries none, and neither
  does a spawn whose effort resolved to `same`. Read unbounded. Never assume a
  tier that was not named.

Two rules hold at every tier:

- **The navigation layer is read in full and never counted** — `CLAUDE.md` and
  its chain, `.claude/context/INDEX.md` and the rows for the files in the
  diff, the task body, and the feature document its `Feature:` line names.
  Only distinct **source and test files beyond the diff** count against the
  cap, and re-opening one already counted is free.
- **A cap that actually binds is reported.** Stop investigating, report the
  remaining criteria under the gates below exactly as usual, and say in one
  line that the cap bound and at which tier. A silent cap cannot be retuned.

Under `shallow` that cap is zero, so callers and imports cannot be read at
all:

- State that plainly instead of working around it. An unread caller is an
  honest **no** to Pre-Report Gate question 3, and the gate below already
  demotes or drops a finding on that answer — a cheap review is a more
  conservative one, never a more confident-and-wrong one.
- **Add no second gate for the budget.** No finding becomes admissible
  because the tier was too narrow to check it.

---

## THE REVIEW GATES

These are gates, not advice: a finding must pass each one to be written down
at all.

**Confidence.** Report only findings held at **80% confidence or better**.
Below that, leave the finding out of the report — not as a hedge, not as a
question, not as an "it may be worth checking".

**The Pre-Report Gate.** Before writing any finding, answer all four:

1. Can I cite the exact line?
2. Can I name the concrete failure mode — the input, the state, and the bad
   outcome?
3. Have I read the callers, the imports and the tests?
4. Is the severity defensible?

- Any **no** or **unsure** downgrades the finding one severity or drops it.
- Answer the questions honestly, before writing; the gate is worthless
  applied retroactively to a finding already written.

**A BLOCKING finding requires proof** — all three of:

- the snippet, quoted;
- the failure scenario, concretely;
- why the guards already in the code do not catch it.

Missing any one of the three, demote it: a BLOCKING finding that cannot show
its work is an IMPORTANT finding with confidence, at best.

**Zero findings is a valid review.** State the result plainly and stop. Never
manufacture a finding because the review would otherwise be empty: invented
findings consume an iterate round, train the next round to argue, and bury the
real finding when one exists. "No findings; all criteria met" is a complete
review.

---

## SEVERITY

Use exactly three tiers. Do not invent a fourth, and do not qualify one.

| Severity | Covers |
| --- | --- |
| `BLOCKING` | Bugs, data loss, security holes, or an **unmet acceptance criterion**. |
| `IMPORTANT` | Missing coverage, real quality problems that are not defects. |
| `ADVISORY` | Suggestions. Reported once, in the round that found them, never re-reviewed. |

- **An unmet acceptance criterion is always BLOCKING**, whatever its size: it
  is the one failure this skill exists to catch.
- **Stratification is a finding.** In a diff that edits a rules document — a
  `CLAUDE.md`, a command or skill body, a feature document, a context file —
  report, `IMPORTANT` by default and citing both lines when there are two:
  - a sentence carrying history ("previously", "no longer", a date or task id
    as provenance);
  - a statement already made elsewhere in the same document or in a file it
    cites;
  - an old sentence left standing beside the new one that supersedes it.

  The rule it enforces is `claude-md:editing-discipline`, in the project's
  `CLAUDE.md`. The size of a diff is never a finding: a large diff is not
  stratified, and a small one is not clean.
- **An untraceable documentation edit is a finding.** Every edit the diff
  makes to a documentation or design file traces to the task: the body's
  criteria, a design change its `## Decisions` records as agreed, or a
  consequential edit — a passage brought into agreement with the approved
  change, no meaning added. Report an edit that introduces a decision the
  task never approved, in a file another command owns or not, as
  `IMPORTANT` by default — `BLOCKING` where it also leaves an acceptance
  criterion unmet — naming the sentence and what it decides. Presented as a
  consequence, it is still the finding.

---

## THE REPORT

Give every finding a stable id `R<round>-<n>` — round number, then the
finding's position in that round: `R1-1`, `R1-2`, `R2-1`. `/task-iterate`
references findings by these ids and keeps a rejection rejected across rounds
by them, so never renumber them between rounds.

Each finding:

```
R1-3  BLOCKING  scripts/cmd-add.sh:142
  Claim:    <the problem, one sentence>
  Scenario: <input, state, and the bad outcome that follows>
  Fix:      <what to change; one or two sentences>
```

The report as a whole:

- A header naming the mode, the diff source, the resolved task (or spec) and
  how it was resolved, and the round number.
- **A verdict per acceptance criterion** — `met`, `not met`, or
  `unverifiable` (the diff neither satisfies nor contradicts it; say what
  would settle it). Quote or paraphrase each criterion so the verdict is
  readable without the task body open.
- The findings, BLOCKING first.
- **One line of overall verdict.**
- A closing section in two groups, in this order:
  - **For the record** — one line per item,
    `<what deviated> — <why> — <resolved by whom>`: a cap that bound, a
    wrong cross-reference in the body, a guard's pre-existing noise.
  - **Follow-ups** — what the caller must decide, an `unverifiable`
    criterion and what would settle it among them — numbered `1.`, `2.`, …,
    each at whatever length it needs. The number is the handle the caller
    replies with: it starts at 1 in every report, carries no meaning beyond
    that, and a single item is still numbered.

  An empty group prints its heading and `none`. The heading and order are
  the run-closing skills' own, but this read-only skill reads a diff, not a
  session, so do not apply `/follow-ups`' rules to fill the group.

Keep the two halves consistent: a `not met` criterion must have a BLOCKING
finding pointing at it, and every BLOCKING finding about a criterion must
appear in that criterion's verdict. If they disagree, one of them is wrong.

---

## OUTPUT DESTINATION

Branch on how this run was invoked:

- **Spawned by `/task-implement --review`** — the invocation says so, and
  supplies the round number and any previous-round context.
  - Return the structured report to the caller through the return channel
    the run's rules name, and **write nothing else to disk**.
  - Where those rules name a result file — a relay child under
    `/runbook-run`'s `RELAY CHILD RULES` — writing the report there is how it
    is returned; otherwise the channel is the reply.
  - Never ask the file question below.
- **Invoked manually** — the round number is 1 unless the caller gave one.
  - Ask once per run (never per finding), before writing the report:

    > Report in chat only, or in chat and a file at
    > `.claude/reviews/<task>-R<round>.md`?

  - On a `spec=` run the file is `.claude/reviews/<spec-stem>-R<round>.md`,
    `<spec-stem>` being the spec's filename without its extension.
  - Reply mapping, pinned: chat only → chat; chat and a file → file. Silence,
    an unclear answer, or EOF means **chat only** — the default.
  - On `file`, create `.claude/reviews/` if it is absent and write the same
    report there as well as reporting it in chat. That file is a transient
    artifact the user owns and deletes; nothing in this repo reads it back
    automatically.

---

## LATER ROUNDS

A first round reviews the whole diff. When the caller supplies previous-round
context — the hunks the last `/task-iterate` changed, plus the rejection
ledger — these rules replace the default behaviour:

- **Scope.** Review **only the hunks that iterate changed**, not the whole
  diff again: untouched code was already reviewed.
- **Sticky rejections.** Never re-raise a finding rejected in an earlier
  round. Escalate it only on evidence that round did not have — a new caller,
  a test that now fails, a line the iterate introduced — and name that
  evidence in the escalation. Restating the original claim more forcefully is
  not evidence.
- Never re-raise `IMPORTANT` and `ADVISORY` findings from an earlier round
  either; they were reported in the round that found them.

This skill has no `--rounds` flag. A manual review produces one report and
the user decides what to do with it; the loop belongs to `/task-implement`.

---

## THE READ-ONLY CONTRACT

Write nothing except the `.claude/reviews/` report a manual run explicitly
opted into, or the result file a spawned run's rules name as its return
channel (OUTPUT DESTINATION). Mutate nothing at all:

- no edit to any source file, test file, task body, `TASKS.md` status,
  `FEATURES.md` entry, or any other project document;
- no `git add`, `commit`, `checkout`, `stash`, `push`, or any other command
  that changes the repository;
- no `gh pr create`, `gh pr comment`, `gh pr review`, `gh pr merge`, or any
  other write through `gh`. Replying on PR threads is `/task-iterate`'s job.
  Read a PR; never open one.

**Run no tests.** Invoke **no test command** — in any mode, under any budget,
under any testing policy, and on either invocation path. No tier relaxes this:
it is a clause of this contract, not a budget setting.

- `/task-implement` already ran the affected tests and then the full suite,
  and the review loop only starts on a green one: treat a passing suite as an
  input the caller hands over, not a fact to re-derive.
- Reading test **files** as source is different and stays required by
  Pre-Report Gate question 3, governed by the budget table.
- Where the caller reports **skip-tests** mode, nothing ran. Say so, and
  report any criterion that depends on runtime behaviour as `unverifiable`,
  naming what would settle it. An untested runtime is never a reason to run
  something.
