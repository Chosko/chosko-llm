# Features (commands, skills, claude-md, statusline & hooks)

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
- `hooks/<name>.sh` — executable script Claude Code runs on hook event.
  Frontmatter in same bash no-op heredoc as statusline, plus two hook-only
  keys: `event:` (required — `PreToolUse`, `SessionStart`, …; install refuses
  without it) and `matcher:` (optional, narrows event to one tool). Installed
  to `$CLAUDE_HOME/hooks/<name>.sh`; `add` prints settings.json wiring prompt
  same way statusline does, naming `$CLAUDE_PROJECT_DIR/...` not absolute path
  since settings.json is committed and travels. **Local-only kind** — exact
  mirror of statusline's global-only rule; see `scope_supports_kind` in
  [shared-lib.md](./shared-lib.md). Both halves (script + settings.json) must
  be committed, and Claude Code snapshots hook config at session start, so
  new wiring needs fresh session.

**Not a kind — `.claude/skills/`.** `skills/<name>/` is shipped: versioned,
walked by `cmd-ls --available`, installed by `cmd-add`. This repo's OWN
`.claude/skills/<name>/SKILL.md` is repo-local development tooling — no
`version:` frontmatter, invisible to every CLI verb (`ls`, `show`, `add`,
`update`, `rm`), installed nowhere, invocable only while working in this repo.
Two exist (`context-budget`, `rule-overlap`). Deliberately absent from
"Currently shipped" below, which lists artifacts the CLI installs; the whole
point of the location is that these are not. See
`../domain/features/repo-local-audits.md` and
`../../docs/authoring-guide.md` § "Repo-local skills are not features".

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
  `/context-convert`, `/refactor-*`). With `--commit` it
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
  stub, `.claude/tasks/` directory, and the project's **test-dispatch
  convention** — `.claude/external/run-affected-tests.sh` +
  `run-full-tests.sh`, thin wrappers inferred from project files giving
  one stable pair of entry points for the affected and full suites.
  Nothing in the `task-*` suite invokes them; `/task-implement`
  resolves its own test command and never reads them. No-test-suite
  projects get no-op stubs carrying the `# CHOSKO_TASK_IMPL_STUB`
  sentinel, which is what marks a wrapper as a stub on a re-run.
  Required before `/task-add`. Idempotent — re-runs only fill missing
  artifacts, never overwrite a non-stub wrapper. **Authoring command —
  leaves scaffolding uncommitted for user review by default;
  `--commit` opts in to committing exactly paths run wrote.**
- `skills/task-engine/` — reference library the `task-*` suite reads;
  **not user-invocable**, takes no arguments, runs nothing, produces no
  output. Exists because a rule stated in four bodies is four things to
  update and three chances to forget. `SKILL.md` is a MAP, not a rule
  holder — it says which reference file owns what and repeats the
  not-invocable statement for an agent that opened the file without
  reading frontmatter; the `description` says the same thing in the words
  skill selection matches on, which is what keeps it out of suggestions.
  Seven files under `references/`, one authority each:
  `resolution.md` (`.claude/TASKS.md` schema and parsing, the `all` /
  `next` / explicit-list selectors, body-file location, the
  `/task-setup`-has-run gate), `status.md` (the eight-value status
  vocabulary, which statuses are terminal, which implementable, legal
  transitions), `targets.md` (`Target:` values, the `## Manual
  interventions` pairing rule, the delegation guard, per-consumer notes),
  `stale.md` (`[STALE]` detection, who writes and clears it, the
  implement-anyway/stop protocol, reconciliation classification),
  `tree.md` (the dirty-tree prompt protocol, four options, `DIRTY_FOLD` /
  `DIRTY_FOLD_UNTRACKED` and the Step-7 fold), `commit.md` (pull-at-start,
  per-task commit and push, `--no-commit` / `--no-push` gating), and
  `review-budget.md` (review cost controls: the `--review-model` /
  `--review-effort` values, their `same` / `auto` reserved words, the
  deterministic three-row `auto` tier table keyed on lines/files/criteria
  and whether the diff touches a non-`.md` file, the read budget behind the
  effort axis — navigation layer full and uncounted at every tier, only
  distinct source/test files beyond the diff counted, `shallow` at zero —
  the no-test-command-at-any-tier clause, and the cap-bound and
  resolved-pair reports). A
  consumer cites the file by
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<f>.md`
  and states only its own deviations. Installed like any other skill
  (`cp -R` of the folder), which is exactly why the engine had to be a
  skill and not a command — see
  `../domain/features/shared-phase-engine.md`. Its five consumers declare
  `requires: skill:task-engine` (`task-review` joined when it took the read
  budget on), so `add` pulls it in and `rm` refuses to
  take it away while any of them is installed.
- `commands/task-add.md` — plans and appends new task conversationally:
  writes summary block to `.claude/TASKS.md` and thin body file at
  `.claude/tasks/<N>.md`. Default body schema (target: claude) contains
  Goal, Acceptance criteria, Decisions (when applicable), Hints.
  When work includes steps
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
  instead of prose description (stage 5 of pipeline): resolves slug
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
  skipped on reconciliation-only run. Owned documents MAY appear in any
  drafted task's Hints or `Files:` — doc task, free-form, split part,
  reconciled body alike — but never silently and never un-adjudicated:
  detection off command's own four-row owner list
  (`domain/features/*.md` → `/architect`; `product-design.md` /
  `technical-direction.md` / `business-model.md` → `/product-design`;
  `product-roadmap.md` → `/product-roadmap`; `PLAN.md` →
  `/production-plan`; `FEATURES.md` / `TASKS.md` excluded), specific
  reconciliations enumerated per file, one question per file inside PHASE
  3's single gate, answered as grant (dated point-scoped bullet written
  into body's Decisions, points into Acceptance criteria) or drop (path
  removed from Hints and `Files:`, remainder noted in Decisions). Silence
  is not a grant; PHASE 4 refuses a task left un-adjudicated. Grant
  authorises that task's implementer — `/task-add` still never edits an
  owned document. Free-form text alongside slug narrows scope;
  feature document read-only to `/task-add` itself. Free-form path unchanged when
  `feature=` absent.
  Documents two product-pipeline additions to backlog schema: optional
  `Feature: <slug>` summary-block line (feature-derived tasks
  only; absent, not `none`, on free-form ones) and `[STALE]` status
  (set by `/architect`, never by `/task-add`; resolved by
  `/task-add feature=<slug>` reconciliation).
  Declares `requires: skill:task-engine` and is the largest consumer of it:
  PHASE 0's setup check and the index-file format reference
  `references/resolution.md`, the status-tag block `status.md`, target values
  and manual interventions `targets.md`, the `[STALE]` and
  reconciliation-classification rules `stale.md`, and PHASE 5 `commit.md`.
  What survives inline is what is unique to authoring.
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
  cleaned stays `[PLANNED]`, since `[PLANNED]` → `[NEW]` illegal — and that
  surviving `Status:` is what `/architect`'s iterate guard keys its own flip
  on, precisely because the pruned `Tasks:` line can no longer tell a cleaned
  feature from a never-planned one. After
  applying, commits changes automatically (`.claude/TASKS.md` + deleted
  body files + `.claude/FEATURES.md` when changed); `--no-commit`
  leaves uncommitted. Declares `requires: skill:task-engine` — first
  *writing* consumer of it: backlog parsing references
  `references/resolution.md`, the prune-set vocabulary `status.md`, the
  `[STALE]` warning `stale.md`, and the commit/push gating `commit.md`.
- `skills/task-implement/` — implements backlog tasks end-to-end with
  tests-first sequence. `SKILL.md` carries common path (clean
  tree, known test runner, numbered `target: claude` task); last of the four
  to move onto `task-engine`, and declares `requires: skill:task-engine` —
  backlog resolution and selectors reference
  `references/resolution.md`, implementable/terminal statuses `status.md`,
  `Target:` handling and the delegation guard `targets.md`, the STALE
  protocol `stale.md`, the dirty-tree check `tree.md`, and PRE-FLIGHT step 5
  plus Step 7 `commit.md`. Its own `dirty-tree.md` supporting file was
  DELETED in that migration (`tree.md` was extracted from it and now holds
  the protocol once), leaving seven
  supporting files read only when their branch fires —
  `test-runner.md` (runner must
  be inferred; mirrors task-setup's table), `no-test-suite.md`,
  `human-in-loop.md`, `unity-mcp-checkpoints.md` (Unity-MCP-driven
  checkpoints — read only when current human-in-loop task's project
  declares `Unity MCP for /task-implement:` marker AND
  `mcp__UnityMCP__*` tools connected this session), `body-schemas.md`
  (non-current body schema), `delegated-runs.md` (2+-task run user delegated to subagents),
  and `review-rounds.md` (`--review` passed; read once after argument
  parsing, before the first task, never otherwise).
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
  for user). On run resolving to 2+ tasks, offers
  to implement each task in fresh subagent so later tasks don't inherit
  earlier ones' context; agents spawned one at a time, never
  parallel (shared working tree, branch, `TASKS.md`), each owning own
  task's status flips, commit, push, while `claude+human` / `human` /
  explicitly requested `[STALE]` tasks stay in parent conversation
  since need user present. `--agents` / `--no-agents`
  pre-answer prompt; single-task runs never see it. On such run parent
  is **launcher**, not orchestrator: evaluates delegation guard
  (`Target:`, `Status:`, `Feature:`) from `TASKS.md` summary blocks
  PRE-FLIGHT step 2 already read, so never opens `.claude/tasks/<N>.md`
  for delegated task on any path; hands every agent same fixed-size
  prompt — task number + repo's absolute path + run's resolved flags
  (open list, not closed set: NO_COMMIT/NO_PUSH/AUTO_CONFIRM, resolved
  testing mode w/ concrete test command, DIRTY_FOLD /
  DIRTY_FOLD_UNTRACKED, non-interactivity notice) + instruction to read
  body, CLAUDE.md, context layer itself; keeps exactly four values per
  return (task number, terminal status, commit hash or nothing-committed,
  one-line failure reason only on failure). Prompt O(1) in batch size and
  in task size, so parent's context no longer grows with batch. Tasks
  parent keeps still get body read in Step 1, unchanged. Commits each task
  separately; `--no-commit` runs full sequence but skips
  per-task commits, leaving every task's changes uncommitted. When a
  `Feature:`-tagged task lands `[DONE]` and leaves every task for that
  feature `[DONE]`/`[SKIP]`, records it as a completion candidate; once, at
  the very end of the run (batched across the whole run, never per-task),
  proposes flipping each candidate's `FEATURES.md` `Status:` from
  `[PLANNED]` to `[DONE]` — user decides per feature, one commit covers
  every flip approved.
  `--review` (with optional `--rounds N`, default 1) runs a review/iterate
  loop per task. Availability gate first: both `task-review` and
  `task-iterate` must be present in the session or the run stops BEFORE any
  `[IN PROGRESS]` flip — never silently skipped, since "implemented" and
  "implemented and reviewed" are different claims. `--rounds` without
  `--review` errors (`--rounds requires --review.`); a non-positive integer
  errors (`--rounds needs a positive integer.`).
  Two cost-control flags steer the spawned reviewer, both defaulting to
  `auto` and both erroring without `--review` in the same shape `--rounds`
  uses: `--review-model <name>|same|auto` (`--review-model requires
  --review.`) and `--review-effort shallow|standard|deep|same|auto`
  (`--review-effort requires --review.`, plus a value check naming the five
  legal levels). Model names pass VERBATIM to the Agent tool — no local
  allow-list, since a hardcoded roster would refuse a model that works.
  The pair resolves **per task, at the top of each round**, never once per
  run, from that round's own diff plus the criteria count already in hand,
  which is what keeps a batch O(1); the two values feed exactly two places —
  the model decides whether the Agent call carries `model:` (omitted on
  `same`, so the child inherits), the effort decides whether the spawn
  prompt carries a budget block (omitted on `same`, so the reviewer reads
  unbounded). Neither the tier table nor the budget table is restated in the
  skill: `task-engine`'s `references/review-budget.md` is their single
  authority and `review-rounds.md` reads it. Loop sits after Step 5 and
  **before Step 6**, on the uncommitted tree — before, not between 6 and 7,
  so a halt on unresolved findings leaves the task `[IN PROGRESS]` rather
  than `[DONE]`-and-halted. Each round spawns `/task-review` as a
  **subagent** (`subagent_type: general-purpose`) — fresh context is the
  mechanism, not an optimizable detail — with an eight-item prompt (repo path,
  `task=<n>`, this round's diff scope, round number, prior rejection ledger
  from round 2 on, and the statement that it was spawned by
  `/task-implement --review` so it writes nothing to disk, the test-suite
  state — green under the resolved policy, or skip-tests and nothing ran,
  handed in because the reviewer runs no test command itself — and the
  budget block, omitted entirely when the effort resolved to `same`). That spawn
  returns **asynchronously**: the call yields an agent id and the findings
  arrive later as a separate notification, so the round waits for them and
  Steps 6/7 are unreachable until the final round's result has actually
  arrived — treating the call's return value as the findings would commit
  unreviewed work while reporting it reviewed. `/task-iterate` then runs in
  **this** session (its edits must land in the tree Step 7 commits), told
  explicitly it is inside a round and must not commit. Loop continues only
  while `BLOCKING` findings remain unresolved and only up to `ROUNDS`; later
  rounds re-review only the hunks the last iterate changed; rejections are
  sticky across rounds. Unresolved `BLOCKING` after the last round stops the
  whole run per FAILURE HANDLING (tree uncommitted, task `[IN PROGRESS]`, no
  next task). Exactly one commit per task either way — the fixes ride in the
  task's own commit, never a second one. In a delegated run REVIEW/ROUNDS
  plus REVIEW_MODEL/REVIEW_EFFORT
  ride through the fixed-size hand-off prompt as two more strings and each
  implementor spawns
  its own reviewer, measuring its own diff (launcher → implementor →
  reviewer; the launcher measures nothing); the four-field
  return contract is unchanged and no finding travels up to the parent.
- `skills/task-review/` — audits a diff against the acceptance criteria of
  the task that produced it and reports structured findings. Exists beside
  Claude Code's built-in `/code-review` because of that one difference:
  generic review asks *is this good code*, this asks *does this satisfy task
  N's criteria*; where the two overlap it defers to the built-in rather than
  reimplementing it. Declares `requires: skill:task-engine` — the fifth
  consumer, and the only one that reads the engine for a single file:
  `references/review-budget.md`, and only when the invocation carried a
  budget block. Three input forms resolved from the argument after
  stripping `task=<n>` and `base=<ref>`: empty → local (`git diff HEAD`), a
  branch name → branch (`git diff <base>...<branch>`, three dots), a bare
  integer or GitHub PR URL → pr (`gh pr diff <N>`). One supporting file,
  `remote-diffs.md`, read ON DEMAND — only when that remaining input is
  non-empty; a local run never opens it. Task resolved first-hit-wins from
  `task=<n>`, a number in the branch name, the PR title, then the most
  recently modified `.claude/tasks/*.md` (weakest signal, so the report says
  which and why); **no resolution stops the run** rather than degrading into
  a generic code review. Three gates before any finding is written:
  ≥80% confidence, the four-question Pre-Report Gate (exact line; concrete
  failure mode; callers/imports/tests read; severity defensible — any "no"
  or "unsure" demotes or drops), and BLOCKING-requires-proof (snippet,
  scenario, why existing guards miss it; missing one ⇒ demote).
  A spawn from `/task-implement --review` may carry a **budget block**
  naming a read tier (`shallow` / `standard` / `deep`), honoured off
  `review-budget.md`: navigation layer (CLAUDE.md chain, context INDEX +
  the diff's rows, task body, feature doc) read in full and NEVER counted at
  any tier; only distinct source/test files beyond the diff count, and
  re-opening a counted file is free; a cap that actually BINDS is reported
  in one line, because a silent cap cannot be retuned. **No budget block
  means no budget** — a manual run and a spawn whose effort resolved to
  `same` both read unbounded, and a tier is never assumed unnamed. The
  budget caps reads, never admissibility: **no fourth gate is added**, and
  `shallow`'s ban on reading callers simply answers Pre-Report Gate question
  3 with "no", which the existing gate already demotes or drops — cheaper
  review, more conservative, never more confident-and-wrong. The skill has
  no cost-control flags of its own; the axes live on `/task-implement`.
  Separate contract clause, NOT a budget setting: **it invokes no test
  command** — any mode, any budget, any testing policy, either invocation
  path; a green suite is an input the caller hands it (spawn-prompt item 7),
  and under a skip-tests caller a criterion depending on runtime behaviour
  is `unverifiable` rather than re-derived. Reading test *files* as source
  is a different thing, governed by the budget table.
  **Zero findings is a valid, complete review** — stated explicitly, because
  a reviewer under implicit pressure to justify itself invents findings.
  Exactly three severities — `BLOCKING` (bugs, data loss, security, or an
  unmet acceptance criterion), `IMPORTANT`, `ADVISORY` (reported once, never
  re-reviewed); an unmet criterion is ALWAYS blocking. Findings carry stable
  `R<round>-<n>` ids, never renumbered, since that is how a rejection stays
  rejected across rounds; the report also carries a per-criterion verdict
  (`met` / `not met` / `unverifiable`) and one overall line, and the two
  halves must agree. Output destination branches on invocation: spawned by
  `/task-implement --review` → structured return, nothing on disk; invoked
  manually → asks once whether to also write
  `.claude/reviews/<task>-R<round>.md`, chat-only being the default on
  silence or EOF. No `--rounds` flag — the loop belongs to
  `/task-implement`. Read-only contract: no edit to any source/test/task/
  status/feature file, no `git add`/`commit`/`checkout`/`stash`/`push`, no
  `gh` write, no PR opened, and no subagents of its own (one reviewer, one
  pass — a dimension-reviewer fan-out is the token cost this repo exists to
  avoid).
- `skills/task-iterate/` — triages findings it did NOT produce, applies what
  survives, records why the rest did not. Same three input forms and same
  `task=` / `base=` parsing as `/task-review`, plus `--no-commit` /
  `--no-push`; fixes always land in the working tree in front of it (branch
  mode assumes that branch is checked out and stops rather than switching).
  **No supporting files** — everything including PR mode is in `SKILL.md`,
  and it never reads a file from another skill's folder, since each skill
  installs as a self-contained folder. Findings come from exactly ONE of
  three sources, in order: passed in by the caller (the `--review` path),
  a `.claude/reviews/<task>-R<n>.md` file (highest round; ambiguity asks),
  or PR review comments via `gh` (one thread = one finding; already-resolved
  threads are prior context, not findings). **Never invents a finding**, not
  as a bonus or an "also noticed" — a skill that both finds and fixes grades
  its own work. Triage is mandatory and explicit: every finding gets exactly
  one of `fix`, `defer` (needs a follow-up task number or a one-line note of
  what the task would be) or `reject` (needs an arguable one-line reason),
  and **the whole verdict table is written out before the first edit** —
  triage decided while editing is triage rationalised by the edit. A
  BLOCKING finding naming an unmet acceptance criterion cannot be deferred;
  a finding arguing against the task body's Decisions is a `reject` with the
  decision as the reason. A `fix` discovered to be wrong once in the file
  flips to `reject` with what was found, reported as a changed verdict. In
  PR mode it replies on each thread and resolves the `fix`ed and `defer`red
  ones while **leaving rejected threads open** for the human. Committing is
  **caller-dependent and the caller asserts the mode, never inferred**:
  standalone it follows the repo's pull/commit/re-sync/push protocol; inside
  a `/task-implement --review` round it commits and pushes nothing, leaving
  the tree for that run's Step 7 so the task keeps exactly one commit. That
  asymmetry is load-bearing and flagged as such in the body against a future
  editor "fixing" it. Returns three things: the triage summary, the sticky
  rejection ledger for the next round, and an explicit yes/no on unresolved
  `BLOCKING` findings — the field `/task-implement`'s loop reads to decide
  whether another round is warranted. Never opens a pull request, in any
  mode.
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
  `/architect` designs within, then compresses `design-process.md`
  (delete-not-append: "Current stage" back to 1–2 sentences + per-document
  one-liners + next step, "Decisions worth keeping" back to flat undated
  terse bullets w/ superseded entries deleted outright — no dated revision
  headers, no `[SUPERSEDED]` retention, no closing-record essay) immediately
  before writing the process-complete marker, and says so in its report.
  Four supporting files load only when their
  branch fires: `document-templates.md` (per-section stubs, read in PHASE 1,
  3, 5, 7), `business-model.md` (strategy question bank — opt-in
  only), `technical-direction.md` (technical question bank, read at
  start of PHASE 6 and again before PHASE 7 writes), `resuming.md` (read
  only when `design-process.md` already exists — also handles marker
  written before PHASE 6/7 existed, offering to continue rather than
  reporting the process complete; and, once the marker says the process
  *is* complete, offers a third arm first — **amend a decision**: edits the
  relevant document directly, re-runs no phase, leaves the marker on
  complete, and applies the same compression before the session ends, so an
  amendment leaves the file no larger than it found it). The stage marker in `design-process.md`
  is rewritten before every phase ends, so an interrupted session resumes
  from a truthful stage — there is no `resume` argument, since the document
  is the state. A fifth supporting file, `council-gate.md`, loads only when
  PHASE 6 reaches a genuine technical fork on the GREENFIELD branch: it
  delegates the decision to the claude-council skill this repo ships
  (vendored under `skills/claude-council/`, opt-in — installed only when the
  user runs `chosko-llm add skill:claude-council`)
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
  `product-design.md`. Preamble carries `Strategy:` paragraph — premise whole
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
  estimates — that's a later feature's, same intent/state split keeping
  feature statuses out of `product-design.md`. Dates/status bar binds
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
  transcription; `propose` = original draft-first behaviour, unchanged.
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
  a newly-decided order). No supporting
  files — schema inline, one file per folder. **Authoring skill — nothing
  committed by default; `--commit` stages exactly written paths in one
  commit, `--no-push` skips the push; `--commit` with nothing written makes
  no commit and says so.**
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
  optional delegation to the claude-council skill this repo ships (opt-in,
  installed only on `chosko-llm add skill:claude-council`) at
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
  non-`[DONE]` tasks to `[STALE]` and feature status to `[ITERATED]` (from
  `[PLANNED]` or `[DONE]`). Guard's two halves decided by different fields:
  task half (list, refuse, ask, `[STALE]` flip) runs only when `Tasks:` IDs
  actually resolve — `Tasks: none` and IDs resolving to nothing are the same
  case, neither an error, and skip it with no ask and no `TASKS.md` write;
  status half always keyed on entry's own `Status:` (`[NEW]` and `[ITERATED]`
  self-transition, `[PLANNED]`/`[DONE]` → `[ITERATED]`, named in closing
  report), because `/task-clean` prunes resolved IDs while leaving `Status:`
  alone, leaving `Tasks: none` unable to tell a cleaned feature from a
  never-planned one. That guard also only reason it touches
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
- `skills/claude-council/` — **vendored**, second of the two (see
  `skills/unity-mcp-skill/` above). Copy of upstream
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
  `~/.claude` literal replaced by `${CLAUDE_HOME:-$HOME/.claude}`. Ships
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
  `[PLANNED]` with all tasks `[DONE]`/`[SKIP]`; no edges → ready; else
  blocked. An edge
  slug resolving to no feature FAILS OPEN — reported as a plan inconsistency,
  feature treated as ready. Section 2's last column is NOT readiness but
  **Next**, derived from status + rollup + readiness and exactly one of
  `-` (`[DONE]`), `/task-add feature=<slug>` (`[NEW]`/`[ITERATED]`), `flip to
  [DONE] in FEATURES.md` (`[PLANNED]`, nothing left but `[DONE]`/`[SKIP]`
  tasks, zero-task case included), `/task-implement <N>` (`[PLANNED]`, work
  left, not blocked, lowest such N) or `blocked by <slug>` — blockedness
  suppresses ONLY `/task-implement`, since planning and a bookkeeping flip are
  never blocked by a dependency. Task rollup is counts per status by default,
  `--task-ids` names each ID; zero tasks renders `-` on a `[DONE]`/`[PLANNED]`
  feature (those states are post-`/task-add`, so zero means `/task-clean`
  pruned) and `no tasks yet` only on `[NEW]`/`[ITERATED]`, in both rollup
  modes; `milestone=<slug>` scopes sections 1–5 and an
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
  never opens body files, feature docs or the roadmap. First consumer of
  `task-engine` and declares `requires: skill:task-engine`: backlog
  resolution references `references/resolution.md` and the status vocabulary
  `status.md`, leaving only the rendering rules inline.
- `commands/session-save.md` — writes per-project handoff file so an in-flight
  conversation's state survive end of that conversation. Command not skill:
  single pass, no phases, no supporting files — same register `/task-list` and
  `/production-status` occupy. One file per save at
  `.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md`; directory created by write, no
  separate `mkdir`. `<slug>` is two-or-three-word kebab-case summary of the
  work (directory listing is the only way an old session ever found), or the
  single argument verbatim. NEVER updates file in place — second save is second
  file with later timestamp. Two forms. **Pointer form**: header block +
  `Resume from:` + one sentence, nothing else. **Full form** (generic and
  common case): optional one-paragraph preamble, then nine `##` sections —
  building / worked-with-evidence / didn't-work-and-why / not-yet-tried / file
  table (`File | Status | Notes`, status exactly one of Complete, In progress,
  Broken, Not started) / decisions-with-reasons / blockers / exact next step /
  environment. Two full-form rules load-bearing: **write every section**, `N/A`
  or `nothing yet` where genuinely empty (skipped section indistinguishable
  from overlooked one), and **evidence or it's a guess**. Form picked by
  artifact detection, which is the COMMAND's job — skills declare nothing, so
  skill gaining/losing artifact needs no change here. Known-artifact table has
  exactly ONE row today: `/product-design` → `.claude/domain/design-process.md`.
  Row qualifies only for **project-scoped state document carrying a resume
  marker** (current-stage/phase/next-step line, rewritten as work progresses) —
  static instruction file shipped inside installed skill folder never qualifies
  (holds no state, path relative to skill folder not project), so
  `/task-implement` deliberately has no row and its sessions take full form.
  See [../../docs/authoring-guide.md](../../docs/authoring-guide.md) § "State
  that outlives a session belongs in a project document". No row matches →
  recency check (file written THIS session carrying resume marker) → offer
  pointer form; decline or nothing found → full form. Header block both forms:
  `Work:` (`task <n>` | `feature <slug>` | `document <path>` | `none`; `none`
  first-class, may carry trailing `— <why>`; never two values, never a list,
  never a guessed task number) and `Running:` (skill/command in flight,
  INFERRED from conversation, never by reading state; ask user once when
  unclear). Pruning half: when THIS conversation itself resumed from a session
  file, write new snapshot FIRST then delete the resumed one as superseded —
  path taken from conversation (`/session-resume` states it), never guessed;
  deletes nothing when it can't tell, so an unresumed file is never
  auto-deleted. Writes nothing outside `.claude/sessions/` — not `.gitignore`,
  not `TASKS.md`/`FEATURES.md`, not a feature or context file. Runs no shell
  command but a single clock read, never `git`. **Does not commit, does not
  push, has no `--commit`.**
- `commands/session-resume.md` — reads one handoff and briefs current
  conversation from it. Command not skill, same single-pass shape. Resolution
  has exactly THREE forms: no argument → newest candidate; `YYYY-MM-DD` →
  newest candidate from that date; a path (contains `/` or `\`, or ends `.md`)
  → read as given with NO candidacy check. **No task-number selector** — bare
  number unrecognized, said in one line, run continues with newest candidate
  (whole failure contract is degradation, never refusal; only a missing
  directory / no candidate / missing explicit path stop it). **Only a file
  carrying a `Work:` line is a candidate** — the store may hold companion
  documents, and a non-candidate is skipped SILENTLY, not warned about. Ties on
  identical `YYYY-MM-DD-HHMM` prefix break deterministically on the FULL
  filename, descending; the picked file is named on the first output line,
  which is what makes a wrong pick correctable. Pointer form is followed: reads
  artifact named by `Resume from:` and briefs from THAT, using session file for
  its header block only; unresolved path named on its own line and briefing
  called thin. Staleness (>14 days) and paths that no longer resolve are both
  reported BEFORE the briefing, never after. Briefing fixed in shape: what was
  being built, what must not be retried (reasons kept attached), exact next
  step VERBATIM — then **stops and waits**, starting no work, not even the
  obvious one-line first step. Pruning half: closes by naming the resumed file
  and instructing the resumed session to delete it once its `Work:` is finished
  — an instruction, never an action, which is what keeps the command read-only
  and what lets `/session-save`'s supersession delete take the path from the
  conversation. Never names the pointed-at artifact for deletion; only the
  session file is superseded. Reads nothing under `.claude/tasks/`, nor
  `FEATURES.md`/`PLAN.md`, unless `Work:` points there. Writes nothing, deletes
  nothing, stages nothing; no `--prune`, no `--commit`. As with
  `/session-save`, no `chosko-llm` subcommand walks `.claude/sessions/` —
  session files are context for a human or agent, never input to tooling.
- `skills/runbook-run/` — orchestrator of the runbook asset kind
  (`.claude/runbooks/<name>.md` bodies + `.claude/RUNBOOKS.md` index; body is
  source of truth, index's `Status:`/`Steps:` derived and rebuildable from it —
  the id and its counter are the one exception, assigned rather than derived).
  **Skill not command** because `cmd-add` copies a skill folder with `cp -R`
  while a command is one file carrying nothing: it hosts `references/
  runbook-schema.md` (store, body schema, step markers `[ ]`/`[~]`/`[x]`/`[!]`,
  the four statuses `[PENDING]`/`[RUNNING]`/`[FAILED]`/`[DONE]`, the optional
  per-step `Needs:` field, index block + its `Last runbook number:` counter and
  per-runbook **id**)
  and `references/subagent-contract.md` (the OPERATING RULES block pasted
  verbatim into every spawned prompt — two placeholders, `<RUNBOOK>` and `<N>`,
  and it now carries the `SPAWN REQUEST` rule), both cited by the other three by
  `${CLAUDE_HOME:-$HOME/.claude}/...` path. No `requires:` — it IS the
  dependency. **Ids**: every runbook carries one beside its kebab-case name,
  and every command taking a name takes an id in its place — **a bare
  all-digits argument is an id, anything else a name**, unambiguous because a
  kebab-case name is never all digits. The id is an alias, never the identity:
  the body file stays `.claude/runbooks/<name>.md` and messages name the
  runbook. `Last runbook number:` only ever increases; survivors are never
  renumbered and a pruned id is never reused (`TASKS.md`'s rule, same reason —
  `max()` would hand a deleted runbook's id to the next one). An index written
  before ids is backfilled in place by the first command that **writes** it
  (`/runbook-create`, `/runbook-clean`, `/runbook-run`); a read-only command
  never does. Loop: re-read body at start of EVERY step (this is the whole
  reconciliation mechanism, and what makes mid-run `--append` steps picked up),
  select first `[ ]`/`[~]`/`[!]` step whose `Depends on:` are all `[x]`, mark
  `[~]`, spawn ONE subagent, **wait for the result notification** (the single
  most dangerous point — the spawn's return value is not the result), classify,
  commit. **Four** result cases: `QUESTIONS FOR USER` → relay to user, answer back
  to the SAME subagent, repeat; `SPAWN REQUEST` → the spawn relay, below; `DONE` + report → `[x]`, write `Done:` (sha,
  decisions, wrong premises), propagate facts as dated `Context:` bullets,
  update `Steps:`, commit; **anything else, incl. ambiguous → `[!]`**, index
  `[FAILED]` + `Failed at:`, halt. **Spawn relay** (`--relay-spawns` forces it;
  otherwise the step's own agent triggers it): where a subagent cannot spawn a
  subagent — cloud sessions — the step's agent writes the child's prompt to a
  `$TMPDIR` file, **never inside the repo**, and ends its turn with
  `SPAWN REQUEST` naming a prompt path, a result path and a model. The
  orchestrator spawns that child **at its own nesting level** — sideways, not
  down, which is the whole mechanism — waits, then tells the same suspended
  caller the result file is ready. It **opens neither file**: forwards, does not
  read, the same discipline as *compresses, does not answer*, and what keeps the
  child's output out of its context. Detection is the SUBAGENT's, not the
  orchestrator's — only the agent needing the tool can tell whether it has it,
  and a probe would measure the wrong environment. The caller stays suspended
  throughout, so one agent works at a time — the one stated exception to *never
  two subagents*; a child's own `SPAWN REQUEST` is served identically, so
  fan-out stays flat; cap of **8 relay rounds per step**, the ninth is a `[!]`
  failure. Relay files are never staged. Question-relay block is fixed text: question, lettered
  options with costs, a recommendation; at an approval gate the full draft
  follows **unabridged** — the one place it must not compress. In the subagent
  position (depth 3, a batch parent driving the runbook) it emits the same block
  as its own final turn under `QUESTIONS FOR USER`, for its parent to carry.
  **Commit convention: one commit per completed step**, staging exactly the
  runbook and the index, then push; `--no-commit`/`--no-push` usual meanings.
  `[~]` is deliberately NEVER committed — its presence in a tree is the resume
  signal and the same-tree exception to one-run-per-runbook (`[RUNNING]` in the
  index blocks a second run otherwise; no lock file, no timestamp, no staleness
  heuristic). Hard contracts: steps are **always sequential** (never parallel,
  even when declared independent — one question stream, and two agents would
  race on `Done:` lines); it **writes exactly two files** and does none of the
  work itself; **no step is ticked before its subagent's result arrives**; it
  reads only `CLAUDE.md`, the runbook and the index, and **does not review** a
  step's diff or commit; **no step invokes `/runbook-run`** (nested runbooks
  refused at spawn time). `--from N`/`--only N` narrow selection but never
  weaken `Depends on:`. Depth budget stated plainly in the body: orchestrator +
  step agent leaves one confirmed level **where nesting works at all** (depth 3
  verified locally 2026-08-24; a cloud subagent cannot spawn, and depth 4 was
  never probed anywhere) — and the spawn relay is why that mostly no longer
  matters: a step wanting its own subagent needs no third level.
- `commands/runbook-create.md` — authors a runbook, or appends to one.
  `requires: skill:runbook-run` — it cites that skill's `runbook-schema.md` for
  the body/index shape rather than carrying a second copy. **The only assigner
  of ids**: a new runbook takes `Last runbook number: + 1` (never `max()`) and
  advances the counter in the same write; an append assigns nothing. Also the
  only writer of a step's `Needs:` line (`agent` / `agent+human` / `human`,
  absent meaning `agent`) — a seventh from-scratch interview question, harvested
  in passing in conversation mode, and called out at the gate because whether
  the run can be left unattended is the one thing the titles cannot say.
  Command not skill:
  one pass with a confirmation gate, no supporting files of its own. Two
  orthogonal axes — target (`<name>` new / `--append <name>` / bare `--append` =
  the runbook this session is running, which a step's subagent knows because the
  spawned prompt names it / no args = ask) and source (the conversation's MOST
  RECENT enumerated follow-up list, the default; or a free-form description via
  one batched interview). Append is a flag, not a `/runbook-append` command:
  interview, prompt rules and gate are identical, only the write target differs.
  Append rules: numbering continues, existing steps NEVER edited, `Sequencing:`
  extended not replaced, `[DONE]` → back to `[PENDING]`, `[FAILED]` stays
  `[FAILED]`, `[RUNNING]` appendable **only from the running session itself**.
  Enforces ten prompt-quality rules before writing (self-contained; names the
  document to read first or carries evidence inline; carries every decision that
  exists nowhere on disk **and nothing that already does** — which is why
  `/task-implement 134` is a complete one-line prompt; states sequencing and
  why; states what must not be re-proposed; real slash commands in real argument
  form; **no path that will not exist at run time, in particular nothing under
  `docs/`**; one deliverable; never invokes `/runbook-run`; **rule 10** prefers
  two steps to one needing a nested spawn — a preference, not rule 9's
  rejection, because a skill that spawns internally cannot be split by an author
  who does not know it will, which is the case the spawn relay covers at run
  time), fixing failures and NAMING each fix in the report rather than silently. Gate shows the proposed
  shape only — never the full prompts, which are a wall of text and are in the
  file a moment later. `Context:` is authored as `none`: decisions belong INSIDE
  the fenced prompt, which keeps it pasteable into a fresh session by hand.
  **Commit convention: authoring** — leaves output uncommitted by default;
  `--commit` commits + pushes, `--commit --no-push` commits only.
- `commands/runbook-list.md` — read side. `requires: skill:runbook-run`, for
  vocabulary rather than parsing: the status set and index block shape are
  specified once in `runbook-schema.md`. One pass over `.claude/RUNBOOKS.md`,
  never opens a body under `.claude/runbooks/` — same discipline as
  `/task-list`'s never opening `.claude/tasks/`, and what keeps cost flat in the
  number of runbooks rather than their size (it is why the index carries
  `Steps:` at all). Prints `<id>. [STATUS] <name> <done>/<total> <created>
  <source> <title>` — the id leads so it can be typed at any other
  runbook command, the one-line title closes so the listing is answerable
  without opening anything; an id-less block prints `-` and is **left alone**,
  the backfill belonging to a command that writes the index. `Failed at:`
  printed as a continuation line under `[FAILED]` rows only. Optional status filter matched without brackets, case-insensitively
  (`/task-list`'s convention); unknown status names the four valid ones rather
  than printing nothing. Missing/empty index is not an error. **Writes nothing**,
  runs no shell, corrects no status however wrong it looks.
- `commands/runbook-describe.md` — the deep read side, and the deliberate pair
  to `/runbook-list`. `requires: skill:runbook-run` for the schema. Takes one
  runbook by **name or id** and prints it in four parts: the index heading line
  (id, name, status, progress, title; `Failed at:` continuation for `[FAILED]`),
  the body header (`Created:`/`Source:`/`Model:`/`Sequencing:`/`Companion:`,
  `Sequencing:` never summarised), every step (marker as the body carries it,
  `depends on:` always, `needs:` only when not plain `agent`, `Done:` rendered
  not summarised for `[x]` and `[!]` alike, `Context:` bullets), then the
  `## Do not re-propose` item count and a by-marker summary. **The one
  read-only runbook command allowed to open a body, and it opens exactly one**
  — never a walk of `.claude/runbooks/` — which is precisely the trade
  `/runbook-list` refuses; a `--verbose` on the listing would have destroyed the
  property that listing is built around, which is why this is its own command.
  **Prompt blocks are NOT printed** (the largest thing in the body; this is not
  a slow `cat`). `Needs:` is authoritative where authored; for a step lacking
  one it MAY infer from the prompt block, always rendered `(inferred)`, only
  where the prompt names the manual act, and **never written anywhere** — the
  note points at `/runbook-create --append` instead. Writes nothing, runs no
  shell, corrects no status however wrong the index looks against the body it
  just read.
- `commands/runbook-clean.md` — pruning, `/task-clean`'s exact shape.
  `requires: skill:runbook-run` for the status vocabulary and block shape. Three
  stages: resolve (no arg = every `[DONE]`; names **or ids** = exactly those,
  and a named non-`[DONE]` runbook is refused BY NAME with its actual status,
  never silently skipped; survivors are never renumbered and the counter never
  moves down) → plan and confirm (name, created date, steps done/total, both paths;
  empty plan says so and stops) → remove and commit (delete body files, remove
  index blocks incl. surrounding `---` rules, stage exactly those paths). An
  unknown name aborts the whole run **before anything is deleted**. Only
  `[DONE]` is eligible — narrower than `/task-clean`, which also takes `[SKIP]`;
  runbooks have no second terminal status. No `--force`, no status argument
  widening the set: a `[FAILED]` runbook is flipped by hand first, one visible
  committed edit. **Commit convention: cleanup** — commits and pushes by
  default (a deletion left uncommitted is the change most likely to be lost, and
  the confirm gate already served as the review pass); `--no-commit`/`--no-push`
  opt out.
- `skills/runbook-suggest/` — the trigger, and the only artifact nobody invokes.
  `requires: command:runbook-create` — the one judgment call in the graph: it
  cites no shared file and needs no schema, but a proposal naming a command that
  is not installed is exactly what `requires:` exists to stop. It depends on the
  command alone, not the whole suite. Skill not command **because a command is
  invoked and this is selected**: Claude Code picks a skill from its
  `description`, so the frontmatter IS the mechanism — no hook, no `Stop`
  handler, no event registration. ~30 lines of body, small because it loads on a
  guess. Threshold, carried in both description and body: suggest only when the
  follow-ups would be **lost with the conversation** — 3+ actions, or 2+ with an
  ordering constraint, or any that depends on decisions recorded nowhere on
  disk; never a two-step list of simple prompts. Anti-triggers named explicitly
  (single next action, list of things already done, checklist this session will
  work through, enumeration inside an explanation, backlog tasks = `/task-add`),
  the way `claude-council`'s description does. **The emitted line is generic**:
  one or two lines pointing at `/runbook-create` — new or append — naming no
  runbook, listing none, and not saying whether one is running, because
  new-versus-append is asked entirely by `/runbook-create`'s no-argument gate.
  Asks nothing (no gate, no waiting — a question from an auto-fired skill is an
  interruption at the wrong moment), opens no file (not `RUNBOOKS.md`, not a
  body), **writes nothing**, and never invokes `/runbook-create` itself. Fire
  rate is tuned by narrowing the description after observing real sessions —
  the accepted method, not an open question, and never a suppression flag.
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
- `claude-md/git-commit-style.md` — claude-md artifact: global commit-message
  shape — subject, optional body, trailer threshold — injected into
  `$CLAUDE_HOME/CLAUDE.md`. Read the artifact for the policy itself; commit
  hygiene (staging, atomicity, push) stays in
  `skills/task-engine/references/commit.md`. Never restate it in a feature
  body: `docs/authoring-guide.md` § *Commit message shape is global*.
- `hooks/remote-session-protocol.sh` — hook artifact (`event: PreToolUse`,
  `matcher: AskUserQuestion`): in a confirmed remote cloud session it DENIES
  the tool and returns the text protocol as `permissionDecisionReason` — one
  numbered batch, lettered options, a recommendation each, then end of turn —
  so a slow reply can't drive a re-ask loop. Gate is **positive-only** and
  evaluated by the shell, not the model: `CLAUDE_CODE_REMOTE=true` or non-empty
  `CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE`; anything else prints nothing (= no
  permission decision) and the tool proceeds untouched. False negatives are the
  accepted failure direction (renamed variable ⇒ hook stops firing ⇒ retune
  it), deliberately not "when in doubt, assume remote". `IS_SANDBOX` is
  explicitly NOT a signal — local sessions are sandboxed too. Carries no
  `set -euo pipefail` by design: exit 2 from a `PreToolUse` hook blocks the
  call, so every path ends in explicit `exit 0`. Chosen over a `CLAUDE.md`
  section (the first implementation, dropped before merge) because a hook costs
  zero resident tokens in the sessions where it never fires, and denial is
  enforcement rather than guidance. Verified end-to-end against live cloud
  sessions: project-committed hooks are trusted in containers, the matcher
  binds, the deny lands, and the model asked in text without retrying the
  denied tool.
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
type: command | skill | claude-md | statusline | hook
description: <one line>
replaces: command:<name>     # OPTIONAL, only on a kind change; see below
requires: skill:<name>       # OPTIONAL, any kind; comma-separated; see below
event: PreToolUse            # hook kind ONLY; required there
matcher: AskUserQuestion     # hook kind ONLY; optional, narrows event to one tool
---
```

`replaces:` is an optional key from the kind-migration path: set it when
a feature changes kind (`commands/<n>.md` rewritten as `skills/<n>/SKILL.md`),
so `add`/`update`/`update --all` remove the superseded artifact from
`$CLAUDE_HOME` instead of leaving two definitions of one slash command. Live
examples: `skills/context-build/SKILL.md` and `skills/context-update/SKILL.md`.
Drop the key once the migration has propagated.

`requires:` is the other optional key, valid on every kind: a comma-separated
list of kind-prefixed specs naming features whose files this one reads at run
time. `add` installs them first, `rm` refuses to remove one while a dependent
is installed (`--force` overrides). One level deep, unversioned,
non-transitive. Live examples: `commands/task-add.md`,
`commands/task-list.md`, `commands/task-clean.md` and
`skills/task-implement/SKILL.md`, all declaring `requires: skill:task-engine`.
Unlike `replaces:`, it is permanent — the dependency does not "propagate" and
the key is dropped only when the reference is.

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
  `skills/architect/` (three), `skills/task-review/remote-diffs.md`,
  `skills/context-build/nested.md` and
  `skills/context-update/nested.md` (one each) all follow this.
  `skills/task-iterate/` has none, and says so in its body so nobody goes
  looking for one. Whole
  folder is copied on install regardless — the saving is tokens per run,
  not bytes on disk.
- **`skills/task-engine/references/` is the other thing entirely.** Those
  files are read by OTHER features, not by their own `SKILL.md`, which is why
  the skill needs `requires:` and a plain supporting file does not. A skill's
  own supporting file is private to it and needs no declaration; a file
  another feature reads is a cross-feature dependency and must be declared, or
  it installs into a dangling path. See
  `../../docs/authoring-guide.md` § "Keeping the two `council-gate.md` copies
  in step" for the case where this does NOT apply (an optional dependency,
  which `requires:` cannot express).
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