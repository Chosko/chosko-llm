# Domain index

Product and rules knowledge for `chosko-llm`. Read this first, then the
files relevant to your task.

This layer answers WHAT the product is and WHY it is built this way. For
CODEBASE STRUCTURE — which file implements what — see
[../context/INDEX.md](../context/INDEX.md).

## Files

| File | Covers |
| --- | --- |
| [context-workflow.md](./context-workflow.md) | Navigation context layer under `.claude/context/`: the three skills (`/context-build`, `/context-update`, `/context-convert`), the per-context-file schema, and how the layer relates to the domain docs and `CLAUDE.md`. |
| [design-process.md](./design-process.md) | State of this project's `/product-design` run: method, phase table, and the current-stage marker a later session resumes from. |
| [product-design.md](./product-design.md) | The product design itself: what `chosko-llm` is, its target users, key flows, design decisions, and high-level feature set. |
| [product-workflow.md](./product-workflow.md) | Product pipeline from idea to backlog (`/domain-setup` → `/product-design` → `/architect` → `/task-add`): the documents each command exchanges and the two status vocabularies that keep design and backlog in sync. |
| [refactor-workflow.md](./refactor-workflow.md) | Philosophy and invariants behind `/refactor-codebase`: behaviour preservation, the plan-first approval gate, the focus concerns, and phase ordering. |
| [task-workflow.md](./task-workflow.md) | Task backlog schema and the dual-path implementation model: Claude Code authors via `/task-add`, Claude or an external LLM implements. |
| [technical-direction.md](./technical-direction.md) | The product's technical foundations: stack, topology, storage, hosting, protocols, cross-cutting concerns, and open decisions. |

## Features

Low-level feature documents live under [features/](./features/), one per
feature, written by `/architect`. The feature index — status and generated
task IDs per feature — is [../FEATURES.md](../FEATURES.md).

| File | Covers |
| --- | --- |
| [features/product-roadmap.md](./features/product-roadmap.md) | The roadmap document and the `/product-roadmap` skill: the strategic premise behind the order, milestones with goals and exit criteria, the scope slices that decide which share of a high-level feature each milestone takes, and the steer fork deciding who proposes the order. |
| [features/slice-aware-architecture.md](./features/slice-aware-architecture.md) | The `/architect` change that resolves a scope slice instead of a whole section when the project has a roadmap, with both resolution modes in on-demand files so unroadmapped projects behave exactly as today. |
| [features/production-plan.md](./features/production-plan.md) | `.claude/PLAN.md` and the `/production-plan` skill: milestone inheritance, ordered feature lists, the dependency graph, cycle and ordering validation, and milestone status. |
| [features/plan-readout.md](./features/plan-readout.md) | The read side: `/production-status`'s what-to-build-next report and milestone-aware grouping in `/task-list`. Writes nothing; every fact is derived at read time. |
| [features/session-continuity.md](./features/session-continuity.md) | `/session-save` and `/session-resume`: the per-project `.claude/sessions/` store, the full and pointer file forms, artifact detection, and the `Work:` line linking a session to the task, feature or document it belongs to. |
| [features/task-peer-review.md](./features/task-peer-review.md) | `/task-review` and `/task-iterate`: the three input forms, the confidence and pre-report gates, mandatory triage, sticky rejections, and the `--review --rounds N` loop inside `/task-implement`. |
| [features/task-implement-launcher.md](./features/task-implement-launcher.md) | The batch-mode change: the parent reads only `Target:`, `Status:` and `Feature:`, never a task body, and hands each agent a fixed-size prompt. |
| [features/shared-phase-engine.md](./features/shared-phase-engine.md) | Extracting the `task-*` suite's repeated rules into `skills/task-engine/references/`, and the `requires:` frontmatter field plus `cmd-add` / `cmd-rm` changes that make cross-feature references safe. |
| [features/repo-local-audits.md](./features/repo-local-audits.md) | `/context-budget` and `/rule-overlap` as unversioned, unshipped skills under this repo's own `.claude/skills/` — and why a tool for building the product is not part of it. |
