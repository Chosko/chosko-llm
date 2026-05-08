---
name: task-add
version: 0.1.1
type: command
description: Plan a new task entry conversationally, confirm with the user, then append it to the project's task backlog.
---

# /task-add
# Global command: plan a new task entry conversationally, confirm with the
# user, then append it to the project's task backlog. Creates the backlog
# file from scratch if absent.
# Usage: /task-add <free-form description of the task to add>
# Example: /task-add fix the URL normalization so two LinkedIn URLs for the
#          same job dedupe correctly

GOAL
Add a single new task to the project's task backlog, following the conventions
below. The flow is: READ → ASK (conversational) → DRAFT → CONFIRM → WRITE.
Never write to the backlog file before the user confirms the draft.

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

LOCATING THE BACKLOG FILE

The backlog file is conventionally `.claude/TASKS.md`. Search order:
1. `.claude/TASKS.md`
2. `TASKS.md`
3. `docs/TASKS.md`

If none exist, you will create `.claude/TASKS.md` (creating the `.claude/`
directory if needed) during the WRITE phase. The file has no header or
preamble — task entries are the entire content.

---

TASK ENTRY FORMAT (canonical template)

Tasks are numbered, separated by `---` on its own line, and indented two
spaces. The very first task in the file also has a leading `---`.

```
  ---

  ## N. <Short imperative title — what the task accomplishes>

  Status: [MISSING]
  Files: <comma-separated list of files this task will create or modify>
  Preconditions: <task numbers this depends on, or "none">
  Description:
  <Plain prose explanation of the problem and the desired behavior. Cite
  file paths and line numbers when describing root cause; name the symbols
  involved; quote the relevant code if it clarifies the bug. Aim for the
  level of detail a different engineer could implement from cold.>

  ### Root cause
  <Optional. Include for bugfixes when the cause is non-obvious.>

  ### Behavior change
  <What the code should do after the task lands. Concrete rules, not
  aspirations.>

  ### Doc updates
  <Optional. Include when the task changes behavior that is described in a
  spec, design doc, domain reference, README, or other authoritative document
  that lives in the repo. For each affected file: name the specific
  section/heading and describe what must change (new content, corrected
  format, added entry, etc.). Be as concrete as you are in ### Behavior change.
  Omit this section entirely if the project has no documentation layer, or if
  the task has no impact on any documented behavior.>

  ### Tests
  <Which test files to add or extend, and what each new test asserts.
  Be explicit about regression guards.>

  ### Definition of done
  - <Bullet list of observable outcomes that prove the task is complete.>
  - Full test suite passes.
```

Required sections: `Status`, `Files`, `Preconditions`, `Description`.
`### Tests` and `### Definition of done` are required for any code task.
`### Doc updates` is **optional but must be included whenever the task alters
behavior described in a repo doc** — omit only when no relevant doc exists
or the task genuinely has no impact on documented behavior.
Other optional sections are included only when they add information.

---

STATUS TAGS (the only allowed values)

- `[MISSING]` — behavior not implemented at all. **Default for new tasks.**
- `[STUBBED]` — placeholder/TODO exists but no real implementation.
- `[INCORRECT]` — implemented but diverges from the spec.
- `[PARTIAL]` — implemented in part; some sub-requirements still missing.
- `[IN PROGRESS]` — agent is currently working on it. (Not set by this command.)
- `[DONE]` — implementation has landed. (Not set by this command.)
- `[SKIP]` — explicitly deferred or abandoned.

A new task added by this command is `[MISSING]` unless the user's description
clearly indicates a different pre-implementation state.

---

PHASE 1 — READ (silent)

1. Use the Read tool to open the backlog file if it exists. Note the highest
   existing task number, the title style ("<Subsystem> — <thing>" vs plain
   imperatives), and the dependency graph between existing tasks.

2. Read enough of the codebase to ground the task:
   - Use Grep / Glob / Read to confirm the actual files involved.
   - If the project has a CLAUDE.md, README.md, or `.claude/` context layer,
     read what's relevant — but do not assume any of these exist.
   - Do not skim. A precondition you miss here becomes a stale dependency
     reference later.

3. Identify the project's documentation layer and cross-check it against the
   task. The goal is to detect every doc that will be out of sync once the
   code change lands:
   - Look for authoritative reference docs: `.claude/domain/`, `docs/`,
     `SPEC.md`, `ARCHITECTURE.md`, design docs named in CLAUDE.md, README
     sections that describe behavior, inline doc comments that serve as specs.
   - Skim only the sections relevant to the task — you are looking for places
     where the current text would become false or incomplete after the task
     lands (changed CLI flags, new API surface, altered data formats, revised
     flows, updated notification payloads, new reserved fields, etc.).
   - If no documentation layer exists, note that so you can omit `### Doc
     updates` from the draft without second-guessing yourself later.

No user-facing output during this phase beyond a single brief sentence saying
what you're reading.

---

PHASE 2 — ASK (conversational)

Identify what you genuinely don't know, and ask the user about it directly.
This is a conversation, not a form. Keep it natural:

- Ask only about things you can't resolve from the code or the user's
  initial description. If everything is clear, skip straight to PHASE 3.
- Prefer a small batch of focused questions (1–4) over a long
  questionnaire. If new questions emerge from the answers, ask those next
  — it's fine to take multiple turns.
- For each question, **suggest the answer you'd pick and why**, so the user
  can confirm with a single word instead of writing prose. Format like:

  > Should the LinkedIn adapter strip all query params, or just the
  > tracking ones? I'd lean toward stripping all — the job ID is in the
  > path and every query param I've seen is session-specific. OK?

- Common things worth asking about (only when actually ambiguous):
  - Multiple valid implementation approaches → pick one, list alternatives.
  - Scope boundaries — is X in or out?
  - Acceptance criteria you can't infer from the description.
  - Whether the task depends on existing work-in-progress.
  - Position in the list when insertion would renumber many tasks.
  - Doc update scope when a doc exists but it's unclear which sections are
    affected, or when you found a relevant doc but can't tell if the task
    should update it (suggest the sections you'd update and ask to confirm).

- Do NOT ask about things that are stylistic conventions already visible in
  the existing file (title format, indentation, status tag default). Just
  match the existing style.

- Do NOT produce the task draft during this phase. The draft comes only
  after every open question has been answered.

If there are zero open questions after PHASE 1, say so in one line and move
straight to PHASE 3.

---

PHASE 3 — DRAFT (present for confirmation)

Once all questions are resolved, render the full plan in one message:

```
PLAN — new task

Backlog file: <path; "to be created" if new>
Proposed number: N
Position: <"appended at end" | "inserted before task M (renumbers M..K)">

Draft entry:
<render the full task entry exactly as it will appear in the file>

Renumbering impact: <none | "tasks 12–18 renumbered, 4 precondition
references updated">
```

End with a single explicit prompt: **"Approve and write?"**

Wait for the user. Iterate if they request changes — re-present the plan
after any non-trivial revision. Do NOT proceed to PHASE 4 without an
explicit approval ("yes", "go", "write it", "approve", or similar).
Silence is not approval.

---

PHASE 4 — WRITE (only after explicit approval)

1. If the backlog file does not exist, use the Write tool to create it (create
   the parent directory first if needed using Bash `mkdir -p`). The new file
   starts empty.

2. Use the Edit tool to insert the new task at the agreed position (or the
   Write tool if the file was just created). Preserve the two-space
   indentation and the `---` separators above each task.

3. If insertion is mid-list:
   - Renumber every task that comes after the insertion point.
   - Update every `Preconditions:` line in the file that references one of
     the renumbered task numbers. Missing this silently breaks the
     workflow — use Grep to re-check the file after editing and confirm no
     stale references remain.

4. Report to the user:
   - The task number assigned.
   - The file path (especially if newly created).
   - Renumbering performed and precondition references updated.

DO NOT:
- Write to the backlog file before PHASE 4.
- Append blindly to the bottom when dependencies imply an earlier slot.
- Invent preconditions to make the task look rigorous — "none" is fine.
- Change the status of any other task.
- Implement the task. This command only creates the entry.
- Commit. This command does not touch git.
