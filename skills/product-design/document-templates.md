# Document templates

Read this in PHASE 1, when stubbing the documents, and again in PHASE 3 and
PHASE 5, when filling them.

Two rules apply to every template here:

- **Stub, don't invent.** In PHASE 1 write the headings and the one-line
  descriptions of what each section will hold, nothing more. A stub that
  guesses at content produces a document the user has to un-write.
- **Documentational register.** These files state what the product is, not
  why the argument went the way it did. Rationale that must survive belongs
  in `design-process.md`.

---

## `design-process.md`

The state file. Written first, rewritten at every phase transition.

```markdown
# Design process

The state of this project's `/product-design` run. `/product-design` reads
this file to decide where to resume; nothing else records that.

## Method

<One paragraph: top-down product design. The user and Claude work through
the phases below conversationally; each phase's output is written into
product-design.md (and business-model.md when in scope) before the next
begins.>

Greenfield or brownfield: <which, and the one-line reason from PHASE 1>
Business modelling: <in scope | out of scope>

## Phases

| Phase | What it does | State |
| --- | --- | --- |
| 0 — gate + resume | Verify the domain layer; resume or start fresh | done |
| 1 — orient + stub | Detect greenfield/brownfield, create the documents | <not started \| in progress \| done> |
| 2 — interview | Product, users, experience, big decisions, business model | <…> |
| 3 — write-back | Fill product-design.md and business-model.md | <…> |
| 4 — high-level features | Identify the feature set, user-experience angle | <…> |
| 5 — feature write-back | Record the feature set in product-design.md | <…> |

## Current stage

**PHASE <N> — <name>: <not started | in progress | done>**

<One or two sentences: what the last session finished, and what the next
one should pick up. Written for a reader who has forgotten everything.>

## Decisions worth keeping

<Rationale that would otherwise be lost with the conversation — the
alternatives considered and why they were rejected. Grows across sessions;
append, don't rewrite. Omit the section until there is something to put in
it.>
```

The **Current stage** block is what a resume reads. Keep it truthful even
mid-phase: "PHASE 2 — interview: in progress. Covered users and the two
main flows; the big design decisions are not started."

---

## `product-design.md`

The product design itself. Sections in this order. PHASE 3 fills the first
four; PHASE 5 fills the last.

```markdown
# <Product name>

<One paragraph a user of the product would recognize as describing it.
What it is and what it is for — not how it is built.>

## Target users

<Who they are, what they are doing when they reach for this, and what they
use today instead. One short subsection or paragraph per distinct user
type; most products have one or two, not six.>

## User experience and key flows

<The two or three journeys that matter most, each walked end to end from
the user's side: what they do, what they see, what they get. Prose or
numbered steps, whichever reads better. No screens-as-wireframes and no
component names.>

## Design decisions

<The choices that shape everything downstream, stated as decisions rather
than options: what this product does and does not do, what it optimizes
for, what it deliberately leaves out. One bullet or short paragraph each.
State the decision; if the reason is inseparable from it, one clause is
enough.>

## High-level features

<Written in PHASE 5, one subsection per feature.>

### <Feature name>

<What it does, from the user-experience angle, at medium-high detail:
enough for /architect to start from and enough to tell it apart from a
neighbouring feature. Names the user and the flow from above that it
serves. No components, data models, libraries, file names, or APIs.>

<Repeat per feature, in the order the product is experienced rather than
the order it would be built.>
```

In PHASE 1, write the headings plus a one-line note of what each will hold.
In PHASE 3 and 5, replace those notes with the content.

If a `product-design.md` already exists hand-written, keep its structure and
extend it — map its sections onto these where they correspond, and add the
missing ones. Do not restructure a document the user wrote to match this
template.

---

## `business-model.md`

Created ONLY when the user opted into business modelling in PHASE 1.
Sections in this order; see `./business-model.md` (the question bank) for
what to ask before filling them.

```markdown
# Business model — <Product name>

## Revenue model

<How the product makes money: the mechanism, not the projection. Which
side pays, for what, and when.>

## Cost structure

<What it costs to run and to build. Split fixed from variable, and name
the costs that scale with usage — they drive the unit economics below.>

## Target segments

<Which segments are being sold to, in priority order, and why that order.
Ties back to product-design.md's target users; where the paying customer
and the user differ, say so explicitly.>

## Pricing

<The pricing model (per seat, usage, tier, one-off, free + paid), the
rough levels, and what a customer gets at each. Say which parts are
decided and which are placeholders.>

## Go-to-market

<How the first customers are reached, and how the tenth and hundredth are
reached differently. Channels, motion, and what has to be true for each to
work.>

## Unit economics

<What one customer is worth and what one costs to acquire and serve, at
whatever precision is honestly available. State the assumptions inline;
an unmarked guess here is worse than an admitted range.>

## Risks

<What would break this model: the assumptions it rests on, the ones most
likely to be wrong, and any that are already known to be shaky. Rank them
— an unranked risk list is not actionable.>
```

Precision discipline: this document will be read later as though it were
researched. Mark estimates as estimates and ranges as ranges, every time.
