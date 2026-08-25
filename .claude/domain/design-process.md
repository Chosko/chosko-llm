# Design process

The state of this project's `/product-design` run. `/product-design` reads
this file to decide where to resume; nothing else records that.

## Method

Top-down product design. The user and Claude work through the phases below
conversationally; each phase's output is written into `product-design.md`
(and `technical-direction.md` in the final phases) before the next phase
begins.

Greenfield or brownfield: brownfield — a shipping CLI, ~20 commands and
skills, four domain workflow docs, and a full context layer already exist.
Business modelling: out of scope

## Phases

| Phase | What it does | State |
| --- | --- | --- |
| 0 — gate + resume | Verify the domain layer; resume or start fresh | done |
| 1 — orient + stub | Detect greenfield/brownfield, create the documents | done |
| 2 — interview | Product, users, experience, big decisions | done |
| 3 — write-back | Fill product-design.md | done |
| 4 — high-level features | Identify the feature set, user-experience angle | done |
| 5 — feature write-back | Record the feature set in product-design.md | done |
| 6 — technical direction | Decide the product's technical foundations | done |
| 7 — technical write-back | Record the direction in technical-direction.md | done |

## Current stage

**PHASE 7 — technical write-back: done. The process is complete.**

`product-design.md` holds the product summary, target users, key flows,
design decisions, and the ten high-level features;
`technical-direction.md` holds the confirmed stack, topology, storage,
deployment, protocols, cross-cutting concerns, and four explicitly open
decisions. Nothing remains for `/product-design` to do. The next step in
the pipeline is `/architect <feature>` on any of the ten features, then
`/task-add feature=<slug>`. A later run of `/product-design` would be a
redesign, not a resume.

## Decisions worth keeping

- **Why an authoring environment and not just a distribution channel.**
  Storing and deploying existing commands was never the whole need. The
  product had to also support designing, planning, implementing, and
  maintaining features. That is why the domain layer, context layer, and
  task backlog are part of the product rather than incidental repository
  hygiene.
- **Why the two-repository split survives its friction.** Working repository
  and managed clone must both be upgraded and updated, which costs a step
  every time. The alternative — one copy, or symlinks — was rejected because
  it removes the sandbox: unfinished work would immediately affect every
  terminal already using the tool. The friction is the price of that
  isolation, and it was judged worth paying.
- **Why the authoring ergonomics are Claude's, not a human's.** The director
  does not hand-write feature markdown; Claude implements everything,
  version bumps included. This is why the authoring loop has caused no pain
  in practice, and why structure aimed at an LLM operator (explicit
  contracts, navigable layers, approval gates) matters more than editor
  conveniences.
- **Rejected alternatives.** A dotfiles repository with symlinks was the
  obvious baseline and was rejected: it distributes files but offers nothing
  for designing or maintaining them, and symlinks remove the sandbox.
  Packaging routes such as language package managers were considered in
  passing and set aside in favour of something the owner could fully manage
  and change; the remaining options were not investigated in depth, since
  the chosen approach already met the need.
- **Why local drift is not addressed yet.** `--local` deployment can leave a
  repository pinned to an older copy of a feature, and `ls` / `update` have
  no local awareness. The current implementation is deliberately cheap (a
  `CLAUDE_HOME` override). The decision is to measure the impact before
  adding complexity, not to pre-empt it.
- **Why governance is one writer plus pull requests.** The owner holds write
  access; authoring teammates contribute through pull requests. This is
  acknowledged as imperfect and was chosen to avoid scope creep, not because
  it is the desired end state.
- **What success looks like.** A new machine reaches a full configuration in
  one command, and a feature idea reaches `~/.claude/` the same day without
  the director writing prompt markdown by hand.
- **Where the feature seams were drawn.** Listing and deploying features
  were merged into one feature: seeing the installed-versus-available gap
  and closing it are the same act, and neither can be described without the
  other. Designing and planning were kept apart — the product design
  pipeline ends at the feature document and the task backlog begins there,
  which makes the handoff a document rather than a conversation. The
  frontmatter and versioning contract was considered as a feature and
  rejected as one: it is a constraint every artifact obeys, already recorded
  under design decisions, and naming it a feature would give `/architect`
  nothing to design.
- **Why the feature section points instead of restating.** Four workflow
  documents already specify the mechanisms behind the authoring features.
  The high-level feature entries describe the experience and link to those
  documents, so a schema or status vocabulary has exactly one home and
  cannot drift between two.
- **Why no exit condition was set for the dependency ban.** A trigger was
  proposed — the day `parse_frontmatter` cannot express something a feature
  needs — and rejected in favour of keeping it simple and deciding when the
  problem actually arrives. Consistent with the standing position that
  nothing changes before the need is demonstrated. The same reasoning
  covers CI: the repo's authoring guards are written by Claude for Claude
  to invoke, and automating them was declined.
