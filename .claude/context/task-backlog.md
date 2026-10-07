# Features: task backlog setup, cleanup, listing

## Overview

Covers the task suite's backlog-maintenance features: `task-setup`,
`task-clean` and `task-list`. The rest of the suite:
[task-suite.md](./task-suite.md).

- `commands/task-setup.md` — initializes backlog: `.claude/TASKS.md`
  stub, `.claude/tasks/` directory, and the project's **test-dispatch
  convention** — `.claude/external/run-affected-tests.sh` +
  `run-full-tests.sh`, thin wrappers inferred from project files giving
  one stable pair of entry points for the affected and full suites.
  Nothing in the `task-*` suite invokes them; `/task-implement`
  resolves its own test command and never reads them. No-test-suite
  projects get no-op stubs carrying the `# CHOSKO_TASK_IMPL_STUB`
  sentinel, which is what marks a wrapper as a stub on a re-run, after it
  asks `skip-tests` or `skip-tests-unattended` and writes
  `Testing policy for /task-implement: <value>` into a
  `## Tasks implementation` section of `CLAUDE.md` — not asked when that
  line already holds one of the two, as after `/project-setup`. Carries no copy of the
  index or body formats — cites `task-engine`'s `resolution.md` § Index
  file format and `/task-add`'s body format relatively, declaring
  `requires: skill:task-engine, command:task-add`.
  Required before `/task-add`. Idempotent — re-runs only fill missing
  artifacts, never overwrite a non-stub wrapper. **Authoring command —
  leaves scaffolding uncommitted for user review by default;
  `--commit` opts in to committing exactly paths run wrote.**
- `skills/task-clean/` — archives terminal-status tasks. Carries
  `replaces: command:task-clean`, so `add` / `update` retire an installed
  command copy. `--backfill`'s procedure sits in supporting file
  `backfill.md`, read ON DEMAND only when the flag is present, so an
  ordinary prune never pays its tokens. Terminal means
  `[DONE]` and `[SKIP]` and nothing else — `[STALE]` is live work awaiting
  reconciliation and `[PARKED]` live work awaiting an answer, and neither is
  ever pruned by default (naming either explicitly warns and confirms; for
  `[PARKED]` the plan says the prune discards the question and orphans the
  `park/task-<N>` branch, named per task, for the next run's sweep); a
  non-terminal status named
  explicitly archives the same
  way, its frozen `Status:` recording that it was pruned live. Removes
  summary blocks and MOVES each body to `.claude/tasks/archive/<N>.md`
  (`mkdir -p` + `git mv`, so history follows the file; plain `mv` for an
  untracked body), then writes a frozen header under its title — `Archived:`
  date plus the summary block's `Status:` / `Files:` / `Preconditions:` /
  `Feature:` as they stood. No body is ever deleted. PHASE 1 probes source
  and destination by exact-path Glob, never a folder listing: a missing
  source is noted and its block still leaves; an existing destination is
  refused (task stays in the backlog), never overwritten. Survivors'
  `Preconditions:` drop archived ids — an archived precondition is a
  satisfied one. Never renumbers — task IDs stable across project's
  lifetime; `Last task number` counter never decreases. A prune never
  opens `.claude/FEATURES.md`, so a feature keeps every id it generated on
  `Tasks:` and `Tasks: none` means never planned. `--backfill` (exclusive with a status set, git only — a `## VCS`
  override stops it — same **"Apply?"** gate) recovers bodies earlier runs
  deleted: `git log --diff-filter=D` under `.claude/tasks/`, latest deletion
  per path, ids live or already archived dropped; body from the deleting
  commit's parent, header from that parent's `TASKS.md` block, `Archived:`
  the deletion date (no block → hand deletion, `Archived:` alone, flagged);
  each id put back on its feature's `Tasks:` line at its ascending position
  — the skill's only `FEATURES.md` write, on that path alone; a vanished
  slug reported, not written. Never writes `TASKS.md` under `--backfill`; a
  second run reports nothing to recover. THE PARK-BRANCH SWEEP runs on every
  prune (not `--backfill`, not under a `## VCS` override): `git branch --list
  'park/task-*'` plus `git ls-remote --heads origin` (remote skipped under
  NO_PUSH), orphan = no summary block or `Status:` neither `[PARKED]` nor
  `[IN PROGRESS]` as PHASE 1 read it (a resumed task keeps its branch as
  rollback source until its commit); orphans get a plan section (none → nothing said), are deleted in
  PHASE 2 step 7 on the same gate (`git branch -D` / `git push origin
  --delete`), a failed delete reported, not fatal; "No tasks to prune." only
  when there are neither tasks nor orphans; a sweep-only run commits nothing.
  Commits automatically:
  `task-clean: archive tasks <N>, …` staging `.claude/TASKS.md` + each
  `.claude/tasks/archive/<N>.md` (`git mv` already staged both halves of the
  rename); backfill `task-clean: backfill <N> archived tasks`, adding
  `.claude/FEATURES.md` when a line was restored. `--no-commit` leaves them
  uncommitted, the move still made. Declares `requires: skill:task-engine`:
  backlog parsing and the archive form and
  rule reference `references/resolution.md` (§ *The archive*; its
  `/task-clean` note makes the skill the archive's only writer and its one
  exception to the read prohibition — a per-destination existence check),
  the prune-set vocabulary `status.md`, the `[STALE]` warning `stale.md`,
  and the commit/push gating `commit.md`.
- `commands/task-list.md` — prints backlog as compact read-only
  summary. Marks `claude+human` / `human` tasks with `⚠ <target>`, shows
  `[<slug>]` for tasks with `Feature:` line, appends `⚠ stale` to
  `[STALE]` tasks and `⚠ parked` to `[PARKED]` ones in that same slot (a
  task is never both; `PARKED` filters like any status; nine tags, the
  padded column still sized to `[IN PROGRESS]`). When `.claude/PLAN.md` exists, also groups tasks under
  milestone headings in plan order, resolving each task's `Feature:` slug
  through the milestones' `Features:` lists, and appends `⚠ blocked by <slug>`
  when the task's feature is blocked — same readiness rule as
  `/production-status`, duplicated rather than shared (one paragraph of logic
  in a markdown prompt), with an unresolvable edge slug ignored rather than
  treated as a blocker. Tasks with no `Feature:` line and slugs no milestone
  lists (including `Unscheduled` ones) fall under one trailing `Unplanned`
  heading; empty milestones get no heading. Marker order stated explicitly in
  the body: `⚠ <target>`, `[<slug>]`, `(deps: N, M)`, `⚠ stale` |
  `⚠ parked`, `⚠ blocked by <slug>`. Filter applies before grouping, so it works within
  groups; the summary line is the same with or without grouping. NO
  `PLAN.md` → no grouping, a silent no-op with no warning and no pointer at `/production-plan`. Reads
  `.claude/TASKS.md`, plus `PLAN.md` and `FEATURES.md` when a plan exists;
  never opens body files, feature docs or the roadmap. Declares
  `requires: skill:task-engine`: backlog
  resolution references `references/resolution.md` and the status vocabulary
  `status.md`, leaving only the rendering rules inline.

## Public API

- Each feature's contract is its text in § Overview. Frontmatter,
  `description` contract and loading-control keys:
  [task-suite.md](./task-suite.md) § Public API.

## Internal patterns

- [task-suite.md](./task-suite.md) § Internal patterns.

## Domain dependencies

- [task-suite.md](./task-suite.md) § Domain dependencies.

## Cross-references

- [task-suite.md](./task-suite.md) — the task-suite hub and its file list.
- [task-engine.md](./task-engine.md) — the reference library `task-clean`
  and `task-list` read.

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
