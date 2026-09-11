# Backlog resolution

Authority for: where the backlog lives, what a summary block holds, when a
per-task body file may be opened, how a run resolves which tasks it
operates on, and the eligibility clause — status plus `Preconditions:` —
that the batch selectors honour.

Extracted verbatim from the `LOCATING THE BACKLOG` sections of
`/task-list`, `/task-clean` and `/task-implement`, from `/task-add`'s
`PHASE 0 — SETUP CHECK` and `INDEX FILE FORMAT`, and from
`/task-implement`'s `ARGUMENT PARSING` selectors.

---

## Where the backlog lives

The backlog index lives at `.claude/TASKS.md`. Per-task body content
lives at `.claude/tasks/<N>.md` — one file per task ID.

## Index file format (`.claude/TASKS.md`)

```
# Tasks

Last task number: <N>

---

## <N>. <Title>

Status: [MISSING]
Target: claude
Files: <comma-separated list>
Preconditions: <comma-separated task numbers, or "none">
Feature: <slug>          ← optional; only on feature-derived tasks

---
```

The summary block holds: number, title, Status, Target, Files,
Preconditions, and — only when the task was generated from a feature
document — `Feature:`. Nothing else. Description and decisions live in the
body.

`Feature:` carries the slug of the feature the task came from. It is
present ONLY on feature-derived tasks and is absent entirely on free-form
ones — do not write `Feature: none`. Like `Status:` and `Preconditions:`,
it is backlog metadata, so it lives in the summary block and never in the
body file.

`Last task number: N` tracks the highest ID ever assigned, not the highest
currently present, and only ever increases. Task IDs are stable: survivors
of a prune are never renumbered and a pruned ID is never reused.

Appearance order in the file is the backlog's order, and it need not be
numeric. `/task-add --before <N>` / `--after <N>` write a new block mid-file
under the next ID from the counter, exactly as an append would, so a higher
ID may sit above a lower one. No existing ID ever moves or changes. Read
order from position, never from the number.

## When the backlog is not initialised

If `.claude/TASKS.md` does not exist, tell the user so, name `/task-setup`,
and stop. Do NOT create anything — no index file, no `.claude/tasks/`
directory.

`/task-add` probes for both required artifacts rather than just the index:

> **PHASE 0 — SETUP CHECK (must pass before anything else)**
>
> Before reading anything else, verify the backlog has been initialized.
> The required artifacts are:
> 1. `.claude/TASKS.md` — the index file.
> 2. `.claude/tasks/` — the per-task body directory.
>
> Probe with the Read tool / Glob. If either is missing, stop:
>
> > The task backlog hasn't been initialized in this project. Run
> > `/task-setup` first — it creates `.claude/TASKS.md` and the
> > `.claude/tasks/` directory. Then re-run `/task-add`.
>
> Do not proceed to PHASE 1. This rule has no exceptions.

## Parsing the index

Read `.claude/TASKS.md` with the Read tool and parse:

- The `Last task number: N` header value.
- Each summary block. Extract:
  - Number (from the `## N. Title` line)
  - Title (the text after `N.`)
  - Status (the value on the `Status:` line, including its brackets)
  - Target (the value on the `Target:` line; treat a missing line
    as `claude`)
  - Preconditions (the value on the `Preconditions:` line)
  - Feature (the value on the `Feature:` line, when the block has
    one; feature-derived tasks only, so a missing line is normal
    and means "free-form task")

`Files:` is on the summary block too, and is read by the features that need
it.

## Opening a per-task body file

Read TASKS.md first to find the summary block for each requested task
(number, title, Status, Files, Preconditions). For each task you are
about to implement, read its `.claude/tasks/<N>.md` body file when you
need its spec — not before. Do NOT bulk-read every body file up front:
open each one only at the moment its task becomes the current one. If the
body file for a task you intend to implement is missing, stop and report
— the task is corrupt and the user should investigate.

## Where a status flip is written

Status flips happen in `.claude/TASKS.md` only — the per-task body
file does not store Status, Files, or Preconditions, so do not edit
the body file when changing status.

## Selectors

A run's task list resolves from its argument to one of:

- A whitespace-separated list of task numbers — implement those tasks in
  the order given. Explicit-list selection is unchanged by the eligibility
  clause below: **a task requested by number is never blocked by a
  precondition.** The user who names a task has already chosen its moment;
  the clause governs only the two batch selectors.
- The literal token `next` (case-insensitive) — the first task in the
  backlog, by appearance order in TASKS.md, that is **eligible** (below);
  implement that single task. Report "Next eligible task: <N> — <title>" and
  proceed without asking for confirmation. If no task is eligible, stop
  with whichever of these is true:
  - no implementable task exists at all — "No eligible tasks found — all
    tasks are DONE, SKIP, IN PROGRESS, or STALE.";
  - implementable tasks exist, but every one of them is blocked — "No
    eligible tasks found — every implementable task is waiting on an unmet
    precondition: 14 (waits on 12), 15 (waits on 14)." Name every blocked
    task by id with the ids it waits on; never claim the backlog is
    finished when the only reason nothing is eligible is an unmet
    precondition.
- The literal token `all` (case-insensitive) — `next` applied repeatedly
  until no task is eligible, which keeps a batch from starting a task ahead
  of one it waits on without a second definition of eligibility. It is
  resolved **once, up front**, by simulating that repetition rather than
  re-resolving after every task: walk the backlog from the top and select
  the first eligible task not yet selected; from then on treat it as
  `[DONE]`, so it satisfies every precondition that names it and is never
  selected again; walk again from the top; stop when a walk selects
  nothing. The selections, in the order made, are the run's fixed list — the
  same list repeated `next` would yield — so the run still gets one
  resolution report and one delegation count. Report it as a one-line
  summary ("Will implement: 3, 7, 12 (5 tasks skipped: 1 DONE, 1 IN
  PROGRESS, 3 SKIP)") and proceed without asking for confirmation — the
  user already chose `all`. If the list comes out empty, stop with the same
  message `next` would give.

### Eligibility

A task is **eligible** only when both hold:

1. its status is implementable — `[MISSING]`, `[STUBBED]`, `[INCORRECT]` or
   `[PARTIAL]`. Tasks whose status is `[DONE]`, `[SKIP]`, `[IN PROGRESS]` or
   `[STALE]` are skipped by both batch selectors;
2. every id on its `Preconditions:` line resolves to a task whose status is
   `[DONE]` or `[SKIP]`. `Preconditions: none` satisfies this trivially. An
   id that resolves to no summary block in TASKS.md is ignored, never a
   blocker — the same tolerance the suite already extends to a hand-edited
   or pruned backlog wherever an id resolves to nothing.

An implementable task that fails clause 2 is **blocked**. Eligibility is
derived on every read and stored nowhere; `Preconditions:` keeps its shape
and becomes load-bearing rather than informational.

**The blocked report.** The `all` resolution report names, by id, every
implementable task left unselected because a precondition is unmet, each
with the ids it waits on — "Blocked by unmet preconditions: 14 (waits on
12), 21 (waits on 20)." — so an unsatisfiable edge is visible rather than
silently skipped. Omit the line when nothing is blocked.

**A precondition cycle** — 20 waits on 21, 21 waits on 20, or any longer
loop — makes every task on it ineligible, and every task waiting on one of
them as well: none of them can ever satisfy clause 2. The resolution still
terminates, because each walk either selects a task not selected before or
ends the resolution, and the tasks are finite. The cycle's tasks appear in
the blocked report like any other blocked task, each naming the ids it
waits on, which is what lets a reader see the loop.

`[STALE]` tasks are skipped by `all` and `next` because each one needs a
per-task judgment call and a batch run should not stop to ask — see
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/stale.md`.
When the resolved list skips any, name them: "Skipped N stale task(s): 12,
14 — implement them explicitly by number to decide each one." A stale task
requested explicitly by number is not skipped.

For `all` and `next`, after resolving the list, check each resolved task's
`Target:` field in its TASKS.md summary block and warn when the run will
need the user present — see
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/targets.md`.

Which statuses a resolved task may carry, and what to do when an explicitly
requested task carries another one, is
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/status.md`.

---

## Per-consumer notes

- **`/task-list`** — the not-initialised message is "No backlog file found.
  Run /task-setup to initialize it, then /task-add to create the first
  task." It performs no writes and needs no shell at all, and it must NOT
  open any file under `.claude/tasks/` — TASKS.md already contains
  everything `/task-list` needs. It takes no selector; its argument is a
  status filter (see `status.md`). When `.claude/PLAN.md` exists it also
  reads `.claude/PLAN.md` and `.claude/FEATURES.md`, read-only, for
  milestone grouping — that resolution is `/task-list`'s own and is not
  part of this file.
- **`/task-clean`** — the not-initialised message is "No backlog file found
  — run /task-setup to initialize it." It parses number, title, status,
  `Files:` and `Preconditions:` from each summary block, and it opens a
  per-task body file only to probe whether it exists before planning its
  deletion: "Probe each path with the Read tool first; if a body file is
  unexpectedly missing, note that in the plan but do not error out." Its
  argument is a status set, not a selector (see `status.md`). It also
  pulls at start before PHASE 1 — see `commit.md`.
- **`/task-implement`** — the not-initialised message is "No backlog file
  found — run /task-setup to initialize it, then /task-add to create
  tasks." The `all` / `next` / explicit-list selectors above are its
  argument form; it is the only consumer that has them. Its one departure
  is a re-check: between tasks of an `all` run it re-reads TASKS.md anyway,
  and there it re-checks the upcoming task's `Preconditions:` against clause
  2 of *Eligibility*, skipping with a one-line report a task whose
  preconditions no longer hold. It reads nothing new to do it.
- **`/task-add`** — resolves nothing from the index but the next ID, the
  task a `--before <N>` / `--after <N>` flag names and, on a
  `feature=<slug>` run, the tasks that feature already generated. Its
  setup check is the two-artifact probe quoted above rather than the
  index-only check the other three make, and its pull-at-start sits in the
  same PHASE 0 — see `commit.md`.
