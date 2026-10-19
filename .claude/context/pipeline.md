# Features: product pipeline

## Overview

Covers the product pipeline's shipped artifacts: the design and planning
stages, their read side, the `pipeline-engine` reference library and the
features built on it, and the vendored `claude-council`. Feature kinds:
[features.md](./features.md); the frontmatter contract every one of them
follows: [feature-contract.md](./feature-contract.md).

Feature entries live in the family's files; this hub keeps the engine and the
entry point every stage shares:

- [product-design.md](./product-design.md) — `/product-design` and the vendored `claude-council`.
- [pipeline-planning.md](./pipeline-planning.md) — `/product-roadmap` and `/production-plan`.
- [architect.md](./architect.md) — `/architect`.
- [pipeline-readers.md](./pipeline-readers.md) — `/production-status` and `/pipeline-check`.
- [pipeline-revise.md](./pipeline-revise.md) — `pipeline-revise`: argument, classification, impact walk, lint bracket.
- [pipeline-revise-plan.md](./pipeline-revise-plan.md) — `pipeline-revise`: plan, gate, actuation, commit.

- `skills/pipeline-engine/` — second non-invocable reference library,
  beside `task-engine` and deliberately NOT merged with it (open question in
  `../domain/features/pipeline-engine.md`). Same pattern: no arguments, runs
  nothing, no output; `SKILL.md` is a MAP carrying no rule text, the
  not-invocable statement in its `#` header and
  `disable-model-invocation: true` in its frontmatter ([feature-contract.md](./feature-contract.md) § Public API). Four files under `references/`, one authority
  each: `probes.md` (fixed set of nine cheap filesystem probes describing a
  project's pipeline setup — `specs` counting the `*.md` files under
  `.claude/specs/` that `/quick-implement` leaves for `/pipeline-revise
  --catch-up`, the two writers that invalidate it — the one-line verdict every consumer prints
  identically, and the in-session reuse rule naming the writers whose runs
  invalidate a verdict; subagents re-probe), `graph.md` (how `FEATURES.md`,
  `TASKS.md`, `PLAN.md`, `RUNBOOKS.md` point at each other — each edge, its
  direction, authoritative side, writer and consumers, and which vanish with
  an absent index; an id at or below `Last task number:` with no block
  resolves archived and terminal; E6 is `File: .claude/runbooks/<id>-<name>.md`
  → body, a legacy `<name>.md` value legal during lazy migration),
  `routing.md` (one row per pipeline
  feature — Feature / Consumes / Produces / Owns / Preconditions / Argument
  shape / Amend — runbook rows take `<id|name|id-name>` and read bodies at
  `File:` — the ownership authority the revision suite reads; owned BY
  LINE, no two rows claiming one line or value; every row verified against
  the shipped body, never a design doc; agrees with the owner table of
  `task-engine`'s `references/design-change.md` and is the one fixed if they
  diverge), `lint.md`
  (closed catalogue of fourteen structural drift findings L1–L14, each with a
  detection rule over `graph.md`'s edges, severity `ERROR` or `WARNING` —
  two levels, deliberately clear of every status vocabulary — one fix command
  and a fixed output template written message first — `<SEVERITY>
  <message> (<artifact> <identifier>[, <evidence>]) → <fix>`, the
  plain-language rule of [interaction-engine.md](./interaction-engine.md)
  `messages.md`; two deliberate absences recorded: a `Tasks:`
  id absent from `TASKS.md` (archived, not drift) and a pending runbook step
  naming a finished task (needs a body read); absent index drops its
  findings, malformed block is its own `ERROR`; no rule probes
  `.claude/tasks/archive/`; L14 — a spec file still under `.claude/specs/`,
  `WARNING`, fixed by `/pipeline-revise --catch-up <spec>` — lists that
  directory and opens no spec). Consumers cite each file by a path
  relative to the citing body ([feature-contract.md](./feature-contract.md) § Internal patterns) and state only
  deviations. Two consumers: `/pipeline-check`, `pipeline-revise`. A third
  feature, `pipeline-suggest`, declares `requires: skill:pipeline-engine`
  but reads none of the four files. Routing table kept honest by repo-local
  `scripts/check-routing.sh`, whose invariants are
  `../../docs/authoring-guide.md` § The routing guard. Row shape (line beginning
  `` | ` ``, name inside first backquotes, one leading `/` stripped) shared
  with `probes.md`'s `installed` probe. Cell semantics not checked. No
  context file of its own — `CLAUDE.md` § Versioning says when to run it.
- `skills/pipeline-suggest/` — the pipeline's auto-suggested entry point
  (feature `pipeline-suggest`), built in `runbook-suggest`'s shape. Fires
  on a free-form request to build, change, fix, remove or sequence work that
  names no slash command. Anti-triggers, deliberately longer than the
  triggers: a question, a request naming a command, "just do it" /
  "directly", work under way in a `/task-implement` run, an enumeration
  inside an explanation, a follow-up list (`runbook-suggest`'s), any request
  while orchestrate mode is on (`interaction-engine`'s `mode.md`, answered
  from the conversation, file never opened; also
  `requires: skill:interaction-engine`), a project with neither index. Gate is TWO existence probes — `.claude/FEATURES.md`,
  `.claude/TASKS.md` — both absent → silence, an erroring probe counts as
  absent; no third probe, never the files' contents, NO reference file (not
  the engine's `probes.md`, not `routing.md`). Body carries an eight-row
  request-shape → command table (feature-sized addition `/architect`; bug /
  small change / chore `/task-add`; ANY change to planned work — wording fix,
  large change, insert, delete, reorder, or a list of them —
  `/pipeline-revise`; "what next" `/production-status`; "is the backlog
  consistent" `/pipeline-check`; follow-up list → none, `runbook-suggest`
  fires; design decision `/product-design`; milestone/release
  `/product-roadmap` or `/production-plan`) — NOT the engine's routing table
  (consumes / produces / owns), different job and content, noted so
  `/rule-overlap` reads the pair as intended. Output: silence on no match or
  the follow-up row alone; else at most TWO lines — the command (both when two
  rows match) plus the quoted matching phrase, optional second saying the
  parent may proceed directly; nothing of the request restated, no failure
  path adds a third. Never invokes, asks, gates or writes; no suppression list
  (would be a state file). `requires: skill:pipeline-engine,
  skill:pipeline-revise` — `requires:` is
  non-transitive, so the revision surface is named; the other commands the
  table names are deliberately not required. The engine is declared for
  installation, not reading, and that declaration is why `routing.md` carries
  a `pipeline-suggest` row (owns `Nothing`, Amend `—`) — `check-routing.sh`
  demands one.

## Public API

Each feature's contract is its bullet in its file's § Overview (listed above). Frontmatter,
`description` contract and loading-control keys:
[feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- [feature-contract.md](./feature-contract.md) § Internal patterns.
- The interaction policy: every stage, `/domain-setup`, `pipeline-revise`
  and `/pipeline-check` declare `requires: skill:interaction-engine` and
  accept `--attended` / `--unattended`
  ([interaction-engine.md](./interaction-engine.md)). `confirmation`: every
  amend gate (plain summary, `show` for the before → after; "Amended …"
  lines plain-language-first), `/production-plan`'s main gate when a
  reconciliation found nothing, `pipeline-revise`'s gate with no open
  question. `destructive`: `/product-design`'s discard. Everything else
  `design` — the conversational rounds, `/product-roadmap`'s gate.
  `/pipeline-check` has no gate. None of them parks.

## Domain dependencies

- `../domain/product-workflow.md` — pipeline stages, document set, feature
  and plan schemas.
- Frontmatter schema: [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds.
- [feature-contract.md](./feature-contract.md) — frontmatter contract, the
  home-path guard.
- [task-add.md](./task-add.md), [task-implement.md](./task-implement.md) —
  `/task-add` and `/task-implement`, the stages after `/production-plan`.
- [runbook-suite.md](./runbook-suite.md) — the runbook suite `pipeline-engine`
  and `pipeline-revise` reach.

## When to read the source

- [features.md](./features.md) § When to read the source.
