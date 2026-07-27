# Product workflow — from product idea to implementation task

This document is the source of truth for the product pipeline: the commands
that take a product from brainstorming through architecture to an
implementable backlog, the documents they exchange, and the two status
vocabularies that keep design and backlog in sync. Read it when touching
`/domain-setup`, `/product-design`, `/architect`, or the feature-aware parts
of `/task-add` and `/task-clean`.

## Why this exists

`/task-add` has always accepted a free-form description and produced a task.
That works when the user already knows what to build. It does not cover the
step before: deciding what the product is, which features it has, and how
they should be built. Three commands fill that gap, and each hands its output
to the next as a document rather than as conversation — so the work survives
across sessions, across machines, and across people.

The pipeline exists to make that handoff explicit. Its cost is a set of files
that must agree on schema; this document is what they agree on.

## The pipeline

| Stage | Command | Consumes | Produces |
| --- | --- | --- | --- |
| 0 — scaffold | `/domain-setup` | nothing | the domain layer + an empty `FEATURES.md` |
| 1 — design | `/product-design` | the user, and the repo when brownfield | `product-design.md`, `technical-direction.md`, optional `business-model.md`, `design-process.md` |
| 2 — architect | `/architect` | a high-level feature, or a bare prompt | `features/<slug>.md` + a `FEATURES.md` entry |
| 3 — plan | `/task-add feature=<slug>` | a feature doc | task bodies + `TASKS.md` entries |
| 4 — build | `/task-implement` | a task body | code |

Stages are entered, not marched through. A project with an existing codebase
commonly starts at stage 0 then jumps to stage 2; a project whose next change
is obvious skips to stage 3 with a free-form description, exactly as today.
Nothing downstream requires that an upstream stage was ever run.

## Artifacts

```
.claude/
  TASKS.md                        the task backlog index
  FEATURES.md                     the feature index (sibling of TASKS.md)
  tasks/<N>.md                    one body per task
  domain/
    INDEX.md                      the domain-layer index
    design-process.md             resumable state of a /product-design run
    product-design.md             high-level product design
    technical-direction.md        the product's technical foundations
    business-model.md             business model (only when requested)
    features/<slug>.md            one doc per low-level feature
```

`FEATURES.md` sits at the `.claude/` root rather than inside `domain/`
because it indexes work items, like `TASKS.md`. The feature *documents* it
points at are knowledge, so they live in the domain layer.

### `product-design.md`

Sections: product summary, target users, user experience and key flows, the
big design decisions, and the high-level feature set. Written in a
documentational register — the WHAT and, to a degree, the HOW. Rationale
belongs in conversation and in `design-process.md`, not here.

### `technical-direction.md`

Sections: stack, topology/architecture, data and storage, async/queueing,
hosting and deployment, inter-component protocols, cross-cutting concerns,
explicitly-open decisions. Unconditional — stubbed alongside
`product-design.md` in PHASE 1 and always filled in PHASE 7, since every
product has technical foundations. This is the standing constraint
`/architect` designs within: when present, it is treated as an existing
stack and `/architect`'s PHASE 2a tech-stack selection is skipped.

### `business-model.md`

Sections: revenue model, cost structure, target segments, pricing,
go-to-market, unit economics, risks. Optional — created only when the user
asks for business modelling, so the pipeline stays usable for internal tools
and side projects.

### `design-process.md`

The state file. Records the method being followed, the phase list, and a
current-stage marker. Every phase transition rewrites the marker *before* the
phase ends, so an interrupted session always resumes from a truthful stage.

### `features/<slug>.md`

Sections: purpose, scope and non-goals, the architecture (components and
their responsibilities), data and state, interfaces and contracts,
dependencies on other features, and open questions. Mid-to-high technical
level — no file-by-file plans and no real code; those are `/task-add`'s
output, produced at planning time against the codebase as it then stands.

## `FEATURES.md` — the feature index

```
# Features

---

## <slug> — <one-line title>

Status: [NEW]
Doc: .claude/domain/features/<slug>.md
Source: product-design.md § <section>
Tasks: none

---
```

| Field | Meaning |
| --- | --- |
| `<slug>` | Stable kebab-case identifier. Never renamed — the same rule that makes task IDs stable. |
| `Status:` | One of `[NEW]` / `[ITERATED]` / `[PLANNED]`. See below. |
| `Doc:` | Path to the feature document. |
| `Source:` | Where the feature came from — `product-design.md § <section>`, or the literal `prompt` when architected directly with no design documents. |
| `Tasks:` | Comma-separated task IDs generated from this feature, or `none`. |

There is no `Last feature number` counter and no numeric IDs: slugs are the
identifiers, so there is nothing to count.

## Feature status vocabulary

Feature status tracks the relationship between the design and the backlog. It
says nothing about whether the feature is *built* — that is what `TASKS.md`
is for. Keeping the two vocabularies separate is deliberate; conflating them
would turn `FEATURES.md` into a second, permanently stale backlog.

| Status | Meaning | Written by |
| --- | --- | --- |
| `[NEW]` | Architected, never planned. No tasks exist. | `/architect`, on first write |
| `[ITERATED]` | Planned, and the design has since changed. | `/architect`, when re-architecting a `[PLANNED]` feature |
| `[PLANNED]` | Tasks exist and match the current design. | `/task-add feature=<slug>` |

### Transitions

| From | To | Trigger |
| --- | --- | --- |
| `[NEW]` | `[PLANNED]` | `/task-add feature=<slug>` |
| `[ITERATED]` | `[PLANNED]` | `/task-add feature=<slug>` reconciles the backlog |
| `[PLANNED]` | `[ITERATED]` | `/architect` re-architects the feature |
| `[NEW]` | `[NEW]` | `/architect` re-architects an unplanned feature |
| `[ITERATED]` | `[ITERATED]` | `/architect` runs again before re-planning |

The two self-transitions are the common case, not an error: re-architecting
when no new tasks have been generated since changes nothing about the
design/backlog relationship.

Two transitions are illegal:

- **`[PLANNED]` → `[NEW]`.** Tasks were generated from this feature. That
  happened; it cannot be un-happened. Even if every task is later removed by
  `/task-clean`, the feature stays `[PLANNED]` — the tasks existed and were
  resolved.
- **`[NEW]` → `[ITERATED]`.** `[ITERATED]` means the backlog has drifted from
  the design. With no tasks downstream there is nothing to drift from.

### `[ITERATED]` is the actionable state

`[NEW]` and `[PLANNED]` are steady states. `[ITERATED]` means *the design
moved and the backlog has not caught up* — work is queued that may no longer
be correct. It is the one state that demands action, and it cannot be
recovered by inspecting the filesystem, which is why it is stored rather than
derived. Commands that report on features surface it prominently.

## Task-side additions

The pipeline adds two things to the task backlog. Both are invisible to
free-form tasks, which behave exactly as they always have.

### `Feature:` — the origin link

An optional line in a `TASKS.md` summary block carrying the slug of the
feature the task was generated from. Present only on feature-derived tasks;
absent on free-form ones. It lives in the summary block rather than the body
for the same reason `Status:` and `Preconditions:` do — it describes the
task's place in the backlog, not what to build.

This line is what makes reconciliation possible: without it, a re-planning
run cannot tell which existing tasks belong to the feature being re-planned.

### `[STALE]` — the drift marker

A task status meaning *the design this task was generated from has changed*.
Set by `/architect` when it re-architects the feature a task came from.

- **Not terminal.** A stale task is live work awaiting reconciliation, not
  abandoned work. `/task-clean` prunes `[DONE]` and `[SKIP]`; it never prunes
  `[STALE]`.
- **Not implementable unattended.** `chosko-llm task-impl` refuses a
  `[STALE]` task. An external LLM cannot judge whether a superseded design
  still applies, and implementing against one is worse than stopping.
- **Implementable interactively, on the user's say-so.** `/task-implement`
  warns — naming the feature and saying the design changed since the task was
  written — then lets the user implement anyway or stop. A human can make
  that call; the orchestrator cannot. The asymmetry is deliberate.
- **Resolved by reconciliation**, described below.

The status vocabulary is duplicated in shell: `scripts/check-task-parity.sh`
holds the canonical tag list and `scripts/cmd-task-impl.sh` holds the
implementable-status allowlist. Any change to the vocabulary must land in
both, or the parity guard fails.

## The iterate guard (`/architect`)

Before re-architecting a feature that already has an entry, `/architect`
reads its `Tasks:` IDs and looks each one up in `TASKS.md`:

1. **Any `[IN PROGRESS]` task → refuse.** Report the task and stop. There is
   no override: work is actively underway against the current design, and
   changing it underneath an in-flight implementation corrupts both.
2. **Any other non-`[DONE]` task → ask.** List the tasks with statuses and
   titles, state that re-architecting may invalidate them, and offer stop or
   proceed.
3. **On proceed** — flip every non-`[DONE]` task to `[STALE]` and set the
   feature `[PLANNED]` → `[ITERATED]`.
4. **No tasks at all** (`[NEW]`, or `Tasks: none`) → skip the guard entirely.
5. **IDs that resolve to no task** are ignored, not an error. `/task-clean`
   normally prunes them, but a hand-edited backlog should not break the run.

`[DONE]` tasks are never touched. Completed work stands regardless of what
the design does afterwards.

This is the only circumstance in which `/architect` writes to `TASKS.md`, and
it writes nothing but `Status:` lines — never creating, deleting, or
reordering entries.

## Reconciliation (`/task-add feature=<slug>`)

When `/task-add` plans a feature that already has tasks, it does not append
blindly — that reliably produces overlapping work. It reads the existing
tasks and classifies each one, presenting the result for approval alongside
the new drafts:

| Situation | Action |
| --- | --- |
| Still valid under the new design | Left untouched. No edit. |
| Needs minor change, and is `[STALE]` or `[MISSING]` | Body updated in place. A `[STALE]` task flips back to `[MISSING]`. |
| Substantially invalidated | Marked `[SKIP]` with a reason; a replacement task is drafted. |
| `[DONE]` | Never modified, skipped, or reopened. Follow-up work is a new task. |

Update-in-place is preferred over skip-and-replace whenever the task's goal
survives the design change: nothing has been implemented yet, so rewriting
the body is cheaper and keeps the backlog free of dead `[SKIP]` entries.
Skip-and-replace is for tasks whose goal no longer survives at all. Which of
the two applies is a judgment call about how much of the task remains — the
criteria are above; there is no mechanical rule.

The run ends with the feature at `[PLANNED]` and its `Tasks:` line listing
the surviving and newly created IDs.

## Who writes what

Exactly one writer per artifact, with `FEATURES.md` the deliberate exception.

| Artifact | Writer |
| --- | --- |
| `domain/INDEX.md` | `/domain-setup` creates it; `/product-design` and `/architect` register the docs they add |
| `design-process.md` | `/product-design` |
| `product-design.md` | `/product-design`; `/architect` writes back clarifications and architecture-driven changes |
| `technical-direction.md` | `/product-design` |
| `business-model.md` | `/product-design` |
| `features/<slug>.md` | `/architect` |
| `FEATURES.md` | `/architect` owns entries, `Status:`, `Doc:`, `Source:`. `/task-add` owns `Tasks:` and the flip to `[PLANNED]`. `/task-clean` prunes dropped IDs from `Tasks:`. |
| `TASKS.md` | `/task-add`, `/task-implement`, `/task-clean` as today; `/architect` only to flip statuses to `[STALE]` |

`FEATURES.md` is split by *line*, not by file, so its two main writers can
never contend for the same field. `/architect` never writes `Tasks:`;
`/task-add` never writes `Doc:` or `Source:`.

## Domain layer vs. context layer

The two `.claude/` knowledge layers stay separate, and the product pipeline
does not change that:

- **Context layer** (`.claude/context/`) — codebase **structure**: which
  files implement what, public APIs, internal patterns. Owned by
  `/context-build` and `/context-update`.
- **Domain layer** (`.claude/domain/`) — **product and rules**: what the
  product is, how its features are designed, why the architecture is what it
  is. Owned by humans, `/domain-setup`, `/product-design`, and `/architect`.

The rule in [context-workflow.md](./context-workflow.md) still holds without
exception: the context commands cross-reference domain files and never modify
them. What changes is only that the domain layer now has commands of its own,
where before it was hand-written and unindexed.

This file is itself a domain file — it describes a process, not a codebase
structure.

## Session resumability

`/product-design` is designed to span sessions. Its state is
`design-process.md`, not conversation history:

- The document records the phase list and a current-stage marker.
- Every phase transition rewrites that marker before the phase ends.
- A later run detects the file, reads the stage, summarizes where the last
  session stopped, and offers to resume there or start fresh.

There is no `resume` argument. Weeks can pass between sessions and a flag
would not be remembered; the document already exists and is the natural
anchor. The corollary is that the marker is load-bearing — a phase that ends
without rewriting it degrades every later resume.

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — hard rules (authoring, versioning,
  copy-not-symlink, no new deps).
- [`./task-workflow.md`](./task-workflow.md) — the backlog schema this
  pipeline feeds: `TASKS.md` summary blocks, body schemas, `Target:` values.
- [`./context-workflow.md`](./context-workflow.md) — the context layer and
  the structure/domain boundary reconciled above.
- [`../context/features.md`](../context/features.md) — shipped artifacts,
  including every command named here.
- `commands/domain-setup.md`, `commands/task-add.md`,
  `commands/task-clean.md`, `skills/product-design/SKILL.md`,
  `skills/architect/SKILL.md` — the implementations.
