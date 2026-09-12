# Resume protocol

Read this only when PHASE 0 found an existing
`.claude/domain/design-process.md`. That file is the state of a previous
run; this is how to pick it up.

There is no `resume` argument to check. The document's presence is the
signal, and its **Current stage** block is the state.

---

## 1. Read the state

Read `.claude/domain/design-process.md` in full — it is short by design.
Extract:

- The **Current stage** marker: which phase, and whether it is in progress
  or done.
- Whether business modelling is in scope.
- Greenfield or brownfield, as the earlier session judged it.
- Anything under **Decisions worth keeping**.

Then read the documents that exist beside it — `product-design.md`,
`technical-direction.md`, and `business-model.md` when in scope — so you
know what is actually written, not just what the marker claims. A
`technical-direction.md` that is still the PHASE 1 stub (headings and
one-line notes, no filled content) counts as not-yet-written when reporting
what the marker claims, exactly like an unfilled `product-design.md`
section would.

**When the marker and the documents disagree**, trust the marker for *where
to resume* and say what you saw: "the marker says PHASE 3 is done, but
`product-design.md` has no design-decisions section — I'll fill that gap
first." A phase that ended without rewriting the marker is the one failure
mode this protocol has to absorb, and it is absorbed by telling the user,
not by silently re-deriving the stage.

**A marker written before PHASE 6/7 existed** — its phase table has only
five rows and its Current stage says `PHASE 5 — feature write-back: done`
with no PHASE 6/7 rows to point at. That does not mean the process is
complete: it means this run predates the technical-direction phases. Treat
it as PHASE 5 done, PHASE 6 not started — offer to continue into PHASE 6
rather than reporting the process as finished. When rewriting the marker
from here, extend the phase table to the current seven-row shape.

## 2. Summarize, in the user's terms

Report, in a few lines:

- Where the last session stopped — the phase, and what it had covered.
- What is written so far, per document.
- What the next phase would do.

Write it for someone who has forgotten the whole thing. Weeks may have
passed; that is the case this protocol exists for.

## 3. Offer the choice

> Resume from PHASE <N> — <name>, or start fresh?
>
> A. **Resume** — pick up where the last session stopped. Existing
>    documents are extended, not replaced.
> B. **Start fresh** — begin a new design process from PHASE 1. I'd rewrite
>    `design-process.md`; existing `product-design.md` /
>    `business-model.md` content would need to be either kept as brownfield
>    input or explicitly discarded — I'll ask which before touching
>    anything.

When the marker says the **process is complete** (PHASE 7 done), offer a
third arm alongside those two, and put it first — it is the common case
for a finished design:

> C. **Amend a decision** — change something specific in the finished
>    design without re-running phases. I'd edit the relevant document
>    directly and leave the process complete.

Wait for an explicit answer. Silence is not an answer.

## 4. On resume (A)

- If the marker's phase is **done**, start the next phase.
- If it is **in progress**, re-enter that phase where the marker says it
  stopped. Do not restart the phase from the top: replay what has already
  been covered as a one-line recap ("we'd covered users and the checkout
  flow"), confirm it still holds, and continue from there.
- Then proceed through the remaining phases exactly as SKILL.md describes,
  rewriting the marker at every transition.

## 5. On start fresh (B)

Before writing anything, resolve the existing content:

> `product-design.md` already has content from the previous process. Keep it
> as brownfield input to the new one, or discard it and start from an empty
> document?

- **Keep** — treat the existing documents as brownfield input: read them in
  PHASE 1, build on them, extend in place.
- **Discard** — confirm once more, naming the files, then overwrite them
  with fresh stubs. This is the only path in this skill that destroys
  written design content, and it requires the user to have said so twice.

Either way, `design-process.md` is rewritten from PHASE 1 with a new phase
table and a marker at PHASE 1. Carry forward anything under **Decisions
worth keeping** — that rationale is expensive to reconstruct and is not
invalidated by restarting the process.

## 6. On amend (C)

Offered only when the marker says the process is complete. This is the
entry point for a targeted change that does not warrant re-running phases:
one decision moved, one feature description corrected, one technical axis
re-decided.

1. Establish what is changing and why, conversationally — same register as
   the phases: contribute, don't just extract. Say which document the
   change lands in before editing it.
2. Edit the relevant document(s) **directly** — `product-design.md`,
   `technical-direction.md`, or `business-model.md` — in the same
   documentational register they were written in. Add every path touched to
   `WRITTEN`. Do not create tasks, `FEATURES.md` entries, or anything under
   `.claude/domain/features/`; the DO NOTs in SKILL.md apply unchanged.
3. Do not touch the phase table and do not move the stage marker off
   process-complete. An amendment is not a phase; the process stays
   complete.
4. **Before the session ends, compress `design-process.md`** exactly as
   PHASE 7 does — see `./document-templates.md`'s "This file shrinks; it
   does not grow". If the amendment produced durable WHY that would
   otherwise be lost, it becomes **one terse line** under **Decisions worth
   keeping**, and any entry it supersedes is deleted outright rather than
   marked. Rewrite **Current stage** rather than appending to it. An
   amendment must leave the file the same size and shape it found it in —
   not larger.
5. Report what changed, in which document, and that `design-process.md` was
   compressed. `--commit` behaves as it does everywhere else in this skill:
   stage exactly `WRITTEN`, or leave everything uncommitted by default.

---

## Never

- Infer the stage from the documents' contents instead of the marker. The
  marker is the state; a mismatch is reported, not resolved by guesswork.
- Resume silently. The user always sees the summary and makes the call.
- Overwrite `product-design.md`, `technical-direction.md`, or
  `business-model.md` on the resume path (A) — that path only extends.
- End an amend (C) without compressing `design-process.md`, or record the
  amendment as a dated revision block, a `[SUPERSEDED]` marker over kept
  text, or another paragraph on **Current stage**. The amend path deletes;
  it never appends.
- Offer the amend arm (C) when the marker says the process is not yet
  complete. There the answer is A or B — resume the unfinished phase.
- Re-ask PHASE 1's business-modelling question when the marker already
  records the answer. If the user now wants to add a business model to a
  process that skipped it, that is a fine thing to offer once, on resume,
  and it creates `business-model.md` at that point.
