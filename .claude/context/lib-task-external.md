# lib-task-external

## Overview

`scripts/lib-task-external.sh` holds helpers specific to external-LLM task orchestrator. Sourced by `cmd-task-impl.sh` **after** `lib.sh` (relies on `log_*` / `die` from there). Never executed directly.

Unlike `lib.sh` (operates on `$CHOSKO_LLM_HOME` / `$CLAUDE_HOME`), every helper here operates on **current project's** backlog, rooted at `${PROJECT_ROOT:-$PWD}`: `.claude/TASKS.md`, `.claude/tasks/<N>.md`, per-project external artifacts under `.claude/external/`.

## Public API

All functions live in `scripts/lib-task-external.sh`.

### Project paths (rooted at `${PROJECT_ROOT:-$PWD}`)
- `project_tasks_index` → `.claude/TASKS.md`.
- `project_task_body <N>` → `.claude/tasks/<N>.md`.
- `project_external_dir` → `.claude/external`.
- `external_artifact <name>` → `.claude/external/<name>`.

### TASKS.md parsing
- `task_summary_block <N>` — prints task `<N>`'s summary block (`## <N>. …` heading down to next `---`/EOF), empty if absent.
- `task_field <N> <field>` — value of `Field:` line (`Status`, `Files`, `Preconditions`) from that block; synthetic `Title` field extracted from heading.
- `task_status <N>` / `task_files <N>` / `task_title <N>` / `task_preconditions <N>` — convenience wrappers over `task_field`.

### TASKS.md mutation
- `flip_task_status <N> <new-status>` — replace `Status:` line in task `<N>`'s block (status must include brackets, e.g. `[IN PROGRESS]`). Atomic: writes tempfile then renames.

### External-artifact / wrapper detection
- `require_external_artifacts` — `die`s unless all four artifacts exist (`implement-prompt.md`, `tests-prompt.md`, `run-affected-tests.sh`, `run-full-tests.sh`) AND two wrapper scripts executable.
- `wrappers_are_stubs` — 0/true when `run-full-tests.sh` carries `# CHOSKO_TASK_IMPL_STUB` sentinel (skip-tests mode).

### Git
- `require_clean_tree` — `die`s if `git status --porcelain` non-empty (respects `.gitignore`).

## Internal patterns

- **`PROJECT_ROOT` single root.** Every path helper honours `${PROJECT_ROOT:-$PWD}`; nothing hardcodes project path. Orchestrator sets `PROJECT_ROOT` once at startup.
- **TASKS.md parsed by awk keyed on `## <N>. ` heading**, `---` (or EOF) ends block. Block grammar here MUST match how `/task-add` / `/task-clean` write blocks and how `Status:` line formatted — keep lockstep with [../domain/task-workflow.md](../domain/task-workflow.md).
- **Status flips atomic** (tempfile + `mv`), interrupted run can't leave half-written `TASKS.md`.
- **Skip-tests detection sentinel-based**, not heuristic: only exact `# CHOSKO_TASK_IMPL_STUB` line counts. `/task-setup` writes sentinel into stub wrappers.

## Domain dependencies

- `../domain/task-workflow.md` — backlog/body schema and external-artifact contract these helpers read and mutate.
- `TASKS.md` summary-block format (heading, `Status:` / `Files:` / `Preconditions:` lines) — owned by `/task-add` / `/task-clean`.

## Cross-references

- [cmd-task-impl.md](./cmd-task-impl.md) — sole consumer; this lib is parse/mutate/guard layer beneath its `implement_one` flow.
- [shared-lib.md](./shared-lib.md) — must be sourced first; provides `log_*` / `die`. This lib adds project-scoped helpers on top.

## When to read the source

- Changing how `TASKS.md` blocks located, parsed, or status-flipped → awk in `task_summary_block` / `task_field` / `flip_task_status`.
- Changing external-artifact set or skip-tests sentinel → `require_external_artifacts` / `wrappers_are_stubs`.
- Changing project-root or artifact path layout → path helpers at top of `scripts/lib-task-external.sh`.