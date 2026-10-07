---
name: runbook-clean
version: 0.3.2
type: command
description: Prune finished runbooks — delete each [DONE] runbook's body under .claude/runbooks/ and remove its .claude/RUNBOOKS.md index block, every finished runbook by default or exactly the ones named. Use it once a runbook's work has landed and its record is no longer needed.
disable-model-invocation: true
requires: skill:runbook-run, skill:interaction-engine
---

# /runbook-clean
# Global command: prune runbooks in the terminal status from the project's
# runbook store. Commits and pushes the removals by default.
# Usage: /runbook-clean
#        /runbook-clean <id|name|id-name> [<id|name|id-name> ...]
#        /runbook-clean [<id|name|id-name> ...] --no-commit   (delete, skip the commit and push)
#        /runbook-clean [<id|name|id-name> ...] --no-push     (commit as usual, skip the push)
#        /runbook-clean [<id|name|id-name> ...] --attended | --unattended   (the gate waits either way)
# Examples: /runbook-clean
#           /runbook-clean ecc-import-landing
#           /runbook-clean 1 5
#           /runbook-clean 1-ecc-import-landing
#           /runbook-clean ecc-import-landing context-layer-refresh
#           /runbook-clean --no-commit

GOAL
- Remove finished runbooks: delete both the body file and the index block.
- Always confirm before writing.
- Removal is an **explicit act, never a consequence of completion**: reaching
  `[DONE]` deletes nothing on its own.

$ARGUMENTS

---

ARGUMENT NOTE

- Scan `$ARGUMENTS` and strip the flags below before STAGE 1 resolves anything.
  What is left is this command's own argument — a list of runbooks, each as
  `<id>`, `<name>` or `<id>-<name>`, or empty for the default.

| Flag | Effect |
| --- | --- |
| `--commit` | Accepted and stripped, a silent no-op: committing is the default. Refused beside `--no-commit` with `--commit and --no-commit cannot be combined. Pick one.` |
| `--no-commit` | Set NO_COMMIT = true. Delete and rewrite the index, but make no commit and no push. |
| `--no-push` | Set NO_PUSH = true. Commit as usual, skip the pull/re-sync/push. |
| `--attended` / `--unattended` | The interaction policy for this run, resolved with a parent's policy and the project's `CLAUDE.md` per `../skills/interaction-engine/references/policy.md`, which holds their argument errors. The one gate here is `destructive` (`../skills/interaction-engine/references/gates.md`); a run stopped there writes nothing. |

- Read `../skills/interaction-engine/references/messages.md` before the gate;
  the closing report follows its output rules.
- NO_COMMIT implies NO_PUSH.
- There is **no `--force`** and **no status argument** (see WHY ONLY `[DONE]`
  below). An argument that looks like a status rather than a runbook name is an
  unknown name; STAGE 1 handles it as one.

---

THE ARTIFACT

- The four-status vocabulary and the shape of an index block — its five fields
  and the conditional `Failed at:` line — are specified in
  `../skills/runbook-run/references/runbook-schema.md`.
- Read it before parsing the index. **Neither is restated here**; cite it,
  never copy it.

---

WHY ONLY `[DONE]`

`[DONE]` is the only eligible status. Each of the other three is ineligible for
its own reason:

- **`[PENDING]`** is unstarted work. Deleting it discards a plan nobody has
  had a chance to execute.
- **`[RUNNING]`** is a run someone is in the middle of. There may be a live
  session holding that name right now.
- **`[FAILED]`** is the status most likely to be misread as finished. It is
  not a finished runbook; it is the **record of a halt that still needs a
  decision**, and the `Failed at:` line is the only place the reason is
  written down outside the body.

**There is no `--force` and no status argument widening the set.** A user who
genuinely wants a non-`[DONE]` runbook — a `[FAILED]` one included — gone
flips its status by hand first — one
visible, committed edit.

This is narrower than `/task-clean`, which prunes `[DONE]` and `[SKIP]`: there
is no `[SKIP]` in the runbook vocabulary at all.

---

STAGE 1 — RESOLVE (no file writes, no deletions)

1. Read `.claude/RUNBOOKS.md`. If it does not exist, or holds no blocks, that
   is **not an error** — tell the user "No runbooks in this project." and
   stop. Do not create it and do not suggest a setup command.

1b. **An index written before ids** — one with no `Last runbook number:` line,
   or blocks whose headings carry no id — is **backfilled by this command**,
   per `runbook-schema.md` § *Backfilling an index written before ids*.
   - Work the ids out here, in order, so the plan can print them.
   - **Write them in STAGE 3**, with the deletions, under the same **"Apply?"**.
     Say in the plan that the backfill will land.
   - Write them only on a run that reaches STAGE 3. An empty plan stops at
     step 6 below without writing anything, backfill included — the schema
     gives the backfill to the first command that *writes* the index.

2. Parse every block per `runbook-schema.md` § *The index block*: the id, the
   name and the one-line title from the heading, then `Status:`, `File:`,
   `Created:`, `Source:` and `Steps:`.
   - `File:` is the path to delete — whatever it holds, an `<id>-<name>.md`
     path or a legacy `<name>.md` one, per `runbook-schema.md` § *`File:` is
     the body's path*. Never build the path from the name.

3. Resolve the set:
   - **No argument** — every runbook whose status is `[DONE]`. Nothing else.
   - **Runbooks given** — exactly those runbooks, in the order the user
     named them. Resolve each argument — `<id>`, `<name>` or `<id>-<name>` —
     to one block by `runbook-schema.md` § *Resolving a runbook argument*,
     which is not restated here. Never widen the set past what was asked for.

4. **An argument that does not resolve aborts the whole run**, before anything
   is deleted — an unknown one, a compound whose halves disagree, or an
   ambiguity, each reported as the schema says.
   - Say which argument did not resolve, list the runbooks that are in the
     index, and stop.
   - Do not remove the ones that were recognised.

5. **Refuse a named runbook that is not `[DONE]` by name, with its actual
   status** — never skip it silently:

   > `cli-dependency-field` is `[FAILED]`, not `[DONE]` — refusing.
   > Only `[DONE]` runbooks are eligible. A `[FAILED]` runbook is the record
   > of a halt that still needs a decision; flip its status by hand if you
   > genuinely want it gone.

   - Carry the matching reason from WHY ONLY `[DONE]` for whichever status it
     is.
   - A refusal does not abort the run the way an unknown name does: report the
     refusal, drop that runbook from the set, and carry on to STAGE 2 with what
     is left.

6. **An empty plan says so and stops**, without asking anything — no
   confirmation prompt for a no-op.
   - With no argument: "No `[DONE]` runbooks to prune."
   - With names, where every one was refused: say that nothing remains
     eligible after the refusals.

---

STAGE 2 — PLAN AND CONFIRM

1. Probe each body path with the Read tool before listing it.
2. Render the plan, printing **both paths** for every runbook — the body file
   and the index block:

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

Nothing else in .claude/runbooks/ is touched.
```

   - Take the name, status, `Steps:` and `Created:` values from the index
     verbatim. The id likewise, except where step 1b assigned it — say so on
     the line when it did, so a reader knows the number is new. Print `Steps:`
     as the index carries it.
   - The body file is the block's `File:` value, printed verbatim — list a
     legacy `<name>.md` path as it stands, never corrected to the prefixed
     form.
   - Note a body file that is unexpectedly missing in the plan — `(body file:
     … — MISSING)` — and do not error out; its index block is still removed.
   - Omit the `Refused` section entirely when nothing was refused.
3. End with a single explicit prompt: **"Apply?"** Gate class: `destructive`
   (`../skills/interaction-engine/references/gates.md`).
4. Wait for the user. **Nothing is written or deleted before an explicit
   answer** — "yes", "go", "apply" or similar. Silence is not approval.
5. If the user asks to drop a runbook from the set, re-render the whole plan
   after the change.

---

STAGE 3 — REMOVE AND COMMIT (only after explicit approval)

### Remove

1. Delete each body file. Use Bash:
   `rm .claude/runbooks/1-ecc-import-landing.md .claude/runbooks/5-context-layer-refresh.md`
   — each path exactly as its block's `File:` holds it. Skip any the plan
   flagged as already missing.

2. Use the Edit tool on `.claude/RUNBOOKS.md` to remove each matched index
   block **including its surrounding `---` rules**.
   - Preserve everything else: the title line, the `Last runbook number:`
     counter, the blank lines between surviving blocks, and the order of the
     survivors.
   - An index with every block removed is left as its title line and its
     counter, and nothing else. Do not delete `.claude/RUNBOOKS.md` or
     `.claude/runbooks/` when the last runbook goes; the directory stays.

3. **Never renumber, never move the counter down**, and never otherwise make a
   pruned id available again — `runbook-schema.md` § *The index block*.

4. **Correct no derived field on a runbook this command is not deleting.** No
   `Status:`, `Steps:`, `Created:`, `Source:` or `Failed at:` line, however
   wrong any of them looks. Reconciliation belongs to `/runbook-run`.
   - Exception: the backfill STAGE 1 step 1b worked out. Assigning an id to a
     survivor of an index that predates ids is the one edit this command makes
     to a runbook it is not deleting, and it is required rather than
     permitted. Write those ids here, with the deletions.

5. **Never edit a body file**, for any reason. The only thing this command does
   to a body is delete it whole, wherever `File:` says it is, a legacy
   `<name>.md` path included. Never rename or migrate a body, and never read
   `body-migration.md`.

6. Report:
   - Each runbook removed, by id and name, with its status and steps.
   - The body files deleted, and any that were already missing.
   - The index blocks removed.
   - Each runbook refused and why, repeated from the plan so the closing
     report is complete on its own.
   - The number of runbooks remaining in the index.

### Commit and push

- This command **commits and pushes by default**. STAGE 2 is this run's only
  gate; ask no further prompt here.
- Under `--no-commit`, the `rm` in STAGE 3 is this command's only shell use:
  report what was removed and stop.
- Otherwise follow the commit-and-push protocol — four steps, in this order:

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

   - `git add -- <path>` stages a deletion as well as a modification, so the
     removed bodies and the rewritten index go in together.
   - **Never a catch-all** (`git add -A` / `git add .` / `git add -u`), never an
     empty commit, never `--no-verify` / `--amend` / `--no-gpg-sign`.
   - On commit failure, surface the exact output, do not retry, and tell the
     user the changes remain staged.
3. **Pre-push re-sync.** `git pull` again, immediately before pushing. On a
   conflict: abort the merge, leave the local commit intact, do **not** push,
   and report that the commit exists locally but could not be synced.
4. **Push.** `git push`. On failure (rejected, no upstream, no remote) report
   the exact output and stop. Never retry, never force-push.

- Under `--no-push`, run step 2 only.
- On a non-git VCS — a project whose `CLAUDE.md` defines a `## VCS` section
  overriding git — skip steps 1, 3 and 4 entirely and use that mapping for the
  commit.

---

DO NOT:
- Touch `.claude/TASKS.md`, `.claude/FEATURES.md`, or any file outside
  `.claude/runbooks/` and `.claude/RUNBOOKS.md`. Runbooks carry no cross-store
  references, so there is nothing to rewrite after a removal, and names of
  removed runbooks are not reserved.
- Run, resume, author or append to a runbook. Those are `/runbook-run` and
  `/runbook-create`.
- Run any git command other than the protocol above; never force-push, retry a
  failed push, branch, or tag.
