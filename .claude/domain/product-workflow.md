# Product workflow — from product idea to implementation task

Source of truth for product pipeline: commands taking product from brainstorm through architecture to implementable backlog, docs they exchange, two status vocabularies keeping design and backlog in sync. Read when touching `/domain-setup`, `/product-design`, `/architect`, or feature-aware parts of `/task-add` and `/task-clean`.

## Why this exists

`/task-add` always accepted free-form description, produced task. Works when user already knows what to build. Doesn't cover step before: deciding what product is, which features it has, how they should be built. Three commands fill gap, each hands output to next as document not conversation — work survives across sessions, machines, people.

Pipeline exists to make handoff explicit. Cost: set of files must agree on schema; this doc is what they agree on.

## The pipeline

| Stage | Command | Consumes | Produces |
| --- | --- | --- | --- |
| 0 — scaffold | `/domain-setup` | nothing | domain layer + empty `FEATURES.md` |
| 1 — design | `/product-design` | user, repo when brownfield | `product-design.md`, `technical-direction.md`, optional `business-model.md`, `design-process.md` |
| 2 — architect | `/architect` | high-level feature, or bare prompt, plus `technical-direction.md` when exists | `features/<slug>.md` + `FEATURES.md` entry |
| 3 — plan | `/task-add feature=<slug>` | feature doc | task bodies + `TASKS.md` entries |
| 4 — build | `/task-implement` | task body | code |

Stages entered, not marched through. Project w/ existing codebase commonly starts stage 0 then jumps stage 2; project whose next change obvious skips to stage 3 w/ free-form description, same as today. Nothing downstream requires upstream stage ever ran.

Stages 1 and 2 can optionally route a genuine decision fork through
claude-council before recommending — see [The council gate](#the-council-gate-optional)
below. It changes nothing when the skill isn't installed.

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

`FEATURES.md` sits at `.claude/` root not inside `domain/` — indexes work items, like `TASKS.md`. Feature *documents* it points at: knowledge, live in domain layer.

### `product-design.md`

Sections: product summary, target users, UX and key flows, big design decisions, high-level feature set. Documentational register — WHAT and, some, HOW. Rationale belongs in conversation and `design-process.md`, not here.

### `technical-direction.md`

Sections: stack, topology/architecture, data and storage, async/queueing, hosting and deployment, inter-component protocols, cross-cutting concerns, explicitly-open decisions. Unconditional — stubbed alongside `product-design.md` PHASE 1, always filled PHASE 7, every product has technical foundations. Standing constraint `/architect` designs within: when present, treated as existing stack, `/architect`'s PHASE 2a tech-stack selection skipped.

### `business-model.md`

Sections: revenue model, cost structure, target segments, pricing, go-to-market, unit economics, risks. Optional — created only when user asks for business modelling, keeps pipeline usable for internal tools and side projects.

### `design-process.md`

State file. Records method being followed, phase list, current-stage marker. Every phase transition rewrites marker *before* phase ends — interrupted session always resumes from truthful stage.

### `features/<slug>.md`

Sections: purpose, scope and non-goals, architecture (components + responsibilities), data and state, interfaces and contracts, dependencies on other features, open questions. Mid-to-high technical level — no file-by-file plans, no real code; that's `/task-add`'s output, produced at planning time against codebase as it then stands.

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
| `<slug>` | Stable kebab-case identifier. Never renamed — same rule as task IDs stable. |
| `Status:` | One of `[NEW]` / `[ITERATED]` / `[PLANNED]`. See below. |
| `Doc:` | Path to feature document. |
| `Source:` | Where feature came from — `product-design.md § <section>`, or literal `prompt` when architected directly, no design docs. |
| `Tasks:` | Comma-separated task IDs generated from feature, or `none`. |

No `Last feature number` counter, no numeric IDs: slugs are identifiers, nothing to count.

## Feature status vocabulary

Feature status tracks relationship between design and backlog. Says nothing whether feature *built* — that's `TASKS.md`'s job. Two vocabularies kept separate deliberately; conflating turns `FEATURES.md` into second, permanently stale backlog.

| Status | Meaning | Written by |
| --- | --- | --- |
| `[NEW]` | Architected, never planned. No tasks exist. | `/architect`, on first write |
| `[ITERATED]` | Planned, design since changed. | `/architect`, when re-architecting `[PLANNED]` feature |
| `[PLANNED]` | Tasks exist, match current design. | `/task-add feature=<slug>` |

### Transitions

| From | To | Trigger |
| --- | --- | --- |
| `[NEW]` | `[PLANNED]` | `/task-add feature=<slug>` |
| `[ITERATED]` | `[PLANNED]` | `/task-add feature=<slug>` reconciles backlog |
| `[PLANNED]` | `[ITERATED]` | `/architect` re-architects feature |
| `[NEW]` | `[NEW]` | `/architect` re-architects unplanned feature |
| `[ITERATED]` | `[ITERATED]` | `/architect` runs again before re-planning |

Two self-transitions: common case not error. Re-architecting when no new tasks generated since — changes nothing about design/backlog relationship.

Two transitions illegal:

- **`[PLANNED]` → `[NEW]`.** Tasks generated from feature. Happened, can't un-happen. Even if every task later removed by `/task-clean`, feature stays `[PLANNED]` — tasks existed, resolved.
- **`[NEW]` → `[ITERATED]`.** `[ITERATED]` means backlog drifted from design. No tasks downstream, nothing to drift from.

### `[ITERATED]` is the actionable state

`[NEW]`, `[PLANNED]`: steady states. `[ITERATED]` means *design moved, backlog hasn't caught up* — work queued may no longer be correct. One state demanding action, can't recover by inspecting filesystem — why stored not derived. Commands reporting features surface it prominently.

## Task-side additions

Pipeline adds two things to task backlog. Both invisible to free-form tasks — behave exactly as always.

### `Feature:` — the origin link

Optional line in `TASKS.md` summary block carrying slug of feature task generated from. Present only on feature-derived tasks; absent on free-form. Lives in summary block, not body — same reason `Status:` and `Preconditions:` do: describes task's place in backlog, not what to build.

This line makes reconciliation possible: without it, re-planning run can't tell which existing tasks belong to feature being re-planned.

### `[STALE]` — the drift marker

Task status meaning *design this task generated from has changed*. Set by `/architect` when re-architecting feature task came from.

- **Not terminal.** Stale task: live work awaiting reconciliation, not abandoned. `/task-clean` prunes `[DONE]`, `[SKIP]`; never prunes `[STALE]`.
- **Not implementable unattended.** `chosko-llm task-impl` refuses `[STALE]` task. External LLM can't judge whether superseded design still applies, implementing against one worse than stopping.
- **Implementable interactively, on user's say-so.** `/task-implement` warns — names feature, says design changed since task written — then lets user implement anyway or stop. Human can make that call; orchestrator can't. Asymmetry deliberate.
- **Resolved by reconciliation**, below.

Status vocabulary duplicated in shell: `scripts/check-task-parity.sh` holds canonical tag list, `scripts/cmd-task-impl.sh` holds implementable-status allowlist. Any vocabulary change must land in both, or parity guard fails.

## The iterate guard (`/architect`)

Before re-architecting feature already having entry, `/architect` reads its `Tasks:` IDs, looks each up in `TASKS.md`:

1. **Any `[IN PROGRESS]` task → refuse.** Report task, stop. No override: work actively underway against current design, changing it underneath in-flight implementation corrupts both.
2. **Any other non-`[DONE]` task → ask.** List tasks w/ statuses and titles, state re-architecting may invalidate them, offer stop or proceed.
3. **On proceed** — flip every non-`[DONE]` task to `[STALE]`, set feature `[PLANNED]` → `[ITERATED]`.
4. **No tasks at all** (`[NEW]`, or `Tasks: none`) → skip guard entirely.
5. **IDs resolving to no task** ignored, not error. `/task-clean` normally prunes them, but hand-edited backlog shouldn't break run.

`[DONE]` tasks never touched. Completed work stands regardless what design does afterwards.

Only circumstance `/architect` writes to `TASKS.md` — writes nothing but `Status:` lines, never creating, deleting, reordering entries.

## Reconciliation (`/task-add feature=<slug>`)

When `/task-add` plans feature already having tasks, doesn't append blindly — reliably produces overlapping work. Reads existing tasks, classifies each, presents result for approval alongside new drafts:

| Situation | Action |
| --- | --- |
| Still valid under new design | Left untouched. No edit. |
| Needs minor change, `[STALE]` or `[MISSING]` | Body updated in place. `[STALE]` task flips back to `[MISSING]`. |
| Substantially invalidated | Marked `[SKIP]` w/ reason; replacement task drafted. |
| `[DONE]` | Never modified, skipped, reopened. Follow-up work: new task. |

Update-in-place preferred over skip-and-replace whenever task's goal survives design change: nothing implemented yet, rewriting body cheaper, keeps backlog free of dead `[SKIP]` entries. Skip-and-replace for tasks whose goal no longer survives at all. Which applies: judgment call how much task remains — criteria above, no mechanical rule.

Run ends w/ feature at `[PLANNED]`, `Tasks:` line listing surviving and newly created IDs.

## Documentation task

When `feature=<slug>` run drafts at least one new task (plain or part of reconciliation), `/task-add` appends one more: `Target: claude` task titled "Update documentation for feature `<slug>`", w/ `Preconditions:` naming every other new task from run — signalling should land once they have. Hints drawn from whichever of README.md, `docs/authoring-guide.md`, relevant `.claude/domain/*.md` files, `.claude/context/features.md`, `.claude/context/INDEX.md` actually describe behavior run's tasks change. Reconciliation-only run creating no new tasks gets no documentation task — nothing new to document.

Documents owned by another command in pipeline — `.claude/domain/features/<slug>.md` (`/architect`) and `product-design.md` / `technical-direction.md` / `business-model.md` (`/product-design`) — never added to doc task's Hints silently; `/task-add` asks explicit confirmation first, defaults to leaving them out, since otherwise stay read-only outside owning command.

## Who writes what

Exactly one writer per artifact, `FEATURES.md` deliberate exception.

| Artifact | Writer |
| --- | --- |
| `domain/INDEX.md` | `/domain-setup` creates it; `/product-design` and `/architect` register docs they add |
| `design-process.md` | `/product-design` |
| `product-design.md` | `/product-design`; `/architect` writes back clarifications, architecture-driven changes |
| `technical-direction.md` | `/product-design` owns it. `/architect` reads it, adopts as established stack when present, treats exactly as existing codebase stack — skipping tech-stack selection, referencing from feature documents rather than restating, never writing to it. |
| `business-model.md` | `/product-design` |
| `features/<slug>.md` | `/architect` |
| `FEATURES.md` | `/architect` owns entries, `Status:`, `Doc:`, `Source:`. `/task-add` owns `Tasks:`, flip to `[PLANNED]`. `/task-clean` prunes dropped IDs from `Tasks:`. |
| `TASKS.md` | `/task-add`, `/task-implement`, `/task-clean` as today; `/architect` only to flip statuses to `[STALE]` |
| `council-report-*.html`, `council-transcript-*.md` | claude-council, when the council gate is convened. Owned by **neither** skill: never added to `WRITTEN`, never staged by `--commit`, never deleted. Both stages name their paths in the closing report and leave them in the working tree for the user to keep or delete. |

`FEATURES.md` split by *line*, not file, so two main writers never contend for same field. `/architect` never writes `Tasks:`; `/task-add` never writes `Doc:` or `Source:`.

## The council gate (optional)

Stages 1 and 2 can pressure-test a genuine decision fork through
[claude-council](https://github.com/TorpedoD/claude-council), a separately
installed skill that runs a decision through five thinking lenses, peer-reviews
them anonymously, forces an adversarial debate when consensus looks
artificially clean, and synthesises a verdict preserving minority dissent.

**It is optional delegation, not a dependency.** The pipeline detects the skill
at `${CLAUDE_HOME:-$HOME/.claude}/skills/claude-council/SKILL.md`. When it is
absent, both stages proceed with their inline propose-and-recommend flow and
say nothing — an authoring run must not advertise an uninstalled optional
dependency mid-flight. Nothing here reimplements the framework, so this repo's
"no new dependencies" rule is untouched: claude-council's own `jq` requirement
stays on claude-council's side of the line.

Where it fires:

| Stage | Fork | Gated by |
| --- | --- | --- |
| 1 — `/product-design` | PHASE 6 technical foundations, **greenfield only** | `skills/product-design/council-gate.md` |
| 2 — `/architect` | PHASE 2a stack choice, PHASE 2b architecture shape, PHASE 2b low-level split | `skills/architect/council-gate.md` |

PHASE 6 is deliberately the higher-leverage of the two: `technical-direction.md`
becomes a standing constraint that `/architect` adopts rather than re-argues, so
an unexamined choice there propagates into every feature document downstream.
Its brownfield branch is excluded — confirm-and-record over an existing stack is
not a fork.

Three invariants hold at both gates:

1. **Triage precedes the offer.** A missing fact is a clarification question,
   not a council question; a fork already settled by an existing stack or a
   present `technical-direction.md` is not a fork at all.
2. **The council informs, never decides.** The user still confirms the
   architecture (stage 2) and still says when PHASE 6 ends (stage 1). A
   confident verdict is not a go-ahead.
3. **Dissent survives.** The minority ledger lands in the feature document's
   Open questions (stage 2) or `product-design.md`'s design decisions
   (stage 1) — a live concern to revisit, never flattened into the verdict.

The gate is invoked with no mode argument, leaving claude-council's own
Quick/Standard/Deep selection and its low-confidence escalation intact.

The two `council-gate.md` files are near-identical and must be kept in step;
[docs/authoring-guide.md](../../docs/authoring-guide.md) explains why the
duplication is forced by the install model and lists the two intended
divergences.

## Commit and push

`/domain-setup`, `/product-design`, `/architect`: all authoring commands/skills — uncommitted by default, `--commit` opts in. When `--commit` passed, all three follow commit-and-push protocol in [docs/authoring-guide.md](../../docs/authoring-guide.md) — pull at start, commit, re-sync, push — not plain `git commit`. `--no-push` (only meaningful alongside `--commit`) skips sync/push cycle, commits locally only. Algorithm not re-derived here; see that doc.

## Domain layer vs. context layer

Two `.claude/` knowledge layers stay separate, product pipeline doesn't change that:

- **Context layer** (`.claude/context/`) — codebase **structure**: which files implement what, public APIs, internal patterns. Owned by `/context-build`, `/context-update`.
- **Domain layer** (`.claude/domain/`) — **product and rules**: what product is, how features designed, why architecture is what it is. Owned by humans, `/domain-setup`, `/product-design`, `/architect`.

Rule in [context-workflow.md](./context-workflow.md) still holds without exception: context commands cross-reference domain files, never modify them. What changes: domain layer now has commands of its own, before hand-written and unindexed.

This file itself domain file — describes process, not codebase structure.

## Session resumability

`/product-design` designed to span sessions. State: `design-process.md`, not conversation history:

- Document records phase list, current-stage marker.
- Every phase transition rewrites marker before phase ends.
- Later run detects file, reads stage, summarizes where last session stopped, offers resume there or start fresh.

No `resume` argument. Weeks can pass between sessions, flag wouldn't be remembered; document already exists, natural anchor. Corollary: marker load-bearing — phase ending without rewriting it degrades every later resume.

**The PHASE 3 sweep.** PHASE 3 (write-back) other natural session boundary alongside PHASE 2's interview — where uncaptured detail most likely to die w/ context window. After write-back, PHASE 3 automatically re-reads `product-design.md`/`business-model.md` against PHASE 2 conversation, integrates anything documents don't cover — WHAT/HOW into `product-design.md`, business material into `business-model.md`, WHY/rationale/rejected alternatives into `design-process.md`'s "Decisions worth keeping" section. No new approval gate; existing PHASE 3 report is review surface. No-op when nothing missing.

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — hard rules (authoring, versioning, copy-not-symlink, no new deps).
- [`./task-workflow.md`](./task-workflow.md) — backlog schema this pipeline feeds: `TASKS.md` summary blocks, body schemas, `Target:` values.
- [`./context-workflow.md`](./context-workflow.md) — context layer, structure/domain boundary reconciled above.
- [`../context/features.md`](../context/features.md) — shipped artifacts, including every command named here.
- `commands/domain-setup.md`, `commands/task-add.md`, `commands/task-clean.md`, `skills/product-design/SKILL.md`, `skills/architect/SKILL.md` — the implementations.