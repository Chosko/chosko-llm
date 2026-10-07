---
name: task-clean
version: 0.11.2
type: skill
description: Prune tasks in a terminal status from the backlog by archiving them — each summary block leaves TASKS.md and the body moves to .claude/tasks/archive/<N>.md, never deleted. Use it when finished tasks clutter the backlog; a backfill mode recovers, from git history, bodies earlier runs deleted.
replaces: command:task-clean
requires: skill:task-engine, skill:interaction-engine
project-policy: vcs:mv, vcs:show, vcs:branch
---

# /task-clean
# Global skill: archive the backlog's tasks in a terminal status — remove
# each matched summary block from `.claude/TASKS.md` and move its
# `.claude/tasks/<N>.md` body to `.claude/tasks/archive/<N>.md` under a
# frozen header recording the summary block it had. Every prune also sweeps orphaned `park/task-<N>` branches at the same
# confirmation. Commits and pushes by default.
# Usage: /task-clean
#        /task-clean <STATUS> [<STATUS> ...]
#        /task-clean --backfill                   (recover bodies earlier runs deleted)
#        /task-clean [<STATUS> ...] --no-commit   (write changes, skip the commit and push)
#        /task-clean <any of the above> --attended | --unattended   (every gate here waits either way)
#        /task-clean [<STATUS> ...] --no-push     (commit as usual, skip the push)
# Examples: /task-clean
#           /task-clean DONE
#           /task-clean DONE SKIP
#           /task-clean DONE --no-commit
#           /task-clean --backfill

## GOAL

- Archive finished or abandoned tasks so the backlog stays focused on work
  that still needs doing: each summary block leaves `.claude/TASKS.md`, and
  the body file moves into the archive, keeping the record of the task.
- Rewrite every `Preconditions:` reference in surviving summary blocks that
  pointed at an archived task.
- Delete the parking branches no parked or resumed task needs any more.
- Always confirm with the user before writing. Never renumber, never reuse
  a pruned ID, and never delete a body.

$ARGUMENTS

## ARGUMENT NOTE

1. Before PHASE 1, scan `$ARGUMENTS` for `--commit`, `--no-commit` and
   `--no-push` and strip whichever appear. Those flags, and everything they
   gate, are `../task-engine/references/commit.md`.
2. Scan for `--attended` and `--unattended` and strip whichever appear.
   - Resolve the run's interaction policy from them, a policy handed down by
     a parent run and the project's `CLAUDE.md`, per
     `../interaction-engine/references/policy.md`, which also holds their
     argument errors.
   - Every gate here is `destructive`, so the policy changes no gate: under
     `unattended`, where nobody answers, stop at the gate with its plan,
     writing nothing.
   - Read `../interaction-engine/references/messages.md` before the gate;
     the final report follows its output rules.
3. Scan for `--backfill`. When it appears, set BACKFILL = true and strip it.
   It is a mode, not a prune set: if anything is left in `$ARGUMENTS` after
   stripping it, stop with:
   `--backfill cannot be combined with a status set. Run /task-clean <STATUS> ... and /task-clean --backfill separately.`
4. Otherwise treat what is left as this skill's own argument — a status set,
   or empty for the default.
5. When BACKFILL is true, read `./backfill.md` once LOCATING THE BACKLOG
   below has run, and follow it in place of PHASE 1 through PHASE 3.

---

## LOCATING THE BACKLOG

- Resolve the backlog per `../task-engine/references/resolution.md`. Its
  `/task-clean` note carries every way this skill departs from it: the
  wording of the not-initialised stop, the fields it parses out of each
  summary block, the single reason it opens a body file — probing that the
  file exists before planning its move — and the one existence check it
  makes inside the archive as that archive's only writer.
- Where the archive lives, what an archived file holds, and what an id
  absent from `TASKS.md` means are that file's § *The archive*.
- Pull at start, before PHASE 1 begins, per `commit.md`.

---

## WHICH STATUSES COUNT AS "TERMINAL"

- The status vocabulary, which of the tags are terminal, and how a status
  argument is accepted are `../task-engine/references/status.md`. Its
  `/task-clean` note carries what this skill does with them.
- Treat a status as a prune set — never a display filter, never a task
  selector. Write no status anywhere: this skill removes whole summary
  blocks.
- With no argument, the prune set is the terminal pair, `[DONE]` and
  `[SKIP]`.
- An explicit set replaces that default rather than adding to it. Any
  canonical status may be named; when a named one is non-terminal, carry
  `status.md`'s warning for it into the plan. Archive a non-terminal task
  named that way exactly like a terminal one; its frozen `Status:` records
  that it was pruned live.
- `[STALE]` and `[PARKED]` are never in the default set.
  - `[STALE]` — what it means, and why it is live work awaiting
    reconciliation rather than abandoned work, are
    `../task-engine/references/stale.md`. When the user names it explicitly,
    say all of that in the plan and confirm before applying.
  - `[PARKED]` — live work waiting on an answer, with its work-in-progress
    on a `park/task-<N>` branch. When the user names it explicitly, carry
    `status.md`'s warning into the plan — the prune discards the question
    and orphans that branch, named per task, which the next run's
    PARK-BRANCH SWEEP deletes — and confirm before applying.

---

## THE FEATURE INDEX

- Never open `.claude/FEATURES.md` in a prune — not to read it, not to
  write it.
- A feature keeps every task id it ever generated on its `Tasks:` line,
  archived ones included, so `Tasks: none` means what it says: the feature
  was never planned. What an id on that line with no summary block means is
  `resolution.md` § *The archive*, and nothing needs rewriting to say so.

---

## THE PARK-BRANCH SWEEP

`/task-implement` keeps a parked task's work-in-progress on a
`park/task-<N>` branch and deletes it, best-effort, once the unparked task
has committed; a delete that was refused, or a parked task pruned or
replaced, leaves one behind.

- Sweep those on every prune, on the one **"Apply?"** gate, so a delete
  that needs a permission prompt runs where a person can approve it.
- Skip the sweep entirely when the project's CLAUDE.md carries a `## VCS`
  section — there are no git branches to sweep.
- **List.** Local branches with `git branch --list 'park/task-*'`; remote
  ones with `git ls-remote --heads origin 'refs/heads/park/task-*'`, unless
  NO_PUSH — then remote branches are neither listed nor deleted
  (`commit.md`'s `/task-clean` note).
- **Orphaned** means task N has no summary block in `.claude/TASKS.md`, or
  has one whose `Status:` is neither `[PARKED]` nor `[IN PROGRESS]` — an
  unparked task that stopped before its commit still needs the branch as
  its rollback source. Judge it against `TASKS.md` as PHASE 1 read it, never
  a body, so a `[PARKED]` task this run prunes keeps its branch until the
  next run.
- **Delete** each orphan in PHASE 2, only after approval:
  `git branch -D park/task-<N>` for a local one,
  `git push origin --delete park/task-<N>` for a remote one. Report a delete
  that fails in PHASE 2's report; it is neither fatal nor retried.
- With no orphans, add no plan section and say nothing about the sweep.

---

## PHASE 1 — REPORT (no file writes, no moves)

1. Read `.claude/TASKS.md` and parse it as `resolution.md` § *Parsing the
   index* describes. Use each summary block's number, title, status,
   `Files:`, `Preconditions:` and — when the block has one — `Feature:`.
   Read the `Last task number: N` header value for information only — it
   does not change.

2. Identify the tasks whose status matches the prune set, and list the
   orphaned park branches per THE PARK-BRANCH SWEEP.
   - Neither → tell the user "No tasks to prune." and stop.
   - Orphans but no tasks → steps 3 and 4 have nothing to plan; the plan
     holds only the sweep.

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
   list becomes empty, the line becomes `Preconditions: none`. Plan no
   renumbering — task IDs are stable.

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

   Park branches to delete (J):                  (omit when none)
     park/task-42   local + remote   task 42 is [DONE]
     park/task-17   remote           task 17 has no summary block
     (remote not checked — --no-push)            ← only under NO_PUSH

   Anything in [IN PROGRESS]? <yes/no — if yes, list them as a heads-up
   so the user notices unfinished work before pruning around it>
   ```

   End with a single explicit prompt: **"Apply?"** Gate class:
   `destructive` (`../interaction-engine/references/gates.md`).

6. Wait for the user.
   - If they ask to change the prune set or exclude specific tasks,
     re-render the plan after the change.
   - Do not proceed to PHASE 2 without an explicit approval ("yes", "go",
     "apply", or similar). Silence is not approval.

---

## PHASE 2 — APPLY (only after explicit approval)

Touch no task whose status is not in the prune set. Change no task content
other than the `Preconditions:` lines on survivors and the frozen header
written into each archived body.

1. Use the Edit tool on `.claude/TASKS.md` to remove each matched
   summary block, including the `---` separator line that precedes it.
   Preserve the file's overall formatting (blank lines between
   surviving blocks, the header, the counter line).

2. Use the Edit tool to rewrite every `Preconditions:` line per the
   plan.

3. Move the per-task body files into the archive, each as a VCS rename so
   history follows the file. Use Bash:
   `mkdir -p .claude/tasks/archive && git mv .claude/tasks/3.md .claude/tasks/archive/3.md && git mv .claude/tasks/7.md .claude/tasks/archive/7.md`
   - When the project's CLAUDE.md carries a `## VCS` section, use its
     mapping's equivalent of `git mv` instead.
   - Move a body the VCS does not track yet with a plain `mv`.
   - Skip the tasks the plan flagged as missing or refused.

4. Use the Edit tool to write the frozen header into each moved file,
   directly under its title. The header's form is `resolution.md`
   § *The archive*; its values come from the summary block PHASE 1 parsed,
   and `Archived:` is today's date. Change nothing else in the file.

5. Do not touch the `Last task number:` line, even when this run archived
   the task with the highest ID — `resolution.md` § *Index file format* is
   why it only ever increases.

6. Use Grep to re-check `.claude/TASKS.md` for any `Preconditions:`
   reference to a now-archived task ID. Confirm no stale references remain.

7. Delete each orphaned park branch the plan listed, local and remote as
   it named, per THE PARK-BRANCH SWEEP.

8. Report to the user:
   - Number of summary blocks removed from `TASKS.md`.
   - Each body file archived, as `<old path> → <new path>`, and any that
     were already missing or refused.
   - Number of `Preconditions:` lines rewritten.
   - Each park branch deleted, local and remote, and any delete that
     failed, with its output.
   - Final task count.
   - The unchanged `Last task number:` value.

9. Continue to PHASE 3.

---

## PHASE 3 — COMMIT AND PUSH

- Commit and push gating — the flags, pull-at-start, staging, one commit
  per prune, the push protocol, and what to do when a commit or a push
  fails — is `../task-engine/references/commit.md`. Its `/task-clean` note
  carries this skill's own specifics:
  - the commit message form;
  - the exact path list PHASE 2 leaves to stage — `.claude/TASKS.md` plus
    each archived file, PHASE 2's `git mv` having already staged both
    halves of every move;
  - that PHASE 3 is its only shell use apart from the `mkdir -p` /
    `git mv` in PHASE 2 and the park-branch sweep;
  - which of the sweep's operations run under which flag.
- Once PHASE 2 completes successfully, commit automatically — PHASE 1's
  **"Apply?"** was the run's only gate; ask no further prompt here.
- A run that only swept branches changed no file and commits nothing.
- Under `--no-commit`:
  - The move still happens — it is the prune's effect, not a commit step —
    so each rename sits in the working tree.
  - The sweep deletes local branches only.
  - Report what was changed — blocks removed, each body moved and where it
    went, `Preconditions:` lines rewritten, branches deleted — and stop.
