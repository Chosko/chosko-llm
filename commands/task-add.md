---
name: task-add
version: 0.14.0
type: command
description: Plan a new task entry conversationally, confirm with the user, write a summary block and body file, then auto-commit and push. Detects work needing manual human steps (e.g. game-engine editors) and authors a Manual interventions section with target claude+human or human. Pass feature=<slug> to plan from an /architect feature document instead of a prose description — reconciling any tasks that feature already generated (update-in-place, skip-and-replace, or leave untouched; [DONE] never touched), tagging new tasks with Feature: <slug>, appending a final documentation-update task when new tasks were drafted, and setting the feature [PLANNED]. Pass --enrich to produce a self-contained body for a local LLM in one shot, --short for trivial low-ambiguity tasks to skip the deep PHASE 1 investigation and write a minimal Goal-only body (mutually exclusive with --enrich and feature=), --no-split to always write exactly one task, --no-commit to write the files but skip the commit (and push), or --no-push to commit without pushing.
---

# /task-add
# Global command: plan a new task entry conversationally, confirm with the
# user, then write a summary block to `.claude/TASKS.md` and a body file at
# `.claude/tasks/<N>.md`. Refuses to run if the backlog has not been
# initialized — the user must run `/task-setup` first. May propose
# splitting the description into multiple tasks when that produces better
# units; pass `--no-split` to always get exactly one task. With
# `feature=<slug>`, plans from a `/architect` feature document instead of a
# prose description, and reconciles tasks that feature already generated.
# Usage: /task-add [--enrich] [--short] [--no-split] [--no-commit] [--no-push] <free-form description of the task>
#        /task-add feature=<slug> [--enrich] [--no-split] [--no-commit] [--no-push] [scope-narrowing text]
# Example: /task-add fix the URL normalization so two LinkedIn URLs dedupe
# Example: /task-add --enrich add CSV export command
# Example: /task-add --short document the current deployment method
# Example: /task-add --no-split add CSV export and PDF export commands
# Example: /task-add feature=session-handling
# Example: /task-add feature=user-profile just the avatar upload

GOAL
Add one or more new tasks to the project's task backlog. The flow is:
SETUP-CHECK → READ → SPLIT-CHECK → ASK → DRAFT → CONFIRM → WRITE → COMMIT.

Two input modes share that flow:

- **Free-form** (the default) — a prose description of the work. Unchanged
  in every respect by the feature mode below.
- **Feature** (`feature=<slug>`) — plan from the low-level feature document
  `/architect` wrote, and reconcile any tasks that feature already
  generated. This is stage 3 of the product pipeline.

By default, the body contains: Goal, Acceptance criteria, Decisions (when
applicable), and Hints. Claude navigates the project at implementation time
and does not need more.

With `--enrich`, produce a self-contained body for a local LLM implementer
in one shot — read `commands/task-enrich.md` for the enriched format and
apply it directly during authoring. Do not write a plain body first and then
enrich it.

With `--short`, skip the deep PHASE 1 investigation for a trivial,
low-ambiguity task and write a minimal Goal-only body instead — see the
ARGUMENT NOTE and SHORT-FORM BODY sections below. `--short` is mutually
exclusive with `--enrich` and `feature=<slug>`.

Never write to any file before the user confirms the draft.

$ARGUMENTS

ARGUMENT NOTE — before PHASE 1, scan $ARGUMENTS for the optional
`--no-commit` flag (independent of `--enrich`). If present, set
NO_COMMIT = true and strip it; the rest is the task description.
`--commit` and `--no-commit` are mutually exclusive — if both appear, stop
with: `--commit and --no-commit cannot be combined. Pick one.` When
NO_COMMIT is false (the default), PHASE 5 auto-commits as before.
`--no-commit` implies no push — nothing was committed to push.

Also scan for the optional `--no-push` flag. If present, set NO_PUSH = true
and strip it. NO_PUSH only matters when NO_COMMIT is false: it skips the
pull-at-start / re-sync / push steps of PHASE 5's commit-and-push protocol
(docs/authoring-guide.md), while still committing as always.

Also scan for the optional `--no-split` flag (independent of `--enrich` and
`--no-commit`, coexists with both). If present, set NO_SPLIT = true and
strip it; PHASE 1.5 is skipped entirely and exactly one task is always
written. When NO_SPLIT is false (the default), PHASE 1.5 considers whether
a split would produce better units.

Also scan for the optional `--short` flag. If present, set SHORT = true and
strip it. `--short` is for trivial, low-ambiguity tasks where the normal
deep PHASE 1 investigation costs more tokens than the task itself; under
SHORT, PHASE 1 is reduced to the minimum needed to fill the `Files:` line
(light Grep/Glob only — no reading of CLAUDE.md, `.claude/context/`, or
`.claude/domain/` files for grounding), PHASE 1.5 is skipped entirely
exactly as under `--no-split` (a short task is never split; SHORT implies
NO_SPLIT = true), and the body is written using the SHORT-FORM BODY schema
below instead of the default one. PHASE 2 still runs — SHORT only removes
the deep-investigation source of open questions, not ambiguity inherent to
the user's own description (see PHASE 2 below). `--short` is mutually
exclusive with `--enrich` and with `feature=<slug>` — both imply exactly
the deep investigation `--short` exists to skip. If `--short` appears with
either, stop with: `--short cannot be combined with --enrich or
feature=<slug>. Pick one.` `--short` composes normally with `--no-commit`
and `--no-push`.

Finally, scan for an optional `feature=<slug>` argument. If present, set
FEATURE = the slug and strip it; it composes with all flags above except
`--short` (see the mutual-exclusion rule above). Whatever free-form text
remains is NOT the task description in this mode — it narrows or annotates
the scope (`feature=user-profile just the avatar upload`), and the feature
document stays the primary source. When FEATURE is unset, every phase
behaves exactly as it always has: no feature resolution, no
reconciliation, no `Feature:` line, no new prompts.

---

FEATURE RESOLUTION (only when FEATURE is set)

Do this immediately after PHASE 0's setup check, before PHASE 1.

1. Read `.claude/FEATURES.md`. If it does not exist, stop:

   > This project has no feature index (`.claude/FEATURES.md`). Run
   > `/domain-setup` to create the domain layer, then `/architect` to
   > design a feature — `feature=<slug>` plans from what `/architect`
   > writes. (Plain `/task-add <description>` works without any of that.)

2. Find the entry whose slug is `<slug>`. If there is none, stop, listing
   the slugs that do exist so the user can correct a typo without going
   to look:

   > No feature `<slug>` in `.claude/FEATURES.md`. Available: `<slug-a>`,
   > `<slug-b>`, `<slug-c>`.

3. Read the path on the entry's `Doc:` line — that document is PHASE 1's
   primary input. If the path does not resolve, stop and say so; the index
   and the domain layer disagree and the user should look.

4. Note the entry's `Status:` and its `Tasks:` line. A non-`none` `Tasks:`
   line means this feature has been planned before, so this run
   RECONCILES rather than appends — see PHASE 3.

---

PHASE 0 — SETUP CHECK (must pass before anything else)

Before reading anything else, verify the backlog has been initialized.
The required artifacts are:
1. `.claude/TASKS.md` — the index file.
2. `.claude/tasks/` — the per-task body directory.

Probe with the Read tool / Glob. If either is missing, stop:

> The task backlog hasn't been initialized in this project. Run
> `/task-setup` first — it creates `.claude/TASKS.md` and the
> `.claude/tasks/` directory. Then re-run `/task-add`.

Do not proceed to PHASE 1. This rule has no exceptions.

If `--enrich` is present in $ARGUMENTS, also verify that
`commands/task-enrich.md` exists. If it does not, stop:

> `/task-add --enrich` requires the task-enrich command to be installed.
> Run `chosko-llm update` or install it manually, then retry.

If all artifacts exist, continue.

Unless NO_COMMIT is true (nothing will be committed this run) or the
project's CLAUDE.md carries a `## VCS` override (non-git, no push step
exists), pull at start per docs/authoring-guide.md's commit-and-push
protocol: run `git pull` on the current branch. A conflict stops the run
here — report the conflict output and tell the user to resolve manually and
re-run. Otherwise continue to PHASE 1.

---

INDEX FILE FORMAT (`.claude/TASKS.md`)

```
# Tasks

Last task number: <N>

---

## <N>. <Title>

Status: [MISSING]
Target: claude
Files: <comma-separated list>
Preconditions: <comma-separated task numbers, or "none">
Feature: <slug>          ← optional; only on feature-derived tasks

---
```

The summary block holds: number, title, Status, Target, Files,
Preconditions, and — only when the task was generated from a feature
document — `Feature:`. Nothing else. Description and decisions live in the
body.

`Feature:` carries the slug of the feature the task came from. It is
present ONLY on feature-derived tasks and is absent entirely on free-form
ones — do not write `Feature: none`. Like `Status:` and `Preconditions:`,
it is backlog metadata, so it lives in the summary block and never in the
body file.

---

PER-TASK BODY FILE FORMAT (default)

```
# Task <N> — <Title>

Target: claude

## Goal
<One paragraph: what and why.>

## Acceptance criteria
- <Verifiable outcome.>
- <…>

## Decisions
<Only present when non-obvious choices were made during authoring — by
the user or by Claude. Each bullet: the choice and a brief why. Omit the
section entirely when no contested calls exist; its absence is meaningful.>

## Manual interventions
<Only present when Target is claude+human or human — see TARGET VALUES &
MANUAL INTERVENTIONS below.>

## Hints
<Required. Always present. File paths the implementer should touch:
edit targets, test files, documentation, collateral files. Write
"none" explicitly only when nothing collateral genuinely exists.>
- <path/to/file>
- <…>
```

---

TARGET VALUES & MANUAL INTERVENTIONS

`Target:` (line 2 of the body, mirrored in the summary block) takes one of:

- `claude` — Claude implements end-to-end. **Default.**
- `local` — enriched body for a local LLM (`--enrich` mode only).
- `claude+human` — Claude implements, but the work includes steps only a
  human can perform in an external tool (a game-engine editor such as
  Unity, a cloud console, physical hardware). `/task-implement` pauses at
  each declared checkpoint, walks the user through it, and verifies the
  outcome before continuing.
- `human` — the task is executed entirely by the user; `/task-implement`
  runs it as a guided walkthrough.

During PHASE 1/2, when the description or the codebase reveals that part
of the work cannot be executed by an agent (editor-only operations, GUI
wizards, hardware), set `Target: claude+human` (or `human` when nothing
is agent-executable) and author a `## Manual interventions` section,
placed between `## Decisions` and `## Hints`. Consistency is enforced
both ways: targets `claude+human`/`human` REQUIRE the section, and the
section requires one of those targets — never write one without the other.

The section opens with a ⚠ warning line, then numbered checkpoints. Each
checkpoint is anchored to a trigger point ("After X: …"), describes the
manual step, and ends with an outcome the implementer can verify itself.
Worked example (Unity):

```
## Manual interventions

⚠ REQUIRES MANUAL INTERVENTION — pause implementation at these points and
walk the user through them in the Unity editor; wait for their
confirmation and verify the outcome before continuing:

1. After the `.inputactions` file is written: select it in the Project
   window, tick **Generate C# Class** in the importer, Apply. Verify the
   generated `.cs` file appears and the project compiles.
2. After `InputManager.cs` compiles: open
   `Assets/_Project/Prefabs/Controllers.prefab`, add the `InputManager`
   component to an appropriate GameObject, and assign any serialized
   references (e.g. the actions asset if referenced via inspector).
   Do NOT hand-edit the prefab YAML for this. Verify the prefab contains
   the component with its references assigned.
```

---

PER-TASK BODY FILE FORMAT — `--enrich` mode

Same body as above plus two additional sections at the end, with
`Target: local` on line 2:

```
## Context bundle
<Selective excerpts of relevant code, patterns, and constraints the local
LLM needs. Include only what is necessary.>

## Implementation steps
<Step-by-step guidance concrete enough to follow without any external reads.>
```

In `--enrich` mode, read `commands/task-enrich.md` for the detailed
format guidance of these two sections.

---

PER-TASK BODY FILE FORMAT — `--short` mode

```
# Task <N> — <Title>

Target: claude

## Goal
<1–3 sentences: what and why. No more — a short task resolves its own
details at implementation time.>

## Decisions
<Only present when a genuine non-obvious call was made during the (now
minimal) authoring pass. Same rule as the default schema. Usually absent.>
```

`## Acceptance criteria` and `## Hints` are omitted entirely — not left as
placeholders — since authoring them without the deep PHASE 1 investigation
would produce content that is likely wrong or vacuous. `/task-implement`
resolves those details at execution time instead.

---

STATUS TAGS (the only allowed values, recorded in TASKS.md)

- `[MISSING]` — behavior not implemented at all. **Default for new tasks.**
- `[STUBBED]` — placeholder/TODO exists but no real implementation.
- `[INCORRECT]` — implemented but diverges from the spec.
- `[PARTIAL]` — implemented in part; some sub-requirements still missing.
- `[IN PROGRESS]` — agent is currently working on it. (Not set by this command.)
- `[DONE]` — implementation has landed. (Not set by this command.)
- `[SKIP]` — explicitly deferred or abandoned.
- `[STALE]` — the feature document this task was generated from has since
  been re-architected, so the task may no longer match the design. Set by
  `/architect` when it re-architects the originating feature; resolved by
  `/task-add feature=<slug>` reconciliation, which either updates the body
  in place (flipping the task back to `[MISSING]`) or marks it `[SKIP]` and
  drafts a replacement. **Never set by this command when creating a task.**
  Not terminal — a stale task is live work awaiting reconciliation.

A new task is `[MISSING]` unless the user's description clearly indicates
a different pre-implementation state.

---

PHASE 1 — READ (silent)

**When SHORT is true**, this phase is reduced to the minimum needed to fill
the `Files:` line: step 1 below, and step 2 using light Grep/Glob only (no
Read of CLAUDE.md, `.claude/context/`, or `.claude/domain/` files for
grounding — the whole point of `--short` is skipping that investigation).
Steps 3 (Hints) and 5 (`--enrich`, which cannot co-occur with `--short`) do
not apply, since the short-form body omits `## Hints`. Step 4 (Decisions)
still applies, but only for non-obvious choices visible from the
description and the light scan — not from a deep read `--short` skips.
Step 4b still applies if the light scan or the description itself surfaces
a manual-intervention need. Continue straight to PHASE 1.5 (skipped, as
under `--no-split`) and then PHASE 2.

1. Read `.claude/TASKS.md`. Note:
   - The current `Last task number: N` value — new task ID = N + 1.
   - Title style in existing tasks — match it.

1b. **When FEATURE is set**, read the feature document resolved above and
   treat it as the PRIMARY context source — the way `/task-implement`
   treats a task body. It already contains the purpose, scope and
   non-goals, architecture, data and state, interfaces, dependencies, and
   open questions. Fan out to CLAUDE.md, `.claude/context/`, and other
   `.claude/domain/` files only where the document does not cover what you
   need; do not re-derive from source what the document already states.

   Then, if the entry's `Tasks:` line is non-`none`, read each listed
   task's TASKS.md summary block AND its `.claude/tasks/<N>.md` body. You
   cannot classify a task you have not read, and PHASE 3 must classify
   every one of them. IDs that resolve to no task are ignored, not an
   error — `/task-clean` normally prunes them.

   Any free-form text alongside `feature=<slug>` narrows the scope: it
   selects which parts of the document this run plans, or adds a
   constraint. It does not replace the document.

2. Read enough of the codebase to ground the task:
   - Use Grep / Glob / Read to confirm which files the task will touch.
   - Read CLAUDE.md and relevant `.claude/context/` files for the area
     under change.
   - Read relevant `.claude/domain/` files for architectural rationale.
   - Stop when you have a clear picture.

3. Identify collateral: documentation, test files, install scripts,
   context-layer files, or cross-referenced commands that will need
   updating alongside the primary edit targets. These become Hints.

4. Note any non-obvious choices you are making (scope, approach,
   interpretation of ambiguous requirements). These become Decisions.

4b. Judge whether any part of the work requires manual human steps in an
   external tool (see TARGET VALUES & MANUAL INTERVENTIONS). If so, plan
   the checkpoints — trigger point, manual step, verifiable outcome — and
   the target (`claude+human`, or `human` when nothing is
   agent-executable). If the user's description suggests manual steps but
   you cannot tell which, make it a PHASE 2 question.

5. **`--enrich` mode only:** also read `commands/task-enrich.md`
   for the enriched body format. Gather additional material for
   `## Context bundle` (relevant excerpts) and `## Implementation steps`
   (step-by-step guidance). Be selective — include only what is necessary.

No user-facing output during this phase beyond a single brief sentence
saying what you're reading.

---

PHASE 1.5 — SPLIT CHECK (skipped entirely when NO_SPLIT is true, or SHORT is
true — `--short` forces `--no-split` behavior, since a task specific enough
to qualify for `--short` is by definition not a bundle of independent
deliverables)

Using the grounded picture from PHASE 1, judge whether the description
would produce better units as multiple tasks — either because it bundles
independent deliverables (e.g. "add CSV export and PDF export"), or
because a single task covering it would simply be too large/sprawling to
implement, test, and commit as one coherent unit. This is a judgment call,
not a rule: most descriptions are fine as one task, and this step should
stay silent for them.

**When FEATURE is set, the calculus inverts.** A feature document describes
a unit of *design*, which is usually several units of *implementation* — so
weigh the document's own structure: distinct components, separable
interfaces, and independently deliverable slices of its architecture
normally each become a task. Proposing a single task for a whole feature is
the exception, appropriate for a small feature. Use the document's
structure as the seam, not an arbitrary count. `--no-split` still forces
exactly one task, in this mode as in any other.

If a split is NOT warranted: say nothing about splitting and continue
straight to PHASE 2 with the single, original description (SPLIT = none).

If a split IS warranted, propose it:

```
This looks like it would work better as N tasks:

1. <Title> — <one-line scope>
2. <Title> — <one-line scope>
...

Split into N tasks, keep as one, or adjust the breakdown?
```

- On acceptance (as proposed or after adjustment): set SPLIT = the
  confirmed ordered list of parts (title + one-line scope each). Note
  which parts depend on earlier parts (used later to auto-wire
  Preconditions). Continue to PHASE 2, which now operates once per part.
- On decline: set SPLIT = none and continue to PHASE 2 with the original,
  single description — the rest of the flow is unaffected.

---

PHASE 2 — ASK (conversational)

Ask only about things you cannot resolve from the code or the user's
description. 1–4 focused questions max. Suggest the answer you'd pick and
why so the user can confirm with a single word.

**When SHORT is true**, this phase is NOT skipped wholesale — it still asks
about ambiguity inherent to the user's own description (e.g. the
description admits multiple plausible interpretations, or names a target
that doesn't clearly resolve). It does not ask about ambiguity that would
only have surfaced through the deep investigation `--short` skips — those
are two different sources of open questions, and only the former applies
under `--short`.

If there are zero open questions after PHASE 1 (and PHASE 1.5), say so in
one line and skip to PHASE 3.

Position questions are unnecessary — new tasks are appended at the end
by default. Only ask about position if the user has signalled they want
grouping.

When SPLIT is set (multiple parts), ask questions across the whole
breakdown in one pass — per-part if a part has its own open question, but
still capped at 1–4 focused questions total. Don't run a full separate
Q&A round per part.

---

PHASE 3 — DRAFT (present for confirmation)

**When FEATURE is set**, open the plan by naming the source above the
drafts, so it is obvious what the tasks were derived from:

```
Source feature: <slug> — <title from the FEATURES.md entry>
Doc:            .claude/domain/features/<slug>.md
Feature status: [NEW] → [PLANNED]        (or [ITERATED] → [PLANNED])
Scope note:     <the free-form narrowing text, if any>
```

Then, when that feature already has tasks, render a RECONCILIATION section
BEFORE the new drafts (see RECONCILIATION below). One approval covers the
reconciliation and the new tasks together — there is no second gate.

When SPLIT is none (the common case), render the single-task plan exactly
as before:

```
PLAN — new task

Index file: .claude/TASKS.md
Body file:  .claude/tasks/<N>.md   (N = previous Last + 1)

Counter update: Last task number  K → N

Draft summary block:
  ---

  ## <N>. <Title>

  Status: [MISSING]
  Target: <claude|local|claude+human|human>
  Files: <comma-separated list>
  Preconditions: <preconds or "none">

Draft body:
  # Task <N> — <Title>

  Target: <claude|local|claude+human|human>

  ## Goal
  …

  ## Acceptance criteria
  - …

  ## Decisions              ← omit section if no non-obvious choices
  - …

  ## Manual interventions   ← only when Target is claude+human or human
  …

  ## Hints
  - …

  ## Context bundle         ← --enrich mode only
  …

  ## Implementation steps   ← --enrich mode only
  …
```

**When SHORT is true** (SPLIT is always none in this mode, per PHASE 1.5),
the draft body omits `## Acceptance criteria` and `## Hints` entirely and
keeps `## Goal` to 1–3 sentences — see PER-TASK BODY FILE FORMAT — `--short`
mode above. `## Decisions` remains conditional as usual.

When SPLIT is set (multiple parts), render every part's full draft in one
message, using sequential IDs starting at `previous Last + 1`:

```
PLAN — N new tasks (split)

Index file: .claude/TASKS.md
Body files: .claude/tasks/<N>.md .. .claude/tasks/<N+k-1>.md

Counter update: Last task number  K → K+k

Part 1/k — Draft summary block:
  ---

  ## <N>. <Title>

  Status: [MISSING]
  Target: <claude|local|claude+human|human>
  Files: <comma-separated list>
  Preconditions: <earlier part's ID(s), or "none">

Part 1/k — Draft body:
  # Task <N> — <Title>

  Target: <claude|local|claude+human|human>

  ## Goal
  …

  ## Acceptance criteria
  - …

  ## Decisions              ← omit section if no non-obvious choices
  - …

  ## Hints
  - …

... (repeat for each remaining part) ...
```

**When FEATURE is set** and at least one new task was drafted above (single
or split), also render the documentation task's draft here, last, using the
next sequential ID after the others. See DOCUMENTATION TASK below for its
content and the ownership-gate question that precedes it. Skip this
entirely on a reconciliation-only run that drafts zero new tasks.

End with: **"Approve and write?"**

Wait for explicit approval. Iterate on changes and re-present the full
plan (all parts, when split) after any non-trivial revision. Silence is
not approval.

---

RECONCILIATION (only when FEATURE is set and its `Tasks:` line is non-`none`)

A re-planning run must not append blindly — that reliably produces
overlapping work. Classify EVERY existing task read in PHASE 1b, and
present the classification in PHASE 3 with a one-line reason each:

| Situation | Action |
| --- | --- |
| Still valid under the new design | Left untouched. No edit at all. |
| Needs minor change, and is `[STALE]` or `[MISSING]` | Body updated in place. A `[STALE]` task flips back to `[MISSING]`. |
| Substantially invalidated | Marked `[SKIP]` with a reason, and a replacement task drafted. |
| `[DONE]` | Never modified, skipped, or reopened. |

**Prefer update-in-place.** Whenever the task's goal survives the design
change, rewriting the body is cheaper than skip-and-replace: nothing has
been implemented yet, and the backlog stays free of dead `[SKIP]` entries
that future readers have to interpret. Reserve skip-and-replace for tasks
whose goal no longer survives at all.

Which of the two applies is a judgment call about how much of the task
remains — the criteria above are the criteria; there is no mechanical rule
and no line count. State the reason for each call so the user can overrule
it in the same approval.

**`[DONE]` is untouchable.** Completed work stands regardless of what the
design did afterwards. If the new design needs more from an area a `[DONE]`
task covered, that is a NEW task, not a reopened one. Never flip a `[DONE]`
task to `[SKIP]`, `[STALE]`, `[MISSING]`, or anything else.

Render it like this:

```
RECONCILIATION — feature <slug> has 4 existing tasks

  12. [DONE]     <title>
      → untouched. Completed work; the new design doesn't change it.
  13. [MISSING]  <title>
      → untouched. Still valid — the interface it builds is unchanged.
  14. [STALE]    <title>
      → body updated in place, back to [MISSING]. The goal survives; the
        component it targets was renamed and its contract narrowed.
  15. [MISSING]  <title>
      → [SKIP] ("superseded: the design no longer has a separate cache
        layer"), replaced by new task <N+2> below.
```

Then the new drafts, then the single **"Approve and write?"**.

---

DOCUMENTATION TASK (feature mode only)

Applies only when FEATURE is set, and only when this run drafts at least
one new task. A reconciliation-only run that leaves every existing task
untouched creates nothing new to document, so this section does not fire.

After the normal new-task draft(s) — single or split — draft exactly one
more task, appended last, whose job is to bring the documentation layers
up to date with this run's other new tasks once they're implemented:

- Title: "Update documentation for feature `<slug>`"
- Target: `claude`
- `Feature: <slug>`
- `Preconditions:` every other new task ID created in this run (not the
  IDs of tasks left untouched or updated in place during reconciliation),
  comma-separated — signals it should land last; not mechanically
  enforced, same as any other `Preconditions:` line.
- `## Goal` names the feature and states that the documentation describing
  its area is now out of date and needs to reflect the shipped behavior.
- `## Hints` are drawn from the same collateral PHASE 1 identified —
  README.md, docs/authoring-guide.md, relevant `.claude/domain/*.md`,
  `.claude/context/features.md`, `.claude/context/INDEX.md` — whichever of
  these actually describe the behavior this run's tasks change. Not a
  fixed list; judge per feature, same as any other task's Hints.

**Ownership gate.** Some of the collateral PHASE 1 surfaces is NOT owned by
this command: `.claude/domain/features/<slug>.md` (owned by `/architect`)
and `product-design.md` / `technical-direction.md` / `business-model.md`
(owned by `/product-design`). Never add one of these to the doc task's
Hints silently. Instead, during PHASE 3, surface it explicitly and ask:

> The doc-update task could also flag `.claude/domain/features/<slug>.md`
> for review, since this feature changed its own design surface — but that
> file is owned by `/architect`, not this command. Include it in the doc
> task's Hints anyway? Default: leave it out — it stays read-only outside
> its owning command elsewhere in this pipeline.

Wait for an explicit answer; silence is not approval, same as any other
PHASE 3 confirmation. Include the file in the drafted task only on
explicit yes.

---

PHASE 4 — WRITE (only after explicit approval)

Single-task case (SPLIT is none):

1. Edit `.claude/TASKS.md`:
   a. Update `Last task number: K` → `Last task number: N`.
   b. Append the new summary block with its `---` separator.

2. Write `.claude/tasks/<N>.md` with the full draft body.
   Task IDs never repeat — a collision is an error; stop and report.

3. Report: task ID, both paths written, counter advanced.

Split case (SPLIT is set, k parts):

1. Edit `.claude/TASKS.md` once:
   a. Update `Last task number: K` → `Last task number: K+k`.
   b. Append all k summary blocks in order, each with its own `---`
      separator, using sequential IDs `K+1 .. K+k`.

2. Write each `.claude/tasks/<N>.md` body file, one per part, `N` ranging
   over `K+1 .. K+k`. A part that depends on an earlier part gets that
   earlier part's ID in its `Preconditions:` line; a part with no
   dependency gets `none`. Task IDs never repeat — a collision is an
   error; stop and report.

3. Report: all task IDs written, all paths, counter advanced by k.

Feature case (FEATURE is set) — in addition to the above:

1. Every new summary block carries `Feature: <slug>` as its last field.
   Existing tasks being updated in place already have it; do not add it to
   a task that lacks it unless that task belongs to this feature.

2. Every new body's `## Goal` names the originating feature, and its
   document path appears under `## Hints` — the implementer should be able
   to reach the design from the task without being told the slug
   separately.

3. Apply the approved reconciliation, and nothing beyond it:
   - Rewrite the body of each task classified "update in place", and flip a
     `[STALE]` one back to `[MISSING]` in TASKS.md.
   - Set each "substantially invalidated" task's `Status:` to `[SKIP]`, and
     record the one-line reason from the plan in its body so a later reader
     knows why. The replacement task is written as a new task.
   - Touch nothing on a task classified "untouched", and nothing at all on
     a `[DONE]` task.

4. Update the feature's entry in `.claude/FEATURES.md`, writing exactly two
   fields:
   - `Tasks:` — the surviving IDs plus the newly created ones, ascending.
     Drop the IDs of tasks this run marked `[SKIP]`; keep `[DONE]` IDs.
   - `Status:` — `[PLANNED]`, from either `[NEW]` or `[ITERATED]`.

   Never write `Doc:` or `Source:` — those are `/architect`'s fields, and
   the by-line split is what lets the two commands share this file.

5. Do NOT edit `.claude/domain/features/<slug>.md`. The feature document is
   read-only to this command; if planning revealed a genuine design
   problem, say so in the report and let the user re-run `/architect`.

6. If a documentation task was drafted (see DOCUMENTATION TASK), write its
   summary block and body exactly like any other new task, using the next
   sequential ID after the others — the counter update from step 1a/2a
   above must already include this ID (e.g. single-task case:
   `Last task number K → N+1`, not `→ N`; split case:
   `Last task number K → K+k+1`, not `→ K+k`). Include its path in the
   report and the commit alongside the rest.

Continue to PHASE 5.

---

PHASE 5 — COMMIT AND PUSH

This is the only phase that shells out: the pull-at-start / commit /
re-sync / push sequence below. No other phase runs a shell command, and
under `--no-commit` this phase runs none of it.

If NO_COMMIT is true, skip committing (and pushing) entirely: the files
PHASE 4 wrote (one task's two files, or all of a split's files) are left
uncommitted in the working tree. Report the task ID(s), all paths, and a
reminder that nothing was committed — the user should commit when ready.
Do not run any git command. Then stop.

Otherwise (the default): PHASE 0 already pulled at start. Commit as below,
then — unless NO_PUSH is true, or the project's CLAUDE.md carries a `## VCS`
override (non-git) — re-sync (`git pull` again) and push per
docs/authoring-guide.md's commit-and-push protocol. A pre-push conflict
aborts the merge, leaves the local commit intact, and reports that the
commit exists locally but needs a manual sync + push.

1. Single-task case — run:
   ```
   git add -- .claude/TASKS.md .claude/tasks/<N>.md
   git commit -m "Add task <N>: <title>"
   ```

   Split case — stage every file PHASE 4 wrote and make ONE commit
   covering every task ID created:
   ```
   git add -- .claude/TASKS.md .claude/tasks/<N>.md .claude/tasks/<N+1>.md ...
   git commit -m "Add tasks <N>-<N+k-1>: <short summary of the split>"
   ```

   Feature case — additionally stage `.claude/FEATURES.md`, plus the body
   file of every existing task the reconciliation rewrote:
   ```
   git add -- .claude/TASKS.md .claude/FEATURES.md .claude/tasks/<N>.md ...
   git commit -m "Plan feature <slug>: tasks <N>-<M>"
   ```
   The backlog change and the feature entry only make sense together, so
   they belong in one commit. Explicit paths only, as always.

2. On commit success, report the commit hash (`git rev-parse --short HEAD`).
   Then, unless NO_PUSH is true or the non-git VCS exemption applies,
   re-sync (`git pull`) and `git push` per the protocol.

3. On commit failure: surface the exact output. Do NOT retry, amend, or use
   `--no-verify`. Files remain staged but uncommitted; tell the user.

4. On push failure (rejected, no upstream, no remote) or a pre-push
   conflict: surface the exact output. Never retry, never force-push. The
   commit exists locally; tell the user it needs a manual sync + push.

PHASE 5 stages ONLY the files PHASE 4 wrote (the single task's two files,
or every file from the split). Never use `git add -A`, `git add .`, or
`git add -u`.

---

DO NOT:
- Write to any file before PHASE 4.
- Renumber existing tasks.
- Update any other task's `Preconditions:` line.
- Auto-create `.claude/TASKS.md` or `.claude/tasks/` if missing.
- Change the status of any existing task.
- Implement the task. This command only creates the entry.
- Use `git add -A`, `git add .`, or `git add -u` in PHASE 5.
- Use `--amend`, `--no-verify`, `--no-gpg-sign`, or any hook-skipping flag.
- Force-push, retry a failed push, branch, tag, or otherwise touch
  shared/visible git state beyond the commit-and-push protocol.
- In `--enrich` mode, write a plain body first and then enrich it separately.
- Propose a split for work that's fine as one task — PHASE 1.5 stays quiet
  unless a split genuinely produces better units.
- Set `Target: claude+human` or `human` without a `## Manual interventions`
  section, or write that section under any other target — the two always
  go together.
- Bundle multiple commits for a split — PHASE 5 makes exactly one commit
  covering all parts.
- Run PHASE 1.5 at all when `--no-split` or `--short` is passed.
- Combine `--short` with `--enrich` or `feature=<slug>` — stop with an
  error instead (see the ARGUMENT NOTE mutual-exclusion rule).
- Write placeholder `## Acceptance criteria` or `## Hints` sections in a
  `--short` body — omit them entirely.
- Skip PHASE 2 wholesale under `--short` — it still asks about ambiguity
  inherent to the user's own description.
- Edit `.claude/domain/features/<slug>.md`, or any other domain document.
  They are read-only here; `/architect` owns them.
- Write `Doc:` or `Source:` in a `.claude/FEATURES.md` entry. This command
  writes `Tasks:` and `Status:` only.
- Modify, skip, reopen, or re-status a `[DONE]` task during reconciliation.
  Follow-up work is a new task.
- Add a `Feature:` line to a task that did not come from that feature, or
  write `Feature: none` on a free-form task — its absence is the signal.
- Change any behavior of the free-form path when `feature=` is absent. The
  feature mode is additive; a plain `/task-add <description>` run must be
  indistinguishable from before.
- Silently add an `/architect`-owned or `/product-design`-owned document to
  the documentation task's Hints — ask first (see DOCUMENTATION TASK).
- Draft a documentation task on a reconciliation-only run that creates zero
  new tasks.
