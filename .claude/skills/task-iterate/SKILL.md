---
name: task-iterate
version: 0.3.2
type: skill
description: Triage review findings it did not produce — fix, defer or reject each one, apply the fixes and record why the rest were not — on an uncommitted tree, a branch or a pull request. Use it after /task-review has reported; /task-implement's review rounds run it in-session between the review and the task's single commit.
requires: skill:interaction-engine
project-policy: vcs:branch
---

# /task-iterate
# Global skill: triage review findings, apply what survives triage, and record
# why the rest did not. Fixes only what it was handed — it never finds anything
# itself. Findings come from exactly one of the review subagent's structured
# output, a .claude/reviews/<task>-R<n>.md file, or the PR's review comments.
# The scope a defer is measured against is the task's — or, with spec=<path>,
# a spec file's, with no fallback.
# Triage is mandatory and explicit: every finding gets exactly one of fix,
# defer or reject — defer needs a follow-up task number or a note that one
# should be authored, reject a one-line reason — and the full verdict table is
# written before any edit is made. Returns a triage summary, a sticky rejection
# ledger for the next round, and whether any BLOCKING findings remain.
# Standalone it commits and pushes by default; inside a /task-implement
# --review round it commits nothing and leaves the corrected tree for that
# run's single commit. Never opens a pull request, in any mode.
# Usage: /task-iterate                        (iterate on uncommitted changes)
#        /task-iterate <branch>               (iterate on a branch)
#        /task-iterate <branch> base=<ref>    (override the base)
#        /task-iterate <pr-number|pr-url>     (iterate on a GitHub PR)
#        /task-iterate <args> task=<n>        (pin the task explicitly)
#        /task-iterate <args> spec=<path>     (measure against a spec file instead of a task)
#        /task-iterate <args> --no-commit     (apply the fixes, commit nothing)
#        /task-iterate <args> --no-push       (commit as usual, skip the push)
#        /task-iterate <args> --attended | --unattended
# Examples: /task-iterate
#           /task-iterate feature/password-auth
#           /task-iterate 214
#           /task-iterate https://github.com/acme/app/pull/214 task=118

GOAL
Take a set of findings someone else produced and answer, for each one and in
writing: **fix it, defer it, or reject it — and why?** Then apply the fixes,
leave the rejections on the record, and hand back a summary the caller can act
on. The triage is the product; applying fixes is the easy half.

---

## WHY THE TRIAGE IS MANDATORY

- Write a verdict per finding: it makes "fix what's worth fixing" auditable and
  produces the **rejection ledger** the next review round depends on.
- Treat triage as mandatory, not advisory: an iterator that fixes everything it
  is told converges on whatever the reviewer said last.
- Treat `reject` as a first-class outcome that needs a reason, not an apology.

---

## THIS SKILL NEVER INVENTS A FINDING

- Triage only findings that arrived from somewhere else. Do not review the
  diff, do not sweep for problems the reviewer missed, and do not add a finding
  of your own — not as a bonus, not as an "also noticed", not folded into
  another finding's fix. Do not expand a finding beyond what it says.
- If the input carries no findings, say so and stop. That is a complete run:
  the reviewer found nothing, so there is nothing to triage.
- Reviewing is `/task-review`'s job; a skill that both finds and fixes grades
  its own work.

---

## SUPPORTING FILES

Everything this skill does is in this file, PR mode included. The one
exception is the interaction engine, which `requires: skill:interaction-engine`
installs beside it:

| Read this file | Exactly when |
| --- | --- |
| `../interaction-engine/references/policy.md` | At ARGUMENT PARSING, to resolve the interaction policy. |
| `../interaction-engine/references/messages.md` | Before the first question or the returned summary. |
| `../interaction-engine/references/gates.md` | The policy resolved to `unattended`. |

Do not look for any other reference file outside this folder.

---

## SHELLING OUT

Unlike `/task-review`, this skill **does** mutate. Run only:

- read-only inspection: `git diff`, `git log`, `git branch`,
  `git symbolic-ref`, `git rev-parse`, `gh pr diff`, `gh pr view`, `gh api`
  reads, `gh --version`;
- the project's test command;
- in standalone mode only: `git add` on explicit paths, `git commit`,
  `git pull` and `git push`.

In every mode, never run `gh pr create` (this skill never opens a pull
request) or any history-rewriting or hook-skipping git flag (`--amend`,
`--no-verify`, `--no-gpg-sign`, `push --force`).

---

## ARGUMENT PARSING

1. Scan the argument string and strip these tokens, in any order and any
   position:
   - `task=<n>` — pin the task explicitly. `<n>` must be a bare integer;
     anything else is an error: stop and say so.
   - `spec=<path>` — measure against a spec file instead of a task body
     (RESOLVING THE TASK).
   - `base=<ref>` — override the base for branch mode. Meaningful only in
     branch mode; on a local or PR run, say it was ignored and continue.
   - `--no-commit` — apply the fixes and commit nothing. Implies `--no-push`.
   - `--commit` — accept and strip it as a silent no-op: committing is the
     default.
   - `--no-push` — commit as usual, skip the pull-at-start and the
     re-sync/push.
   - `--attended` / `--unattended` — the interaction policy. Resolve it with a
     policy handed down by the caller and the project's `CLAUDE.md` per
     `../interaction-engine/references/policy.md`, which also holds their
     argument errors. This skill has no parking mechanism
     (`../interaction-engine/references/gates.md`); a stopped run applies
     nothing.
2. Stop on conflicting tokens:
   - `task=` and `spec=` together: `task= and spec= cannot be combined. Pick one.`
   - `--commit` and `--no-commit` together:
     `--commit and --no-commit cannot be combined. Pick one.`
3. Trim what remains: that is the **input**. Classify it:

   | Input | Mode | What is iterated on |
   | --- | --- | --- |
   | *(empty)* | local | the uncommitted working tree — `git diff HEAD` |
   | a branch name | branch | that branch's own work — `git diff <base>...<branch>` |
   | a PR number or a PR URL | pr | that pull request — `gh pr diff <N>` |

4. Apply the fixes to the **working tree in front of you**, in every mode.

### Branch mode — resolving `<base>`

- Branch mode assumes that branch is checked out. If it is not, say so and
  stop. Never check out, create or switch a branch — switching branches under a
  user is not this skill's call.
- Resolve `<base>`; first hit wins:
  1. **`base=<ref>` from the argument.** Verify it resolves
     (`git rev-parse --verify`); if it does not, stop and say so rather than
     silently falling through to the default.
  2. **The repository's default branch** —
     `git symbolic-ref --quiet refs/remotes/origin/HEAD`, which yields
     `refs/remotes/origin/<name>`; take `<name>`.
  3. **`git remote show origin`**, whose `HEAD branch:` line says the same
     thing when the symbolic ref is absent locally.
  4. **`master` or `main`**, whichever exists as a ref. If both do, or neither,
     stop and ask for `base=<ref>` (gate class: `design`).
- Resolve the branch itself with `git rev-parse --verify` against the local
  ref, then `origin/<branch>`. If neither exists, stop and say the branch was
  not found locally or on `origin`. Do not guess a similar name and do not fall
  back to local mode.
- Use three dots in the diff, never two: two would attribute everything that
  landed on the base since the branch forked to the branch under review.

### PR mode — sanitising the argument before it can reach a shell

- Accept exactly two forms:
  - a **bare integer**: the whole argument matches `^[0-9]+$`;
  - the **trailing number of a GitHub PR URL**: the argument matches
    `^https://github\.com/[^/]+/[^/]+/pull/([0-9]+)(/.*)?$`, and the capture
    group is the number.
- Reject anything else and stop, naming what was rejected. Do not strip
  characters until something matches, do not try a looser pattern on failure,
  and do not ask the shell to interpret it. This rule is also the classifier:
  an input that is neither of the two forms is a branch name.
- **Never interpolate the raw argument into a command.** Pass `gh` only the
  integer extracted by one of the two patterns — by construction nothing but
  digits. An argument that merely *looks* safe is still passed as the extracted
  integer, never as itself.
- Check `gh` is available (`gh --version`) before the first `gh` call. If it is
  missing, stop with an error that names it:

  > Iterating on a pull request needs the GitHub CLI (`gh`), which is not
  > available on this machine. Install it, or iterate on the branch instead:
  > `/task-iterate <branch>`.

- **Never fall back** to local or branch mode on a PR input: a silent fallback
  would fix the working tree and report it as work on PR 214.
- Local and branch mode never invoke `gh` at all — do not check for it on those
  paths.

---

## RESOLVING THE TASK

The task body is what a `defer` verdict is measured against — "valid, but out
of scope for this task" needs the task's scope in hand.

1. Resolve it in this order, taking the first that yields a task body at
   `.claude/tasks/<n>.md`, or a spec file, that exists:
   1. **`task=<n>` or `spec=<path>`** — explicit, always wins. A `spec=` run
      reads that file in place of a task body and never falls back to the
      steps below: a path that does not exist stops the run with
      `No spec file at <path>.`
   2. **The branch name** — a number in it (`feature/118-dual-llm`,
      `task-118`, `118-dual-llm`) names the task.
   3. **The PR title** — pr mode only; a leading `Task <n>:` or a bare number.
   4. **The most recently modified `.claude/tasks/*.md`**, excluding
      `.claude/tasks/archive/`. This is the weakest signal: state which file
      was picked and why in the triage report.
2. If none of the four resolves, **stop**:

   > I could not work out which task these findings belong to. Re-run with
   > `task=<n>` — without the task's scope I cannot tell a `defer` from a `fix`.

3. Read the resolved body. Read a spec exactly as a task body — it carries the
   same sections:
   - its **Acceptance criteria** (a finding that names an unmet criterion is not
     deferrable — see TRIAGE);
   - its **Decisions** (a finding that argues against a recorded decision is a
     `reject`, and the decision is the reason);
   - its **Hints**.
4. Read what the fixes will touch — the callers, the imports, the tests, the
   project's `CLAUDE.md` and its `.claude/context/` entries for those files.

---

## WHERE THE FINDINGS COME FROM

Take findings from exactly one of three sources, resolved in this order:

1. **The caller passed them in.** `/task-implement --review` spawns
   `/task-review` as a subagent and hands its structured output here. This is
   the common path and it needs no file.
2. **A review file** at `.claude/reviews/<task>-R<n>.md` — on a `spec=` run
   `.claude/reviews/<spec-stem>-R<n>.md`, the spec's filename without its
   extension — written by a manual `/task-review` run that opted into one.
   Use the highest `<n>` present for the resolved task, and name the file you
   read in the report. If several files could plausibly apply and the highest
   round is ambiguous, ask which before triaging anything (gate class:
   `design`).
3. **The PR's review comments** — pr mode only, read with
   `gh pr view <N> --comments` or the review-comments API through `gh api`.
   Each thread is one finding. A thread already resolved is prior context, not
   a finding: do not reopen it.

- If the caller passed findings in, do not also read a file or the PR threads —
  one source per run.
- If none of the three yields anything, say so and stop.

**The finding schema** these arrive in, and which every reference below uses:

```
R1-3  BLOCKING  scripts/cmd-add.sh:142
  Claim:    <the problem, one sentence>
  Scenario: <input, state, and the bad outcome that follows>
  Fix:      <what to change; one or two sentences>
```

- The id is `R<round>-<n>` — round number, then the finding's position in that
  round. It is stable across rounds and **must not be renumbered**: it is how a
  rejection stays rejected.
- Severities are exactly three — `BLOCKING`, `IMPORTANT`, `ADVISORY`. An unmet
  acceptance criterion is always `BLOCKING`.
- A finding from a PR thread has no id of its own: assign it `R<round>-<n>` in
  thread order and say so, so the rest of the run can reference it.

---

## TRIAGE

**Every finding gets exactly one verdict. No finding is skipped, merged into
another, or handled implicitly by a fix that happens to cover it.**

| Verdict | Meaning | Requires |
| --- | --- | --- |
| `fix` | valid, will be corrected now | — |
| `defer` | valid, but out of scope for this task | a follow-up task number, or a note that one should be authored |
| `reject` | not valid | a one-line reason |

1. **Write the full verdict table out before making any edit.** Not after, not
   as you go: triage decided while editing is rationalised by the edit already
   made, and the table is the artifact this skill exists to produce:

```
R1-1  BLOCKING  fix      — <what will change>
R1-2  IMPORTANT defer    — follow-up task 141 (or: no task yet; one should be authored for <scope>)
R1-3  ADVISORY  reject   — <one line: why this is not valid>
```

2. Present the table, then proceed. In a standalone run, put it in chat before
   the first edit; in a run inside `/task-implement --review`, put it in the
   output returned to the caller.

Rules that constrain the verdict:

- A `BLOCKING` finding naming an **unmet acceptance criterion** cannot be
  deferred. Fix it, or reject it on the ground that the criterion is in fact
  met — and then the reason must say where.
- A finding arguing against something the task body's **Decisions** section
  records is a `reject`, and the decision is the reason. The reviewer did not
  have the authority to reopen it, and neither does this skill.
- Use `defer` for work that is genuinely a different task, not for work that is
  merely tedious. A `defer` with no follow-up number must say what the task
  would be, in one line, so `/task-add` has something to start from.
- Give `reject` a reason that could be argued with — "not valid" is not a
  reason. The next round's reviewer receives this line as binding context, so
  it has to carry the argument on its own.

---

## APPLYING THE FIXES

Apply only the `fix` findings, in id order.

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

**Tests.**

- Where the project has a test suite, re-run the tests affected by the files
  just changed, and fix the code — never the test — until they pass.
- Where it has none, or where its `CLAUDE.md` declares a testing policy of
  `skip-tests` or `skip-tests-unattended`, skip this step silently: there is
  nothing to run and the absence is already a recorded project decision.
- If a fix cannot be made to pass, stop: report which findings were applied,
  which one failed and how, and leave the tree as it is. Do not commit a broken
  tree, and do not weaken or delete a test to get past this.

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
- Reply and resolve through `gh` (`gh pr comment`, `gh api` on the
  review-comment reply and resolve endpoints), always against the sanitised
  integer.
- Never open a pull request or submit a review: reply only to threads on a PR
  that already exists.

---

## COMMITTING — IT DEPENDS ON THE CALLER

The two callers get different behaviour, deliberately.

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

- `--no-push` skips steps 1, 3 and 4 while still committing.
- `--no-commit` skips the commit too, leaving every fix in the working tree.
- On a project whose `CLAUDE.md` defines a `## VCS` section overriding git,
  skip the pull, re-sync and push entirely — only the commit (checkin) step
  runs.

Commit message, unless the repo's `git log` shows a different house style:

```
Iterate on task <n> review findings

<one line per finding fixed>
```

On a `spec=` run the subject names the spec's stem instead:
`Iterate on <spec-stem> review findings`.

### Inside a `/task-implement --review` round

**Commit nothing. Push nothing.** Leave the corrected tree for that run's
existing Step 7.

- Reason: `/task-implement` holds a one-commit-per-task contract. Committing
  here would land a separate fix commit for work no human reviewed separately —
  two commits for one task. Leaving the tree uncommitted keeps the task at
  exactly one commit, the property the `--review` loop was built not to break.
- This is the one place this skill departs from the symmetric design, and it is
  load-bearing. Do not make the two paths agree.

---

## THE CALLER ASSERTS THE MODE — IT IS NEVER INFERRED

- Treat in-run mode as an **instruction this skill must be given**, in the
  form:

  > You are running inside a `/task-implement --review` round; do not commit or
  > push.

- Absent that assertion, apply the standalone rules. Full stop.
- Do not infer the mode from a dirty working tree, from findings having been
  passed in rather than read from a file, from the round number, from the
  presence of a parent agent, or from anything else. A wrong inference commits
  inside a `/task-implement` run — and fails silently, because a commit that
  should not exist looks like a commit that should.

---

## WHAT THIS SKILL RETURNS

Whatever the mode, end by returning three things, written to
`../interaction-engine/references/messages.md` § *Output*:

1. **The triage summary** — per finding id, the verdict, and for each `fix`
   what actually changed (the file, and one line on the change). Report a
   verdict that changed during APPLYING THE FIXES at its final value, with the
   original verdict named.
2. **The rejection ledger** — every `reject`ed finding's id and its one-line
   reason, together, as a block. This travels into the next round as **binding
   context**: a rejected finding may not be re-raised there, only escalated on
   evidence the earlier round did not have. In PR mode the rejection replies on
   the threads are the same ledger, and the block names the threads instead.
3. **Whether any `BLOCKING` findings remain unresolved** — as an explicit
   yes/no plus the ids. `/task-implement`'s loop reads exactly this field to
   decide whether another round is warranted, so state it plainly, never leave
   it to be inferred from the summary above it. A `BLOCKING` finding is
   unresolved when it was deferred, rejected, or attempted and abandoned; a
   fixed one is resolved.
