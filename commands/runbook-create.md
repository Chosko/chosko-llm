---
name: runbook-create
version: 0.8.3
type: command
description: Author a runbook — an ordered list of self-contained prompts under .claude/runbooks/, indexed in .claude/RUNBOOKS.md — from this conversation's follow-up list or a free-form description, or append steps to one. Use it to hand ordered work to later sessions that lack this conversation's context.
requires: skill:runbook-run
---

# /runbook-create
# Global command: author a runbook — an ordered list of self-contained
# prompts, each written to be executed by a fresh agent that has none of the
# conversation the prompts came out of — or append steps to an existing one.
# Writes the runbook's body at its index block's `File:` path
# (`.claude/runbooks/<id>-<name>.md` for a new runbook) and its
# `.claude/RUNBOOKS.md` index block, and nothing else. Never runs a runbook;
# that is `/runbook-run`. Steps come from the conversation's most recent
# follow-up list by default, or from a free-form description gathered in one
# batched interview. A new runbook takes the next id from the index's
# `Last runbook number:` counter; a new step takes the next id from the
# body's `Last step number:` counter, so no existing step is ever edited or
# renumbered, and an append lands at the foot unless `--before` / `--after`
# place it. Authors each step's optional `Needs:` line (agent / agent+human /
# human) and calls out the steps that need a person at the confirmation
# gate, which shows the proposed shape only, never the full prompts. Refuses
# a name already taken, or whose first kebab segment is all digits, with one
# suggested alternative. Commits and pushes what it wrote by default.
# Usage: /runbook-create
#        /runbook-create <name>
#        /runbook-create <free-form description of the work>
#        /runbook-create --append <id|name|id-name>
#        /runbook-create --append
#        /runbook-create --append <id|name|id-name> --before <step>  (insert above that step)
#        /runbook-create --append <id|name|id-name> --after <step>   (insert below that step)
#        /runbook-create <args> --no-commit  (write the runbook, skip the commit and push)
#        /runbook-create <args> --no-push    (commit as usual, skip the push)
#        /runbook-create <args> --commit     (accepted; changes nothing — the default already commits)
# Examples: /runbook-create implement-ecc-import
#           /runbook-create --append implement-ecc-import
#           /runbook-create --append 3 --before 4
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
| `--before <step>` | Set POSITION = before `<step>`. The appended steps are written immediately above that step instead of at the foot. |
| `--after <step>` | Set POSITION = after `<step>`. The appended steps are written immediately below that step instead of at the foot. |
| `--no-commit` | Set COMMIT = false. Write the runbook, but make no commit and no push. Implies NO_PUSH. |
| `--no-push` | Set NO_PUSH = true. Commit as usual, skip the pull/re-sync/push. |
| `--commit` | Accepted and changes nothing — COMMIT is already true. |

`--before` and `--after` each take a value — a **step id**, the number in a
step's heading, never a position in the list — and both the flag and its value
are stripped. They are mutually exclusive; if both appear, stop with:
`--before and --after cannot be combined. Pick one.` Either one without
`--append` stops with `--before requires --append.` (or `--after requires
--append.`) — a new runbook has no steps to place against. Without either flag
an append goes at the foot, exactly as it always has.

COMMIT is true unless `--no-commit` is passed. `--commit` is stripped
silently, so existing runbook steps and invocations that still pass it keep
working. `--commit` and `--no-commit` together stop the run with:
`--commit and --no-commit cannot be combined. Pick one.`

**Pull at start.** Unless `--no-commit` was passed or `NO_PUSH` is true, run
`git pull` on the current branch before PHASE 1 resolves anything. A conflict
stops the run there: report the output and tell the user to resolve manually
and re-run. On a non-git VCS (a `## VCS` section in `CLAUDE.md`) skip it.

---

THE ARTIFACT

The store, the body schema, the four step markers, the `Done:` line, the
four-status vocabulary and the index block are all specified in
`../skills/runbook-run/references/runbook-schema.md`.
Read it before parsing or writing either file, and emit exactly the shapes it
gives. **Nothing about the artifact is restated here** — a second copy is the
copy that drifts.

What is this command's own is everything below: how the target is resolved,
where the material comes from, the ten rules every prompt must pass, the
confirmation gate, and the append rules.

---

WHAT THIS COMMAND WRITES

Two files, and within them only certain lines. Ownership is split **by line**,
which is what makes appending safe while a run is in progress:

| Line | Written here | Never written here |
| --- | --- | --- |
| the header, `Last step number:`, `Sequencing:`, `Companion:` | yes | `Archive:`, which is `/runbook-prune`'s — an append never writes, normalises or drops it |
| a step's title and its ```prompt``` block | yes | — |
| `Depends on:` | yes | — |
| `Needs:` | `agent+human` and `human` only | `agent`, which is the default and is never written |
| `## Do not re-propose` | yes | — |
| the step marker | `[ ]` only | `[~]`, `[x]`, `[!]` |
| `Context:` | `none` only, at authoring time | a run's dated correction bullets |
| `Done:` | — | never; it does not exist until a run writes it |
| the index `Status:` | `[PENDING]` only | `[RUNNING]`, `[FAILED]`, `[DONE]` |
| the index `File:` | at creation, `.claude/runbooks/<id>-<name>.md`; on an append, only the rewrite a migration makes | any other change |

The one exception is the `[DONE]` → `[PENDING]` flip an append forces (see
APPEND RULES). Everything else in the right-hand column belongs to
`/runbook-run`.

The body is always opened and written at the path its block's `File:` line
holds, never at a path built from the name — `runbook-schema.md` § *The store*.

This command writes no task, no feature document, and no line that belongs to
a run. It also never executes a runbook.

---

PHASE 1 — RESOLVE THE TARGET

Four forms, resolved in this order.

1. **`/runbook-create --append <id|name|id-name>`** — append to that runbook.
   The argument is resolved to exactly one index block by `runbook-schema.md`
   § *Resolving a runbook argument*, and its errors are the ones that rule
   gives: an unknown argument lists the runbooks that do exist, so a typo is
   corrected without going to look; a compound whose halves disagree names the
   runbook the id actually belongs to; an ambiguity names both candidates.
   Each stops the run with nothing written.

2. **`/runbook-create --append`, no name** — append to the runbook **this
   session is currently running**. An orchestrator session knows which one
   that is; a step's subagent knows because the prompt that spawned it names
   its runbook and step. With no current runbook this is an error, and the
   error names the fix: `--append <name>`. The body is the one at that
   runbook's `File:` path, and it is **never migrated** — the runbook is
   `[RUNNING]`.

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

**The step a `--before` / `--after` names** is resolved against the target
runbook's body as soon as forms 1 or 2 have found it, before any material is
gathered: `<step>` matches the id in a step heading, never the step's position
in the list. An id no step carries is an error that **lists the runbook's
steps** — id, marker and title, in list order — so a typo is corrected without
going to look. Nothing is gathered and nothing is written.

**The migration check on an append target.** Once form 1 or 2 has resolved
the target — after the pull at start, and before any material is
gathered — apply the check in `runbook-schema.md` § *The store* to the target's
block. On a hit, read
`../skills/runbook-run/references/body-migration.md`
and migrate the body as it says; on no hit that file is never opened. A
`[RUNNING]` target is **never migrated**, under any flag: it is appended to at
its current `File:` path. A target path that is already taken stops the run
with nothing written, as that file says. Whatever path results — the `File:`
path as read, or the new one — is the path every later read and write in this
run uses. The `--before` / `--after` step lookup above runs first, against the
body at the `File:` path as read, so a step id no step carries stops the run
before anything is migrated; never migrate under a condition that stops it.

The migration is the **one write that may happen before PHASE 4's gate**. It
changes no content — a rename plus a one-line `File:` rewrite — and a run that
stops afterwards, at the gate or anywhere else, leaves it in the tree exactly
as `body-migration.md` § *Staging* describes.

**Name collisions.** A new runbook whose name is already in the index is
**refused with a suggested alternative**, never disambiguated automatically: a
runbook is referred to by name for the length of its execution, and two
similar names are a real hazard. Say which name is taken, what its status is,
suggest one alternative, and offer `--append <name>` as the other option.
Names of removed runbooks are not reserved. Their **ids** are the opposite:
`runbook-schema.md` § *The index block* is why a pruned id is never handed out
again, so a collision is only ever possible on a name.

**Leading-numeric names.** A new runbook whose name's first kebab segment is
all digits — `2026-migration` — is **refused the same way**, beside the
collision rule and before any file is written: say why, suggest one
alternative (`migration-2026`), and write nothing. The reason is
`runbook-schema.md` § *Resolving a runbook argument*: such a name could read as
`<id>-<name>`, and refusing it is what keeps that rule unambiguous. Both checks
apply to **every** new name — one the user typed, one this command proposes at
the gate from a free-form description (never propose a name that would fail
either), and one the user substitutes at the gate.

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

**A body written before the step counter** — an append target whose header
carries no `Last step number:` line — is backfilled the same way and at the same
point, per `runbook-schema.md` § *Backfilling a body written before the step
counter*: set it in place to the highest step id present in the body, before
this run assigns anything. This command is one of the two the counter is
load-bearing for, and it owns the header line, so it performs the backfill
rather than falling back to `max()`. A new runbook has nothing to backfill —
PHASE 5 writes the line.

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
- the ordering constraints, and **why** each one exists,
- **which actions in the list need a person** rather than an agent. A
  conversation that produced the follow-ups usually said so in passing ("then
  you flip it in the editor"); that is a step's `Needs:` line. Where the
  conversation is silent, the step is `agent` and gets no line — do not
  interrogate the user for it in this mode, which exists precisely to avoid an
  interview.

The rejected options are the `## Do not re-propose` section. The
step-specific ones go in the step's own prompt instead.

### From-scratch mode

Applies when the argument was a free-form description. Nothing useful is in
context, so ask for it — as **one batch**, with a recommended answer for each,
so the whole interview can be settled in a sentence:

1. **What must be true when this runbook is finished?** The end state. It is
   what makes the last step recognizable as the last step.
2. **What are the steps, in order?** Titles are enough at this stage.
3. **Which steps must precede which, and why?** The order is list position
   and the edges are `Depends on:`. A *why* those two cannot show — "1–4 all
   edit the same file" — is the optional one-line `Sequencing:`; when there is
   none, the runbook has no `Sequencing:` line.
4. **For each step, which document should the agent read first?** A step with
   no such document needs its evidence carried inline instead, which is worth
   knowing now rather than at write time.
5. **What has already been decided, tried or rejected?** This becomes prompt
   material and the optional `## Do not re-propose` section. It is the
   question this mode exists to ask, because unlike conversation mode there is
   nothing else to harvest it from.
6. **Does any step need a person?** Which of them cannot be executed by an
   agent alone — an editor-only operation, a GUI wizard, hardware — and whether
   the step is partly manual or wholly so. The answer is each step's `Needs:`
   line per `runbook-schema.md` § *A step*; recommend `agent` for every step,
   which is the common case, so a runbook of ordinary agent work is confirmed
   with one word. **An `agent` step gets no `Needs:` line at all** — the value
   is the default and the schema says it is never written.

A seventh question — **the model** — is asked **only when the default `opus`
is not wanted**. Do not ask it routinely.

---

THE PROMPT-QUALITY RULES

Ten rules. Apply every one of them to every step before the file is written.
They are stated here in full because approximating them produces prompts that
read as complete and are not.

1. **Self-contained.** An agent with no history of this conversation can
   execute it. This is the rule the other nine serve. Self-contained means
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

10. **Prefer two steps to a step that needs a nested spawn.** A step whose
    prompt invokes something that wants its own subagent — `/task-implement
    --review --rounds 2`, which wants an implementor and then a reviewer — is
    usually better authored as two steps: implement, then review. Each is
    spawned by the orchestrator directly, the review still gets the fresh
    context that is its whole point, and the runbook gains an honest marker
    for each half instead of one marker covering both.

    This is a **preference, not a rejection** like rule 9, and the reason is
    that it does not always apply: a skill that spawns internally, without the
    author knowing it will, cannot be split by an author who does not know.
    `/runbook-run`'s spawn relay covers that case at run time — the step's
    agent asks the orchestrator to spawn the child on its behalf. So splitting
    is the better shape where it is available, and the relay is the fallback
    where it is not. Where a step is left un-split deliberately, say so in the
    confirmation report; do not split it silently.

---

PHASE 3 — ENFORCE THE RULES

Check every step against all ten. **A step that fails a rule is fixed before
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
File:  .claude/runbooks/<id>-<name>.md   (an append: its `File:` path, after any migration)
Index: .claude/RUNBOOKS.md
Position: before step 4 — <its title>   (appends only; or: after step <n> — <title>; or: at the foot)

Header:     Created <YYYY-MM-DD> · Source <…> · Model opus
Sequencing: <one line: why this order, where position and Depends on: can't show it — or none>
Companion:  <path, or none>

Steps:
  1. <title>                      depends on: none
  2. <title>                      depends on: 1     needs: agent+human
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

On an append the list shows only the new steps, under the ids they will be
written with, and `Position:` says where in the list they land — so a step
numbered 6 that will run before step 4 reads that way at the gate, not only in
the file.

A step whose `Needs:` is `agent` prints no `needs:` annotation — the default
is silent. A step that is **not** `agent` always prints one, and the plan says
in one line beneath the list that the run will need someone present at those
steps. That is the one thing about the shape a user cannot infer from the
titles, and it decides whether they can start the run and walk away.

**Only the shape.** Full prompts are deliberately not shown back: they are a
wall of text that gets skimmed, and they are in the file a moment later, where
a fix is one `/pipeline-patch` or `--append` away. The gate exists to catch a **wrong order or a
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
   silently, idempotently, in the shape `runbook-schema.md` § *The store*
   gives a freshly created index. Backfill an index written before ids, per
   PHASE 1's rule, before step 2.
2. Take the new id from `Last runbook number: + 1` — **before** the body is
   written, because the body's file name carries it. Nothing is written yet.
3. Write `.claude/runbooks/<id>-<name>.md`: the header, then each step in
   order. The header's `Last step number:` is the last step id assigned in this
   write — on a runbook authored whole, the number of steps.
4. Append the index block with `Status: [PENDING]`, `Steps: 0/<total>` and
   `File: .claude/runbooks/<id>-<name>.md`, in the heading and field shape
   `runbook-schema.md` § *The index block* gives, and advance the counter to
   the id **in the same write**.

What is this command's own is the *when*: it is the only thing that assigns a
**runbook** id or advances `Last runbook number:`, exactly as `/task-add` is for
`.claude/TASKS.md`, and an append assigns no runbook id because the runbook it
appends to already has one. **Step** ids are the parallel case one level down —
this command is the only thing that assigns one or advances the body's
`Last step number:`, and there both a new runbook and an append do. The ids'
shape and the reason each is taken from its counter rather than from `max()`
are the schema's, cited and not copied.

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

All of these apply to every append — at the foot or at a `--before` /
`--after` position alike — and to the `--append` half of PHASE 5:

- **Numbering continues from the body header's `Last step number:` counter**,
  never from the highest existing step id: the new steps take the next unused
  ids — the counter plus one, plus two, … — in the order they are authored, and
  the counter is advanced to the last id assigned in the same write. Backfill a
  body that has no such line first, per PHASE 1's rule. Never derive the next id
  with `max()` over the headings present; `runbook-schema.md` § *The header* is
  why. This is a rule about the id only, never the position — after an earlier
  insert the step at the foot need not be the highest-numbered one.
- **Position is list position.** Without `--before` / `--after` the new steps
  go after the last step in the list. `--before <step>` writes them, as one
  contiguous block in their authored order, immediately above that step's
  heading; `--after <step>` writes them immediately below that step's section,
  above the next step's heading, or above `## Do not re-propose` or at the end
  of the body when it is the last step. `/runbook-run` walks the body top to
  bottom, so the position is the order and the id carries none, per
  `runbook-schema.md` § *A step*.
- **`Depends on:` may reference existing steps**, including completed ones.
  The new steps' `Depends on:` lines are authored as part of the append, with
  the position in mind. **An existing step's `Depends on:` is never
  rewritten** — not to point at a step inserted above it, not for any reason.
- **The `Sequencing:` header line is never touched** — not extended, not
  replaced, not added to a runbook that has none. It is one line, fixed at
  authoring time, per `runbook-schema.md` § *The header*; an append that
  extended it is what once grew a header to a page of dated narration. A dated
  fact an appended step needs goes in its prompt, and a fact learned later
  goes in its `Context:`.
- **Existing steps are never edited.** This is the invariant that makes an
  append safe during a run, and it holds wherever the new steps land: no
  existing step's heading, marker, `Depends on:`, `Needs:`, `Context:`, prompt
  block or `Done:` line changes, and none is moved or renumbered. An insert
  adds new steps between existing ones; it changes none of them.
- **Appending to a `[DONE]` runbook flips it back to `[PENDING]`.** There is
  unfinished work again and the status has to say so. This is the one status
  this command writes other than `[PENDING]` on creation.
- **Appending to a `[FAILED]` runbook leaves it `[FAILED]`.** The halt still
  needs a decision, and adding steps does not resolve it. Say so in the report.
- **Appending to a `[RUNNING]` runbook is allowed only from the running
  session itself** — one session, one tree, no race. From any other session,
  refuse and say why. The steps are written at the runbook's current `File:`
  path, which is never migrated. The run picks the new steps up at its next step
  re-read; there is nothing to notify. It selects by list position, so a step
  inserted above steps already `[x]` is simply the next pending step it
  reaches.
- **The index `Steps: <done>/<total>` is updated** — the total grows, the done
  count is untouched.
- **The runbook's id and the index counter are untouched.** An append adds steps
  to a runbook that already has an id; nothing is assigned and
  `Last runbook number:` does not move. The body's own `Last step number:` is
  the opposite — an append is exactly what advances it.

---

PHASE 6 — COMMIT AND PUSH (skipped under `--no-commit`)

If COMMIT is false (`--no-commit` was passed), do nothing here. Report the
paths written, remind the user that nothing was committed, and stop.

Otherwise (the default), follow the commit-and-push protocol — four steps, in
this order:

1. **Pull at start.** Already run before PHASE 1, per ARGUMENT NOTE. A
   conflict stopped the run there.
2. **Commit.** Stage **exactly** the paths this run wrote — the body at its
   `File:` path and `.claude/RUNBOOKS.md`, by explicit path — and make one
   commit:

   ```
   git add -- <File: path> .claude/RUNBOOKS.md
   git commit -m "Add runbook <name>"        # or: "Append <n> steps to runbook <name>"
   ```

   On an append that migrated, `<File: path>` is the new path, and the same
   `git add` also names the old path, held from the migration, so the one
   commit carries both halves of the rename — staged exactly as
   `body-migration.md` § *Staging* says, never in a commit of its own.

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
- Write to any file before PHASE 4's **"Approve and write?"** is answered —
  the sole exception being an append target's migration, per PHASE 1.
- Build a body path from the name. The body is opened and written at `File:`.
- Migrate a `[RUNNING]` runbook, migrate anything but the append target, or
  overwrite a taken target path — `body-migration.md`.
- Accept a new name that is taken or whose first kebab segment is all digits.
- Restate the body schema, the step markers, the status vocabulary or the
  index block in this body. They are
  `../skills/runbook-run/references/runbook-schema.md`,
  cited and never copied.
- Show the full prompts back at the confirmation gate. Shape only.
- Fix a rule failure silently. Every fix is named in the report.
- Accept a step whose prompt invokes `/runbook-run`. Rule 9 is enforced here,
  not deferred to spawn time.
- Split a step under rule 10 silently, or treat that rule as a rejection.
  It is a preference: name the split, or name the reason a step was left
  whole, in the confirmation report.
- Write a `Done:` line, a step marker other than `[ ]`, or an index `Status:`
  other than `[PENDING]` — the sole exception being the `[DONE]` → `[PENDING]`
  flip an append forces.
- Write anything into `Context:` other than `none`. Corrections and learned
  facts are the run's, and a prompt's decisions belong inside the prompt.
- Edit an existing step during an append — its title, marker, `Depends on:`,
  `Needs:`, `Context:`, prompt block or `Done:` line — or move or renumber
  one. Writing new steps above an existing one with `--before` / `--after` is
  not an edit to it; changing any line of an existing step is.
- Give an inserted step an id derived from its position, or renumber existing
  steps so the ids read in order — `runbook-schema.md` § *A step*.
- Accept `--before` and `--after` together, either without `--append`, or a
  step id no step carries.
- Write to the `Sequencing:` line on an append — neither extend nor replace
  it — or write one longer than a single line when authoring.
- Append to a `[RUNNING]` runbook from a session that is not the one running
  it.
- Disambiguate a colliding name automatically. Refuse it, suggest one
  alternative, and offer `--append`.
- Reserve the names of removed runbooks.
- Derive a new id with `max()` over the blocks present, reuse a pruned
  runbook's id, renumber an existing runbook, or advance
  `Last runbook number:` on an append — `runbook-schema.md`
  § *The index block* is the authority for all four.
- Derive a new **step** id with `max()` over the headings present, or leave the
  body's `Last step number:` unadvanced after assigning one. The counter is the
  only source of the next unused step id, and a body missing the line is
  backfilled before it is read, never worked around — `runbook-schema.md`
  § *The header* and § *Backfilling a body written before the step counter*.
- Treat the id as the runbook's identity. It is an alias for the command line
  that the body's file name also carries; the name still names every message
  about the runbook.
- Ask new-versus-append anywhere except the no-argument form of PHASE 1.
- Add a runbook step to `/task-setup` or `/project-setup`, or require any
  setup before a runbook can be created.
- Execute a runbook, or any step of one. That is `/runbook-run`.
- Create a task, a feature document, or any file other than the body at its
  `File:` path and `.claude/RUNBOOKS.md`.
- Run any git command under `--no-commit` — other than the move an append
  target's migration makes, which runs either way; and on any run, never
  force-push, retry a failed push, branch, tag, or stage with a catch-all.
