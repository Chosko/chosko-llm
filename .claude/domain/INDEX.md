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
