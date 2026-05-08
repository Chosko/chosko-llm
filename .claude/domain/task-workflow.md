# Task workflow — dual-LLM authoring/implementation

This project's `task-*` commands are designed around a deliberate split:
**Claude Code authors tasks; a smaller local LLM implements them.** Read
this doc when touching any `task-*` command, when changing the per-task
body schema, or when wiring an external implementer.

## Roles

- **Author** — Claude Code, via `/task-add`. Plans the task, identifies
  files, gathers context, writes a rich body file. Has access to the
  full repo and project conventions.
- **Implementer** — a less-powerful local model. Target stack:
  **qwen2.5-coder:14b via Ollama, driven by aider**. aider provides
  file-read, repo-map, and diff-based file-edit tools. The model is
  competent but not Claude-Code-level — it needs explicit pointers and
  acceptance criteria, not implicit conventions.

`/task-implement` (run by Claude Code) is a third path: the same
backlog, implemented by Claude itself when the user prefers. It still
benefits from the rich body schema (less reflexive context fan-out).

## Self-contained-body invariant

Per-task body files at `.claude/tasks/<N>.md` must be self-contained
enough for the external implementer. The schema (post-Task-1) is:

- `## Description` — prose, problem + desired behavior, file paths and
  line numbers when relevant.
- `### Files to modify` — replicates the `Files:` field from the
  TASKS.md summary block. The output surface.
- `### Required reading` — paths + line ranges + why, for files the
  implementer should `/add` to aider before editing.
- `### Relevant snippets` — optional. Quoted excerpts of central,
  non-obvious code, prefixed with `path:line` origins.
- `### Conventions to follow` — project rules the implementer must
  respect (pulled from CLAUDE.md and relevant context files).
- `### Out of scope` — explicit guardrails on what NOT to do.
- `### Behavior change` / `### Doc updates` — as applicable.
- `### Tests` — required for any code task.
- `### Definition of done` — required for any code task.

The implementer is fed the body file as the contract. If a piece of
information is missing from the body, that's an authoring bug — fix the
body, don't expect the implementer to discover it.

## Body vs TASKS.md — division of concerns

| Field | TASKS.md summary block | Body file | Why |
| --- | --- | --- | --- |
| Title, number | yes | yes (heading) | identification |
| Status | yes | no | changes during life — body would drift |
| Preconditions | yes | no | backlog-flow concern, not implementation |
| Files | yes | yes (`### Files to modify`) | output surface — implementer needs it |

Only `Files` is intentionally duplicated. `/task-add` writes both at
creation; neither changes during implementation, so drift risk is low.
`Status` and `Preconditions` are deliberately kept out of the body
because they describe how the task fits into the backlog, not what
needs to be built.

## Static implement-procedure artifact

`/task-setup` writes `.claude/external/implement-prompt.md` — the
system-prompt analogue of `/task-implement` for an external LLM. It
covers role, inputs, procedure, output discipline, and stop conditions.
It is project-local (travels via git, so a teammate can clone and run)
and idempotent (re-running `/task-setup` does not overwrite an edited
prompt file).

Standard aider invocation:

```
aider --model ollama/qwen2.5-coder:14b \
      --read .claude/external/implement-prompt.md \
      --read .claude/tasks/<N>.md
```

## `/task-implement` discipline

When the body uses the v0.2+ schema, Claude Code should treat it as a
high-quality starting point and avoid reflexive bulk-reads of the
context layer. This is a hint, not a constraint — judgment, not a
checklist. Reach for CLAUDE.md, `.claude/context/`, and other source
files when they would meaningfully inform the change; skip them when
the body is already sufficient. Older bodies (pre-Task-1 schema) lack
the new sections — for those, consult the context layer as before.

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — hard rules (authoring,
  versioning, copy-not-symlink, no new deps).
- [`../context/features.md`](../context/features.md) — shipped
  artifacts including every `task-*` command.
- [`../../docs/authoring-guide.md`](../../docs/authoring-guide.md) —
  frontmatter schema + semver bump rules.
- `commands/task-setup.md`, `commands/task-add.md`,
  `commands/task-implement.md`, `commands/task-clean.md`,
  `commands/task-list.md` — the command implementations.
