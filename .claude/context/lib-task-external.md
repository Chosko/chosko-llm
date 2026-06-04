# lib-task-external

## Overview

`scripts/lib-task-external.sh` holds the helpers specific to the external-LLM
task orchestrator. It is sourced by `cmd-task-impl.sh` **after** `lib.sh`
(it relies on `log_*` / `die` from there) and is never executed directly.

Unlike `lib.sh` (which operates on `$CHOSKO_LLM_HOME` / `$CLAUDE_HOME`), every
helper here operates on the **current project's** backlog, rooted at
`${PROJECT_ROOT:-$PWD}`: `.claude/TASKS.md`, `.claude/tasks/<N>.md`, and the
per-project external artifacts under `.claude/external/`.

## Public API

All functions live in `scripts/lib-task-external.sh`.

### Project paths (rooted at `${PROJECT_ROOT:-$PWD}`)
- `project_tasks_index` → `.claude/TASKS.md`.
- `project_task_body <N>` → `.claude/tasks/<N>.md`.
- `project_external_dir` → `.claude/external`.
- `external_artifact <name>` → `.claude/external/<name>`.

### TASKS.md parsing
- `task_summary_block <N>` — prints task `<N>`'s summary block (`## <N>. …`
  heading down to the next `---`/EOF), or empty if absent.
- `task_field <N> <field>` — value of a `Field:` line (`Status`, `Files`,
  `Preconditions`) from that block; the synthetic `Title` field is extracted
  from the heading.
- `task_status <N>` / `task_files <N>` / `task_title <N>` /
  `task_preconditions <N>` — convenience wrappers over `task_field`.

### TASKS.md mutation
- `flip_task_status <N> <new-status>` — replace the `Status:` line in task
  `<N>`'s block (status must include brackets, e.g. `[IN PROGRESS]`). Atomic:
  writes a tempfile then renames.

### External-artifact / wrapper detection
- `require_external_artifacts` — `die`s unless all four artifacts exist
  (`implement-prompt.md`, `tests-prompt.md`, `run-affected-tests.sh`,
  `run-full-tests.sh`) AND the two wrapper scripts are executable.
- `wrappers_are_stubs` — 0/true when `run-full-tests.sh` carries the
  `# CHOSKO_TASK_IMPL_STUB` sentinel (skip-tests mode).

### Git
- `require_clean_tree` — `die`s if `git status --porcelain` is non-empty
  (respects `.gitignore`).

## Internal patterns

- **`PROJECT_ROOT` is the single root.** Every path helper honours
  `${PROJECT_ROOT:-$PWD}`; nothing hardcodes a project path. The orchestrator
  sets `PROJECT_ROOT` once at startup.
- **TASKS.md is parsed by awk keyed on the `## <N>. ` heading**, with `---`
  (or EOF) ending a block. The block grammar here MUST match how
  `/task-add` / `/task-clean` write blocks and how the `Status:` line is
  formatted — keep them in lockstep with [../domain/task-workflow.md](../domain/task-workflow.md).
- **Status flips are atomic** (tempfile + `mv`), so an interrupted run can't
  leave a half-written `TASKS.md`.
- **Skip-tests detection is sentinel-based**, not heuristic: only the exact
  `# CHOSKO_TASK_IMPL_STUB` line counts. `/task-setup` writes that sentinel
  into stub wrappers.

## Domain dependencies

- `../domain/task-workflow.md` — the backlog/body schema and the
  external-artifact contract these helpers read and mutate.
- The `TASKS.md` summary-block format (heading, `Status:` / `Files:` /
  `Preconditions:` lines) — owned by `/task-add` / `/task-clean`.

## Cross-references

- [cmd-task-impl.md](./cmd-task-impl.md) — the sole consumer; this lib is the
  parse/mutate/guard layer beneath its `implement_one` flow.
- [shared-lib.md](./shared-lib.md) — must be sourced first; provides
  `log_*` / `die`. This lib adds project-scoped helpers on top.

## When to read the source

- Changing how `TASKS.md` blocks are located, parsed, or status-flipped →
  the awk in `task_summary_block` / `task_field` / `flip_task_status`.
- Changing the external-artifact set or the skip-tests sentinel →
  `require_external_artifacts` / `wrappers_are_stubs`.
- Changing the project-root or artifact path layout → the path helpers at the
  top of `scripts/lib-task-external.sh`.
