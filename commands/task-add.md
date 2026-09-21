---
name: task-add
version: 2.5.5
type: command
description: Plan one new task with the user and write it to the backlog — a summary block in TASKS.md plus a body file — from a prose description or from an /architect feature document. Use it for any new unit of work; stage 5 of the pipeline: turns a feature document into tasks; its output is /task-implement's input.
requires: skill:task-engine
---

# /task-add
# Global command: plan a new task entry conversationally, confirm with the
# user, then write a summary block to `.claude/TASKS.md` and a body file at
# `.claude/tasks/<N>.md`. Refuses to run if the backlog has not been
# initialized — the user must run `/task-setup` first. May propose
# splitting the description into multiple tasks when that produces better
# units; pass `--no-split` to always get exactly one task. `--short` skips
# the deep investigation and writes a minimal Goal-only body (mutually
# exclusive with `feature=` and `--single`). With `feature=<slug>`, plans
# from a `/architect` feature document instead of a prose description,
# reconciles tasks that feature already generated ([DONE] never touched),
# tags new tasks `Feature: <slug>`, appends a final documentation-update
# task and sets the feature [PLANNED]; `feature=<slug> --single` attaches
# exactly one task without reconciling. On a project with FEATURES.md a
# free-form run asks at its approval gate whether the task belongs to a
# feature. `--before <N>` / `--after <N>` write the task at that position
# with the `Preconditions:` edge it implies — no existing id moves. Detects
# work needing a human present and authors a Manual interventions section
# with target claude+human or human. A drafted task that names a document
# another pipeline command owns has every design change it implies agreed at
# the approval gate and recorded in its body, so the implementer never has to
# ask. Commits and pushes what it wrote by default.
# Usage: /task-add [--short] [--no-split] [--before <N> | --after <N>] [--no-commit] [--no-push] <free-form description of the task>
#        /task-add feature=<slug> [--no-split] [--before <N> | --after <N>] [--no-commit] [--no-push] [scope-narrowing text]
#        /task-add feature=<slug> --single [--before <N> | --after <N>] [--no-commit] [--no-push] <description of the one task>
# Example: /task-add fix the URL normalization so two LinkedIn URLs dedupe
# Example: /task-add --short document the current deployment method
# Example: /task-add --no-split add CSV export and PDF export commands
# Example: /task-add --before 42 migrate the config format ahead of the loader rewrite
# Example: /task-add feature=session-handling
# Example: /task-add feature=user-profile just the avatar upload
# Example: /task-add feature=user-profile --single reject avatars over 5 MB

GOAL
Add one or more new tasks to the project's task backlog. The flow is:
SETUP-CHECK → READ → SPLIT-CHECK → ASK → DRAFT → CONFIRM → WRITE → COMMIT.

Two input modes share that flow:

- **Free-form** (the default) — a prose description of the work.
- **Feature** (`feature=<slug>`) — plan from the low-level feature document
  `/architect` wrote, and reconcile any tasks that feature already
  generated. This is stage 5 of the product pipeline.

The body's default shape is PER-TASK BODY FILE FORMAT below: Claude
navigates the project at implementation time and needs no more than that.

With `--short`, skip the deep PHASE 1 investigation for a trivial,
low-ambiguity task and write a minimal Goal-only body instead — see the
ARGUMENT NOTE and PER-TASK BODY FILE FORMAT — `--short` mode below.

With `--before <N>` / `--after <N>`, the new task is written at that position
rather than at the end, together with the `Preconditions:` edge the position
implies — see PLACEMENT. With `feature=<slug> --single`, exactly one task is
attached to a `[PLANNED]` feature without re-planning it — see SINGLE-TASK
ATTACHMENT.

Never write to any file before the user confirms the draft.

$ARGUMENTS

ARGUMENT NOTE — the `--no-commit` and `--no-push` flags, and everything they
gate, are
`../skills/task-engine/references/commit.md`.
Scan `$ARGUMENTS` for them before PHASE 1 and strip whichever appear; what
is left, after the flags below are stripped too, is the task description.

Also scan for the optional `--no-split` flag (independent of `--no-commit`,
coexists with it). If present, set NO_SPLIT = true and
strip it; PHASE 1.5 is skipped entirely and exactly one task is always
written. When NO_SPLIT is false (the default), PHASE 1.5 considers whether
a split would produce better units.

Also scan for the optional `--short` flag. If present, set SHORT = true and
strip it. `--short` is for trivial, low-ambiguity tasks where the normal
deep PHASE 1 investigation costs more tokens than the task itself; SHORT
implies NO_SPLIT = true, and what it changes is stated where it applies —
PHASE 1, PHASE 1.5, PHASE 2, PHASE 3, and PER-TASK BODY FILE FORMAT —
`--short` mode. `--short` is mutually exclusive with `feature=<slug>` — it
implies exactly the deep investigation `--short` exists to skip. If `--short`
appears with it, stop with: `--short cannot be combined with feature=<slug>.
Pick one.` `--short` composes normally with `--no-commit` and `--no-push`.

Also scan for the optional `--before <N>` and `--after <N>` flags and strip
whichever appears with its value, setting PLACE = `before` or `after` and
ANCHOR = N. They are mutually exclusive — if both appear, stop with:
`--before and --after cannot be combined. Pick one.` A flag with no value,
or a value that is not a task number, stops with:
`--before and --after need a task number.` Whether N names an existing task
is checked in PHASE 1 step 1, once `TASKS.md` is read; an N matching no task
stops there with the unknown-task message in PLACEMENT. With neither flag,
PLACE is unset; PLACEMENT carries what the flags write and what they compose
with.

Also scan for the optional `--single` flag. If present, set SINGLE = true and
strip it. It is meaningful only beside `feature=<slug>` — without it, stop
with: `--single needs feature=<slug>.` It is mutually exclusive with
`--short`, for the same reason `feature=<slug>` is: it plans against the
feature document, which is the investigation `--short` exists to skip. If
both appear, stop with: `--short cannot be combined with --single. Pick one.`
SINGLE implies NO_SPLIT = true — exactly one task is written. See
SINGLE-TASK ATTACHMENT.

Finally, scan for an optional `feature=<slug>` argument. If present, set
FEATURE = the slug and strip it; it composes with all flags above except
`--short` (see the mutual-exclusion rule above). Whatever free-form text
remains is NOT the task description in this mode — it narrows or annotates
the scope (`feature=user-profile just the avatar upload`), and the feature
document stays the primary source. Under `--single` the remaining text IS
the one task's description, planned against that document. When FEATURE is
unset there is no feature resolution, no reconciliation and no `Feature:`
line; the only feature-aware step of a free-form run is THE ORPHAN QUESTION,
and only on a project that has `.claude/FEATURES.md`.

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
   RECONCILES rather than appends — see PHASE 3. Under SINGLE it never
   does; see SINGLE-TASK ATTACHMENT.

5. When SINGLE is true, the entry's `Status:` must be `[PLANNED]`, the only
   status an attached task leaves true. Otherwise stop:

   > `--single` attaches a task to a `[PLANNED]` feature; `<slug>` is
   > `<status>`.

   followed by `Run /task-add feature=<slug> to plan it.` for `[NEW]` or
   `[ITERATED]`, or `Follow-up work on a finished feature is a free-form
   task.` for `[DONE]`.

---

PHASE 0 — SETUP CHECK (must pass before anything else)

Backlog resolution follows
`../skills/task-engine/references/resolution.md`,
whose `/task-add` note carries every way this command departs from it: the
two-artifact probe this phase makes rather than the index-only check the
other three make, the wording of its not-initialised stop, and that the only
things it resolves from the index are the next task ID, the task a
`--before <N>` / `--after <N>` flag names, and — on a `feature=<slug>` run —
the tasks that feature already generated.

Do not proceed to PHASE 1 until that probe passes — no exceptions.

If all artifacts exist, pull at start per `commit.md`, then continue to
PHASE 1.

---

INDEX FILE FORMAT (`.claude/TASKS.md`)

The index file's shape — the header, the `---` separators, the summary-block
schema, which fields a block holds and which of them is optional, and why
`Last task number` only ever increases — is
`../skills/task-engine/references/resolution.md`
§ *Index file format*. Emit exactly that shape.

This command is the writer of new summary blocks and the only thing that
advances `Last task number`. Everything it writes into a block is fixed by
the phases below: `Status:` from `status.md`, `Target:` from `targets.md`,
`Files:` and `Preconditions:` from PHASE 1 (plus the anchor edge under
`--after`), and `Feature:` only on a `feature=<slug>` run or a task the
orphan question attached. Where the block lands is PLACEMENT's. Description
and decisions never go here — they live in the body.

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
edit targets, test files, documentation, collateral files. Write "none"
explicitly only when nothing collateral genuinely exists.>
- <path/to/file>
- <…>
```

---

TARGET VALUES & MANUAL INTERVENTIONS

The three `Target:` values, what each means at implementation time, the rule
that `claude+human` / `human` and a `## Manual interventions` section always
go together, and that section's shape — the ⚠ warning line, the numbered
checkpoints each anchored to a trigger point and ending in a verifiable
outcome, and the worked Unity example — are
`../skills/task-engine/references/targets.md`.
Its `/task-add` note carries this command's half: it is the **only** writer
of `Target:`, `claude` is its default, and it sets `claude+human` or `human`
only alongside that section — never one without the other.

Authoring that pair is this command's job, and it happens in PHASE 1/2, when
the description or the codebase reveals that part of the work cannot be
executed by an agent (editor-only operations, GUI wizards, hardware). The
section goes between `## Decisions` and `## Hints`, as the body schema above
shows.

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

The status vocabulary — the eight tags and what each means, which are
terminal, and the legal transitions — is
`../skills/task-engine/references/status.md`. Its
`/task-add` note carries what this command does with them.

Here a status is only ever something written onto a task this command
creates or reconciles — never a display filter, never a prune set, never a
task selector. A new task is `[MISSING]` unless the user's description
clearly indicates a different pre-implementation state. This command never
sets `[IN PROGRESS]` or `[DONE]`; during reconciliation it may write
`[SKIP]` on a superseded task, or flip a `[STALE]` one back to `[MISSING]`.

What `[STALE]` means, who sets it and who clears it, is
`../skills/task-engine/references/stale.md`. This
command is its clearer and never its writer: `/architect` sets the tag, and
only a `feature=<slug>` reconciliation here resolves it.

---

PHASE 1 — READ (silent)

**When SHORT is true**, this phase is reduced to the minimum needed to fill
the `Files:` line: step 1 below, and step 2 using light Grep/Glob only (no
Read of CLAUDE.md, `.claude/context/`, or `.claude/domain/` files for
grounding — the whole point of `--short` is skipping that investigation).
Step 3 (Hints) does not apply, since the short-form body omits
`## Hints`. Step 4 (Decisions)
still applies, but only for non-obvious choices visible from the
description and the light scan — not from a deep read `--short` skips.
Step 4b still applies if the light scan or the description itself surfaces
a manual-intervention need. Continue straight to PHASE 1.5 (skipped, as
under `--no-split`) and then PHASE 2.

1. Read `.claude/TASKS.md`. Note:
   - The current `Last task number: N` value — new task ID = N + 1.
   - Title style in existing tasks — match it.
   - When PLACE is set, task ANCHOR's summary block and its current
     `Preconditions:` line. No such block → stop, per PLACEMENT.
   - On a free-form run without `--short`, whether `.claude/FEATURES.md`
     exists. If it does, read it, read-only, for THE ORPHAN QUESTION's slug
     list; if it does not, say nothing about it.

1b. **When FEATURE is set**, read the feature document resolved above and
   treat it as the PRIMARY context source — the way `/task-implement`
   treats a task body. It already contains the purpose, scope and
   non-goals, architecture, data and state, interfaces, dependencies, and
   open questions. Fan out to CLAUDE.md, `.claude/context/`, and other
   `.claude/domain/` files only where the document does not cover what you
   need; do not re-derive from source what the document already states.

   Then, if the entry's `Tasks:` line is non-`none` and SINGLE is false,
   read each listed task's TASKS.md summary block AND its
   `.claude/tasks/<N>.md` body. You
   cannot classify a task you have not read, and PHASE 3 must classify
   every one of them. An ID with no summary block is archived and
   terminal, per `resolution.md` § *The archive*: reconciliation leaves it
   unclassified, reads no body for it, and does not treat it as an error.
   PHASE 4 keeps it on the `Tasks:` line.

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

Position questions are unnecessary by default — new tasks are appended at
the end, and `--before <N>` / `--after <N>` are how a position is expressed
when one matters (see PLACEMENT). Only ask about position if the user has
signalled they want the task somewhere specific without passing either
flag; then ask which task it goes before or after, and apply the answer
exactly as the matching flag would — position and edge together.

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
Feature status: [NEW] → [PLANNED]        (or [ITERATED] → [PLANNED];
                                          under --single: [PLANNED], unchanged)
Scope note:     <the free-form narrowing text, if any>
```

Then, when that feature already has tasks and SINGLE is false, render a
RECONCILIATION section BEFORE the new drafts (see RECONCILIATION below).

The plan is a **digest** of what was drafted, not the draft itself: the
heading, the target, the goal, the decisions, and the manual interventions
when there are any. Those are what the user can weigh before the task
exists. Everything else — the summary block's fields, the acceptance
criteria, the Hints — is drafted in full exactly as PER-TASK BODY FILE
FORMAT specifies and written by PHASE 4, whose report names the task ID(s),
both paths and the counter advance.

When SPLIT is none (the common case), render one digest:

```
PLAN — new task

## <N>. <Title>

Target: <claude|claude+human|human>

## Goal
…

## Decisions              ← omit section if no non-obvious choices
- …

## Manual interventions   ← only when Target is claude+human or human;
…                           rendered in full when it is
```

**When SHORT is true** (SPLIT is always none in this mode, per PHASE 1.5),
the digest has the same shape over the shorter body PER-TASK BODY FILE
FORMAT — `--short` mode defines.

When SPLIT is set (multiple parts), render one digest per part in write
order, in one message, using sequential IDs starting at `previous Last + 1`,
under a single `Order:` line naming those IDs in that order — the sequence
the parts land in is itself being approved:

```
PLAN — N new tasks (split)

Order: <N>, <N+1>, … <N+k-1>

Part 1/k

## <N>. <Title>

Target: <claude|claude+human|human>

## Goal
…

## Decisions              ← omit section if no non-obvious choices
- …

## Manual interventions   ← only when Target is claude+human or human;
…                           rendered in full when it is

... (repeat for each remaining part) ...
```

**When FEATURE is set** and at least one new task was drafted above (single
or split), also render the documentation task's draft here, last, using the
next sequential ID after the others. See DOCUMENTATION TASK below for its
content, and DESIGN-CHANGE CHECK for the question that accompanies it when
it diverges from an owned document. Skip this entirely on a
reconciliation-only run that drafts zero new tasks.

When PLACE is set, add one line at the top of the plan, under the heading
and any `Order:` line, so the position — and, under `--before`, the edit to
the anchor task — is approved with the rest:

```
Placement:  before task <ANCHOR> — task <ANCHOR> Preconditions: <old> → <new>
            (or: after task <ANCHOR> — new task waits on <ANCHOR>)
```

That line and `Order:` are the only wiring the gate shows.

Before the closing prompt, render the design-change question for every
drafted task that diverges from an owned document — see DESIGN-CHANGE CHECK.
On a free-form run, render THE ORPHAN QUESTION here too, under the same rule.

End with: **"Approve and write?"**

This is the run's only gate: the reconciliation, the design-change question
and the orphan question are all answered in this same exchange, never at a
second one. Wait for explicit approval. Iterate on changes and re-present
the full plan (all parts, when split) after any non-trivial revision.
Silence is not approval.

---

RECONCILIATION (only when FEATURE is set, SINGLE is false, and its `Tasks:`
line is non-`none`)

A re-planning run must not append blindly — that reliably produces
overlapping work.

The four-way classification itself, the standing preference for
update-in-place over skip-and-replace, and the rule that `[DONE]` is
untouchable are
`../skills/task-engine/references/stale.md`
§ *Clearing it*. This command is the only feature that applies them.

What is this command's own is when and how they are applied: classify EVERY
existing task read in PHASE 1b — not a sample, not the `[STALE]` ones only —
and present the classification in PHASE 3 with a one-line reason each, so the
user can overrule any call inside the same approval.

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

---

DOCUMENTATION TASK (feature mode only)

Applies only when FEATURE is set, and only when this run drafts at least
one new task. A reconciliation-only run that leaves every existing task
untouched creates nothing new to document, so this section does not fire.
It does not fire on a `--single` run either, nor on a free-form task the
orphan question attached: one attached task is not a planning pass.

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

Some of that collateral is owned by another command in this pipeline. Naming
one of those documents here is allowed but never free: DESIGN-CHANGE CHECK
below governs it, and the documentation task is its worked example.

---

PLACEMENT (only when `--before <N>` or `--after <N>` was passed)

By default a new task is appended at the end of `.claude/TASKS.md`. The two
placement flags write it somewhere else, and each writes two things at once:

- **`--before <N>`** — the new summary block goes immediately above task N's,
  and the new task's ID is appended to task N's `Preconditions:` line
  (replacing `none` when that is what it held). Task N now waits on the new
  task.
- **`--after <N>`** — the new summary block goes immediately below task N's,
  and N goes on the new task's own `Preconditions:` line, beside whatever
  PHASE 1 put there (replacing `none`). The new task now waits on task N.

**Why both halves, always together.** The position is for the human reading
`TASKS.md` top to bottom; the edge is for the selectors, which pick work by
appearance order *and* by satisfied `Preconditions:` —
`../skills/task-engine/references/resolution.md`
§ *Selectors*. A position without the edge lets a selector start the two
tasks in the other order the moment both are eligible; an edge without the
position leaves the file reading one order while the selectors follow
another. Either half alone leaves the two disagreeing, so there is no flag
for one without the other.

**Unknown N.** PHASE 1 step 1 confirms a summary block `## <N>.` exists. If
none does, stop — the unknown-task counterpart of the unknown-slug stop:

> No task `<N>` in `.claude/TASKS.md`.

N may carry any status. On a `[DONE]` or `[SKIP]` task the edge changes no
selection, but it is written all the same, so position and edge never
disagree. Under `--before <N>`, never also put N on the new task's own
`Preconditions:` — that is a two-task cycle, and the selectors would report
both tasks blocked for good.

**IDs do not move.** An insertion consumes the next ID from
`Last task number:` exactly as an append does. No existing task is
renumbered or moved, and a higher ID sitting above a lower one is the
expected result, not something to tidy. Moving an existing task is a
revision, not an insertion, and is not this command's job.

**Composition.** Either flag composes with `--short`, `--no-split`,
`--no-commit`, `--no-push`, `feature=<slug>` and `--single`. When the run
writes more than one new task — a split, or a `feature=<slug>` run's drafts
with its documentation task last — the flag applies to the first of them,
and the remaining ones follow it in order: they are written as one run, in
their usual order, occupying the single block's place (immediately above
N's block under `--before`, immediately below it under `--after`). The edge
is written for the first task alone — under `--before`, N gains the first
new ID; under `--after`, the first new task gains N — and the others carry
their own `Preconditions:` wiring as usual.

A task carrying a `Feature:` line may land among another feature's tasks, or
among free-form ones. That is legal: reconciliation keys on the `Feature:`
line, never on position.

---

SINGLE-TASK ATTACHMENT (`feature=<slug> --single`)

`/task-add feature=<slug> --single "<description>"` plans exactly one task
against the named feature's document and attaches it to that feature,
without re-planning the feature. The description is this one task's; the
feature document is still PHASE 1b's primary context, so the task is
grounded in the design.

What it writes:

- the one task, whose summary block carries `Feature: <slug>` and whose body
  names the feature in `## Goal` and its document under `## Hints`, exactly
  like any feature-derived task;
- the feature's `FEATURES.md` `Tasks:` line, with the new ID appended
  (ascending).

What it does not do:

- **No reconciliation.** It runs no reconciliation over the feature's other
  tasks: PHASE 1b does not read them, and PHASE 3 renders no RECONCILIATION
  section. Whether they still match the design is a question for the next
  full `/task-add feature=<slug>` run, not this one.
- **No status change.** The feature's `FEATURES.md` `Status:` is untouched —
  a `[PLANNED]` feature with one more planned task has not changed its
  design-to-backlog relationship. That is also why only a `[PLANNED]`
  feature takes an attached task (FEATURE RESOLUTION step 5): a `[NEW]`
  feature has no tasks by definition, and a `[DONE]` one would be left
  claiming every task is done with one open.
- **No documentation task** — see DOCUMENTATION TASK.
- **No split.** SINGLE implies NO_SPLIT; exactly one task is written.

**The write-back line.** PHASE 4's report always ends with this one fixed
line, so the drift is announced when it is created rather than discovered
later:

> Feature document `<the entry's Doc: path>` was not updated for task <N> —
> `/pipeline-revise feature=<slug> "<what task <N> adds>"` writes it back.

That line is all this command does about the document.

---

THE ORPHAN QUESTION (free-form runs, only when `.claude/FEATURES.md` exists)

Asked only when FEATURE is unset, SHORT is false, and `.claude/FEATURES.md`
exists; on a project without that file the question is not asked and nothing
is said about it. It is not asked under `--short` either: its only non-`none`
answer is the `--single` path, which `--short` cannot take.

Just before **"Approve and write?"**, render:

> Does this task belong to a feature?
>
>   `<slug-a>` — <title>
>   `<slug-b>` — <title>
>   none — keep it free-form (the default)

listing every `[PLANNED]` entry in `.claude/FEATURES.md`, in index order —
the only status an attached task leaves true. When no entry is `[PLANNED]`
there is nothing to attach to, and the question is not asked.

- **A slug** takes the `--single` path for that feature: read the entry's
  `Doc:` as PHASE 1b's primary context, revise the draft against it (the
  `Feature:` line, the Goal naming the feature, the document under Hints),
  and re-present the plan at the same gate. From then on SINGLE-TASK
  ATTACHMENT applies in full, the write-back line included. The question is
  asked on every free-form run, a split included; on a split plan every part
  is attached the same way, and the write-back line names every attached ID.
- **none** — or an approval that does not address the question — writes
  the task as a free-form task, with no `Feature:` line.

---

DESIGN-CHANGE CHECK

Applies to **every task this run drafts** — the documentation task, a single
free-form task, each part of a split, and any existing body rewritten during
reconciliation. What it catches is a task whose implementation would change a
design the user has not seen changed: the user agrees to the design change at
the gate, or the task is redrawn. A document is never kept wrong on purpose,
and a path is never marked read-only.

**Detection.** These paths are owned by another command in this pipeline. This
table is the sole source of ownership — do not try to derive it from a
project's domain layer, which most projects do not carry:

| Path | Owner |
| --- | --- |
| `.claude/domain/features/*.md` | `/architect` |
| `.claude/domain/product-design.md`, `technical-direction.md`, `business-model.md` | `/product-design` |
| `.claude/domain/product-roadmap.md` | `/product-roadmap` |
| `.claude/PLAN.md` | `/production-plan` |

`.claude/FEATURES.md` and `.claude/TASKS.md` are **excluded**: they are split by
line rather than by file, and this command is itself one of their writers.

Run the check against both the drafted `## Hints` and the summary block's
`Files:` line, for every task drafted in this run. A path matching a row above
is a *detected file*.

**Enumeration.** For each detected file, list the points at which the task's
implementation touches what the document says — numbered, one line or two
each, each naming the passage it lands on. "Review this document for drift" is
not a point. Every point is one of two kinds:

- **settles** — the document leaves the matter open (an open question, an
  unstated detail, a choice the design defers to implementation) and the task
  decides it. No conflict with the design.
- **diverges** — the document states one thing and the task will do another.
  A design change.

A detected file with no points is a path in `## Hints` like any other.

**The question.** Asked only when at least one point diverges, at PHASE 3 —
one block per task, every detected file's diverging points together, settling
points listed beneath for the record:

> Task `<N>` as drafted changes the design at these points:
>
>   1. `<path>` § <section>: <before> → <after> — <one line of context>
>   2. …
>
> Agree?
>
> It also settles, without conflict: <path> § <section> — <the point>.

A task whose points all settle asks nothing; its settled points still go into
the body below.

**Agreement.** The design change is agreed as a whole, not passage by passage:
the implementer updates every passage of the document that states the old
design, the enumerated ones included, and introduces no meaning beyond the
agreed change. The path stays in `## Hints` and joins `Files:`. Write it into
the drafted body before PHASE 4 — `## Acceptance criteria`:

> - `<path>` states the agreed design change — <the change in one line> — in
>   every passage that stated the old one, and settles <the settled points>.
>   Nothing else in the document changes.

and `## Decisions`:

> - **Design change agreed (user decision, `<YYYY-MM-DD>`):** <one line per
>   diverging point>. Settled here: <one line per settling point>. `<path>` is
>   normally `<owner>`'s; this task updates it for exactly this and for nothing
>   else. A further design decision met at implementation time is not
>   covered: leave that passage untouched and name it under *Needs you* as a
>   precise follow-up.

`<YYYY-MM-DD>` is the date of this `/task-add` run. A task with settling
points only records them the same way, without the user-decision marker.

**Disagreement.** The task, not the document, is wrong: it is heading
somewhere the user does not want. Return to PHASE 2 with the diverging points
as the open questions, redraft, and re-present the plan at the same gate.

**Hard rules.**

- A diverging point is never written as agreed without an explicit answer.
  Silence is not agreement, and neither is an approval that does not address
  the question: re-ask and wait rather than assume.
- PHASE 4 never writes a task with an unanswered diverging point. If it would,
  stop the run and report — write nothing.
- **Agreement does not make this command a writer.** `/task-add` never edits
  an owned document itself; the agreement authorises the *implementer of the
  task it drafts*, at implementation time. One writer per artifact holds for
  the pipeline commands.
- A body rewritten — reconciliation here, or an amendment under
  `../skills/task-engine/references/amend.md` — re-runs the check only on
  the points the rewrite adds; an agreement already recorded in
  `## Decisions` stands.

---

PHASE 4 — WRITE (only after explicit approval)

Task IDs never repeat — a collision is an error; stop and report.

Single-task case (SPLIT is none):

1. Edit `.claude/TASKS.md`:
   a. Update `Last task number: K` → `Last task number: N`.
   b. Insert the new summary block, with its `---` separator, at the
      resolved position — the end of the file by default, or where
      PLACEMENT puts it.
   c. Under `--before <ANCHOR>`, append N to task ANCHOR's
      `Preconditions:` line (replacing `none`) — the one edit this command
      makes to another task's line.

2. Write `.claude/tasks/<N>.md` with the full draft body.

3. Report: task ID, both paths written, counter advanced.

Split case (SPLIT is set, k parts):

1. Edit `.claude/TASKS.md` once:
   a. Update `Last task number: K` → `Last task number: K+k`.
   b. Insert all k summary blocks in order, each with its own `---`
      separator, using sequential IDs `K+1 .. K+k`, at the resolved
      position — the end of the file by default, or as one run where
      PLACEMENT puts the first of them.
   c. Under `--before <ANCHOR>`, append `K+1` — the first part's ID — to
      task ANCHOR's `Preconditions:` line, as in the single-task case.

2. Write each `.claude/tasks/<N>.md` body file, one per part, `N` ranging
   over `K+1 .. K+k`. A part that depends on an earlier part gets that
   earlier part's ID in its `Preconditions:` line; a part with no
   dependency gets `none`.

3. Report: all task IDs written, all paths, counter advanced by k.

Feature case (FEATURE is set) — in addition to the above:

1. Every new summary block carries `Feature: <slug>` as its last field.
   Existing tasks being updated in place already have it; do not add it to
   a task that lacks it unless that task belongs to this feature.

2. Every new body's `## Goal` names the originating feature, and its
   document path appears under `## Hints` — the implementer should be able
   to reach the design from the task without being told the slug
   separately. It is an edit target only for what DESIGN-CHANGE CHECK
   recorded in the body.

3. Apply the approved reconciliation, and nothing beyond it (under SINGLE
   there is none, so this step does nothing):
   - Rewrite the body of each task classified "update in place", and flip a
     `[STALE]` one back to `[MISSING]` in TASKS.md.
   - Set each "substantially invalidated" task's `Status:` to `[SKIP]`, and
     record the one-line reason from the plan in its body so a later reader
     knows why. The replacement task is written as a new task.
   - Touch nothing on a task classified "untouched", and nothing at all on
     a `[DONE]` task.

4. Update the feature's entry in `.claude/FEATURES.md`, writing exactly two
   fields:
   - `Tasks:` — the surviving IDs, the archived IDs PHASE 1b left
     unclassified, and the newly created ones, ascending. Drop the IDs of
     tasks this run marked `[SKIP]`; keep `[DONE]` IDs.
   - `Status:` — `[PLANNED]`, from either `[NEW]` or `[ITERATED]`.

   Under SINGLE, or for a task the orphan question attached, write
   `Tasks:` alone — the existing IDs plus the new one(s), ascending — and
   leave `Status:` exactly as it is.

   Never write `Doc:` or `Source:` — those are `/architect`'s fields, and
   the by-line split is what lets the two commands share this file.

5. The feature document `.claude/domain/features/<slug>.md` is not this
   command's to edit — DESIGN-CHANGE CHECK's hard rules are why. If planning
   revealed a genuine design problem in it, say so in the report and let the
   user re-run `/architect`.

6. If a documentation task was drafted (see DOCUMENTATION TASK), write its
   summary block and body exactly like any other new task, using the next
   sequential ID after the others — the counter update from step 1a/2a
   above must already include this ID (e.g. single-task case:
   `Last task number K → N+1`, not `→ N`; split case:
   `Last task number K → K+k+1`, not `→ K+k`). Include its path in the
   report and the commit alongside the rest. Never under SINGLE.

7. Under SINGLE, or for a task the orphan question attached, end the report
   with the write-back line from SINGLE-TASK ATTACHMENT.

Continue to PHASE 5.

---

PHASE 5 — COMMIT AND PUSH

Commit and push gating — the flags, pull-at-start, staging by explicit path,
one commit per unit of work, the push protocol, and what to do when a commit
or a push fails — is
`../skills/task-engine/references/commit.md`. Its
`/task-add` note carries this command's own specifics: the four
commit-message forms — single task, split, feature, attached — one commit each, exactly
which paths PHASE 4 leaves to stage in each case, and that PHASE 5 is the only
phase here that shells out.

Under `--no-commit` this phase runs none of it: the files PHASE 4 wrote stay
uncommitted, reported with their task ID(s) and paths. Otherwise the commit
happens automatically once PHASE 4 completes, with no further prompt here.

---

DO NOT:
- Auto-create `.claude/TASKS.md` or `.claude/tasks/` if missing —
  `resolution.md` § *When the backlog is not initialised* is the rule, and
  PHASE 0's stop is the whole response.
- Implement the task. This command only creates the entry.
- Edit any document under `.claude/domain/`. They are read-only here.
- Add a `Feature:` line to a task that did not come from that feature and
  was not attached to it by `--single` or the orphan question, or write
  `Feature: none` on a free-form task — `resolution.md` § *Index file
  format* is why its absence is the signal.
