---
name: task-add
version: 0.2.0
type: command
description: Plan a new task entry conversationally, confirm with the user, then write a summary to TASKS.md and a body file under .claude/tasks/.
---

# /task-add
# Global command: plan a new task entry conversationally, confirm with the
# user, then write a one-block summary to `.claude/TASKS.md` and a full
# body file at `.claude/tasks/<N>.md`. Refuses to run if the backlog has
# not been initialized — the user must run `/task-setup` first.
# Usage: /task-add <free-form description of the task to add>
# Example: /task-add fix the URL normalization so two LinkedIn URLs for the
#          same job dedupe correctly

GOAL
Add a single new task to the project's task backlog, following the
conventions below. The flow is: SETUP-CHECK → READ → ASK
(conversational) → DRAFT → CONFIRM → WRITE. Never write to any file
before the user confirms the draft.

$ARGUMENTS

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to an existing file;
  use the Write tool only when creating a new file from scratch. Never use
  shell redirection, `tee`, `Set-Content`, `Out-File`, or any shell
  mechanism to write files.
- Bash / PowerShell are not needed by this command at all.

---

PHASE 0 — SETUP CHECK (must pass before anything else)

Before reading anything else, verify the backlog has been initialized.
The required artifacts are:
1. `.claude/TASKS.md` — the index file.
2. `.claude/tasks/` — the per-task body directory.

Probe with the Read tool / Glob. If either is missing, do NOT auto-create
anything. Tell the user:

> The task backlog hasn't been initialized in this project. Run
> `/task-setup` first — it creates `.claude/TASKS.md` and the
> `.claude/tasks/` directory. Then re-run `/task-add`.

…and stop. Do not proceed to PHASE 1, do not ask questions, do not draft.
This rule has no exceptions: even if the user supplied a perfectly
unambiguous description, refuse until `/task-setup` has run.

If both artifacts exist, continue.

---

INDEX FILE FORMAT (`.claude/TASKS.md`)

```
# Tasks

Last task number: <N>

---

## <N>. <Title>

Status: [MISSING]
Files: <comma-separated list>
Preconditions: <comma-separated task numbers, or "none">

---

## <M>. <Title>
…
```

The summary block holds only: number, title, Status, Files, Preconditions.
No description, no behavior change, no tests — those live in the per-task
body file.

PER-TASK BODY FILE FORMAT (`.claude/tasks/<N>.md`)

```
# Task <N> — <Title>

## Description
<Plain prose explanation of the problem and the desired behavior. Cite
file paths and line numbers when describing root cause; name the symbols
involved; quote relevant code if it clarifies the bug. Aim for the level
of detail a different engineer could implement from cold.>

### Root cause
<Optional. Bugfixes where the cause is non-obvious.>

### Behavior change
<What the code should do after the task lands. Concrete rules.>

### Doc updates
<Optional but required when behavior touches a documented surface. Name
the affected files and sections; describe what changes.>

### Tests
<Which test files to add/extend and what each new test asserts.>

### Definition of done
- <Bullets — observable outcomes.>
- Full test suite passes.
```

Required body sections: `## Description`. `### Tests` and
`### Definition of done` are required for any code task. Other sections
are included only when they add information.

---

STATUS TAGS (the only allowed values, recorded in TASKS.md)

- `[MISSING]` — behavior not implemented at all. **Default for new tasks.**
- `[STUBBED]` — placeholder/TODO exists but no real implementation.
- `[INCORRECT]` — implemented but diverges from the spec.
- `[PARTIAL]` — implemented in part; some sub-requirements still missing.
- `[IN PROGRESS]` — agent is currently working on it. (Not set by this command.)
- `[DONE]` — implementation has landed. (Not set by this command.)
- `[SKIP]` — explicitly deferred or abandoned.

A new task added by this command is `[MISSING]` unless the user's
description clearly indicates a different pre-implementation state.

---

PHASE 1 — READ (silent)

1. Use the Read tool to open `.claude/TASKS.md`. Note:
   - The current `Last task number: N` value — the new task's ID will be
     `N + 1`.
   - Existing summary blocks: their numbers, titles, statuses, and the
     dependency graph implied by `Preconditions:` lines.
   - Title style ("<Subsystem> — <thing>" vs plain imperatives) — match it.

2. Read enough of the codebase to ground the task:
   - Use Grep / Glob / Read to confirm the actual files involved.
   - If the project has a CLAUDE.md, README.md, or `.claude/context/`
     navigation layer, read what's relevant.
   - Do NOT read other per-task body files in `.claude/tasks/` unless
     you genuinely need their content — TASKS.md gives you the
     dependency graph already.

3. Identify the project's documentation layer and cross-check it against
   the task. Goal: detect every doc that will be out of sync once the
   code change lands. Look for `.claude/domain/`, `docs/`, `SPEC.md`,
   `ARCHITECTURE.md`, design docs named in CLAUDE.md, README sections
   that describe behavior, inline doc comments that serve as specs.

No user-facing output during this phase beyond a single brief sentence
saying what you're reading.

---

PHASE 2 — ASK (conversational)

Same rules as before — ask only about things you cannot resolve from the
code or the user's initial description. 1–4 focused questions max. For
each question, suggest the answer you'd pick and why so the user can
confirm with a single word. Do not produce the draft until every open
question is answered. If there are zero open questions after PHASE 1,
say so in one line and skip to PHASE 3.

Position-in-list questions are usually unnecessary now that task numbers
are stable IDs — new tasks are appended at the end of `TASKS.md` by
default. Only ask about position if the user has clearly indicated they
want the new entry visually grouped with related tasks.

---

PHASE 3 — DRAFT (present for confirmation)

Render the full plan in one message:

```
PLAN — new task

Index file: .claude/TASKS.md
Body file:  .claude/tasks/<N>.md   (N = previous Last + 1)
Position:   appended at end (or "inserted after task M for grouping")

Counter update: Last task number  K → N

Draft summary block (will be written to TASKS.md):
  ---

  ## <N>. <Title>

  Status: [MISSING]
  Files: <files>
  Preconditions: <preconds or "none">

Draft body file (will be written to .claude/tasks/<N>.md):
  # Task <N> — <Title>

  ## Description
  …

  ### Behavior change
  …

  ### Tests
  …

  ### Definition of done
  - …
```

End with a single explicit prompt: **"Approve and write?"**

Wait for the user. Iterate if they request changes — re-present the plan
after any non-trivial revision. Do NOT proceed to PHASE 4 without an
explicit approval ("yes", "go", "write it", "approve", or similar).
Silence is not approval.

---

PHASE 4 — WRITE (only after explicit approval)

1. Use the Edit tool on `.claude/TASKS.md`:
   a. Update the `Last task number: K` line to `Last task number: N`
      where N = K + 1.
   b. Insert the new summary block at the agreed position. The block
      starts with its own `---` separator line above the `## N. Title`
      heading. Preserve the file's existing formatting.

2. Use the Write tool to create `.claude/tasks/<N>.md` with the full
   draft body. This is always a brand-new file — task IDs never repeat,
   so a collision means something is wrong; stop and report instead of
   overwriting.

3. Report to the user:
   - The task ID assigned (= the new `Last task number`).
   - The two paths written: the index file and the new body file.
   - Confirmation that the counter advanced.

DO NOT:
- Write to any file before PHASE 4.
- Renumber existing tasks. Task numbers are stable IDs, so insertions
  never trigger renumbering — only the visual order in TASKS.md may
  change.
- Update any other task's `Preconditions:` line.
- Decrement or otherwise rewrite the counter on a no-op.
- Auto-create `.claude/TASKS.md` or `.claude/tasks/` if they are
  missing — the user must run `/task-setup` first.
- Change the status of any existing task.
- Implement the task. This command only creates the entry.
- Commit. This command does not touch git.
