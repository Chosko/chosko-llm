---
name: runbook-clean
version: 0.3.0
type: command
description: Prune finished runbooks — delete each [DONE] runbook's body under .claude/runbooks/ and remove its .claude/RUNBOOKS.md index block, every finished runbook by default or exactly the ones named. Use it once a runbook's work has landed and its record is no longer needed.
disable-model-invocation: true
requires: skill:runbook-run
---

# /runbook-clean
# Global command: prune runbooks in the terminal status from the project's
# runbook store. Deletes the matched runbook's body file at the path its
# index block's `File:` line holds and removes that block from
# `.claude/RUNBOOKS.md`. Always reports the plan and asks for explicit
# confirmation before writing or deleting anything. Only [DONE] is eligible
# — [PENDING], [RUNNING] and [FAILED] never are — and there is no `--force`
# and no status argument widening the set. A named runbook that is not
# [DONE] is refused by name with its actual status; an unknown name aborts
# the whole run before anything is deleted; an empty plan says so and stops.
# A body is deleted at whatever path its `File:` line holds and never
# renamed; survivors are never renumbered and the counter never moves down.
# Every run also sweeps the `wt/runbook-<id>-step-<n>` worktrees and
# branches whose step is [x], or whose runbook it is removing, at the same
# confirmation. Commits and pushes the removals by default.
# Usage: /runbook-clean
#        /runbook-clean <id|name|id-name> [<id|name|id-name> ...]
#        /runbook-clean [<id|name|id-name> ...] --no-commit   (delete, skip the commit and push)
#        /runbook-clean [<id|name|id-name> ...] --no-push     (commit as usual, skip the push)
# Examples: /runbook-clean
#           /runbook-clean ecc-import-landing
#           /runbook-clean 1 5
#           /runbook-clean 1-ecc-import-landing
#           /runbook-clean ecc-import-landing context-layer-refresh
#           /runbook-clean --no-commit

GOAL
Remove finished runbooks so the store stays useful for the one question it
exists to answer — what is still to be done, and how far it got. Delete both
the body file and the index block, and remove the worktrees finished steps
left behind. Always confirm before writing.

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
what is left is this command's own argument — a list of runbooks, each as
`<id>`, `<name>` or `<id>-<name>`, or empty for the default.

| Flag | Effect |
| --- | --- |
| `--commit` | Accepted and stripped, a silent no-op: committing is the default. Refused beside `--no-commit` with `--commit and --no-commit cannot be combined. Pick one.` |
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
`../skills/runbook-run/references/runbook-schema.md`.
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

THE WORKTREE SWEEP

A parallel `/runbook-run` gives each step its own worktree at
`.claude/worktrees/runbook-<id>-step-<n>` on a branch
`wt/runbook-<id>-step-<n>`, and a step that failed or was interrupted leaves
both behind. The rule — what a leftover worktree means, why an unfinished
step's is never removed, and how a finished one's goes — is
`../skills/task-engine/references/worktree.md` § *The sweep*, reached
through `/runbook-run`'s own requirement on the engine; this command applies
it on the same **"Apply?"** gate as the removals, and skips it when the
project's CLAUDE.md carries a `## VCS` section — there are no worktrees to
sweep. Its own specifics:

- **List.** Worktrees with `git worktree list --porcelain`, keeping the
  entries whose path is `.claude/worktrees/runbook-<id>-step-<n>` or whose
  branch is `wt/runbook-<id>-step-<n>`; branches with
  `git branch --list 'wt/runbook-*'`, so a branch whose worktree was already
  removed by hand is still found. Nothing is listed on the remote: a
  worktree and its branch are never pushed.
- **Finished** means runbook `<id>` is in the set STAGE 1 resolved for
  removal, or its index block's `File:` body holds step `<n>` as `[x]` as
  the schema reads it — an id on the header's `Archive:` line included.
  Reading that body for the marker is the one reason this command opens a
  body it is not deleting. A step with any other marker keeps its worktree
  and is not listed: that worktree may be the only copy of the work. A
  worktree whose runbook has no index block, or whose step the body does
  not hold, is kept too, and named in STAGE 3's report as left in place.
- **Remove** each finished one in STAGE 3, only after approval:
  `git worktree remove .claude/worktrees/runbook-<id>-step-<n>`, then
  `git branch -d wt/runbook-<id>-step-<n>`; a branch with no worktree is
  deleted alone. A remove or delete that fails is a *Follow-ups* item in
  STAGE 3's report naming the path and the command that failed — neither
  fatal nor retried, and nothing else of the sweep stops for it.

The sweep is local and changes no tracked file: it runs whole under
`--no-commit` and `--no-push`, and a run that only sweeps commits nothing.
No finished worktree means no plan section and nothing said about the
sweep.

---

STAGE 1 — RESOLVE (no file writes, no deletions)

1. Read `.claude/RUNBOOKS.md`. If it does not exist, or holds no blocks, that
   is **not an error** — tell the user "No runbooks in this project." and
   stop. Do not create it and do not suggest a setup command.

1b. **An index written before ids** — one with no `Last runbook number:` line,
   or blocks whose headings carry no id — is **backfilled by this command**,
   per `runbook-schema.md` § *Backfilling an index written before ids*. Work
   the ids out here, in order, so the plan can print them; **write them in
   STAGE 3**, with the deletions, under the same **"Apply?"**. Say in the plan
   that the backfill will land.

   It is written only on a run that deletes a runbook in STAGE 3. An empty
   plan stops at step 7 below without writing anything, backfill included, and
   a run that only sweeps writes nothing either — the schema gives the
   backfill to the first command that *writes* the index, and a run that
   deletes nothing never does.

2. Parse every block per `runbook-schema.md` § *The index block*: the id, the
   name and the one-line title from the heading, then `Status:`, `File:`,
   `Created:`, `Source:` and `Steps:`. `File:` is the path to delete — whatever
   it holds, an `<id>-<name>.md` path or a legacy `<name>.md` one, per
   `runbook-schema.md` § *`File:` is the body's path*. The path is never built
   from the name.

3. Resolve the set:

   - **No argument** — every runbook whose status is `[DONE]`. Nothing else.
   - **Runbooks given** — exactly those runbooks, in the order the user
     named them. Each argument — `<id>`, `<name>` or `<id>-<name>` — is
     resolved to one block by `runbook-schema.md` § *Resolving a runbook
     argument*, which is not restated here. The set is never widened past what
     was asked for.

4. **An argument that does not resolve aborts the whole run**, before anything
   is deleted — an unknown one, a compound whose halves disagree, or an
   ambiguity, each reported as the schema says. Say which argument did not
   resolve, list the runbooks that are in the index, and stop
   — do not remove the ones that were recognised. A partial deletion from a
   mistyped list is the worst outcome available here, and it is silent: the
   user sees a success report naming fewer runbooks than they typed and has no
   reason to re-read it.

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

6. List the finished worktrees per THE WORKTREE SWEEP, the removal set now
   known.

7. **An empty plan says so and stops**, without asking anything — no
   confirmation prompt for a no-op. A plan is empty when there is nothing
   to remove and nothing to sweep. With no argument: "No `[DONE]` runbooks to
   prune." With names, where every one was refused: say that nothing remains
   eligible after the refusals. With worktrees to sweep but no runbook to
   remove, the plan holds only the sweep.

---

STAGE 2 — PLAN AND CONFIRM

Render the plan. Print **both paths** for every runbook — the body file and
the index block — because they are two separate deletions in two separate
files, and a user approving this needs to see that both go:

```
PLAN — runbook-clean

Index file: .claude/RUNBOOKS.md

Runbooks to remove (2):
  1. ecc-import-landing    [DONE]  7/7   created 2026-08-24
      body file:   .claude/runbooks/1-ecc-import-landing.md
      index block: .claude/RUNBOOKS.md
  5. context-layer-refresh [DONE]  3/3   created 2026-08-26
      body file:   .claude/runbooks/5-context-layer-refresh.md
      index block: .claude/RUNBOOKS.md

Refused (1):
  2. cli-dependency-field  [FAILED] — only [DONE] is eligible

Worktrees to remove (2):
  .claude/worktrees/runbook-1-step-7   wt/runbook-1-step-7   runbook 1 is being removed
  (no worktree)                        wt/runbook-3-step-2   step 2 of runbook 3 is [x]

Nothing else in .claude/runbooks/ is touched.
```

- Take the name, status, `Steps:` and `Created:` values from the index
  verbatim. The id likewise, except where step 1b assigned it — say so on the
  line when it did, so a reader knows the number is new. `Steps:` is printed as the index carries it. Printing the id as
  well as the name is what lets a user check that the runbook they typed a
  number for is the one about to be deleted.
- The body file is the block's `File:` value, printed verbatim — a legacy
  `<name>.md` path is listed as it stands, never corrected to the prefixed
  form.
- Probe each body path with the Read tool before listing it. A body file that
  is unexpectedly missing is **noted in the plan** — `(body file: … —
  MISSING)` — and does not error out; its index block is still removed, which
  is exactly the reconciliation the user wants.
- Omit the `Refused` section entirely when nothing was refused, and the
  `Worktrees to remove` section when there is nothing to sweep.

End with a single explicit prompt: **"Apply?"**

Wait for the user. **Nothing is written or deleted before an explicit
answer** — "yes", "go", "apply" or similar. Silence is not approval. If the
user asks to drop a runbook from the set, re-render the whole plan after the
change.

---

STAGE 3 — REMOVE AND COMMIT (only after explicit approval)

### Remove

1. Delete each body file. Use Bash:
   `rm .claude/runbooks/1-ecc-import-landing.md .claude/runbooks/5-context-layer-refresh.md`
   — each path exactly as its block's `File:` holds it. Skip any the plan
   flagged as already missing.

2. Use the Edit tool on `.claude/RUNBOOKS.md` to remove each matched index
   block **including its surrounding `---` rules**. A block that is deleted
   without them leaves a doubled rule behind, and the file slowly fills with
   separators fencing nothing.

   Preserve everything else: the title line, the `Last runbook number:`
   counter, the blank lines between surviving blocks, and the order of the
   survivors. An index with every block removed is left as its title line and
   its counter, and nothing else — do not delete the file.

3. **Never renumber, and never move the counter down** —
   `runbook-schema.md` § *The index block*.

4. **Correct no derived field on a runbook this command is not deleting.** No
   status, no `Steps:` count, no `Failed at:` line, however wrong any of them
   looks. Reconciliation belongs to `/runbook-run`, which re-reads the body
   every step. This does **not** bar the backfill STAGE 1 step 1b worked out —
   assigning an id to a survivor of an index that predates ids is the one edit
   this command makes to a runbook it is not deleting, and it is required
   rather than permitted. Write those ids here, with the deletions.

5. **Never edit a body file.** The only thing this command does to a body is
   delete it whole.

6. Remove each worktree and delete each `wt/runbook-<id>-step-<n>` branch
   the plan listed, per THE WORKTREE SWEEP.

7. Report:
   - Each runbook removed, by id and name, with its status and steps.
   - The body files deleted, and any that were already missing.
   - The index blocks removed.
   - Each runbook refused and why, repeated from the plan so the closing
     report is complete on its own.
   - Each worktree removed and each branch deleted; a remove or delete that
     failed as a *Follow-ups* item naming the path and the command; any
     worktree the sweep left in place because it could not tell its step
     was finished.
   - The number of runbooks remaining in the index.

### Commit and push

This command **commits and pushes by default** — the cleanup convention, not
the authoring one. `/task-clean` has the same default for the same two
reasons: a deletion left uncommitted is the change most likely to be lost, and
STAGE 2's **"Apply?"** has already served as the review pass that an authoring
command's uncommitted output exists to allow. STAGE 2 is this run's only gate;
no further prompt is asked here.

Under `--no-commit`, the `rm` in STAGE 3 and the worktree sweep's listing,
removes and deletes are this command's only shell use: report what was
removed and stop.

Otherwise follow the commit-and-push protocol — four steps, in this order:

1. **Pull at start.** `git pull` on the current branch, before STAGE 1 reads
   the index (i.e. at the top of the run, not here). A conflict stops the run
   there, before anything is planned: report the output and tell the user to
   resolve manually and re-run.
2. **Commit.** Stage **exactly** the deleted body paths and
   `.claude/RUNBOOKS.md`, by explicit path, and make one commit:

   ```
   git add -- .claude/runbooks/1-ecc-import-landing.md .claude/RUNBOOKS.md
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
- Delete anything at all when a name or id is unknown. Abort the whole run
  first.
- Renumber a surviving runbook, lower `Last runbook number:`, or otherwise make
  a pruned id available again — `runbook-schema.md` § *The index block*.
- Ask for confirmation on an empty plan. Say it is empty and stop.
- Remove an index block without its surrounding `---` rules.
- Edit a runbook body file, for any reason.
- Rename or migrate a body, or read `body-migration.md`. A body is deleted
  wherever `File:` says it is, a legacy `<name>.md` path included.
- Change a `Status:`, `Steps:`, `Created:`, `Source:` or `Failed at:` line on a
  surviving runbook, however wrong it looks. That is `/runbook-run`'s to fix.
- Delete the index's title line or its `Last runbook number:` counter when the
  last block goes.
- Delete `.claude/RUNBOOKS.md` or `.claude/runbooks/` when the last runbook
  goes. An empty index is its title line; the directory stays.
- Restate the status vocabulary or the index block's shape in this body. They
  are
  `../skills/runbook-run/references/runbook-schema.md`,
  cited and never copied.
- Touch `.claude/TASKS.md`, `.claude/FEATURES.md`, or any file outside
  `.claude/runbooks/`, `.claude/RUNBOOKS.md` and the worktrees under
  `.claude/worktrees/` the sweep removes. Runbooks carry no cross-store
  references — nothing points at a runbook the way a task's `Preconditions:`
  line points at a task id — so there is nothing to rewrite after a removal,
  and names of removed runbooks are not reserved.
- Run, resume, author or append to a runbook. Those are `/runbook-run` and
  `/runbook-create`.
- Run any git command other than the protocol above and the worktree sweep's;
  never force-push, retry a failed push, branch, or tag.
