---
name: task-enrich
version: 0.3.2
type: command
description: Expand a thin (target: claude) task body into a self-contained enriched body for a local LLM implementer. Refuses human-in-the-loop tasks (target claude+human or human) — a headless local LLM cannot pause for manual steps. Pass --commit to commit the enriched body; default leaves it uncommitted.
---

# /task-enrich
# Expand a task body into an enriched, self-contained body suitable
# for a local LLM implementer (e.g. qwen2.5-coder via aider).
# Usage: /task-enrich <N>            (N = task number; leaves the body uncommitted)
# Usage: /task-enrich <N> --commit   (commit the enriched body when done)

GOAL
Transform the body file `.claude/tasks/<N>.md` from thin (`Target: claude`)
to enriched (`Target: local`) by appending a `## Context bundle` section and
a `## Implementation steps` section. The Goal, Acceptance criteria, Decisions,
and Hints sections are preserved unchanged. The `Target:` line is updated to
`local`. No other files are modified. By default no commit is made; with
`--commit`, the enriched body is committed at the end.

$ARGUMENTS

---

PHASE 0 — VALIDATE

1. Parse `<N>` from $ARGUMENTS. Also parse the optional `--commit` flag:
   if present, set COMMIT = true and strip it before reading `<N>`.
   `--commit` and `--no-commit` are mutually exclusive — if both appear,
   stop with: `--commit and --no-commit cannot be combined. Pick one.`
2. Read `.claude/tasks/<N>.md`. If the file does not exist, stop:
   > Task <N> body file not found at `.claude/tasks/<N>.md`. Check the
   > task number and try again.
3. Check the `Target:` field on line 2:
   - If `Target: local`, stop:
     > Task <N> is already enriched (Target: local). Nothing to do.
   - If `Target: claude+human` or `Target: human`, stop:
     > Task <N> requires human intervention (Target: <value>) — a headless
     > local LLM cannot pause for manual steps. Human-in-the-loop tasks
     > stay on the Claude path: implement with `/task-implement <N>`.
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

Edit the body file in place. Never use the Write tool on an existing body
file — it would overwrite it.

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
   - If `--commit` was NOT passed: a reminder that no commit was made;
     the user should commit when ready.

Continue to PHASE 4.

---

PHASE 4 — COMMIT (only when `--commit` was passed)

This is the only phase that shells out (`git add -- <path>` and
`git commit`), and only when `--commit` was passed. No other phase runs a
shell command.

If COMMIT is false (the default), do nothing here — the enriched body is
left uncommitted for the user to review. This is the default behavior and
is unchanged.

If COMMIT is true, after the write in PHASE 3 succeeds:

1. Stage EXACTLY the one file this command wrote and commit it:
   ```
   git add -- .claude/tasks/<N>.md
   git commit -m "Enrich task <N>: <title>"
   ```
   Never use `git add -A`, `git add .`, or `git add -u`.
2. On success, report the commit hash (`git rev-parse --short HEAD`).
3. On failure (e.g. a pre-commit hook rejects the commit): surface the
   exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. The file remains staged but uncommitted; tell the user.

---

DO NOT:
- Modify Goal, Acceptance criteria, Decisions, or Hints sections.
- Modify `.claude/TASKS.md` or any file other than the task body.
- Write a new body file from scratch — always edit the existing one.
- Commit, stage, push, or touch git state unless `--commit` was passed.
  Even with `--commit`, never push, branch, tag, or use hook-skipping
  flags — make exactly one commit of the task body.
- Enrich a task that is already `Target: local`.
- Enrich a `Target: claude+human` or `Target: human` task.
- Embed more context than the implementation strictly requires. Select;
  do not dump.
- Include step-by-step instructions for things that are self-evident
  from the acceptance criteria. Steps should resolve ambiguity, not
  narrate the obvious.
