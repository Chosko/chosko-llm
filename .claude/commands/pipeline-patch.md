---
name: pipeline-patch
version: 0.1.0
type: command
description: Apply a change that touches exactly one feature document, task or runbook step through that owner's amend arm, then re-check it — or refuse. From a required anchor (feature=<slug>, task=<N> or runbook=<name|id> step=<n>) it probes, walks the pipeline's graph reading only the indexes — FEATURES.md, TASKS.md, PLAN.md, RUNBOOKS.md, never a task body, feature document or runbook body — and counts the owners the change would touch. The single-owner rule is a count plus a closed checklist, never a judgement: exactly one owner and none of five structural signals (more than one owner, a dependency edge changing, scope added that no task covers, a deletion that crosses artifacts, a reorder of existing entries) loads that owner's amend arm by path, runs it with its own gate, and runs /pipeline-check scoped to the anchor. Anything else is refused in one line naming /pipeline-revise and the signal that triggered it — no escalation, no second question, nothing written. Writes no line of its own and makes no commit of its own; --commit / --no-push are forwarded to the arm.
requires: skill:pipeline-engine, skill:architect, skill:task-engine, skill:runbook-run
---

# /pipeline-patch
# Global command: apply a change that touches exactly one feature document,
# task or runbook step, through that owner's amend arm, and re-check the
# anchor — or refuse in one line and name /pipeline-revise. Reads only the
# indexes.
# Usage: /pipeline-patch <anchor> "<change>" [--commit] [--no-push]
#        anchor: feature=<slug> | task=<N> | runbook=<name|id> step=<n>
# Examples: /pipeline-patch task=42 "Hints: point at the new loader module"
#           /pipeline-patch feature=user-profile "Interfaces and contracts: promise task 51's size check"
#           /pipeline-patch runbook=implement-auth step=4 "context: the schema migration already ran"

GOAL
The cheap half of revising planned work. A change one owner's amend arm
covers — a task's wording, a promise written back into a feature document, a
fact added to a pending runbook step — needs no impact analysis: it needs the
arm, run once, and a lint to confirm nothing drifted. This command decides
that from the indexes alone, then runs the arm or refuses.

It never escalates. A patch that turns out to be structural stops and names
`/pipeline-revise`; the user chose the cheap tool, and gets to choose again.

$ARGUMENTS

---

THE ENGINE AND THE ARMS

What this command knows about the pipeline is `pipeline-engine`'s, read by
path:

- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/probes.md`
  — the probe, its verdict line and the reuse rule;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/graph.md`
  — the edges between the indexes, every one read off an index line;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/routing.md`
  — which owner a line belongs to, and, in its Amend column, the arm a
  revision routes through;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/lint.md`
  — the findings the closing check reports.

The three owners this command can patch, and the arm `routing.md`'s Amend
column gives each:

| Owner | Arm, loaded by path |
| --- | --- |
| a feature document | `/architect amend` — `${CLAUDE_HOME:-$HOME/.claude}/skills/architect/amend.md` |
| a task | `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/amend.md` |
| a runbook step | `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/step-amend.md` — a strike, a `Context:` fact, or an insert through `/runbook-create --append` |

This command restates no probe, no edge, no finding and no arm's rule.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--commit` flag (COMMIT = true) and the
optional `--no-push` flag (NO_PUSH = true), and strip both. NO_PUSH only
matters when COMMIT is true.

Then scan for the anchor, which is **required** here, in exactly one of three
forms, and strip it:

- `feature=<slug>`
- `task=<N>`
- `runbook=<name|id> step=<n>`

What remains is the change, as one quoted string. A missing anchor or an
empty change stops with:
`/pipeline-patch needs an anchor — feature=<slug>, task=<N> or runbook=<name|id> step=<n> — and the change to make. A change with no anchor is /pipeline-revise's.`

---

WORKFLOW

1. **Probe.** Run the probe from `probes.md`, or reuse a verdict line already
   in the conversation where that file's reuse rule allows.

2. **Resolve the anchor**, from the index lines alone:
   - `feature=<slug>` — an entry in `.claude/FEATURES.md`. None, or no feature
     index, stops listing the slugs that exist (or saying there are none).
   - `task=<N>` — a summary block in `.claude/TASKS.md`. An id at or below
     `Last task number:` with no block is archived and terminal, per
     `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
     § *The archive*; one above it was never assigned. Either way stop, say
     which, and list the live tasks, id and title.
   - `runbook=<name|id> step=<n>` — a block in `.claude/RUNBOOKS.md`, by name
     or id, per
     `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`
     § *The store*; an unknown one stops listing the runbooks. The step is
     resolved by the arm, which lists the runbook's steps for an unknown id —
     this command has no body to find it in.

   Nothing is written on a stop.

3. **Walk the graph** from the anchor along `graph.md`'s edges, reading only
   `.claude/FEATURES.md`, `.claude/TASKS.md`, `.claude/PLAN.md` and
   `.claude/RUNBOOKS.md`: the entries the change would write, and the edges it
   would move.

4. **Count, then check.** Proceed only when both hold:
   - **the change writes exactly one owner** — one feature document, one task
     or one runbook step, the unit one amend arm amends. Writes an arm makes
     as its own consequence — `/architect amend`'s `[STALE]` flips, the
     `Tasks:` id the task arm adds with an orphan's `Feature:`, the `Steps:`
     count a strike moves — are that arm's and are not counted;
   - **none of the five structural signals is present** (THE CHECKLIST).

   Both are read off the change and the index lines. Neither is a judgement
   about whether the change feels small.

   A change that writes **none** of the three — only a line another owner
   holds, such as a milestone's `Features:` order in `.claude/PLAN.md` — is
   not a patch. Stop in one line naming that line's owner from `routing.md`'s
   Owns column, and write nothing.

5. **Proceed.** Load the owner's arm by path and execute it end to end,
   **including its own gate**, with the flags COMMITTING forwards. The arm
   reads what its own inputs name; that read comes after this command's
   decision and never feeds back into it. An arm that refuses, or whose gate
   the user answers with stop, ends the run with the arm's own message and
   nothing written.

6. **Check.** When the arm wrote, run `/pipeline-check` scoped to the anchor:
   - `feature=<slug>` → `/pipeline-check feature=<slug>`;
   - `task=<N>` → `/pipeline-check feature=<slug>` with the slug on the task's
     `Feature:` line when it resolves in `.claude/FEATURES.md`, otherwise
     `/pipeline-check` unscoped;
   - `runbook=<name|id> step=<n>` → `/pipeline-check` unscoped — no index line
     ties a runbook to a slug, so the command has no runbook scope.

   When `/pipeline-check` is not installed, evaluate `lint.md` directly over
   the indexes and keep the findings whose identifier is the anchor or an
   entry the walk reached, rendered from their templates unchanged.

7. **Report** — the arm's closing report line, then the check's output. When
   the arm wrote and `--commit` was not passed, end with an explicit reminder
   that nothing was committed.

---

THE CHECKLIST

Five structural signals, verbatim and closed. Any one present refuses the
patch:

1. more than one owner;
2. a dependency edge changing;
3. scope added that no task covers;
4. a deletion that crosses artifacts;
5. a reorder of existing entries.

How each is read off the change and the index lines:

- **More than one owner** — the count in step 4 is two or more.
- **A dependency edge changing** — an id added to, dropped from or re-pointed
  on a `Preconditions:` line, or a plan dependency moving. An id that
  resolves to nothing is no edge (`graph.md` E4), so dropping one is not this
  signal.
- **Scope added that no task covers** — a promise added to a feature document
  that no live task on its `Tasks:` line answers to by title or `Files:`; and
  any new task, since no existing task is it.
- **A deletion that crosses artifacts** — the removal of an entry another
  index line points at: a task named on a `Preconditions:` line or listed on
  a feature's `Tasks:`, or a feature. Striking a runbook step no index line
  names is one owner and not this signal.
- **A reorder of existing entries** — an existing task or step asked to run
  at another position.

Each signal is a case `/pipeline-revise`'s classifier receives:

| Signal | Where `/pipeline-revise` takes it |
| --- | --- |
| More than one owner | the branch the change's kind selects, whose owner sequence runs each owner in order |
| A dependency edge changing | `amend.md` — a `Preconditions:` change that moves no entry — at the structural tier |
| Scope added that no task covers — a promise added to a feature document | `amend.md`, at the structural tier |
| Scope added that no task covers — a new task | `insert.md`, at the structural tier |
| A deletion that crosses artifacts | `delete.md`, at the structural tier |
| A reorder of existing entries | `reorder.md` |

---

REFUSE

One line, then stop:

```
Not a patch — <signal>: <what in the change set it off>. Run /pipeline-revise <anchor> "<change>".
```

No escalation, no second question, nothing written, no partial work: on this
path the arm is never loaded.

---

COMMITTING

`--commit` and `--no-push` are parsed here and forwarded to the arm; this
command makes no commit of its own.

| Arm | Without `--commit` (the default) | With `--commit` |
| --- | --- | --- |
| An arm loaded by path — each leaves its commit to whoever executes it | nothing is committed | the arm's closed write set, staged by explicit path and committed as one unit of work, the arm's closing report line as the subject, per `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md` and its push protocol — pull-at-start included, the push skipped under `--no-push` |
| `/runbook-create --append`, for a step insert | no flag | `--commit`, plus `--no-push` when given |

---

WRITE SET

Empty. This command writes no line any owner owns — every write in a run is
the arm's — and it appears in no who-writes-what table: its routing row owns
nothing.

---

DO NOT:
- Open a task body, a feature document or a runbook body. The walk and the
  decision read only `.claude/FEATURES.md`, `.claude/TASKS.md`,
  `.claude/PLAN.md` and `.claude/RUNBOOKS.md`. This is the line separating
  this command from `/pipeline-revise`.
- Open anything under `.claude/tasks/archive/`.
- Proceed on a judgement that a change is small enough: proceed on the count
  and the checklist, or refuse.
- Escalate into `/pipeline-revise`, ask a second question, or write anything
  on the refuse path.
- Load more than one arm, run an arm twice, or bypass an arm's own gate.
- Write any line yourself, or commit anything but the arm's own write set.
- Skip the scoped check after the arm wrote.
