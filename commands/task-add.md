---
name: task-add
version: 0.9.1
type: command
description: Plan a new task entry conversationally, confirm with the user, write a summary block and body file, then auto-commit. Detects work needing manual human steps (e.g. game-engine editors) and authors a Manual interventions section with target claude+human or human. Pass --enrich to produce a self-contained body for a local LLM in one shot, --no-split to always write exactly one task, or --no-commit to write the files but skip the commit.
---

# /task-add
# Global command: plan a new task entry conversationally, confirm with the
# user, then write a summary block to `.claude/TASKS.md` and a body file at
# `.claude/tasks/<N>.md`. Refuses to run if the backlog has not been
# initialized — the user must run `/task-setup` first. May propose
# splitting the description into multiple tasks when that produces better
# units; pass `--no-split` to always get exactly one task.
# Usage: /task-add [--enrich] [--no-split] [--no-commit] <free-form description of the task>
# Example: /task-add fix the URL normalization so two LinkedIn URLs dedupe
# Example: /task-add --enrich add CSV export command
# Example: /task-add --no-split add CSV export and PDF export commands

GOAL
Add one or more new tasks to the project's task backlog. The flow is:
SETUP-CHECK → READ → SPLIT-CHECK → ASK → DRAFT → CONFIRM → WRITE → COMMIT.

By default, the body contains: Goal, Acceptance criteria, Decisions (when
applicable), and Hints. Claude navigates the project at implementation time
and does not need more.

With `--enrich`, produce a self-contained body for a local LLM implementer
in one shot — read `commands/task-enrich.md` for the enriched format and
apply it directly during authoring. Do not write a plain body first and then
enrich it.

Never write to any file before the user confirms the draft.

$ARGUMENTS

ARGUMENT NOTE — before PHASE 1, scan $ARGUMENTS for the optional
`--no-commit` flag (independent of `--enrich`). If present, set
NO_COMMIT = true and strip it; the rest is the task description.
`--commit` and `--no-commit` are mutually exclusive — if both appear, stop
with: `--commit and --no-commit cannot be combined. Pick one.` When
NO_COMMIT is false (the default), PHASE 5 auto-commits as before.

Also scan for the optional `--no-split` flag (independent of `--enrich` and
`--no-commit`, coexists with both). If present, set NO_SPLIT = true and
strip it; PHASE 1.5 is skipped entirely and exactly one task is always
written. When NO_SPLIT is false (the default), PHASE 1.5 considers whether
a split would produce better units.

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

---
```

The summary block holds: number, title, Status, Target, Files, Preconditions.
Nothing else. Description and decisions live in the body.

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

STATUS TAGS (the only allowed values, recorded in TASKS.md)

- `[MISSING]` — behavior not implemented at all. **Default for new tasks.**
- `[STUBBED]` — placeholder/TODO exists but no real implementation.
- `[INCORRECT]` — implemented but diverges from the spec.
- `[PARTIAL]` — implemented in part; some sub-requirements still missing.
- `[IN PROGRESS]` — agent is currently working on it. (Not set by this command.)
- `[DONE]` — implementation has landed. (Not set by this command.)
- `[SKIP]` — explicitly deferred or abandoned.

A new task is `[MISSING]` unless the user's description clearly indicates
a different pre-implementation state.

---

PHASE 1 — READ (silent)

1. Read `.claude/TASKS.md`. Note:
   - The current `Last task number: N` value — new task ID = N + 1.
   - Title style in existing tasks — match it.

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

PHASE 1.5 — SPLIT CHECK (skipped entirely when NO_SPLIT is true)

Using the grounded picture from PHASE 1, judge whether the description
would produce better units as multiple tasks — either because it bundles
independent deliverables (e.g. "add CSV export and PDF export"), or
because a single task covering it would simply be too large/sprawling to
implement, test, and commit as one coherent unit. This is a judgment call,
not a rule: most descriptions are fine as one task, and this step should
stay silent for them.

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

End with: **"Approve and write?"**

Wait for explicit approval. Iterate on changes and re-present the full
plan (all parts, when split) after any non-trivial revision. Silence is
not approval.

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

Continue to PHASE 5.

---

PHASE 5 — COMMIT

This is the only phase that shells out: `git add -- <path> <path>` and
`git commit`. No other phase runs a shell command, and under `--no-commit`
this phase runs none either.

If NO_COMMIT is true, skip committing entirely: the files PHASE 4 wrote
(one task's two files, or all of a split's files) are left uncommitted in
the working tree. Report the task ID(s), all paths, and a reminder that
nothing was committed — the user should commit when ready. Do not run any
git command. Then stop.

Otherwise (the default):

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

2. On success, report the commit hash (`git rev-parse --short HEAD`).

3. On failure: surface the exact output. Do NOT retry, amend, or use
   `--no-verify`. Files remain staged but uncommitted; tell the user.

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
- Push, branch, tag, or otherwise touch shared/visible git state.
- In `--enrich` mode, write a plain body first and then enrich it separately.
- Propose a split for work that's fine as one task — PHASE 1.5 stays quiet
  unless a split genuinely produces better units.
- Set `Target: claude+human` or `human` without a `## Manual interventions`
  section, or write that section under any other target — the two always
  go together.
- Bundle multiple commits for a split — PHASE 5 makes exactly one commit
  covering all parts.
- Run PHASE 1.5 at all when `--no-split` is passed.
