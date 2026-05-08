---
name: task-setup
version: 0.2.0
type: command
description: Initialize the project's task backlog — creates .claude/TASKS.md, the .claude/tasks/ directory, and the external implement-prompt at .claude/external/implement-prompt.md.
---

# /task-setup
# Global command: initialize the project's task backlog. Creates the
# `.claude/TASKS.md` index file, the `.claude/tasks/` directory where
# per-task body files live, and `.claude/external/implement-prompt.md` —
# the static system prompt for an external LLM (aider + Ollama)
# implementing tasks from the backlog. Idempotent: a re-run leaves
# existing artifacts untouched and only creates the missing ones.
# Usage: /task-setup

GOAL
Create the three artifacts that the rest of the task-* workflow assumes:
1. `.claude/TASKS.md` — the lightweight index (one summary block per task,
   plus a counter for the highest task number ever assigned).
2. `.claude/tasks/` — the directory where each task's full body lives in
   `<N>.md` (one file per task ID).
3. `.claude/external/implement-prompt.md` — the static prompt template
   that an external LLM (target: qwen2.5-coder:14b via aider) is fed
   alongside a task body file. Travels with the project via git so a
   teammate can clone-and-run.

This command is the gate for `/task-add`. `/task-add` will refuse to run
until artifacts 1 and 2 exist.

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Write tool to create new files. Never use shell
  redirection, `tee`, `Set-Content`, or `Out-File`.
- Bash / PowerShell are only used to create directories
  (`mkdir -p .claude/tasks`, `mkdir -p .claude/external`).

---

WORKFLOW

For each of the three artifacts, check whether it already exists and
create it if missing. Never overwrite an existing artifact — re-running
`/task-setup` on a partially or fully initialized project must be
idempotent.

1. **Probe the three artifacts:**
   - `.claude/TASKS.md` — use the Read tool; "file not found" means it
     does not exist.
   - `.claude/tasks/` — use Glob `.claude/tasks/*` or list it.
   - `.claude/external/implement-prompt.md` — use the Read tool.

2. **Create whichever are missing:**
   - If `.claude/TASKS.md` is missing, use the Write tool to create it
     with this exact stub content:

     ```
     # Tasks

     Last task number: 0
     ```

     No trailing task entries. The first task added will sit below this
     header.

   - If `.claude/tasks/` is missing, create it (`mkdir -p .claude/tasks`).

   - If `.claude/external/implement-prompt.md` is missing, create the
     parent directory if needed (`mkdir -p .claude/external`) then use
     the Write tool to write the template. The exact content to write is
     the literal block in the **EXTERNAL IMPLEMENT-PROMPT TEMPLATE**
     section below — write it verbatim, no edits, no project-specific
     interpolation.

3. **Report to the user:**
   - For each artifact: created (with path) or already present.
   - If everything already existed, say "Backlog already initialized."
   - If anything was created, hint that `/task-add` is usable and that
     the external implement-prompt is ready for aider invocations like:
     `aider --model ollama/qwen2.5-coder:14b \`
     `      --read .claude/external/implement-prompt.md \`
     `      --read .claude/tasks/<N>.md`

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
`/task-implement` reads them, and an external LLM consumes them
directly via aider)

`.claude/tasks/<N>.md`:

```
# Task <N> — <Title>

## Description
<Plain prose explanation …>

### Files to modify
<Comma-separated list, identical to the `Files:` field in the task's
TASKS.md summary block. The output surface — what an implementer will
edit. Replicated here so an external LLM fed only this body file knows
what to touch.>

### Required reading
<Bulleted list of `path:line-range — why` entries the implementer
should `/add` to aider before editing.>

### Relevant snippets
<Optional. 5–30 line excerpts of central, non-obvious code, prefixed
with `path:line` origins.>

### Conventions to follow
<Bulleted list of project rules (drawn from CLAUDE.md and the relevant
context layer).>

### Out of scope
<Bulleted list of things the implementer must NOT do — explicit
guardrails.>

### Root cause
<Optional. Bugfixes when non-obvious.>

### Behavior change
<Concrete rules.>

### Doc updates
<Optional. Required when behavior changes touch a documented surface.>

### Tests
<Test files / smoke checklists and assertions.>

### Definition of done
- <Bullets.>
- Full test suite passes.
```

The per-task file is self-contained — an external LLM fed only this
file plus `.claude/external/implement-prompt.md` should have enough
context to implement. The tracking metadata that DOES NOT live in the
body is `Status:` and `Preconditions:` — those describe the task's
place in the backlog, not its implementation, and live only in
`TASKS.md`. `Files:` is intentionally duplicated as `### Files to
modify` because it's part of the implementation contract.

---

EXTERNAL IMPLEMENT-PROMPT TEMPLATE

Write this exact content (everything between the BEGIN and END markers,
not including the markers themselves) to
`.claude/external/implement-prompt.md` when the artifact is missing:

```
=== BEGIN external/implement-prompt.md ===
# Implement-prompt for external LLMs

You are an engineer implementing one task from this project's task
backlog. You are running inside aider with file-read, repo-map, and
file-edit (SEARCH/REPLACE) tools.

## Inputs

- The task body file at `.claude/tasks/<N>.md` (provided as a `--read`
  context). Sections you should expect: Description, Files to modify,
  Required reading, Relevant snippets (optional), Conventions to
  follow, Out of scope, Behavior change, Tests, Definition of done.
- The project's CLAUDE.md and any context/domain layer it cites.

## Procedure

1. Read the task body in full. Description and Behavior change tell
   you what to build; "Files to modify" is the output surface.
2. For every entry in "Required reading", `/add` the file to aider's
   context before you start editing.
3. Skim CLAUDE.md if you have not already; honor every rule under
   "Conventions to follow".
4. Implement the change one file at a time, only touching files in
   "Files to modify" (plus genuine collateral such as imports or
   fixture updates). Stop at any rule under "Out of scope".
5. Add or extend the test files / smoke checklists named under
   "Tests".
6. Verify every bullet under "Definition of done" is observable.
7. If the project has an automated test suite, run it; all tests must
   pass before you consider the task complete.

## Output discipline

- Use aider SEARCH/REPLACE diff blocks. No speculative refactors.
- Do not modify files outside "Files to modify" without explanation.
- Do not change the task body file (`.claude/tasks/<N>.md`) or
  `.claude/TASKS.md` — those are managed by `/task-add` and
  `/task-implement`, not by the implementer.

## Stop conditions

If any of the following hold, stop and report rather than proceeding:
- The task body is ambiguous on a decision you cannot defer.
- A file listed in "Required reading" is missing.
- A test that you did not introduce starts failing.
- A change you must make falls outside "Files to modify" and you
  cannot justify it as collateral.
=== END external/implement-prompt.md ===
```

---

DO NOT:
- Create any task entries — `/task-setup` only creates the empty
  scaffolding. The first task is added by `/task-add`.
- Overwrite an existing `TASKS.md`, any `.claude/tasks/<N>.md` file,
  or an existing `.claude/external/implement-prompt.md`. The
  implement-prompt may have been edited by the user; never clobber it.
- Modify the implement-prompt template content per project — it is a
  static, project-agnostic template. Project-specific guidance lives
  in CLAUDE.md and the context/domain layer, which the prompt already
  tells the external LLM to consult.
- Commit. The user decides whether to commit the scaffolding.
