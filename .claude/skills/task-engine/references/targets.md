# `Target:` values and the delegation guard

Authority for: the three `Target:` values, the `## Manual interventions`
pairing rule, what each target means at implementation time, and which
tasks may never be handed to a subagent.

Extracted verbatim from `/task-add`'s `TARGET VALUES & MANUAL
INTERVENTIONS`, `/task-implement`'s Step 1 and its `ARGUMENT PARSING`
warning, and `delegated-runs.md`'s `What stays in the parent`.

---

## The three values

`Target:` (line 2 of the body, mirrored in the summary block) takes one of:

- `claude` — Claude implements end-to-end. **Default.**
- `claude+human` — Claude implements, but the work includes steps only a
  human can perform in an external tool (a game-engine editor such as
  Unity, a cloud console, physical hardware). `/task-implement` pauses at
  each declared checkpoint, walks the user through it, and verifies the
  outcome before continuing.
- `human` — the task is executed entirely by the user; `/task-implement`
  runs it as a guided walkthrough.

There are exactly three. A summary block with no `Target:` line is treated
as `claude`.

## `## Manual interventions` is paired with the target

During PHASE 1/2, when the description or the codebase reveals that part
of the work cannot be executed by an agent (editor-only operations, GUI
wizards, hardware), set `Target: claude+human` (or `human` when nothing
is agent-executable) and author a `## Manual interventions` section,
placed between `## Decisions` and `## Hints`. Consistency is enforced
both ways: targets `claude+human`/`human` REQUIRE the section, and the
section requires one of those targets — never write one without the other.

The section opens with a ⚠ warning line, then numbered checkpoints. Each
checkpoint is anchored to a trigger point ("After X: …"), describes the
manual step, and ends with an outcome the implementer can verify itself.
Worked example (Unity):

```
## Manual interventions

⚠ REQUIRES MANUAL INTERVENTION — pause implementation at these points and
walk the user through them in the Unity editor; wait for their
confirmation and verify the outcome before continuing:

1. After the `.inputactions` file is written: select it in the Project
   window, tick **Generate C# Class** in the importer, Apply. Verify the
   generated `.cs` file appears and the project compiles.
2. After `InputManager.cs` compiles: open
   `Assets/_Project/Prefabs/Controllers.prefab`, add the `InputManager`
   component to an appropriate GameObject, and assign any serialized
   references (e.g. the actions asset if referenced via inspector).
   Do NOT hand-edit the prefab YAML for this. Verify the prefab contains
   the component with its references assigned.
```

## At implementation time

If the target is `claude+human` or `human`, follow the human-in-the-loop
protocol for the rest of that task. For `claude+human`, announce the
manual-intervention checkpoints up front — a one-line summary per
checkpoint — so the user knows where the run will pause and what they'll
be asked to do. For `human`, state that this task runs as a guided
walkthrough and confirm the user is ready to start.

Never make production edits on a `Target: human` task, and never proceed
past a manual-intervention checkpoint on the user's word alone when the
outcome is checkable — verify it yourself first.

When a batch selector resolves the task list, check each resolved task's
`Target:` field in its TASKS.md summary block. If any resolved task is
`claude+human` or `human`, append a warning to the resolution report:
"Task(s) <IDs> require human intervention — the run will pause and need
you present." These tasks cannot run unattended.

## The delegation guard

Not every task can be delegated to a subagent. The parent implements these
itself, in the list's original order, exactly as an ordinary in-context run
would:

- **`claude+human` and `human` tasks.** The human-in-the-loop protocol
  requires the implementer to pause at each checkpoint, explain the manual
  step in a turn that ends with no tool call, and wait for the user's
  free-text confirmation. A subagent cannot hold that conversation with the
  user.
- **`[STALE]` tasks requested explicitly by number.** The stale protocol
  asks the user to choose implement-anyway or stop; that question is the
  parent's, and a task the user chooses to implement then runs in-context.

So a delegated run is usually mixed. Before the first task starts, say so
plainly — name the IDs and why:

> Delegating tasks 20, 22 to fresh agents (one at a time). Tasks 21, 23
> run here in this conversation: 21 is `claude+human` and 23 is `[STALE]`,
> and both need you present.

Never delegate silently and never let the user discover the split from the
output.

The three fields the guard needs — `Target:`, `Status:` and `Feature:` —
all live in the task's `TASKS.md` summary block, so the guard costs nothing
per task and no body read can be justified by it.

---

## Per-consumer notes

- **`/task-add`** — the only writer of `Target:`. `claude` is its default;
  it sets `claude+human` or `human` only alongside a `## Manual
  interventions` section, and never one without the other.
- **`/task-list`** — reads `Target:` for one marker only: if the task's
  target is `claude+human` or `human`, append `⚠ <target>` after the title
  (before any deps annotation) so human-in-the-loop tasks are visible at a
  glance. Target `claude` gets no marker. Its pre-migration copy of that rule
  also named a fourth value, `local`; that value was removed from the system
  when the dual-LLM lane was deleted, so it is deliberately not carried here,
  and `/task-list`'s mention of it went with the migration.
- **`/task-clean`** — does not read `Target:` at all.
- **`/task-implement`** — the only consumer that acts on a target. It reads
  its supporting `human-in-loop.md` for a `claude+human` / `human` task,
  which in turn carries the gate deciding whether the manual checkpoints
  can be driven through Unity MCP. It applies the delegation guard on a run
  resolving to 2+ tasks with delegation enabled.
