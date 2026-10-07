---
name: runbook-prune
version: 0.2.2
type: command
description: Prune the finished steps out of one runbook — remove every [x] step and record its id on the body's Archive: line, so a surviving dependency and the index's step count still resolve. Use it to shrink a long-running runbook without renumbering a step or touching a pending one.
disable-model-invocation: true
requires: skill:runbook-run, skill:interaction-engine
---

# /runbook-prune
# Global command: remove the finished steps from one runbook's body and
# record their ids on the header's `Archive:` line. Reads and writes
# exactly two files — the body at its index block's `File:` path, and
# `.claude/RUNBOOKS.md`. Always reports the plan and asks for explicit
# confirmation before writing anything. Only [x] steps are removed; [ ], [~]
# and [!] are never touched, and a struck step is [x] like any other. An id
# in `Archive:` still counts as [x], so a surviving `Depends on:` resolves
# and the index's `Steps:` count keeps counting archived ids. A body with no
# `Last step number:` line is backfilled to the highest id present before
# anything is deleted; the counter is otherwise never touched. Refuses a
# [RUNNING] runbook and one with a [~] step; a runbook with no [x] step says
# so and stops. Commits and pushes by default.
# Usage: /runbook-prune <id|name|id-name>
#        /runbook-prune <id|name|id-name> --no-commit   (prune, skip the commit and push)
#        /runbook-prune <id|name|id-name> --no-push     (commit as usual, skip the push)
#        /runbook-prune <id|name|id-name> --attended | --unattended   (the gate waits either way)
# Examples: /runbook-prune ecc-import-landing
#           /runbook-prune 1
#           /runbook-prune 1-ecc-import-landing
#           /runbook-prune ecc-import-landing --no-commit

GOAL
Remove a runbook's finished `[x]` steps from its body, so the body
`/runbook-run` re-reads at the start of every step of every run holds the plan
that is left, not the plan that was.

- Record every removed id on the body header's `Archive:` line.
- **An id in `Archive:` counts as `[x]`.** A surviving `Depends on:` naming a
  pruned step still resolves, so run no dependency check and open no third
  file: this is a two-file operation.

$ARGUMENTS

---

ARGUMENT NOTE

- Scan `$ARGUMENTS` and strip the flags below before STAGE 1 resolves anything.
- What is left is this command's own argument — **exactly one** runbook, as
  `<id>`, `<name>` or `<id>-<name>`.

| Flag | Effect |
| --- | --- |
| `--commit` | Accepted and stripped, a silent no-op: committing is the default. Refused beside `--no-commit` with `--commit and --no-commit cannot be combined. Pick one.` |
| `--no-commit` | Set NO_COMMIT = true. Prune the body and rewrite the index, but make no commit and no push. |
| `--no-push` | Set NO_PUSH = true. Commit as usual, skip the pull/re-sync/push. |
| `--attended` / `--unattended` | The interaction policy for this run, resolved with a parent's policy and the project's `CLAUDE.md` per `../skills/interaction-engine/references/policy.md`, which holds their argument errors. The one gate here is `destructive` (`../skills/interaction-engine/references/gates.md`); a run stopped there writes nothing. |

- Read `../skills/interaction-engine/references/messages.md` before the gate;
  the closing report follows its output rules.
- NO_COMMIT implies NO_PUSH — there is nothing to push.
- Accept **no step argument and no `--all`**, nor a `--force` or any other way
  of widening or narrowing the set: a prune is per runbook and takes every
  `[x]` step in the one named runbook.
- With no argument at all, say the command needs a runbook and list the ones
  that exist. Do not default to every runbook the way `/runbook-clean` defaults
  to every `[DONE]` one: a prune edits a body, and the body it edits is always
  named.

---

THE ARTIFACT

- Read `../skills/runbook-run/references/runbook-schema.md` before parsing
  anything. It specifies the body schema — header fields, the shape of a step,
  the four step markers, the four-status vocabulary and the index block.
- **Never restate any of it in this body**; cite it. A pruner whose idea of a
  step's shape has drifted from the runner's removes the wrong lines, in a file
  nothing else will re-derive.
- Two of its sections are this command's own: § *The header*, which holds
  `Archive:` and `Last step number:`, and § *Backfilling a body written before
  the step counter*, which names `/runbook-prune` as one of the two commands
  that carries the backfill.

---

STAGE 1 — RESOLVE (no file writes)

1. Read `.claude/RUNBOOKS.md`. If it does not exist, or holds no blocks, that
   is **not an error** — tell the user "No runbooks in this project." and stop.
   Do not create it and do not suggest a setup command.

2. Resolve the argument to **exactly one** index block by `runbook-schema.md`
   § *Resolving a runbook argument* (its four ordered checks; do not restate
   them). Write nothing in any of these cases:
   - An unknown argument: list the runbooks that do exist and stop.
   - A compound whose halves disagree, or an ambiguity: report it as that rule
     says and stop.

3. **Refuse a `[RUNNING]` runbook by name, with its status**, and stop:

   > `ecc-import-landing` is `[RUNNING]` — refusing. A step is executing now,
   > possibly in another session; pruning the body under it would rewrite a
   > file that run re-reads at every step.

4. Parse the body at the block's `File:` line, **verbatim** — whatever it
   holds, an `<id>-<name>.md` path or a legacy `<name>.md` one, per
   `runbook-schema.md` § *`File:` is the body's path*. Never build the path
   from the name.
   - **Never migrate or rename it.** A legacy file name stays as it is; read and
     write the body wherever `File:` says it is.
   - Do not read `body-migration.md` — the same rule `step-amend.md` follows:
     migration belongs to the commands that already own the `File:` line,
     `/runbook-run` and `/runbook-create --append`.

5. **Refuse a body carrying a `[~]` step**, whatever the index says its status
   is, and stop naming the step:

   > `ecc-import-landing` step 4 is `[~]` — a step some run is in the middle
   > of. Refusing.

   - The body decides here, not the index: an interrupted run leaves `[~]`
     behind with the index back at `[PENDING]`.
   - Nothing else gates: `[PENDING]`, `[FAILED]` and `[DONE]` are all prunable.

6. Collect the steps to remove: **every step whose marker is `[x]`**, in list
   order.
   - Never remove `[ ]` (unstarted) or `[!]` (a failure awaiting a re-run);
     `[~]` refuses the whole command (step 5).
   - A **struck** step — one `step-amend.md` set to `[x]` with a
     `struck — <reason>` `Done:` line — is `[x]` and is pruned like any other.
     Do not read the `Done:` line; a strike is not a special case.

7. **A runbook with no `[x]` steps says so and stops**, without asking
   anything — no confirmation prompt for a no-op:

   > `ecc-import-landing` has no `[x]` steps — nothing to prune.

8. Work out the three derived values the plan prints, **without writing any of
   them yet**:

   - **The backfill.** If the header has **no `Last step number:` line**, the
     value to write is the **highest step id present in the body right now,
     counting the `[x]` steps about to be removed** — `runbook-schema.md`
     § *Backfilling a body written before the step counter*, which names this
     command as one of its two carriers. Say in the plan that the backfill will
     land. If the line is present, it is read for nothing and written for
     nothing: see NEVER TOUCH THE COUNTER below.
   - **The resulting `Archive:` line.** The ids already on `Archive:`, if any,
     plus every id being removed, **sorted ascending, comma-separated** (the
     separator `Depends on:` uses).
   - **The resulting `Steps:` count.** `<done>/<total>`, both halves counting
     the archived ids:
     - total = the number of steps left in the body + the length of the
       resulting `Archive:` list;
     - done = the number of surviving `[x]` steps — zero, unless the gate kept
       one — + that same length.
     - A runbook pruned to nothing therefore reads `7/7`, not `0/0`.

---

NEVER TOUCH THE COUNTER

- `Last step number:` is **read and written by this command in exactly one
  case**: the backfill in STAGE 1 step 8, on a body that has no such line.
- On a body that has one, a prune **never changes it** — not up, not down, not
  to match what is left. The counter is the highest id ever assigned, only ever
  increases, and is never derived with `max()` (`runbook-schema.md`
  § *The header*).
- Leaving the counter alone is what makes **pruning the highest-numbered step
  legal**: the next append still takes counter + 1, so a removed id is never
  handed out twice. Never renumber a surviving step or reuse a pruned id.
- Run the backfill **before any step is deleted**, counting the steps about to
  go, so the value written is the one `max()` would have returned a moment
  earlier — never the lower one it would return afterwards.
- Never derive the next step id with `max()` anywhere, or leave the body in a
  state where an appender would have to. A prune never lowers the next append's
  id, on a legacy body or a current one.

---

STAGE 2 — PLAN AND CONFIRM

Render the plan. Print **both paths** — the body and the index — because they
are two separate writes in two separate files:

```
PLAN — runbook-prune

Runbook:    1. ecc-import-landing   [PENDING]
Body file:  .claude/runbooks/1-ecc-import-landing.md
Index file: .claude/RUNBOOKS.md

Steps to remove (4):
  1. Read the architecture note and confirm the file set
  2. Land the launcher change
  3. Peer review the launcher change
  5. Update the context layer            (struck)

Steps remaining (2):  4, 6

Archive: 1, 2, 3, 5        (was: absent)
Steps:   4/6               (was: 4/6)

Last step number: 6        (backfilled — the header had no counter)

Nothing else in the body is touched: no marker, no Done: line, no Context:
bullet, no prompt block, and no other runbook.
```

- Take the id, the name, the status and both paths from the index verbatim, and
  each step's id and title from the body's heading verbatim.
- Mark a struck step as `(struck)` on its line, so the user does not read the
  list as "these all ran". It is pruned either way.
- Print the surviving step ids — they are what the user is approving.
- Print the resulting `Archive:` line with its previous value beside it —
  `(was: absent)` on a first prune, `(was: 1, 2)` otherwise.
- Print the resulting `Steps:` count with its previous value beside it. They
  will usually be the same number: **a prune changes no count**.
- Print the `Last step number:` line **only when the backfill applies**, with
  the reason. On a body that already carries the counter, say nothing about it
  at all.

End with a single explicit prompt: **"Apply?"** Gate class: `destructive`
(`../skills/interaction-engine/references/gates.md`).

- Wait for the user. **Write nothing before an explicit answer** — "yes",
  "go", "apply" or similar. Silence is not approval.
- If the user asks to keep a step the plan lists, drop it from the set and
  re-render the whole plan; its id does not go on `Archive:`, and both derived
  values change with it.

---

STAGE 3 — PRUNE AND COMMIT (only after explicit approval)

### Write the body

In this order, with the Edit tool, in the one file at the resolved `File:`
path:

1. **The backfill first, when it applies.** Write `Last step number: <N>`
   into the header — directly under the `Created: … · Source: … · Model: …`
   line, where `runbook-schema.md` § *The body schema* shows it — **before any
   step is removed**, as the prune's first write (the ordering rule in NEVER
   TOUCH THE COUNTER).

2. **The `Archive:` line.** Write the resolved list into the header:

   ```
   Archive: 1, 2, 3, 5
   ```

   - Place it **after `Companion:`** — last in the header: after `Companion:`
     when that line is present, after whatever the last header line is when it
     is not.
   - On a runbook already pruned, replace the existing line with the resolved
     one, which includes its old ids.
   - On a runbook never pruned, create the line here. A runbook never pruned
     carries no `Archive:` line at all; never write one empty.
   - Never remove a step without putting its id on `Archive:` — the line keeps
     a `Depends on:` naming it resolvable and the `Steps:` count honest.

3. **Remove each `[x]` step, whole** — from its `##` heading through the end of
   its fenced prompt block, including the `Depends on:`, `Needs:`, `Context:`
   and `Done:` lines between them, and the blank line that separated it from
   the next step. Leave a body someone could have authored: no orphan `Done:`
   line, no stranded prompt fence, no run of blank lines where four steps used
   to be.

4. **Change nothing else in the body.**
   - Not a surviving step's marker, `Depends on:`, `Needs:`, `Context:`,
     prompt block or any other line.
   - Not `Created:`, `Source:`, `Model:`, `Sequencing:` or `Companion:`.
   - Not `## Do not re-propose`, which is global to the runbook and outlives
     every step in it.
   - **Leave a surviving `Depends on:` that names a pruned step exactly as it
     is** — do not rewrite, renumber or delete the entry. `Archive:` keeps it
     resolvable, and rewriting it would destroy the record of the real
     constraint.

5. A prune may legally empty the body of steps, leaving only the header, the
   `Archive:` line and the `## Do not re-propose` section. That is correct — do
   not delete the file, and do not delete the runbook's index block. Removing a
   runbook is `/runbook-clean`'s.

### Write the index

6. Use the Edit tool on `.claude/RUNBOOKS.md` to set this block's `Steps:` line
   to the resolved count. **Nothing else in the block changes** — not
   `Status:`, not `File:`, not `Created:`, not `Source:`, not `Failed at:`, and
   not the heading. A prune is not a run: it finishes nothing and fails
   nothing.

7. **Correct no derived field on any other runbook**, however wrong it looks,
   and change no `Status:`, `File:`, `Created:`, `Source:` or `Failed at:` line
   on any runbook. Reconciliation belongs to `/runbook-run`, which re-reads the
   body every step.
   - Do not backfill index ids either: that belongs to the commands
     `runbook-schema.md` § *Backfilling an index written before ids* names, and
     this command is not one of them.
   - The pruned runbook's own `Steps:` line is the only line this command writes
     in this file.

### Report

8. Report:
   - The runbook, by id and name, with its status.
   - Each step removed, by id and title, marking the struck ones.
   - The step ids that remain.
   - The resulting `Archive:` line and `Steps:` count.
   - The backfilled `Last step number:`, when it was written.
   - Both paths written.

### Commit and push

- Commit and push **by default** (`/runbook-clean`'s convention, not the
  authoring one): STAGE 2's **"Apply?"** has already served as the review pass,
  and a deletion left uncommitted is the change most likely to be lost.
- STAGE 2 is this run's only gate; ask no further prompt here.
- Under `--no-commit`, report what was pruned and stop.

Otherwise follow the commit-and-push protocol — four steps, in this order:

1. **Pull at start.** `git pull` on the current branch, before STAGE 1 reads
   the index (i.e. at the top of the run, not here). A conflict stops the run
   there, before anything is planned: report the output and tell the user to
   resolve manually and re-run.
2. **Commit.** Stage **exactly** the body's `File:` path and
   `.claude/RUNBOOKS.md`, by explicit path, and make one commit:

   ```
   git add -- .claude/runbooks/1-ecc-import-landing.md .claude/RUNBOOKS.md
   git commit -m "Prune 4 done steps from runbook ecc-import-landing"
   ```

   **Never a catch-all** (`git add -A` / `git add .` / `git add -u`), never an
   empty commit, never `--no-verify` / `--amend` / `--no-gpg-sign`. On commit
   failure, surface the exact output, do not retry, and tell the user the
   changes remain staged.
3. **Pre-push re-sync.** `git pull` again, immediately before pushing. On a
   conflict: abort the merge, leave the local commit intact, do **not** push,
   and report that the commit exists locally but could not be synced.
4. **Push.** `git push`. On failure (rejected, no upstream, no remote) report
   the exact output and stop. Never retry, never force-push.

- Under `--no-push`, run step 2 only.
- On a non-git VCS — a project whose `CLAUDE.md` defines a `## VCS` section
  overriding git — skip steps 1, 3 and 4 entirely and use that mapping for the
  commit.
- Run no git command other than this protocol; never force-push, retry a
  failed push, branch, or tag.

---

DO NOT:
- Touch `.claude/TASKS.md`, `.claude/FEATURES.md`, or any file outside the one
  body and `.claude/RUNBOOKS.md`.
- Run, resume, author or append to a runbook. Those are `/runbook-run` and
  `/runbook-create`.
