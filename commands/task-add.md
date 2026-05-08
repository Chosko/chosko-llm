---
name: task-add
version: 0.4.0
type: command
description: Plan a new task entry conversationally, confirm with the user, write a summary to TASKS.md and a richer body file under .claude/tasks/ that an external LLM (aider + Ollama) can implement directly, then optionally commit the two written files.
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
(conversational) → DRAFT → CONFIRM → WRITE → OFFER COMMIT. Never write
to any file before the user confirms the draft, and never commit
without a separate explicit approval at PHASE 5.

$ARGUMENTS

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to an existing file;
  use the Write tool only when creating a new file from scratch. Never use
  shell redirection, `tee`, `Set-Content`, `Out-File`, or any shell
  mechanism to write files.
- Bash / PowerShell are used ONLY by PHASE 5 (the optional commit step):
  `git status --porcelain`, `git add -- <path> <path>`, and `git commit`.
  No other phases shell out.

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

The body file must be **self-contained** enough that an external LLM
(target: qwen2.5-coder:14b via aider) fed only this file plus the
project's `.claude/external/implement-prompt.md` can implement the
task. That goal drives the schema below.

```
# Task <N> — <Title>

## Description
<Plain prose explanation of the problem and the desired behavior. Cite
file paths and line numbers when describing root cause; name the symbols
involved; quote relevant code if it clarifies the bug. Aim for the level
of detail a different engineer could implement from cold.>

### Files to modify
<Comma-separated list of files this task will edit. MUST be identical
to the `Files:` field of the task's summary block in TASKS.md —
duplicated here so the external LLM has the output surface in the body
itself. `Status:` and `Preconditions:` are NOT replicated; those are
backlog-flow concerns that don't belong in the implementation contract.>

### Required reading
<Bulleted list. Each entry: `path[:line-range] — why`. The implementer
should `/add` these to aider before editing. Include CLAUDE.md, the
relevant `.claude/context/*.md`, the relevant `.claude/domain/*.md`,
and the source files involved.>

### Relevant snippets
<Optional. Quote 5–30 line excerpts of code that are central to the
task and non-obvious. Each snippet prefixed with its `path:line`
origin. Skip when "Required reading" is enough.>

### Conventions to follow
<Bulleted list of project rules the implementer must respect (e.g.
"scripts start with `set -euo pipefail`", "no jq/yq deps", "honor
`CHOSKO_LLM_HOME` / `CLAUDE_HOME`"). Pull from CLAUDE.md and the
context/domain layer relevant to the touched code.>

### Out of scope
<Bulleted list of things the implementer must NOT do (e.g. "do not
add new dependencies", "do not refactor unrelated files", "do not
bump versions of unrelated features"). Explicit guardrails for a
weaker model.>

### Root cause
<Optional. Bugfixes where the cause is non-obvious.>

### Behavior change
<What the code should do after the task lands. Concrete rules.>

### Doc updates
<Optional but required when behavior touches a documented surface. Name
the affected files and sections; describe what changes.>

### Tests
<Which test files / smoke checklists to add/extend and what each new
assertion or checklist item must cover.>

### Definition of done
- <Bullets — observable outcomes.>
- Full test suite passes.
```

Required body sections: `## Description`, `### Files to modify`,
`### Required reading`, `### Conventions to follow`, `### Out of
scope`, `### Tests`, `### Definition of done`. Optional sections
(`### Relevant snippets`, `### Root cause`, `### Behavior change`,
`### Doc updates`) are included only when they add information.

`### Files to modify` MUST exactly mirror the summary block's `Files:`
field. `/task-add` writes both at creation time; subsequent commands
do not edit either, so drift is impossible if both are written
consistently here.

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

2. Read enough of the codebase to ground the task. The body file must
   be self-contained for an external implementer, so be more thorough
   than a single-glance survey:
   - Use Grep / Glob / Read to confirm the actual files involved.
   - Read the project's CLAUDE.md, README.md, and the `.claude/context/`
     navigation layer where it covers the touched code.
   - Read any `.claude/domain/*.md` files that describe the subsystem
     under change — domain docs hold conventions and architectural
     rationale that belong in `### Conventions to follow`.
   - Do NOT read other per-task body files in `.claude/tasks/` unless
     you genuinely need their content — TASKS.md gives you the
     dependency graph already.

3. Identify the project's documentation layer and cross-check it against
   the task. Goal: detect every doc that will be out of sync once the
   code change lands. Look for `.claude/domain/`, `docs/`, `SPEC.md`,
   `ARCHITECTURE.md`, design docs named in CLAUDE.md, README sections
   that describe behavior, inline doc comments that serve as specs.

4. Gather material for the new body sections specifically:
   - **Files to modify** — the concrete list of edit targets, which will
     also become the summary block's `Files:` field.
   - **Required reading** — for each file an implementer will need to
     understand before editing, note `path[:line-range]` and a one-line
     reason. Include CLAUDE.md and any context/domain file you read in
     step 2 that meaningfully informs the task.
   - **Relevant snippets** — identify any 5–30 line stretches of
     non-obvious code that the implementer must understand. Plan to
     quote them inline so the implementer does not have to chase
     tangents.
   - **Conventions to follow** — extract project rules from CLAUDE.md
     and the relevant context/domain files (e.g. "no new deps",
     "scripts start with `set -euo pipefail`", schema invariants).
   - **Out of scope** — anticipate where a weaker model might
     overreach (refactor unrelated code, bump unrelated versions, add
     defensive scaffolding) and list explicit prohibitions.

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

If your PHASE 1 sweep left **Required reading**, **Conventions to
follow**, or **Out of scope** substantially empty for a code task,
that's a signal to ask before drafting — those sections are required
and the body's value to an external implementer drops sharply without
them. (An empty `### Relevant snippets` is fine; it's optional.)

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

  ### Files to modify
  <comma-separated; MUST match the summary block's Files: field>

  ### Required reading
  - <path[:lines] — why>
  - …

  ### Relevant snippets
  <optional; omit the section entirely if empty>

  ### Conventions to follow
  - …

  ### Out of scope
  - …

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

After the report, continue to PHASE 5.

---

PHASE 5 — OFFER COMMIT (optional, requires explicit approval)

The two files written by PHASE 4 (`.claude/TASKS.md` and
`.claude/tasks/<N>.md`) are a natural, self-contained commit. PHASE 5
asks the user whether to capture them now, then either does so or
leaves them unstaged.

1. Print exactly one prompt:

   > Task <N> written. Commit `.claude/TASKS.md` + `.claude/tasks/<N>.md` now? [y/N]

2. Interpret the answer:
   - **Explicit yes** (`y`, `yes`, `commit`, `go`): proceed to step 3.
   - **Anything else** (no, blank line, EOF, an unrelated reply, silence):
     print `Skipped commit. Files left unstaged.` and stop. Do not
     stage, do not commit. The user can commit by hand later.

3. On yes, run exactly:

   ```
   git add -- .claude/TASKS.md .claude/tasks/<N>.md
   git commit -m "Add task <N>: <title>" \
              -m "<one-line summary derived from Description's first sentence, optional>"
   ```

   Use a HEREDOC for the commit message body if it is multi-line. The
   second `-m` is optional — drop it if the description's first
   sentence does not yield a useful one-liner.

4. On success, report the resulting commit hash to the user
   (`git rev-parse --short HEAD`).

5. On failure (e.g. pre-commit hook rejects the commit): surface the
   exact failure output to the user. Do NOT retry, do NOT amend, do
   NOT use `--no-verify` or any hook-skipping flag. The two files
   remain in whatever state git left them (typically staged but
   uncommitted); tell the user that and let them decide.

PHASE 5 stages ONLY the two files PHASE 4 wrote. It must not run
`git add -A`, `git add .`, `git add -u`, or anything that could pull
in unrelated dirty files from the working tree.

---

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
- Use `git add -A`, `git add .`, or `git add -u` in PHASE 5 — only
  the two files written by PHASE 4 may be staged.
- Use `--amend`, `--no-verify`, `--no-gpg-sign`, or any other
  hook-skipping or commit-rewriting flag. If a pre-commit hook fails,
  surface it and let the user fix it.
- Push, branch, tag, or otherwise touch shared/visible git state.
- Commit without an explicit yes at PHASE 5. Silence is not approval.
