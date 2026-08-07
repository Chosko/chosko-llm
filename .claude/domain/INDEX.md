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
| [features/product-roadmap.md](./features/product-roadmap.md) | The roadmap document and the `/product-roadmap` skill: milestones with goals and exit criteria, and the scope slices that decide which share of a high-level feature each milestone takes. |
| [features/slice-aware-architecture.md](./features/slice-aware-architecture.md) | The `/architect` change that resolves a scope slice instead of a whole section when the project has a roadmap, with both resolution modes in on-demand files so unroadmapped projects behave exactly as today. |
| [features/production-plan.md](./features/production-plan.md) | `.claude/PLAN.md` and the `/production-plan` skill: milestone inheritance, ordered feature lists, the dependency graph, cycle and ordering validation, and milestone status. |
| [features/plan-readout.md](./features/plan-readout.md) | The read side: `/production-status`'s what-to-build-next report and milestone-aware grouping in `/task-list`. Writes nothing; every fact is derived at read time. |
