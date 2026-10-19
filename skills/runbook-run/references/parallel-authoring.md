# Authoring a parallel runbook

Read by `/runbook-create` only for a parallel runbook, on one of three
signals: the user asked for one — by saying so, or by naming a parallelism
("three at a time", "max"); the run appends to a runbook whose header already
carries `Parallelism:`, whether or not the user says so again; or the
project's `CLAUDE.md` carries a `Parallel policy:` line other than `off` and
the user did not ask for a sequential runbook. Never infer it from the shape
of the work. A runbook with no `Parallelism:` line is authored without this
file.

Read `./parallel-schema.md` beside it: under a parallelism above one,
`Depends on:` is the **only** ordering constraint, and a step with no edge to
another is independent of it by the runbook's own declaration. An edge left
to omission is exactly what a parallel run violates silently, so this file
adds one duty to each phase.

## The value

Write the value the user named; else the `Parallel policy:` line's value;
else propose `max` at the gate, where the user sets it. Write `Parallelism:`
where `./parallel-schema.md` § *The header line* puts it, on a new runbook
only — never on an append, never beside `Sequencing:`.

## PHASE 2 — every ordering constraint is an edge

- Ask "which steps must precede which, and why" **exhaustively**: for every
  pair of steps the author might order — two that edit one file, one that
  reads what another writes, a review of an implementation — write an edge
  or declare the two independent. Leave nothing to position.
  - From scratch: question 3, put pair by pair.
  - From the conversation: harvest the edges it settled, and put the pairs
    it left open to the user in one batch before the gate, each with a
    recommended answer — the one interview question conversation mode asks.
  - On an append: the pairs include every existing step the new ones might
    order against. An existing step's `Depends on:` is never rewritten, so
    decline an edge from an existing step to a new one with one line: the new
    step sits above it, or the constraint goes through `/pipeline-revise`.
- Write a sequencing note the user offers — "1–4 all edit the same file" — as
  edges (`4` on `3`, `3` on `2`, `2` on `1`), never as `Sequencing:`, and say
  so in one line. Rule 4's "states its sequencing and why" is met inside the
  prompt and by the edge.

## PHASE 4 — the gate approves the graph

Show the line `Parallelism: <N|max>` in the header block, and beneath the
step list one statement:

```
  Every step without an edge is independent of every step not reachable
  from it: 2 and 3 may run at once.
```

Approval is the author's declaration of every independence the statement
names, so a pair the user would have ordered is corrected here, as an edge,
before anything is written. On an append the statement covers the new steps
against every step in the runbook.
