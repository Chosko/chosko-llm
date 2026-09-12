# The index graph

Authority for: how the pipeline's indexes point at each other — each edge by
the artifact and the exact line it lives on, its direction, which side is
authoritative when the two disagree, which command writes each side and what
consumes it — and which edges do not exist on a project missing an index.

Authored here. The graph is how the indexes **point**, and nothing else: it
restates no index's schema. Where a schema has an owner, the owner is cited
and this file adds the edge alone.

---

## Index-only by construction

Every edge below is read off an index line — `.claude/FEATURES.md`,
`.claude/TASKS.md`, `.claude/PLAN.md` or `.claude/RUNBOOKS.md`. **No edge
requires opening a task body, an archived body, a feature document, a runbook
body or a design document.** A consumer that opens one does so for its own
reasons — to amend it, to show it, to check what an index cannot say — never
to traverse the graph. An edge whose only complete form would need a body is
recorded with the index-side form it has, or with none, and says which.

That is what keeps the cost of walking the graph bounded by the number of
indexes rather than by the size of the backlog.

**No edge probes `.claude/tasks/archive/`, and traversing the graph never
requires it.** An id absent from `TASKS.md` resolves to "archived, terminal"
from the absence itself; no reader checks whether the archived file is there.

## Where the schemas live

- `TASKS.md`'s summary block and `Last task number:` —
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
  § *Index file format*; the archive and the archived-and-terminal rule — the
  same file, § *The archive*.
- `RUNBOOKS.md`'s index block, the runbook body and the `Steps:` counter —
  `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`.
- `PLAN.md` — `/production-status`'s body, § *READING THE INPUTS*, which
  parses it and never rewrites it.
- A `FEATURES.md` entry — `/architect`'s, which writes it.

Each citation names the schema's home. The lines an edge reads are named with
the edge, so reading one never requires opening a cited file.

Which command owns each line an edge lives on is `routing.md`'s. The writers
named per edge here are those owners, named so a walk can say who fixes what
it finds; were the two files ever to disagree, `routing.md` is the ownership
authority.

## Nodes

A node is identified by the index line that heads it:

| Node | Identified by |
| --- | --- |
| feature | `## <slug> — <title>` in `FEATURES.md` |
| task | `## <N>. <title>` in `TASKS.md` |
| milestone | `## <milestone-slug> — <title>` in `PLAN.md` |
| runbook | `## <id>. <name> — <title>` in `RUNBOOKS.md` |

A design section, a roadmap milestone, a feature document, a task body and a
runbook body are the far ends of edges: each is **named** by the index line
that points at it, never opened by the edge.

---

## The edges

### E1 — `FEATURES.md` `Source:` → design section, and milestone

- **Line.** `Source: product-design.md § <Section>`, with an optional
  ` (<milestone-slug>)` suffix, or the literal `Source: prompt`.
- **Direction.** Feature → the design section it was architected from, and —
  when the suffix is present — → the roadmap milestone whose scope slice it
  came from. `Source: prompt` points nowhere.
- **Authoritative.** The design and the roadmap: they are what the feature was
  derived from, so a `Source:` naming a section or milestone that no longer
  exists is stale on the feature's side.
- **Writers.** `/architect` writes `Source:`; `/product-design` writes the
  section; `/product-roadmap` writes the milestone.
- **Resolves by name.** The section and the milestone slug are read off the
  line. Checking that either still exists would open a design document, which
  no edge does.
- **Consumed by.** The impact walk: a changed design section reaches every
  feature whose `Source:` names it; a changed milestone reaches every feature
  whose suffix carries its slug.

### E2 — `FEATURES.md` `Doc:` → feature document

- **Line.** `Doc: <path>`, conventionally `.claude/domain/features/<slug>.md`.
- **Direction.** Feature → its document.
- **Authoritative.** The entry: the document is wherever `Doc:` says.
- **Writers.** `/architect`, on both sides.
- **Consumed by.** The impact walk: a changed feature reaches its document —
  the material its owner amends. The walk names the path and opens nothing.

### E3 — `FEATURES.md` `Tasks:` ↔ `TASKS.md` `Feature:`

One link carried on two lines, stated per direction because the two
directions resolve an absence differently.

**When the two sides disagree** about a live task — its `Feature:` names a
feature whose `Tasks:` does not list it, or the reverse — `Feature:` is
authoritative: it sits on the task itself. `Tasks:` is authoritative only for
ids that no longer have a block, which it alone still names.

**E3a — `Tasks:` → task ids.**

- **Line.** `Tasks: <id>, <id>, …` or `Tasks: none`.
- **Direction.** Feature → every task it generated.
- **Resolution.** **An id on a `Tasks:` line with no summary block in
  `TASKS.md` is archived and terminal, not dangling.** The rule's authority is
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
  § *The archive*. What this edge does with it: such an id resolves to a
  terminal task without anything being read, is never reported, and counts as
  resolved wherever an edge asks whether a feature's work is finished. A
  cleaned feature keeps every id it ever generated on this line, so the
  absence is its normal state.
- **Writers.** `/task-add` writes `Tasks:`; `/task-clean --backfill` restores
  archived ids to it.
- **Consumed by.** `lint.md` L6 and L11. The impact walk: a changed feature
  reaches its live tasks — the ids that do have a block.

**E3b — `Feature:` → feature slug.**

- **Line.** `Feature: <slug>` on a summary block — present only on
  feature-derived tasks.
- **Direction.** Task → the feature it came from.
- **Resolution.** A slug with no entry in `FEATURES.md` is a **real
  inconsistency**. Nothing archives a feature slug — a slug is never renamed,
  reused or pruned — so its absence carries no meaning but drift.
- **Writers.** `/task-add` writes `Feature:`; `/architect` writes the entry it
  resolves to.
- **Consumed by.** `lint.md` L1, L2 and L7. The impact walk: a changed task
  reaches its feature.

### E4 — `TASKS.md` `Preconditions:` → task ids

- **Line.** `Preconditions: <id>, <id>, …` or `Preconditions: none`.
- **Direction.** Dependent task → each task it waits on.
- **Resolution.** An id with a block resolves to that task. An id with no
  block resolves by the archive rule
  (`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
  § *The archive*) to archived and terminal — a satisfied precondition — when
  it is at or below `Last task number:`. An id **above** the counter was never
  assigned, so it was never archived either: it resolves to nothing, and is
  the one unresolvable reference this edge can carry.
- **Authoritative.** The dependent's line: it is the dependency.
- **Writers.** `/task-add` writes it, including the anchor task's line under
  `--before`; `/task-clean` drops pruned ids from survivors' lines.
- **Consumed by.** `lint.md` L3, L4 and L5. The impact walk: a changed task
  reaches every task that waits on it.

### E5 — `PLAN.md` slug references → `FEATURES.md` slugs

- **Lines.** Each milestone block's `Features:` list, the `## Unscheduled`
  block's `Features:` list, and each line of the flat `## Dependencies` list,
  `- <slug>: depends on <slug>, <slug>`.
- **Direction.** Plan → feature. A `Features:` entry places a feature in a
  milestone or in `Unscheduled`; a dependency line points a feature at the
  features it depends on.
- **Authoritative.** `FEATURES.md` for which slugs exist; `PLAN.md` for
  membership, order and dependencies.
- **Writers.** `/production-plan` writes every `PLAN.md` line; `/architect`
  writes the entries the slugs resolve to.
- **Consumed by.** `lint.md` L8 and L9 — a "plan edge" there is any of these
  lines. The impact walk: a changed feature reaches the milestone listing it
  and every feature whose dependency line names it.

### E6 — `RUNBOOKS.md` `File:` → runbook body

- **Line.** `File: .claude/runbooks/<name>.md` on an index block.
- **Direction.** Index block → the body it summarises.
- **Authoritative.** The body: the index is its summary, derivable from it but
  for the id and its counter (`runbook-schema.md` § *The index block*).
- **Writers.** `/runbook-create` writes the block and the body;
  `/runbook-run` advances both; `/runbook-clean` removes both.
- **Read from the index side.** `Status:` and `Steps:` on the same block
  summarise the body `File:` points at, so a question they answer is answered
  without following the edge.
- **Consumed by.** `lint.md` L10, which reads that summary instead of the
  body. The impact walk: the path a consumer follows when it decides to open a
  candidate runbook E7 named.

### E7 — runbook step → task ids and feature slugs

- **Where it lives.** Inside a step's prompt block, in the body — a step
  written as `/task-implement <n>` or `/task-add feature=<slug>`. The runbook
  schema has no field for it.
- **Index-side form.** **None at step granularity.** `RUNBOOKS.md` carries no
  per-step targets, so the graph cannot say which step names which task
  without opening a body, which it does not do. What the index does carry is
  which runbooks still have steps to run — a block whose `Status:` is not
  `[DONE]` — and that is the whole of this edge as the graph reads it: an open
  runbook **may** name any task or feature.
- **Authoritative.** The body.
- **Writers.** `/runbook-create`, the only writer of a prompt block.
- **Consumed by.** The impact walk: a changed task or feature reaches every
  open runbook, as a candidate the walk names but cannot confirm. Finding the
  step itself is the consumer's decision to open the body through E6.

---

## When an index is absent

An edge exists only when the index it lives on exists. A missing index removes
its edges and every finding that walks them, and the consumer degrades rather
than failing — the contract `/production-status` already keeps.

| Index absent | Edges gone |
| --- | --- |
| `FEATURES.md` | E1, E2, E3a; E3b and E5 lose the side they resolve against. |
| `TASKS.md` | E3b, E4; E3a loses the side it resolves against. |
| `PLAN.md` | E5. |
| `RUNBOOKS.md` | E6, E7. |

An edge that has lost the side it resolves against is not evaluated at all:
with no `FEATURES.md`, a `Feature:` slug is neither known nor unknown, and
treating it as unknown would report every feature-derived task as drift. With
no `TASKS.md`, every `Tasks:` id would otherwise read as archived.

A missing roadmap or design document removes nothing: E1 names its far end
and never resolves it.
