# Features (commands, skills, claude-md & statusline)

Artifacts this repo *ships*. CLI installs and updates them.

## Overview

Feature kinds, keyed by feature name (kebab-case):

- `commands/<name>.md` — single markdown file, YAML frontmatter. Body = prompt Claude Code runs when user invoke `/<name>`.
- `skills/<name>/SKILL.md` — folder containing `SKILL.md` plus supporting files. Folder copied recursively on install.
- `claude-md/<name>.md` — managed section injected into
  `$CLAUDE_HOME/CLAUDE.md` (between `<!-- chosko-llm:<name>:begin … -->` /
  `:end` markers) rather than copied as standalone file — global CLAUDE.md
  guidance ships and updates like any other feature. `chosko-llm add/rm/update`
  treat as `claude-md:` kind; surrounding user content preserved.
- `statusline/<name>.sh` — directly executable status-bar shell script,
  installed verbatim to `$CLAUDE_HOME/statusline/<name>.sh`. Frontmatter
  lives in bash no-op heredoc (`: <<'CHOSKO_FRONTMATTER' ... CHOSKO_FRONTMATTER`)
  right after shebang, so `parse_frontmatter`'s first-`---`-pair scan still
  find it. Since `settings.json`'s `"statusLine"` key not this repo's
  shape to own, `chosko-llm add` skip editing it — prints copy-pasteable
  prompt for Claude Code session to merge key in safely. `chosko-llm
  add/rm/update/ls/show` treat as `statusline:` kind.

Currently shipped:
- `commands/project-setup.md` — interactive first-time project init
  wizard. Two phases: GATHER phase collects every choice upfront (VCS
  detection, CLAUDE.md seeding from pasted source, AGENTS.md, task backlog,
  domain layer, context layer), EXECUTE phase applies them in
  fixed order.
  **Authoring command — makes NO commits by default.** Writes own
  artifacts (CLAUDE.md project-info section synthesized from user-pasted
  material only, `## VCS` section mapping git→`cm` for non-git VCS like
  Plastic SCM, `## Tasks implementation` section on Unity projects
  covering editor dirty-tree noise and optional skip-tests
  testing-policy marker, and AGENTS.md), then runs heavy sub-commands last —
  `/task-setup` (leaves scaffolding uncommitted by default), then
  `/domain-setup` (Step 5b — deliberately BEFORE context layer, since
  `/context-build`'s DOMAIN DEPENDENCIES sections link to domain files; its
  GATHER step detects existing `.claude/domain/` and offers indexing docs
  already there), then
  `/context-build` (a skill since v0.46.0; most context-hungry, gated
  step, and the wizard always invokes it in its default FLAT layout —
  never `nested`). On Unity
  projects also offers `/unity-mcp-setup`, invoked LAST (after
  `/context-build`, so freshly-built context layer exists for its
  `mcp-tools.md` doc) — wizard only offers and delegates, holds no MCP
  logic itself. By default everything, including
  sub-commands' output, left uncommitted for user review and commit
  in one pass — matching other authoring features (`/context-build`,
  `/context-convert`, `/task-enrich`, `/refactor-*`). With `--commit` it
  commits own artifacts first, then runs sub-commands with `--commit`
  so each commits own output. VCS detection decides whether to inject
  VCS-mapping section (and, under `--commit`, which VCS commits target).
- `commands/unity-mcp-setup.md` — makes Unity project ready for
  MCP-assisted `/task-implement`. Idempotent, re-runnable. Refuses on
  non-Unity projects (probes `ProjectSettings/ProjectVersion.txt`). Two
  sides: VERSIONED project side — adds `com.coplaydev.unity-mcp` to
  `Packages/manifest.json` if missing, writes CLAUDE.md marker
  `Unity MCP for /task-implement: com.coplaydev.unity-mcp (UnityMCP, http)`
  (phrase `/task-implement` scans for), and, when project has
  context layer, creates `.claude/context/mcp-tools.md` + `INDEX.md`
  row — and MACHINE-LOCAL Claude side that registers/verifies
  `UnityMCP` server via `claude mcp add` / `claude mcp list` (written to
  `~/.claude.json` local scope, never committed). **Authoring command —
  leaves versioned artifacts uncommitted by default; `--commit` commits
  exactly those paths.** Handles "running session's tool index doesn't
  refresh after `claude mcp add`" gotcha by telling user to restart.
- `skills/context-build/` — introduces navigation context layer. Three
  phases: analysis (no writes, stops for approval), author, wire CLAUDE.md
  entry-point. Flat by default, stamping `Layout: flat` into the INDEX it
  authors; `nested` / `nested=<unit1>,<unit2>` builds router + per-unit
  leaves instead. One supporting file, `nested.md`, read ON DEMAND — only
  when the run is nested — so flat runs (the common path) never pay its
  tokens. Refuses to convert an existing layer, pointing at
  `/context-convert`. Leaves output uncommitted by default; `--commit`
  commits layer (INDEX, context files, CLAUDE.md edit) with explicit paths
  only. Carries `replaces: command:context-build`.
- `skills/context-update/` — refreshes existing context layer. Four modes
  (smart / `full` / `files=`+`git=` targeted / `-y`), backfills
  `Layout: flat` into any INDEX lacking the marker, then auto-commits
  context files it updated (explicit paths only; no commit when nothing
  changed). Joins auto-committing group with `/task-add` and
  `/task-clean`. `--no-commit` leaves updates uncommitted. One supporting
  file, `nested.md`, read ON DEMAND when the layer's marker says
  `Layout: nested` — covers per-leaf `Last updated` (each leaf its own
  date authority, router has none), one-leaf-per-file ownership, and
  `unit=<name>` scoping/disambiguation.
- `skills/context-convert/` — restructures an existing layer between the
  two layouts in place, either direction; `/context-build` refuses that
  operation and points here. Direction inferred from the `Layout:` marker,
  forceable with `to=nested` / `to=flat`; `nested=` pre-seeds unit names
  only, never file placement. Plan-first: Phase 1 reports every path move,
  date decision and link rewrite, then stops (`-y` skips the gate).
  Content is MOVED, never rewritten — the only in-file edit is a relative
  link whose depth changed. Dates fail safe both ways (flat→nested: every
  leaf inherits the flat date verbatim; nested→flat: the MINIMUM leaf
  date, never max, never today). No `nested.md` split — every run of this
  skill concerns the nested layout, so there is no cheap flat path to
  keep. Authoring-command commit family: `--commit` to commit and push.
  No `replaces:` — it is new, not a migration.
- `commands/domain-setup.md` — initializes domain knowledge layer, same
  way `/task-setup` initializes backlog: `.claude/domain/`,
  `.claude/domain/features/`, `.claude/domain/INDEX.md` whose
  `| File | Covers |` table matches context INDEX's shape,
  `.claude/FEATURES.md` stub (a `.claude/` root sibling of `TASKS.md`,
  since it indexes work items — feature *documents* live in
  domain layer), and CLAUDE.md pointer at domain index that composes
  with `/context-build`'s context-layer pointer instead of replacing it.
  Idempotent, probe-per-artifact; on project with hand-written domain
  docs indexes them (heading + opening paragraph → "Covers" cell)
  rather than writing empty index. Creates layer and nothing in it —
  design documents and feature entries belong to `/product-design` and
  `/architect`. **Authoring command — leaves scaffolding uncommitted
  by default; `--commit` stages exactly `WRITTEN` paths in one commit.**
- `commands/task-setup.md` — initializes backlog: `.claude/TASKS.md`
  stub, `.claude/tasks/` directory, `.claude/external/implement-prompt.md`
  (static system prompt fed to external LLM via aider). Required
  before `/task-add`. Idempotent — re-runs only fill missing artifacts,
  never overwrite edited implement-prompt. **Authoring command —
  leaves scaffolding uncommitted for user review by default;
  `--commit` opts in to committing exactly paths run wrote.**
- `commands/task-add.md` — plans and appends new task conversationally:
  writes summary block to `.claude/TASKS.md` and thin body file at
  `.claude/tasks/<N>.md`. Default body schema (target: claude) contains
  Goal, Acceptance criteria, Decisions (when applicable), Hints. With
  `--enrich`, produces enriched body (target: local) in one shot by
  reading `/task-enrich` for format guidance. When work includes steps
  only human can perform in external tool (e.g. Unity editor),
  sets `Target: claude+human` (or `human`) and authors
  `## Manual interventions` checkpoint section — two always go
  together. Refuses if `/task-setup` not run. May propose splitting
  description into multiple tasks (independent deliverables, or one
  task too large); on acceptance writes every part with sequential
  IDs and auto-wired `Preconditions:` in one run. `--no-split` always
  writes exactly one task. Auto-commits written files (all parts in
  one commit for split); `--no-commit` leaves uncommitted.
  With `feature=<slug>` plans from `/architect` feature document
  instead of prose description (stage 3 of pipeline): resolves slug
  through `.claude/FEATURES.md`, reads `Doc:` path as primary context
  source, inverts split check (design unit usually several
  implementation units), tags every new summary block `Feature: <slug>`,
  sets entry's `Tasks:` and `Status: [PLANNED]` — never `Doc:` or
  `Source:`. On feature already with tasks RECONCILES under same
  single approval gate: leave-untouched / update-body-in-place (preferred; a
  `[STALE]` task flips back to `[MISSING]`) / `[SKIP]`-and-replace, with
  `[DONE]` never touched. When run drafts at least one new task, it
  appends one final documentation-update task (`Target: claude`,
  `Preconditions:` listing run's other new task IDs) whose Hints point at
  affected README.md / authoring-guide.md / domain / context-layer docs;
  skipped on reconciliation-only run. `/architect`-owned and
  `/product-design`-owned documents MAY appear in that task's Hints, but
  never silently — file and owner named at PHASE 3 gate, user can strike
  it. Free-form text alongside slug narrows scope;
  feature document read-only to `/task-add` itself. Free-form path unchanged when
  `feature=` absent.
  Documents two product-pipeline additions to backlog schema: optional
  `Feature: <slug>` summary-block line (feature-derived tasks
  only; absent, not `none`, on free-form ones) and `[STALE]` status
  (set by `/architect`, never by `/task-add`; resolved by
  `/task-add feature=<slug>` reconciliation).
- `commands/task-clean.md` — prunes terminal-status tasks. Terminal means
  `[DONE]` and `[SKIP]` and nothing else — `[STALE]` is live work awaiting
  reconciliation and never pruned by default (naming it explicitly
  warns and confirms). Removes summary
  blocks AND deletes matching body files. Never renumbers — task IDs
  stable across project's lifetime; `Last task number`
  counter never decreases. Also drops every pruned ID from any
  `.claude/FEATURES.md` `Tasks:` line (line left empty becomes
  `Tasks: none`), silently skipped when project has no feature index —
  writer invalidating those IDs fixes them in same run, so
  `/architect`'s iterate guard stays pure reader, never under-reports.
  Feature `Status:` deliberately untouched: feature whose tasks were all
  cleaned stays `[PLANNED]`, since `[PLANNED]` → `[NEW]` illegal. After
  applying, commits changes automatically (`.claude/TASKS.md` + deleted
  body files + `.claude/FEATURES.md` when changed); `--no-commit`
  leaves uncommitted.
- `skills/task-implement/` — implements backlog tasks end-to-end with
  tests-first sequence. `SKILL.md` carries common path (clean
  tree, known test runner, numbered `target: claude` task); six
  supporting files read only when their branch fires —
  `dirty-tree.md` (non-empty `git status`), `test-runner.md` (runner must
  be inferred; mirrors task-setup's table), `no-test-suite.md`,
  `human-in-loop.md`, `unity-mcp-checkpoints.md` (Unity-MCP-driven
  checkpoints — read only when current human-in-loop task's project
  declares `Unity MCP for /task-implement:` marker AND
  `mcp__UnityMCP__*` tools connected this session), `body-schemas.md`
  (non-current body schema), and `delegated-runs.md` (2+-task run user delegated to subagents).
  Reads each task's body file from `.claude/tasks/<N>.md` only when
  needed, treats it as primary context source — only fans out to
  CLAUDE.md and context layer when body doesn't cover what's
  needed. Status flips happen in `.claude/TASKS.md`. Human-in-the-loop
  tasks: on
  `target: claude+human` pauses at each `## Manual interventions`
  checkpoint, walks user through manual step, independently
  verifies outcome before continuing; on `target: human` task runs
  as guided walkthrough (no production edits by Claude, bookkeeping
  still Claude's). When project declares Unity MCP plugin
  (`Unity MCP for /task-implement:` marker in CLAUDE.md) and
  `mcp__UnityMCP__*` tools connected this session, `human-in-loop.md`'s
  gate reads `unity-mcp-checkpoints.md` instead: Claude checks Unity
  Console after compilation, performs editor actions itself, rewrites
  each checkpoint into verification step — opt-outable per run, no-op
  (standard manual protocol) when MCP not connected. Honors `Testing policy for /task-implement:
  skip-tests|full-tdd|skip-tests-unattended` marker in project's
  CLAUDE.md (checked before heuristic test-suite detection) so
  no-test-suite decision persists across runs instead of re-asked
  each time. In skip-tests mode, per-task "Proceed?" confirmation can
  be suppressed with `-y` flag for single run, or permanently via
  `skip-tests-unattended` marker value. On `[STALE]` task
  warns naming originating feature and offers implement-anyway or stop
  (`all` / `next` skip stale tasks, report them, rather than deciding
  for user) — interactive counterpart to `chosko-llm task-impl`
  refusing stale task outright. On run resolving to 2+ tasks, offers
  to implement each task in fresh subagent so later tasks don't inherit
  earlier ones' context; agents spawned one at a time, never
  parallel (shared working tree, branch, `TASKS.md`), each owning own
  task's status flips, commit, push, while `claude+human` / `human` /
  explicitly requested `[STALE]` tasks stay in parent conversation
  since need user present. `--agents` / `--no-agents`
  pre-answer prompt; single-task runs never see it. Commits each task
  separately; `--no-commit` runs full sequence but skips
  per-task commits, leaving every task's changes uncommitted.
- `skills/product-design/` — designs product top-down with user, writes
  result into domain layer: `design-process.md` (state
  file), `product-design.md`, `technical-direction.md`, and — only when
  user opts in — `business-model.md`. Eight phases: PHASE 0 gates on
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
  `/architect` designs within. Four supporting files load only when their
  branch fires: `document-templates.md` (per-section stubs, read in PHASE 1,
  3, 5, 7), `business-model.md` (strategy question bank — opt-in
  only), `technical-direction.md` (technical question bank, read at
  start of PHASE 6 and again before PHASE 7 writes), `resuming.md` (read
  only when `design-process.md` already exists — also handles marker
  written before PHASE 6/7 existed, offering to continue rather than
  reporting the process complete). The stage marker in `design-process.md`
  is rewritten before every phase ends, so an interrupted session resumes
  from a truthful stage — there is no `resume` argument, since the document
  is the state. A fifth supporting file, `council-gate.md`, loads only when
  PHASE 6 reaches a genuine technical fork on the GREENFIELD branch: it
  delegates the decision to the separately-installed claude-council skill
  (detected at `${CLAUDE_HOME:-$HOME/.claude}/skills/claude-council/SKILL.md`,
  silent and no-op when absent), invoked with no mode argument so
  claude-council's own Quick/Standard/Deep triage applies. The brownfield
  branch is excluded — confirm-and-record over an existing stack is not a
  fork. Dissent folds into `product-design.md`'s design decisions; the
  council's own report/transcript are owned by neither skill and never enter
  `WRITTEN` or `--commit`; the `design-process.md` stage marker is not
  written when convening, since a mid-phase consultation is not a phase
  transition. Kept in step with the `/architect` copy — see
  `../../docs/authoring-guide.md`. `product-design.md` and `business-model.md` stay high-level
  by construction: implementation detail is `/architect`'s output;
  `technical-direction.md` is one document where stack and
  infrastructure detail belongs. Never writes `.claude/FEATURES.md`,
  feature docs, or tasks. **Authoring skill — nothing committed by default;
  `--commit` stages exactly documents written in one commit.**
- `skills/product-roadmap/` — product-level WHEN of the pipeline, between
  `/product-design` and `/architect`. Writes one document,
  `.claude/domain/product-roadmap.md`, plus its `.claude/domain/INDEX.md`
  row, and nothing else — never `FEATURES.md`, `PLAN.md`, `TASKS.md`, or
  `product-design.md`. Ordered milestone blocks keyed by stable kebab-case
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
  estimates — that's a later feature's, same intent/state split keeping
  feature statuses out of `product-design.md`. PHASE 0 gates on
  `/domain-setup` (only refusal in skill), reads domain INDEX,
  `product-design.md` when present (optional — usable from bare
  description), any existing roadmap as its own resume state (no marker
  file, document is state), and `.claude/FEATURES.md` READ-ONLY. PHASE 1 is
  conversation and run's single approval gate; PHASE 2 is only write phase.
  Both failure modes are warnings, not refusals: `Covers:` entry naming
  section absent from `product-design.md`, and editing slice whose section
  already has features (names slugs, points at `/architect <slug>`, proceeds
  on user's say-so — `[ITERATED]` stays `/architect`'s field). No supporting
  files — schema inline, one file per folder. **Authoring skill — nothing
  committed by default; `--commit` stages exactly written paths in one
  commit, `--no-push` skips the push; `--commit` with nothing written makes
  no commit and says so.**
- `skills/architect/` — stage 2 of product pipeline: turns one or more
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
  path anyway, stated in one line — so adoption is incremental and a project
  with no roadmap behaves exactly as before. `--no-slices` forces traditional
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
  design change. Six supporting files load only on their branch:
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
  `iterating.md` (the feature already has an entry), `tech-stack-
  selection.md` (no existing stack in either form — an existing stack
  always wins), `council-gate.md` (PHASE 2 hit a genuine design fork —
  optional delegation to the separately-installed claude-council skill at
  the stack choice, the architecture shape, and the low-level split;
  detected under `CLAUDE_HOME`, silent and no-op when absent, invoked with
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
  and `prompt` features, backward compatible, and the sole mechanism by which
  a low-level feature knows its milestone. Reads `product-roadmap.md`, never
  writes it, and never reads `PLAN.md`. The only writer of `[STALE]`:
  the iterate guard refuses outright while any generated task is
  `[IN PROGRESS]` (no override), else asks, then flips surviving
  non-`[DONE]` tasks to `[STALE]` and feature `[PLANNED]` →
  `[ITERATED]`. That guard also only reason it touches
  `.claude/TASKS.md`, writes nothing there but `Status:` lines. Slugs
  stable, never renamed. Never writes `technical-direction.md` — that
  is `/product-design`'s document. **Authoring skill — nothing committed by
  default; `--commit` stages exactly written paths (including TASKS.md
  when guard fired) in one commit.**
- `skills/production-plan/` — feature-level WHEN of the pipeline, between
  `/architect` and `/task-add`. Sole writer of `.claude/PLAN.md`, a third
  index beside `TASKS.md` and `FEATURES.md`, and writes NOTHING else — never
  `FEATURES.md`, `TASKS.md`, feature docs, `product-roadmap.md`,
  `product-design.md`, or the domain `INDEX.md`. Schema: `Roadmap:` (or
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
  `[SHIPPED]` proposed only when every feature is `[PLANNED]` and every task
  `[DONE]`/`[SKIP]`, always confirmed, never reopened. Explicit placement
  overrides the parenthetical, is reported plainly, never gated or refused.
  PHASE 2 validates BEFORE the gate and before any write, and both invariants
  REFUSE with no override flag: a cycle is reported as the actual cycle path,
  and a dependency in a later milestone is reported with both features and
  both milestones (a dependency on an `Unscheduled` feature is a warning
  instead — `Unscheduled` has no position, so it cannot be "later"); each
  milestone's `Features:` must be a topological order of the edges restricted
  to it. PHASE 2 ends at the run's single approval gate; PHASE 3 is the only
  write phase. One supporting file, `reconciling.md`, read on demand when
  PHASE 0 finds an existing `PLAN.md` — the five-situation re-run table
  (feature absent from the plan proposed for placement; plan slug gone from
  `FEATURES.md` reported and dropped along with its edges; `[ITERATED]`
  feature's dependencies re-read as a DIFF, never a wholesale replacement;
  roadmap milestone added in roadmap order; plan milestone gone from the
  roadmap reported, kept and flagged) — all folded into that same one gate,
  mirroring `/task-add`'s convention. Other failures are reports, not
  refusals: an edge slug resolving to no feature is dropped, a milestone with
  no features is a warning, `>1 [ACTIVE]` reports and asks. Nothing
  plan-aware exists in `/task-add`, `/task-implement`, or the bash CLI —
  deferred by the feature's open questions. **Authoring skill — nothing
  committed by default; `--commit` stages exactly `.claude/PLAN.md` in one
  commit, `--no-push` skips the push; `--commit` with nothing written makes
  no commit and says so.**
- `skills/unity-mcp-skill/` — Unity-MCP operator guide vendored from
  upstream skill. `SKILL.md` carries resource-first workflow,
  core tool categories, best-practice patterns for driving Unity
  editor over MCP; two supporting files under `references/` hold
  detailed material — `tools-reference.md` (per-tool parameters and
  examples) and `workflows.md` (extended scene/script/UI/camera/test
  workflows). Frontmatter reconciled to repo rules on vendoring:
  `name: unity-mcp-skill` (upstream `name` was
  `unity-mcp-orchestrator`), plus required `version` and `type: skill`;
  body and description otherwise verbatim. Complements Unity story
  already in repo (`commands/unity-mcp-setup.md` and
  `skills/task-implement/unity-mcp-checkpoints.md` checkpoint flow) by
  giving Claude reusable reference when operating editor via
  `mcp__UnityMCP__*` tools.
- `commands/production-status.md` — read side of the planning layer. Thin
  read-only reporter (a command, not a skill: no conversation, no supporting
  files) joining `.claude/PLAN.md`, `.claude/FEATURES.md`, `.claude/TASKS.md`
  and `.claude/domain/product-roadmap.md`, all read-only. Eight output
  sections in fixed order: the milestone (slug, title, `Status:`, plus `Goal:`
  and `Exit criteria:` echoed verbatim from the roadmap); its features in plan
  order with `FEATURES.md` status, task rollup and readiness; the ready set;
  the ONE recommended next feature (first ready in plan order); blocked
  features each named with what blocks it and why; coverage gaps (milestones
  with `Features: none`, plus `product-design.md` sections no `Covers:` names);
  unplanned features (`FEATURES.md` slugs missing from the plan, plus
  `Unscheduled`); remaining milestones one line each. READINESS is the only
  computation and is derived every read, never stored: ready when every edge
  pointing at the feature comes from a feature `[PLANNED]` in `FEATURES.md`
  with all tasks `[DONE]`/`[SKIP]`; no edges → ready; else blocked. An edge
  slug resolving to no feature FAILS OPEN — reported as a plan inconsistency,
  feature treated as ready. Task rollup is counts per status by default,
  `--task-ids` names each ID; `milestone=<slug>` scopes sections 1–5 and an
  unknown slug stops listing available slugs (matching `/task-add
  feature=<slug>`). Staleness is STRUCTURAL, never temporal — names slugs
  missing from `PLAN.md`, never compares `Last reconciled:` against dates or
  mtimes. Failure contract is degradation throughout (no roadmap omits
  goal/exit criteria, no `TASKS.md` drops rollups, no `[ACTIVE]` reports the
  first `[PLANNED]`); the only stops are a missing `PLAN.md` and an unknown
  `milestone=`. Writes nothing, runs NO shell command of any kind, never opens
  a file under `.claude/tasks/`, and never starts the work it recommends.
- `commands/task-list.md` — prints backlog as compact read-only
  summary. Marks `claude+human` / `human` tasks with `⚠ <target>`, shows
  `[<slug>]` for tasks with `Feature:` line, appends `⚠ stale` to
  `[STALE]` tasks. When `.claude/PLAN.md` exists, also groups tasks under
  milestone headings in plan order, resolving each task's `Feature:` slug
  through the milestones' `Features:` lists, and appends `⚠ blocked by <slug>`
  when the task's feature is blocked — same readiness rule as
  `/production-status`, duplicated rather than shared (one paragraph of logic
  in a markdown prompt), with an unresolvable edge slug ignored rather than
  treated as a blocker. Tasks with no `Feature:` line and slugs no milestone
  lists (including `Unscheduled` ones) fall under one trailing `Unplanned`
  heading; empty milestones get no heading. Marker order stated explicitly in
  the body: `⚠ <target>`, `[<slug>]`, `(deps: N, M)`, `⚠ stale`,
  `⚠ blocked by <slug>`. Filter applies before grouping, so it works within
  groups; summary line unchanged. NO `PLAN.md` → byte-for-byte the old output,
  a silent no-op with no warning and no pointer at `/production-plan`. Reads
  `.claude/TASKS.md`, plus `PLAN.md` and `FEATURES.md` when a plan exists;
  never opens body files, feature docs or the roadmap.
- `commands/task-enrich.md` — expands thin (`target: claude`) task body
  into enriched self-contained body (`target: local`) for local LLM
  implementer. Appends `## Context bundle` and `## Implementation steps`
  sections; updates `Target:` to `local`. Refuses human-in-the-loop tasks
  (`target: claude+human` / `human`). Doesn't commit by default;
  `--commit` opts in to committing enriched body.
- `commands/refactor-codebase.md` — behaviour-preserving, plan-first,
  test-gated refactor: extract constants/enums, dedupe, split oversized
  files, clean imports, rename. `scope=` / `focus=` limit work; `--commit`
  commits result (default leaves uncommitted).
- `commands/refactor-tests.md` — splits oversized test files into focused ones,
  runs suite before/after each split to keep it green. `threshold=`
  sets line cutoff; `--commit` commits splits (default uncommitted).
- `claude-md/tool-usage-policy.md` — claude-md artifact: global tool-usage
  guidance injected into `$CLAUDE_HOME/CLAUDE.md`. Installed/updated/removed
  via `claude-md:` kind, not as copied file.
- `statusline/session-statusline.sh` — statusline artifact: model · cwd ·
  git branch · context% · cost · 5h/7d rate limits. Installed/updated/removed
  via `statusline:` kind; `chosko-llm add` prints settings.json
  wiring prompt after copying script.

## Public API (per-feature contract)

Every feature file requires complete frontmatter block:
```yaml
---
name: <kebab-case>          # MUST match filename / folder name
version: <semver>           # required; install refuses without it
type: command | skill
description: <one line>
replaces: command:<name>     # OPTIONAL, only on a kind change; see below
---
```

`replaces:` is the optional fifth key from the kind-migration path: set it when
a feature changes kind (`commands/<n>.md` rewritten as `skills/<n>/SKILL.md`),
so `add`/`update`/`update --all` remove the superseded artifact from
`$CLAUDE_HOME` instead of leaving two definitions of one slash command. Live
examples: `skills/context-build/SKILL.md` and `skills/context-update/SKILL.md`.
Drop the key once the migration has propagated.

See `../../docs/authoring-guide.md` for canonical spec, including
semver bump rules, commit-control convention, three places task
status vocabulary must agree, and rule that multi-session skill keeps
its state in versioned project document.

## Internal patterns

- **Filename = folder name = `name` field.** Mismatch breaks `update --all`
  since `cmd-ls`/`cmd-update` iterate filesystem entries while resolution
  by user input goes via `name`. Authoring guide flags this as common
  mistake.
- **Skills are folders, not single files.** Bare `skills/foo.md` is
  ignored by every script. See `feature_kind` in
  [shared-lib.md](./shared-lib.md).
- **Supporting files are read on demand.** A skill folder's non-`SKILL.md`
  files exist so the common path stays cheap: `SKILL.md` names the branch
  and the file to read when it fires, and nothing else reads them.
  `skills/task-implement/` (seven), `skills/product-design/` (four),
  `skills/architect/` (three), `skills/context-build/nested.md` and
  `skills/context-update/nested.md` (one each) all follow this. Whole
  folder is copied on install regardless — the saving is tokens per run,
  not bytes on disk.
- **No state file.** Versions live in frontmatter; what's installed is
  whatever exists under `$CLAUDE_HOME`. See `../../CLAUDE.md` hard rules.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter schema, naming rules,
  semver bump table. Canonical.
- `../../CLAUDE.md` — hard rules: every feature has frontmatter; filesystem
  is source of truth; copy-not-symlink; `cmd-add` / `cmd-update` reject
  files missing `version`.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `parse_frontmatter`,
  `require_versioned_source`, path helpers that locate features.
- [cmd-add.md](./cmd-add.md), [cmd-update.md](./cmd-update.md),
  [cmd-rm.md](./cmd-rm.md), [cmd-ls.md](./cmd-ls.md) — verbs that
  operate on these artifacts.

## When to read the source

- Authoring or modifying specific feature → relevant
  `commands/<name>.md` or `skills/<name>/SKILL.md`. Body content
  outside scope of this navigation layer; it's prompt material for
  Claude Code, not project source.
- Adding/removing frontmatter field → `../../docs/authoring-guide.md` plus
  `parse_frontmatter` in `scripts/lib.sh` (see
  [shared-lib.md](./shared-lib.md)).