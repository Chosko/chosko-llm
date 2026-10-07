# Features: pipeline-revise

## Overview

Covers the pipeline's one revision surface, `pipeline-revise`: its argument,
classification, impact walk and lint bracket. Planning, the gate, actuation
and the commit: [pipeline-revise-plan.md](./pipeline-revise-plan.md). The
rest of the pipeline family: [pipeline.md](./pipeline.md).

- `skills/pipeline-revise/` — the pipeline's ONE revision surface (feature
  `pipeline-revision`). Explicit, never auto-triggered. `requires:
  skill:pipeline-engine, skill:architect, skill:task-engine,
  skill:runbook-run, skill:product-design, skill:production-plan,
  skill:product-roadmap` — the engine plus every owner whose amend arm a step
  may drive. `SKILL.md` carries the workflow; five flat supporting files, one
  per branch — `amend.md`, `insert.md`, `delete.md`, `reorder.md`, and
  `catch-up.md` for `--catch-up` — read ON DEMAND, one per kind a run's items
  classify into, each once, never one no item needs; all five share one
  seven-section schema (*Applies when*,
  *Impact walk*, *Owner sequence*, *Tier*, *Verification*, *Outcomes*,
  *Never*). **Argument is a change set**: `"<change set>"` — free-form text
  describing however many changes, or a numbered list in `/follow-ups`'
  output shape (one item per number); free-form splits into items at the
  changes it describes, the split said back at the gate for the user to
  correct. `<anchor> "<change>"` is also accepted for a single item.
  **`--catch-up <spec-path | "<landed change>">`** is the fifth branch, an
  editorial mode over code that has already landed: no anchor (an anchor
  beside it stops), a spec path that does not exist stops; its items are the
  points where a document lags the change — a spec's `## Drift` bullets plus
  the documents its Hints and diff touch, or what the walk finds from a
  description — each *settled* (editorial: `/architect amend` runs with
  `editorial` carried in, no task staled; a task amend only where its Hints
  cite a rewritten passage; a dated runbook `Context:` fact) or a **design
  break** (asked at the gate: accept the code → `amend.md`'s path, or keep
  the design → `insert.md`'s path, a task to bring the code back);
  `/context-update --no-commit` is the plan's last step when a context layer
  describes a touched file; a `CLAUDE.md` / README lag is a report
  follow-up; the run's one commit `git rm`s the spec it was given (the one
  write `WRITE SET` grants the skill itself), a stopped or uncommitted run
  leaving it in place. Anchor,
  four forms: `feature=<slug>`, `task=<N>`,
  `runbook=<id|name|id-name> step=<n>` (resolved by `runbook-schema.md`'s
  rule), and a milestone named in an item's own text (`m3`, an exit criterion
  quoted) resolving to a `##` block of `product-roadmap.md` — that last has
  NO argument form. The argument anchor applies to every item naming no
  artifact of its own; an item naming one uses its own; an item anchored on
  nothing, or an anchor resolving to nothing, stops the whole run listing
  what exists (archived vs never-assigned task id said), never picks between
  two. CLASSIFY per item, first-match in order reorder → delete → insert →
  amend (amend = everything else, incl. a milestone line and a
  `Preconditions:` change that moves no entry — the boundary `reorder.md`
  states so classification stays unambiguous); a change set spanning four
  kinds is ONE run. Impact walk per item, both directions over `graph.md`'s
  edges and no other traversal — top-down design section → features → tasks,
  plan edges, runbook steps; bottom-up task → feature doc when `Feature:`
  resolves (an unresolved slug stops the upward walk, not an error), plus
  forward to E4 successors. Whether the walk continues FROM those successors
  is per branch and written down in each: `amend.md` continues from every
  successor whose basis changes — up to that successor's own feature doc
  (E3b, then E2), stopping on an unresolved slug as for the anchor, then
  forward again (E4) — and `delete.md` the same from every successor whose
  edge is dropped AND whose basis is thereby withdrawn, which is what keeps a
  reorder (drop then replace with the same spec) from walking up spuriously;
  `insert.md` explicitly does NOT, a successor gaining a wait edge still
  delivering what it did; `reorder.md` inherits both. Every node visited once
  ACROSS THE WHOLE SET — an artifact two items reach is one entry. A doc
  reached that way is named from index lines and enters the owner sequence as
  an `/architect amend` step, never opened here — whether it needs a change is
  that arm's call. May open bodies, scoped per item: the target artifact,
  tasks whose `Preconditions:` name it or whose `Files:` overlap, runbook
  steps naming it, PLUS what a headless arm reads to make a decision the plan
  takes for it (for `/architect amend`, the feature's tasks' summary blocks,
  a body only when the block cannot decide); never bulk, never the archive.
  Lint bracket: `/pipeline-check` scoped to the union of the items' features
  (unscoped when an item anchors on a runbook or a milestone) BEFORE the
  proposal and AFTER actuation (also when stopped part-way), report shows
  cleared / created / unchanged; plus a successor-body read wherever an
  insert, delete or edge change moved a precondition — reported, never fixed.

## Public API

- See [pipeline.md](./pipeline.md) § Public API.

## Internal patterns

- See [pipeline.md](./pipeline.md) § Internal patterns.

## Domain dependencies

- See [pipeline.md](./pipeline.md) § Domain dependencies.

## Cross-references

- [pipeline.md](./pipeline.md) — the pipeline family hub, incl.
  `pipeline-engine`, whose `graph.md` edges the impact walk follows.
- [pipeline-revise-plan.md](./pipeline-revise-plan.md) — the rest of this
  entry.
- [pipeline-readers.md](./pipeline-readers.md) — `/pipeline-check`, the lint
  bracket.

## When to read the source

- See [pipeline.md](./pipeline.md) § When to read the source.
