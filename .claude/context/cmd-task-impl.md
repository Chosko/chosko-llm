Compress via /caveman-compress skill needs file path. User gave text directly — compress inline, return markdown body.

# cmd-task-impl

## Overview

`scripts/cmd-task-impl.sh` — CLI orchestrator, drive 7-step task-implement sequence for **current project** (cwd) via external LLM — aider + Ollama (`qwen2.5-coder:14b` default) — instead of Claude Code. Executable counterpart to `/task-implement` command: same backlog, same per-task flow, one commit per task. Only subcommand operating on user's project, not `$CLAUDE_HOME`.

Helper logic in `scripts/lib-task-external.sh` (sourced alongside `lib.sh`) — backlog path/parse helpers, `flip_task_status`, `require_clean_tree`, artifact/stub detection. See [lib-task-external.md](./lib-task-external.md).

## Public API

CLI:
- `chosko-llm task-impl <N> [<N>…]` — implement those task numbers in order.
- `chosko-llm task-impl all` — every task with status `[MISSING]` / `[STUBBED]` / `[INCORRECT]` / `[PARTIAL]`, document order. `[STALE]` outside allowlist — `all` never selects one.
- `--model <name>` / `--retries <N>` / `--map-tokens <N>` — aider knobs (also via `CHOSKO_TASK_IMPL_MODEL` / `_RETRIES` / `_AIDER_MAP_TOKENS`).
- `--help` (anywhere in argv) — usage, exit 0.

Env: `CHOSKO_TASK_IMPL_AIDER` (aider executable), plus three above.

Exit codes: 2 usage error (no tasks / unknown flag); 1 (via `die`) on missing backlog, missing external artifacts, missing aider, corrupt task, explicitly requested `[STALE]` task, or task not going green within retry budget; 0 all requested tasks complete.

## Internal patterns

- **Reads static external artifacts** under `.claude/external/` (`implement-prompt.md`, `tests-prompt.md`, `run-affected-tests.sh`, `run-full-tests.sh`) — created by `/task-setup`. `require_external_artifacts` refuses run without them.
- **Skip-tests mode** auto-detected via `wrappers_are_stubs` (`# CHOSKO_TASK_IMPL_STUB` sentinel). That mode: steps 2/4/5 skipped, each task asks confirmation first.
- **Tests-first, enforced via retries.** Step 3 re-invokes aider up to `--retries` times till affected tests pass; step 5 same against full suite. Task never going green left `[IN PROGRESS]`, run halts.
- **Status flips + commit = orchestrator's job, not aider's.** aider runs with `--no-auto-commits`; script does `flip_task_status` + one `git add -- <index + Files> && git commit -m "Task N: <title>"` per task, staging explicit paths only.
- **Clean-tree gate per task** (`require_clean_tree`) mirrors `/task-implement` pre-flight.
- **`[STALE]` refused, not skipped.** Implementable-status allowlist (`resolve_all` awk selection + per-task `case` in `implement_one`) excludes `[STALE]`; explicitly requested stale ID `die`s with feature slug from its `Feature:` line + pointer to `/task-add feature=<slug>`. Interactive `/task-implement` may implement one on user's say-so — asymmetry deliberate, external LLM can't judge superseded design.

## Domain dependencies

- `../domain/task-workflow.md` — dual-LLM split this orchestrator implements (Claude authors, external LLM implements); body schema + external-artifact contract.
- `../../skills/task-implement/SKILL.md` — Claude-driven sibling; both keep same 7-step shape + one-commit-per-task rule.

## Cross-references

- [lib-task-external.md](./lib-task-external.md) — project-scoped backlog parse/mutate/guard helpers this orchestrator built on.
- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for logging/`die` (required before `lib-task-external.sh`).
- [cli-entry.md](./cli-entry.md) — proxy routes `task-impl` here.

## When to read source

- Changing per-task workflow, retry handling, commit shape → `scripts/cmd-task-impl.sh` (`implement_one`).
- Changing backlog parsing, status flips, artifact resolution, stub detection → `scripts/lib-task-external.sh`.
- Changing aider invocation (flags, model, map-tokens) → `run_aider` in `cmd-task-impl.sh`.