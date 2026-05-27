---
name: task-add
version: 0.6.0
type: command
description: Plan a new task entry conversationally, confirm with the user, write a summary block and body file, then auto-commit. Pass --enrich to produce a self-contained body for a local LLM in one shot.
---

# /task-add
# Global command: plan a new task entry conversationally, confirm with the
# user, then write a summary block to `.claude/TASKS.md` and a body file at
# `.claude/tasks/<N>.md`. Refuses to run if the backlog has not been
# initialized — the user must run `/task-setup` first.
# Usage: /task-add [--enrich] <free-form description of the task>
# Example: /task-add fix the URL normalization so two LinkedIn URLs dedupe
# Example: /task-add --enrich add CSV export command

GOAL
Add a single new task to the project's task backlog. The flow is:
SETUP-CHECK → READ → ASK → DRAFT → CONFIRM → WRITE → COMMIT.

By default, the body contains: Goal, Acceptance criteria, Decisions (when
applicable), and Hints. Claude navigates the project at implementation time
and does not need more.

With `--enrich`, produce a self-contained body for a local LLM implementer
in one shot — read `skills/task-enrich/SKILL.md` for the enriched format and
apply it directly during authoring. Do not write a plain body first and then
enrich it.

Never write to any file before the user confirms the draft.

$ARGUMENTS

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to an existing file;
  use the Write tool only when creating a new file from scratch. Never use
  shell redirection, `tee`, `Set-Content`, `Out-File`, or any shell
  mechanism to write files.
- Bash / PowerShell are used ONLY by PHASE 5 (the commit step):
  `git add -- <path> <path>` and `git commit`. No other phases shell out.

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
`skills/task-enrich/SKILL.md` exists. If it does not, stop:

> `/task-add --enrich` requires the task-enrich skill to be installed.
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

## Hints
<Required. Always present. File paths the implementer should touch:
edit targets, test files, documentation, collateral files. Write
"none" explicitly only when nothing collateral genuinely exists.>
- <path/to/file>
- <…>
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

In `--enrich` mode, read `skills/task-enrich/SKILL.md` for the detailed
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

5. **`--enrich` mode only:** also read `skills/task-enrich/SKILL.md`
   for the enriched body format. Gather additional material for
   `## Context bundle` (relevant excerpts) and `## Implementation steps`
   (step-by-step guidance). Be selective — include only what is necessary.

No user-facing output during this phase beyond a single brief sentence
saying what you're reading.

---

PHASE 2 — ASK (conversational)

Ask only about things you cannot resolve from the code or the user's
description. 1–4 focused questions max. Suggest the answer you'd pick and
why so the user can confirm with a single word.

If there are zero open questions after PHASE 1, say so in one line and
skip to PHASE 3.

Position questions are unnecessary — new tasks are appended at the end
by default. Only ask about position if the user has signalled they want
grouping.

---

PHASE 3 — DRAFT (present for confirmation)

Render the full plan in one message:

```
PLAN — new task

Index file: .claude/TASKS.md
Body file:  .claude/tasks/<N>.md   (N = previous Last + 1)

Counter update: Last task number  K → N

Draft summary block:
  ---

  ## <N>. <Title>

  Status: [MISSING]
  Target: <claude|local>
  Files: <comma-separated list>
  Preconditions: <preconds or "none">

Draft body:
  # Task <N> — <Title>

  Target: <claude|local>

  ## Goal
  …

  ## Acceptance criteria
  - …

  ## Decisions              ← omit section if no non-obvious choices
  - …

  ## Hints
  - …

  ## Context bundle         ← --enrich mode only
  …

  ## Implementation steps   ← --enrich mode only
  …
```

End with: **"Approve and write?"**

Wait for explicit approval. Iterate on changes and re-present the full
plan after any non-trivial revision. Silence is not approval.

---

PHASE 4 — WRITE (only after explicit approval)

1. Edit `.claude/TASKS.md`:
   a. Update `Last task number: K` → `Last task number: N`.
   b. Append the new summary block with its `---` separator.

2. Write `.claude/tasks/<N>.md` with the full draft body.
   Task IDs never repeat — a collision is an error; stop and report.

3. Report: task ID, both paths written, counter advanced.

Continue to PHASE 5.

---

PHASE 5 — COMMIT

1. Run:
   ```
   git add -- .claude/TASKS.md .claude/tasks/<N>.md
   git commit -m "Add task <N>: <title>"
   ```

2. On success, report the commit hash (`git rev-parse --short HEAD`).

3. On failure: surface the exact output. Do NOT retry, amend, or use
   `--no-verify`. Files remain staged but uncommitted; tell the user.

PHASE 5 stages ONLY the two files PHASE 4 wrote. Never use `git add -A`,
`git add .`, or `git add -u`.

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
