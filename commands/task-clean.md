---
name: task-clean
version: 0.4.0
type: command
description: Prune tasks in a terminal status — remove summary blocks from TASKS.md and delete their per-task body files. Task IDs are stable; survivors are NEVER renumbered. Automatically commits the removals; pass --no-commit to leave them uncommitted.
---

# /task-clean
# Global command: prune tasks in a terminal status from the project's task
# backlog. Removes the matched task's summary block from `.claude/TASKS.md`
# and deletes the corresponding `.claude/tasks/<N>.md` body file. Survivors
# are NOT renumbered — task numbers are stable IDs across the project's
# lifetime, so the `Last task number` counter is never decremented and
# pruned IDs are never reused. Always reports the plan and asks for
# explicit confirmation before writing.
# Usage: /task-clean
#        /task-clean <STATUS> [<STATUS> ...]
#        /task-clean [<STATUS> ...] --no-commit   (write changes, skip the commit)
# Examples: /task-clean
#           /task-clean DONE
#           /task-clean DONE SKIP
#           /task-clean DONE --no-commit

GOAL
Remove tasks that are finished or abandoned so the backlog stays focused
on work that still needs doing. Delete both the summary block in
`.claude/TASKS.md` and the per-task body file. Rewrite every
`Preconditions:` reference in surviving summary blocks that pointed at a
removed task. Always confirm with the user before writing. Never
renumber.

$ARGUMENTS

ARGUMENT NOTE — before PHASE 1, scan $ARGUMENTS for the optional
`--no-commit` flag. If present, set NO_COMMIT = true and strip it; the rest
is the status set (or empty for the default). `--commit` and `--no-commit`
are mutually exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.` When NO_COMMIT is
false (the default), PHASE 3 auto-commits as before.

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to an existing file;
  use the Write tool only when creating a new file from scratch. Never use
  shell redirection, `tee`, `Set-Content`, `Out-File`, or any shell
  mechanism to write files.
- Bash / PowerShell are used to delete the per-task body files
  (`rm .claude/tasks/<N>.md`) and, unless `--no-commit` was passed, to run
  the git operations in PHASE 3 (`git add --` and `git commit`). Under
  `--no-commit`, the only shell use is the body-file deletion.

---

LOCATING THE BACKLOG

The backlog lives at `.claude/TASKS.md` with per-task body files at
`.claude/tasks/<N>.md`. If `.claude/TASKS.md` does not exist, tell the
user "No backlog file found — run /task-setup to initialize it." and
stop. Do NOT create anything.

---

WHICH STATUSES COUNT AS "TERMINAL"

Default (when `$ARGUMENTS` is empty): `[DONE]` and `[SKIP]`. These are
the two statuses that indicate the task no longer needs work.

If `$ARGUMENTS` lists one or more status tags (case-insensitive,
brackets optional), use that explicit set instead. Accept any of the
canonical statuses (`[MISSING]`, `[STUBBED]`, `[INCORRECT]`,
`[PARTIAL]`, `[IN PROGRESS]`, `[DONE]`, `[SKIP]`) but warn if the user
is asking to prune a non-terminal status:

- `[IN PROGRESS]` — currently being worked on. Pruning is almost
  certainly a mistake. Confirm twice, the second time with the specific
  tasks listed.
- `[MISSING]`, `[STUBBED]`, `[INCORRECT]`, `[PARTIAL]` — these mean work
  still remains. Pruning them throws away the spec. If the user really
  wants to discard a task, this is the right command for it, but flag
  the unusual choice in the plan.

If the user passes a tag that isn't one of the canonical statuses, list
the valid options and stop.

---

PHASE 1 — REPORT (no file writes, no deletions)

1. Use the Read tool to open `.claude/TASKS.md`. Parse:
   - The `Last task number: N` header value (informational — it does
     not change).
   - Each summary block: number, title, status, `Files:`,
     `Preconditions:`.

2. Identify the tasks whose status matches the prune set. If there are
   none, tell the user "No tasks to prune." and stop.

3. For each surviving task, find any `Preconditions:` line that
   references a pruned task ID. Plan to drop those references; if the
   list becomes empty, the line becomes `Preconditions: none`. Do NOT
   plan any renumbering — task IDs are stable.

4. List the per-task body files to be deleted: one
   `.claude/tasks/<N>.md` per pruned task. Probe each path with the
   Read tool first; if a body file is unexpectedly missing, note that
   in the plan but do not error out.

5. Render the plan:

   ```
   PLAN — task-clean

   Index file: .claude/TASKS.md
   Pruning statuses: [DONE], [SKIP]   (or whatever set applies)

   Tasks to remove (N):
     3.  [DONE]  Title …       (body file: .claude/tasks/3.md)
     7.  [DONE]  Title …       (body file: .claude/tasks/7.md)
     12. [SKIP]  Title …       (body file: .claude/tasks/12.md — MISSING)

   Renumbering: NONE — task IDs are stable across the project's
                lifetime. Survivors keep their numbers; the
                "Last task number" counter is unchanged.

   Precondition references to update (M):
     Task 8:  Preconditions "3, 7" → "none"
     Task 10: Preconditions "12"   → "none"
     …

   Anything in [IN PROGRESS]? <yes/no — if yes, list them as a heads-up
   so the user notices unfinished work before pruning around it>
   ```

   End with a single explicit prompt: **"Apply?"**

   Wait for the user. If they ask to change the prune set or exclude
   specific tasks, re-render the plan after the change. Do NOT proceed
   to PHASE 2 without an explicit approval ("yes", "go", "apply", or
   similar). Silence is not approval.

---

PHASE 2 — APPLY (only after explicit approval)

1. Use the Edit tool on `.claude/TASKS.md` to remove each matched
   summary block, including the `---` separator line that precedes it.
   Preserve the file's overall formatting (blank lines between
   surviving blocks, the header, the counter line).

2. Use the Edit tool to rewrite every `Preconditions:` line per the
   plan.

3. Delete the per-task body files. Use Bash:
   `rm .claude/tasks/3.md .claude/tasks/7.md .claude/tasks/12.md`
   (skip files the plan flagged as already missing). On Windows the
   tool harness is bash-aware via the Bash tool.

4. Do NOT touch the `Last task number:` line. It tracks the highest ID
   ever assigned, not the highest currently present, and only ever
   increases.

5. After editing, use Grep to re-check `.claude/TASKS.md` for any
   `Preconditions:` reference to a now-removed task ID and confirm no
   stale references remain.

6. Report to the user:
   - Number of summary blocks removed from `TASKS.md`.
   - Number of body files deleted (and any that were already missing).
   - Number of `Preconditions:` lines rewritten.
   - Final task count.
   - The unchanged `Last task number:` value.

After the report, continue to PHASE 3.

---

PHASE 3 — COMMIT

If NO_COMMIT is true, skip committing entirely: the `.claude/TASKS.md` edits
and the body-file deletions from PHASE 2 are left uncommitted in the working
tree. Report what was changed (blocks removed, body files deleted,
`Preconditions:` lines rewritten) and remind the user that nothing was
committed — they should commit when ready. Do not run any git command. Then
stop.

Otherwise (the default), after PHASE 2 completes successfully, commit the
changes automatically — no further prompt is needed.

1. Run exactly:

   ```
   git add -- .claude/TASKS.md .claude/tasks/<N>.md .claude/tasks/<M>.md …
   git commit -m "task-clean: remove tasks <N>[, <M>, …]"
   ```

   Stage `.claude/TASKS.md` (modified) plus each deleted body file path
   (body files pruned in PHASE 2). Staging a deleted file via
   `git add -- path` works identically to staging a modified one — git
   records the deletion when the file no longer exists on disk.

   PHASE 3 stages ONLY the files PHASE 2 touched. It must not run
   `git add -A`, `git add .`, `git add -u`, or anything that could pull
   in unrelated dirty files from the working tree.

   Commit message format: `task-clean: remove tasks <N>[, <M>, …]`
   where `<N>`, `<M>`, … are the pruned task IDs in ascending order.

2. On success, report the resulting commit hash to the user:
   `git rev-parse --short HEAD`.

3. On failure (e.g. pre-commit hook rejects the commit): surface the
   exact failure output to the user. Do NOT retry, do NOT amend, do
   NOT use `--no-verify` or any hook-skipping flag. The files remain
   in whatever state git left them (typically staged but uncommitted);
   tell the user that and let them decide.

DO NOT:
- Write to any file during PHASE 1.
- Renumber surviving tasks. Task IDs are stable — re-using a number for
  a different task in the future would silently break historical
  references in commit messages, comments, and external systems.
- Decrement the `Last task number:` counter, even if you just removed
  the task with the highest ID.
- Touch tasks whose status is not in the prune set.
- Change task content other than `Preconditions:` lines on survivors.
- Use `git add -A`, `git add .`, or `git add -u` in PHASE 3 — only the
  files touched by PHASE 2 may be staged.
- Use `--amend`, `--no-verify`, `--no-gpg-sign`, or any other
  hook-skipping or commit-rewriting flag. If a pre-commit hook fails,
  surface it and let the user fix it.
- Push, branch, tag, or otherwise touch shared/visible git state.
