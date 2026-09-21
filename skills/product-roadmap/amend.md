# `/product-roadmap amend` — one targeted change to the roadmap

Read this when ARGUMENT PARSING recognised the `amend "<change>"` form, once
the domain-layer gate has passed and the pull-at-start has run. It carries
the whole arm: a consumer that has read only this file — `/product-roadmap`
itself, or a pipeline revision surface reading it by path — can execute it
end to end; where a rule lives in `SKILL.md`, this file cites it by section
and restates nothing it owns.

The arm runs no roadmap conversation: the change is described, not
sequenced. It pins the change to named lines of the document, drafts the
edit, settles it at one gate, and writes.

---

## Inputs

- `<change>` — the quoted text after `amend`: what to change, naming the
  milestone and the line it lands in, or quoting the passage.
- `--commit`, `--no-commit`, `--no-push` — unchanged in meaning; see
  *Committing*.
- **A draft, optionally**, when a revision surface runs this arm: the edit
  it drafted at plan time, in the before → after shape of § 3. See § *The
  gate*.

It reads `.claude/domain/product-roadmap.md` and nothing else. Not
`product-design.md`, not `FEATURES.md`, not `PLAN.md`: nothing is being
sequenced. A missing roadmap stops the arm — `No roadmap to amend; run
/product-roadmap to draft one.` — with nothing written.

## 1. Pin the change

The lines the arm may edit are the ones the document schema in `SKILL.md`
§ *The document schema* defines: the preamble's `Strategy:` paragraph; a
milestone's title line, `Goal:`, `Exit criteria:` bullets, `Rationale:` and
`Covers:` bullets; the `Not now` and `Open sequencing questions` entries. A
line counts as named when the change names its milestone and field, or
quotes or names a passage that lives in it.

A change the arm cannot pin to named lines — one that adds, removes or
reorders a milestone, moves scope between milestones without naming both, or
spans the sequence — is refused:

> This change can't be pinned to named lines of `product-roadmap.md`. Name
> the milestone and the line it changes, or re-run `/product-roadmap
> "<change>"` to revise the sequence.

Adding or removing a bullet under `Exit criteria:`, `Covers:`, `Not now` or
`Open sequencing questions` is a pinned change; adding or removing a
milestone is not.

## 2. Draft the edit

Draft the edit to the pinned lines only, in the document's own register.
Every rule under `SKILL.md` § *The document schema*, "Rules the schema is
not free to bend", binds here unchanged — no `Status:`, no dates or
estimates, `Strategy:` global and `Rationale:` comparative, every `Covers:`
entry a scope statement, and the rest of that list. A change that would
break one is refused with the rule named, not softened into something that
passes.

## 3. The gate

One message: each pinned line, before → after, and nothing else. Then:

- **With no draft passed in** — wait for an explicit approval. Silence, an
  unclear reply or EOF writes nothing.
- **With a draft passed in** — compare it with the draft § 2 produced from
  the same reads. When they match, write without waiting: the consumer's
  gate already approved this edit. When they differ, render the difference
  as the gate and wait; the consumer's draft was made from the same
  document, so a difference means the document moved or the drafting
  disagrees, and either is the user's call.

## 4. Write

Write the pinned lines to `.claude/domain/product-roadmap.md`, as approved,
and add the path to `WRITTEN`. Nothing else: not the `INDEX.md` row, which
already exists; not any other document.

## 5. Report

```
Amended product-roadmap.md: <milestone> § <line>[, <milestone> § <line>].
```

When `WRITTEN` is non-empty and the run committed nothing, end with an
explicit reminder that nothing was committed.

## Committing

Under `/product-roadmap amend`, `SKILL.md`'s COMMIT AND PUSH applies to
`WRITTEN` unchanged. A consumer that executes this file by path commits
under its own rules; § 4's path is what it stages.

---

## Never

- Run PHASE 1, add, remove or reorder a milestone, or move scope between
  milestones the change does not both name.
- Write a `Status:`, a date, an estimate, or anything outside the pinned
  lines.
- Wait at the gate when a passed-in draft matches, or write on a passed-in
  draft that does not.
