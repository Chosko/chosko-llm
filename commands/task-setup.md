---
name: task-setup
version: 0.1.0
type: command
description: Initialize the project's task backlog — creates .claude/TASKS.md and the .claude/tasks/ directory.
---

# /task-setup
# Global command: initialize the project's task backlog. Creates the
# `.claude/TASKS.md` index file and the `.claude/tasks/` directory where
# per-task body files live. Idempotent: a re-run on an already-initialized
# project reports the existing layout and does nothing.
# Usage: /task-setup

GOAL
Create the two artifacts that the rest of the task-* commands assume:
1. `.claude/TASKS.md` — the lightweight index (one summary block per task,
   plus a counter for the highest task number ever assigned).
2. `.claude/tasks/` — the directory where each task's full body lives in
   `<N>.md` (one file per task ID).

This command is the gate for `/task-add`. `/task-add` will refuse to run
until both artifacts exist.

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Write tool to create new files. Never use shell
  redirection, `tee`, `Set-Content`, or `Out-File`.
- Bash / PowerShell are only used to create the `.claude/` and
  `.claude/tasks/` directories (`mkdir -p`).

---

WORKFLOW

1. Check whether `.claude/TASKS.md` already exists (use the Read tool — a
   "file not found" error means it does not). Check whether
   `.claude/tasks/` exists (use Glob `.claude/tasks/*` or list it).

2. If both already exist, tell the user "Backlog already initialized at
   `.claude/TASKS.md` (with task directory `.claude/tasks/`)." and stop.
   Do not overwrite or modify anything.

3. If only one of the two exists, create the missing artifact (do not
   touch the existing one), then report what was created and what was
   already present.

4. If neither exists:
   a. Create the `.claude/` directory if it does not exist
      (`mkdir -p .claude/tasks` from Bash creates both at once).
   b. Use the Write tool to create `.claude/TASKS.md` with this exact
      stub content:

      ```
      # Tasks

      Last task number: 0
      ```

      No trailing task entries. The first task added will sit below this
      header.

5. Report to the user:
   - The path of the index file created.
   - The path of the tasks directory created.
   - A one-line hint that `/task-add` is now usable.

---

INDEX FILE FORMAT (for reference — `/task-add` and `/task-clean` are
the writers)

```
# Tasks

Last task number: <N>

---

## <N>. <Title>

Status: [MISSING]
Files: <comma-separated files>
Preconditions: <comma-separated task numbers, or "none">

---

## <M>. <Title>
...
```

The `Last task number` line tracks the highest ID ever assigned. It only
ever increases — `/task-clean` removes survivors but never decrements it.
That guarantees task numbers are stable IDs across the project's lifetime.

PER-TASK BODY FILE FORMAT (for reference — `/task-add` writes these,
`/task-implement` reads them)

`.claude/tasks/<N>.md`:

```
# Task <N> — <Title>

## Description
<Plain prose explanation …>

### Root cause
<Optional. Bugfixes when non-obvious.>

### Behavior change
<Concrete rules.>

### Doc updates
<Optional. Required when behavior changes touch a documented surface.>

### Tests
<Test files and assertions.>

### Definition of done
- <Bullets.>
- Full test suite passes.
```

The per-task file contains body content only. The tracking metadata
(Status, Files, Preconditions, Title) lives in `TASKS.md` so that
`/task-list` and status flips do not need to open the body file.

---

DO NOT:
- Create any task entries — `/task-setup` only creates the empty
  scaffolding. The first task is added by `/task-add`.
- Overwrite an existing `TASKS.md` or any `.claude/tasks/<N>.md` file.
- Commit. The user decides whether to commit the scaffolding.
