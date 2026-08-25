---
name: task-iterate
version: 0.1.0
type: skill
description: Triage review findings it did not produce, apply the ones that survive triage, and record why the rest did not. Three input forms — no argument iterates on the uncommitted working tree, a branch name on that branch against the repository's default branch or an explicit base=<ref>, and a PR number or URL on that pull request through gh. Findings come from exactly one of the review subagent's structured output, a .claude/reviews/<task>-R<n>.md file, or the PR's review comments; the skill never invents a finding and never adds one of its own. Triage is mandatory and explicit — every finding gets exactly one of fix, defer or reject, defer requires a follow-up task number or a note that one should be authored, reject requires a one-line reason, and the full verdict table is written before any edit is made. Committing depends on the caller and the caller asserts it: standalone it commits and pushes like every other auto-committing feature, accepting --no-commit and --no-push, while inside a /task-implement --review round it commits nothing and leaves the corrected tree for that run's Step 7 so the task still produces exactly one commit. It returns a triage summary, a sticky rejection ledger for the next round, and whether any BLOCKING findings remain unresolved. It never opens a pull request, in any mode.
---

# /task-iterate
# Global skill: triage review findings, apply what survives triage, and record
# why the rest did not. Fixes only what it was handed — it never finds anything
# itself.
# Usage: /task-iterate                        (iterate on uncommitted changes)
#        /task-iterate <branch>               (iterate on a branch)
#        /task-iterate <branch> base=<ref>    (override the base)
#        /task-iterate <pr-number|pr-url>     (iterate on a GitHub PR)
#        /task-iterate <args> task=<n>        (pin the task explicitly)
#        /task-iterate <args> --no-commit     (apply the fixes, commit nothing)
#        /task-iterate <args> --no-push       (commit as usual, skip the push)
# Examples: /task-iterate
#           /task-iterate feature/password-auth
#           /task-iterate 214
#           /task-iterate https://github.com/acme/app/pull/214 task=118

GOAL
Take a set of findings someone else produced and answer, for each one and in
writing: **fix it, defer it, or reject it — and why?** Then apply the fixes,
leave the rejections on the record, and hand back a summary the caller can act
on.

The triage is the product. Applying fixes is the easy half.

---

## WHY THE TRIAGE IS MANDATORY

This step is normally done silently, in someone's head: a reviewer lists
things, the implementer quietly fixes some of them, and nothing records what
was dismissed or why. Forcing a written verdict per finding is the whole
point of this skill. It makes "fix what's worth fixing" auditable, and it
produces the **rejection ledger** the next review round depends on.

An iterator that fixes everything it is told converges on whatever the
reviewer said last. Triage is therefore mandatory rather than advisory, and
`reject` is a first-class outcome that needs a reason, not an apology.

---

## THIS SKILL NEVER INVENTS A FINDING

Every finding triaged here arrived from somewhere else. The skill does not
review the diff, does not sweep for problems the reviewer missed, and does not
add a finding of its own — not as a bonus, not as an "also noticed", not
folded into another finding's fix.

If the input carries no findings, say so and stop. That is a complete run: the
reviewer found nothing, so there is nothing to triage.

Reviewing is `/task-review`'s job. A skill that both finds and fixes is its own
reviewer, and grades its own work.

---

## NO SUPPORTING FILES

Everything this skill does is in this file, PR mode included. Do not look for a
sibling reference file and do not read one from another skill's folder — each
skill installs as a self-contained folder, so a path outside this one does not
resolve on an installed machine.

---

## SHELLING OUT

Unlike `/task-review`, this skill **does** mutate — that is what it is for. It
may run: read-only inspection (`git diff`, `git log`, `git branch`,
`git symbolic-ref`, `git rev-parse`, `gh pr diff`, `gh pr view`, `gh api`
reads, `gh --version`), the project's test command, and — in standalone mode
only — `git add` on explicit paths, `git commit`, `git pull` and `git push`.

Two things stay forbidden in every mode: `gh pr create` (this skill never opens
a pull request) and any history-rewriting or hook-skipping git flag
(`--amend`, `--no-verify`, `--no-gpg-sign`, `push --force`).

---

## ARGUMENT PARSING

Scan the argument string and strip these tokens, in any order and any position:

- `task=<n>` — pin the task explicitly. `<n>` must be a bare integer; anything
  else is an error, stop and say so.
- `base=<ref>` — override the base for branch mode. Meaningful only in branch
  mode; on a local or PR run, say it was ignored and continue.
- `--no-commit` — apply the fixes and commit nothing. Implies `--no-push`.
- `--no-push` — commit as usual, skip the pull-at-start and the re-sync/push.

`--commit` and `--no-commit` are mutually exclusive — if both appear, stop
with: `--commit and --no-commit cannot be combined. Pick one.`

What remains, trimmed, is the **input**:

| Input | Mode | What is iterated on |
| --- | --- | --- |
| *(empty)* | local | the uncommitted working tree — `git diff HEAD` |
| a branch name | branch | that branch's own work — `git diff <base>...<branch>` |
| a PR number or a PR URL | pr | that pull request — `gh pr diff <N>` |

In every mode the fixes are applied to the **working tree in front of you**.
Branch mode assumes that branch is checked out; if it is not, say so and stop
rather than checking it out — switching branches under a user is not this
skill's call.

### Branch mode — resolving `<base>`

First hit wins:

1. **`base=<ref>` from the argument.** Verify it resolves
   (`git rev-parse --verify`); if it does not, stop and say so rather than
   silently falling through to the default.
2. **The repository's default branch** —
   `git symbolic-ref --quiet refs/remotes/origin/HEAD`, which yields
   `refs/remotes/origin/<name>`; take `<name>`.
3. **`git remote show origin`**, whose `HEAD branch:` line says the same thing
   when the symbolic ref is absent locally.
4. **`master` or `main`**, whichever exists as a ref. If both do, or neither,
   stop and ask for `base=<ref>`.

Resolve the branch itself with `git rev-parse --verify` against the local ref,
then `origin/<branch>`. If neither exists, stop and say the branch was not
found locally or on `origin` — do not guess a similar name and do not fall back
to local mode. Three dots in the diff, never two: two would attribute
everything that landed on the base since the branch forked to the branch under
review.

### PR mode — sanitising the argument before it can reach a shell

Accept exactly two forms:

- a **bare integer**: the whole argument matches `^[0-9]+$`;
- the **trailing number of a GitHub PR URL**: the argument matches
  `^https://github\.com/[^/]+/[^/]+/pull/([0-9]+)(/.*)?$`, and the capture
  group is the number.

Reject anything else and stop, naming what was rejected. Do not strip
characters until something matches, do not try a looser pattern on failure, and
do not ask the shell to interpret it. This rule is also the classifier: an
input that is neither of the two forms is a branch name.

**The raw argument is never interpolated into a command.** What reaches `gh` is
the integer extracted by one of the two patterns above — a value that by
construction contains nothing but digits. An argument that merely *looks* safe
is still passed as the extracted integer, never as itself.

Check `gh` is available (`gh --version`) before the first `gh` call. If it is
missing, stop with an error that names it:

> Iterating on a pull request needs the GitHub CLI (`gh`), which is not
> available on this machine. Install it, or iterate on the branch instead:
> `/task-iterate <branch>`.

**Never fall back** to local or branch mode on a PR input. A silent fallback
would fix the working tree and report it as work on PR 214. Local and branch
mode never invoke `gh` at all, so its absence is invisible to them — do not
check for it on those paths.

---

## RESOLVING THE TASK

The task body is what a `defer` verdict is measured against — "valid, but out
of scope for this task" needs the task's scope in hand. Resolve it in this
order, taking the first that yields a `.claude/tasks/<n>.md` that exists:

1. **`task=<n>`** — explicit, always wins.
2. **The branch name** — a number in it (`feature/118-dual-llm`, `task-118`,
   `118-dual-llm`) names the task.
3. **The PR title** — pr mode only; a leading `Task <n>:` or a bare number.
4. **The most recently modified `.claude/tasks/*.md`** — the weakest signal, so
   state which file was picked and why in the triage report.

If none of the four resolves, **stop**:

> I could not work out which task these findings belong to. Re-run with
> `task=<n>` — without the task's scope I cannot tell a `defer` from a `fix`.

Read the resolved body: its **Acceptance criteria** (a finding that names an
unmet criterion is not deferrable — see TRIAGE), its **Decisions** (a finding
that argues against a recorded decision is a `reject`, and the decision is the
reason), and its **Hints**. Then read what the fixes will touch — the callers,
the imports, the tests, the project's `CLAUDE.md` and its `.claude/context/`
entries for those files.

---

## WHERE THE FINDINGS COME FROM

Exactly one of three sources, resolved in this order:

1. **The caller passed them in.** `/task-implement --review` spawns
   `/task-review` as a subagent and hands its structured output here. This is
   the common path and it needs no file.
2. **A review file** at `.claude/reviews/<task>-R<n>.md`, written by a manual
   `/task-review` run that opted into one. Use the highest `<n>` present for
   the resolved task, and name the file you read in the report. If several
   files could plausibly apply and the highest round is ambiguous, ask which
   before triaging anything.
3. **The PR's review comments** — pr mode only, read with
   `gh pr view <N> --comments` or the review-comments API through `gh api`.
   Each thread is one finding. A thread already resolved is prior context, not
   a finding: do not reopen it.

If the caller passed findings in, do not also read a file or the PR threads —
one source per run. If none of the three yields anything, say so and stop.

**The finding schema** these arrive in, and which every reference below uses:

```
R1-3  BLOCKING  scripts/cmd-add.sh:142
  Claim:    <the problem, one sentence>
  Scenario: <input, state, and the bad outcome that follows>
  Fix:      <what to change; one or two sentences>
```

The id is `R<round>-<n>` — round number, then the finding's position in that
round. It is stable across rounds and **must not be renumbered**: it is how a
rejection stays rejected. Severities are exactly three — `BLOCKING`,
`IMPORTANT`, `ADVISORY` — and an unmet acceptance criterion is always
`BLOCKING`. A finding arriving from a PR thread has no id of its own; assign it
`R<round>-<n>` in thread order and say so, so the rest of the run can reference
it.

---

## TRIAGE

**Every finding gets exactly one verdict. No finding is skipped, merged into
another, or handled implicitly by a fix that happens to cover it.**

| Verdict | Meaning | Requires |
| --- | --- | --- |
| `fix` | valid, will be corrected now | — |
| `defer` | valid, but out of scope for this task | a follow-up task number, or a note that one should be authored |
| `reject` | not valid | a one-line reason |

**Write the full verdict table out before making any edit.** Not after, not
as you go. Triage decided while editing is triage rationalised by the edit
already made, and the table is the artifact this skill exists to produce.

```
R1-1  BLOCKING  fix      — <what will change>
R1-2  IMPORTANT defer    — follow-up task 141 (or: no task yet; one should be authored for <scope>)
R1-3  ADVISORY  reject   — <one line: why this is not valid>
```

Rules that constrain the verdict:

- A `BLOCKING` finding naming an **unmet acceptance criterion** cannot be
  deferred. It is either fixed, or rejected on the ground that the criterion is
  in fact met — and then the reason must say where.
- A finding arguing against something the task body's **Decisions** section
  records is a `reject`, and the decision is the reason. The reviewer did not
  have the authority to reopen it, and neither does this skill.
- `defer` is for work that is genuinely a different task, not for work that is
  merely tedious. A `defer` with no follow-up number must say what the task
  would be, in one line, so `/task-add` has something to start from.
- `reject` needs a reason that could be argued with — "not valid" is not a
  reason. The next round's reviewer receives this line as binding context, so
  it has to carry the argument on its own.

Present the table, then proceed. In a standalone run the table goes in chat
before the first edit; in a run inside `/task-implement --review` it goes into
the output returned to the caller.

---

## APPLYING THE FIXES

Only the `fix` findings are applied. Work through them in id order.

- Read each file before editing it; make targeted edits rather than rewrites.
- Change only what the finding asked for, plus genuine collateral (an import,
  a fixture, a call site). A fix that grows into a refactor is scope this run
  was not given — say so and leave it.
- Follow the project's existing style. Do not add comments explaining that a
  reviewer asked for the change.
- If a fix turns out to be wrong once you are in the file — the code already
  handles the case, or the fix would break something the finding did not see —
  do not apply it. Change that finding's verdict to `reject`, with what you
  found as the reason, and say the verdict changed and why. Discovering the
  finding was wrong is a legitimate outcome; quietly not applying it is not.

**Tests.** Where the project has a test suite, re-run the tests affected by the
files just changed, and fix the code — never the test — until they pass. Where
it has none, or where its `CLAUDE.md` declares a testing policy of
`skip-tests` or `skip-tests-unattended`, skip this step silently: there is
nothing to run and the absence is already a recorded project decision.

If a fix cannot be made to pass, stop: report which findings were applied,
which one failed and how, and leave the tree as it is. Do not commit a broken
tree, and do not weaken a test to get past this.

---

## PR MODE — REPLYING ON THREADS

After the fixes are applied, and only in pr mode:

- **On each thread whose finding was `fix`ed** — reply saying what changed, in
  one or two sentences, then resolve the thread.
- **On each thread whose finding was `defer`red** — reply with the follow-up
  task number, or that one should be authored and for what. Resolve it: the
  concern has an owner elsewhere.
- **On each thread whose finding was `reject`ed** — reply with the one-line
  reason and **leave the thread open**. A rejection is an argument the human
  may want to have; closing it ends the conversation unilaterally. Those
  replies are also the rejection ledger for this PR — the next round reads them
  the way an in-session round reads the returned ledger.

Reply and resolve through `gh` (`gh pr comment`, `gh api` on the review-comment
reply and resolve endpoints), always against the sanitised integer.

**This skill never opens a pull request**, here or anywhere. It replies to
threads on a PR that already exists; it does not create one, and it does not
submit a review.

---

## COMMITTING — IT DEPENDS ON THE CALLER

There are two callers and they get different behaviour. The difference is
deliberate, and the reason matters more than the rule.

### Standalone

Commit and push, following the repository's commit-and-push protocol:

1. **Pull at start** — `git pull` on the current branch, before any edit. A
   conflict stops the run before any work happens; report it and tell the user
   to resolve manually and re-run.
2. Apply the fixes, then stage **only the explicit paths this run changed**
   (`git add -- <path> <path>`). Never `git add -A`, `git add .`, or
   `git add -u`. Make no empty commit: if triage rejected or deferred
   everything, nothing changed, so nothing is committed.
3. **Pre-push re-sync** — `git pull` again immediately before pushing. A clean
   fast-forward continues; a conflict aborts the merge, leaves the local commit
   intact, does **not** push, and reports that the commit exists locally and
   needs a manual sync and push.
4. **Push** — `git push`. On failure (rejected, no upstream, no remote): report
   the exact output and stop. Never retry, never force-push.

`--no-push` skips steps 1, 3 and 4 while still committing. `--no-commit` skips
the commit too, leaving every fix in the working tree. On a project whose
`CLAUDE.md` defines a `## VCS` section overriding git, skip the pull, re-sync
and push entirely — only the commit (checkin) step runs.

Commit message, unless the repo's `git log` shows a different house style:

```
Iterate on task <n> review findings

<one line per finding fixed>
```

### Inside a `/task-implement --review` round

**Commit nothing. Push nothing.** Leave the corrected tree for that run's
existing Step 7.

The reason, because a future editor who sees only the rule will "fix" the
asymmetry: `/task-implement` holds a one-commit-per-task contract. If iterate
committed here, a reviewed task would land an implementation commit plus a
separate fix commit for work no human reviewed separately — two commits for one
task, and the second one describing corrections to the first. Leaving the tree
uncommitted keeps the task at exactly one commit, which is the property the
`--review` loop was built not to break.

This is the one place this skill departs from the symmetric design, and it is
load-bearing. Do not make the two paths agree.

---

## THE CALLER ASSERTS THE MODE — IT IS NEVER INFERRED

In-run mode is an **instruction this skill must be given**, in the form:

> You are running inside a `/task-implement --review` round; do not commit or
> push.

Absent that assertion, the standalone rules apply. Full stop.

Do not infer the mode from a dirty working tree, from findings having been
passed in rather than read from a file, from the round number, from the
presence of a parent agent, or from anything else. An inference that gets it
wrong commits inside a `/task-implement` run — which is exactly the failure the
rule above exists to prevent, and it fails silently, because a commit that
should not exist looks like a commit that should.

---

## WHAT THIS SKILL RETURNS

Whatever the mode, end by returning three things:

1. **The triage summary** — per finding id, the verdict, and for each `fix`
   what actually changed (the file, and one line on the change). A verdict that
   changed during APPLYING THE FIXES is reported at its final value, with the
   original verdict named.
2. **The rejection ledger** — every `reject`ed finding's id and its one-line
   reason, together, as a block. This travels into the next round as **binding
   context**: a rejected finding may not be re-raised there, only escalated on
   evidence the earlier round did not have. In PR mode the rejection replies on
   the threads are the same ledger, and the block names the threads instead.
3. **Whether any `BLOCKING` findings remain unresolved** — as an explicit
   yes/no plus the ids. `/task-implement`'s loop reads exactly this field to
   decide whether another round is warranted, so it is stated plainly, never
   left to be inferred from the summary above it. A `BLOCKING` finding is
   unresolved when it was deferred, rejected, or attempted and abandoned; a
   fixed one is resolved.

---

DO NOT:
- Invent a finding, add one of your own, or expand a finding beyond what it
  says.
- Skip a finding, merge two into one verdict, or leave any finding untriaged.
- Start editing before the full verdict table is written out.
- Defer a `BLOCKING` finding that names an unmet acceptance criterion.
- Reject a finding without a one-line reason, or defer one without a follow-up
  task number or a note that one should be authored.
- Re-litigate a decision the task body's Decisions section records.
- Weaken or delete a test to make a fix pass.
- Commit or push when the caller asserted the in-run mode — or infer that mode
  from anything other than the caller's assertion.
- Stage with `git add -A` / `git add .` / `git add -u`, make an empty commit,
  or use `--amend`, `--no-verify`, `--no-gpg-sign` or a force push.
- Open a pull request, submit a review, or resolve a thread whose finding was
  rejected.
- Interpolate a raw PR argument into a shell command, or fall back from PR mode
  to local or branch mode when `gh` is missing.
- Check out, create or switch a branch.
- Renumber finding ids.
