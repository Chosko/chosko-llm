# Backfill (`--backfill`)

Read this when BACKFILL is true — `/task-clean` was invoked with
`--backfill`. An ordinary prune never opens this file, and nothing here
applies to one.

Backfill recovers what earlier `/task-clean` runs deleted, for a project
that pruned before the archive existed: each per-task body that git history
records as deleted comes back into `.claude/tasks/archive/<N>.md` under a
frozen header, and its id goes back on the `Tasks:` line of the feature
that generated it. It is an explicit act — no prune triggers it, runs it or
suggests it — in the register `/pipeline-check` keeps for a one-off check:
the user asks for it when they want it, and nothing else ever starts it.

The archived-file form and what an id absent from `TASKS.md` means are
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
§ *The archive*. This file states only how backfill fills that form from
history, and the one place it departs from it.

`SKILL.md`'s LOCATING THE BACKLOG and its pull at start have already run.
This file replaces PHASE 1 through PHASE 3 there; the gate, the commit and
the push keep the same shape.

---

## Git only

Recovery reads git history. When the project's CLAUDE.md carries a `## VCS`
section overriding git, or the project is not a git repository at all, stop
before reading anything else:

> `--backfill` recovers deleted task bodies from git history, and this
> project's version control is not git. There is no recovery path for it;
> nothing was changed.

There is no `cm` port and no other history source: the stop is the whole of
the non-git behaviour.

---

## PHASE B1 — DISCOVER AND REPORT (no file writes)

1. **Live ids.** Read `.claude/TASKS.md` and collect the id of every
   summary block. The `Last task number:` line is not used and never
   changes.

2. **Deletions.** List every deletion git history records under
   `.claude/tasks/`, newest first:

   ```
   git log --diff-filter=D --format='@@ %H %as' --name-only -- .claude/tasks/
   ```

   Keep only paths of the form `.claude/tasks/<N>.md` — a direct child of
   `.claude/tasks/`, `<N>` a number. For each path keep the **first**
   commit listed, the newest: the latest deletion is the one that left the
   file gone. That is the task's deleting commit.

3. **Drop what needs no recovery.** Drop an id when any of these holds:
   - it is live in `TASKS.md` (step 1);
   - `.claude/tasks/<N>.md` exists in the working tree again;
   - `.claude/tasks/archive/<N>.md` already exists.

   Check the last two with an existence check on that exact path (Glob) —
   never a listing of the archive folder, never opening a file in it.

4. **Nothing left.** When step 2 found no deletion, or step 3 dropped every
   id, say which and stop — no plan, no **"Apply?"**, no commit:

   > Nothing to recover — git history records no deleted task body under
   > `.claude/tasks/`.

   > Nothing to recover — every task body git history records as deleted
   > is live in `TASKS.md` or already archived.

   A second backfill lands on the second message. Never report an empty
   run as a success.

5. **Recover each remaining id** from its deleting commit's parent,
   `<commit>^`:
   - the body is `git show <commit>^:.claude/tasks/<N>.md`;
   - the header's values come from the `## <N>. <title>` summary block in
     `git show <commit>^:.claude/TASKS.md`, parsed as `resolution.md`
     § *Parsing the index* describes;
   - `Archived:` is the deleting commit's date (`%as` above), not today's,
     so the header tells the truth about when the task left the backlog.

   A body whose summary block the parent's `TASKS.md` does not carry was
   deleted by hand, not pruned. It is archived with `Archived:` alone and
   flagged in the plan — backfill's one departure from the archived-file
   form, and the only way a header carries fewer lines than that form
   names.

6. **Feature links.** For each recovered block carrying `Feature: <slug>`,
   read `.claude/FEATURES.md`:
   - the slug has an entry → plan to put the id back on that entry's
     `Tasks:` line at its ascending position — before the first id greater
     than it — or as the line's only id when it reads `Tasks: none`. An id
     already on the line needs nothing.
   - the slug has no entry → report it; write nothing for it.
   - `.claude/FEATURES.md` does not exist → no link can be restored; say so
     once in the plan.

   Nothing else in `FEATURES.md` is planned: no `Status:`, no `Doc:`, no
   `Source:`. This is the only `.claude/FEATURES.md` write left in
   `/task-clean`, and it exists only on this path.

7. **Render the plan:**

   ```
   PLAN — task-clean --backfill

   Source: git history of .claude/tasks/   (<D> deleted bodies found, <K> dropped as live or already archived)
   Archive: .claude/tasks/archive/          (created by this run)   ← only when it does not exist yet

   Tasks to recover (R):
     88.  —       Title …   deleted in 1a2b3c4 (2026-05-02)  → .claude/tasks/archive/88.md
                            no summary block in 1a2b3c4^ — hand deletion; header carries Archived: only
     150. [DONE]  Title …   deleted in c868de7 (2026-09-11)  → .claude/tasks/archive/150.md
     151. [SKIP]  Title …   deleted in c868de7 (2026-09-11)  → .claude/tasks/archive/151.md

   Feature Tasks: lines to restore (F):         (omit when none)
     Feature task-archive: Tasks "196, 199" → "150, 196, 199"   (adding 150)

   Feature slugs no longer in FEATURES.md (S):  (omit when none)
     old-feature — tasks 12, 13   (not written)

   TASKS.md: unchanged. Feature statuses: unchanged.
   ```

   Ids ascending. The title is the parent block's, or the body's own title
   line for a hand deletion.

   End with a single explicit prompt: **"Apply?"** — the same gate as a
   prune. If the user asks to exclude specific ids, re-render the plan
   after the change. Do NOT proceed to PHASE B2 without an explicit
   approval. Silence is not approval.

---

## PHASE B2 — APPLY (only after explicit approval)

1. Create `.claude/tasks/archive/` when it does not exist (`mkdir -p`).

2. For each recovered id, write the body byte-for-byte from history:
   `git show <commit>^:.claude/tasks/<N>.md > .claude/tasks/archive/<N>.md`
   Then use the Edit tool to write the frozen header directly under its
   title, in the form `resolution.md` § *The archive* gives, with the
   values step 5 recovered. Change nothing else in the body.

3. Use the Edit tool to restore each planned `Tasks:` line in
   `.claude/FEATURES.md`. Nothing else in that file changes.

4. Do NOT write `.claude/TASKS.md`. A recovered task is archived, not live;
   backfill never returns one to the backlog.

5. Report to the user:
   - Each body recovered, as `<N> → .claude/tasks/archive/<N>.md`, with its
     deleting commit, and which of them were flagged as hand deletions.
   - Each feature whose `Tasks:` line was restored, and which ids went back
     on it. Say explicitly that feature statuses were left as they were.
   - Each slug reported as no longer in `FEATURES.md`.

After the report, continue to PHASE B3.

---

## PHASE B3 — COMMIT AND PUSH

Commit and push gating is
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`,
exactly as for a prune. Its `/task-clean` note carries backfill's own
specifics: the commit message form, the archive paths it stages, and that
`.claude/FEATURES.md` joins them when a `Tasks:` line was restored. Once
PHASE B2 completes successfully the commit happens automatically — PHASE
B1's **"Apply?"** was the run's only gate.

Under `--no-commit`, report what was written — each archived file and each
`Tasks:` line restored — and stop.

DO NOT:
- Run on a project whose VCS is not git, or reach for any other history
  source.
- Write `.claude/TASKS.md`, or return an archived task to the live backlog.
- Overwrite a file in `.claude/tasks/archive/`, or look inside that folder
  beyond PHASE B1's existence check on each destination.
- Change any field of `.claude/FEATURES.md` other than a `Tasks:` line, or
  write a link for a slug it no longer has.
- Run as part of a prune, or alongside a status set.
