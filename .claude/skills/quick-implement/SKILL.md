---
name: quick-implement
version: 0.2.2
type: skill
description: Take one small change from conversation to commit in a single run — a spec conversation with a drift check against the documented design, one gate, then tests first and one commit holding the change and its spec file under .claude/specs/ — with no backlog entry. Use it for a change one person can describe and one commit can hold; anything bigger goes to /task-add.
requires: skill:task-engine, skill:interaction-engine, command:follow-ups
---

# /quick-implement
# Global skill: plan a change in conversation, check it against the project's
# documentation, confirm once, then implement it tests-first and commit it
# together with a spec file recording what was decided. No TASKS.md entry, no
# FEATURES.md write. A spec too big for one commit stops at the gate with a
# pointer to /task-add. The spec stays in .claude/specs/ until
# /pipeline-revise --catch-up brings the documentation up to date and deletes
# it.
# Usage: /quick-implement "<change>"
#        /quick-implement "<change>" feature=<slug>   (read that feature document as context)
#        /quick-implement "<change>" --review         (review the change before committing it)
#        /quick-implement "<change>" --review --rounds N
#        /quick-implement "<change>" --attended | --unattended
# Examples: /quick-implement "make the export button disabled while a download runs"
#           /quick-implement "add a --json flag to the list command" feature=cli-output --review

GOAL
One run, in this order:

1. Check the working tree.
2. Hold the spec conversation and run the drift check.
3. Ask once, at the gate.
4. Write the spec file.
5. Implement it tests first, with the review loop under `--review`.
6. Commit the change and the spec together, and push.
7. Give the closing report.

---

SUPPORTING FILES (read on demand)

| Read this file | Exactly when |
| -------------- | ------------ |
| `../interaction-engine/references/policy.md` | Every run, at ARGUMENT PARSING. |
| `../interaction-engine/references/messages.md` | Every run, before the gate. |
| `../interaction-engine/references/gates.md` | The policy resolved to `unattended`. |
| `../task-engine/references/tree.md` | Every run, at step 1. |
| `../task-engine/references/design-change.md` | Every run, at the drift check. |
| `./drift-check.md` | Every run, once the spec is drafted. |
| `./spec.md` | Every run, when drafting the spec and when writing it. |
| `../task-engine/references/testing-policy.md` | Every run, at step 5. |
| `../task-engine/references/tests-first.md` | Every run, at step 5. |
| `../task-engine/references/commit.md` | Every run, at step 6. |
| `../task-engine/references/closing-report.md` | Every run, at step 7. |
| `../task-engine/references/review-budget.md` | `--review` was passed. |
| `../interaction-engine/references/mode.md` | Every run, at step 2, to know whether orchestrate mode is on. |

---

UNDER ORCHESTRATE MODE

When orchestrate mode is on — the check in
`../interaction-engine/references/mode.md`, made at step 2 — these run
differently and nothing else changes:

- **STEP 2 runs in one fresh subagent.** It holds the spec conversation and
  the drift check and returns the drafted spec, its drift hits, the size
  judgement, the testing policy it resolved and any open question. This
  session relays the subagent's questions to the user and the answers back
  to the same subagent until it returns, then holds STEP 3's gate itself.
- **STEP 5's implementation is split into areas** by the `orchestrate-mode`
  skill's rules for splitting into areas, the area brief and launch, the
  spec file being the owner's note. Each area agent follows
  `../task-engine/references/tests-first.md` for its own files under the
  testing policy resolved at step 2, and stages and commits nothing.
- **The review loop's fixes are applied by the areas.** This session routes
  each finding, by the file and region it cites, to the area that owns them,
  and edits nothing itself; a finding citing a file no area owns opens a new
  area for it. Each area with findings gets a fresh agent with the area
  brief, the owner's note being its findings verbatim, `spec=<the spec
  path>` and the in-run statement of step 4 below; the agent runs
  `/task-iterate` on them — triage and fixes both — for its own files only,
  stages and commits nothing, and reports its triage, its rejection ledger
  and any `BLOCKING` finding left open. This session merges the areas'
  ledgers into the one the next round's reviewer receives.

The run still makes its one commit, the change and the spec together, at
step 6.

---

ARGUMENT PARSING

Strip these from the arguments, in any position:

- `feature=<slug>` — anchor the spec on a feature document for context. The
  slug must have an entry in `.claude/FEATURES.md` whose `Doc:` file exists;
  otherwise stop with `No feature <slug> with a readable document in
  .claude/FEATURES.md.`
- `--review` — run the review loop (step 5). `--rounds N` sets its round
  cap, a positive integer, default 1; `--rounds` without `--review` stops
  with `--rounds requires --review.`, and a non-integer with
  `--rounds needs a positive integer.`
- `--attended` / `--unattended` — the interaction policy, resolved per
  `../interaction-engine/references/policy.md`, which holds their argument
  errors. Under `unattended`, also read
  `../interaction-engine/references/gates.md`.

What is left is the change, in the user's words. An empty change stops with
`Describe the change: /quick-implement "<change>".`

There is no `--no-commit` and no `--no-push`: one spec is one commit, and the
spec's lifecycle depends on that commit existing. Either flag stops the run
with `/quick-implement always commits and pushes — use /task-add and
/task-implement to hold work back.`

---

STEP 1 — CHECK THE WORKING TREE

Before the conversation, run the dirty-tree protocol from
`../task-engine/references/tree.md`. It runs first so the spec this run
writes is never itself a file the check reports. DIRTY_FOLD, when set, folds
the pre-existing changes into step 6's commit as that file describes.

Then pull, per `../task-engine/references/commit.md` § *Pull at start*.

---

STEP 2 — THE SPEC CONVERSATION AND THE DRIFT CHECK

Draft a spec for the change — `## Goal`, `## Acceptance criteria`,
`## Decisions`, `## Hints` — the way a free-form task is planned:

- **Investigate before asking.** Read the code the change touches — the
  project's `CLAUDE.md` and its `.claude/context/` entries first, then the
  source they point to — so the criteria name real files and behaviour.
  With `feature=<slug>`, read that feature document in full as context.
- **Ask only what the code cannot answer.** One to four focused questions at
  most, asked together, each with options and a recommendation. A spec with
  nothing left open asks nothing.
- **Criteria are checkable.** Each bullet is one statement a reviewer can
  mark met or not met from the diff.

Then run the drift check, `./drift-check.md`, against the drafted spec.

**Size.** Judge whether the spec is one change one commit can hold. Signs it
is not: criteria that fall into independent groups, more than one area of the
code changed for unrelated reasons, or work that needs a human step between
parts. A spec judged too big goes to the gate as a stop — STEP 3.

**Testing policy.** Resolve how tests run now, before the gate, per
`../task-engine/references/testing-policy.md`, so any question it raises is
asked at the gate rather than after it. The affected tests are those the
spec's `## Hints` and criteria name. Its no-test-suite branch is
`../task-engine/references/no-test-suite.md`, with this change as its one
unit of work: the scaffold-or-skip question joins the gate's questions, a
scaffold the user chooses lands in its own commit as that file says, and
approval at the gate stands in for skip-tests mode's "Proceed?" — set
AUTO_CONFIRM for the run.

---

STEP 3 — THE GATE

One gate, the run's only one. Show a plain-language summary, per
`../interaction-engine/references/messages.md` § *Output*: what the change
does, the acceptance criteria in brief, the files it will touch, and every
diverging drift hit in plain words — what the document says, what the change
does instead (the path last, in parentheses). Settled hits are counted, not
listed. A `show` reply prints the full drafted spec.

End with **"Implement it?"**, after any open question from STEP 2,
the testing-policy question among them.

**Too big.** A spec judged too big for one commit ends the run here instead:
say why in one or two lines, name the parts it would split into, and point to
`/task-add "<change>"`. Nothing is written, under either policy.

Gate class: `confirmation` when the spec has no open question, `design`
otherwise. Under `unattended` the gate follows
`../interaction-engine/references/gates.md`, this skill having no parking
mechanism; a stopped run writes nothing. Divergences never
make the gate `design` on their own: they are listed, never blocking.

Wait for an explicit approval under `attended`; silence is not approval. A
change requested at the gate is applied to the draft and the gate shown
again.

---

STEP 4 — WRITE THE SPEC

Write the approved spec to its file, per `./spec.md`, `## Drift` included.

---

STEP 5 — IMPLEMENT

Follow `../task-engine/references/tests-first.md` Steps 2–5 under the
testing policy resolved in STEP 2, the specification being the spec file and
the declared files those its `## Hints` name. The change is
documentation-only, for the steps that file skips, when every file it touches
is documentation (`README.md`, `CHANGELOG.md`, `docs/**` or comparable
prose, never a command or skill specification).

A failure that cannot be fixed stops the run: nothing is committed, the spec
and the change stay in the tree, and the closing report says what failed.

**Under `--review`**, after Step 5 and before step 6, on the uncommitted tree:

1. Check that the `task-review` and `task-iterate` skills are both available;
   if either is missing, stop before step 6 and name it — a run that says it
   reviewed nothing has not reviewed.
2. Spawn `/task-review` as a fresh-context subagent (Agent tool,
   `subagent_type: "general-purpose"`) with: the repository path, `spec=<the
   spec path>`, the round's diff scope (round 1 the whole uncommitted diff
   plus the spec file; later rounds only the hunks the last iterate changed),
   the round number, from round 2 the rejection ledger verbatim, that it was
   spawned by `/task-implement --review` — the statement `/task-review`
   keys its spawned output and its budget block on — the test-suite state,
   and the
   budget block. Resolve the reviewer's model and budget with `auto`, per
   `../task-engine/references/review-budget.md`, from the round's own diff.
3. **Wait for the reviewer's result to arrive** — the Agent call returns an
   id, never the findings.
4. Invoke `/task-iterate` in this session with the findings and
   `spec=<the spec path>`, stating: "You are running inside a
   `/task-implement --review` round; do not commit or push." Under
   orchestrate mode the areas run it instead (UNDER ORCHESTRATE MODE).
5. Repeat while `BLOCKING` findings remain unresolved and rounds are left.
   Unresolved `BLOCKING` findings after the last round stop the run before
   step 6, the tree left as it is, the findings named in the closing report.

---

STEP 6 — COMMIT AND PUSH

One commit holding the change and the spec, per
`../task-engine/references/commit.md`: stage by explicit path every file the
change touched and the spec file, then commit with the repository's
existing message style, falling back to:

```
Quick-implement: <spec title>
```

In skip-tests mode, add `(no tests — manual verification pending)` as the
body. Report the hash, then re-sync and push per `commit.md`'s push protocol.

A failed commit leaves the change and the spec staged and stops, exactly as
`commit.md` § *Failure* says. A push failure leaves the commit local and
stops with the manual sync-and-push instruction.

This run never writes `.claude/TASKS.md` or `.claude/FEATURES.md`, and never
deletes the spec.

---

STEP 7 — THE CLOSING REPORT

The run's last act, at completion and at every stop alike, per
`../task-engine/references/closing-report.md`. The specification is the spec
file. Its *Follow-ups* group carries, beside the items that file names:

- for each diverging drift hit in a feature document,
  `/architect amend feature=<slug> "<the change>"`, naming the passages;
- for everything else the drift check and the implementation left lagging,
  one `/pipeline-revise --catch-up <spec path>`;
- the items the `/follow-ups` command's rules yield, its body read by name and
  applied to this run, never invoked; with `/follow-ups` not installed, this
  group holds the run's own items only, silently.

A run that stopped before step 6 names what it left in the tree and how to
resume — re-run the same change, or `/task-add` it.

