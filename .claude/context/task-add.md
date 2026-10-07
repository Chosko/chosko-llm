# Features: task-add

## Overview

Covers `/task-add`, the backlog's authoring command. The rest of the suite:
[task-suite.md](./task-suite.md).

- `commands/task-add.md` — plans and writes new task conversationally:
  writes summary block to `.claude/TASKS.md` and thin body file at
  `.claude/tasks/<N>.md`. **Placement**: new blocks append at the end by
  default; `--before <N>` writes above task N's block and appends the new
  id to N's `Preconditions:` (the one sanctioned edit to another task's
  line), `--after <N>` writes below it and puts N on the new task's
  `Preconditions:` — position and edge ALWAYS together (position for the
  reader, edge for `next`/`all`), flags mutually exclusive, unknown N
  stops, next id from the counter exactly as an append, no existing id
  moves; with several new tasks the flag places the first and the rest
  follow it. **`feature=<slug> --single`**: exactly one task attached to a
  `[PLANNED]` feature (any other status stops) — `Feature:` line plus the
  id appended to `Tasks:`, but NO reconciliation, `Status:` untouched, no
  documentation task, no split; mutually exclusive with `--short`; the
  report ends with a fixed write-back line naming
  `/pipeline-revise feature=<slug>`; commits under the single-task/split
  message plus `FEATURES.md` (`commit.md`'s fourth, "attached" form, never
  `Plan feature`). **Orphan question**: a free-form run (not `--short`) on a
  project with `.claude/FEATURES.md` asks inside PHASE 3's existing gate
  whether the task belongs to a `[PLANNED]` feature, none the default; a
  slug takes the `--single` path. No `FEATURES.md` → nothing asked.
  **Approval digest**: PHASE 3 renders per task only the `## <N>. <Title>`
  heading, `Target:`, `## Goal`, `## Decisions` when present and
  `## Manual interventions` in full when the target is `claude+human` /
  `human` — plus one `Order:` line on a split and the `Placement:` line
  under `--before` / `--after`, the only wiring the gate shows. The summary
  block's fields, the acceptance criteria and the Hints are authored in full
  and written by PHASE 4, whose report names the IDs, both paths and the
  counter advance. Default body schema (target: claude) contains
  Goal, Acceptance criteria, Decisions (when applicable), Hints.
  When work includes steps
  only human can perform in external tool (e.g. Unity editor),
  sets `Target: claude+human` (or `human`) and authors
  `## Manual interventions` checkpoint section — the pairing rule is
  `targets.md`'s. Refuses if `/task-setup` not run. May propose splitting
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
  detection off the four-row owner list in `task-engine`'s
  `references/design-change.md`, which `/task-add` cites
  (`domain/features/*.md` → `/architect`; `product-design.md` /
  `technical-direction.md` / `business-model.md` → `/product-design`;
  `product-roadmap.md` → `/product-roadmap`; `PLAN.md` →
  `/production-plan`; `FEATURES.md` / `TASKS.md` excluded), specific
  points enumerated per file as *settles* (document leaves it open) or
  *diverges* (design change). DESIGN-CHANGE CHECK asks one question per
  task inside PHASE 3's single gate, only when a point diverges — before →
  after, agree? — settling points listed for the record. Agreement covers
  the whole design change (every passage stating the old design), recorded
  as an acceptance criterion plus a dated Decisions bullet, path joins
  `Files:`; disagreement returns to PHASE 2 questions. No read-only marker,
  no drop answer. Silence is not agreement; PHASE 4 refuses a task with an
  unanswered diverging point. A rewritten body (reconciliation or
  `task-engine/references/amend.md`) re-checks only points it adds.
  Agreement authorises that task's implementer — `/task-add` still never
  edits an owned document. Free-form text alongside slug narrows scope;
  feature document read-only to `/task-add` itself.
  Documents two product-pipeline additions to backlog schema: optional
  `Feature: <slug>` summary-block line (feature-derived tasks
  only; absent, not `none`, on free-form ones) and `[STALE]` status
  (resolved by `/task-add feature=<slug>` reconciliation).
  Declares `requires: skill:task-engine` and is the largest consumer of it:
  PHASE 0's setup check and the index-file format reference
  `references/resolution.md`, the status-tag block `status.md`, target values
  and manual interventions `targets.md`, the `[STALE]` and
  reconciliation-classification rules `stale.md`, the DESIGN-CHANGE CHECK
  `design-change.md`, the RECONCILIATION application rules (and PHASE 4
  feature-case step 3) `reconciliation.md`, THE ORPHAN QUESTION
  `orphan-question.md`, and PHASE 5 `commit.md` — each kept as
  a heading with its conditions and a citation, its phase placement in that
  file's `/task-add` note. What stays inline is what is unique to
  authoring.

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
- [task-engine.md](./task-engine.md) — the reference library it reads.

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
