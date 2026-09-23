# The runbook asset kind

The single authority for what a runbook **is**: where it is stored, the shape
of its body, the five step markers, the four-status vocabulary, and the index
block. Every feature in the runbook suite reads this file rather than carrying
its own copy — a second copy is the copy that drifts.

This file describes the artifact. It does not describe the execution protocol
(that is `SKILL.md` in this folder) or the authoring rules (those live in
`/runbook-create`'s body, which has exactly one consumer).

---

## The store

```
.claude/runbooks/<id>-<name>.md     the runbook
.claude/RUNBOOKS.md                 the index
```

Both are **committed**. The work a runbook drives is executed across machines
and cloud sessions, and the `Done:` lines are the record of what actually
happened — they are re-read far more often than anyone expects.

`<name>` is kebab-case and **is** the identifier: it is what appears in the
index heading, in the body heading (`# Runbook: <name>`), and in every error,
report and relay block about a runbook.

Beside the name, every runbook carries a numeric **id** — a shorthand for
referring to it on a command line, the way a task id works in
`.claude/TASKS.md`. The id is an **alias, never a replacement**: a rename is
still a rename, errors and reports name the runbook by name, and the body
carries no id of its own. The id appears in the body's **file name** — a
runbook named `runbook-slug` with id 3 lives at `3-runbook-slug.md` — so the
number typed on a command line is the one visible on disk; the index stays the
id's authority.

### `File:` is the body's path

**Every command opens a runbook's body at the path its index block's `File:`
line holds, and never builds the path from the name.** A block for a runbook
created with ids in file names says `File: .claude/runbooks/<id>-<name>.md`. A
block written earlier may still say `File: .claude/runbooks/<name>.md`, and
that legacy value **stays correct**: the file is where `File:` says it is.

**The migration check.** A command that is writing a runbook, and whose block's
`File:` file name does not begin with `<id>-`, has a body to migrate, per
`./body-migration.md`.

### Resolving a runbook argument

Every command that takes a runbook — `/runbook-run`, `/runbook-create
--append`, `/runbook-clean`, `/runbook-describe`, and the `runbook=` anchor —
accepts it as `<id>`, `<name>` or `<id>-<name>`, and resolves it to **exactly
one** index block by these checks, in order:

1. **All digits** — an id: the block carrying that id.
2. **Exactly equal to a block's name** — that block.
3. **Of the shape `<digits>-<rest>`, where block `<digits>` exists and its name
   is `<rest>`** — that block. When the halves disagree it is an **error**,
   never a fallback to either half: if block `<digits>` exists under a
   different name, name the runbook that id actually belongs to and say that
   `<rest>` is not it; if `<rest>` is some other runbook's name, say so too. A
   mismatched compound is a typo, and either half picked silently would act on
   the wrong runbook.
4. **Anything else** — unknown. Report it by listing the runbooks that do
   exist.

An argument that resolves to no block stops the command before it writes
anything, and so does one of the errors above.

**Why this is unambiguous rather than heuristic.** A kebab-case name can never
be all digits, so check 1 never meets a name. A new name whose first kebab
segment is all digits (`2026-migration`) is **refused** at creation, with one
suggested alternative, exactly as a name already taken is — so for every
runbook created under this rule, checks 2 and 3 can never both match. Name
before prefix protects a runbook authored earlier with such a name: it still
resolves by its exact name. The one residual case is a legacy name that is
exactly `<id>-<another runbook's name>`, which could match two blocks; that is
**reported as an ambiguity naming both candidates**, never resolved by
guessing.

Both paths are created **on first use**, silently and idempotently, by
whichever feature first needs to write one. A project needs no setup step for
runbooks; nothing has to be initialised in advance. A freshly created index is
its title line and its counter at `0`, and nothing else.

A name already present is refused with a suggested alternative rather than
disambiguated automatically — a runbook is referred to by name for the length
of its execution, and two similar names are a real hazard. Names of removed
runbooks are not reserved: nothing holds a persistent pointer to a runbook the
way a task's `Preconditions:` line points at a task id.

---

## The body schema

````markdown
# Runbook: <name>

Created: 2026-08-24 · Source: /architect run · Model: opus
Last step number: 7
Execution policy: unattended                      ← optional; absent means attended
Sequencing: 1–4 all edit skills/task-implement/SKILL.md.          ← optional; one line
Companion: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md
Archive: 1, 2                                     ← optional; written by /runbook-prune

## [ ] 1. <title>

Depends on: none

Context: none

```prompt
<self-contained prompt: names the document to read first, carries every
decision that exists nowhere on disk, may open with a slash command>
```

## [ ] 2. <title>

Depends on: 1

Needs: agent+human          ← optional; omitted entirely on an `agent` step

Context: none

```prompt
...
```

## Do not re-propose

- <option already assessed and rejected, with its reason>
````

### The header

| Field | Meaning |
| --- | --- |
| `Created:` | provenance — the date the runbook was authored. |
| `Source:` | provenance — where the material came from (`/architect run`, `manual`, …). |
| `Model:` | the model **every** step is spawned with. Header-only; there is no per-step model. `/runbook-run --model <model>` overrides it for a whole run. |
| `Last step number:` | the **highest step id ever assigned** in this runbook — not the highest currently present — and it **only ever increases**. The next unused step id is this value plus one; it is **never derived with `max()`** over the step headings. This is `.claude/TASKS.md`'s `Last task number:` rule and the index's own `Last runbook number:` rule verbatim, and it holds for the same reason: once a step can be removed, a counter derived with `max()` drops and hands a removed step's id to the next step written — repointing every reference recorded before the removal (`Depends on:` lines, `Failed at: step <n>`, `Context:` bullets, commit messages) at the wrong step. |
| `Execution policy:` | optional. `attended` or `unattended` — what a run does with a question nobody present can answer: under `attended` the question is relayed and the run waits; under `unattended` the step is parked (`[P]`) and the run goes on. **Absent means `attended`.** Authored by `/runbook-create` only when the user asks for it, never by default, and never rewritten by a run; `/runbook-run --attended` / `--unattended` overrides it for one run. Any value other than those two words is an **argument error at run time**. |
| `Sequencing:` | optional, absent by default; **one line** when present. Its only job is **why** this is the order, in the cases list position and `Depends on:` cannot express — "1–4 all edit the same file". What the order *is* is list position and `Depends on:`, never this line. It is written at authoring time and never changed afterwards: an append or an amendment does not extend it, and a dated fact about an inserted or struck step goes in that step's `Context:`. The one-line cap is what stops the header growing without bound — an extendable field accumulated a full page of dated append narration in one real runbook. An existing longer line is left as it is. |
| `Companion:` | optional. A background document offered to every step, inserted into every spawned prompt. |
| `Archive:` | optional, last in the header, after `Companion:`. A comma-separated list of the step ids `/runbook-prune` has removed from this body, ascending. Absent on a runbook never pruned, and never written empty. **An id on this line counts as `[x]`** — see § *The five step markers*, which is where that rule is stated and why the line exists at all: it is what keeps a surviving `Depends on:` naming a pruned step resolvable, and what keeps the index's `Steps:` count honest once the steps it counted are gone. It is a bare id list and nothing more: no titles, no `Done:` lines, no commit shas. The record of what those steps did lives in the commits they made; the ids exist for dependency resolution and the count. |

### A step

A step is a `##` heading carrying its marker, its number and its title:

```
## [ ] 3. Peer review the launcher change
```

**The number is the step's id, not its position.** It is a stable
identifier, assigned once when the step is written and never changed
afterwards — the same rule `.claude/TASKS.md` uses for task ids. **The next
unused id is the header's `Last step number:` plus one**, never the highest
existing step id: the counter is what survives a step being removed. **Order is
list position**: a runbook is walked top to bottom, and the step that appears
first comes first, whatever its number. A body may therefore legally carry
step ids out of numeric order — a step inserted with `/runbook-create --append
<name> --before 3` takes the next unused id and sits above step 3:

```
## [x] 1. …
## [x] 2. …
## [ ] 6. …      ← inserted later; runs before 3
## [ ] 3. …
```

Never infer order from the numbering, and never renumber to restore it. Every
reference to a step is by id — `Depends on:`, `/runbook-run`'s `--from`,
`--to` and `--only`, a `Context:` bullet's `(from step N)`, the index's
`Failed at: step <n>` — and renumbering would silently repoint all of them.

Under the heading, in this order:

- **`Depends on:`** — a comma-separated list of step ids, or `none`. It
  records the real constraint. It never causes anything to run in parallel:
  steps are sequential, always. It exists so a deadlock is detectable and so
  `--from`, `--to` and `--only` have something to check against.
- **`Needs:`** — optional. Whether executing this step requires a person, and
  in what measure. Exactly three values, deliberately the same vocabulary as a
  task's `Target:` in `.claude/TASKS.md` so the two stores read alike:

  | Value | Meaning |
  | --- | --- |
  | `agent` | The step's subagent can execute it start to finish. **The default when the line is absent.** |
  | `agent+human` | Mostly agent work, but part of it needs a person — an editor-only operation, a GUI wizard, hardware. |
  | `human` | Nothing in it is agent-executable; the step is a walkthrough. |

  It is **authored**, by `/runbook-create`, at the moment the author still
  knows. It is descriptive, not enforcing: nothing gates on it, and a run does
  not refuse a step because of it. Its job is to let a reader see, before
  starting, which steps mean the run cannot be left unattended — the one thing
  a `Depends on:` graph cannot tell them.

  An absent `Needs:` means `agent`, and it is the common case. A runbook whose
  every step is agent work carries no `Needs:` lines at all — **`Needs: agent`
  is never written**, which is why the template above shows the line only on
  the step that needs it. A reader who sees no `Needs:` on a step has been told
  it is `agent`, not that the author forgot.
- **`Context:`** — `none` at authoring time in the common case, and the run's
  field thereafter: corrections, failure notes, and facts learned by earlier
  steps, each as a dated bullet. The decisions a prompt needs belong *inside*
  the prompt, which is what keeps the fenced block pasteable into a fresh
  session on its own. Three bullet forms, all dated:

  | Form | Written when |
  | --- | --- |
  | `- <date> <correction, failure note or fact>` | a run learns something a later step or reader needs. |
  | `- <date> parked: <question>` | the step is parked (`[P]`). The question **verbatim**, options included, multi-line where the question was — never an approval-gate draft, which is work-in-progress and lives where the work does. |
  | `- <date> unparked with answer: <text>` | the parked question is answered and the marker goes back to `[ ]`. The answer as given; the step's agent reads it here in place of asking again. |
- **exactly one fenced ```prompt``` block** — the self-contained prompt. It is
  written once, by the author, and is **never edited by a run**. New facts go
  to `Context:`; a reader must always be able to see what was originally asked
  and what was learned since, separately.

### `## Do not re-propose`

Optional, trailing, and **global to the runbook**: it is appended to every
spawned prompt, not just the next one. It lists options already assessed and
rejected, with their reasons. Without it a fresh agent — which by design has
none of the conversation the prompts came out of — re-proposes what was already
turned down.

---

## The five step markers

| Marker | Meaning |
| --- | --- |
| `[ ]` | pending |
| `[~]` | in progress |
| `[x]` | done — a `Done:` line follows |
| `[!]` | failed — a `Done:` line follows, opening with the reason |
| `[P]` | parked — a `Context:` bullet opening `parked:` carries the question (§ *A step*) |

A step is one marker at a time: `[P]` replaces the `[~]` the step carried
while it ran, and the two never sit on the same step. `[P]` counts as **not
done** in the index's `Steps:` count, and it is **committed**, like `[x]` and
`[!]` — `[~]` is the one marker that is never committed. It is written under
the `unattended` execution policy only (§ *The header*), and it is cleared to
`[ ]` when the question is answered, with a second `Context:` bullet.

### An archived id counts as `[x]`

A step id on the header's `Archive:` line **is `[x]`, everywhere a marker is
read**. It has no heading left to carry one: `/runbook-prune` removed the step,
and the id on that line is all that survives of it.

This is the rule the whole prune rests on, and it is stated here rather than in
`/runbook-prune`'s body because every reader of a marker needs it, not only the
command that writes the line:

- a `Depends on:` naming an archived id is **satisfied** — which is why a prune
  runs no dependency check and rewrites no `Depends on:` line;
- the index's `Steps:` count counts an archived id as done, and as present —
  see § *The index block*;
- a body whose every remaining step is `[x]`, or that has no remaining steps at
  all, is a `[DONE]` runbook exactly as before.

A struck step reaches `[x]` the same way (`references/step-amend.md`), so the
two compose without a special case: a struck step is pruned like any other, and
its id then resolves from `Archive:` as it did from its heading.

### The `Done:` line

**It does not exist until a run writes it.** An authored runbook has no `Done:`
lines at all. A run appends one when a step reaches `[x]` or `[!]`.

**The default is terse — one line, in this form:**

```
Done: <YYYY-MM-DD>, commit `<sha>` (<N> files, +<X>/-<Y>).
```

The date the step finished, the commit sha (several, comma-separated, with the
diffstat summed across them), and the diffstat. A step that made no commit says
so in the sha's place, and why: `Done: <YYYY-MM-DD>, no commit — <reason>.`

Two things are added **only when they pass one test** — would a later reader of
this runbook be misled without it?

- **a decision taken while executing** — what the agent chose where the prompt
  left room, when a later step or reader would otherwise assume the other
  choice;
- **a premise in the step that proved wrong.**

What passes the test is what a re-reader must know, never what the agent did to
arrive there. None of these belong on the line, whatever the report carried:

- per-round review tallies — findings raised, accepted, rejected;
- which files were touched — the diffstat already counts them, and the commit
  names them;
- a restatement of the step's prompt or of a task body;
- narration of the agent's own resumption, retries or process.

A line that passes nothing is the one-line default and is complete as it is.
The record lives in the commit; the `Done:` line points at it. (Lines written
before this form are not rewritten — they are the record of what happened.)

A `[!]` step's `Done:` line still **opens with the failure reason**, and a
struck step's line is `references/step-amend.md`'s, unchanged.

---

## The four-status vocabulary

In `.claude/RUNBOOKS.md`:

| Status | Meaning | Written by |
| --- | --- | --- |
| `[PENDING]` | authored and not started, or started and interrupted — a runbook waiting on a `[P]` step is `[PENDING]` too, and the index's `Parked:` line is what says so | `/runbook-create`, `/runbook-run` |
| `[RUNNING]` | a step is executing now | `/runbook-run` |
| `[FAILED]` | a step reported failure or an unreadable result; the run halted | `/runbook-run` |
| `[DONE]` | every step is `[x]` | `/runbook-run` |

These four are **deliberately distinct** from `.claude/TASKS.md`'s status tags
and `.claude/FEATURES.md`'s, so that a grep for a status never returns a mix of
the three stores. Do not borrow a tag from either of the others, and do not
lend one of these to them.

A status argument is matched **without brackets and case-insensitively**, the
convention `/task-list` already uses. An unknown status names the four valid
ones rather than printing nothing — a silent empty result is
indistinguishable from having no matching runbooks.

---

## The index block

`.claude/RUNBOOKS.md` mirrors `.claude/TASKS.md`'s block shape **and its
counter**:

```
# Runbooks

Last runbook number: 7

---

## 3. <name> — <one-line title>

Status: [PENDING]
File: .claude/runbooks/<id>-<name>.md
Created: 2026-08-24
Source: /architect run
Steps: 0/7

---
```

- The heading carries the **id, the name and the one-line title**, in that
  order. The id is the only part of the heading that is not the runbook's own
  wording.
- `Last runbook number: <N>` tracks the **highest id ever assigned**, not the
  highest currently present, and **only ever increases**. Ids are stable: a
  survivor of a prune is never renumbered and a pruned id is never reused.
  This is `TASKS.md`'s rule verbatim and holds for the same reason — a counter
  derived with `max()` hands a deleted runbook's id to the next one, and every
  reference written down before the prune then points at the wrong runbook.
- `Steps:` is `<done>/<total>`, where **done counts `[x]` only**. `[~]`, `[!]`
  and `[P]` are not done. **Every id on the body's `Archive:` line counts toward
  both halves** — it is `[x]` (§ *An archived id counts as `[x]`*) and it was a
  step. So total is the steps present plus the archived ids, done is the
  present `[x]` steps plus the same archived ids, and a prune therefore changes
  neither number: a runbook pruned to nothing still reads `7/7`, not `0/0`.
  That is what keeps the index a summary — the count stays derivable from the
  body alone, from its steps and its header together.
- A line `Failed at: step <n> — <reason>` is present **only** while the status
  is `[FAILED]`, and is removed when a re-run clears it. It is carried in the
  index because the one thing a reader of a halted runbook needs is why it
  halted, and making them open the body for a single sentence is the friction
  that stops the listing being used.
- A line `Parked: steps <ids>` — the ids of every `[P]` step, ascending — is
  present **only** while at least one step is `[P]`, and is removed when none
  remains. It is the `Failed at:` rule above applied again, for the same
  reason: a listing shows a runbook waiting on an answer without opening its
  body.

**The index is a summary.** With one exception it holds nothing that is not
derivable from the body: that is what makes a hand-edited body safe —
re-reading it reconciles the index — and what lets a listing render without
ever opening a body file. The exception is the id and its counter, which are
assigned, not derived, and therefore live only here.

### Backfilling an index written before ids

An index with no `Last runbook number:` line, or blocks whose headings carry no
id, is upgraded **in place by the first command that writes to it** —
`/runbook-create`, `/runbook-clean` or `/runbook-run`. Assign ids in the order
the blocks already appear, set the counter to the highest assigned, and change
nothing else in the file.

**A read-only command never performs it.** `/runbook-list` renders an id-less
block with `-` in its id column and moves on. Correcting the index belongs to a
command that already has it open for writing — the same rule that stops the
listing correcting a `Steps:` count it thinks is wrong.

### Backfilling a body written before the step counter

The same shape, one level down. A body with **no `Last step number:` line** is
legal — every body written before the field existed has none — and is upgraded
**in place**, set to the highest step id present in it, by whichever of these
two commands writes it first:

- **`/runbook-create --append`**, before it assigns any id;
- **`/runbook-prune`**, before it removes anything.

Those are the only two. They are the commands the counter is load-bearing
for — one assigns from it, the other is why deriving it with `max()` stopped
being safe — and a body they never touch needs no upgrade.

**`/runbook-run` and `references/step-amend.md` write bodies and never backfill
it.** The header is `/runbook-create`'s line by that command's
ownership-by-line table, and neither of them reads the value: a run writes
markers, `Done:` lines and `Context:` bullets, and an amendment strikes a
pending step. Widening the header's ownership for a value neither needs buys
nothing. **A read-only command never backfills**, exactly as above.

This is a backfill, not a migration: no sweep, no script, and no
`/pipeline-check` finding for a body that has not got one yet.

---

## Two deliberate absences

Both were considered and rejected. They are recorded here so a later reader
does not re-add them.

**There is no `[SKIP]` status.** A runbook is authored complete: the
confirmation gate at authoring time is where a step nobody wants gets struck.
An unwanted step is **deleted before the run**, not carried as a tombstone.
Tasks need `[SKIP]` because a backlog accumulates over months and the record of
a decision not to do something has value; a runbook is a single ordered plan
with a beginning and an end, and a skipped step in it is just noise in the
`Steps:` count. `[P]` is not a skip: a parked step is still to run, once its
question is answered.

**There is no per-step `Produces:` field.** It was considered — a step
declaring up front whether it ends in a commit or in a report would let an
ambiguous result be classified more confidently. It is not adopted for two
reasons: the result classification is already unambiguous without it (`DONE` +
report, `QUESTIONS FOR USER`, or anything else — see `SKILL.md`), and a field
the author must predict correctly is a field that will be wrong. A wrong
`Produces:` would make a correct result look like a failure, which is worse
than having no field at all.
