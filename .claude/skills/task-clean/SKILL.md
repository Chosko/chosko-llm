---
name: task-clean
version: 0.9.0
type: skill
description: Prune tasks in a terminal status by archiving them — remove each summary block from TASKS.md and move the task's body file to .claude/tasks/archive/<N>.md under a frozen header, so no body is ever deleted. Terminal means [DONE] and [SKIP] only; [STALE] is live work awaiting reconciliation and is never pruned by default. A prune never opens .claude/FEATURES.md — a feature keeps every task id it ever generated. Task IDs are stable; survivors are NEVER renumbered. Pass --backfill instead of a status set to recover, from git history, the bodies earlier runs deleted into the same archive. Automatically commits and pushes; pass --no-commit to leave the changes uncommitted, or --no-push to commit without pushing.
replaces: command:task-clean
requires: skill:task-engine
---

# /task-clean
# Global skill: prune tasks in a terminal status from the project's task
# backlog by archiving them. Removes the matched task's summary block from
# `.claude/TASKS.md` and moves the corresponding `.claude/tasks/<N>.md` body
# file into `.claude/tasks/archive/<N>.md`, under a frozen header recording
# the summary block it had. No body is deleted. Survivors are NOT
# renumbered — task numbers are stable IDs across the project's lifetime,
# so the `Last task number` counter is never decremented and pruned IDs are
# never reused. Always reports the plan and asks for explicit confirmation
# before writing.
# Usage: /task-clean
#        /task-clean <STATUS> [<STATUS> ...]
#        /task-clean --backfill                   (recover bodies earlier runs deleted)
#        /task-clean [<STATUS> ...] --no-commit   (write changes, skip the commit and push)
#        /task-clean [<STATUS> ...] --no-push     (commit as usual, skip the push)
# Examples: /task-clean
#           /task-clean DONE
#           /task-clean DONE SKIP
#           /task-clean DONE --no-commit
#           /task-clean --backfill

GOAL
Archive tasks that are finished or abandoned so the backlog stays focused
on work that still needs doing. Remove the summary block from
`.claude/TASKS.md` and move the per-task body file into the archive, where
it keeps the record of what the task was. Rewrite every `Preconditions:`
reference in surviving summary blocks that pointed at an archived task.
Always confirm with the user before writing. Never renumber, and never
delete a body.

$ARGUMENTS

ARGUMENT NOTE — the `--no-commit` and `--no-push` flags, and everything they
gate, are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`.
Scan `$ARGUMENTS` for them before PHASE 1 and strip whichever appear.

Also scan for `--backfill`. When it appears, set BACKFILL = true and strip
it. It is a mode, not a prune set, so if anything is left in `$ARGUMENTS`
after stripping it, stop with:
`--backfill cannot be combined with a status set. Run /task-clean <STATUS> ... and /task-clean --backfill separately.`

Otherwise what is left is this skill's own argument — a status set, or
empty for the default.

When BACKFILL is true, read `./backfill.md` once LOCATING THE BACKLOG below
has run, and follow it in place of PHASE 1 through PHASE 3.

---

LOCATING THE BACKLOG

Backlog resolution follows
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`,
whose `/task-clean` note carries every way this skill departs from it: the
wording of the not-initialised stop, the fields it parses out of each summary
block, the single reason it opens a body file — probing that the file
exists before planning its move — and the one existence check it makes
inside the archive as that archive's only writer. Where the archive lives,
what an archived file holds, and what an id absent from `TASKS.md` means
are that file's § *The archive*.

Pull at start, before PHASE 1 begins, per `commit.md`.

---

WHICH STATUSES COUNT AS "TERMINAL"

The status vocabulary, which of the tags are terminal, and how a status
argument is accepted are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/status.md`. Its
`/task-clean` note carries what this skill does with them.

Here a status is a prune set — never a display filter, never a task selector
— and this skill writes no status anywhere: it removes whole summary
blocks. With no argument the prune set is the terminal pair, `[DONE]` and
`[SKIP]`. An explicit set replaces that default rather than adding to it; any
canonical status may be named, and when a named one is non-terminal, carry
`status.md`'s warning for it into the plan. A non-terminal task named that
way is archived exactly like a terminal one; its frozen `Status:` records
that it was pruned live.

`[STALE]` is never in the default set. What it means, and why it is live work
awaiting reconciliation rather than abandoned work, are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/stale.md`; when
the user names it explicitly, say all of that in the plan and confirm before
applying.

---

THE FEATURE INDEX

A prune does not open `.claude/FEATURES.md` — not to read it, not to write
it. A feature keeps every task id it ever generated on its `Tasks:` line,
archived ones included, so `Tasks: none` means what it says: the feature
was never planned. What an id on that line with no summary block means is
`resolution.md` § *The archive*, and nothing needs rewriting to say so.

---

PHASE 1 — REPORT (no file writes, no moves)

1. Read `.claude/TASKS.md` and parse it as `resolution.md` § *Parsing the
   index* describes. `/task-clean` uses each summary block's number, title,
   status, `Files:`, `Preconditions:` and — when the block has one —
   `Feature:`, and reads the `Last task number: N` header value for
   information only — it does not change.

2. Identify the tasks whose status matches the prune set. If there are
   none, tell the user "No tasks to prune." and stop.

3. Plan each pruned task's move: `.claude/tasks/<N>.md` →
   `.claude/tasks/archive/<N>.md`. Probe both paths with an existence
   check on the exact path (Glob) — never by listing the archive folder or
   opening a file in it:
   - **Source missing** — note it in the plan but do not error out. Nothing
     is archived for that task; its summary block still leaves `TASKS.md`.
   - **Destination already exists** — refuse that move in the plan rather
     than overwrite. Ids are unique, so the file can only have been placed
     by hand. The task drops out of the prune set: its summary block and
     its body stay where they are, and the plan names the file so the user
     can deal with it before re-running.
   - **`.claude/tasks/archive/` missing** — normal before the first
     archive; PHASE 2 creates it. Never an error.

4. For each surviving task — including any refused in step 3 — find any
   `Preconditions:` line that references a pruned task ID. Plan to drop
   those references (an archived precondition is a satisfied one); if the
   list becomes empty, the line becomes `Preconditions: none`. Do NOT plan
   any renumbering — task IDs are stable.

5. Render the plan:

   ```
   PLAN — task-clean

   Index file: .claude/TASKS.md
   Pruning statuses: [DONE], [SKIP]   (or whatever set applies)
   Archive: .claude/tasks/archive/    (created by this run)   ← only when it does not exist yet

   Tasks to archive (N):
     3.  [DONE]  Title …   .claude/tasks/3.md  → .claude/tasks/archive/3.md
     7.  [DONE]  Title …   .claude/tasks/7.md  → .claude/tasks/archive/7.md
     12. [SKIP]  Title …   .claude/tasks/12.md — MISSING, nothing to archive; the block still leaves TASKS.md

   Refused (K):                                  (omit when none)
     9.  [DONE]  Title …   .claude/tasks/archive/9.md already exists — not overwritten; task 9 stays in the backlog

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

3. Move the per-task body files into the archive, each as a VCS rename so
   history follows the file. Use Bash:
   `mkdir -p .claude/tasks/archive && git mv .claude/tasks/3.md .claude/tasks/archive/3.md && git mv .claude/tasks/7.md .claude/tasks/archive/7.md`
   When the project's CLAUDE.md carries a `## VCS` section, use its
   mapping's equivalent of `git mv` instead. A body the VCS does not track
   yet moves with a plain `mv`. Skip the tasks the plan flagged as missing
   or refused.

4. Use the Edit tool to write the frozen header into each moved file,
   directly under its title. The header's form is `resolution.md`
   § *The archive*; its values come from the summary block PHASE 1 parsed,
   and `Archived:` is today's date. Change nothing else in the file.

5. Do NOT touch the `Last task number:` line — `resolution.md` § *Index file
   format* is why it only ever increases.

6. After editing, use Grep to re-check `.claude/TASKS.md` for any
   `Preconditions:` reference to a now-archived task ID. Confirm no stale
   references remain.

7. Report to the user:
   - Number of summary blocks removed from `TASKS.md`.
   - Each body file archived, as `<old path> → <new path>`, and any that
     were already missing or refused.
   - Number of `Preconditions:` lines rewritten.
   - Final task count.
   - The unchanged `Last task number:` value.

After the report, continue to PHASE 3.

---

PHASE 3 — COMMIT AND PUSH

Commit and push gating — the flags, pull-at-start, staging, one commit per
prune, the push protocol, and what to do when a commit or a push fails — is
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`. Its
`/task-clean` note carries this skill's own specifics: the commit message
form, the exact path list PHASE 2 leaves to stage — `.claude/TASKS.md` plus
each archived file, PHASE 2's `git mv` having already staged both halves of
every move — and that PHASE 3 is its only shell use apart
from the `mkdir -p` / `git mv` in PHASE 2. Once PHASE 2 completes
successfully the commit happens automatically — PHASE 1's **"Apply?"** was
the run's only gate, and no further prompt is asked here.

Under `--no-commit` the move still happens — it is the prune's effect, not
a commit step — so each rename sits in the working tree and PHASE 2's
`mkdir -p` / `git mv` are the skill's only shell use. Report what was
changed — blocks removed, each body moved and where it went,
`Preconditions:` lines rewritten — and stop.

DO NOT:
- Write to any file, or move one, during PHASE 1.
- Delete a body file. Every pruned body is moved into the archive, or
  noted in the plan as already missing.
- Overwrite a file in `.claude/tasks/archive/`, or look inside that folder
  beyond PHASE 1's existence check on each destination.
- Renumber surviving tasks. Task IDs are stable — re-using a number for
  a different task in the future would silently break historical
  references in commit messages, comments, and external systems.
- Decrement the `Last task number:` counter, even if you just archived
  the task with the highest ID.
- Touch tasks whose status is not in the prune set.
- Add `[STALE]` to the default prune set.
- Change task content other than `Preconditions:` lines on survivors and
  the frozen header written into each archived body.
