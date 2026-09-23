# Task parking

Authority for: the one event that parks a task, how a prompt with a default
resolves under the `unattended` policy, the `## Parking handoff` section, the
`park/task-<N>` branch, the park sequence, the unpark transaction, when an
unpark is attempted, and the two refusals.

Authored in the engine — no feature ever carried a copy of it. Read by
`/task-implement` only when UNATTENDED is true, or when a task in its
resolved list is `[PARKED]`. A run under `attended` that meets no parked task
never opens this file: what the always-read bodies carry is the ninth tag in
`./status.md`, the eligibility clause in `./resolution.md` and the commit
forms in `./commit.md`, each citing here.

---

## The one event that parks

Parking is the outcome of exactly one event: **a question the agent asked
about the work** — a skill's own blocking question inside the per-task
workflow (an ambiguous acceptance criterion it cannot settle from the body
and the codebase, a `--review` round's approval gate), or, when the session
is a runbook step agent, the question it would otherwise end its turn with
under `QUESTIONS FOR USER`. Under `unattended` that question parks the task
instead of halting the run. Under `attended` nothing ever parks: the question
is put to the user and the run waits.

Every other gate keeps its existing outcome, and none gets a handoff:

- an unmet precondition skips the task — `./resolution.md` § *Eligibility*;
- a runbook step whose `Depends on:` is not done is unselectable, untouched —
  the runbook's own rule, not a park;
- a failure leaves the task `[IN PROGRESS]` — `/task-implement`'s FAILURE
  HANDLING;
- a prompt whose silence already resolves to a value takes that value —
  § *Prompts with a default*.

## Prompts with a default

Under UNATTENDED a prompt whose silence already resolves to a value takes
that value, and each value taken is one *For the record* line in the closing
report:

| Prompt | Value taken |
| --- | --- |
| the delegation question (PRE-FLIGHT step 2b) | no — in-context |
| the `[PARTIAL]` surfacing (Step 6) | `[PARTIAL]` is written |
| the feature-flip proposal (FEATURE COMPLETION) | none |
| `Proceed?` in skip-tests mode | yes |
| the dirty-tree prompt at pre-flight (`./tree.md`) | abort |
| a `[STALE]` task named explicitly (`./stale.md`) | skip, with one line |

The one prompt with no default — an ambiguous test runner — aborts the run.
A pre-flight prompt can never park, because there is no current task yet;
that is why it needs this rule and nothing more.

## The handoff

A parked task's body gains a trailing `## Parking handoff` section — the one
section of a body `/task-implement` writes, appended at the park and removed
at the unpark. Its fields, in order:

```
## Parking handoff

Parked: 2026-09-23 — Step 3 — the criterion names two files and the body only one
Parking Branch: park/task-42
Question:
<the question exactly as it was asked, every line, options included>
```

- `Parked:` — the date as `YYYY-MM-DD`, the step reached, one reason clause,
  and the words `approval gate` when the question is one: a yes/no on a draft
  that is in the tree, such as a `--review` round's approval.
- `Parking Branch:` — `park/task-<N>`, or `[none]` when nothing had been
  edited and so no branch was made.
- `Question:` — the question verbatim and multi-line, options included.
  Never compressed, never paraphrased.
- `Answer:` — present only after an unpark whose merge failed (§ *The unpark
  transaction*), holding the answer that was given so the attended unpark
  need not ask it again.

Nothing else — no draft, no restated body, no copy of the referenced files.
The body, the files and the branch are re-read at unpark, and the draft is
the work-in-progress on the branch already.

## The branch

`park/task-<N>` — the name is deterministic from the task number and
recorded on the handoff anyway: the field for the reader, the name as a
guard. It holds **one commit** of the task's uncommitted work: every tracked
edit and every untracked file the task created, **excluding**
`.claude/TASKS.md` and `.claude/tasks/<N>.md`, which stay on the base for the
bookkeeping commit. It is branched from the current head and pushed, unless
NO_PUSH — then it exists locally only, and an unpark on another machine fails
as *branch not found*, which is reported, never worked around. A branch of
that name already existing is an inconsistent state and fails the park; it is
never overwritten and never reused.

## The park sequence

1. Confirm no `park/task-<N>` exists, locally or on the remote. One that
   does fails the park as a Step 7 failure: task `[IN PROGRESS]`, tree
   intact, run stopped.
2. When the task has edited nothing, record `[none]` and go to step 4.
   Otherwise create the branch from the current head and check it out —
   the uncommitted work carries over — stage the task's tracked edits and
   created files by explicit path, minus the two backlog files, commit
   `Task <N>: parked work-in-progress`, and push it unless NO_PUSH. A push
   refused here is a Step 7 push failure: the branch commit exists locally
   and needs a manual push.
3. Check the base branch back out. The two backlog files, still
   uncommitted, come with it.
4. Write the handoff into `.claude/tasks/<N>.md`, flip `Status:` to
   `[PARKED]` in `.claude/TASKS.md`, stage exactly those two paths, commit
   `Task <N>: parked — <reason>`, and push unless NO_PUSH.

The base tree is clean afterwards, so the next task meets no dirty tree.
Print the question in chat with a number handle, then continue.

## The unpark transaction

Nothing destructive happens until the last step, and a failure rolls back to
the parked state exactly as it was.

1. **Ask first.** Put the handoff's `Question:` to the answerer (§ *The
   answerer rule*) before touching the tree — that is what lets a `skip`
   cost nothing. An `approval gate` is the one exception: its draft cannot
   be approved unseen, so step 2 runs first and the question is asked with
   the draft in the tree. A gate is therefore never pre-answerable; the
   pre-ask lists it as skip-only.
2. **Cherry-pick without committing** — `git cherry-pick -n <parking
   commit>` onto the current head; nothing to pick when `Parking Branch:`
   is `[none]`. A conflict aborts the pick and restores the tree.
3. **Delete the branch**, local and remote, unless it was `[none]`.
4. **Resume the task** at the step `Parked:` names, with the answer in
   hand. The `Status:` flip to `[IN PROGRESS]` and the handoff's removal
   ride in the task's own Step 7 commit — the one path on which the body
   file is staged (`./commit.md`). Step 7 commits as always.

A conflict at step 2:

- under UNATTENDED — the task stays `[PARKED]`; the answer already given is
  written into the handoff as an `Answer:` line and `Parked:` is rewritten
  with a reason naming the merge failure; that update is committed as
  bookkeeping, `Task <N>: parked — <reason>`, so the next task meets no dirty
  tree; the task is skipped and the closing report names it as needing an
  attended unpark;
- under `attended` — the run halts and asks how to merge.

## The answerer rule

Unpark is attempted whenever an answerer exists: an attended session when
the task is reached, or an UNATTENDED run holding an answer for the task —
from the pre-ask at launch, or from a reply by number in chat during the
run. How those answers are taken and held is `/task-implement`'s own. With
no answer the task is skipped with one line — "Skipping task 42 — parked,
no answer held." — and never re-parked: no branch is touched, no commit is
made. `all` and `next` treat `[PARKED]` as implementable exactly under that
condition; a `[PARKED]` task named by number is unparked under either
policy, its answer under `unattended` coming from the pre-ask, where `skip`
skips it as the batch selectors would.

## Refusals

- `--unattended` beside `--no-commit`: parking is made of commits. Stop
  with `--unattended and --no-commit cannot be combined.`
- `--unattended` on a project whose `CLAUDE.md` maps git to another VCS
  (a `## VCS` section, `./commit.md`): a parking branch is the mechanism
  and there is no equivalent. Stop with `--unattended needs git — this
  project's CLAUDE.md maps another VCS.`

---

## Per-consumer notes

- **`/task-implement`** — the only reader of this file and the only writer
  of everything it describes: the tag, the handoff, the branch and the
  three commit forms. The `--unattended` flag, UNATTENDED's resolution from
  the flag or the conversation, the pre-ask, the chat handle and the
  in-memory answers are its own and are stated in its body, not here.
- **`/task-list`, `/task-clean`, `/task-add`, `/pipeline-check`** — meet
  `[PARKED]` only as a tag, per `./status.md`, and never open this file.
