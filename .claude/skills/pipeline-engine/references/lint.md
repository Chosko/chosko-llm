# The drift catalogue

Authority for: every structural drift finding the pipeline reports — its
detection rule over `graph.md`'s edges, its severity, the one command that
fixes it and the line it prints as — and the two rules for a finding whose
index is absent or whose block cannot be read.

Authored here. `/pipeline-check` evaluates this catalogue, and any revision
surface that reports drift reads the same file, so a finding is defined once
and renders the same everywhere.

---

## What it detects

**Structural inconsistency only** — a reference between indexes that does not
resolve, or an index state its owner has not acted on. Whether a feature
document still describes what its tasks build is a judgement about meaning,
not structure: it is `/architect amend`'s precision guard, not this
catalogue's, and no finding here approximates it.

## What no rule reads

Every detection rule reads **index lines only** — `.claude/FEATURES.md`,
`.claude/TASKS.md`, `.claude/PLAN.md`, `.claude/RUNBOOKS.md` — through the
`graph.md` edge it names. **No rule opens a file under `.claude/tasks/`,
`.claude/runbooks/` or `.claude/domain/`.**

**No rule probes `.claude/tasks/archive/`, opens an archived file, or reports
on its contents.** The prohibition is stated once, here, and holds for the
whole catalogue and for any finding ever added to it: an archived task is
known to the lint only as an id absent from `TASKS.md`, which is all it needs
to be.

## Severity

Two levels, one discriminator:

- **`ERROR`** — a reference that cannot be resolved, or a state that will
  misdirect a run: something a pipeline command will act on wrongly if it is
  left.
- **`WARNING`** — a legal state that needs its owner's attention: nothing is
  broken, but someone has a step to take.

Every finding carries exactly one. The two are deliberately not
`/task-review`'s `BLOCKING` / `IMPORTANT` / `ADVISORY`, and deliberately clear
of every status vocabulary, so a grep for a status never returns a severity.

## The output line

Every finding prints as one line: the severity padded to seven characters,
then the artifact, then the offending identifier — always in those three
positions — then its message and its fix:

```
<SEVERITY> <artifact> <identifier> — <message> → <fix>
```

`<artifact>` is the index whose line the fix changes: `FEATURES.md`,
`PLAN.md`, `TASKS.md` or `RUNBOOKS.md`. `<identifier>` is `task <N>`,
`feature <slug>`, `runbook <id>. <name>`, or `header` for a line outside any
block. Each finding below carries its own template; the fix is printed
verbatim.

---

## The catalogue

Eleven findings, and no others. The catalogue is closed: adding a finding is
an edit to this file, so every consumer gains it at once and none can disagree
about whether it exists.

### L1 — a task's `Feature:` slug absent from `FEATURES.md` · ERROR

- **Walks.** E3b.
- **Needs.** `TASKS.md`, `FEATURES.md`.
- **Fires when** a summary block's `Feature: <slug>` names no entry in
  `FEATURES.md`.

```
ERROR   TASKS.md task <N> — Feature: <slug> names no feature in FEATURES.md → /pipeline-patch
```

### L2 — a task with no `Feature:` line · WARNING

- **Walks.** E3b, absent.
- **Needs.** `TASKS.md`, `FEATURES.md`.
- **Fires when** `FEATURES.md` exists and a summary block carries no
  `Feature:` line. A free-form task is legal; on a project that keeps a
  feature index, it is work no feature accounts for.

```
WARNING TASKS.md task <N> — no Feature: line on a project with FEATURES.md → /pipeline-patch
```

### L3 — a `Preconditions:` id that resolves to no task · ERROR

- **Walks.** E4.
- **Needs.** `TASKS.md`.
- **Fires when** an id on a `Preconditions:` line is greater than `Last task
  number:` — an id never assigned. An id at or below the counter with no
  block is archived and terminal by E4's resolution, a satisfied
  precondition, and is not a finding.

```
ERROR   TASKS.md task <N> — Preconditions: <id> was never assigned (Last task number: <K>) → /pipeline-patch
```

### L4 — a `Preconditions:` id naming a `[SKIP]` task · ERROR

- **Walks.** E4.
- **Needs.** `TASKS.md`.
- **Fires when** an id on a `Preconditions:` line resolves to a block whose
  `Status:` is `[SKIP]`. `[SKIP]` satisfies a precondition, so the dependent
  becomes eligible on work that was abandoned rather than done.

```
ERROR   TASKS.md task <N> — Preconditions: <id> is [SKIP] → /pipeline-patch
```

### L5 — a precondition cycle · ERROR

- **Walks.** E4, over live blocks only — an archived id is terminal and closes
  no loop.
- **Needs.** `TASKS.md`.
- **Fires when** following `Preconditions:` from a task leads back to it — a
  cycle in the sense
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
  § *Eligibility* gives it. Each cycle is reported once, on whichever of its
  tasks appears first in `TASKS.md`.

```
ERROR   TASKS.md task <N> — precondition cycle <N> → <M> → … → <N> → /pipeline-revise
```

### L6 — an `[ITERATED]` feature · WARNING

- **Walks.** E3a — the feature's `Tasks:` are what re-planning reconciles.
- **Needs.** `FEATURES.md`.
- **Fires when** an entry's `Status:` is `[ITERATED]`: re-architected, and the
  backlog not yet re-planned against the new design.

```
WARNING FEATURES.md feature <slug> — [ITERATED]: re-architected, backlog not re-planned → /task-add feature=<slug>
```

### L7 — a `[STALE]` task · WARNING

- **Walks.** E3b, to name the feature in the message.
- **Needs.** `TASKS.md`.
- **Fires when** a summary block's `Status:` is `[STALE]`. What the tag means
  is `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/stale.md`.
  With no `Feature:` line, the message says the originating feature is
  unrecorded.

```
WARNING TASKS.md task <N> — [STALE]: feature <slug> was re-architected after this task was written → /pipeline-revise
```

### L8 — a `FEATURES.md` slug absent from `PLAN.md` · WARNING

- **Walks.** E5, from the feature's side.
- **Needs.** `FEATURES.md`, `PLAN.md`.
- **Fires when** an entry's slug is in no milestone's `Features:` and not in
  `## Unscheduled`'s. `Unscheduled` is a placement, not an absence; a
  `## Dependencies` line places nothing, so a slug named only there is still
  absent from the plan.

```
WARNING PLAN.md feature <slug> — in FEATURES.md, nowhere in PLAN.md → /production-plan
```

### L9 — a plan edge naming an unknown slug · ERROR

- **Walks.** E5.
- **Needs.** `FEATURES.md`, `PLAN.md`.
- **Fires when** a slug on any line E5 names — a milestone's or
  `Unscheduled`'s `Features:`, either side of a `## Dependencies` line — has
  no entry in `FEATURES.md`. One finding per unknown slug per line.

```
ERROR   PLAN.md feature <slug> — named by <milestone-slug> Features: | Unscheduled | Dependencies (<dependent>) but not in FEATURES.md → /pipeline-patch
```

Print exactly one of the three `named by` forms: the line that carries the
slug.

### L10 — a `[PENDING]` runbook whose every step is done · WARNING

- **Walks.** E6, from the index side.
- **Needs.** `RUNBOOKS.md`.
- **Fires when** an index block carries `Status: [PENDING]` together with
  `Steps: <n>/<n>` — done equal to total. **Derived from `RUNBOOKS.md` alone:**
  `Steps:` counts `[x]` steps only
  (`${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`
  § *The index block*), so `<n>/<n>` says every step is done while
  `[PENDING]` says the runbook is still waiting to run. The block contradicts
  itself, and neither half needs the body to see it.

```
WARNING RUNBOOKS.md runbook <id>. <name> — [PENDING] with Steps: <n>/<n> → /pipeline-patch
```

### L11 — a fully resolved `[PLANNED]` feature · WARNING

- **Walks.** E3a.
- **Needs.** `FEATURES.md`, `TASKS.md`.
- **Fires when** an entry's `Status:` is `[PLANNED]` and every id on its
  `Tasks:` line is `[DONE]`, `[SKIP]`, **or absent from `TASKS.md`**. An
  absent id is archived and terminal by E3a's resolution and counts as
  resolved; without that clause a cleaned feature would never be reported as
  ready to flip. `Tasks: none` satisfies it trivially.

```
WARNING FEATURES.md feature <slug> — [PLANNED], every task on Tasks: resolved → flip to [DONE]
```

---

## Two deliberate absences

Both were considered and are not findings. They are recorded so a later
reader neither concludes they were forgotten nor adds them back.

**"A feature's `Tasks:` id absent from `TASKS.md`" is not a finding.**
`/task-clean` moves a pruned body to `.claude/tasks/archive/<N>.md` and leaves
the feature's `Tasks:` line intact, so that absence is the normal state of a
cleaned feature and means **archived, terminal** — the rule is
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
§ *The archive*. Reporting it would flag every cleaned feature on the first
run against an archived backlog.

**"A pending runbook step naming a task already `[DONE]` or `[SKIP]`" is not a
finding.** Detecting it means reading a step's prompt block, which means
opening a runbook body — which no rule here does, and which is why `graph.md`
E7 has no step-level index form. `/runbook-run` surfaces the same problem at
the moment it matters: it prints each step before spawning it. A
`RUNBOOKS.md` that carried per-step targets is what would make a cheap
index-only version possible; until it does, the finding stays out.

---

## Failure rules

**An absent index drops its findings.** A finding whose **Needs** names an
index the project does not have is not evaluated and not reported — dropped
from the run, never an error. A project with no `PLAN.md` has no plan
findings; that is not drift.

**A malformed block is a finding of its own, never an abort.** A block missing
a line some finding reads, or carrying a value outside that line's vocabulary
— a `Status:` no status list contains, a `Steps:` that is not
`<done>/<total>`, a `Preconditions:` or `Tasks:` that is neither `none` nor a
list of ids — is reported, and the run carries on:

```
ERROR   <artifact> <identifier> — malformed: <the line missing or unreadable> → /pipeline-patch
```

It is `ERROR` because a block that cannot be read will misdirect any command
that acts on it. Its own findings are skipped for the run; as the far end of
another block's edge it still exists. It is not a twelfth catalogue entry: it
reports an index that cannot be read, not drift between indexes.
