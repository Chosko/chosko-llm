# The runbook asset kind

The single authority for what a runbook **is**: where it is stored, the shape
of its body, the four step markers, the four-status vocabulary, and the index
block. Every feature in the runbook suite reads this file rather than carrying
its own copy — a second copy is the copy that drifts.

This file describes the artifact. It does not describe the execution protocol
(that is `SKILL.md` in this folder) or the authoring rules (those live in
`/runbook-create`'s body, which has exactly one consumer).

---

## The store

```
.claude/runbooks/<name>.md          the runbook
.claude/RUNBOOKS.md                 the index
```

Both are **committed**. The work a runbook drives is executed across machines
and cloud sessions, and the `Done:` lines are the record of what actually
happened — they are re-read far more often than anyone expects.

`<name>` is kebab-case and **is** the identifier: it is what `/runbook-run`,
`/runbook-create --append` and `/runbook-clean` take as their argument, and
what appears in the index heading. There is no counter and no numeric id —
names are the identifiers, exactly as in `.claude/FEATURES.md`.

Both paths are created **on first use**, silently and idempotently, by
whichever feature first needs to write one. A project needs no setup step for
runbooks; nothing has to be initialised in advance. A freshly created index is
its title line and nothing else.

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
Sequencing: 1–4 ordered (all three edit skills/task-implement/SKILL.md); 5–7 independent.
Companion: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md

## [ ] 1. <title>

Depends on: none

Context: none

```prompt
<self-contained prompt: names the document to read first, carries every
decision that exists nowhere on disk, may open with a slash command>
```

## [ ] 2. <title>

Depends on: 1

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
| `Sequencing:` | one line of prose stating the order **and why it is the order**. This is the part a reader needs and a bare dependency graph does not carry — "1–4 all edit the same file" is worth more than four `Depends on:` lines. |
| `Companion:` | optional. A background document offered to every step, inserted into every spawned prompt. |

### A step

A step is a `##` heading carrying its marker, its number and its title:

```
## [ ] 3. Peer review the launcher change
```

Under the heading, in this order:

- **`Depends on:`** — a comma-separated list of step numbers, or `none`. It
  records the real constraint. It never causes anything to run in parallel:
  steps are sequential, always. It exists so a deadlock is detectable and so
  `--only` and `--from` have something to check against.
- **`Context:`** — `none` at authoring time in the common case, and the run's
  field thereafter: corrections, failure notes, and facts learned by earlier
  steps, each as a dated bullet. The decisions a prompt needs belong *inside*
  the prompt, which is what keeps the fenced block pasteable into a fresh
  session on its own.
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

## The four step markers

| Marker | Meaning |
| --- | --- |
| `[ ]` | pending |
| `[~]` | in progress |
| `[x]` | done — a `Done:` line follows |
| `[!]` | failed — a `Done:` line follows, opening with the reason |

### The `Done:` line

**It does not exist until a run writes it.** An authored runbook has no `Done:`
lines at all. A run appends one when a step reaches `[x]` or `[!]`, and it
records three things:

1. **the commit sha** (or that there was none, and why),
2. **the decisions taken while executing** — what the agent chose where the
   prompt left room,
3. **any premise in the step that proved wrong.**

Those are the three things a hand-run of this loop recorded and the three that
were re-read most often. A `Done:` line whose only content is "done" is a line
that will be worthless in a week.

---

## The four-status vocabulary

In `.claude/RUNBOOKS.md`:

| Status | Meaning | Written by |
| --- | --- | --- |
| `[PENDING]` | authored and not started, or started and interrupted | `/runbook-create`, `/runbook-run` |
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

`.claude/RUNBOOKS.md` mirrors `.claude/TASKS.md`'s block shape, minus its
counter:

```
---

## <name> — <one-line title>

Status: [PENDING]
File: .claude/runbooks/<name>.md
Created: 2026-08-24
Source: /architect run
Steps: 0/7

---
```

- `Steps:` is `<done>/<total>`, where **done counts `[x]` only**. `[~]` and
  `[!]` are not done.
- A fifth line, `Failed at: step <n> — <reason>`, is present **only** while the
  status is `[FAILED]`, and is removed when a re-run clears it. It is carried
  in the index because the one thing a reader of a halted runbook needs is why
  it halted, and making them open the body for a single sentence is the
  friction that stops the listing being used.

**The index is a summary.** It holds nothing that is not derivable from the
body. That is what makes a hand-edited body safe — re-reading it reconciles the
index — and what lets a listing render without ever opening a body file.

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
`Steps:` count.

**There is no per-step `Produces:` field.** It was considered — a step
declaring up front whether it ends in a commit or in a report would let an
ambiguous result be classified more confidently. It is not adopted for two
reasons: the result classification is already unambiguous without it (`DONE` +
report, `QUESTIONS FOR USER`, or anything else — see `SKILL.md`), and a field
the author must predict correctly is a field that will be wrong. A wrong
`Produces:` would make a correct result look like a failure, which is worse
than having no field at all.
