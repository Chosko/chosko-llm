# Features: product design and claude-council

## Overview

Covers stage 1 of the product pipeline, `/product-design`, and the vendored
`claude-council` its council gate (and `/architect`'s) delegates to. The rest
of the pipeline family: [pipeline.md](./pipeline.md).

- `skills/product-design/` — designs product top-down with user, writes
  result into domain layer: `design-process.md` (state
  file), `product-design.md`, `technical-direction.md`, and — only when
  user opts in — `business-model.md`. `amend.md`: the `amend "<change>"`
  form and the resume menu's arm C — one pinned change to a named section
  of one document on a complete design, one before → after gate, no phase,
  `design-process.md` compressed; headless when a revision surface passes
  its draft in and it matches. Eight phases: PHASE 0 gates on
  `/domain-setup` having run, auto-detects resume; PHASE 1 orients
  (greenfield vs. brownfield, read from CLAUDE.md/README/context
  layer/source tree), stubs documents plus their
  `.claude/domain/INDEX.md` rows (`technical-direction.md` stubbed
  unconditionally, since PHASE 6 always runs); PHASE 2 interviews; PHASE 3
  writes back then automatically sweeps conversation against what was
  just written — integrating any decision, constraint, flow detail,
  rejected alternative, or terminology documents don't cover
  (WHAT/HOW into `product-design.md`, business material into
  `business-model.md`, WHY/rationale into `design-process.md`'s "Decisions
  worth keeping" — no new approval gate, no-op when nothing missing)
  — before its report and stop; PHASE 4 identifies high-level feature set from
  user-experience angle; PHASE 5 records it; PHASE 6 is conversational
  round establishing product's technical foundations (stack, topology,
  data, async, hosting, protocols, cross-cutting concerns) — always runs,
  reads back which PHASE 4/5 features drive which choices, branches on
  greenfield/brownfield (confirm-and-record vs. propose-with-recommendation)
  — PHASE 7 writes it into `technical-direction.md`, standing constraint
  `/architect` designs within, then compresses `design-process.md`
  (delete-not-append: "Current stage" back to 1–2 sentences + per-document
  one-liners + next step, "Decisions worth keeping" back to flat undated
  terse bullets w/ superseded entries deleted outright — no dated revision
  headers, no `[SUPERSEDED]` retention, no closing-record essay) immediately
  before writing the process-complete marker, and says so in its report.
  Six supporting files load only when their branch fires: `amend.md`
  (above), `document-templates.md` (per-section stubs, read in PHASE 1,
  3, 5, 7), `business-model.md` (strategy question bank — opt-in
  only), `technical-direction.md` (technical question bank, read at
  start of PHASE 6 and again before PHASE 7 writes), `resuming.md` (read
  only when `design-process.md` already exists — also handles marker
  written before PHASE 6/7 existed, offering to continue rather than
  reporting the process complete; and, once the marker says the process
  *is* complete, offers a third arm first — **amend a decision**: edits the
  relevant document directly, re-runs no phase, leaves the marker on
  complete, and applies the same compression before the session ends, so an
  amendment leaves the file no larger than it found it), and `council-gate.md`
  (below). The stage marker in `design-process.md`
  is rewritten before every phase ends, so an interrupted session resumes
  from a truthful stage — there is no `resume` argument, since the document
  is the state. `council-gate.md` loads only when PHASE 6 reaches a genuine
  technical fork on the GREENFIELD branch: it delegates the decision to the
  claude-council skill this repo ships (detected **by name** — "is the
  `claude-council` skill available", per `../../docs/authoring-guide.md`
  § "Asking whether a feature is installed: name it" — silent and no-op when
  absent), invoked with no mode argument so
  claude-council's own Quick/Standard/Deep triage applies. The brownfield
  branch is excluded — confirm-and-record over an existing stack is not a
  fork. Dissent folds into `product-design.md`'s design decisions; the
  council's own report/transcript are owned by neither skill and never enter
  `WRITTEN` and are never staged; the `design-process.md` stage marker is not
  written when convening, since a mid-phase consultation is not a phase
  transition. Kept in step with the `/architect` copy — see
  `../../docs/authoring-guide.md`. `product-design.md` and `business-model.md` stay high-level
  by construction: implementation detail is `/architect`'s output;
  `technical-direction.md` is one document where stack and
  infrastructure detail belongs. Never writes `.claude/FEATURES.md`,
  feature docs, or tasks. **Commits by default — stages exactly the documents
  written, `design-process.md` included, in one commit and pushes**; `--no-commit` runs no git command, `--no-push` skips the push;
  `--commit` accepted as a silent no-op.
- `skills/claude-council/` — **vendored**, second of the two (see
  `skills/unity-mcp-skill/` in [setup-commands.md](./setup-commands.md) § Overview). Copy of upstream
  `TorpedoD/claude-council`: structured LLM-council pressure test for one
  high-stakes decision — five thinking-lens advisors, anonymised peer
  review, forced debate on suspiciously clean consensus, dual-chairman
  synthesis preserving dissent, plus a JSONL journal that feeds a
  meta-analysis loop. 15 files: `SKILL.md`, seven `references/`, four
  `scripts/` (jq-backed journal append/outcome/search + meta-analysis),
  `assets/report-template.html`, `evals/evals.json`, `journal/.gitkeep`.
  Two vendoring adaptations, re-applied on every upstream re-sync:
  frontmatter pinned (upstream's `|` block-scalar `description` breaks
  `parse_frontmatter`; `version` and `type` were absent), and every
  `~/.claude` literal replaced by the file-relative form (`./scripts/…`,
  `./journal/…`, resolved against the skill's own directory — its
  install-path note says so, because those paths appear in `bash` lines run
  from the project root). Ships
  but is **opt-in** — installed only by
  `chosko-llm add skill:claude-council`, which is exactly the path both
  `council-gate.md` copies detect, so an uninstalled council still makes
  the gate a silent no-op. Needs `jq` at run time (journal append,
  `/claude-council meta`) — documented, not engineered away; see
  `../../docs/authoring-guide.md` "Vendored skills".

## Public API

- See [pipeline.md](./pipeline.md) § Public API.

## Internal patterns

- See [pipeline.md](./pipeline.md) § Internal patterns.

## Domain dependencies

- See [pipeline.md](./pipeline.md) § Domain dependencies.

## Cross-references

- [pipeline.md](./pipeline.md) — the pipeline family hub.
- [architect.md](./architect.md) — `/architect`, whose `council-gate.md` copy
  is kept in step with `/product-design`'s.

## When to read the source

- See [pipeline.md](./pipeline.md) § When to read the source.
