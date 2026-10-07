# Human-in-the-loop tasks (Target: claude+human / human)

Read this when the current task's `Target:` is `claude+human` or `human`.

A body whose `Target:` is `claude+human` or `human` carries a
`## Manual interventions` section: a ⚠ warning line followed by numbered
checkpoints, each anchored to a trigger point ("After X: …") with a manual
step the user must perform in an external tool (e.g. the Unity editor) and
a verifiable outcome. If the section is missing on such a target, stop and
report — the task is inconsistent; the user should fix it with /task-add
conventions in mind.

## Checkpoints a connected tool can perform

A checkpoint whose manual step a tool connected this session can perform —
discovered from the live tool set, whatever server provides it — may be
performed by the agent instead of handed to the user. When the task has such
a checkpoint, these four rules apply on top of the checkpoint protocol
below:

1. **Automatic or manual, asked once per task.** At task start, when the
   checkpoints are announced, ask once whether the agent performs them
   through the tool (more tokens; the user verifies) or the user does (the
   agent verifies), and let the one answer settle the whole task. The
   question is a real decision —
   `../interaction-engine/references/gates.md` § *Real decisions* — and is
   asked as its own turn, per the explain-first rule below. Under manual,
   the rest of this section does not apply.
2. **After a compile, read the tool's console.** A checkpoint whose only ask
   is "let it compile and check for errors" is done by the agent through the
   tool, with no pause when the console is clean. Errors from this task's
   changes are fixed and re-checked before moving past the checkpoint;
   errors the agent cannot resolve stop the task per the skill's FAILURE
   HANDLING.
3. **Wait out a reload.** After a change that makes the tool reload — a
   domain reload, an asset re-import, a restart — wait until the tool
   reports it is ready before the next action or check.
4. **Verify the outcome, not the claim.** A step the agent performed is
   re-queried through the tool or the filesystem before the checkpoint
   counts as done, and the user-facing step becomes a verification ("I
   created X — confirm you see it") delivered under the same protocol; the
   user's "looks right" is a second check, never the only one. A step the
   tool cannot perform falls back to the standard protocol for that step
   alone.

## Checkpoint protocol (used by both targets)

1. **Pause** when implementation reaches a checkpoint's trigger point. Do
   not continue past it.
2. **Explain first, then ask.** Before any confirmation, write the manual
   step out as exact, sequential actions — menu paths, object and component
   names, field assignments — adapted to what actually happened so far
   (real paths, real names — not the body's placeholders if they drifted).
   The user must be able to act from this explanation alone, without prior
   knowledge of the change and without asking back.
   Deliver the explanation as a plain-text turn that ends with NO tool
   call: some UIs (including the Claude Code CLI) hide assistant text that
   precedes a question dialog in the same turn, so pairing the explanation
   with a question tool renders the instructions invisible. End the turn by
   telling the user how to confirm (e.g. "reply done when finished").
3. **Wait for the user's explicit free-text confirmation** (e.g. "done")
   that they performed it. Only after the Step 2 explanation — never a bare
   "did you do it?" on its own, and never via a question dialog in the same
   turn as the explanation.
4. **Verify independently.** The user saying "done" is not proof. Check
   the claimed outcome yourself: Read/Glob for files that must exist,
   run a compile or test command, inspect the artifact's content —
   whatever the checkpoint's outcome makes checkable. Only what is
   genuinely unverifiable from the filesystem/CLI (e.g. a purely visual
   editor state) may rest on the user's word — say so explicitly when it
   does.
5. **On verification failure:** report exactly what is missing or wrong
   (e.g. "you confirmed the prefab was created, but
   `Assets/_Project/Prefabs/Foo.prefab` does not exist"), re-guide the
   user through the step, and repeat from 3. Never proceed past an
   unverified checkpoint unless the user explicitly overrides ("skip the
   check, move on") — record the override in the final report.

## Target: claude+human

Implement normally (all steps of the per-task workflow apply); the
checkpoints interleave with Step 3 at their trigger points. Announce all
checkpoints up front in Step 1 so the user knows the run will need them.

## Target: human — guided walkthrough mode

Claude makes NO production edits for this task: every change is performed
by the user, guided checkpoint by checkpoint with the same protocol. Claude
still runs read-only checks, compile/test commands for verification, and
still owns the bookkeeping: the `Status:` flips in TASKS.md and the Step 7
commit of the user's changes. Steps 2–5 of the per-task workflow apply only
insofar as the user performs them under guidance; where the project's test
flow is agent-runnable, Claude may still run the test commands itself
(running tests is verification, not production editing).
