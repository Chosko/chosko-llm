# Amending one task

Authority for: changing one existing task in place — the two checks made
before anything is written, which body sections and which summary-block
fields may change, rewriting a `Preconditions:` edge, deleting a live task,
adding `Feature:`, the single gate, the closed write set and the closing
report line.

Authored here, by feature `owner-amend-arms`. No consumer ever carried a copy
of it: until it existed, changing one task had no command at all. It is a
peer of the other reference files rather than a section inside one of them
because the protocol spans several of them, and a home inside one would give
it two.

> **A note on that citation.** Naming the feature records where the rule was
> authored, for a reader working on the `chosko-llm` repo. It is never an
> instruction to open a path at run time: the domain layer is not installed,
> and everything below stands on its own.

The file is complete on its own. A consumer that has read only this file —
and, where a rule already lives there, the reference files it cites by path —
can execute an amendment end to end without opening any `task-*` feature's
body.

---

## Inputs

- **The task id** `<N>`.
- **The change** — what to alter, in words.
- `.claude/TASKS.md` — task `<N>`'s summary block, parsed per
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
  § *Parsing the index*; and, for the gate, the blocks of any task its
  `Preconditions:` names or whose `Preconditions:` names it.
- `.claude/tasks/<N>.md` — this task's body and no other, opened per
  `resolution.md` § *Opening a per-task body file*.
- For check 2 only, when the block carries `Feature: <slug>`: that slug's
  `.claude/FEATURES.md` entry and the document its `Doc:` line names.

## Before writing — two checks

Made in this order, before the gate. Either one failing stops the amendment
with nothing written.

1. **The task is live, and not `[IN PROGRESS]`.**
   - `[IN PROGRESS]` → refuse, naming the task:

     > Can't amend task <N> — "<title>": it is `[IN PROGRESS]`, and an
     > implementation is underway against its current spec. Let it finish,
     > or reset its status first.

   - `[DONE]` or `[SKIP]` → refuse. Completed or abandoned work is never
     touched; follow-up work is a new task —
     `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/status.md`
     § *Transitions*.
   - An id with no summary block is archived and terminal, per
     `resolution.md` § *The archive* → refuse on the same ground, and open
     nothing under `.claude/tasks/archive/`.
   - `[STALE]` → may be amended. The amendment never clears the tag — that
     is reconciliation's, per
     `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/stale.md`
     § *Clearing it* — and the report says the task is still `[STALE]`.
2. **The change leaves the feature's promise alone.** On a task carrying
   `Feature: <slug>`, read the feature document and ask whether the change
   alters what it promises — a component, a contract, a behaviour, a
   non-goal — rather than how this one task delivers its part of it. If it
   does, stop and route:

   > This changes what feature `<slug>` promises, not only task <N>. Amend
   > the design with `/architect amend feature=<slug> "<change>"` — its guard
   > decides what happens to task <N>.

   A task with no `Feature:` line skips this check.

## What may change

### The body

The current schema — `## Goal`, `## Acceptance criteria`, `## Decisions`,
`## Manual interventions`, `## Hints` — under the title line and the body's
own `Target:` line.

| Section | Amendment |
| --- | --- |
| `## Goal` | Rewritten in place. |
| `## Acceptance criteria` | Rewritten in place: bullets added, reworded or removed. |
| `## Hints` | Rewritten in place. |
| `## Decisions` | Added to. An existing bullet is rewritten only when the change reverses it, and the rewrite then carries the reason for the reversal — a decision is the task's written reason, and deleting one silently loses it. |
| `## Manual interventions` | Added, rewritten or removed only together with `Target:`, under the pairing rule in `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/targets.md`. |
| Title line `# Task <N> — <Title>` | Changes only when the summary block's title does, to the same text. |

**Owned documents.** A change that adds a path owned by another pipeline
command to `## Hints` or to `Files:` needs the grant-or-drop answer that
`/task-add`'s OWNERSHIP PRE-AUTHORISATION asks for such a path — its owner
table, its two answers and its hard rules, cited here and not restated —
asked inside this file's gate, never at a second one. An existing grant is
never widened by an amendment; a wider grant is a new question.

### The summary block

| Field | Amendment |
| --- | --- |
| `## <N>. <Title>` | The title may change. The id never does. |
| `Status:` | Only to `[SKIP]`, to delete the task (below). Every other transition belongs to its own writer, per `status.md` § *Transitions*. |
| `Target:` | May change — together with `## Manual interventions` per `targets.md`, and with the body's `Target:` line. |
| `Files:` | May be rewritten. |
| `Preconditions:` | May be rewritten to add or drop an edge (below). |
| `Feature:` | May be added to an orphan task; never changed or removed on a feature-derived one (below). |

`Last task number:` never moves, and the block never moves in the file:
position is decided when a task is created (`resolution.md` § *Index file
format*), and an amendment reorders nothing. A `Status:` is written in
`.claude/TASKS.md` only, per `resolution.md` § *Where a status flip is
written*.

### `Preconditions:`

An edge may be added or dropped by rewriting this task's own
`Preconditions:` line.

- **A dropped edge is named in the task's `## Decisions`**, with why the
  task no longer waits on it, so the removal has a written reason and a
  reader who finds the edge gone can find out why.
- An added edge that closes a precondition cycle is named at the gate: under
  `resolution.md` § *Eligibility*, every task on a cycle stays blocked.
- Only this task's line is written. Another task's `Preconditions:` is never
  edited here.

### Deleting a live task

A live task is deleted by writing `Status: [SKIP]` and a dated `## Decisions`
bullet giving the reason. **Never by removing its block or its body**:
removing a summary block from the backlog is `/task-clean`'s act, over
terminal statuses only, and `[SKIP]` is what makes the task eligible for it.
The vocabulary is `status.md`'s.

Every task whose `Preconditions:` names the skipped one is named at the gate:
`[SKIP]` satisfies the eligibility clause, so those tasks stop waiting.

### `Feature:`

- **Added to an orphan task** — only onto a `[PLANNED]` feature, the one
  kind `/task-add feature=<slug> --single` attaches a task to — and the
  task's id is appended to that feature's `.claude/FEATURES.md` `Tasks:` line
  in the same amendment. The two lines are one link (`stale.md` § *Detecting
  it and finding the feature*); writing one half leaves the other
  contradicting it.
- **Never changed or removed on a feature-derived task.** The feature's
  `Tasks:` line is the other half of that link and would have to move with
  it, and moving a task between features is re-planning, which is
  `/task-add feature=<slug>` reconciliation's.

## The gate

One gate, carrying: task `<N>`'s id, status and title; each field and
section that changes, before → after; any dropped edge with its reason; any
task a `[SKIP]` releases; any cycle an added edge closes; any owned-document
question. End with **"Apply?"** and wait for an explicit answer. Silence, an
unclear reply or EOF writes nothing.

## What is written

Exactly:

- task `<N>`'s summary block in `.claude/TASKS.md` — the fields the table
  above lets change, and no other block;
- `.claude/tasks/<N>.md`;
- `.claude/FEATURES.md` — one feature's `Tasks:` line, and only when
  `Feature:` was added to an orphan task.

Nothing else: no other task's block or body, no feature document, no
`Status:` value but `[SKIP]`, no `Last task number:`, nothing under
`.claude/tasks/archive/`.

Committing is the consumer's. When it commits, it stages those paths by
explicit path as one unit of work, per
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`
§ *Staging* and § *One commit per unit of work*.

## The closing report line

```
Amended task <N> — <fields and sections changed>[; skipped: <reason>][; dropped precondition <M>: <reason>][; still [STALE]].
```

---

## Per-consumer notes

- **The pipeline revision surfaces** — the consumers. They read this file by
  path and execute it. They own none of the lines it writes; each stays its
  owner's.
- **`/task-add`** — the owner of the lines this file lets change: the body,
  the block's title, `Target:`, `Files:`, `Preconditions:` and `Feature:`,
  and `FEATURES.md` `Tasks:`. Its own body does not read this file. Its
  OWNERSHIP PRE-AUTHORISATION and its `--single` rule are cited above, not
  changed.
