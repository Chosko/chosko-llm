# Features: product pipeline

## Overview

Covers the product pipeline's shipped artifacts: the design and planning
stages, their read side, the `pipeline-engine` reference library and the
features built on it, and the vendored `claude-council`. Feature kinds and the
frontmatter contract every one of them follows: [features.md](./features.md).

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
- `skills/architect/` — stage 3 of product pipeline: turns one or more
  high-level features into low-level feature documents under
  `.claude/domain/features/`, each indexed by `.claude/FEATURES.md` entry.
  Input is `product-design.md` section, named features, or bare
  free-form prompt (usable on codebase that never ran
  `/product-design`); with no argument lists design's features and
  asks. Input resolution has TWO modes, in two on-demand files (below),
  dispatched PER TARGET rather than per run: slice mode activates purely on
  `.claude/domain/product-roadmap.md` carrying at least one milestone with a
  `Covers:` line (no flag file, no settings key, no frontmatter switch), and
  a target whose section that roadmap does not slice takes the traditional
  path anyway, stated in one line; a project with no roadmap takes the
  traditional path. `--no-slices` forces traditional
  mode per run (silent no-op where there is no roadmap). PHASE 0 gates on
  `/domain-setup`, reads design/technical-
  direction/feature/context layers, probes for the roadmap, detects whether stack exists — a
  present `technical-direction.md` counts as stack that exists, exactly
  like established codebase, so PHASE 2a skipped and
  `tech-stack-selection.md` never read on that path; PHASE 0b is iterate guard; PHASE 1 clarifies (skipped when nothing ambiguous,
  writing answers back into `product-design.md`); PHASE 2 architects
  conversationally, top-down — when `technical-direction.md` exists it
  designs within it and names the document in one line, and a genuine
  mismatch is flagged once and designed around rather than silently
  overridden (the remedy is re-running `/product-design`, never editing
  the document) — stopping at mid-to-high technical level, no code, no
  file-by-file plans, those being `/task-add`'s output; PHASE 3 writes the
  documents, the `FEATURES.md` entries, the INDEX rows, and any upstream
  design change. Seven supporting files load only on their branch:
  `sectioned-input.md` and `sliced-input.md` — the two input-resolution
  modes, mutually exclusive per target and never both read for the same
  target: `sectioned-input.md` when the target resolves traditionally (no
  roadmap, or `--no-slices`, or a roadmap that does not slice this target's
  section), matching against `product-design.md` sections and existing
  `FEATURES.md` slugs; `sliced-input.md` when a roadmap slice matches the
  target, carrying slice resolution (one match architects it, several across
  milestones ask, the union is never architected and the milestone never
  guessed), the exact-then-prose section matching rule, the slice's
  exclusions flowing into the feature document's non-goals, and the extended
  `Source:` — then
  `iterating.md` (the feature already has an entry), `amend.md` (the
  `amend feature=<slug>[,<slug>...] "<change>"` argument form; replaces
  input resolution, PHASE 0b and PHASES 1–3 for the run: per feature, edits
  only the sections the change names, dropping a feature the change can't
  be scoped to; runs a PRECISION iterate guard — each live task classified
  touched or untouched from its summary block, body opened only when that
  can't decide, a body that decides counting as a mechanical signal — that
  drops the feature only on a touched `[IN PROGRESS]` task and stales only
  touched tasks; one gate with a section per feature settling whether the
  change is editorial — CLEAR cases (task touched on summary block or body,
  or nameable added scope → not editorial; empty touched set, no scope, no
  contract text changed → editorial) print a `Classified:` evidence line
  and write with no reply; AMBIGUOUS cases (a body still undecided,
  borderline scope call, findings pointing different ways) ask A/B/C with
  the letter derived from touched set and scope call (empty and none → A,
  else B), one reply answering every asked feature — under
  `/pipeline-revise` it applies the carried classification with no prompt
  when its own derivation agrees, and the stricter one, not editorial over
  editorial, with no prompt and the deviation in the closing line when it
  differs; `product-design.md` upstream edit drafted once; one commit; no
  progress marker), `tech-stack-
  selection.md` (no existing stack in either form — an existing stack
  always wins), `council-gate.md` (PHASE 2 hit a genuine design fork —
  optional delegation to the claude-council skill this repo ships at the
  stack choice, the architecture shape, and the low-level split; detected
  **by name** ("is the `claude-council` skill available"), silent and no-op
  when absent, invoked with
  no mode argument, dissent folding into the feature document's Open
  questions, its verdict recorded in the PHASE 2 progress marker so a
  resumed session never re-convenes, and its report/transcript kept out of
  `WRITTEN` under a second narrow carve-out to the "nothing written before
  PHASE 3" rule; kept in step with the `/product-design` copy),
  `feature-doc-template.md` (PHASE 3, always; its
  Architecture section opens with a stack reference — "Built on <stack> per
  the product design", naming `technical-direction.md` when that's the
  source — rather than restating the choice). Writes `Status:` / `Doc:` /
  `Source:` in `FEATURES.md` and never `Tasks:` — the by-line split that
  lets it share the file with `/task-add`. `Source:` carries an optional
  ` (<milestone-slug>)` suffix written only in slice mode
  (`product-design.md § Authentication (m1-mvp)`), absent on traditional-mode
  and `prompt` features, and the sole mechanism by which
  a low-level feature knows its milestone. Reads `product-roadmap.md`, never
  writes it, and never reads `PLAN.md`. The only writer of `[STALE]`:
  the iterate guard refuses outright while any generated task is
  `[IN PROGRESS]` (no override), else asks, then flips surviving
  non-`[DONE]` tasks to `[STALE]` and feature status to `[ITERATED]` (from
  `[PLANNED]` or `[DONE]`). Guard's two halves decided by different fields:
  task half (list, refuse, ask, `[STALE]` flip) runs only when `Tasks:` IDs
  actually resolve — `Tasks: none` and IDs resolving to nothing are the same
  case, neither an error, and skip it with no ask and no `TASKS.md` write;
  status half always keyed on entry's own `Status:` (`[NEW]` and `[ITERATED]`
  self-transition, `[PLANNED]`/`[DONE]` → `[ITERATED]`, named in closing
  report). An ID absent from `TASKS.md` is archived and terminal
  (`resolution.md` § *The archive*), so it has nothing to refuse on, ask
  about or mark `[STALE]`. That guard and `amend.md`'s precision guard are the
  only reasons it touches `.claude/TASKS.md`; both write nothing there but
  `Status:` lines. Slugs
  stable, never renamed. Never writes `technical-direction.md` — that
  is `/product-design`'s document. **Commits by default — stages exactly the
  written paths (including TASKS.md when guard fired) in one commit and
  pushes**; `--no-commit` runs no git command, `--no-push` skips the push;
  `--commit` accepted as a silent no-op. **`amend.md` run by path keeps no default
  of its own — only `/architect amend` inherits this one.**
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
- `skills/claude-council/` — **vendored**, second of the two (see
  `skills/unity-mcp-skill/` in [features.md](./features.md) § Overview). Copy of upstream
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
- `commands/production-status.md` — read side of the planning layer. Thin
  read-only reporter (a command, not a skill: no conversation, no supporting
  files) joining `.claude/PLAN.md`, `.claude/FEATURES.md`, `.claude/TASKS.md`
  and `.claude/domain/product-roadmap.md`, all read-only. Eight output
  sections in fixed order: the milestone (slug, title, `Status:`, plus `Goal:`
  and `Exit criteria:` echoed verbatim from the roadmap); its features in plan
  order as a five-column markdown table (`#`, `Feature`, `Status`, `Tasks`,
  `Next`) — the rendering is prescribed in the body, not left to the agent;
  the ready set;
  the ONE recommended next feature (first ready in plan order); blocked
  features each named with what blocks it and why; coverage gaps (milestones
  with `Features: none`, plus `product-design.md` sections no `Covers:` names);
  unplanned features (`FEATURES.md` slugs missing from the plan, plus
  `Unscheduled`); remaining milestones one line each. Section 4 ECHOES the
  recommended feature's section-2 Next value rather than recomputing a next
  step from the rollup — one action rule per report, so the recommendation
  cannot contradict the row above it. A `[DONE]` feature has
  no readiness of its own computed — reported plainly, never in the ready
  set, the blocked list, or the recommendation, though it still satisfies
  edges dependents point at it. READINESS otherwise is the only computation
  and is derived every read, never stored: ready when every edge
  pointing at the feature comes from a feature `[DONE]` in `FEATURES.md`, or
  `[PLANNED]` with all tasks `[DONE]`/`[SKIP]` or archived; no edges → ready; else
  blocked. An edge
  slug resolving to no feature FAILS OPEN — reported as a plan inconsistency,
  feature treated as ready. Section 2's last column is NOT readiness but
  **Next**, derived from status + rollup + readiness and exactly one of
  `-` (`[DONE]`), `/task-add feature=<slug>` (`[NEW]`/`[ITERATED]`), `flip to
  [DONE] in FEATURES.md` (`[PLANNED]`, nothing left but `[DONE]`/`[SKIP]`/
  archived tasks, an all-archived `Tasks:` line and the zero-task case
  included), `/task-implement <N>` (`[PLANNED]`, work
  left, not blocked — N the first open task, never an archived id —
  `task-engine`'s eligibility clause stated inline, fed by the
  summary blocks already read, so no new read and still never a body),
  `blocked by <slug>` (checked first, whatever the preconditions say) or
  `waits on task <id>` (not blocked, but every open task has an unmet
  precondition; names the first such task's unmet ids) — blockedness
  suppresses ONLY `/task-implement`, since planning and a bookkeeping flip are
  never blocked by a dependency. Task rollup is counts per status by default,
  `--task-ids` names each ID; an ID absent from `TASKS.md` is archived and
  terminal (`resolution.md` § *The archive*, named as the rule's home, never
  opened) and is REPORTED, not ignored — `archived: N` joins the same rollup
  line and its total (`[archived]` per ID under `--task-ids`), lowercase
  because it is not a status, counted from absence alone with nothing probed
  under `.claude/tasks/archive/`. Zero tasks is a literal `Tasks: none` only
  (an all-archived line renders `archived: N`): `-` on a `[DONE]`/`[PLANNED]`
  feature (those states are post-`/task-add`, so `none` there means a
  backlog cleaned before task archiving, when `/task-clean` dropped IDs from
  the line) and `no tasks yet` only on `[NEW]`/`[ITERATED]`, in both rollup
  modes; `milestone=<slug>` scopes sections 1–5 and an
  unknown slug stops listing available slugs (matching `/task-add
  feature=<slug>`). Staleness is STRUCTURAL, never temporal — names slugs
  missing from `PLAN.md`, never compares `Last reconciled:` against dates or
  mtimes. Failure contract is degradation throughout (no roadmap omits
  goal/exit criteria, no `TASKS.md` drops rollups, no `[ACTIVE]` reports the
  first `[PLANNED]`); the only stops are a missing `PLAN.md` and an unknown
  `milestone=`. Writes nothing, runs NO shell command of any kind, never opens
  a file under `.claude/tasks/` (the archive included), and never starts the
  work it recommends.
- `skills/pipeline-engine/` — second non-invocable reference library,
  beside `task-engine` and deliberately NOT merged with it (open question in
  `../domain/features/pipeline-engine.md`). Same pattern: no arguments, runs
  nothing, no output; `SKILL.md` is a MAP carrying no rule text, the
  not-invocable statement in its `#` header and
  `disable-model-invocation: true` in its frontmatter ([features.md](./features.md) § Public API). Four files under `references/`, one authority
  each: `probes.md` (fixed set of cheap filesystem probes describing a
  project's pipeline setup, the one-line verdict every consumer prints
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
  the shipped body, never a design doc; agrees with `/task-add`'s
  DESIGN-CHANGE CHECK table and is the one fixed if they diverge), `lint.md`
  (closed catalogue of thirteen structural drift findings L1–L13, each with a
  detection rule over `graph.md`'s edges, severity `ERROR` or `WARNING` —
  two levels, deliberately clear of every status vocabulary — one fix command
  and a fixed output template; two deliberate absences recorded: a `Tasks:`
  id absent from `TASKS.md` (archived, not drift) and a pending runbook step
  naming a finished task (needs a body read); absent index drops its
  findings, malformed block is its own `ERROR`; no rule reads a body or
  probes `.claude/tasks/archive/`). Consumers cite each file by a path
  relative to the citing body ([features.md](./features.md) § Internal patterns) and state only
  deviations. Two consumers: `/pipeline-check`, `pipeline-revise`. A third
  feature, `pipeline-suggest`, declares `requires: skill:pipeline-engine`
  but reads none of the four files. Routing table kept honest by repo-local
  `scripts/check-routing.sh`, whose invariants are
  `../../docs/authoring-guide.md` § The routing guard. Row shape (line beginning
  `` | ` ``, name inside first backquotes, one leading `/` stripped) shared
  with `probes.md`'s `installed` probe. Cell semantics not checked. No
  context file of its own — `CLAUDE.md` § Versioning says when to run it.
- `commands/pipeline-check.md` — second read-only reporter of the pipeline,
  beside `/production-status`, and like it spanning the whole pipeline
  rather than a stage. Command not skill (single pass, no supporting files);
  declares `requires: skill:pipeline-engine` and restates no probe, edge or
  finding — cites all four engine files by path. Probes (or reuses a verdict
  already in the conversation), reads each of `.claude/FEATURES.md`,
  `.claude/TASKS.md`, `.claude/PLAN.md`, `.claude/RUNBOOKS.md` that exists,
  evaluates `lint.md` over `graph.md`'s edges, prints findings in one fenced
  block grouped by artifact in fixed order (`FEATURES.md`, `PLAN.md`,
  `TASKS.md`, `RUNBOOKS.md`), each line from its `lint.md` template with its
  fix verbatim, closing on a count of both severities; clean run prints
  exactly ONE line naming the indexes read. `feature=<slug>` keeps only the
  findings touching that feature — its entry, tasks whose `Feature:` names it
  or whose id is on its `Tasks:` with their precondition findings and
  cycles, plan lines naming it; no runbook finding in scope (`RUNBOOKS.md`
  ties no runbook to a slug). Unknown slug, or no `FEATURES.md`, said in one
  line and the unscoped report runs. Failure contract is degradation: absent
  index drops its findings, malformed block reported, unrecognised argument
  named and ignored; ONLY stop is a project with none of the four indexes,
  pointed at `/task-setup` / `/domain-setup`. Reports, never fixes: writes
  nothing, commits nothing, flips no status; no exit-code contract, no
  `--fix`, no `--quiet`. Opens no file under `.claude/tasks/archive/` or
  `.claude/domain/features/`; under `.claude/tasks/` and `.claude/runbooks/`
  it opens exactly the bodies `lint.md`'s two parking findings name — L12, a
  `[PARKED]` task with no `## Parking handoff` (`ERROR`, fix
  `/task-implement <N>` attended), reading each parked task's body for the
  heading; L13, a runbook whose `[P]` steps and index `Parked:` line disagree
  (`WARNING`, fix `/runbook-run <id>`), reading each non-`[DONE]` runbook's
  body for its markers, never a prompt block — and no branch probe; `feature=`
  keeps L12 on a parked task in scope. The filesystem probe is
  its only shell use — the one stated departure from `/production-status`,
  which runs none. Runs only when invoked; no pipeline writer auto-runs it.
- `skills/pipeline-revise/` — the pipeline's ONE revision surface (feature
  `pipeline-revision`). Explicit, never auto-triggered. `requires:
  skill:pipeline-engine, skill:architect, skill:task-engine,
  skill:runbook-run, skill:product-design, skill:production-plan,
  skill:product-roadmap` — the engine plus every owner whose amend arm a step
  may drive. `SKILL.md` carries the workflow; four flat supporting files, one
  per branch — `amend.md`, `insert.md`, `delete.md`, `reorder.md` — read ON
  DEMAND, one per kind a run's items classify into, each once, never one no
  item needs; all four share one seven-section schema (*Applies when*,
  *Impact walk*, *Owner sequence*, *Tier*, *Verification*, *Outcomes*,
  *Never*). **Argument is a change set**: `"<change set>"` — free-form text
  describing however many changes, or a numbered list in `/follow-ups`'
  output shape (one item per number); free-form splits into items at the
  changes it describes, the split said back at the gate for the user to
  correct. `<anchor> "<change>"` is also accepted for a single item. Anchor,
  four forms: `feature=<slug>`, `task=<N>`,
  `runbook=<id|name|id-name> step=<n>` (resolved by `runbook-schema.md`'s
  rule), and a milestone named in an item's own text (`m3`, an exit criterion
  quoted) resolving to a `##` block of `product-roadmap.md` — that last has
  NO argument form. The argument anchor applies to every item naming no
  artifact of its own; an item naming one uses its own; an item anchored on
  nothing, or an anchor resolving to nothing, stops the whole run listing
  what exists (archived vs never-assigned task id said), never picks between
  two. CLASSIFY per item, first-match in order reorder → delete → insert →
  amend (amend = everything else, incl. a milestone line and a
  `Preconditions:` change that moves no entry — the boundary `reorder.md`
  states so classification stays unambiguous); a change set spanning four
  kinds is ONE run. Impact walk per item, both directions over `graph.md`'s
  edges and no other traversal — top-down design section → features → tasks,
  plan edges, runbook steps; bottom-up task → feature doc when `Feature:`
  resolves (an unresolved slug stops the upward walk, not an error), plus
  forward to E4 successors. Whether the walk continues FROM those successors
  is per branch and written down in each: `amend.md` continues from every
  successor whose basis changes — up to that successor's own feature doc
  (E3b, then E2), stopping on an unresolved slug as for the anchor, then
  forward again (E4) — and `delete.md` the same from every successor whose
  edge is dropped AND whose basis is thereby withdrawn, which is what keeps a
  reorder (drop then replace with the same spec) from walking up spuriously;
  `insert.md` explicitly does NOT, a successor gaining a wait edge still
  delivering what it did; `reorder.md` inherits both. Every node visited once
  ACROSS THE WHOLE SET — an artifact two items reach is one entry. A doc
  reached that way is named from index lines and enters the owner sequence as
  an `/architect amend` step, never opened here — whether it needs a change is
  that arm's call. May open bodies, scoped per item: the target artifact,
  tasks whose `Preconditions:` name it or whose `Files:` overlap, runbook
  steps naming it, PLUS what a headless arm reads to make a decision the plan
  takes for it (for `/architect amend`, the feature's tasks' summary blocks,
  a body only when the block cannot decide); never bulk, never the archive.
  Lint bracket: `/pipeline-check` scoped to the union of the items' features
  (unscoped when an item anchors on a runbook or a milestone) BEFORE the
  proposal and AFTER actuation (also when stopped part-way), report shows
  cleared / created / unchanged; plus a successor-body read wherever an
  insert, delete or edge change moved a precondition — reported, never fixed.
  **Merge**: two items reaching one artifact become one step — several
  sections of one feature doc one `/architect amend` naming them all, several
  docs one multi-slug run, every roadmap edit one `/product-roadmap amend`,
  every plan edit one `/production-plan amend`, every design edit one
  `/product-design amend`, one runbook's inserts one `/runbook-create
  --append`. **Order** upstream first across items: design → feature docs →
  task amends → removals → task insertions and `/task-add` reconciliation →
  plan → runbook strikes, facts, insertions; a step consuming an earlier
  step's output follows it whatever the kinds say. **Decide at plan time**:
  every decision an owner's arm makes by a closed rule over its reads is
  taken in the proposal and shown on its step — `/architect amend`'s
  editorial classification (per `../architect/amend.md` § 4 over the touched
  set and the scope call), the drafted task fields and body sections, a
  struck id + reason or dated `Context:` fact, the drafted design / roadmap /
  plan edits — and that step is tagged **headless**: runs with the decision
  carried in, asks nothing, the arm writing without a second gate when the
  draft matches its own. `/task-add` create and reconcile, the one owner whose
  work is drafting, are tagged **GATED** with one `Will ask:` line and sort
  LAST wherever the order allows, so every headless write lands before the
  first stop. A reconciliation step is conditional and shows its evidence
  (`because step 1 stales 12, 14`; none rendered when the carried
  classification is editorial for every feature); an id unknown until a step
  runs is a placeholder (`<id from step 5>`) in every later step. Tiers
  editorial / local / structural set a sequence's length, judged by the
  branch file (`reorder.md` fixed structural; `insert.md` structural when it
  adds scope, local when the doc already promises it; `delete.md` local only
  for a task nothing else names — insert/delete/reorder never editorial);
  only a borderline wording-vs-meaning architect classification stays open.
  ONE gate, and it ALWAYS waits; nothing written before it by the skill or
  any arm: verdict line; the items numbered with branch + anchor; touched
  artifacts with the edge or read that reached each plus the untouched ones
  listed for overruling; numbered owner steps on
  `<owner> — <headless|GATED> — <invocation or arm path> — writes: <what>`
  plus the carried decision or `Will ask:` line plus the lint findings each
  clears or creates; the lint in scope; any still-open architect question in
  that arm's ambiguous form. Reply grammar: `go`; `all but <n>[, <m>]`;
  `<n> as runbook step` (the step deferred self-contained, carrying its
  invocation, anchor, change and every decision taken here, to a named
  runbook, the session's runbook, or a new one `/runbook-create` writes —
  `all as runbook steps` defers the plan); `<n> after <m>`; a letter for an
  open architect question or an overruled touched/untouched call or tier;
  `stop`. Anything but `go`/`stop` re-renders at the SAME gate with the edit
  applied; a dropped step drops its dependents, named; silence, unclear reply
  or EOF is `stop`. Actuation: sequential in the session, never parallel,
  never subagents; a headless step runs its arm by path with the decision
  carried in, a gated step runs its owner's command with that owner's gate
  intact; a step an earlier outcome made moot is dropped with a line, none
  added after the gate; deferred steps go to `/runbook-create --append` (or
  `/runbook-create <name>`) with `--no-commit` once the in-session steps have
  run — the skill writes no line of the runbook. Branch owner sequences:
  amend = `/product-design`'s amend arm → `/architect amend` per feature →
  tasks in two forms (task-engine `amend.md` per task when step 2 stales
  nothing; one `/task-add feature=<slug>` reconciliation when it stales or
  moves the feature `[ITERATED]`, unstaled tasks' own amends first, doc-less
  facts as its annotation) → `step-amend.md` per step; insert = `/architect
  amend` for new scope → `/task-add feature=<slug> --single --before/--after`
  (or the reconciliation form when step 1 leaves the feature `[ITERATED]`) →
  successors' `Preconditions:` via the task arm → `/runbook-create --append
  --before/--after`; delete = withdraw the promise → `[SKIP]` + dated reason →
  successors' edges dropped with the reason → steps struck, and for a feature
  every live task `[SKIP]` plus a `/production-plan` run, entry kept (lint
  then reports L11); reorder = skip-and-insert, new id at the new place, no
  renumber. **Closing follow-up gate** after actuation: what execution
  surfaced and the plan did not hold — a created task no open runbook running
  its feature has a step for, a successor no longer reading as a sequence, a
  lint finding created, a feature an owner named for reconciliation that no
  step ran — rendered in the same numbered shape with the same reply grammar,
  skipped when nothing arose, nothing written without the reply. Failure
  contract: an owner refusing (touched `[IN PROGRESS]`, `[DONE]`, a
  `[RUNNING]` position) or a gated owner's gate answered stop stops the
  sequence there, earlier writes kept and reported, NEVER rolled back, the
  after-lint still runs; a missing owner stops before the gate; absent
  `/runbook-create` makes `as runbook step` an error and re-renders. Write
  set empty — no line, no file, no report on disk; no status value, no change
  ledger. Owns the run's commit (COMMITTING, per `commit.md`): commits +
  pushes by default, `--no-commit` / `--no-push`, `--commit` a no-op; pull
  once at start after every item resolves; every owner step uncommitted
  (`/task-add`, `/product-design`, `/product-roadmap`, `/production-plan`,
  `/runbook-create` incl. `--append`, `/architect` always get `--no-commit`;
  by-path arms run with no commit; no owner pulls or pushes); after the
  closing gate, ONE commit of the union of reported writes — a runbook
  written for deferred steps included — subject = the `Revised <items> items
  — …` line. No commit on a stop before the gate, `stop` at either gate, a
  sequence stopped part-way (left uncommitted on purpose, every path listed),
  an empty write, or `--no-commit`.
- `skills/pipeline-suggest/` — the pipeline's auto-suggested entry point
  (feature `pipeline-suggest`), built in `runbook-suggest`'s shape. Fires
  on a free-form request to build, change, fix, remove or sequence work that
  names no slash command. Anti-triggers, deliberately longer than the
  triggers: a question, a request naming a command, "just do it" /
  "directly", work under way in a `/task-implement` run, an enumeration
  inside an explanation, a follow-up list (`runbook-suggest`'s), a project
  with neither index. Gate is TWO existence probes — `.claude/FEATURES.md`,
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

Each feature's contract is its bullet in § Overview. Frontmatter,
`description` contract and loading-control keys:
[features.md](./features.md) § Public API.

## Internal patterns

- None of their own: [features.md](./features.md) § Internal patterns.

## Domain dependencies

- `../domain/product-workflow.md` — pipeline stages, document set, feature
  and plan schemas.
- Frontmatter schema: [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds, frontmatter contract, the
  home-path guard.
- [task-suite.md](./task-suite.md) — `/task-add` and `/task-implement`, the
  stages after `/production-plan`.
- [runbook-suite.md](./runbook-suite.md) — the runbook suite `pipeline-engine`
  and `pipeline-revise` reach.

## When to read the source

- [features.md](./features.md) § When to read the source.
