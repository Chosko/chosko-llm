# `/product-design amend` — one targeted change to the design documents

Read this when ARGUMENT PARSING recognised the `amend "<change>"` form, once
PHASE 0's gate has passed and the pull-at-start has run; or from
`./resuming.md` § 6, when the resume menu's amend arm was chosen. It carries
the whole arm: a consumer that has read only this file — `/product-design`
itself, or a pipeline revision surface reading it by path — can execute it
end to end; where a rule lives in another file in this folder, this file
cites it by path and restates nothing it owns.

The arm runs no phase: one decision moved, one feature description
corrected, one technical axis re-decided. It pins the change to a section of
one of the three documents, drafts the edit, settles it at one gate, writes,
and leaves the process complete.

---

## Inputs

- `<change>` — the quoted text after `amend`: what to change, naming the
  document and section it lands in, or quoting the passage.
- `--commit`, `--no-commit`, `--no-push` — unchanged in meaning; see
  *Committing*.
- **A draft, optionally**, when a revision surface runs this arm: the edit
  it drafted at plan time, in the before → after shape of § 3. See § *The
  gate*.

It reads `.claude/domain/design-process.md`, for its stage marker, and the
document the change names — `product-design.md`, `technical-direction.md` or
`business-model.md` — and nothing else.

- `design-process.md` present and its marker not at process-complete →
  refuse: `The design process is not complete (PHASE <N>); re-run
  /product-design to resume it.` An amendment edits a finished design.
- `design-process.md` absent, the named document present → the documents
  are hand-written; amend them as they stand, and skip § 4's compression.
- The named document absent → stop and say so.

## 1. Pin the change

Pin the change to the `##` sections of the document it edits, as the
document actually carries them. A section counts as named when the change
names it, or quotes or names a passage that lives in it.

A change that names no section and points at no passage the arm can locate
is refused:

> This change can't be pinned to a section of `<document>`. Name the section
> it changes, or re-run `/product-design` to revisit the design.

## 2. Draft the edit

Draft the edit to the pinned sections only, in the document's own
register — high-level, from the user-experience angle in `product-design.md`,
the stack and topology angle in `technical-direction.md`. `SKILL.md`'s DO
NOTs apply unchanged: no tasks, no `FEATURES.md` entries, nothing under
`.claude/domain/features/`. Every section not pinned stays as it is.

## 3. The gate

One message: each pinned section, before → after, and nothing else. Then:

- **With no draft passed in** — wait for an explicit approval. Silence, an
  unclear reply or EOF writes nothing.
- **With a draft passed in** — compare it with the draft § 2 produced from
  the same reads. When they match, write without waiting: the consumer's
  gate already approved this edit. When they differ, render the difference
  as the gate and wait.

## 4. Write

Write the pinned sections to the named document, as approved, and add the
path to `WRITTEN`.

Then, when `design-process.md` exists, compress it exactly as PHASE 7 does —
`./document-templates.md`'s "This file shrinks; it does not grow". Durable
WHY the amendment produced becomes one terse line under **Decisions worth
keeping**, and any entry it supersedes is deleted outright. **Current stage**
is rewritten, never appended to; the marker stays at process-complete, the
phase table untouched. The file leaves the same size and shape it was found
in, and its path joins `WRITTEN` only when a line changed.

## 5. Report

```
Amended <document>: § <section>[, § <section>][; design-process.md compressed].
```

When `WRITTEN` is non-empty and the run committed nothing, end with an
explicit reminder that nothing was committed.

## Committing

Under `/product-design amend`, `SKILL.md`'s COMMIT AND PUSH applies to
`WRITTEN` unchanged. A consumer that executes this file by path commits
under its own rules; § 4's paths are what it stages.

---

## Never

- Run a phase, move the stage marker, or touch the phase table.
- Record the amendment as a dated revision block, a `[SUPERSEDED]` marker
  over kept text, or another paragraph on **Current stage**.
- Write anything but the named document and `design-process.md`.
- Wait at the gate when a passed-in draft matches, or write on a passed-in
  draft that does not.
