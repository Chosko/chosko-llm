---
name: task-clean
version: 0.8.0
type: command
description: Prune tasks in a terminal status — remove summary blocks from TASKS.md and delete their per-task body files. Terminal means [DONE] and [SKIP] only; [STALE] is live work awaiting reconciliation and is never pruned by default. Also drops the pruned IDs from any .claude/FEATURES.md Tasks: line (leaving feature statuses alone), so /architect's iterate guard never reads a dead ID. Task IDs are stable; survivors are NEVER renumbered. Automatically commits and pushes the removals; pass --no-commit to leave them uncommitted, or --no-push to commit without pushing.
requires: skill:task-engine
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
#        /task-clean [<STATUS> ...] --no-commit   (write changes, skip the commit and push)
#        /task-clean [<STATUS> ...] --no-push     (commit as usual, skip the push)
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

ARGUMENT NOTE — the `--no-commit` and `--no-push` flags, and everything they
gate, are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`.
Scan `$ARGUMENTS` for them before PHASE 1 and strip whichever appear; what
is left is this command's own argument — a status set, or empty for the
default.

---

LOCATING THE BACKLOG

Backlog resolution follows
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`,
whose `/task-clean` note carries every way this command departs from it: the
wording of the not-initialised stop, the fields it parses out of each summary
block, and the single reason it opens a body file — probing that the file
exists before planning its deletion.

Pull at start, before PHASE 1 begins, per `commit.md`.

---

WHICH STATUSES COUNT AS "TERMINAL"

The status vocabulary, which of the tags are terminal, and how a status
argument is accepted are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/status.md`. Its
`/task-clean` note carries what this command does with them.

Here a status is a prune set — never a display filter, never a task selector
— and this command writes no status anywhere: it removes whole summary
blocks. With no argument the prune set is the terminal pair, `[DONE]` and
`[SKIP]`. An explicit set replaces that default rather than adding to it; any
canonical status may be named, and when a named one is non-terminal, carry
`status.md`'s warning for it into the plan.

`[STALE]` is never in the default set. What it means, and why it is live work
awaiting reconciliation rather than abandoned work, are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/stale.md`; when
the user names it explicitly, say all of that in the plan and confirm before
applying.

---

PHASE 1 — REPORT (no file writes, no deletions)

1. Read `.claude/TASKS.md` and parse it as `resolution.md` § *Parsing the
   index* describes. `/task-clean` uses each summary block's number, title,
   status, `Files:` and `Preconditions:`, and reads the `Last task number: N`
   header value for information only — it does not change.

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

4b. Probe `.claude/FEATURES.md` with the Read tool. If it does not exist,
   skip this step and every later reference to it silently — most projects
   have no feature index, and its absence is not an error. If it does
   exist, find every `Tasks:` line that references a pruned ID and plan to
   drop those IDs. A line left with no IDs becomes `Tasks: none`. Plan NO
   change to any feature's `Status:` line — see the note in PHASE 2.

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

   Feature Tasks: lines to update (K):        (omit when no FEATURES.md)
     Feature session-handling: Tasks "3, 7, 9" → "9"   (dropping 3, 7)
     Feature user-profile:     Tasks "12"      → "none" (dropping 12)
     Feature statuses are unchanged.

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

4. Do NOT touch the `Last task number:` line — `resolution.md` § *Index file
   format* is why it only ever increases.

4b. If `.claude/FEATURES.md` exists, use the Edit tool to drop each pruned
   ID from every `Tasks:` line that references it, per the plan. A line left
   with no IDs becomes `Tasks: none`.

   **Do not change any feature's `Status:`.** A feature whose tasks were all
   cleaned stays `[PLANNED]`: the tasks existed and were resolved, and
   `[PLANNED]` → `[NEW]` is an illegal transition — it would claim the
   feature was never planned. Pruning is bookkeeping about which tasks still
   exist, not a statement about the design/backlog relationship.

   This command is the writer that invalidates those IDs, so it is the one
   that fixes them — immediately, in the same run. `/architect`'s iterate
   guard is a pure reader of `Tasks:`; a dead ID there makes it under-report
   which tasks a re-architecture would invalidate.

5. After editing, use Grep to re-check `.claude/TASKS.md` for any
   `Preconditions:` reference to a now-removed task ID, and
   `.claude/FEATURES.md` (when it exists) for any `Tasks:` reference to
   one. Confirm no stale references remain in either.

6. Report to the user:
   - Number of summary blocks removed from `TASKS.md`.
   - Number of body files deleted (and any that were already missing).
   - Number of `Preconditions:` lines rewritten.
   - Each feature whose `Tasks:` line changed, and which IDs were dropped
     from it. Say explicitly that feature statuses were left as they were.
   - Final task count.
   - The unchanged `Last task number:` value.

After the report, continue to PHASE 3.

---

PHASE 3 — COMMIT AND PUSH

Commit and push gating — the flags, pull-at-start, staging, one commit per
prune, the push protocol, and what to do when a commit or a push fails — is
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`. Its
`/task-clean` note carries this command's own specifics: the commit message
form, the exact path list PHASE 2 leaves to stage and when
`.claude/FEATURES.md` joins it, and that PHASE 3 is its only shell use apart
from the `rm` in PHASE 2. Once PHASE 2 completes successfully the commit
happens automatically — PHASE 1's **"Apply?"** was the run's only gate, and
no further prompt is asked here.

Under `--no-commit` that `rm` is the command's only shell use: report what
was changed — blocks removed, body files deleted, `Preconditions:` lines
rewritten, feature `Tasks:` lines rewritten — and stop.

DO NOT:
- Write to any file during PHASE 1.
- Renumber surviving tasks. Task IDs are stable — re-using a number for
  a different task in the future would silently break historical
  references in commit messages, comments, and external systems.
- Decrement the `Last task number:` counter, even if you just removed
  the task with the highest ID.
- Touch tasks whose status is not in the prune set.
- Add `[STALE]` to the default prune set.
- Change task content other than `Preconditions:` lines on survivors.
- Change a feature's `Status:` in `.claude/FEATURES.md`, or any field other
  than `Tasks:`. A feature whose tasks were all pruned stays `[PLANNED]`;
  `[PLANNED]` → `[NEW]` is illegal. `Doc:` and `Source:` belong to
  `/architect`.
- Error out when `.claude/FEATURES.md` is absent — skip that step silently.
