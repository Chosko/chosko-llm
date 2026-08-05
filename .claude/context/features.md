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
  `/product-design`-owned documents never added to that task's Hints
  without asking first. Free-form text alongside slug narrows scope;
  feature document read-only. Free-form path unchanged when
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
  reporting process complete). Stage marker in `design-process.md`
  rewritten before every phase ends, so interrupted session resumes
  from truthful stage — no `resume` argument, since document
  is state. `product-design.md` and `business-model.md` stay high-level
  by construction: implementation detail is `/architect`'s output;
  `technical-direction.md` is one document where stack and
  infrastructure detail belongs. Never writes `.claude/FEATURES.md`,
  feature docs, or tasks. **Authoring skill — nothing committed by default;
  `--commit` stages exactly documents written in one commit.**
- `skills/architect/` — stage 2 of product pipeline: turns one or more
  high-level features into low-level feature documents under
  `.claude/domain/features/`, each indexed by `.claude/FEATURES.md` entry.
  Input is `product-design.md` section, named features, or bare
  free-form prompt (usable on codebase that never ran
  `/product-design`); with no argument lists design's features and
  asks. PHASE 0 gates on `/domain-setup`, reads design/technical-
  direction/feature/context layers, detects whether stack exists — a
  present `technical-direction.md` counts as stack that exists, exactly
  like established codebase, so PHASE 2a skipped and
  `tech-stack-selection.md` never read on that path; PHASE 0b is iterate guard; PHASE 1 clarifies (skipped when nothing ambiguous,
  writing answers back into `product-design.md`); PHASE 2 architects
  conversationally, top-down — when `technical-direction.md` exists,
  designs within it and names document in one line, genuine
  mismatch flagged once and designed around rather than silently
  overridden (remedy: re-running `/product-design`, never editing
  document) — stopping at mid-to-high technical level, no code, no
  file-by-file plans, those being `/task-add`'s output; PHASE 3 writes
  documents, `FEATURES.md` entries, INDEX rows, any upstream
  design change. Three supporting files load only on their branch:
  `iterating.md` (feature already has entry), `tech-stack-
  selection.md` (no existing stack in either form — existing stack
  always wins), `feature-doc-template.md` (PHASE 3, always; its
  Architecture section opens with stack reference — "Built on <stack> per
  the product design", naming `technical-direction.md` when that's
  source — rather than restating choice). Writes `Status:` / `Doc:` /
  `Source:` in `FEATURES.md`, never `Tasks:` — by-line split that
  lets it share file with `/task-add`. Only writer of `[STALE]`:
  iterate guard refuses outright while any generated task is
  `[IN PROGRESS]` (no override), else asks, then flips surviving
  non-`[DONE]` tasks to `[STALE]` and feature `[PLANNED]` →
  `[ITERATED]`. That guard also only reason it touches
  `.claude/TASKS.md`, writes nothing there but `Status:` lines. Slugs
  stable, never renamed. Never writes `technical-direction.md` — that
  is `/product-design`'s document. **Authoring skill — nothing committed by
  default; `--commit` stages exactly written paths (including TASKS.md
  when guard fired) in one commit.**
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
- `commands/task-list.md` — prints backlog as compact read-only
  summary. Marks `claude+human` / `human` tasks with `⚠ <target>`, shows
  `[<slug>]` for tasks with `Feature:` line, appends `⚠ stale` to
  `[STALE]` tasks. Reads only `.claude/TASKS.md`; never opens body
  files.
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