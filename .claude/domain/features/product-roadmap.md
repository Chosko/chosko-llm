# Product roadmap

The roadmap is the product's WHEN at the highest level: an ordered list of
milestones, each with an outcome it delivers, the criteria that make it
shippable, and the share of each high-level feature it takes on. It is
written by a `/product-roadmap` skill into the domain layer, alongside
`product-design.md` rather than inside the backlog, because it records
intent and rationale rather than state.

## Purpose

The product pipeline covers what to build (`/product-design`), how to build
it (`/architect`), and the work to do it (`/task-add`). Nothing covers when.
Ordering exists today in exactly one place — `Preconditions:` on individual
tasks — which is far too low a level to express a release, and feature
documents carry dependency prose that nothing reads.

This feature adds the product-level half of the missing layer. Its reader is
the director deciding what the next release contains and why; its consumer
is `/architect`, which uses the roadmap's scope slices to decide how a
high-level feature decomposes. See
[product-design.md § Roadmap and planning](../product-design.md).

The feature-level half — dependency edges, ordering, milestone state — is
[production-plan](./production-plan.md).

## Scope and non-goals

In scope: the roadmap document and its schema, the skill that writes it
conversationally, milestone identity and ordering, scope slices, and a
read-only warning when a slice being edited already has architected features.

Deliberately out:

- **Milestone state.** The roadmap carries no `Status:` line. Which milestone
  is active and which have shipped belongs to
  [production-plan](./production-plan.md), for the same reason
  `product-design.md` carries no feature statuses and `FEATURES.md` does:
  intent and state are separate documents with separate writers.
- **Dates and estimates.** No target dates, no sizing, no velocity. The
  product is a personal workbench with no delivery commitments; adding a
  time axis would invite maintenance of numbers nobody acts on. Recorded as
  an open question rather than a closed one.
- **Low-level feature slugs.** The roadmap names `product-design.md`
  sections, never `FEATURES.md` slugs. It must be writable before anything
  has been architected.
- **Any write outside its own document.** In particular it never writes
  `FEATURES.md`, `PLAN.md`, or `TASKS.md`.
- **Validating that a milestone's coverage is complete.** A high-level
  feature spanning several milestones is the normal case, not a defect. See
  the scope-slice discussion below.

## Architecture

Built on the stack recorded in
[technical-direction.md](../technical-direction.md): a markdown prompt
executed by Claude Code, operating on markdown documents. No bash, no new
dependencies. The shipped-artifact conventions this follows — frontmatter,
per-feature versioning, the authoring-command commit family — are in
[`.claude/context/features.md`](../../context/features.md).

**The skill.** A skill rather than a command, because the work is a
multi-round conversation with supporting material, matching
`/product-design` and `/architect`. Members of the authoring family: nothing
is committed unless `--commit` is passed, `--no-push` commits without
pushing, and the commit-and-push protocol in `docs/authoring-guide.md`
applies when it is.

Its shape follows `/architect`'s: a gate that refuses when the domain layer
is absent and points at `/domain-setup`; a read pass over
`product-design.md` and any existing roadmap; a conversational round; a
single write phase behind one approval gate.

**The document**, at `.claude/domain/product-roadmap.md`, registered as a row
in the domain `INDEX.md`. Ordered milestone blocks, each carrying:

- `Goal:` — the outcome the milestone delivers, as an outcome and not a
  feature list.
- `Exit criteria:` — what makes it shippable.
- `Rationale:` — why this milestone before the next.
- `Covers:` — the scope slices, one per high-level feature the milestone
  takes a share of.

Two further sections: **Not now**, holding deliberately deferred work each
with the trigger that would pull it back in, and **Open sequencing
questions**.

**Scope slices** are the load-bearing idea. A high-level feature is a design
unit, not a scheduling unit: the axis that splits it across releases is
business strategy — MVP scoping, cost, timing — not architecture. So
`§ Authentication` may appear under an early milestone as "email and
password only" and under a much later one as "third-party OAuth providers".
Each appearance is a slice, authored as a prose scope statement whose real
payload is its **exclusions**:

```
Covers:
- product-design.md § Authentication — email + password only. No third-party
  providers, no SSO, no reset-by-SMS.
- product-design.md § Feature catalogue — `ls` and `add` only.
```

A slice's identity is the `(milestone, section)` pair. This is deliberate:
it introduces no fourth identifier vocabulary beside task IDs, feature slugs
and milestone slugs, and `m1-mvp § Authentication` is already unique and
already addressable by `/architect`.

The consequence for `Covers:` is that it is **a decomposition instruction,
not a delivery claim** — neither advisory nor contractual. It constrains how
`/architect` decomposes a section rather than promising what ships, which is
what lets the roadmap be load-bearing without being a claim that anything
must validate against.

**The already-architected warning.** When the conversation edits a slice
whose section already has features in `FEATURES.md`, the skill says so and
points at `/architect`. It reads `FEATURES.md` and never writes it: marking
those features stale would mean writing `Status:`, which belongs to
`/architect`. The gap this leaves is recorded under open questions.

## Data and state

One document, versioned with the project. No index, no state file, no
timestamps — consistent with the filesystem-is-the-state rule in
[technical-direction.md](../technical-direction.md).

- **Milestone identity** is a stable kebab-case slug, e.g. `m1-mvp`. Never
  renamed and never renumbered, the same rule feature slugs and task IDs
  follow, because `PLAN.md` and `FEATURES.md` `Source:` lines both reference
  it.
- **Milestone order** is list position in the document. Identity carries no
  ordering information, so a milestone inserted between two others needs no
  renumbering.
- **Slice identity** is the `(milestone, section)` pair; slices have no
  independent identifier and no state.
- **Nothing derived is stored.** Coverage reports, readiness and progress are
  computed by [production-plan](./production-plan.md) and
  [plan-readout](./plan-readout.md) at read time.

The document is also the skill's resume state, in the same spirit as
`design-process.md` for `/product-design` — but with no separate marker
file, because a roadmap conversation is a single round rather than eight
phases. A re-run reads the existing document, proposes changes against it,
and writes behind one approval gate.

## Interfaces and contracts

**Exposes**, all as document structure:

- The ordered milestone list, with slugs — consumed by
  [production-plan](./production-plan.md).
- Per-milestone `Covers:` slices — consumed by
  [slice-aware-architecture](./slice-aware-architecture.md).
- `Goal:` and `Exit criteria:` — read by humans, and echoed by
  [plan-readout](./plan-readout.md).

**Expects:** the domain layer exists (`/domain-setup` has run).
`product-design.md` is read when present but not required — the skill is
usable from a bare description, as `/architect` is.

**Failure contract:**

- No domain layer → refuse, point at `/domain-setup`, create nothing. Same
  gate `/architect` and `/product-design` use.
- A `Covers:` entry naming a section absent from `product-design.md` → warn,
  do not refuse. The roadmap may legitimately run ahead of the design
  document.
- Editing a slice whose section already has architected features → warn and
  point at `/architect`; proceed on the user's say-so.
- `--commit` with nothing written → make no commit and say so.

## Dependencies

- **`/domain-setup`'s domain layer** — the directory, the domain `INDEX.md`,
  and `FEATURES.md`. Predates this feature index and has no slug here.
- **`product-design.md`** — read-only, and optional. Its section headings are
  the vocabulary `Covers:` entries are written in.
- No dependency on any feature in this index; this is the root of the
  planning chain. [slice-aware-architecture](./slice-aware-architecture.md)
  and [production-plan](./production-plan.md) both depend on it.
- No external dependencies. Markdown and Claude Code only.

## Open questions

- **Exit criteria are not checked against anything.** Moving a feature out of
  a milestone can leave that milestone's `Exit criteria:` unmeetable, and
  nothing detects it. An earlier design had an approval-gate check for this;
  it was dropped along with the coverage-completeness machinery, on the
  grounds that partial coverage is the normal case. The remedy today is
  reading `/production-status`'s derived coverage report against the criteria
  by hand. Blocks nothing; worth revisiting if a milestone ever ships against
  criteria it did not meet.
- **Slice edits after architecture are not propagated.** The warning above
  tells the user, but nothing flips the affected features to `[ITERATED]`,
  because that field is `/architect`'s. Detecting *which* features are
  actually stale would need either timestamps or a slice fingerprint stored
  per feature — both rejected for now as state this product does not keep.
- **Whether milestones should ever carry dates or estimates.** Excluded above
  for a personal workbench with no delivery commitments. If the pipeline is
  used on work with real deadlines, this is the first thing that will be
  missed.
- **Whether a milestone may cover a section with no slice statement**, i.e.
  "all of it". Convenient shorthand, but it reintroduces the completeness
  claim this design removed. Currently: every `Covers:` entry carries a
  scope statement.
