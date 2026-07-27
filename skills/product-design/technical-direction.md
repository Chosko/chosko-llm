# Technical-direction question bank

Read this at the start of PHASE 6 — before the technical-direction
conversation — and again before PHASE 7 writes `technical-direction.md`.

This is a bank, not a script. Work through the axes that matter for *this*
product; skip what does not apply and say you are skipping it. A single-user
side project and a multi-tenant platform need different subsets of these
questions.

Same rule as PHASE 2 and PHASE 4: **contribute, don't just ask**. Confirm
what sounds right, flag a mismatch between a proposed choice and a feature
from PHASE 4/5, and offer a recommendation rather than an open-ended menu.

The axes below overlap with `skills/architect/tech-stack-selection.md` —
that file scores a stack for one feature against an existing product; this
one decides the product's technical foundations as a whole, before any
feature exists to score against. Read it for the evaluation-axes discipline
and the "present two or three candidates with a recommendation" shape; do
not read it any further than that here.

---

## Branch first: greenfield or brownfield

Use PHASE 1's judgement, already made.

- **Brownfield.** Open with what you already see — the language, framework,
  storage, and deployment target read from the repo in PHASE 1. State it and
  ask "is this still the intent?" rather than asking the user to re-derive
  it. Work through the axes below only for what is genuinely undecided —
  a new subsystem, a scaling change, a component the existing stack does not
  cover.
- **Greenfield.** Work through every axis that applies. For any axis with a
  real choice, propose two or three candidates, state the trade-offs, and
  recommend one — never leave the user with an unranked list.

## Stack

- Primary language(s) and framework(s) — one per major component if they
  differ (e.g. a different stack for a background worker than for the API).
- Which PHASE 4/5 features force this choice, and how?

## Topology / architecture shape

- Monolith, modular monolith, or services? What is the actual reason —
  team size, deploy independence, scaling a specific component, or is it
  cargo-culted from elsewhere?
- If services: how many, split along what boundary, and which feature from
  PHASE 4/5 is the seam?
- What is the largest single component doing, and does anything in the
  feature set threaten to overload it?

## Data and storage

- Primary data store(s) — relational, document, key-value, blob, search,
  time-series — one per distinct data shape the features need, not one by
  default.
- Which feature has the data model that decides this (e.g. relational
  invariants, full-text search, high write throughput)?
- Where does file/blob storage live, if any feature needs it?

## Async / queueing

- Does anything need to happen outside the request/response cycle — background
  jobs, scheduled work, fan-out, retries? Which feature drives it?
- If yes: queue, message broker, or scheduled job runner — and why that
  shape rather than a synchronous call?
- If no: say so explicitly rather than leaving the section silently empty.

## Hosting and deployment target

- Where does this run — a user's machine, a browser, a phone, a managed
  cloud, self-hosted infra, an air-gapped environment?
- Single environment or a promotion path (dev → staging → prod)?
- What does deploying a change look like, roughly — the mechanism, not the
  tooling detail? (CI/CD specifics are a task, not a direction.)

## Inter-component protocols

- How do the pieces talk to each other and to clients — REST, RPC,
  GraphQL, WebSockets, message passing, shared database, CLI/IPC?
- Any protocol forced by a specific feature (realtime needs a persistent
  connection; offline-first needs a sync protocol)?

## Cross-cutting concerns

- Auth/identity — is there one, and roughly what shape (sessions, tokens,
  third-party identity)?
- Observability — does this need logs/metrics/traces from day one, or is
  that premature for the product's current stage?
- Testing approach — is there a default the stack implies, or is this
  explicitly deferred to implementation time?
- Anything regulatory, compliance, or data-residency related that constrains
  the above?

## Explicitly-open decisions

- Which axes above were discussed but left undecided, and why (needs a
  prototype, needs a team decision, genuinely doesn't matter yet)? Mark
  these as open in the document — an unmarked gap reads as an oversight to
  a later reader, and `/architect` needs to know it is allowed to decide
  this one itself rather than treating it as settled.

---

## Writing it up

Fill the sections of `technical-direction.md` per `./document-templates.md`.
Two disciplines carry the most weight:

1. **State the decision, not the debate.** Same documentational register as
   `product-design.md` — a reader six months from now needs the current
   truth, not the alternatives that were rejected and why. Rationale that
   must survive belongs in `design-process.md`.
2. **Mark what's still open.** A section that says "not yet decided — needs
   X" is more useful to `/architect` than a guess dressed up as a decision.
