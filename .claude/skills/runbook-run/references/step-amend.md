# Amending one step

Authority for: changing one step of a runbook after it was authored —
striking it, inserting a step beside it, adding facts to its `Context:` —
what never changes, what a `[RUNNING]` runbook accepts, the single gate, the
closed write set and the closing report line.

It sits beside `runbook-schema.md` and `subagent-contract.md` because several
features read it by path, which is what this folder is for. It is complete on
its own: a consumer that has read only this file — and `runbook-schema.md`,
where this file cites it — can execute an amendment end to end without
opening `/runbook-run`'s or `/runbook-create`'s body. The one exception is an
insert, which is performed by running `/runbook-create --append` itself.

---

## Inputs

- **The runbook** — a name or an id, resolved by
  `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`
  § *The store*'s one rule. An unknown name or id lists the runbooks that do
  exist and stops.
- **The step** — by id, never by position (`runbook-schema.md` § *A step*).
  An id no step carries lists the runbook's steps — id, marker and title, in
  list order — and stops.
- **The operation** — *strike* with its reason, *insert* with its material
  and a position, or *context* with the facts to add.

It reads `.claude/RUNBOOKS.md` (this runbook's block) and
`.claude/runbooks/<name>.md`, and nothing else.

## What may be amended

- **Only a pending step — `[ ]`.** A step already `[x]` or `[!]` is never
  edited, and an existing `Done:` line is never rewritten: those are the
  record of what happened. A `[~]` step is in a subagent's hands right now and
  is never edited either.
- **A `[RUNNING]` runbook accepts inserts after the current step and nothing
  before it.** The current step is the `[~]` one. On a `[RUNNING]` runbook a
  strike or a `Context:` fact likewise lands only on a pending step listed
  below the current one, and every amendment is made from the running
  session — the rule `/runbook-create --append` already applies to an insert:
  one session, one tree, no race.
- A `[DONE]` runbook has no pending step to strike or annotate. An insert
  into one is `/runbook-create --append`'s, under its own rules.

## Strike

A step nobody should run is **struck**, never deleted:

- its marker becomes `[x]`;
- a `Done:` line is written under it, opening `struck — <reason>`, with **no
  commit sha** — there was no commit, and the reason says why;
- it keeps its number, its title, its `Depends on:`, its `Context:` and its
  prompt block.

It is never deleted and steps are never renumbered, because a `Depends on:`
line elsewhere may point at the struck step's number, and `runbook-schema.md`
§ *A step* is why ids never move. `[x]` is the one existing marker that
works: `/runbook-run`'s selection already passes over a ticked step with no
special case, and the runbook can still reach `[DONE]` once every step is
`[x]`. `[!]` would mean *failed* and halt the run; a strike is a decision,
not a failure.

Two consequences, both named at the gate:

- Every step whose `Depends on:` names the struck step is released by it: a
  struck step is `[x]`, and `[x]` is what a dependency waits for.
- The index's `Steps:` done count counts the struck step, since it counts
  `[x]` (`runbook-schema.md` § *The index block*). When the strike leaves
  every step `[x]`, the index `Status:` becomes `[DONE]` — what the
  vocabulary says a runbook whose every step is `[x]` is.

A struck step's `Done:` line is the one `Done:` line not written by a run.
`runbook-schema.md` § *Two deliberate absences* — an unwanted step is deleted
before the run — governs the authoring gate, before a step has an id anything
relies on. After that, a step is struck, not deleted.

## Insert

Inserting a step **is** the positional append:
`/runbook-create --append <name|id> --before <step>` or `--after <step>`, run
as that command runs it, with its own confirmation gate and its own APPEND
RULES. Without either flag the new step goes to the foot. This file describes
no second insertion mechanism: `/runbook-create --append` is the runbook
suite's only step writer.

On a `[RUNNING]` runbook the position must lie after the current step —
`--after` the current step, or `--before` / `--after` a pending step listed
below it. A position at or above the current step is refused.

## Context

A pending step's `Context:` may gain **dated fact bullets**, the field's shape
in `runbook-schema.md` § *A step*:

```
Context:
- 2026-09-11 (amend): <the fact>
```

When the line reads `Context: none`, the bullets replace `none`. Existing
bullets are never rewritten or removed. `Context:` is the **only field an
amendment adds to**.

## The prompt block is immutable

A step's fenced prompt block is never edited — `runbook-schema.md` § *A
step*. The consequence for an amendment: **a step whose prompt is wrong is
struck, and a corrected step inserted**, `--after` the struck one so it runs
where the struck one would have. The corrected step takes a new id. A
`Depends on:` line naming the struck id is not rewritten — `/runbook-create`'s
APPEND RULES forbid it — so list position is what keeps the corrected step
ahead of the steps that depended on the struck one; say so at the gate.

## Never changed

- The header, `Sequencing:` (an insert extends it, as `/runbook-create
  --append` does), `Companion:`, `## Do not re-propose`, and any step's
  title, `Depends on:` or `Needs:`.
- Any marker, except a pending step's `[ ]` → `[x]` on a strike.
- Any step already `[x]`, `[!]` or `[~]`, and any `Done:` line already
  written.
- Step ids. Nothing is renumbered, and nothing is deleted.
- The vocabulary. No new step marker and no new status value:
  `runbook-schema.md`'s four markers and four statuses stand unchanged.

## The gate

One gate for a strike or a context amendment: the runbook, the step (id,
marker, title), the operation with the exact lines to be written, the steps a
strike releases, and — on a `[RUNNING]` runbook — which step is current. End
with **"Apply?"** and wait for an explicit answer. Silence, an unclear reply
or EOF writes nothing.

An insert's gate is `/runbook-create`'s own confirmation gate; this file adds
none beside it.

## What is written

- **Strike** — in the body, the step's marker and its new `Done:` line; in
  the index, the block's `Steps:` done count, and `Status:` → `[DONE]` only
  when every step is now `[x]`.
- **Context** — in the body, the step's `Context:` lines only.
- **Insert** — exactly what `/runbook-create --append` writes, and nothing
  more.

Committing is the consumer's. When it commits, it stages exactly the runbook
and the index, by explicit path.

## The closing report line

```
Amended runbook <name>, step <id>: <struck — <reason> | +<n> context fact(s) | inserted step(s) <ids> <before|after> step <id>>.
```
