# Business-model question bank

Read this only when the user opted into business modelling in PHASE 1 —
before the business-model part of PHASE 2's interview, and again before
writing `business-model.md` in PHASE 3.

This is a bank, not a script. Ask what the product needs; skip what does not
apply and say you are skipping it. A side project and a venture-backed
platform need different subsets, and working through all fifty questions on
an internal tool is how a designed process becomes a resented one.

Same rule as the rest of PHASE 2: **contribute, don't just ask**. When the
user's answer implies something they have not said — a channel that cannot
support that price, a cost that scales faster than the revenue — say so.

---

## Revenue model

- Who pays? Is the payer the same person as the user? (If not, everything
  downstream changes — the buyer's problem and the user's problem are
  different documents.)
- What exactly is being sold: access, usage, outcomes, a one-off artifact?
- Is revenue recurring or transactional? If recurring, what makes a
  customer keep paying in month twelve?
- Is there a free tier? What does it cost to serve a free user, and what
  makes one convert?
- Any revenue that is not the obvious one — marketplace fees, data,
  services, support?

## Cost structure

- What does it cost to build the first version? Roughly, in people and
  months rather than currency.
- What does it cost to run per month with zero customers?
- Which costs scale with usage, and against what unit — requests, seats,
  storage, LLM tokens, support hours?
- Which cost is the one most likely to surprise them? (Inference,
  egress, and support are the usual answers.)
- Is any cost step-shaped rather than linear — a plan tier, a hire, a
  compliance threshold?

## Target segments

- Which segment is first, and why that one rather than the larger one?
- What does that segment already spend on this problem?
- How reachable are they — is there a place they already gather?
- Which segment is deliberately NOT being served in v1?
- Does the product need multiple segments simultaneously to work at all
  (two-sided market)? If so, which side is harder to get, and what is the
  plan for the cold start?

## Pricing

- What is the price, roughly, and what is the unit?
- Anchored against what — the alternative they use today, the cost of the
  problem, or a competitor?
- Where does the price break down: the customer ten times larger, or ten
  times smaller?
- Is there a floor set by variable cost? What is the margin at the
  proposed price?
- Which parts of the pricing are decided and which are placeholders? (Mark
  this in the document — an unmarked guess reads as a decision later.)

## Go-to-market

- How do the first ten customers hear about this? Name the specific
  channel, not "marketing".
- How do the hundredth, given that the first ten usually come from the
  founder's network?
- Is the motion self-serve, sales-led, or community-led? Does the price
  support that motion? (A sales-led motion under a $20/month price is the
  classic mismatch.)
- What is the time from first contact to first payment?
- Are there partners or platforms this depends on? What happens if one
  changes its terms?

## Unit economics

- What is a customer worth over their life, at whatever precision is
  honest?
- What does it cost to acquire one, through the channel named above?
- What does it cost to serve one per month?
- How long until a customer pays back their acquisition cost?
- Which of these numbers is a real measurement, which is an estimate from a
  comparable, and which is a guess? Label each in the document — the
  labels are the most useful thing on the page.

## Risks

- What must be true for this model to work that is not yet known to be
  true?
- Which assumption, if wrong, kills it outright, versus merely hurts?
- What is the biggest competitive risk — an incumbent adding this as a
  feature, or a new entrant undercutting?
- What is the concentration risk: one customer, one channel, one platform,
  one supplier?
- Regulatory, legal, or data-protection exposure?
- Rank the risks before writing them down. An unranked list is a list
  nobody acts on.

---

## Writing it up

Fill the sections of `business-model.md` per `./document-templates.md`. Two
disciplines carry the most weight:

1. **Mark estimates as estimates.** Ranges as ranges, comparables as
   comparables. This document gets read months later as though it were
   researched; unlabeled numbers become false precision.
2. **State what was not asked.** If a section was skipped as not
   applicable, say so in one line rather than leaving the heading empty — an
   empty heading reads as an oversight, and the next session will try to
   fill it.
