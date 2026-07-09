# Human-in-the-loop tasks (Target: claude+human / human)

Read this when the current task's `Target:` is `claude+human` or `human`.

A body whose `Target:` is `claude+human` or `human` carries a
`## Manual interventions` section: a ⚠ warning line followed by numbered
checkpoints, each anchored to a trigger point ("After X: …") with a manual
step the user must perform in an external tool (e.g. the Unity editor) and
a verifiable outcome. If the section is missing on such a target, stop and
report — the task is inconsistent; the user should fix it with /task-add
conventions in mind.

## Checkpoint protocol (used by both targets)

1. **Pause** when implementation reaches a checkpoint's trigger point. Do
   not continue past it.
2. **Explain first, then ask.** Before any confirmation question, write a
   short lead-in paragraph — e.g. "Now I need your manual intervention —
   please do the following…" — that walks the user through the manual step
   concretely: the exact action(s) to perform, adapted to what actually
   happened so far (real paths, real names — not the body's placeholders if
   they drifted). The user must be able to act from this explanation alone,
   without asking back. Never lead with the confirmation question; the
   explanation always comes first.
3. **Ask, then wait** for the user's explicit confirmation that they
   performed it. Only after the Step 2 explanation — never a bare "did you
   do it?" on its own.
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
checkpoints interleave with Step 4 at their trigger points. Announce all
checkpoints up front in Step 1 so the user knows the run will need them.

## Target: human — guided walkthrough mode

Claude makes NO production edits for this task: every change is performed
by the user, guided checkpoint by checkpoint with the same protocol. Claude
still runs read-only checks, compile/test commands for verification, and
still owns the bookkeeping: the `Status:` flips in TASKS.md and the Step 8
commit of the user's changes. Steps 2–6 of the per-task workflow apply only
insofar as the user performs them under guidance; where the project's test
flow is agent-runnable, Claude may still run the test commands itself
(running tests is verification, not production editing).
