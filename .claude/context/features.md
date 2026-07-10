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
  context layer), and an EXECUTE phase that applies them in a fixed order.
  **Authoring command — makes NO commits by default.** It writes its own
  artifacts (CLAUDE.md project-info section synthesized from user-pasted
  material only, a `## VCS` section mapping git→`cm` for non-git VCS like
  Plastic SCM, a `## Tasks implementation` section on Unity projects
  covering editor dirty-tree noise and the optional skip-tests
  testing-policy marker, and AGENTS.md), then runs the heavy sub-commands last —
  `/task-setup` (which leaves its scaffolding uncommitted by default) then
  `/context-build` (the most context-hungry, gated command, run last so it
  can't strand the earlier steps). By default everything, including the
  sub-commands' output, is left uncommitted for the user to review and commit
  in one pass — matching the other authoring commands (`/context-build`,
  `/context-update`, `/task-enrich`, `/refactor-*`). With `--commit` it
  commits its own artifacts first, then runs the sub-commands with `--commit`
  so each commits its own output. VCS detection decides whether to inject the
  VCS-mapping section (and, under `--commit`, which VCS the commits target).
- `commands/context-build.md` — introduces a navigation context layer. Leaves
  it uncommitted by default; `--commit` commits the layer (INDEX, context
  files, CLAUDE.md edit) with explicit paths only.
- `commands/context-update.md` — refreshes an existing context layer, then
  auto-commits the context files it updated (explicit paths only; no commit
  when nothing changed). Joins the auto-committing group with `/task-add`
  and `/task-clean`. `--no-commit` leaves the updates uncommitted.
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
- `commands/task-clean.md` — prune terminal-status tasks. Removes summary
  blocks AND deletes the matching body files. Never renumbers — task IDs
  are stable across the project's lifetime; the `Last task number`
  counter never decreases. After applying, commits the changes
  automatically (`.claude/TASKS.md` + deleted body files); `--no-commit`
  leaves them uncommitted.
- `skills/task-implement/` — implement backlog tasks end-to-end with
  TDD. The repo's only skill: `SKILL.md` carries the common path (clean
  tree, known test runner, numbered `target: claude` task) and five
  supporting files are read only when their branch fires —
  `dirty-tree.md` (non-empty `git status`), `test-runner.md` (runner must
  be inferred; mirrors task-setup's table), `no-test-suite.md`,
  `human-in-loop.md`, and `body-schemas.md` (non-current body schema).
  Reads each task's body file from `.claude/tasks/<N>.md` only when
  needed and treats it as the primary context source — only fans out to
  CLAUDE.md and the context layer when the body doesn't cover what's
  needed. Status flips happen in `.claude/TASKS.md`. Human-in-the-loop
  tasks: on
  `target: claude+human` it pauses at each `## Manual interventions`
  checkpoint, walks the user through the manual step, and independently
  verifies the outcome before continuing; on `target: human` the task runs
  as a guided walkthrough (no production edits by Claude, bookkeeping
  still Claude's). Honors a `Testing policy for /task-implement:
  skip-tests|full-tdd` marker in a project's CLAUDE.md (checked before
  heuristic test-suite detection) so a no-test-suite decision persists
  across runs instead of being re-asked each time. Commits each task
  separately; `--no-commit` runs the full TDD sequence but skips the
  per-task commits, leaving every task's changes uncommitted.
- `commands/task-list.md` — print the backlog as a compact read-only
  summary. Marks `claude+human` / `human` tasks with `⚠ <target>`. Reads
  only `.claude/TASKS.md`; never opens the body files.
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
semver bump rules.

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
