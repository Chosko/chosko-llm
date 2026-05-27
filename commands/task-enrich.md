---
name: task-enrich
version: 0.1.0
type: command
description: Expand a thin (target: claude) task body into a self-contained enriched body for a local LLM implementer.
---

# /task-enrich
# Expand a task body into an enriched, self-contained body suitable
# for a local LLM implementer (e.g. qwen2.5-coder via aider).
# Usage: /task-enrich <N>   (N = task number)

GOAL
Transform the body file `.claude/tasks/<N>.md` from thin (`Target: claude`)
to enriched (`Target: local`) by appending a `## Context bundle` section and
a `## Implementation steps` section. The Goal, Acceptance criteria, Decisions,
and Hints sections are preserved unchanged. The `Target:` line is updated to
`local`. No other files are modified. No commit is made.

$ARGUMENTS

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to existing files.
  Never use the Write tool on an existing body file — it would overwrite it.
- Bash / PowerShell: not used by this command.

---

PHASE 0 — VALIDATE

1. Parse `<N>` from $ARGUMENTS.
2. Read `.claude/tasks/<N>.md`. If the file does not exist, stop:
   > Task <N> body file not found at `.claude/tasks/<N>.md`. Check the
   > task number and try again.
3. Check the `Target:` field on line 2:
   - If `Target: local`, stop:
     > Task <N> is already enriched (Target: local). Nothing to do.
   - If `Target: claude` (or the field is absent), continue.
4. Read `.claude/TASKS.md` and locate the summary block for task <N>
   to confirm the task exists in the index and note its `Files:` list.

---

PHASE 1 — GATHER CONTEXT (silent)

The goal is to collect exactly what the local LLM will need — no more.
A bloated context bundle defeats its purpose (context overflow is the
problem we are solving).

1. Read the body file in full. Note the Goal, Acceptance criteria,
   Decisions, and Hints sections.

2. For each path listed in `## Hints`, read the file. These are the
   primary edit targets.

3. Navigate the project context layer to understand conventions and
   patterns relevant to this task:
   - Read CLAUDE.md (hard rules, language constraints, install patterns).
   - Read `.claude/context/` files that cover the touched code.
   - Read `.claude/domain/` files relevant to the subsystem under change.
   - Stop as soon as you have enough; do not read everything.

4. Identify any non-obvious code patterns, helper functions, or schema
   invariants that the implementer must follow. Note their locations and
   extract the relevant excerpts.

5. Determine the implementation steps at a level of detail sufficient to
   follow without additional reads. Each step must be grounded in
   something either already in the body or in the context you gathered.

No output during this phase.

---

PHASE 2 — DRAFT (present for confirmation)

Present the two new sections before writing anything:

```
PLAN — enrich task <N>

## Context bundle
<content>

## Implementation steps
<content>

Target: will be updated from `claude` → `local`
```

End with: **"Approve and write?"**

Wait for explicit approval ("yes", "go", "write it", or similar).
Silence is not approval. Iterate if the user requests changes.

---

PHASE 3 — WRITE (only after explicit approval)

1. Use the Edit tool on `.claude/tasks/<N>.md`:
   a. Change `Target: claude` → `Target: local` on line 2.
      If `Target:` is absent, insert `Target: local` on line 2
      (immediately after the `# Task N — Title` heading).
   b. Append the two new sections at the end of the file, after the
      existing content, in this order:
      ```
      ## Context bundle
      <content>

      ## Implementation steps
      <content>
      ```

2. Report to the user:
   - Task number and title.
   - Confirmation that `Target:` was updated to `local`.
   - Reminder that no commit was made; the user should commit when ready.

---

DO NOT:
- Modify Goal, Acceptance criteria, Decisions, or Hints sections.
- Modify `.claude/TASKS.md` or any file other than the task body.
- Write a new body file from scratch — always edit the existing one.
- Commit, stage, push, or touch git state.
- Enrich a task that is already `Target: local`.
- Embed more context than the implementation strictly requires. Select;
  do not dump.
- Include step-by-step instructions for things that are self-evident
  from the acceptance criteria. Steps should resolve ambiguity, not
  narrate the obvious.
