# Features (commands, skills & claude-md)

The artifacts this repo *ships*. The CLI exists to install and update them.

## Overview

Feature kinds, all keyed by feature name (kebab-case):

- `commands/<name>.md` — a single markdown file with YAML frontmatter. The
  body is the prompt Claude Code runs when the user invokes `/<name>`.
- `skills/<name>/SKILL.md` — a folder containing `SKILL.md` plus any
  supporting files. The folder is copied recursively on install.
- `claude-md/<name>.md` — a managed section injected into
  `$CLAUDE_HOME/CLAUDE.md` (between `<!-- chosko-llm:<name>:begin … -->` /
  `:end` markers) rather than copied as a standalone file, so global CLAUDE.md
  guidance ships and updates like any other feature. `chosko-llm add/rm/update`
  treat it as the `claude-md:` kind; surrounding user content is preserved.

Currently shipped:
- `commands/project-setup.md` — interactive first-time project initialization
  wizard. Two phases: a GATHER phase that collects every choice upfront (VCS
  detection, CLAUDE.md seeding from pasted source, AGENTS.md, task backlog,
  domain layer, context layer), and an EXECUTE phase that applies them in a
  fixed order.
  **Authoring command — makes NO commits by default.** It writes its own
  artifacts (CLAUDE.md project-info section synthesized from user-pasted
  material only, a `## VCS` section mapping git→`cm` for non-git VCS like
  Plastic SCM, a `## Tasks implementation` section on Unity projects
  covering editor dirty-tree noise and the optional skip-tests
  testing-policy marker, and AGENTS.md), then runs the heavy sub-commands last —
  `/task-setup` (which leaves its scaffolding uncommitted by default), then
  `/domain-setup` (Step 5b — deliberately BEFORE the context layer, since
  `/context-build`'s DOMAIN DEPENDENCIES sections link to domain files; its
  GATHER step detects an existing `.claude/domain/` and offers to index the
  docs already there), then
  `/context-build` (the most context-hungry, gated command). On Unity
  projects it also offers `/unity-mcp-setup`, invoked LAST (after
  `/context-build`, so a freshly-built context layer exists for its
  `mcp-tools.md` doc) — the wizard only offers and delegates, holding no MCP
  logic of its own. By default everything, including the
  sub-commands' output, is left uncommitted for the user to review and commit
  in one pass — matching the other authoring commands (`/context-build`,
  `/context-update`, `/task-enrich`, `/refactor-*`). With `--commit` it
  commits its own artifacts first, then runs the sub-commands with `--commit`
  so each commits its own output. VCS detection decides whether to inject the
  VCS-mapping section (and, under `--commit`, which VCS the commits target).
- `commands/unity-mcp-setup.md` — make a Unity project ready for
  MCP-assisted `/task-implement`. Idempotent, re-runnable. Refuses on
  non-Unity projects (probes `ProjectSettings/ProjectVersion.txt`). Two
  sides: a VERSIONED project side — adds `com.coplaydev.unity-mcp` to
  `Packages/manifest.json` if missing, writes the CLAUDE.md marker
  `Unity MCP for /task-implement: com.coplaydev.unity-mcp (UnityMCP, http)`
  (the phrase `/task-implement` scans for), and, when the project has a
  context layer, creates `.claude/context/mcp-tools.md` + an `INDEX.md`
  row — and a MACHINE-LOCAL Claude side that registers/verifies the
  `UnityMCP` server via `claude mcp add` / `claude mcp list` (written to
  `~/.claude.json` local scope, never committed). **Authoring command —
  leaves its versioned artifacts uncommitted by default; `--commit` commits
  exactly those paths.** Handles the "running session's tool index doesn't
  refresh after `claude mcp add`" gotcha by telling the user to restart.
- `commands/context-build.md` — introduces a navigation context layer. Leaves
  it uncommitted by default; `--commit` commits the layer (INDEX, context
  files, CLAUDE.md edit) with explicit paths only.
- `commands/context-update.md` — refreshes an existing context layer, then
  auto-commits the context files it updated (explicit paths only; no commit
  when nothing changed). Joins the auto-committing group with `/task-add`
  and `/task-clean`. `--no-commit` leaves the updates uncommitted.
- `commands/domain-setup.md` — initialize the domain knowledge layer, the
  way `/task-setup` initializes the backlog: `.claude/domain/`,
  `.claude/domain/features/`, a `.claude/domain/INDEX.md` whose
  `| File | Covers |` table matches the context INDEX's shape, the
  `.claude/FEATURES.md` stub (a `.claude/` root sibling of `TASKS.md`,
  because it indexes work items — the feature *documents* live in the
  domain layer), and a CLAUDE.md pointer at the domain index that composes
  with `/context-build`'s context-layer pointer instead of replacing it.
  Idempotent, probe-per-artifact; on a project with hand-written domain
  docs it indexes them (heading + opening paragraph → the "Covers" cell)
  rather than writing an empty index. Creates the layer and nothing in it —
  design documents and feature entries belong to `/product-design` and
  `/architect`. **Authoring command — leaves its scaffolding uncommitted
  by default; `--commit` stages exactly the `WRITTEN` paths in one commit.**
- `commands/task-setup.md` — initialize the backlog: `.claude/TASKS.md`
  stub, `.claude/tasks/` directory, and `.claude/external/implement-prompt.md`
  (the static system prompt fed to an external LLM via aider). Required
  before `/task-add`. Idempotent — re-runs only fill in missing artifacts
  and never overwrite an edited implement-prompt. **Authoring command —
  leaves its scaffolding uncommitted for the user to review by default;
  `--commit` opts in to committing exactly the paths the run wrote.**
- `commands/task-add.md` — plan and append a new task conversationally:
  writes a summary block to `.claude/TASKS.md` and a thin body file at
  `.claude/tasks/<N>.md`. The default body schema (target: claude) contains
  Goal, Acceptance criteria, Decisions (when applicable), and Hints. With
  `--enrich`, produces an enriched body (target: local) in one shot by
  reading `/task-enrich` for format guidance. When the work includes steps
  only a human can perform in an external tool (e.g. the Unity editor),
  sets `Target: claude+human` (or `human`) and authors a
  `## Manual interventions` checkpoint section — the two always go
  together. Refuses if `/task-setup` has not run. May propose splitting
  the description into multiple tasks (independent deliverables, or one
  task that's too large); on acceptance writes every part with sequential
  IDs and auto-wired `Preconditions:` in one run. `--no-split` always
  writes exactly one task. Auto-commits the written files (all parts in
  one commit for a split); `--no-commit` leaves them uncommitted.
  With `feature=<slug>` it plans from an `/architect` feature document
  instead of a prose description (stage 3 of the pipeline): resolves the slug
  through `.claude/FEATURES.md`, reads the `Doc:` path as the primary context
  source, inverts the split check (a design unit is usually several
  implementation units), tags every new summary block `Feature: <slug>`, and
  sets the entry's `Tasks:` and `Status: [PLANNED]` — never `Doc:` or
  `Source:`. On a feature that already has tasks it RECONCILES under the same
  single approval gate: leave-untouched / update-body-in-place (preferred; a
  `[STALE]` task flips back to `[MISSING]`) / `[SKIP]`-and-replace, with
  `[DONE]` never touched. Free-form text alongside the slug narrows scope;
  the feature document is read-only. The free-form path is unchanged when
  `feature=` is absent.
  Documents the two product-pipeline additions to the backlog schema: the
  optional `Feature: <slug>` summary-block line (feature-derived tasks
  only; absent, not `none`, on free-form ones) and the `[STALE]` status
  (set by `/architect`, never by `/task-add`; resolved by
  `/task-add feature=<slug>` reconciliation).
- `commands/task-clean.md` — prune terminal-status tasks. Terminal means
  `[DONE]` and `[SKIP]` and nothing else — `[STALE]` is live work awaiting
  reconciliation and is never pruned by default (naming it explicitly
  warns and confirms). Removes summary
  blocks AND deletes the matching body files. Never renumbers — task IDs
  are stable across the project's lifetime; the `Last task number`
  counter never decreases. Also drops every pruned ID from any
  `.claude/FEATURES.md` `Tasks:` line (a line left empty becomes
  `Tasks: none`), silently skipped when the project has no feature index —
  the writer that invalidates those IDs fixes them in the same run, so
  `/architect`'s iterate guard stays a pure reader and never under-reports.
  Feature `Status:` is deliberately untouched: a feature whose tasks were all
  cleaned stays `[PLANNED]`, since `[PLANNED]` → `[NEW]` is illegal. After
  applying, commits the changes automatically (`.claude/TASKS.md` + deleted
  body files + `.claude/FEATURES.md` when it changed); `--no-commit`
  leaves them uncommitted.
- `skills/task-implement/` — implement backlog tasks end-to-end with
  TDD. The repo's only skill: `SKILL.md` carries the common path (clean
  tree, known test runner, numbered `target: claude` task) and five
  supporting files are read only when their branch fires —
  `dirty-tree.md` (non-empty `git status`), `test-runner.md` (runner must
  be inferred; mirrors task-setup's table), `no-test-suite.md`,
  `human-in-loop.md`, `unity-mcp-checkpoints.md` (Unity-MCP-driven
  checkpoints — read only when the current human-in-loop task's project
  declares the `Unity MCP for /task-implement:` marker AND the
  `mcp__UnityMCP__*` tools are connected this session), and `body-schemas.md`
  (non-current body schema).
  Reads each task's body file from `.claude/tasks/<N>.md` only when
  needed and treats it as the primary context source — only fans out to
  CLAUDE.md and the context layer when the body doesn't cover what's
  needed. Status flips happen in `.claude/TASKS.md`. Human-in-the-loop
  tasks: on
  `target: claude+human` it pauses at each `## Manual interventions`
  checkpoint, walks the user through the manual step, and independently
  verifies the outcome before continuing; on `target: human` the task runs
  as a guided walkthrough (no production edits by Claude, bookkeeping
  still Claude's). When the project declares a Unity MCP plugin
  (`Unity MCP for /task-implement:` marker in CLAUDE.md) and the
  `mcp__UnityMCP__*` tools are connected this session, `human-in-loop.md`'s
  gate reads `unity-mcp-checkpoints.md` instead: Claude checks the Unity
  Console after compilation, performs editor actions itself, and rewrites
  each checkpoint into a verification step — opt-outable per run, and a
  no-op (standard manual protocol) when MCP isn't connected. Honors a `Testing policy for /task-implement:
  skip-tests|full-tdd` marker in a project's CLAUDE.md (checked before
  heuristic test-suite detection) so a no-test-suite decision persists
  across runs instead of being re-asked each time. On a `[STALE]` task it
  warns naming the originating feature and offers implement-anyway or stop
  (`all` / `next` skip stale tasks and report them, rather than deciding
  for the user) — the interactive counterpart to `chosko-llm task-impl`
  refusing a stale task outright. Commits each task
  separately; `--no-commit` runs the full TDD sequence but skips the
  per-task commits, leaving every task's changes uncommitted.
- `skills/product-design/` — design a product top-down with the user and
  write the result into the domain layer: `design-process.md` (the state
  file), `product-design.md`, `technical-direction.md`, and — only when the
  user opts in — `business-model.md`. Eight phases: PHASE 0 gates on
  `/domain-setup` having run and auto-detects a resume, PHASE 1 orients
  (greenfield vs. brownfield, read from CLAUDE.md/README/the context
  layer/the source tree) and stubs the documents plus their
  `.claude/domain/INDEX.md` rows (`technical-direction.md` stubbed
  unconditionally, since PHASE 6 always runs), PHASE 2 interviews, PHASE 3
  writes back, PHASE 4 identifies the high-level feature set from the
  user-experience angle, PHASE 5 records it, PHASE 6 is a conversational
  round establishing the product's technical foundations (stack, topology,
  data, async, hosting, protocols, cross-cutting concerns) — always runs,
  reads back which PHASE 4/5 features drive which choices, and branches on
  greenfield/brownfield (confirm-and-record vs. propose-with-recommendation)
  — PHASE 7 writes it into `technical-direction.md`, the standing constraint
  `/architect` designs within. Four supporting files load only when their
  branch fires: `document-templates.md` (per-section stubs, read in PHASE 1,
  3, 5, and 7), `business-model.md` (the strategy question bank — opt-in
  only), `technical-direction.md` (the technical question bank, read at the
  start of PHASE 6 and again before PHASE 7 writes), and `resuming.md` (read
  only when `design-process.md` already exists — also handles a marker
  written before PHASE 6/7 existed, offering to continue rather than
  reporting the process complete). The stage marker in `design-process.md`
  is rewritten before every phase ends, so an interrupted session resumes
  from a truthful stage — there is no `resume` argument, since the document
  is the state. `product-design.md` and `business-model.md` stay high-level
  by construction: implementation detail is `/architect`'s output;
  `technical-direction.md` is the one document where stack and
  infrastructure detail belongs. It never writes `.claude/FEATURES.md`,
  feature docs, or tasks. **Authoring skill — nothing committed by default;
  `--commit` stages exactly the documents written in one commit.**
- `skills/architect/` — stage 2 of the product pipeline: turn one or more
  high-level features into low-level feature documents under
  `.claude/domain/features/`, each indexed by a `.claude/FEATURES.md` entry.
  Input is a `product-design.md` section, named features, or a bare
  free-form prompt (so it is usable on a codebase that never ran
  `/product-design`); with no argument it lists the design's features and
  asks. PHASE 0 gates on `/domain-setup`, reads the design/technical-
  direction/feature/context layers, and detects whether a stack exists — a
  present `technical-direction.md` counts as a stack that exists, exactly
  like an established codebase, so PHASE 2a is skipped and
  `tech-stack-selection.md` is never read on that path; PHASE 0b is the
  iterate guard; PHASE 1 clarifies (skipped when nothing is ambiguous,
  writing answers back into `product-design.md`); PHASE 2 architects
  conversationally, top-down — when `technical-direction.md` exists it
  designs within it and names the document in one line, and a genuine
  mismatch is flagged once and designed around rather than silently
  overridden (the remedy is re-running `/product-design`, never editing
  the document) — stopping at mid-to-high technical level, no code, no
  file-by-file plans, those being `/task-add`'s output; PHASE 3 writes the
  documents, the `FEATURES.md` entries, the INDEX rows, and any upstream
  design change. Three supporting files load only on their branch:
  `iterating.md` (the feature already has an entry), `tech-stack-
  selection.md` (no existing stack in either form — an existing stack
  always wins), `feature-doc-template.md` (PHASE 3, always; its
  Architecture section opens with a stack reference — "Built on <stack> per
  the product design", naming `technical-direction.md` when that's the
  source — rather than restating the choice). Writes `Status:` / `Doc:` /
  `Source:` in `FEATURES.md` and never `Tasks:` — the by-line split that
  lets it share the file with `/task-add`. The only writer of `[STALE]`:
  the iterate guard refuses outright while any generated task is
  `[IN PROGRESS]` (no override), else asks, then flips surviving
  non-`[DONE]` tasks to `[STALE]` and the feature `[PLANNED]` →
  `[ITERATED]`. That guard is also the only reason it touches
  `.claude/TASKS.md`, and it writes nothing there but `Status:` lines. Slugs
  are stable and never renamed. Never writes `technical-direction.md` — that
  is `/product-design`'s document. **Authoring skill — nothing committed by
  default; `--commit` stages exactly the written paths (including TASKS.md
  when the guard fired) in one commit.**
- `skills/unity-mcp-skill/` — a Unity-MCP operator guide vendored from
  the upstream skill. `SKILL.md` carries the resource-first workflow,
  core tool categories, and best-practice patterns for driving the Unity
  editor over MCP; two supporting files under `references/` hold the
  detailed material —  `tools-reference.md` (per-tool parameters and
  examples) and `workflows.md` (extended scene/script/UI/camera/test
  workflows). Frontmatter was reconciled to repo rules on vendoring:
  `name: unity-mcp-skill` (the upstream `name` was
  `unity-mcp-orchestrator`), plus the required `version` and `type: skill`;
  body and description are otherwise verbatim. Complements the Unity story
  already in the repo (`commands/unity-mcp-setup.md` and the
  `skills/task-implement/unity-mcp-checkpoints.md` checkpoint flow) by
  giving Claude a reusable reference when operating the editor via
  `mcp__UnityMCP__*` tools.
- `commands/task-list.md` — print the backlog as a compact read-only
  summary. Marks `claude+human` / `human` tasks with `⚠ <target>`, shows
  `[<slug>]` for tasks with a `Feature:` line, and appends `⚠ stale` to
  `[STALE]` tasks. Reads only `.claude/TASKS.md`; never opens the body
  files.
- `commands/task-enrich.md` — expand a thin (`target: claude`) task body
  into an enriched self-contained body (`target: local`) for a local LLM
  implementer. Appends `## Context bundle` and `## Implementation steps`
  sections; updates `Target:` to `local`. Refuses human-in-the-loop tasks
  (`target: claude+human` / `human`). Does not commit by default;
  `--commit` opts in to committing the enriched body.
- `commands/refactor-codebase.md` — behaviour-preserving, plan-first,
  test-gated refactor: extract constants/enums, dedupe, split oversized
  files, clean imports, rename. `scope=` / `focus=` limit the work; `--commit`
  commits the result (default leaves it uncommitted).
- `commands/refactor-tests.md` — split oversized test files into focused ones,
  running the suite before/after each split to keep it green. `threshold=`
  sets the line cutoff; `--commit` commits the splits (default uncommitted).
- `claude-md/tool-usage-policy.md` — a claude-md artifact: global tool-usage
  guidance injected into `$CLAUDE_HOME/CLAUDE.md`. Installed/updated/removed
  via the `claude-md:` kind, not as a copied file.

## Public API (per-feature contract)

Every feature file requires a complete frontmatter block:
```yaml
---
name: <kebab-case>          # MUST match filename / folder name
version: <semver>           # required; install refuses without it
type: command | skill
description: <one line>
---
```

See `../../docs/authoring-guide.md` for the canonical spec, including the
semver bump rules, the commit-control convention, the three places the task
status vocabulary must agree, and the rule that a multi-session skill keeps
its state in a versioned project document.

## Internal patterns

- **Filename = folder name = `name` field.** A mismatch breaks `update --all`
  because `cmd-ls`/`cmd-update` iterate filesystem entries while resolution
  by user input goes via `name`. The authoring guide flags this as a common
  mistake.
- **Skills are folders, not single files.** A bare `skills/foo.md` is
  ignored by every script. See `feature_kind` in
  [shared-lib.md](./shared-lib.md).
- **No state file.** Versions live in frontmatter; what's installed is
  whatever exists under `$CLAUDE_HOME`. See `../../CLAUDE.md` hard rules.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter schema, naming rules,
  semver bump table. Canonical.
- `../../CLAUDE.md` — hard rules: every feature has frontmatter; filesystem
  is the source of truth; copy-not-symlink; `cmd-add` / `cmd-update` reject
  files missing `version`.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `parse_frontmatter`,
  `require_versioned_source`, and the path helpers that locate features.
- [cmd-add.md](./cmd-add.md), [cmd-update.md](./cmd-update.md),
  [cmd-rm.md](./cmd-rm.md), [cmd-ls.md](./cmd-ls.md) — the verbs that
  operate on these artifacts.

## When to read the source

- Authoring or modifying a specific feature → the relevant
  `commands/<name>.md` or `skills/<name>/SKILL.md`. The body content is
  outside the scope of this navigation layer; it's prompt material for
  Claude Code, not project source.
- Adding/removing a frontmatter field → `../../docs/authoring-guide.md` plus
  `parse_frontmatter` in `scripts/lib.sh` (see
  [shared-lib.md](./shared-lib.md)).
