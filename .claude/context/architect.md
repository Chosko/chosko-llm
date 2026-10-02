# Features: architect

## Overview

Covers stage 3 of the product pipeline, `/architect`. The rest of the
pipeline family: [pipeline.md](./pipeline.md).

- `skills/architect/` — stage 3 of product pipeline: turns one or more
  high-level features into low-level feature documents under
  `.claude/domain/features/`, each indexed by `.claude/FEATURES.md` entry.
  Input is `product-design.md` section, named features, or bare
  free-form prompt (usable on codebase that never ran
  `/product-design`); with no argument lists design's features and
  asks. Input resolution has TWO modes, in two on-demand files (below),
  dispatched PER TARGET rather than per run: slice mode activates purely on
  `.claude/domain/product-roadmap.md` carrying at least one milestone with a
  `Covers:` line (no flag file, no settings key, no frontmatter switch), and
  a target whose section that roadmap does not slice takes the traditional
  path anyway, stated in one line; a project with no roadmap takes the
  traditional path. `--no-slices` forces traditional
  mode per run (silent no-op where there is no roadmap). PHASE 0 gates on
  `/domain-setup`, reads design/technical-
  direction/feature/context layers, probes for the roadmap, detects whether stack exists — a
  present `technical-direction.md` counts as stack that exists, exactly
  like established codebase, so PHASE 2a skipped and
  `tech-stack-selection.md` never read on that path; PHASE 0b is iterate guard; PHASE 1 clarifies (skipped when nothing ambiguous,
  writing answers back into `product-design.md`); PHASE 2 architects
  conversationally, top-down — when `technical-direction.md` exists it
  designs within it and names the document in one line, and a genuine
  mismatch is flagged once and designed around rather than silently
  overridden (the remedy is re-running `/product-design`, never editing
  the document) — stopping at mid-to-high technical level, no code, no
  file-by-file plans, those being `/task-add`'s output; PHASE 3 writes the
  documents, the `FEATURES.md` entries, the INDEX rows, and any upstream
  design change. Seven supporting files load only on their branch:
  `sectioned-input.md` and `sliced-input.md` — the two input-resolution
  modes, mutually exclusive per target and never both read for the same
  target: `sectioned-input.md` when the target resolves traditionally (no
  roadmap, or `--no-slices`, or a roadmap that does not slice this target's
  section), matching against `product-design.md` sections and existing
  `FEATURES.md` slugs; `sliced-input.md` when a roadmap slice matches the
  target, carrying slice resolution (one match architects it, several across
  milestones ask, the union is never architected and the milestone never
  guessed), the exact-then-prose section matching rule, the slice's
  exclusions flowing into the feature document's non-goals, and the extended
  `Source:` — then
  `iterating.md` (the feature already has an entry), `amend.md` (the
  `amend feature=<slug>[,<slug>...] "<change>"` argument form; replaces
  input resolution, PHASE 0b and PHASES 1–3 for the run: per feature, edits
  only the sections the change names, dropping a feature the change can't
  be scoped to; runs a PRECISION iterate guard — each live task classified
  touched or untouched from its summary block, body opened only when that
  can't decide, a body that decides counting as a mechanical signal — that
  drops the feature only on a touched `[IN PROGRESS]` task and stales only
  touched tasks; one gate with a section per feature settling whether the
  change is editorial — CLEAR cases (task touched on summary block or body,
  or nameable added scope → not editorial; empty touched set, no scope, no
  contract text changed → editorial) print a `Classified:` evidence line
  and write with no reply; AMBIGUOUS cases (a body still undecided,
  borderline scope call, findings pointing different ways) ask A/B/C with
  the letter derived from touched set and scope call (empty and none → A,
  else B), one reply answering every asked feature — under
  `/pipeline-revise` it applies the carried classification with no prompt
  when its own derivation agrees, and the stricter one, not editorial over
  editorial, with no prompt and the deviation in the closing line when it
  differs; `product-design.md` upstream edit drafted once; one commit; no
  progress marker), `tech-stack-
  selection.md` (no existing stack in either form — an existing stack
  always wins), `council-gate.md` (PHASE 2 hit a genuine design fork —
  optional delegation to the claude-council skill this repo ships at the
  stack choice, the architecture shape, and the low-level split; detected
  **by name** ("is the `claude-council` skill available"), silent and no-op
  when absent, invoked with
  no mode argument, dissent folding into the feature document's Open
  questions, its verdict recorded in the PHASE 2 progress marker so a
  resumed session never re-convenes, and its report/transcript kept out of
  `WRITTEN` under a second narrow carve-out to the "nothing written before
  PHASE 3" rule; kept in step with the `/product-design` copy),
  `feature-doc-template.md` (PHASE 3, always; its
  Architecture section opens with a stack reference — "Built on <stack> per
  the product design", naming `technical-direction.md` when that's the
  source — rather than restating the choice). Writes `Status:` / `Doc:` /
  `Source:` in `FEATURES.md` and never `Tasks:` — the by-line split that
  lets it share the file with `/task-add`. `Source:` carries an optional
  ` (<milestone-slug>)` suffix written only in slice mode
  (`product-design.md § Authentication (m1-mvp)`), absent on traditional-mode
  and `prompt` features, and the sole mechanism by which
  a low-level feature knows its milestone. Reads `product-roadmap.md`, never
  writes it, and never reads `PLAN.md`. The only writer of `[STALE]`:
  the iterate guard refuses outright while any generated task is
  `[IN PROGRESS]` (no override), else asks, then flips surviving
  non-`[DONE]` tasks to `[STALE]` and feature status to `[ITERATED]` (from
  `[PLANNED]` or `[DONE]`). Guard's two halves decided by different fields:
  task half (list, refuse, ask, `[STALE]` flip) runs only when `Tasks:` IDs
  actually resolve — `Tasks: none` and IDs resolving to nothing are the same
  case, neither an error, and skip it with no ask and no `TASKS.md` write;
  status half always keyed on entry's own `Status:` (`[NEW]` and `[ITERATED]`
  self-transition, `[PLANNED]`/`[DONE]` → `[ITERATED]`, named in closing
  report). An ID absent from `TASKS.md` is archived and terminal
  (`resolution.md` § *The archive*), so it has nothing to refuse on, ask
  about or mark `[STALE]`. That guard and `amend.md`'s precision guard are the
  only reasons it touches `.claude/TASKS.md`; both write nothing there but
  `Status:` lines. Slugs
  stable, never renamed. Never writes `technical-direction.md` — that
  is `/product-design`'s document. **Commits by default — stages exactly the
  written paths (including TASKS.md when guard fired) in one commit and
  pushes**; `--no-commit` runs no git command, `--no-push` skips the push;
  `--commit` accepted as a silent no-op. **`amend.md` run by path keeps no default
  of its own — only `/architect amend` inherits this one.**

## Public API

- See [pipeline.md](./pipeline.md) § Public API.

## Internal patterns

- See [pipeline.md](./pipeline.md) § Internal patterns.

## Domain dependencies

- See [pipeline.md](./pipeline.md) § Domain dependencies.

## Cross-references

- [pipeline.md](./pipeline.md) — the pipeline family hub.
- [product-design.md](./product-design.md) — `/product-design`, whose
  documents `/architect` designs within, and `claude-council`.
- [pipeline-planning.md](./pipeline-planning.md) — `/product-roadmap`, whose
  `Covers:` lines drive slice mode, and `/production-plan`.

## When to read the source

- See [pipeline.md](./pipeline.md) § When to read the source.
