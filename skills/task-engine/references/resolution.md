# Backlog resolution

Authority for: where the backlog lives, what a summary block holds, when a
per-task body file may be opened, and how a run resolves which tasks it
operates on.

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
  the order given.
- The literal token `all` (case-insensitive) — implement every task in the
  backlog whose current status is `[MISSING]`, `[STUBBED]`, `[INCORRECT]`,
  or `[PARTIAL]`, in the order they appear in the file. Skip tasks whose
  status is `[DONE]`, `[SKIP]`, `[IN PROGRESS]`, or `[STALE]`. After
  resolving the list, report it to the user as a one-line summary ("Will
  implement: 3, 7, 12 (5 tasks skipped: 1 DONE, 1 IN PROGRESS, 3 SKIP)")
  and proceed without asking for confirmation — the user already chose
  `all`.
- The literal token `next` (case-insensitive) — find the first task in the
  backlog (by appearance order in TASKS.md) whose status is `[MISSING]`,
  `[STUBBED]`, `[INCORRECT]`, or `[PARTIAL]`, and implement that single
  task. Skip tasks whose status is `[DONE]`, `[SKIP]`, `[IN PROGRESS]`, or
  `[STALE]`. If no eligible task is found, tell the user "No eligible
  tasks found — all tasks are DONE, SKIP, IN PROGRESS, or STALE." and
  stop. Otherwise, report "Next eligible task: <N> — <title>" and proceed
  without asking for confirmation.

If the argument is empty, tell the user the usage and stop.

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
  argument form; it is the only consumer that has them.
- **`/task-add`** — resolves nothing from the index but the next ID and, on
  a `feature=<slug>` run, the tasks that feature already generated. Its
  setup check is the two-artifact probe quoted above rather than the
  index-only check the other three make, and its pull-at-start sits in the
  same PHASE 0 — see `commit.md`.
