# cmd-task-impl

## Overview

`scripts/cmd-task-impl.sh` is the CLI orchestrator that drives the 8-step
task-implement sequence for the **current project** (cwd) using an external
LLM — aider + Ollama (`qwen2.5-coder:14b` by default) — instead of Claude
Code. It is the executable counterpart to the `/task-implement` command:
same backlog, same per-task flow, one commit per task. It is the only
subcommand that operates on the user's project rather than on `$CLAUDE_HOME`.

Helper logic lives in `scripts/lib-task-external.sh` (sourced alongside
`lib.sh`) — backlog path/parse helpers, `flip_task_status`,
`require_clean_tree`, artifact/stub detection. See
[lib-task-external.md](./lib-task-external.md).

## Public API

CLI:
- `chosko-llm task-impl <N> [<N>…]` — implement those task numbers in order.
- `chosko-llm task-impl all` — every task whose status is `[MISSING]` /
  `[STUBBED]` / `[INCORRECT]` / `[PARTIAL]`, in document order.
- `--model <name>` / `--retries <N>` / `--map-tokens <N>` — aider knobs
  (also via `CHOSKO_TASK_IMPL_MODEL` / `_RETRIES` / `_AIDER_MAP_TOKENS`).
- `--help` (anywhere in argv) — usage, exit 0.

Env: `CHOSKO_TASK_IMPL_AIDER` (aider executable), plus the three above.

Exit codes: 2 on usage error (no tasks / unknown flag); 1 (via `die`) on a
missing backlog, missing external artifacts, missing aider, a corrupt task,
or a task that won't go green within the retry budget; 0 when all requested
tasks complete.

## Internal patterns

- **Reads the static external artifacts** under `.claude/external/`
  (`implement-prompt.md`, `tests-prompt.md`, `run-affected-tests.sh`,
  `run-full-tests.sh`) — created by `/task-setup`. `require_external_artifacts`
  refuses to run without them.
- **Skip-tests mode** is auto-detected via `wrappers_are_stubs` (the
  `# CHOSKO_TASK_IMPL_STUB` sentinel). In that mode steps 2/3/5/6 are skipped
  and each task asks for confirmation first.
- **TDD enforced via retries.** Step 3 expects affected tests to FAIL first;
  step 4 re-invokes aider up to `--retries` times until affected tests pass;
  step 6 does the same against the full suite. A task that never goes green is
  left `[IN PROGRESS]` and the run halts.
- **Status flips + commit are the orchestrator's job, not aider's.** aider
  runs with `--no-auto-commits`; the script does `flip_task_status` and one
  `git add -- <index + Files> && git commit -m "Task N: <title>"` per task,
  staging explicit paths only.
- **Clean-tree gate per task** (`require_clean_tree`) mirrors the
  `/task-implement` pre-flight.

## Domain dependencies

- `../domain/task-workflow.md` — the dual-LLM split this orchestrator
  implements (Claude authors, the external LLM implements); body schema and
  the external-artifact contract.
- `../../skills/task-implement/SKILL.md` — the Claude-driven sibling; the two
  keep the same 8-step shape and one-commit-per-task rule.

## Cross-references

- [lib-task-external.md](./lib-task-external.md) — the project-scoped backlog
  parse/mutate/guard helpers this orchestrator is built on.
- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for logging/`die`
  (required before `lib-task-external.sh`).
- [cli-entry.md](./cli-entry.md) — the proxy routes `task-impl` here.

## When to read the source

- Changing the per-task workflow, retry handling, or commit shape →
  `scripts/cmd-task-impl.sh` (`implement_one`).
- Changing backlog parsing, status flips, artifact resolution, or stub
  detection → `scripts/lib-task-external.sh`.
- Changing aider invocation (flags, model, map-tokens) → `run_aider` in
  `cmd-task-impl.sh`.
