# Features: runbook readers

## Overview

Covers the runbook suite's read side: `commands/runbook-list.md` and
`commands/runbook-describe.md`. The family hub:
[runbook-suite.md](./runbook-suite.md).

- `commands/runbook-list.md` — read side. `requires: skill:runbook-run`, for
  vocabulary rather than parsing: the status set and index block shape are
  specified once in `runbook-schema.md`. One pass over `.claude/RUNBOOKS.md`,
  never opens a body under `.claude/runbooks/` — same discipline as
  `/task-list`'s never opening `.claude/tasks/`, and what keeps cost flat in the
  number of runbooks rather than their size (it is why the index carries
  `Steps:` at all). Prints `<id>. [STATUS] <name> <done>/<total> <created>
  <source> <title>` — the id leads so it can be typed at any other
  runbook command, the one-line title closes so the listing is answerable
  without opening anything; an id-less block prints `-` and is **left alone**,
  the backfill belonging to a command that writes the index. `Failed at:`
  printed as a continuation line under `[FAILED]` rows only; a block's
  `Parked:` line printed the same way, `↳ parked: steps <ids>`, whatever the
  status, after `Failed at:` when both are present — the reason the index
  carries `Parked:` at all. Optional status filter matched without brackets, case-insensitively
  (`/task-list`'s convention); unknown status names the four valid ones rather
  than printing nothing. Missing/empty index is not an error. **Writes nothing**,
  runs no shell, corrects no status, `Failed at:` or `Parked:` line however
  wrong it looks.
- `commands/runbook-describe.md` — the compact one-runbook summary, and the
  deliberate pair to `/runbook-list`. `requires: skill:runbook-run` for the
  schema. Takes one runbook as `<id|name|id-name>` (the schema's resolution
  rule), extracts from the body at its block's `File:` path (a `File:` that
  does not resolve is reported; never migrates), and renders a fixed shape: the
  index heading line (`Failed at:` continuation for `[FAILED]` only, and a
  `↳ parked: steps <ids>` continuation for a block carrying `Parked:`, after
  `Failed at:` when both), one header
  line (`Created:`/`Source:`/`Model:` — no `Sequencing:`, `Companion:`,
  `Last step number:` or
  re-propose count), an `Archived: <ids>   (pruned; counted as done)` line
  directly under it **only when the body carries an `Archive:` line** (absent
  renders nothing),
  one line per step (marker as the body carries it, `[P]` included — printed
  with nothing of its `Context:`, the question staying in the body; `deps:`
  only when non-empty and printed verbatim even when it names an archived id —
  never annotated or cross-referenced against `Archived:`, `needs:` only for an
  authored non-`agent` value), at most
  one `done:` line per step (sha(s) + short summary, wrong premises as a count,
  `[!]` opens `FAILED —`), no `Context:` text, then a by-marker count **that
  counts every archived id as done and as present** (schema § *An archived id
  counts as `[x]`*, so the count agrees with the heading line's progress
  figure; `[P]` named "parked"; a fully-pruned body renders heading + header +
  `Archived:` + count,
  not an error) and the
  "need a person present" line. **Read budget (THE READ BUDGET section):** the
  index plus Grep line extraction from exactly one body — header fields
  (`Created:`, `Source:`, `Model:`, `Archive:`), step
  headings, `Depends on:`, `Needs:`, first line of `Done:`, prompt fences only
  to discard matches inside them. Never a full Read of the body, never prompt
  text, never `.claude/tasks/` (archive included), `.claude/domain/`,
  `.claude/context/` or another body; task ids in `Done:` printed as written.
  Malformed body reported as found, never compensated by reading more. No
  `Needs:` inference. Writes nothing, runs no shell,
  corrects no status, count, marker, `Failed at:` or `Parked:` line however
  wrong the index looks — deriving the count from
  the body's steps *and* its `Archive:` line is derivation, not
  reconciliation; a disagreeing index `Steps:` is reported in prose only.

## Public API

- [runbook-suite.md](./runbook-suite.md) § Public API.

## Internal patterns

- [runbook-suite.md](./runbook-suite.md) § Internal patterns.

## Domain dependencies

- [runbook-suite.md](./runbook-suite.md) § Domain dependencies.

## Cross-references

- [runbook-suite.md](./runbook-suite.md) — the runbook suite's hub, and its
  family-wide cross-references.
- [runbook-run.md](./runbook-run.md) — the schema both commands cite.

## When to read the source

- [runbook-suite.md](./runbook-suite.md) § When to read the source.
