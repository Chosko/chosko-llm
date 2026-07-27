# Tech-stack selection

Read this ONLY when the project has no existing technology stack — a
greenfield repo, or a new subsystem with no precedent to follow. On a project
that already has a stack, skip it entirely and adopt what is there; the stack
is not a decision that gets re-opened per feature.

## The rule that comes first

**An existing stack wins.** If the project has a language, framework,
storage, or delivery mechanism already in use, that is the stack. Proposing
alternatives for a feature in an established codebase is not architecture, it
is churn. Say in one line that you are adopting the existing stack and move
on to the architecture.

This file exists for the case where there is genuinely nothing to adopt.

## Evaluation axes

Score candidates against the axes that matter for *this* product, not all of
them. Three or four axes chosen well beat a matrix of ten.

| Axis | The question it answers |
| --- | --- |
| Fit to the product | Does the stack make the product's central operation natural, or does it fight it? (Realtime, batch, offline-first, and document-heavy products each rule out different stacks.) |
| Team familiarity | Who is building this, and what do they already know? The best stack nobody on the team knows is usually the second-best choice. |
| Operational cost | What does it cost to run at the expected scale, and what does it cost to run at 1% of it? |
| Ecosystem | Are the two or three things this product needs solved libraries, or would they be built from scratch? |
| Deployment target | Where does it have to run — a user's machine, a browser, a phone, someone else's cloud, an air-gapped host? |
| Longevity | Will this still be maintained and hirable-for in five years? |
| Constraints | Anything non-negotiable: an existing platform, a compliance regime, a licence policy, a customer requirement. |

Constraints are checked first — they eliminate candidates, and eliminating is
cheaper than comparing.

## How to present candidates

Two or three candidates. One is not a choice; five is a research project.

For each:

- **What it is** — one line, in case the user doesn't know the stack.
- **Why it fits this product** — tied to something specific from
  `product-design.md` or the user's description, not to general merit.
- **What it costs** — the honest downside. Every stack has one; a candidate
  presented without a downside reads as a sales pitch and gets discounted
  accordingly.
- **What it would rule out** — the doors this choice closes later. This is
  the part users most often haven't considered.

Then **make a recommendation**, with the reason in one sentence. Presenting
three balanced options and no opinion pushes the decision back onto the user
without giving them anything they didn't already have.

Example shape:

> **Candidate A — <stack>.** <One line on what it is.> Fits because <specific
> tie to the product>. Costs: <the real downside>. Rules out: <doors closed>.
>
> **Candidate B — <stack>.** …
>
> **Recommendation: A**, because <the one thing that decides it>.

## Tie it back to the design

Every claim about fit must trace to something written down — a flow in
`product-design.md`, a target user, a stated constraint. When the design
doesn't say enough to decide, that is a PHASE 1 clarification, not a
judgment call to make quietly:

> Choosing between A and B depends on whether this has to work offline. The
> design doesn't say. Which is it?

## Recording the choice

The stack decision is **not** a feature. Record it where it belongs:

- **`product-design.md`, design decisions** — the choice and the one-line
  reason. It is a product-shaping decision and belongs in the high-level
  document, so a reader who never opens a feature document still knows what
  the product is built on.
- **Each feature document** — reference the stack, don't re-argue it. "Built
  on <stack> per the product design" plus whatever is feature-specific.

If `product-design.md` does not exist (the bare-prompt path), record the
decision at the top of the first feature document's Architecture section, and
say in the closing report that the stack decision is currently recorded
there and would be better placed in a product design document later.

## What not to do

- Do not choose a stack the user has not agreed to. Recommend; they decide.
- Do not re-open an existing stack because a different one would suit this
  feature better. If the mismatch is genuinely severe, say so once as a
  flagged concern and then design within the existing stack anyway.
- Do not spread the decision across every feature document. One place, plus
  references.
- Do not pick versions, package managers, or lint configs here. Those are
  implementation choices, and they belong to the tasks that set the project
  up.
