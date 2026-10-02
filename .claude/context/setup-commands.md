# Features: setup commands and Unity MCP

## Overview

Covers the project-initialization commands and the Unity MCP pair. Feature
kinds: [features.md](./features.md); the frontmatter contract every one of
them follows: [feature-contract.md](./feature-contract.md).

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
  `/context-build` (most context-hungry, gated step, and the wizard always
  invokes it in its default FLAT layout — never `nested`). On Unity
  projects also offers `/unity-mcp-setup`, invoked LAST (after
  `/context-build`, so freshly-built context layer exists for its
  `mcp-tools.md` doc) — wizard only offers and delegates, holds no MCP
  logic itself. By default everything, including
  sub-commands' output, left uncommitted for user review and commit
  in one pass — `../../docs/authoring-guide.md` § Commit-and-push
  convention. With `--commit` it
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

## Public API

- None beyond [feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- None beyond [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- None beyond [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds and the rest of the shipped
  inventory; [feature-contract.md](./feature-contract.md) — the frontmatter
  contract these features follow.

## When to read the source

- None beyond [features.md](./features.md) § When to read the source.
