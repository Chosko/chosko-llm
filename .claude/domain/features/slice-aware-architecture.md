# Slice-aware architecture

`/architect` today resolves its target against `product-design.md`'s
high-level feature sections. This feature teaches it a second resolution
mode: when the project has a roadmap, a target resolves to a **scope slice**
— one milestone's share of a high-level feature — and the feature documents
it writes are scoped to that slice. The two modes live in separate on-demand
supporting files, so a project with no roadmap behaves exactly as it does
today.

## Purpose

A high-level feature is a design unit. The share of it that ships in a given
release is a business decision, taken by the roadmap's author on grounds
`/architect` cannot see: MVP scoping, infrastructure cost, timing, strategy.
If `/architect` decomposes the whole of `§ Authentication` at once, it
produces low-level features that straddle milestones — and then every
downstream mechanism has to cope with a work unit that is partly in one
release and partly in another.

Teaching `/architect` to architect one slice removes the problem at its
source instead of managing it later. Every low-level feature then belongs to
exactly one slice, and every slice to exactly one milestone, so
milestone → slices → features is a tree with no crossing edges. That
property is what makes [production-plan](./production-plan.md) simple.

The second purpose is a guarantee: `/architect` must behave **exactly as it
does today** on the many projects that will never have a roadmap. See
[product-design.md § Roadmap and planning](../product-design.md).

## Scope and non-goals

In scope: the branch that selects a resolution mode, the two supporting
files that hold the modes, slice resolution and disambiguation, exclusions
flowing into feature-document non-goals, the `Source:` field extension, and
the `--no-slices` escape hatch.

Deliberately out:

- **Any behaviour change on projects with no roadmap.** This is the feature's
  central constraint, not a nice-to-have.
- **Restructuring the rest of `/architect`.** The gate, PHASE 0b's iterate
  guard, PHASE 1, PHASE 2's conversation and PHASE 3's write rules are
  untouched. Only input resolution and the `Source:` format are affected.
- **Reading `PLAN.md`.** `/architect` reads the roadmap, never the plan. The
  plan is downstream of it.
- **Writing the roadmap.** `product-roadmap.md` belongs to
  `/product-roadmap`, exactly as `technical-direction.md` belongs to
  `/product-design`. A slice that turns out wrong is fixed by re-running that
  skill.
- **Marking features stale when a slice changes.** Discussed under
  [product-roadmap](./product-roadmap.md)'s open questions.

## Architecture

Built on the stack recorded in
[technical-direction.md](../technical-direction.md): a markdown prompt, no
code. The skill being extended is described in
[`.claude/context/features.md`](../../context/features.md); its existing
phase structure is the thing this feature must leave intact.

**The activation probe.** Slice mode activates on the presence of
`.claude/domain/product-roadmap.md` carrying at least one milestone with a
`Covers:` line. That is the whole of the configuration — no flag file, no
settings key, no frontmatter switch, consistent with the
filesystem-is-the-state rule.

**Dispatch is per target feature, not per run.** One invocation can architect
several features, and a roadmap that slices `§ Authentication` may say
nothing about `§ Config export`. Each target resolves independently: a
section with no slice takes the traditional path even on a roadmapped
project. This matters because it makes adoption incremental — a roadmap can
slice one section and leave the rest alone.

**Two supporting files, both read on demand.** The skill folder already uses
this pattern for `iterating.md`, `tech-stack-selection.md` and
`feature-doc-template.md`: `SKILL.md` names the branch and the file to read
when it fires, and nothing else reads them.

- `sectioned-input.md` — the traditional mode: resolve the target against
  `product-design.md` sections and existing `FEATURES.md` slugs; write
  `Source: product-design.md § <section>`.
- `sliced-input.md` — slice mode: resolve against the roadmap's slices,
  disambiguate, carry exclusions into non-goals, write the extended
  `Source:`.

Only input resolution and the `Source:` format move into these files.
Everything shared stays in `SKILL.md`, so neither file duplicates the other's
scaffolding.

**`sectioned-input.md` is the current text moved, not rewritten.** This is
the same discipline `/context-convert` holds itself to — content is moved,
never rewritten — and it is what makes the behaves-as-today guarantee
verifiable by reading a diff rather than by trusting a claim.

**Slice resolution**, in `sliced-input.md`:

1. Find every slice whose section matches the target.
2. One slice → architect it. Several, across different milestones → ask which
   one, listing each with its milestone and scope statement. The user may
   also name the milestone in the invocation to skip the question.
3. Take the slice's scope statement as a boundary: the low-level features
   produced cover the slice, and the statement's exclusions become the
   feature document's **non-goals** — a section the document template
   already has, which is why no template change is needed.
4. Record the milestone in `Source:`.

**The `Source:` extension.** The field gains an optional milestone
parenthetical:

```
Source: product-design.md § Authentication (m1-mvp)
```

Absent on traditional-mode features and on `Source: prompt` features. This is
what makes milestone inheritance in [production-plan](./production-plan.md) a
lookup rather than an inference, and it is a one-token addition to a field
`/architect` already owns — no new field, no new writer.

**`--no-slices`** forces traditional mode on a roadmapped project, following
the repo's `--no-split` / `--no-agents` / `--no-commit` convention.

## Data and state

No new storage. Two schema changes, both to documents that already exist:

- **`FEATURES.md` `Source:`** — optional ` (<milestone-slug>)` suffix.
  Backward compatible: every existing entry stays valid, and readers that
  ignore the suffix keep working. `/architect` remains its only writer, so
  the by-line ownership split in
  [product-workflow.md](../product-workflow.md) is unaffected.
- **The feature document's non-goals section** — now populated from the slice
  exclusions when one applies. Section already exists; only its source of
  content is new.

The accepted cost of the symmetric file split is that a project with no
roadmap pays one probe and one file read it does not pay today. Against what
`/architect` already reads — the domain `INDEX.md`, `product-design.md`,
`technical-direction.md`, `FEATURES.md`, the context `INDEX.md` and
`feature-doc-template.md` — this is noise, and the symmetry keeps neither
path privileged if roadmapped projects become the norm.

## Interfaces and contracts

**Consumes** from [product-roadmap](./product-roadmap.md): milestone slugs
and per-milestone `Covers:` slices, read-only.

**Exposes** to [production-plan](./production-plan.md): the `Source:`
milestone parenthetical, which is the sole mechanism by which a low-level
feature knows its milestone.

**Expects:** the roadmap document's `Covers:` entries name
`product-design.md` sections in a form recognizable against that document's
headings.

**Failure contract:**

- No roadmap, or no `Covers:` line in it → traditional mode, silently. Not a
  warning: it is the normal state of most projects.
- Roadmap present, target section unsliced → traditional mode for that
  target, stated in one line so the choice is visible.
- Target section sliced across several milestones, no milestone named → ask.
  Never guess, and never architect the union of the slices.
- A slice whose section is absent from `product-design.md` → architect it
  anyway, warn once. Consistent with `/product-roadmap` warning rather than
  refusing on the same condition.
- `--no-slices` on a project with no roadmap → no-op, no warning.

## Dependencies

- [product-roadmap](./product-roadmap.md) — needs the document schema, the
  milestone slugs, and the `Covers:` slice format. Hard dependency: slice
  mode cannot be built before the thing it resolves against exists.
- **`/architect` itself** — an existing shipped skill. This is the only
  feature in this group that changes another feature's contract, so it
  carries a version bump on that skill and the corresponding update to
  [product-workflow.md](../product-workflow.md)'s who-writes-what table and
  `Source:` field description.
- No external dependencies.

## Open questions

- **Whether a low-level feature may legitimately span two slices.** Still
  open, and untested by what shipped. The design assumes not, and that
  assumption is what makes the milestone tree crossing-free. A shared
  component genuinely needed by an early slice and substantially extended by
  a later one is the case that would test it; the expected answer is two
  features, but it has not been proven against a real example.
- ~~**How slice scope statements are matched to section headings.**~~
  **Settled at implementation**, in `skills/architect/sliced-input.md`: an
  exact match on the section name comes first (case-insensitive, tolerant of
  surrounding whitespace and trailing punctuation); only when nothing matches
  exactly does a forgiving prose match apply, and a prose match is never
  silent — the matched slice and its milestone are stated in one line for the
  user to correct. A fuzzy candidate is never considered alongside an exact
  one. The tie-break argument was failure direction: a strict exact-heading
  rule fails *closed*, dropping the target into traditional mode silently,
  which is the one outcome a user would not notice. Still worth revisiting if
  mismatches show up in practice.
- **Whether `--no-slices` should also be available per target** rather than
  per run. Still open. Shipped per run, as designed: no evidence yet that a
  mixed run needs the finer grain, since unsliced sections already fall back
  on their own.
