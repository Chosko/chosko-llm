# Product workflow — from product idea to implementation task

Source of truth for product pipeline: commands taking product from brainstorm through architecture to implementable backlog, docs they exchange, three status vocabularies keeping design, delivery and backlog in sync. Read when touching `/domain-setup`, `/product-design`, `/product-roadmap`, `/architect`, `/production-plan`, `/production-status`, or feature-aware parts of `/task-add`, `/task-list` and `/task-clean`.

## Why this exists

`/task-add` always accepted free-form description, produced task. Works when user already knows what to build. Doesn't cover step before: deciding what product is, which features it has, how they should be built. Three commands fill gap, each hands output to next as document not conversation — work survives across sessions, machines, people.

Pipeline exists to make handoff explicit. Cost: set of files must agree on schema; this doc is what they agree on.

## The pipeline

| Stage | Command | Consumes | Produces |
| --- | --- | --- | --- |
| 0 — scaffold | `/domain-setup` | nothing | domain layer + empty `FEATURES.md` |
| 1 — design | `/product-design` | user, repo when brownfield | `product-design.md`, `technical-direction.md`, optional `business-model.md`, `design-process.md` |
| 2 — roadmap | `/product-roadmap` | user, `product-design.md` when present (optional), existing roadmap as its own resume state, `FEATURES.md` read-only | `product-roadmap.md` + its domain `INDEX.md` row |
| 3 — architect | `/architect` | high-level feature, or bare prompt, plus `technical-direction.md` when exists, plus `product-roadmap.md` slice when target section sliced | `features/<slug>.md` + `FEATURES.md` entry |
| 4 — sequence | `/production-plan` | `FEATURES.md` (slugs, `Status:`, `Source:`, `Tasks:`), each feature doc's `## Dependencies`, `product-roadmap.md` when present (optional), `TASKS.md` for `[SHIPPED]` proposal — all read-only | `PLAN.md` |
| 5 — plan | `/task-add feature=<slug>` | feature doc | task bodies + `TASKS.md` entries |
| 6 — build | `/task-implement` | task body | code |
| read | `/production-status` | `PLAN.md`, `FEATURES.md`, `TASKS.md`, `product-roadmap.md` — all read-only | terminal output only; **nothing written** |

Last row is not a stage — nothing hands to it, it hands to nothing. It's the read side, spanning the whole pipeline; see [The read stage](#the-read-stage-production-status) below.

Stages entered, not marched through. Project w/ existing codebase commonly starts stage 0 then jumps stage 3; project whose next change obvious skips to stage 5 w/ free-form description, same as today. Nothing downstream requires upstream stage ever ran.

Stages 1 and 3 can optionally route a genuine decision fork through
claude-council before recommending — see [The council gate](#the-council-gate-optional)
below. It changes nothing when the skill isn't installed.

## Artifacts

```
.claude/
  TASKS.md                        the task backlog index
  FEATURES.md                     the feature index (sibling of TASKS.md)
  PLAN.md                         the production plan (third index beside the other two)
  tasks/<N>.md                    one body per task
  domain/
    INDEX.md                      the domain-layer index
    design-process.md             resumable state of a /product-design run
    product-design.md             high-level product design
    product-roadmap.md            the ordered milestones and their scope slices
    technical-direction.md        the product's technical foundations
    business-model.md             business model (only when requested)
    features/<slug>.md            one doc per low-level feature
```

`FEATURES.md` sits at `.claude/` root not inside `domain/` — indexes work items, like `TASKS.md`. Feature *documents* it points at: knowledge, live in domain layer. `PLAN.md` sits there for same reason: indexes work items, knowledge it indexes lives in domain layer.

### `product-design.md`

Sections: product summary, target users, UX and key flows, big design decisions, high-level feature set. Documentational register — WHAT and, some, HOW. Rationale belongs in conversation and `design-process.md`, not here.

### `product-roadmap.md`

Preamble w/ a `Strategy:` paragraph — the premise the whole order rests on, global where `Rationale:` is local; labelled so a revision can locate it, and read as input on every revision, never rewritten to agree w/ a newly-decided order. Then ordered milestone blocks keyed by stable kebab-case slug (`m1-mvp`), each carrying `Goal:` (an outcome, not a feature list), `Exit criteria:`, `Rationale:`, `Covers:`; then `Not now` (each deferral w/ trigger pulling it back in) and `Open sequencing questions`. Order is list position — slug carries none, so milestone inserted between two others needs no renumber. `Covers:` entries name `product-design.md` sections, never `FEATURES.md` slugs, each w/ prose scope statement whose payload is its exclusions; slice identity is `(milestone, section)` pair. `Covers:` is decomposition instruction for `/architect`, not delivery claim — partial coverage of section across milestones normal, nothing validates completeness. No `Status:` line, no dates, no estimates: milestone state is not the roadmap's, same intent/state split keeping feature statuses out of `product-design.md`. Document is also `/product-roadmap`'s resume state — no marker file.

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
Source: product-design.md § <section>[ (<milestone-slug>)]
Tasks: none

---
```

| Field | Meaning |
| --- | --- |
| `<slug>` | Stable kebab-case identifier. Never renamed — same rule as task IDs stable. |
| `Status:` | One of `[NEW]` / `[ITERATED]` / `[PLANNED]`. See below. |
| `Doc:` | Path to feature document. |
| `Source:` | Where feature came from — `product-design.md § <section>`, or literal `prompt` when architected directly, no design docs. Optional ` (<milestone-slug>)` suffix when feature came from roadmap scope slice: `Source: product-design.md § Authentication (m1-mvp)`. Absent on traditional-mode and `prompt` features — backward compatible, readers ignoring suffix keep working. Sole mechanism by which low-level feature knows its milestone. |
| `Tasks:` | Comma-separated task IDs generated from feature, or `none`. |

No `Last feature number` counter, no numeric IDs: slugs are identifiers, nothing to count.

## Feature status vocabulary

Feature status tracks relationship between design and backlog. Says nothing whether feature *built* — that's `TASKS.md`'s job. Two vocabularies kept separate deliberately; conflating turns `FEATURES.md` into second, permanently stale backlog.

| Status | Meaning | Written by |
| --- | --- | --- |
| `[NEW]` | Architected, never planned. No tasks exist. | `/architect`, on first write |
| `[ITERATED]` | Planned, design since changed. | `/architect`, when re-architecting `[PLANNED]` or `[DONE]` feature |
| `[PLANNED]` | Tasks exist, match current design. | `/task-add feature=<slug>` |
| `[DONE]` | Every task is `[DONE]` or `[SKIP]`; nothing left to build against the current design. | User, by hand — or `/task-implement`, proposed at the end of a run and only on the user's confirmation. See [task-workflow.md § `[DONE]` feature-completion proposal](./task-workflow.md#done-feature-completion-proposal). |

### Transitions

| From | To | Trigger |
| --- | --- | --- |
| `[NEW]` | `[PLANNED]` | `/task-add feature=<slug>` |
| `[ITERATED]` | `[PLANNED]` | `/task-add feature=<slug>` reconciles backlog |
| `[PLANNED]` | `[ITERATED]` | `/architect` re-architects feature |
| `[PLANNED]` | `[DONE]` | `/task-implement` proposes it (last task of the feature lands `[DONE]`/`[SKIP]`), user confirms — or a human flips it by hand |
| `[DONE]` | `[ITERATED]` | `/architect` re-architects a completed feature |
| `[NEW]` | `[NEW]` | `/architect` re-architects unplanned feature |
| `[ITERATED]` | `[ITERATED]` | `/architect` runs again before re-planning |

Two self-transitions: common case not error. Re-architecting when no new tasks generated since — changes nothing about design/backlog relationship.

Transitions illegal:

- **`[PLANNED]` or `[DONE]` → `[NEW]`.** Tasks generated from feature. Happened, can't un-happen. Even if every task later removed by `/task-clean`, feature stays `[PLANNED]` (or `[DONE]`) — tasks existed, resolved.
- **`[NEW]` → `[ITERATED]`.** `[ITERATED]` means backlog drifted from design. No tasks downstream, nothing to drift from.
- **`[DONE]` → `[PLANNED]`.** `[DONE]` doesn't reopen on its own — reopening happens only by moving through `[ITERATED]` (re-architecting) or by a human editing the file directly. `/task-add feature=<slug>` never targets a `[DONE]` feature: with no `[STALE]`/`[MISSING]` tasks and nothing `[ITERATED]`, there is nothing left for it to reconcile.

### `[ITERATED]` is the actionable state

`[NEW]`, `[PLANNED]`, `[DONE]`: steady states. `[ITERATED]` means *design moved, backlog hasn't caught up* — work queued may no longer be correct. One state demanding action, can't recover by inspecting filesystem — why stored not derived. Commands reporting features surface it prominently.

### `[DONE]` is proposed, never applied silently

Same discipline as `PLAN.md`'s `[SHIPPED]`: a status this consequential is never flipped without the user in the loop. `/task-implement` is the only command that proposes it, and only at the point defined in [task-workflow.md § `[DONE]` feature-completion proposal](./task-workflow.md#done-feature-completion-proposal) — never mid-run, never without asking. A human can flip a feature to `[DONE]` by hand at any time regardless of `/task-implement`; the skill never overwrites a status a human already set, and never treats a hand-set `[DONE]` as something to second-guess.

## `PLAN.md` — the production plan

Third index at `.claude/` root, beside `TASKS.md` and `FEATURES.md`. Written by `/production-plan` and by nothing else. Answers what `FEATURES.md` can't: which low-level feature belongs to which milestone, in what order, and after what.

```
# Plan

Roadmap: .claude/domain/product-roadmap.md
Last reconciled: <YYYY-MM-DD>

---

## <milestone-slug> — <milestone title>

Status: [PLANNED]
Covers: product-design.md § <Section>, product-design.md § <Section>
Features: <slug>, <slug>, <slug>

---

## Unscheduled

Features: <slug>, <slug>

## Dependencies

- <slug>: depends on <slug>, <slug>
```

- **`Roadmap:`** names roadmap plan was built against, or literal `none`. **`Last reconciled:`** informational only — nothing computes from it; real staleness signal is `FEATURES.md` slug missing from plan.
- **`Features:` is ordered and order IS the priority.** No `P0`/`P1` label, no dates, estimates, sizes, percentages: second ordering beside ordered list eventually contradicts it. Empty milestone carries `Features: none` — coverage gap meaning `/architect` hasn't run its slices yet, warning not error.
- **`Covers:` derived**, rewritten every run from roadmap's own `Covers:` lines (section names only; scope prose stays in roadmap), so it can't drift and hand edits to it don't survive. Omitted entirely where no roadmap.
- **`Unscheduled`** block carries `Features:` only — no `Status:`, no `Covers:` — and is written even when empty, so schema is uniform.
- **`## Dependencies` is ONE flat edge list** at foot of document, not `Depends:` line per feature. Two reasons: keeps `PLAN.md` from becoming second index keyed by feature slug, and puts every edge in one place where cycle is visible to human reader.
- Milestones appear in **roadmap order** (list position, never slug). Milestone the roadmap no longer lists is kept where it sits, flagged, `Covers:` dropped — nothing left to derive it from.
- **Nothing derivable is stored.** Readiness, coverage and per-feature task rollups computed at read time, never persisted.

Feature's milestone is **inherited by lookup**, not inference: the ` (<milestone-slug>)` parenthetical on its `FEATURES.md` `Source:` line, written by `/architect` in slice mode. No parenthetical, or `Source: prompt` → `Unscheduled`. Explicit placement overrides the parenthetical, is reported plainly at approval gate, never gated or refused — roadmap makes no completeness claim for it to violate.

Dependency **edges**: feature documents propose, `PLAN.md` records. Skill reads each document's `## Dependencies` prose, proposes edge set machine-readably, user confirms, plan stores it. **Prose is never rewritten** — it stays human-facing statement, edge list is its parsable projection, and drift is resolved by re-running the skill, same reconciliation pattern `/task-add feature=<slug>` uses. Storing confirmed edges is exactly what allows an edge the documents never stated. Only feature-to-feature edges: task-level ordering is `Preconditions:`, untouched.

Two invariants **refuse rather than warn**, both validated before any write, neither with an override flag: a **cycle** (reported as the actual cycle path) and a **dependency in a later milestone** (reported with both features and both milestones). Within a milestone, `Features:` must be topological order of edges restricted to it. Dependency on an `Unscheduled` feature is a *warning*, not that refusal — `Unscheduled` has no position, so it can't be "later".

## Milestone status vocabulary

Third status vocabulary in pipeline, deliberately small. Lives in `PLAN.md`, not the roadmap: roadmap holds intent, this index holds state — same split as `product-design.md` versus `FEATURES.md`, and it keeps one writer per artifact.

| Status | Meaning | Written by |
| --- | --- | --- |
| `[PLANNED]` | Scheduled, not started. | `/production-plan`, on first write |
| `[ACTIVE]` | Being built now. **At most one milestone at a time.** | `/production-plan`, on user's say-so |
| `[SHIPPED]` | Delivered. **Terminal.** | `/production-plan`, only on user confirmation |

`[SHIPPED]` is *proposed* only when every feature in the milestone is `[DONE]`, or `[PLANNED]` in `FEATURES.md` **and** all its tasks are `[DONE]` or `[SKIP]` in `TASKS.md` — a `[PLANNED]` feature meeting that bar and a `[DONE]` feature describe the same backlog state, one recorded on `FEATURES.md`, the other not yet — and always confirmed by user rather than applied automatically. **It can never reopen**: follow-up work is always a new milestone, same discipline making `[DONE]` terminal for tasks and `[PLANNED]` → `[NEW]` illegal for features. More than one `[ACTIVE]` → reported, user asked which is meant; never picked automatically.

Three vocabularies, three jobs, kept separate on purpose: **feature** status says whether backlog matches design, **task** status says whether work is done, **milestone** status says whether it shipped. Conflating any two turns one index into second, permanently stale copy of another.

## Reconciliation (`/production-plan`)

Re-run diffs plan against current `FEATURES.md` and roadmap, presents everything behind **one approval gate**, matching `/task-add`'s single-gate convention. Starts from existing plan and proposes a diff, never a blank page — rebuilding from scratch would throw away the two things only the plan holds: orderings inside each milestone, and confirmed edges the feature documents don't state.

| Situation | Action |
| --- | --- |
| Feature in `FEATURES.md`, absent from plan | Proposed for placement — its `Source:` milestone, or `Unscheduled`. This is the plan's real staleness signal. |
| Slug in plan, gone from `FEATURES.md` | Reported and dropped, with every edge naming it. Hand-deleted feature must not break run or leave edge pointing at nothing. |
| Feature is `[ITERATED]` | Its document's dependencies re-read, edge **diff** proposed — never wholesale replacement, which would delete a stored edge the docs never stated. |
| Milestone in roadmap, absent from plan | Added, at its roadmap position, `[PLANNED]`, `Features: none`. |
| Milestone in plan, gone from roadmap | Reported, kept and flagged — hand edits tolerated, not silently reverted. |

Reconciliation never writes anything but `PLAN.md`, never re-derives an ordering the user set, never resets a milestone `Status:`, and adds no second gate. Validation runs on reconciled proposal exactly as on first run: plan valid yesterday can be invalid today because a milestone moved.

Deliberately NOT plan-aware, deferred by the feature's open questions: `/task-add feature=<slug>` does not warn on unsatisfied dependencies, `/task-implement` and `chosko-llm task-impl` do not honour plan order, and no bash script parses `PLAN.md`.

## The read stage (`/production-status`)

A plan nobody reads changes no decisions. `PLAN.md` holds milestones, order and edges; `FEATURES.md` holds each feature's design/backlog state; `TASKS.md` holds the work. **The useful answer lives in the join of all three and in none of them alone** — a feature is workable when it's in the active milestone, its dependencies are finished, and its tasks exist. `/production-status` computes that join and reports it.

Command, not skill: thin read-only reporter, no conversation, no supporting files — the register `/task-list` occupies. **Writes nothing**: no status flips, no reordering, no commit, no cached answer, no shell command of any kind. Never opens a file under `.claude/tasks/` — `TASKS.md` carries everything. Every writer in this layer is `/production-plan`.

Eight output sections in fixed order: (1) the milestone — slug, title, `Status:`, plus `Goal:` and `Exit criteria:` echoed verbatim from the roadmap; (2) its features in plan order, each w/ `FEATURES.md` status, task rollup and readiness; (3) the ready set; (4) the ONE recommended next feature — first ready in plan order; (5) blocked features, each named w/ what blocks it; (6) coverage gaps — milestones w/ `Features: none` (outstanding `/architect` work) and `product-design.md` sections no `Covers:` names; (7) unplanned features; (8) remaining milestones, one line each. Plan order is the report's order, because that order is the priority.

**Readiness and coverage are derived on every read, never stored.** A `[DONE]` feature has no readiness of its own computed — it's finished, not pending, so it never lands in the ready set or as the recommendation, and is reported plainly instead; it still counts as satisfying any edge a dependent points at it. For every other feature: ready when every dependency edge pointing at it originates from a feature `[DONE]`, or `[PLANNED]` in `FEATURES.md` w/ all its tasks `[DONE]` or `[SKIP]`; no edges → ready; everything else blocked, always named w/ its blocker so a blocked list is actionable rather than a dead end. A milestone whose only otherwise-ready features are all `[DONE]` reports that plainly too — nothing left to plan, pointing at `/production-plan` in case it's ready to propose `[SHIPPED]`. Deriving means it can never be wrong about a task someone just finished — and it's why `PLAN.md` stores no readiness or coverage rollup: storing derivable state creates a second thing to keep in sync. Rollup granularity: counts per status by default, `--task-ids` names each task. `milestone=<slug>` scopes to a named milestone; unknown slug stops listing available slugs, same as `/task-add feature=<slug>`.

**Staleness is structural, not temporal.** Report names every `FEATURES.md` slug missing from `PLAN.md` and points at `/production-plan`; nothing compares `Last reconciled:` against modification times or dates. A plan that has fallen behind says so by having gaps — no state this product doesn't keep.

**Failure contract is degradation, never refusal** — a read-only report must never be the thing that stops a session. No roadmap → omit goal and exit criteria. No `TASKS.md` → no rollups, every dependency-satisfied feature ready. No `[ACTIVE]` milestone → report first `[PLANNED]`, say none is active. Edge naming an unknown slug → report the plan inconsistency and treat the feature as ready, **failing open**: a hand-edited plan must not make the report claim there is nothing to do. Only stops: no `PLAN.md` (point at `/production-plan`) and an unknown `milestone=`.

**It reports work, never selects or starts it.** Naming the next ready feature is where the command ends; `/task-add feature=<slug>` and `/task-implement` are how work begins.

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

## Slice-aware resolution (`/architect`)

`/architect` has two input-resolution modes, in two on-demand supporting files: `skills/architect/sectioned-input.md` (traditional — target matched against `product-design.md` sections and existing `FEATURES.md` slugs) and `skills/architect/sliced-input.md` (slice mode). Project w/ no roadmap behaves exactly as before.

- **Activation probe:** `.claude/domain/product-roadmap.md` present, carrying at least one milestone w/ `Covers:` line. Whole of the configuration — no flag file, no settings key, no frontmatter switch.
- **Dispatch per target, not per run.** Roadmap slicing `§ Authentication` may say nothing about `§ Config export`; each target resolves independently, so unsliced section takes traditional path even on roadmapped project. Makes adoption incremental.
- **Resolution:** find every slice whose section matches target; one match → architect it; several across different milestones → ask which, listing each w/ milestone and scope statement. User may name milestone in invocation to skip question. Union of several slices never architected, milestone never guessed.
- **Slice scope statement is a boundary.** Its exclusions become the feature document's non-goals — section already in template, only source of content new.
- **Milestone recorded in `Source:`** as the optional parenthetical, above.
- **`--no-slices`** forces traditional mode on roadmapped project; silent no-op where no roadmap. Per run, not per target — unsliced sections already fall back on their own.
- **Failure contract:** no roadmap or no `Covers:` line → traditional mode, silently (normal state of most projects, not a warning); roadmap present but target section unsliced → traditional mode for that target, stated in one line; slice whose section absent from `product-design.md` → architect anyway, warn once, matching `/product-roadmap` warning rather than refusing on same condition.

`PLAN.md` never read here, `product-roadmap.md` never written. Everything else in `/architect` — gate, iterate guard, clarify, architecture conversation, write rules, commit protocol — untouched by slice mode.

## The iterate guard (`/architect`)

Before re-architecting feature already having entry, `/architect` reads its `Tasks:` IDs, looks each up in `TASKS.md`:

1. **Any `[IN PROGRESS]` task → refuse.** Report task, stop. No override: work actively underway against current design, changing it underneath in-flight implementation corrupts both.
2. **Any other non-`[DONE]` task → ask.** List tasks w/ statuses and titles, state re-architecting may invalidate them, offer stop or proceed.
3. **On proceed** — flip every non-`[DONE]` task to `[STALE]`, set feature status to `[ITERATED]` (from `[PLANNED]` or `[DONE]`).
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

Documents owned by another command in pipeline — `.claude/domain/features/<slug>.md` (`/architect`) and `product-design.md` / `technical-direction.md` / `business-model.md` (`/product-design`) — MAY appear in doc task's Hints. Not illegal move: feature changing its own design surface routinely needs document brought back in line w/ what shipped. Illegal move is doing it silently — `/task-add` names file and its owner at PHASE 3 gate, where user can strike it, and never writes owned document into task user wasn't told about. Ownership still means one writer per artifact for the *pipeline commands*: `/task-add` itself never edits these files.

## Who writes what

Exactly one writer per artifact, `FEATURES.md` deliberate exception.

| Artifact | Writer |
| --- | --- |
| `domain/INDEX.md` | `/domain-setup` creates it; `/product-design` and `/architect` register docs they add |
| `design-process.md` | `/product-design` |
| `product-design.md` | `/product-design`; `/architect` writes back clarifications, architecture-driven changes |
| `product-roadmap.md` | `/product-roadmap`, only writer. Reads `product-design.md` and `FEATURES.md`, writes neither. `/architect` reads it to resolve slices, never writes it — wrong slice fixed by re-running `/product-roadmap`. |
| `technical-direction.md` | `/product-design` owns it. `/architect` reads it, adopts as established stack when present, treats exactly as existing codebase stack — skipping tech-stack selection, referencing from feature documents rather than restating, never writing to it. |
| `business-model.md` | `/product-design` |
| `features/<slug>.md` | `/architect` |
| `FEATURES.md` | `/architect` owns entries, `Status:`, `Doc:`, `Source:` — including `Source:`'s optional milestone suffix, no new writer. `/task-add` owns `Tasks:`, flip to `[PLANNED]`. `/task-clean` prunes dropped IDs from `Tasks:`. `/task-implement` may flip a `[PLANNED]` feature to `[DONE]`, and only that transition, and only on the user's confirmation. A human may also flip `Status:` to `[DONE]` directly by hand at any time — the one field on this file with no single command owner. |
| `PLAN.md` | `/production-plan`, sole writer, and the only file it writes. Reads `FEATURES.md`, feature documents, `product-roadmap.md` and `TASKS.md` strictly read-only — a problem it spots in any of them is reported, never fixed there. Its only *readers* are `/production-status` and `/task-list`; no other command in the pipeline reads it, and nothing but `/production-plan` writes it. |
| `TASKS.md` | `/task-add`, `/task-implement`, `/task-clean` as today; `/architect` only to flip statuses to `[STALE]` |
| `council-report-*.html`, `council-transcript-*.md` | claude-council, when the council gate is convened. Owned by **neither** skill: never added to `WRITTEN`, never staged by `--commit`, never deleted. Both stages name their paths in the closing report and leave them in the working tree for the user to keep or delete. |

`FEATURES.md` split by *line*, not file, so two main writers never contend for same field. `/architect` never writes `Tasks:`; `/task-add` never writes `Doc:` or `Source:`.

## The council gate (optional)

Stages 1 and 3 can pressure-test a genuine decision fork through
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
| 3 — `/architect` | PHASE 2a stack choice, PHASE 2b architecture shape, PHASE 2b low-level split | `skills/architect/council-gate.md` |

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
   architecture (stage 3) and still says when PHASE 6 ends (stage 1). A
   confident verdict is not a go-ahead.
3. **Dissent survives.** The minority ledger lands in the feature document's
   Open questions (stage 3) or `product-design.md`'s design decisions
   (stage 1) — a live concern to revisit, never flattened into the verdict.

The gate is invoked with no mode argument, leaving claude-council's own
Quick/Standard/Deep selection and its low-confidence escalation intact.

The two `council-gate.md` files are near-identical and must be kept in step;
[docs/authoring-guide.md](../../docs/authoring-guide.md) explains why the
duplication is forced by the install model and lists the two intended
divergences.

## Commit and push

`/production-status` runs no git command at all and has no `--commit` — it is a reporter, not an author, and has nothing to commit.

`/domain-setup`, `/product-design`, `/product-roadmap`, `/architect`, `/production-plan`: all authoring commands/skills — uncommitted by default, `--commit` opts in. When `--commit` passed, all five follow commit-and-push protocol in [docs/authoring-guide.md](../../docs/authoring-guide.md) — pull at start, commit, re-sync, push — not plain `git commit`. `--no-push` (only meaningful alongside `--commit`) skips sync/push cycle, commits locally only. Algorithm not re-derived here; see that doc.

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
- `commands/domain-setup.md`, `commands/task-add.md`, `commands/task-clean.md`, `commands/task-list.md`, `commands/production-status.md`, `skills/product-design/SKILL.md`, `skills/product-roadmap/SKILL.md`, `skills/architect/SKILL.md`, `skills/production-plan/SKILL.md` — the implementations.