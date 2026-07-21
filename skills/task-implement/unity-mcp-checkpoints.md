# Unity MCP-driven checkpoints (enhanced human-in-loop mode)

Read this ONLY when all three hold on a `claude+human` / `human` task:

1. The current task is human-in-the-loop (you are already in
   `./human-in-loop.md`).
2. The project's CLAUDE.md contains the marker line
   `Unity MCP for /task-implement:` — the project declares a Unity MCP
   plugin.
3. The `mcp__UnityMCP__*` tools are actually present in this session — the
   Claude-side server is registered AND connected right now.

If the marker is present but the `mcp__UnityMCP__*` tools are NOT in this
session, do NOT read or apply this file: fall back to the standard protocol
in `./human-in-loop.md`, and tell the user once that Unity MCP is declared
but not connected this session — they can run `/unity-mcp-setup` (and, per
its gotcha, restart the session) to enable editor automation. If CLAUDE.md
has no marker at all, this file is irrelevant and never gets read.

When Unity MCP is eligible, this file REPLACES how the manual checkpoints
are handled — instead of pausing and asking the user to act in the editor,
Claude does the editor work itself and hands the user a verification step.
Everything else in the per-task workflow is unchanged.

## Per-run opt-out (ask once, at task start)

Eligibility does not force the enhanced mode. When you announce the
checkpoints up front in Step 1, ask the user ONE plain-language question and
let one answer settle the whole task:

> Unity MCP is connected for this project, so the manual checkpoints in
> this task can go two ways:
>
> **Automatic** — I make the changes in Unity Editor myself, then pause.
> You verify.
>
> **Manual** — I pause at each checkpoint. You make the Unity changes
> yourself. I verify.
>
> Which would you like — **automatic** or **manual**?

- If the user chooses **manual** (opt-out): ignore this file for the rest of
  the task and follow the standard `./human-in-loop.md` protocol exactly —
  behave as if Unity MCP were not available.
- If the user chooses **automatic**: apply the two behaviours below.

Deliver this question as its own turn (per the explain-first rule in
`./human-in-loop.md` — do not bury it behind a tool call), and wait for the
user's answer before starting Step 4.

## Behaviour 1 — auto-check the Unity Console after compilation

A checkpoint whose only ask is "open Unity, let scripts compile, check the
Console for errors" needs no human. Do it yourself:

1. Trigger/await compilation and read the Console via the `mcp__UnityMCP__*`
   tools (e.g. the console/log-reading tool the server exposes; discover the
   exact tool names from the live `mcp__UnityMCP__*` set — do not hardcode).
2. If the Console is clean, the checkpoint is satisfied automatically —
   record it and move on with no pause. When this was the checkpoint's ONLY
   step, the whole checkpoint becomes fully automatic.
3. If the Console shows compile errors that stem from this task's changes,
   iterate: fix the code, recompile, re-read the Console, and repeat until
   clean — before proceeding past the checkpoint. This is ordinary Step 4
   implementation work, just verified through the editor instead of a local
   test run.
4. If errors appear that you cannot resolve (e.g. they point at project
   state only the user controls), stop and report per the skill's FAILURE
   HANDLING — do not push past a red Console.

## Behaviour 2 — perform editor actions, then hand over a verification

For a checkpoint that asks the user to do something in the editor (create a
GameObject, add a component, assign a serialized reference, set an import
setting), attempt it yourself with the `mcp__UnityMCP__*` tools instead of
instructing the user.

1. **Attempt the action** via the appropriate MCP tool (e.g.
   `manage_gameobject`, `manage_scene`, an import/asset tool). Discover the
   real tool names and arguments from the live `mcp__UnityMCP__*` set.
2. **On success, rewrite the checkpoint from an instruction into a
   verification.** Where the standard protocol would say "create a
   GameObject Foo as a child of Bar", you instead did it, so the user-facing
   step becomes: "I created GameObject Foo as a child of Bar — please
   confirm you see it in the Hierarchy." Deliver this at the checkpoint's
   trigger point using the SAME explain-first, end-the-turn-with-no-tool-call
   protocol from `./human-in-loop.md`, and still verify independently
   whatever is checkable (read the MCP result, re-query the scene/object via
   `mcp__UnityMCP__*`, confirm the file/asset exists) — the user's "looks
   right" is a second check, not the only one. Purely visual outcomes that
   nothing can confirm from the tools/filesystem may rest on the user's
   word; say so when they do.
3. **On failure or a step Claude genuinely cannot do** (the tool errors, the
   action needs a GUI wizard the server doesn't expose, or Unity is closed
   so the call fails): preserve the ORIGINAL manual checkpoint for the user.
   Fall back to the standard `./human-in-loop.md` protocol for that step —
   explain the manual action, wait for confirmation, verify — exactly as if
   MCP were unavailable. Do not block the run on an action MCP can't perform;
   just route that one step back to the human.

## What does not change

- The explain-first / end-turn-with-no-tool-call / independent-verify
  discipline from `./human-in-loop.md` still governs every user-facing
  checkpoint, including the rewritten verification steps.
- `Target: human` still means Claude makes no *production code* edits;
  under this mode Claude may still drive the editor via MCP for the
  checkpoints the user opted into, but the guided-walkthrough spirit holds
  — offer the manual path readily and never override a user who wants to do
  a step themselves.
- Status flips, commits, and the rest of the per-task workflow are
  unaffected.
