# Task implement launcher

A change to `/task-implement`'s batch mode. The parent session stops
orchestrating its subagents and becomes a launcher: it resolves the task list,
reads only the three fields the delegation guard needs, and hands each agent a
fixed-size prompt. The agents gather their own context, exactly as they would if
the user had invoked `/task-implement <n>` by hand.

## Purpose

Batch mode today has the parent read each task body and compose an accurate
hand-off prompt per agent. The result works, and it costs the thing the whole
delegation exists to save: the parent's context grows with every task in the
run, so a ten-task batch ends with a parent holding ten task bodies it will
never use again. The agents then re-read much of the same material anyway.

The parent needs to know three things about a task to decide whether it may be
delegated at all. It does not need to know what the task says. Reading the body
to write a prompt about the body is work the agent is about to do properly, from
a clean context, with the full navigation layer available to it.

## Scope and non-goals

In scope: what the parent reads, what the hand-off prompt contains, what the
agent does on arrival, and what the parent accumulates on return.

Deliberately out:

- **Single-task runs.** `/task-implement 12` runs in the conversation and is
  untouched. There is no agent, no hand-off, nothing to shrink.
- **Parallel agents.** Agents still run one at a time, in order. The existing
  prohibition stands and is unrelated to this change.
- **Changing the delegation guard.** `human`, `claude+human` and explicitly
  requested `[STALE]` tasks still stay in the parent conversation because they
  need the user present. Only the *cost of evaluating* the guard changes.
- **Changing what a task run does.** Steps 1–7 are identical. This is a change
  to who reads what, not to the implementation flow.
- **Removing the parent's summary duties.** Feature-completion proposals,
  batched to the end of the run, still happen in the parent.

## Architecture

### What the parent reads

Resolution first, unchanged: `TASKS.md` supplies the candidate list for `all`,
`next`, or an explicit set of numbers, along with each task's status.

Then, per candidate, the parent needs exactly three fields — and every one of
them is already in the summary block `TASKS.md` gave it, so it reads nothing
further:

| Field | Needed for |
|---|---|
| `Target:` | the delegation guard — `human` / `claude+human` stay in the parent |
| `Status:` | eligibility; skip anything already terminal, and `[STALE]` detection |
| `Feature:` | the end-of-run feature-completion check |

`[STALE]` is a `TASKS.md` status, written there by `/architect`, so staleness is
read straight off the same summary block — no join against `FEATURES.md` is
needed for it. `FEATURES.md` is still read once per run, for the
feature-completion proposal this feature does not change. That is one file for
the whole run, not one per task, so it does not scale with batch size.

**The parent never opens a task body.** One `TASKS.md` read and one
`FEATURES.md` read are the entire budget. Anything the parent later discovers it
needs, it does not get; it belongs in the agent.

### The hand-off prompt

Fixed size, independent of the task. It carries the task number, the resolved
flags for the run, and the instruction to proceed as if invoked directly:

```
Implement task <n> from this project's backlog using /task-implement.
Flags for this run: <resolved flag list>.
Read the task body, CLAUDE.md, and .claude/context/ yourself — you have not
been given them. Report back only: task number, terminal status, commit hash
if you committed, and a one-line failure reason if you did not.
```

The prompt is O(1) in the number of tasks and O(1) in task size. A fifty-task
batch composes the same prompt fifty times with a different number in it.

This works because the agent is not context-starved — it has the same project
it would have had if the user typed the command, including the two navigation
layers this repo exists to maintain. `.claude/context/` is precisely the
precomputed answer to "what do I need to read", and handing an agent a
pre-chewed summary instead is paying for that layer twice.

### What the agent does

Exactly what a manual `/task-implement <n>` does. It reads its own task body,
resolves its own context, runs Steps 1–7, commits and pushes per the run's
flags. No special batch-agent path exists, which is itself the point: the
delegated flow and the manual flow stop being two things that can drift apart.

### What the parent accumulates

Per returned agent: task number, terminal status, commit hash, and a one-line
failure reason if it failed. Nothing else. The parent's context after a
fifty-task run is fifty short rows.

Failure handling is unchanged: a failed agent stops the run without spawning
the next, and the parent reports which tasks completed with hashes, which failed
and what the agent said, and which were never attempted.

### Interaction with `--review`

`--review` and `--rounds` are part of the resolved flag list and pass through
the hand-off prompt like any other flag. Each implementor agent then spawns its
own reviewer. The parent neither sees nor accumulates a single finding — the
review loop is entirely inside the agent, which is the correct place for it and
the reason this change and
[task-peer-review](./task-peer-review.md) compose cleanly rather than
compounding.

## Data and state

None added. `delegated-runs.md` continues to exist on delegated runs and
continues to hold the per-run record; the launcher writes the same rows it wrote
before, drawn from the return values rather than from what it already knew.

## Interfaces and contracts

No new commands, no new flags, no change to any documented usage line. The
observable behaviour of `/task-implement` is unchanged; what changes is the
parent's token profile. This is a **patch-level** change to the skill's
`version:` in the sense that no interface moves, though the body change is
substantial — bump minor on the skill and minor on root `VERSION`, since the
delegation contract is materially different even if its surface is not.

Hard contracts:

- The parent reads no task body, on any path, ever.
- Delegated and manual runs execute the same flow.
- Agents run sequentially, never in parallel.
- `human` / `claude+human` / requested `[STALE]` tasks never reach an agent.

## Dependencies

- **[shared-phase-engine](./shared-phase-engine.md)** — not required, but the
  two touch the same file and the launcher is the smaller change. Land this
  first, then refactor; the reverse order rebases a large refactor onto a
  restructured file for no gain.
- The `.claude/context/` layer is what makes the thin prompt viable. On a
  project with no context layer the agent falls back to reading the source
  itself, which is slower but correct — the change does not require the layer,
  it just pays off most where the layer exists.

## Open questions

- **Does the agent need the run's dirty-tree decision?** The parent resolves
  the dirty-tree prompt once for the run. That answer is a flag and travels in
  the flag list, so this is probably already handled — worth confirming during
  implementation rather than assuming.
- **Grep reliability on the three fields — resolved, and moot.** The parent
  greps no body at all: `Target:`, `Status:` and `Feature:` all appear in the
  task's `TASKS.md` summary block, which PRE-FLIGHT already reads once for the
  whole run. No fenced block in a task body can mislead a read that never
  happens.
- **The `next` resolution path — confirmed.** It reads `TASKS.md` only and does
  not peek at bodies to break ties, so nothing had to change for it.
