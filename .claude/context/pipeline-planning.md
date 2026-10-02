# Features: pipeline planning — product-roadmap and production-plan

## Overview

Covers the pipeline's two WHEN stages: `/product-roadmap` (product-level,
before `/architect`) and `/production-plan` (feature-level, before
`/task-add`). The rest of the pipeline family: [pipeline.md](./pipeline.md).

- `skills/product-roadmap/` — product-level WHEN of the pipeline, between
  `/product-design` and `/architect`. Writes one document,
  `.claude/domain/product-roadmap.md`, plus its `.claude/domain/INDEX.md`
  row, and nothing else — never `FEATURES.md`, `PLAN.md`, `TASKS.md`, or
  `product-design.md`. `amend.md`: the `amend "<change>"` form — one pinned
  change to named milestone lines (`Strategy:`, `Goal:`, `Exit criteria:`,
  `Rationale:`, `Covers:`, `Not now`), one before → after gate, no
  conversation, refuses an unpinnable change; headless when a revision
  surface passes its draft in and it matches. Preamble carries `Strategy:` paragraph — premise whole
  order rests on, global where `Rationale:` is local (why the sequence runs
  this way vs. why one milestone precedes next), labelled so revision can
  locate it. Then ordered milestone blocks keyed by stable kebab-case
  slug (`m1-mvp`), each carrying `Goal:` / `Exit criteria:` / `Rationale:` /
  `Covers:`, then `Not now` (every deferral carries trigger that pulls it
  back) and `Open sequencing questions`. Order is list position, so
  milestone inserted between two others needs no renumber; slice identity is
  `(milestone, section)` pair, no fourth identifier vocabulary. `Covers:`
  entries name `product-design.md` sections, never `FEATURES.md` slugs, and
  each carries prose scope statement whose payload is its exclusions —
  decomposition instruction for `/architect`, not delivery claim, so partial
  coverage of section across milestones is normal case and nothing validates
  completeness. Carries NO milestone state: no `Status:` line, no dates, no
  estimates — milestone status is `/production-plan`'s, the same
  intent/state split that keeps feature statuses out of `product-design.md`. Dates/status bar binds
  `Strategy:` too; deadline surfacing there becomes open sequencing question.
  PHASE 0 gates on
  `/domain-setup` (only refusal in skill), reads domain INDEX,
  `product-design.md` when present (optional — usable from bare
  description), any existing roadmap as its own resume state (no marker
  file, document is state), and `.claude/FEATURES.md` READ-ONLY. PHASE 0 then
  settles `STEER` in the same message as its findings summary (costs no extra
  round trip): "Do you have an ordering in mind? If not, I'll propose one." —
  because sequencing is business intent the documents can't contain, and a
  draft written first anchors both user and skill. Two sentences, NOT an
  either/or, and the skill says so: a disjunction gives the reply two arms to
  mirror into answer options, and arms w/ different subjects ("you have" vs.
  "should I propose") mirror into labels whose "I" means user in one and agent
  in other. Reply maps straight: yes → `given`, no → `propose`. `given` = take milestone
  skeleton first, draft goals/criteria/rationale/slices from it, governed by
  `/product-design`'s contribute-don't-just-ask so branch doesn't decay into
  transcription; `propose` = draft first.
  Question SKIPPED (not asked as ceremony) when `$ARGUMENTS` carried an
  ordering or revision already has roadmap. PHASE 1 is
  conversation and run's single approval gate (steer question is a question,
  not an approval); PHASE 2 is only write phase.
  Three failure modes are warnings, not refusals: `Covers:` entry naming
  section absent from `product-design.md`, editing slice whose section
  already has features (names slugs, points at `/architect <slug>`, proceeds
  on user's say-so — `[ITERATED]` stays `/architect`'s field), and revision
  whose deltas contradict recorded premise (names contradiction, asks which
  moves — premise is read as input on revision, NEVER rewritten to agree with
  a newly-decided order). One supporting file, `amend.md`, read for the
  amend form; schema inline. **Commits by default — stages exactly the
  written paths in one commit and pushes; nothing written makes no commit
  and says so**; `--no-commit` runs no git command, `--no-push` skips the push;
  `--commit` accepted as a silent no-op.
- `skills/production-plan/` — feature-level WHEN of the pipeline, between
  `/architect` and `/task-add`. Sole writer of `.claude/PLAN.md`, a third
  index beside `TASKS.md` and `FEATURES.md`, and writes NOTHING else — never
  `FEATURES.md`, `TASKS.md`, feature docs, `product-roadmap.md`,
  `product-design.md`, or the domain `INDEX.md`. `amend.md`: the
  `amend "<change>"` form — `reconciling.md`'s diff narrowed to the
  features, edges or milestones the change names, PHASE 2 validation
  intact, one diff gate; headless when a revision surface passes its draft
  in and it matches. Schema: `Roadmap:` (or
  `none`) and informational `Last reconciled:` headers; one block per
  milestone carrying `Status:`, derived `Covers:` and ordered `Features:`; an
  `Unscheduled` block (`Features:` only, written even when empty); and ONE
  flat `## Dependencies` edge list (`- <slug>: depends on <slug>, <slug>`)
  rather than a `Depends:` line per feature — keeps `PLAN.md` from becoming a
  second index keyed by feature slug and puts every edge where a cycle is
  visible. `Features:` order IS the priority: no `P0`/`P1`, no dates,
  estimates, sizes or readiness/coverage rollups (derived at read time).
  `Covers:` is rewritten from the roadmap's own `Covers:` lines every run, so
  hand edits to it never survive. PHASE 0 gates ONLY on `.claude/FEATURES.md`
  (points at `/domain-setup`; the skill's one gate) — a roadmap is optional,
  and without one everything lands in `Unscheduled` and ordering still works;
  no features at all writes nothing and says so. Read pass is entirely
  read-only: `FEATURES.md` (slugs, `Status:`, `Source:`, `Tasks:`), each
  feature doc's `## Dependencies` section, `product-roadmap.md` when present,
  any existing `PLAN.md` as resume state, and `.claude/TASKS.md` for the
  `[SHIPPED]` proposal alone. PHASE 1 inherits each milestone by LOOKUP off
  the `Source:` parenthetical `/architect` writes (never inferred from
  section names or `Covers:` prose; no parenthetical and `Source: prompt` →
  `Unscheduled`), orders each milestone, proposes the edge set from each
  document's prose for the user to confirm — prose is never rewritten, and a
  stored edge the docs never stated is legitimate — and handles milestone
  status `[PLANNED]` / `[ACTIVE]` / `[SHIPPED]`, at most one `[ACTIVE]`,
  `[SHIPPED]` proposed only when every feature is `[DONE]`, or `[PLANNED]`
  with every task `[DONE]`/`[SKIP]`, always confirmed, never reopened.
  Explicit placement overrides the parenthetical, is reported plainly, never gated or refused.
  PHASE 2 validates BEFORE the gate and before any write, and both invariants
  REFUSE with no override flag: a cycle is reported as the actual cycle path,
  and a dependency in a later milestone is reported with both features and
  both milestones (a dependency on an `Unscheduled` feature is a warning
  instead — `Unscheduled` has no position, so it cannot be "later"); each
  milestone's `Features:` must be a topological order of the edges restricted
  to it. PHASE 2 ends at the run's single approval gate; PHASE 3 is the only
  write phase. Two supporting files, `reconciling.md` and `amend.md`
  (above); `reconciling.md` is read on demand when PHASE 0 finds an
  existing `PLAN.md` — the five-situation re-run table
  (feature absent from the plan proposed for placement; plan slug gone from
  `FEATURES.md` reported and dropped along with its edges; `[ITERATED]`
  feature's dependencies re-read as a DIFF, never a wholesale replacement;
  roadmap milestone added in roadmap order; plan milestone gone from the
  roadmap reported, kept and flagged) — all folded into that same one gate,
  mirroring `/task-add`'s convention. Other failures are reports, not
  refusals: an edge slug resolving to no feature is dropped, a milestone with
  no features is a warning, `>1 [ACTIVE]` reports and asks. Nothing
  plan-aware exists in `/task-add`, `/task-implement`, or the bash CLI —
  deferred by the feature's open questions. **Commits by default — stages
  exactly `.claude/PLAN.md` in one commit and pushes; nothing written makes
  no commit and says so**; `--no-commit` runs no git command, `--no-push` skips the push;
  `--commit` accepted as a silent no-op.

## Public API

- See [pipeline.md](./pipeline.md) § Public API.

## Internal patterns

- See [pipeline.md](./pipeline.md) § Internal patterns.

## Domain dependencies

- See [pipeline.md](./pipeline.md) § Domain dependencies.

## Cross-references

- [pipeline.md](./pipeline.md) — the pipeline family hub.
- [architect.md](./architect.md) — `/architect`, which reads the roadmap and
  writes the `Source:` parenthetical `/production-plan` looks milestones up by.
- [pipeline-readers.md](./pipeline-readers.md) — `/production-status`, the
  read side of `PLAN.md`.

## When to read the source

- See [pipeline.md](./pipeline.md) § When to read the source.
