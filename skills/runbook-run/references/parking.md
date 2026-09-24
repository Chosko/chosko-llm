# Step parking

Authority for what `/runbook-run` does with a parked step: the fifth result
row, the end branch that is not a deadlock, unparking, the launch pre-ask,
mid-run answers, the rejections, and a `[P]` step reached under `attended`.
The artifact side — the `[P]` marker, the two `Context:` bullet forms, the
index `Parked:` line and the header `Execution policy:` — is
`./runbook-schema.md`, cited here and restated nowhere.

Read once per run, on two triggers only: the policy resolved to `unattended`
(loop step 1), or step 3 met a `[P]` step — selected under `attended`, or
blocking selection under either policy. A default attended run that meets no
`[P]` step never opens this file. Everything here is bookkeeping in the two
files the orchestrator writes: nothing in it opens a task body, a branch or a
step's diff.

---

## The handles

Every parked question the run prints carries a handle `P<n>` — `P1`, `P2`, … —
and the handle is the reply handle. One sequence per run: the pre-ask labels
its items from `P1`, each step parked later takes the next unused handle, and
the closing report lists a parked step under the handle it already holds, or
the next unused one. The questions inside a parked block are labelled `Q1`,
`Q2`, … and their options `a`, `b`, … (OPERATING RULES), so a reply names both
without colliding — `Unpark P1: Q1a, Q2b`. Any reply that names the handle and
leaves no doubt which answer goes to which question is accepted, and so is a
reply by the step's id or title.

## The fifth result row

Active under `unattended` only. On a `QUESTIONS FOR USER` result — from the
step's agent, from a relay child, or from the session itself under
`--inline` — do not relay. Instead:

1. Set the step's marker to `[P]`, replacing `[~]`.
2. Append to its `Context:` — in place of `none` when that is all it holds —
   `- <date> parked: <question>`: the block's question and its options,
   verbatim and multi-line, and the agent's recommendation when it gave one.
   When the block is an approval gate, record the question and the words
   `approval gate` and leave the draft out: the draft is work-in-progress,
   and a skill that parks a task keeps it on that task's branch
   (`runbook-schema.md` § *A step*).
3. Print the question in chat under the next handle, in one fixed block:

   ```
   Parked (P3) — Step 4 of 7 — Peer review — the agent asked:

     <the question, its options and the recommendation, verbatim>

   Reply `Unpark P3: <answers>` (e.g. `Unpark P3: Q1a, Q2b`) to unpark it;
   the run goes on meanwhile.
   ```

4. Write the index `Parked: steps <ids>` line — this id added, ascending
   (`runbook-schema.md` § *The index block*); `Status:` stays `[RUNNING]`
   and `Steps:` does not move, since `[P]` is not done.
5. Commit in loop step 8 as any step is committed, and loop.

No `Done:` line is written: the step has not run to an end. The agent that
asked is never resumed — its turn ended, and nothing is sent back to it. When
the step is unparked it runs again from the start in a fresh subagent, with
the answer in its `Context:`; that is why OPERATING RULES has it leave the
tree clean of its own changes before asking, and why the block says it did.
The orchestrator does not check the tree — it does not review — and the next
step's agent meets the dirty-tree prompt as it always does. A relay child's
question parks the step the same way: the step is one unit, and it re-runs
whole. The orchestrator still compresses and never answers; the fifth row
stores the question, it does not settle it.

## The end branch

Steps remain, none is selectable, and at least one of them is `[P]`. This is
not a deadlock and not a failure — the run is waiting on an answer nobody
present can give. Set the index `Status:` back to `[PENDING]` (the `Parked:`
line stays), commit per COMMIT CADENCE, and give the closing report, whose
*Follow-ups* group names every `[P]` step with its question verbatim under its
`P<n>` handle, and under it the steps waiting on it — every step that is not
`[x]` and whose `Depends on:` reaches it, directly or through another
blocked step. The report is the run's last act here as at any other end
(CLOSING THE RUN).

A runbook that is a linear chain therefore stops after its first parked
step; one whose `Depends on:` lines were authored honestly runs on through
everything that does not need the answer. Either way the report says exactly
what to answer. The branch applies inside a bounded run too: reaching it
inside `--from`/`--to` is the same end, with the range's remaining steps
listed as they would be at a `--to` bound.

## Unparking a step

Bookkeeping only, in the two files the orchestrator writes:

1. Append `- <date> unparked with answer: <text>` to the step's `Context:`,
   the answer as given.
2. Set the marker to `[ ]`.
3. Rewrite the index `Parked:` line without this id; remove the line when no
   `[P]` step remains.
4. Commit the runbook and the index, by explicit path, as one bookkeeping
   commit of its own — under `--no-commit`, write and do not commit.

**The unparked step is the next step selected.** It sits above the current
step in list order, or is the first candidate, so the ordinary top-down rule
of step 3 picks it — and it is stated here as a rule, not left to the list:
the selection that follows an unpark picks the unparked step whenever its
`Depends on:` are `[x]` and it is in range. A step outside the range is
recorded and not run, as at any bound.

Runbook steps never park work on a branch; a task's branch is the task's.
When the step's prompt is a `/task-implement` on a task that is itself
`[PARKED]`, the answer is recorded on the step only — no handoff is written,
no `Answer:` line, nothing in `.claude/TASKS.md` — and the task unparks when
the step executes: the step's agent holds the answer in its `Context:` and
answers `/task-implement`'s question from there, per OPERATING RULES.

## The pre-ask

At loop step 1, under `unattended` only, unless `--skip-parked`. With no
`[P]` step in range, nothing is printed. Otherwise, before any step is
marked, print one block listing every `[P]` step in range under its handle,
in list order, each with the question its `parked:` bullet holds, verbatim:

```
Parked steps in this run — answer each by handle (`P1: Q1a, Q2b`), or reply
`skip` for one (`skip P2`) or for all (`skip all`):

P1. Step 4 — Peer review — parked 2026-09-23
    <the question, options included>
P2. Step 6 — Approve the migration draft — parked 2026-09-23, approval gate —
    skip-only: its draft is approved in an attended run, when the step runs
```

Wait for a reply. Each answer unparks its step at once, per § *Unparking a
step*, all of them in one bookkeeping commit; a `skip` leaves the step `[P]`
and records nothing. An `approval gate` item is skip-only — its draft cannot
be approved unseen, and it is not in the body — and an answer to one is
rejected with one line and records nothing. Silence, EOF or an unrelated
reply is `skip all`, the value `--skip-parked` gives. An attended run has no
pre-ask: it asks when it reaches the step, after the user has seen the
earlier steps' outcomes.

## Mid-run answers

The orchestrator reads the chat between steps — at loop step 8, after the
commit and before the re-read. A reply by a handle printed this run, or
naming a parked step by id or title, is that step's answer: unpark it per
§ *Unparking a step*, and the next selection picks it. Any other message is
ordinary conversation, and the run continues.

The same holds after the closing report, while the session is still open: a
reply by the report's `P<n>` handle is recorded the same way, and the next
`/runbook-run` of the runbook selects the step.

## The rejections

Each is one line in chat and records nothing:

- an answer to a handle this run never printed;
- a second answer to a step already unparked — the first answer wins, and
  changing it is a hand edit of `Context:`;
- an answer to an `approval gate` item, at the pre-ask or in chat.

The same three, and no other, are the task side's
(`../../task-engine/references/parking.md` § *The answerer rule*).

## A parked step reached under `attended`

A `[P]` step left by an earlier run, met by an attended run at step 3 as the
step it would otherwise select. Ask its question in the fixed block of THE
QUESTION RELAY, headed `Step <n> of <total> — <title> — parked <date>,
asking:`, the `parked:` bullet's text verbatim under it, and wait — as a
subagent, end the turn under `QUESTIONS FOR USER` and resume when the answer
returns, by the relay's own subagent-position rule. The orchestrator answers
nothing itself. With the answer, unpark per § *Unparking a step* and select
the step now. A step whose bullet says `approval gate` is unparked without a
question — its bullet is a plain dated one, `- <date> unparked by an
attended run; the gate is asked when the step runs`, never one opening
`unparked with answer:`, which OPERATING RULES would read as the gate's
answer — and the step's agent relays the gate with its draft, as any
attended question is relayed: a gate is answered seen, never from a block.
