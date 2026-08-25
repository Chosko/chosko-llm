---
name: runbook-clean
version: 0.1.0
type: command
description: Prune finished runbooks — delete each body file under .claude/runbooks/ and remove its .claude/RUNBOOKS.md index block, including the surrounding --- rules. With no argument the plan is every [DONE] runbook; with names, exactly those. Only [DONE] is eligible — [PENDING] is unstarted work, [RUNNING] is a run someone is in the middle of, and [FAILED] is a halt that still needs a decision — and there is no --force and no status argument widening the set. A named runbook that is not [DONE] is refused by name with its actual status, an unknown name aborts the whole run before anything is deleted, and an empty plan says so and stops without asking. Always plans and confirms before writing. Automatically commits and pushes the removals; pass --no-commit to leave them uncommitted, or --no-push to commit without pushing.
requires: skill:runbook-run
---

# /runbook-clean
# Global command: prune runbooks in the terminal status from the project's
# runbook store. Deletes the matched runbook's body file at
# `.claude/runbooks/<name>.md` and removes its summary block from
# `.claude/RUNBOOKS.md`. Always reports the plan and asks for explicit
# confirmation before writing or deleting anything.
# Usage: /runbook-clean
#        /runbook-clean <name> [<name> ...]
#        /runbook-clean [<name> ...] --no-commit   (delete, skip the commit and push)
#        /runbook-clean [<name> ...] --no-push     (commit as usual, skip the push)
# Examples: /runbook-clean
#           /runbook-clean ecc-import-landing
#           /runbook-clean ecc-import-landing context-layer-refresh
#           /runbook-clean --no-commit

GOAL
Remove finished runbooks so the store stays useful for the one question it
exists to answer — what is still to be done, and how far it got. Delete both
the body file and the index block. Always confirm before writing.

Removal is an **explicit act, never a consequence of completion**. Reaching
`[DONE]` deletes nothing on its own: the `Done:` lines are the record of what
was decided while the work was being done, and they are re-read far more often
than anyone expects. That durability is the whole point, and it is also why
this command has to exist — the store is committed and grows without bound,
and a directory holding a year of finished runbooks makes `/runbook-list`
useless.

$ARGUMENTS

---

ARGUMENT NOTE

Scan `$ARGUMENTS` and strip the flags below before STAGE 1 resolves anything;
what is left is this command's own argument — a list of runbook names, or
empty for the default.

| Flag | Effect |
| --- | --- |
| `--no-commit` | Set NO_COMMIT = true. Delete and rewrite the index, but make no commit and no push. |
| `--no-push` | Set NO_PUSH = true. Commit as usual, skip the pull/re-sync/push. |

NO_COMMIT implies NO_PUSH — there is nothing to push. There is **no
`--force`**, and there is **no status argument**; see WHY ONLY `[DONE]` below
for the reason both are absent. An argument that looks like a status rather
than a runbook name is an unknown name, and STAGE 1 handles it as one.

---

THE ARTIFACT

The four-status vocabulary and the shape of an index block — its five fields
and the conditional `Failed at:` line — are specified in
`${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`.
Read it before parsing the index. **Neither is restated here** — a second copy
is the copy that drifts, and a pruner whose idea of the status set has drifted
from the runner's deletes the wrong thing.

---

WHY ONLY `[DONE]`

`[DONE]` is the only eligible status, and each of the other three is ineligible
for its own reason:

- **`[PENDING]`** is unstarted work. Deleting it discards a plan nobody has
  had a chance to execute.
- **`[RUNNING]`** is a run someone is in the middle of. There may be a live
  session holding that name right now.
- **`[FAILED]`** is the status most likely to be misread as finished. It is
  not a finished runbook; it is the **record of a halt that still needs a
  decision**, and the `Failed at:` line is the only place the reason is
  written down outside the body.

**There is no `--force` and no status argument widening the set.** A user who
genuinely wants a `[FAILED]` runbook gone flips its status by hand first — one
visible, committed edit that leaves a trace in the history. A flag would make
the same deletion invisible.

This is deliberately **narrower than `/task-clean`**, which prunes `[DONE]`
and `[SKIP]`. Runbooks have no second terminal status: there is no `[SKIP]`
in the runbook vocabulary at all.

---

STAGE 1 — RESOLVE (no file writes, no deletions)

1. Read `.claude/RUNBOOKS.md`. If it does not exist, or holds no blocks, that
   is **not an error** — tell the user "No runbooks in this project." and
   stop. Do not create it and do not suggest a setup command.

2. Parse every block per `runbook-schema.md` § *The index block*: the name and
   one-line title from the heading, then `Status:`, `File:`, `Created:`,
   `Source:` and `Steps:`. `/runbook-clean` is the one runbook command that
   needs `File:` — it is the path to delete.

3. Resolve the set:

   - **No argument** — every runbook whose status is `[DONE]`. Nothing else.
   - **Names given** — exactly those runbooks, in the order the user named
     them. The set is never widened past what was asked for.

4. **An unknown name aborts the whole run**, before anything is deleted. Say
   which name is not in the index, list the names that are, and stop — do not
   remove the names that were recognised. A partial deletion from a mistyped
   list is the worst outcome available here, and it is silent: the user sees a
   success report naming fewer runbooks than they typed and has no reason to
   re-read it.

5. **A named runbook that is not `[DONE]` is refused by name, with its actual
   status** — never silently skipped. The user asked for it explicitly, and a
   skip that is not said out loud reads as a successful removal:

   > `cli-dependency-field` is `[FAILED]`, not `[DONE]` — refusing.
   > Only `[DONE]` runbooks are eligible. A `[FAILED]` runbook is the record
   > of a halt that still needs a decision; flip its status by hand if you
   > genuinely want it gone.

   Carry the matching reason from WHY ONLY `[DONE]` for whichever status it
   is. Refusing one name does not abort the run the way an unknown name does —
   the name exists, and the rest of the plan is still coherent. Report the
   refusal, drop that runbook from the set, and carry on to STAGE 2 with what
   is left.

6. **An empty plan says so and stops**, without asking anything — no
   confirmation prompt for a no-op. With no argument: "No `[DONE]` runbooks to
   prune." With names, where every one was refused: say that nothing remains
   eligible after the refusals.

---

STAGE 2 — PLAN AND CONFIRM

Render the plan. Print **both paths** for every runbook — the body file and
the index block — because they are two separate deletions in two separate
files, and a user approving this needs to see that both go:

```
PLAN — runbook-clean

Index file: .claude/RUNBOOKS.md

Runbooks to remove (2):
  ecc-import-landing    [DONE]  7/7   created 2026-08-24
      body file:   .claude/runbooks/ecc-import-landing.md
      index block: .claude/RUNBOOKS.md
  context-layer-refresh [DONE]  3/3   created 2026-08-26
      body file:   .claude/runbooks/context-layer-refresh.md
      index block: .claude/RUNBOOKS.md

Refused (1):
  cli-dependency-field  [FAILED] — only [DONE] is eligible

Nothing else in .claude/runbooks/ is touched.
```

- Take the name, status, `Steps:` and `Created:` values from the index
  verbatim. `Steps:` is printed as the index carries it.
- Probe each body path with the Read tool before listing it. A body file that
  is unexpectedly missing is **noted in the plan** — `(body file: … —
  MISSING)` — and does not error out; its index block is still removed, which
  is exactly the reconciliation the user wants.
- Omit the `Refused` section entirely when nothing was refused.

End with a single explicit prompt: **"Apply?"**

Wait for the user. **Nothing is written or deleted before an explicit
answer** — "yes", "go", "apply" or similar. Silence is not approval. If the
user asks to drop a runbook from the set, re-render the whole plan after the
change.

---

STAGE 3 — REMOVE AND COMMIT (only after explicit approval)

### Remove

1. Delete each body file. Use Bash:
   `rm .claude/runbooks/ecc-import-landing.md .claude/runbooks/context-layer-refresh.md`
   Skip any the plan flagged as already missing.

2. Use the Edit tool on `.claude/RUNBOOKS.md` to remove each matched index
   block **including its surrounding `---` rules**. A block that is deleted
   without them leaves a doubled rule behind, and the file slowly fills with
   separators fencing nothing.

   Preserve everything else: the title line, the blank lines between surviving
   blocks, and the order of the survivors. An index with every block removed
   is left as its title line and nothing else — do not delete the file.

3. **Touch no runbook this command is not deleting.** No status is corrected,
   no `Steps:` count recomputed, no `Failed at:` line rewritten, however wrong
   any of them looks. Reconciliation belongs to `/runbook-run`, which re-reads
   the body every step.

4. **Never edit a body file.** The only thing this command does to a body is
   delete it whole.

5. Report:
   - Each runbook removed, by name, with its status and steps.
   - The body files deleted, and any that were already missing.
   - The index blocks removed.
   - Each name refused and why, repeated from the plan so the closing report
     is complete on its own.
   - The number of runbooks remaining in the index.

### Commit and push

This command **commits and pushes by default** — the cleanup convention, not
the authoring one. `/task-clean` has the same default for the same two
reasons: a deletion left uncommitted is the change most likely to be lost, and
STAGE 2's **"Apply?"** has already served as the review pass that an authoring
command's uncommitted output exists to allow. STAGE 2 is this run's only gate;
no further prompt is asked here.

Under `--no-commit`, the `rm` in STAGE 3 is this command's only shell use:
report what was removed and stop.

Otherwise follow the commit-and-push protocol — four steps, in this order:

1. **Pull at start.** `git pull` on the current branch, before STAGE 1 reads
   the index (i.e. at the top of the run, not here). A conflict stops the run
   there, before anything is planned: report the output and tell the user to
   resolve manually and re-run.
2. **Commit.** Stage **exactly** the deleted body paths and
   `.claude/RUNBOOKS.md`, by explicit path, and make one commit:

   ```
   git add -- .claude/runbooks/ecc-import-landing.md .claude/RUNBOOKS.md
   git commit -m "Prune 1 done runbook: ecc-import-landing"
   ```

   `git add -- <path>` stages a deletion as well as a modification, so the
   removed bodies and the rewritten index go in together. **Never a catch-all**
   (`git add -A` / `git add .` / `git add -u`), never an empty commit, never
   `--no-verify` / `--amend` / `--no-gpg-sign`. On commit failure, surface the
   exact output, do not retry, and tell the user the changes remain staged.
3. **Pre-push re-sync.** `git pull` again, immediately before pushing. On a
   conflict: abort the merge, leave the local commit intact, do **not** push,
   and report that the commit exists locally but could not be synced.
4. **Push.** `git push`. On failure (rejected, no upstream, no remote) report
   the exact output and stop. Never retry, never force-push.

Under `--no-push`, run step 2 only. On a non-git VCS — a project whose
`CLAUDE.md` defines a `## VCS` section overriding git — skip steps 1, 3 and 4
entirely and use that mapping for the commit.

---

DO NOT:
- Write to or delete any file before STAGE 2's **"Apply?"** is answered.
- Remove a runbook whose status is anything other than `[DONE]`.
- Accept a `--force` flag, a status argument, or any other way of widening the
  eligible set. Neither exists; a user who wants a non-`[DONE]` runbook gone
  flips its status by hand first.
- Skip a named non-`[DONE]` runbook silently. Refuse it by name, with its
  actual status.
- Delete anything at all when a name is unknown. Abort the whole run first.
- Ask for confirmation on an empty plan. Say it is empty and stop.
- Remove an index block without its surrounding `---` rules.
- Edit a runbook body file, for any reason.
- Change a `Status:`, `Steps:`, `Created:`, `Source:` or `Failed at:` line on a
  surviving runbook, however wrong it looks. That is `/runbook-run`'s to fix.
- Delete `.claude/RUNBOOKS.md` or `.claude/runbooks/` when the last runbook
  goes. An empty index is its title line; the directory stays.
- Restate the status vocabulary or the index block's shape in this body. They
  are
  `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`,
  cited and never copied.
- Touch `.claude/TASKS.md`, `.claude/FEATURES.md`, or any file outside
  `.claude/runbooks/` and `.claude/RUNBOOKS.md`. Runbooks carry no cross-store
  references — nothing points at a runbook the way a task's `Preconditions:`
  line points at a task id — so there is nothing to rewrite after a removal,
  and names of removed runbooks are not reserved.
- Run, resume, author or append to a runbook. Those are `/runbook-run` and
  `/runbook-create`.
- Run any git command other than the protocol above; never force-push, retry a
  failed push, branch, or tag.
