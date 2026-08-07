---
name: production-plan
version: 0.1.0
type: skill
description: Write the production plan into .claude/PLAN.md — a third index beside TASKS.md and FEATURES.md recording which low-level feature belongs to which milestone, in what order, and after what. The feature-level WHEN of the pipeline, sitting between /architect and /task-add. Inherits each feature's milestone from the parenthetical on its FEATURES.md Source: line, turns each feature document's Dependencies prose into a confirmed edge list, and refuses the two arrangements that cannot be built — a dependency cycle, and a feature scheduled before something it needs. Re-runnable: a later run reconciles the plan against the current FEATURES.md and roadmap behind one approval gate. Requires /domain-setup; a roadmap is optional — without one every feature lands in Unscheduled and dependency ordering still works. Sole writer of PLAN.md; reads FEATURES.md, the feature documents, the roadmap and TASKS.md and writes none of them. Nothing committed by default; pass --commit to commit and push exactly what the run wrote (--commit --no-push to skip the push).
---

# /production-plan
# Global skill: decide which low-level feature belongs to which milestone, in
# what order, and after what — and write it down as `.claude/PLAN.md`, a
# third index beside `TASKS.md` and `FEATURES.md`. Sits between `/architect`
# (how each feature is built) and `/task-add` (what to build next), and
# supplies the feature-level WHEN neither of them covers.
# Usage: /production-plan                        (build or reconcile the plan)
#        /production-plan <free-form context>    (placements, orderings, what is active now)
#        /production-plan --commit               (commit and push exactly what this run wrote)
#        /production-plan --commit --no-push     (commit locally, skip the push)

GOAL
Produce **one ordered plan**. Every architected feature is placed in a
milestone or in `Unscheduled`; within a milestone the feature list is
ordered, and **that order is the priority** — there is no second priority
axis, no `P0`/`P1` label, nothing that could contradict the list.

Alongside the placement, turn the `## Dependencies` prose that every feature
document already carries into a **machine-readable edge list** the plan
stores, and refuse the two arrangements that cannot be built: a dependency
cycle, and a feature scheduled before something it needs.

The register is **feature-level scheduling, not design and not
implementation**. Nothing here decides how a feature is built (that is
`/architect`) or what its tasks are (that is `/task-add`).

Read [`.claude/domain/product-workflow.md`](../../.claude/domain/product-workflow.md)
in the target project if it has one; this skill is a stage of the pipeline
that document describes.

$ARGUMENTS

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `./reconciling.md` | PHASE 0 finds `.claude/PLAN.md` already exists. Read before PHASE 1 — it carries the five-situation re-run protocol. |

A first run — no `PLAN.md` yet — reads neither this table's file nor
anything else beyond `SKILL.md`. The `PLAN.md` schema below is needed by
every run, first or later, so it lives here rather than in a supporting file.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--commit` flag. If present, set
COMMIT = true and strip it. `--commit` and `--no-commit` are mutually
exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`

Also scan for the optional `--no-push` flag and strip it. NO_PUSH only
matters when COMMIT is true: it skips the pull-at-start / re-sync / push
steps of the commit-and-push protocol while still committing as always.

Whatever remains is free-form context about the plan — a feature the user
wants placed in a particular milestone, an ordering they want, which
milestone is being built now, a milestone they consider shipped. Fold it
into PHASE 1 rather than treating it as a command.

Maintain a `WRITTEN` list of every path this invocation wrote. It drives the
final report and the optional commit.

---

PHASE 0 — GATE + READ

**Gate.** `.claude/FEATURES.md` must exist. Probe it (Read). If it is
missing, stop:

> This project has no feature index. Run `/domain-setup` first — it creates
> `.claude/domain/`, the domain `INDEX.md`, and `.claude/FEATURES.md`. Then
> architect at least one feature with `/architect`, and re-run
> `/production-plan`.

Do not proceed and do not create the index yourself. No exceptions. This is
the only gate in the skill.

**A roadmap is not required.** `.claude/domain/product-roadmap.md` is an
optional input. Without it every feature lands in `Unscheduled`, dependency
edges and cycle validation still work, and the plan is still worth having —
a project gets sequencing without roadmap ceremony. Its absence is the
normal state of many projects, so say so in one line and carry on; never
warn, never refuse, and never point at `/product-roadmap` as a prerequisite.

If COMMIT is true and the project's CLAUDE.md does not carry a `## VCS`
override (non-git), pull at start per the commit-and-push protocol: run
`git pull` on the current branch. A conflict stops the run here — report the
conflict output and tell the user to resolve manually and re-run.

**Read the inputs**, in this order. Every one of them is **read-only** — this
skill writes `.claude/PLAN.md` and nothing else, ever:

1. `.claude/FEATURES.md` — every feature slug, its `Status:`, its `Source:`
   line (including the optional ` (<milestone-slug>)` parenthetical), and
   its `Tasks:` line.
2. Each feature document named by a `Doc:` line — its `## Dependencies`
   section only. That prose is the input to the edge proposal in PHASE 1;
   nothing else in the document is needed here.
3. `.claude/domain/product-roadmap.md`, **if present** — the milestone
   slugs, their order (list position, top to bottom), and their `Covers:`
   lines.
4. `.claude/PLAN.md`, if present — the existing plan. This is the run's
   resume state; a re-run proposes changes *against* it rather than from a
   blank page. If it exists, read `./reconciling.md` before PHASE 1.
5. `.claude/TASKS.md` — task statuses, **only** to decide whether to propose
   a milestone as `[SHIPPED]` in PHASE 1. Nothing else in this skill reads
   or depends on task state.

**No features at all** — `FEATURES.md` exists but lists none: write nothing,
say so in one line ("No features are architected yet — run `/architect`
first; there is nothing to plan."), and stop. This is not a refusal and not
an error.

Say in two or three lines what you found — first run or reconciliation, how
many features, how many milestones (or that there is no roadmap) — then
continue.

---

PHASE 1 — PLACE, CONNECT, DECIDE

One conversational round that assembles the whole proposal. Contribute
rather than only extract: propose the placement and the ordering with
reasons, and say what looks wrong.

**1. Milestone inheritance — a lookup, not an inference.** For each feature
in `FEATURES.md`, read its `Source:` line:

- `Source: product-design.md § <Section> (<milestone-slug>)` → the feature
  belongs to `<milestone-slug>`. Take it directly. Because `/architect`
  architects one scope slice at a time, the parenthetical already records
  which milestone the feature came from; do not re-derive it from the
  section name, the roadmap's `Covers:` prose, or anything else.
- No parenthetical, or `Source: prompt` → the feature starts in
  `Unscheduled` until placed by hand.
- A parenthetical naming a milestone the roadmap does not have → place the
  feature there anyway and say so in one line. A hand-edited or
  ahead-of-the-roadmap `Source:` must not break the run.

**Explicit placement overrides the parenthetical.** The user may place any
feature in any milestone — from `$ARGUMENTS` or in this conversation — and
that placement wins. Business circumstances change, and the roadmap makes no
completeness claim for an override to violate. So an override is **never
gated and never refused**; it is only **reported plainly** at the approval
gate, naming the feature, the milestone its `Source:` implies, and the
milestone it is being placed in. Silently applying it is the one thing that
is not allowed.

**2. Ordering within each milestone.** `Features:` is ordered and the order
is the priority. Propose an order consistent with the dependency edges
(step 3) and, where the edges leave a choice, with what unblocks the most
work first. Say which constraint is driving each placement. On a
reconciliation, start from the existing order and discuss only the delta.

Do not invent a priority field, a `P0`/`P1` label, a size, an estimate, or a
date. If the user asks for a priority, the answer is a position in the list.

**3. Dependency edges — documents propose, `PLAN.md` records.** For each
feature, read its document's `## Dependencies` section and propose the edges
it implies, in machine-readable form:

> `config-export` depends on `settings-store`, `feature-flags`
> — from its Dependencies section: "needs the settings store to read from,
> and the flag registry to decide what is exportable".

The user confirms, edits, adds and removes. **The prose stays the
human-facing statement and is never rewritten by this skill** — the edge
list is its parsable projection, and drift between them is resolved by
re-running this skill, not by editing feature documents. An edge the
documents do not state is legitimate: the user may add it, and storing
confirmed edges is exactly what makes that possible.

Only *feature-to-feature* edges belong here. Task-level ordering already has
`Preconditions:` in the backlog and is untouched by this skill.

**An edge naming a slug that resolves to no feature** — a renamed or deleted
feature, or a typo — is **reported and dropped**, never a refusal. Say which
edge was dropped and why, and carry on, the same way `/architect`'s iterate
guard ignores task IDs that resolve to nothing.

**4. Milestone status.** The vocabulary is exactly three values and nothing
else:

| Status | Meaning |
| --- | --- |
| `[PLANNED]` | Scheduled, not started. |
| `[ACTIVE]` | Being built now. **At most one milestone at a time.** |
| `[SHIPPED]` | Delivered. **Terminal — it can never reopen.** |

- A milestone new to the plan starts `[PLANNED]`.
- `[ACTIVE]` is the user's call — ask which milestone is being built now if
  it is not obvious and not already recorded. **More than one `[ACTIVE]`**
  (in the existing plan, or after the user's answer) → report both and ask
  which one is meant. Do not pick one.
- **`[SHIPPED]` is proposed, never applied automatically.** Propose it for a
  milestone only when *every* feature in it is `[PLANNED]` in `FEATURES.md`
  **and** every task on those features' `Tasks:` lines is `[DONE]` or
  `[SKIP]` in `TASKS.md`. Then ask; the user confirms or declines.
- **`[SHIPPED]` never reopens.** Not on request, not with a flag. Follow-up
  work on a shipped milestone is a *new* milestone in the roadmap — the same
  discipline that makes `[DONE]` terminal for tasks and `[PLANNED]` → `[NEW]`
  illegal for features. If the user asks, say this and offer the new
  milestone instead.

**5. Reconciliation** (only when `PHASE 0` found an existing `PLAN.md`).
Follow `./reconciling.md` and fold its findings into this same proposal.
Everything — new placements, dropped slugs, re-read edges, added and orphaned
milestones — lands behind the one approval gate below.

---

PHASE 2 — VALIDATE

Runs **before the approval gate and before any write**, on the proposal
PHASE 1 assembled. Both invariants **refuse** rather than warn: nothing is
written, and there is no override flag for either.

**1. Cycles.** Walk the whole confirmed edge set, across milestones, and
detect cycles. On a cycle, report **the actual cycle path** and refuse:

> Refusing to write the plan: the dependencies contain a cycle.
>
>   `checkout` → `pricing` → `tax-rules` → `checkout`
>
> A cycle cannot be built in any order. Break it by removing one of those
> edges — usually the one the feature documents state least clearly — and
> re-run `/production-plan`.

A cycle is not a judgement call, so there is no flag to force past it and no
"proceed anyway" option to offer.

**2. Ordering within a milestone.** For each milestone, restrict the edge set
to the features in that milestone. The milestone's `Features:` list must be a
**topological order** of those edges: every feature appears after everything
it depends on. If it does not, report the offending pair and either fix the
order with the user or stop — never write a list you know violates its own
edges.

**3. A dependency in a later milestone → refuse outright.** If a feature in
milestone *i* depends on a feature in milestone *j* where *j* comes after *i*
in roadmap order, the dependency cannot be satisfied by the time it is
needed. Report both features **and both their milestones**, and refuse:

> Refusing to write the plan: `m1-mvp`'s `config-export` depends on
> `sync-engine`, which is scheduled in `m3-teams`. A milestone cannot depend
> on a later one. Either move `sync-engine` earlier, move `config-export`
> later, or drop the edge.

A dependency **on a feature in `Unscheduled`** is *not* this refusal:
`Unscheduled` has no position, so it cannot be "later". Report it as a
warning — the dependency is unschedulable until that feature is placed — and
carry on.

**The approval gate.** Once validation passes, present the whole proposal in
one place and get the user's confirmation:

- Every milestone in order, with its status and its ordered `Features:` list.
- `Unscheduled`, with its features.
- Every explicit placement override, naming the `Source:` milestone and the
  milestone chosen instead.
- Every edge added, changed or removed this run, and every edge dropped for
  naming an unresolvable slug.
- Every status change proposed, `[SHIPPED]` proposals foremost.
- On a reconciliation, everything `./reconciling.md` turned up.

**This is the run's one and only approval gate.** Do not gate anything
earlier and do not add a second gate before the write.

---

PHASE 3 — WRITE

The only phase that writes, and it writes exactly one path:
**`.claude/PLAN.md`**. Add it to `WRITTEN`.

On a re-run, update it in place: keep the milestone blocks, the orderings and
the edges that did not change. `FEATURES.md`, `TASKS.md`, the feature
documents, `product-roadmap.md`, `product-design.md` and the domain
`INDEX.md` are **never written by this skill**, under any circumstances,
including to fix something this run noticed.

### The document schema

````markdown
# Plan

Roadmap: .claude/domain/product-roadmap.md
Last reconciled: <YYYY-MM-DD>

---

## <milestone-slug> — <milestone title>

Status: [PLANNED]
Covers: product-design.md § <Section>, product-design.md § <Section>
Features: <slug>, <slug>, <slug>

---

## <milestone-slug> — <milestone title>

Status: [ACTIVE]
Covers: product-design.md § <Section>
Features: <slug>, <slug>

---

## Unscheduled

Features: <slug>, <slug>

## Dependencies

- <slug>: depends on <slug>, <slug>
- <slug>: depends on <slug>
````

Rules the schema is not free to bend:

- **`Roadmap:`** names the roadmap this plan was built against, or the
  literal `none` when the project has no roadmap.
- **`Last reconciled:`** is a plain date and is **informational only**.
  Nothing computes from it, nothing expires because of it, and no reader may
  treat it as a staleness signal — the real staleness signal is a
  `FEATURES.md` slug missing from the plan.
- **Milestones appear in roadmap order**, top to bottom, separated by `---`.
  The order comes from the roadmap's list positions, never from the slugs.
- **`Status:`** is exactly one of `[PLANNED]` / `[ACTIVE]` / `[SHIPPED]`, on
  every milestone block. Never on `Unscheduled`.
- **`Covers:`** is **derived** — rewritten from the roadmap's own `Covers:`
  lines on every run, section names only, with the roadmap's scope prose left
  where it belongs. It is present for readability and is never a source of
  truth, so never hand-edit it and never let the user's edits to it survive a
  run. Omit the line entirely when there is no roadmap.
- **`Features:`** is a comma-separated, **ordered** list of feature slugs.
  The order is the priority. A milestone with no features carries
  `Features: none`.
- **`Unscheduled`** is a block with `Features:` and nothing else — no
  `Status:`, no `Covers:`. Write it even when empty (`Features: none`), so
  the schema is uniform.
- **`## Dependencies` is one flat edge list at the end of the document**, one
  line per dependent feature, and there is **no `Depends:` line on a
  feature**. Two reasons, both load-bearing: it keeps `PLAN.md` from becoming
  a second index keyed by feature slug, and it puts every edge in one place,
  where a cycle is visible to a human reader. A feature with no dependencies
  gets no line.
- **No dates, no estimates, no sizing, no percentages, no priority labels,
  and no readiness or coverage rollups.** Readiness, coverage and per-feature
  task counts are computed at read time by whatever reports the plan; storing
  them here creates a second thing to keep in sync.

**Closing report.** State:

- Every milestone, in order, with its status and its ordered features.
- Everything in `Unscheduled`, and what would place it (a `Source:`
  parenthetical from `/architect`, or an explicit placement here).
- Every placement override applied.
- Every edge added, changed, removed or dropped.
- Every status change written, and every `[SHIPPED]` proposal the user
  declined.
- Every warning raised — an unscheduled dependency, a milestone slug absent
  from the roadmap, a milestone with no features.
- The paths written (`WRITTEN`).
- The next step: `/task-add feature=<slug>` for the first feature of the
  `[ACTIVE]` milestone.
- When `WRITTEN` is non-empty and `--commit` was not passed: an explicit
  reminder that nothing was committed.

---

COMMIT AND PUSH (only when `--commit` was passed)

If COMMIT is false (the default), run no git/VCS command at all. The plan is
left uncommitted for the user to review — matching `/product-roadmap`,
`/architect`, `/product-design`, and `/domain-setup`.

If COMMIT is true (the pull-at-start from PHASE 0 already ran):

1. If `WRITTEN` is empty — validation refused, the user declined at the gate,
   or a re-run changed nothing — make no commit and no push. Say so and stop.
2. Stage EXACTLY the paths in `WRITTEN` — `.claude/PLAN.md` — and commit
   once:

   ```
   git add -- .claude/PLAN.md
   git commit -m "Update the production plan"
   ```

   Never use `git add -A`, `git add .`, or `git add -u`. On a non-git VCS,
   use the project's `## VCS` mapping in CLAUDE.md (git→`cm`).
3. On commit success, report the commit hash (`git rev-parse --short HEAD`).
   Then, unless NO_PUSH is true or the non-git VCS exemption applies,
   re-sync (`git pull` again — other commits may have landed while the run
   was in progress; a conflict aborts the merge, leaves the local commit
   intact and is reported, not pushed) and then `git push`.
4. On commit failure (e.g. a pre-commit hook rejects the commit): surface
   the exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.
5. On push failure (rejected, no upstream, no remote) or a pre-push
   conflict: surface the exact output. Never retry, never force-push. The
   commit exists locally; tell the user it needs a manual sync + push.

---

DO NOT:
- Write anything before PHASE 3, or write anything in PHASE 3 other than
  `.claude/PLAN.md`. In particular never write `.claude/FEATURES.md`,
  `.claude/TASKS.md`, task bodies, anything under `.claude/domain/features/`,
  `product-roadmap.md`, `product-design.md`, `technical-direction.md`, or
  `.claude/domain/INDEX.md`. This skill is the sole writer of one file and
  the reader of everything else. A problem it notices in another artifact is
  reported, never fixed here.
- Rewrite a feature document's `## Dependencies` prose to match the confirmed
  edges. The prose is the human-facing statement; the edge list is its
  projection. Drift is resolved by re-running this skill.
- Add a priority field, a `P0`/`P1` label, a date, an estimate, a size, a
  percentage, or any readiness/coverage rollup to `PLAN.md`. Priority is
  position in `Features:`; everything else in that list is derivable and is
  computed at read time.
- Write a `Depends:` line on a feature block. Dependencies live in the one
  flat `## Dependencies` list.
- Hand-write or preserve a hand-edited `Covers:` line. It is derived from the
  roadmap on every run.
- Proceed past a cycle or a later-milestone dependency. Both refuse, both
  report specifics — the cycle path, or both features with both milestones —
  and neither has an override flag.
- Refuse over an explicit placement override, a milestone missing from the
  roadmap, a milestone with no features, an edge slug that resolves to
  nothing, or a missing roadmap. Those are reports and warnings. The only
  refusals in this skill are PHASE 0's gate and PHASE 2's two invariants.
- Reopen a `[SHIPPED]` milestone, or apply `[SHIPPED]` without the user
  confirming it. Follow-up work is a new milestone.
- Record more than one `[ACTIVE]` milestone, or pick between two on the
  user's behalf.
- Infer a feature's milestone from its section name, the roadmap's `Covers:`
  prose, or the shape of its document. Inheritance is the `Source:`
  parenthetical or nothing.
- Rename a feature slug or a milestone slug, or reuse one for something else.
  Slugs are stable identifiers, like task IDs.
- Require a roadmap. Without one, everything is `Unscheduled` and the run
  still produces a useful plan.
- Advance past PHASE 2's approval gate without the user confirming. There is
  exactly one gate and that is it.
- Run any git/VCS command unless `--commit` was passed; and with it, stage
  only the explicit `WRITTEN` paths, never a catch-all, push per the
  commit-and-push protocol unless `--no-push` was passed, and never
  force-push, retry a failed push, branch, tag, or use hook-skipping flags
  (`--no-verify`, `--no-gpg-sign`, `--amend`).
- Create `.claude/FEATURES.md` yourself when PHASE 0's gate fails. Point at
  `/domain-setup` and stop.
