---
name: runbook-create
version: 0.2.0
type: command
description: Author a runbook — an ordered list of self-contained prompts under .claude/runbooks/<name>.md, plus its .claude/RUNBOOKS.md index block — or append steps to one that already exists, including one a run is in the middle of. Assigns each new runbook the next id from the index's Last runbook number: counter, which every other runbook- command then accepts in place of the name. Two axes: where the steps go (a new runbook, --append <name|id>, --append with no name for the runbook this session is running, or no arguments at all, which asks) and where the material comes from (the current conversation's most recent follow-up list, the default; or a free-form description gathered through one batched interview). Enforces nine prompt-quality rules against every step before writing — self-contained, names the document to read first, carries every decision that exists nowhere on disk and nothing that already does, states its sequencing and what must not be re-proposed, uses real slash commands, references no path missing at run time, produces one deliverable, and never invokes /runbook-run — fixing failures and naming each fix in the confirmation report. The gate shows the proposed shape only, never the full prompts. Authoring command — leaves the runbook uncommitted for one review pass by default; pass --commit to commit and push it, or --commit --no-push to commit without pushing.
requires: skill:runbook-run
---

# /runbook-create
# Global command: author a runbook — an ordered list of self-contained
# prompts, each written to be executed by a fresh agent that has none of the
# conversation the prompts came out of — or append steps to an existing one.
# Writes `.claude/runbooks/<name>.md` and its `.claude/RUNBOOKS.md` index
# block, and nothing else. Never runs a runbook; that is `/runbook-run`.
# Usage: /runbook-create
#        /runbook-create <name>
#        /runbook-create <free-form description of the work>
#        /runbook-create --append <name>
#        /runbook-create --append
#        /runbook-create <args> --commit            (commit and push what this run wrote)
#        /runbook-create <args> --commit --no-push  (commit locally, skip the push)
# Examples: /runbook-create implement-ecc-import
#           /runbook-create --append implement-ecc-import
#           /runbook-create land the four follow-ups from today's architect run

GOAL
Harvest the material for a runbook while the conversation that produced it is
still open, enforce the checklist that makes each prompt survive a fresh
agent, confirm the shape with the user, and write the runbook and its index
block.

The hard part is not the file format. A prompt written inside a rich
conversation reads as complete and is not: it leans on decisions made an hour
ago and written down nowhere, on a document everyone present had already read,
and on knowledge of which options were already rejected. Handed to a fresh
agent, that prompt produces confident work against the wrong premise. THE
PROMPT-QUALITY RULES below are what stops that, and applying them is this
command's actual job.

$ARGUMENTS

---

ARGUMENT NOTE

Scan `$ARGUMENTS` and strip the flags below before resolving anything; what
is left is the target name or the free-form description.

| Flag | Effect |
| --- | --- |
| `--append` | Set APPEND = true. The steps go onto an existing runbook rather than into a new one. |
| `--commit` | Set COMMIT = true. Commit and push what this run wrote. Default is false — the output is left uncommitted for one review pass. |
| `--no-push` | Set NO_PUSH = true. Only meaningful alongside `--commit`: commit locally, skip the pull/re-sync/push. |

`--no-push` without `--commit` is accepted and has no effect — there is
nothing to push. If `--no-commit` is passed, say that this is an authoring
command whose default already commits nothing, and continue as if it were
absent.

---

THE ARTIFACT

The store, the body schema, the four step markers, the `Done:` line, the
four-status vocabulary and the index block are all specified in
`${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`.
Read it before parsing or writing either file, and emit exactly the shapes it
gives. **Nothing about the artifact is restated here** — a second copy is the
copy that drifts.

What is this command's own is everything below: how the target is resolved,
where the material comes from, the nine rules every prompt must pass, the
confirmation gate, and the append rules.

---

WHAT THIS COMMAND WRITES

Two files, and within them only certain lines. Ownership is split **by line**,
which is what makes appending safe while a run is in progress:

| Line | Written here | Never written here |
| --- | --- | --- |
| the header, `Sequencing:`, `Companion:` | yes | — |
| a step's title and its ```prompt``` block | yes | — |
| `Depends on:` | yes | — |
| `## Do not re-propose` | yes | — |
| the step marker | `[ ]` only | `[~]`, `[x]`, `[!]` |
| `Context:` | `none` only, at authoring time | a run's dated correction bullets |
| `Done:` | — | never; it does not exist until a run writes it |
| the index `Status:` | `[PENDING]` only | `[RUNNING]`, `[FAILED]`, `[DONE]` |

The one exception is the `[DONE]` → `[PENDING]` flip an append forces (see
APPEND RULES). Everything else in the right-hand column belongs to
`/runbook-run`.

This command writes no task, no feature document, and no line that belongs to
a run. It also never executes a runbook.

---

PHASE 1 — RESOLVE THE TARGET

Four forms, resolved in this order.

1. **`/runbook-create --append <name|id>`** — append to that runbook. The
   argument may be the runbook's kebab-case name or the numeric id the index
   assigns it, resolved by `runbook-schema.md` § *The store*'s one rule: a bare
   all-digits argument is an id, anything else a name. An unknown name or id is
   an error listing the runbooks that do exist, so a typo is corrected without
   going to look.

2. **`/runbook-create --append`, no name** — append to the runbook **this
   session is currently running**. An orchestrator session knows which one
   that is; a step's subagent knows because the prompt that spawned it names
   its runbook and step. With no current runbook this is an error, and the
   error names the fix: `--append <name>`.

3. **`/runbook-create <argument>`, no `--append`** — a new runbook. A **single
   kebab-case token** is read as the name; **anything longer** is read as a
   free-form description, and the name is proposed at the confirmation gate.

4. **`/runbook-create`, no arguments** — ask which:

   > New runbook, or append to an existing one?
   >
   > A. **New** — give it a name.
   > B. **Append** — to which?
   >
   >   3. implement-ecc-import   [RUNNING]   27/32   ← this session
   >   5. context-layer-refresh  [PENDING]    0/3
   >   1. ecc-import-landing     [DONE]       7/7

   List the runbooks from `.claude/RUNBOOKS.md` with **non-`[DONE]` ones
   first** and **the currently running one first of all**. The number on each
   line is the runbook's **id**, not its position in the list — so an answer
   naming a number selects the same runbook however the list is ordered, and
   the same number works on any later command line. **This is the only
   place new-versus-append is asked**, and it is asked here because this is
   the command the user chose to run — an auto-triggered suggestion must not
   ask it.

**Name collisions.** A new runbook whose name is already in the index is
**refused with a suggested alternative**, never disambiguated automatically: a
runbook is referred to by name for the length of its execution, and two
similar names are a real hazard. Say which name is taken, what its status is,
suggest one alternative, and offer `--append <name>` as the other option.
Names of removed runbooks are not reserved. Their **ids** are the opposite:
`runbook-schema.md` § *The index block* is why a pruned id is never handed out
again, so a collision is only ever possible on a name.

**First use is silent and idempotent.** If `.claude/runbooks/` or
`.claude/RUNBOOKS.md` does not exist, create it at write time — the index as
its title line and its `Last runbook number: 0` counter, and nothing else. Say
nothing about having done it; a project needs no setup step for runbooks, and
neither `/task-setup` nor `/project-setup` gains one.

**An index written before ids** — one with no counter line, or blocks whose
headings carry no id — is backfilled here, per `runbook-schema.md`
§ *Backfilling an index written before ids*, before this run assigns anything.
This command writes the index, so it performs the backfill rather than working
around it.

---

PHASE 2 — GATHER THE MATERIAL

Two modes. The target resolved in PHASE 1 does not change which one applies —
both modes work for a new runbook and for an append.

### Conversation mode (the default, and the mode this command exists for)

Applies whenever no free-form description was given. The decisions, the
rejected options and the verified probes are all still in context, and every
one of them is candidate prompt material.

The source is the **most recent enumerated follow-up list in the
conversation**. Earlier lists are **superseded and ignored** — except for
items still outstanding, which are carried forward. This is deliberate: a
conversation that produced three successive lists produced two obsolete ones,
and the confirmation gate is what makes a wrong pick cheap to correct.

Then harvest, from the conversation and not from the files:

- every decision that was settled here and written to no file,
- every option that was assessed and rejected, with its reason,
- every probe whose result is now a fact,
- the ordering constraints, and **why** each one exists.

The rejected options are the `## Do not re-propose` section. The
step-specific ones go in the step's own prompt instead.

### From-scratch mode

Applies when the argument was a free-form description. Nothing useful is in
context, so ask for it — as **one batch**, with a recommended answer for each,
so the whole interview can be settled in a sentence:

1. **What must be true when this runbook is finished?** The end state. It is
   what makes the last step recognizable as the last step.
2. **What are the steps, in order?** Titles are enough at this stage.
3. **Which steps must precede which, and why?** The *why* is the part that
   goes on the `Sequencing:` line — "1–4 all edit the same file" is worth more
   to a future reader than a dependency graph.
4. **For each step, which document should the agent read first?** A step with
   no such document needs its evidence carried inline instead, which is worth
   knowing now rather than at write time.
5. **What has already been decided, tried or rejected?** This becomes prompt
   material and the optional `## Do not re-propose` section. It is the
   question this mode exists to ask, because unlike conversation mode there is
   nothing else to harvest it from.

A sixth question — **the model** — is asked **only when the default `opus` is
not wanted**. Do not ask it routinely.

---

THE PROMPT-QUALITY RULES

Nine rules. Apply every one of them to every step before the file is written.
They are stated here in full because approximating them produces prompts that
read as complete and are not.

1. **Self-contained.** An agent with no history of this conversation can
   execute it. This is the rule the other eight serve. Self-contained means
   *complete given what the invoked command reads*, **not exhaustive**: a
   prompt that invokes a skill which reads its own inputs from disk is
   complete as the bare invocation.

2. **Names the document to read first** — or, where there is none, **carries
   the evidence inline**. A step with no feature document says so and then
   supplies what it has. When the invoked command names that document itself
   (`/task-implement 134` reads `.claude/tasks/134.md`), the prompt **does
   not repeat it**.

3. **Carries every decision that exists nowhere on disk — and nothing that
   already does.** Anything settled in conversation and not yet written to a
   file is invisible to a fresh agent and will be re-litigated, usually
   differently. The converse binds just as hard: restating what a task body, a
   feature document or `CLAUDE.md` already says duplicates it, and the
   duplicate drifts. The correct prompt for an authored task is the one-line
   `/task-implement <n>` — the body carries its decisions, its
   pre-authorisations and its verification, and `/task-implement` checks its
   own preconditions. **One-line prompts are the expected case, not a
   shortcut.**

4. **States its sequencing and why.** Not "do this third", but "this goes last
   of the four that touch `skills/task-implement/SKILL.md`".

5. **States what must not be re-proposed.** Options already assessed and
   rejected, and recommendations already overruled. Step-specific ones go in
   the step's prompt; runbook-wide ones go in `## Do not re-propose`.

6. **Uses an existing slash command where one fits**, in its **real argument
   form** — `/task-add feature=<slug>`, never a paraphrase of what it does.

7. **References no path that will not exist at run time.** In particular
   **nothing under `docs/`**, which is authoring-time-only and is never
   installed.

8. **Produces one deliverable.** A step that lands two unrelated artifacts is
   two steps, because half of it succeeding has no honest marker.

9. **Never invokes `/runbook-run`.** Nested runbooks are forbidden, and the
   rejection happens **here**, at authoring time, not at spawn time. The
   reason is the depth budget: the orchestrator occupies one nesting level and
   the step's agent a second, so a nested orchestrator would leave nothing for
   the work. Reject such a step by name, with that reason, and propose the
   alternative — the steps inline, or a separate runbook run afterwards.

---

PHASE 3 — ENFORCE THE RULES

Check every step against all nine. **A step that fails a rule is fixed before
the file is written, and the fix is named in the confirmation report rather
than applied silently.** The user is the only one who knows whether a missing
decision was an omission or a deliberate delegation, and a silent fix takes
that judgement away from them.

Typical fixes, each named in the report:

- a rule-3 failure — a decision that lives only in this conversation — is
  written into the prompt, and the report says which decision was added;
- a rule-3 failure in the other direction — a prompt restating a task body —
  is **cut back** to the bare invocation, and the report says what was removed;
- a rule-8 failure is **split into two steps**, and the report names the split;
- a rule-7 failure is repointed at a path that exists at run time, or the
  evidence is inlined;
- a rule-9 failure is **rejected outright** — it is not fixable by rewording.

---

PHASE 4 — CONFIRM (the gate)

Before writing anything, report the proposed **shape** and stop for approval:

```
PLAN — runbook <name>            (or: append to runbook <id>. <name>)

Id:    <the id this runbook will be assigned>   (new runbooks only)
File:  .claude/runbooks/<name>.md
Index: .claude/RUNBOOKS.md

Header:     Created <YYYY-MM-DD> · Source <…> · Model opus
Sequencing: <the one-line prose statement of the order and why>
Companion:  <path, or none>

Steps:
  1. <title>                      depends on: none
  2. <title>                      depends on: 1
  3. <title>                      depends on: 1

Fixes applied:
  - step 2 was split from step 1 (rule 8: two unrelated deliverables)
  - step 3 carries the 2026-08-25 decision that <…> (rule 3: settled here,
    on disk nowhere)
  - step 4's prompt was cut to `/task-implement 141` (rule 3: it restated
    the task body)

Do not re-propose: <n> items
```

End with a single explicit prompt: **"Approve and write?"**

**Only the shape.** Full prompts are deliberately not shown back: they are a
wall of text that gets skimmed, and they are in the file a moment later,
uncommitted and open to review. The gate exists to catch a **wrong order or a
missing step** — both expensive after the first step has run, and cheap now.

Wait for an explicit answer. Iterate and re-render the whole plan after any
non-trivial change. Silence is not approval, and nothing is written before
one.

---

PHASE 5 — WRITE (only after explicit approval)

Emit the body and the index block exactly as `runbook-schema.md` specifies.
Two cases.

### New runbook

1. Create `.claude/runbooks/` and `.claude/RUNBOOKS.md` if either is missing —
   silently, idempotently, the index as its title line and its counter at `0`.
   Backfill an index written before ids, per PHASE 1's rule, before step 2.
2. Write `.claude/runbooks/<name>.md`: the header, then each step in order.
3. Append the index block with `Status: [PENDING]` and `Steps: 0/<total>`,
   under a heading carrying the runbook's **new id**, its name and its
   one-line title.
4. Advance `Last runbook number:` to that id, **in the same write** as step 3.

The new id is `Last runbook number: + 1` — never `max()` over the blocks
present, which would reuse a pruned runbook's id. This command is the only
thing that assigns an id or advances the counter, exactly as `/task-add` is
for `.claude/TASKS.md`; an append assigns nothing, because the runbook it
appends to already has one.

Every step marker is `[ ]`. There are no `Done:` lines — an authored runbook
has none at all.

### Append

The APPEND RULES below govern it, all of them.

### `Context:` at authoring time

Write `Context: none` on every step, in the common case. The decisions a
prompt needs belong **inside the prompt**, which is what keeps the fenced
block pasteable into a fresh session on its own — the property that keeps a
runbook executable by hand when `/runbook-run` is unavailable, or when the
user simply prefers to drive it. `Context:` is the **run's** field:
corrections, failure notes, and facts learned by earlier steps.

---

APPEND RULES

All of these apply to every append, and to the `--append` half of PHASE 5:

- **Numbering continues** from the last existing step.
- **`Depends on:` may reference existing steps**, including completed ones.
- **The `Sequencing:` header line is extended, never replaced.** It describes
  the whole runbook, and the appended steps are now part of it.
- **Existing steps are never edited.** An append adds material after the last
  step and touches nothing above the append point. This is what makes it safe
  during a run.
- **Appending to a `[DONE]` runbook flips it back to `[PENDING]`.** There is
  unfinished work again and the status has to say so. This is the one status
  this command writes other than `[PENDING]` on creation.
- **Appending to a `[FAILED]` runbook leaves it `[FAILED]`.** The halt still
  needs a decision, and adding steps does not resolve it. Say so in the report.
- **Appending to a `[RUNNING]` runbook is allowed only from the running
  session itself** — one session, one tree, no race. From any other session,
  refuse and say why. The run picks the new steps up at its next step
  re-read; there is nothing to notify.
- **The index `Steps: <done>/<total>` is updated** — the total grows, the done
  count is untouched.
- **The runbook's id and the counter are untouched.** An append adds steps to a
  runbook that already has an id; nothing is assigned and
  `Last runbook number:` does not move.

---

PHASE 6 — COMMIT AND PUSH (only when `--commit` was passed)

If COMMIT is false (the default), do nothing here. Report the paths written
and stop, closing with the one line that matters: the prompts **are** the
product, and they are cheapest to fix now, before the first step runs. The
review pass matters more here than for most authoring commands.

If COMMIT is true, follow the commit-and-push protocol — four steps, in this
order:

1. **Pull at start.** `git pull` on the current branch, before this run's own
   work begins (i.e. before PHASE 1 resolves anything, when `--commit` is on
   the command line). A conflict stops the run there: report the output and
   tell the user to resolve manually and re-run.
2. **Commit.** Stage **exactly** the paths this run wrote —
   `.claude/runbooks/<name>.md` and `.claude/RUNBOOKS.md`, by explicit path —
   and make one commit:

   ```
   git add -- .claude/runbooks/<name>.md .claude/RUNBOOKS.md
   git commit -m "Add runbook <name>"        # or: "Append <n> steps to runbook <name>"
   ```

   Never a catch-all (`git add -A` / `git add .` / `git add -u`), never an
   empty commit, never `--no-verify` / `--amend` / `--no-gpg-sign`. On commit
   failure, surface the exact output, do not retry, and tell the user the
   files remain staged.
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
- Write to any file before PHASE 4's **"Approve and write?"** is answered.
- Restate the body schema, the step markers, the status vocabulary or the
  index block in this body. They are
  `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`,
  cited and never copied.
- Show the full prompts back at the confirmation gate. Shape only.
- Fix a rule failure silently. Every fix is named in the report.
- Accept a step whose prompt invokes `/runbook-run`. Rule 9 is enforced here,
  not deferred to spawn time.
- Write a `Done:` line, a step marker other than `[ ]`, or an index `Status:`
  other than `[PENDING]` — the sole exception being the `[DONE]` → `[PENDING]`
  flip an append forces.
- Write anything into `Context:` other than `none`. Corrections and learned
  facts are the run's, and a prompt's decisions belong inside the prompt.
- Edit an existing step — its title, its `Depends on:`, or its prompt block —
  during an append, or edit any line above the append point.
- Replace the `Sequencing:` line on an append. Extend it.
- Append to a `[RUNNING]` runbook from a session that is not the one running
  it.
- Disambiguate a colliding name automatically. Refuse it, suggest one
  alternative, and offer `--append`.
- Reserve the names of removed runbooks.
- Derive a new id with `max()` over the blocks present, reuse a pruned
  runbook's id, renumber an existing runbook, or advance
  `Last runbook number:` on an append — `runbook-schema.md`
  § *The index block* is the authority for all four.
- Treat the id as the runbook's identity. It is an alias for the command line;
  the name still names the body file and every message about the runbook.
- Ask new-versus-append anywhere except the no-argument form of PHASE 1.
- Add a runbook step to `/task-setup` or `/project-setup`, or require any
  setup before a runbook can be created.
- Execute a runbook, or any step of one. That is `/runbook-run`.
- Create a task, a feature document, or any file other than
  `.claude/runbooks/<name>.md` and `.claude/RUNBOOKS.md`.
- Run any git command unless `--commit` was passed; and with it, never
  force-push, retry a failed push, branch, tag, or stage with a catch-all.
