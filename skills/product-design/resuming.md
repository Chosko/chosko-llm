# Resume protocol

Read this only when PHASE 0 found an existing
`.claude/domain/design-process.md` — the state of a previous run. Its
presence is the signal; its **Current stage** block is the state.

---

## 1. Read the state

1. Read `.claude/domain/design-process.md` in full and extract:
   - The **Current stage** marker: which phase, and whether it is in
     progress or done.
   - Whether business modelling is in scope.
   - Greenfield or brownfield, as the earlier session judged it.
   - Anything under **Decisions worth keeping**.
2. Read the documents beside it — `product-design.md`,
   `technical-direction.md`, and `business-model.md` when in scope — to know
   what is actually written, not just what the marker claims. A
   `technical-direction.md` still at its PHASE 1 stub (headings and one-line
   notes, no filled content) counts as not-yet-written, exactly like an
   unfilled `product-design.md` section.
3. **When the marker and the documents disagree**, trust the marker for
   *where to resume* and tell the user what you saw: "the marker says PHASE 3
   is done, but `product-design.md` has no design-decisions section — I'll
   fill that gap first." Never silently re-derive the stage.
4. **A marker written before PHASE 6/7 existed** — a five-row phase table
   and a Current stage of `PHASE 5 — feature write-back: done`, with no
   PHASE 6/7 rows — does not mean the process is complete. Treat it as
   PHASE 5 done, PHASE 6 not started, and offer to continue into PHASE 6
   rather than reporting the process finished. When rewriting the marker
   from here, extend the phase table to the current seven-row shape.

## 2. Summarize, in the user's terms

Report, in a few lines, written for someone who has forgotten the whole
thing (weeks may have passed):

- Where the last session stopped — the phase, and what it had covered.
- What is written so far, per document.
- What the next phase would do.

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
third arm alongside those two, and put it first. Offer it only then; with
the process not yet complete, the answer is A or B.

> C. **Amend a decision** — change something specific in the finished
>    design without re-running phases. I'd edit the relevant document
>    directly and leave the process complete.

Wait for an explicit answer. Silence is not an answer. Gate class:
`design` (`../interaction-engine/references/gates.md`).

## 4. On resume (A)

- If the marker's phase is **done**, start the next phase.
- If it is **in progress**, re-enter that phase where the marker says it
  stopped. Do not restart it from the top: replay what has been covered as a
  one-line recap ("we'd covered users and the checkout flow"), confirm it
  still holds, and continue from there.
- Then proceed through the remaining phases exactly as SKILL.md describes,
  rewriting the marker at every transition.
- Never overwrite `product-design.md`, `technical-direction.md`, or
  `business-model.md` on this path — it only extends.

## 5. On start fresh (B)

1. Before writing anything, resolve the existing content:

   > `product-design.md` already has content from the previous process. Keep it
   > as brownfield input to the new one, or discard it and start from an empty
   > document?

   - **Keep** — treat the existing documents as brownfield input: read them
     in PHASE 1, build on them, extend in place.
   - **Discard** — confirm once more, naming the files, then overwrite them
     with fresh stubs. This is the only path in this skill that destroys
     written design content, and it requires the user to have said so
     twice. Gate class: `destructive`.
2. Either way, rewrite `design-process.md` from PHASE 1 with a new phase
   table and a marker at PHASE 1. Carry forward anything under **Decisions
   worth keeping** — restarting the process does not invalidate it.

## 6. On amend (C)

1. Establish what is changing and why, conversationally — same register as
   the phases: contribute, don't just extract — until the change can be
   stated as one sentence naming the document and section it lands in.
2. Run `./amend.md` with that sentence as its `<change>`: it pins, drafts,
   gates, writes and compresses `design-process.md`, and its report and
   committing are the arm's. The direct `amend "<change>"` argument form
   reaches the same file without this menu.

---

## Never

- Resume silently. The user always sees the summary and makes the call.
- Re-ask PHASE 1's business-modelling question when the marker already
  records the answer. If the user now wants to add a business model to a
  process that skipped it, you may offer that once, on resume; it creates
  `business-model.md` at that point.
