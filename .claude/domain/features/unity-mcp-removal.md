# Unity MCP removal

Deletes the repo's own Unity MCP integration — the `/unity-mcp-setup`
command, the vendored `unity-mcp-skill`, the `Unity MCP for /task-implement:`
`CLAUDE.md` marker and the `/task-implement` checkpoint file that reads it —
superseded by Unity's official MCP. What was generic in that
checkpoint file moves into `/task-implement`'s human-in-the-loop
instructions, written for any tool an agent can drive, so a Unity project
with the official MCP connected keeps the "Claude does the editor work, the
user verifies" behaviour without the repo naming any particular server.

## Purpose

The integration is built around one third-party package
(`com.coplaydev.unity-mcp`) and its `mcp__UnityMCP__*` tool names, which
Unity's official MCP server supersedes. Keeping a setup command and a
vendored operator guide for the superseded package means installing,
documenting and auditing a surface nobody should use, and teaching
`/task-implement` to look for a marker that points at it.

The checkpoint behaviour is worth keeping and is not Unity-specific: when a
connected tool can perform a manual step, the agent may do it and hand the
user a verification instead of an instruction. That belongs to the
human-in-the-loop protocol itself, stated once, for whatever tool the
session has.

## Scope and non-goals

In scope: deleting the two features and the checkpoint file; removing the
marker and every passage that reads, writes or offers it; relocating the
generic checkpoint behaviour; updating every reference in shipped bodies,
the context layer, the domain layer and the two repo-local audit skills; the
`CHANGELOG` instructions for users with installed copies.

Deliberately out:

- **A replacement Unity integration.** No new setup command, no vendored
  guide for the official server, no recipe for driving the Unity editor in
  the repo. A project that wants one keeps it in its own `CLAUDE.md` or
  context layer.
- **A removal mechanism for installed copies.** The CLI has no "feature
  withdrawn upstream" verb and gains none: `ls` shows an installed copy of
  either feature as `local only` — installed, absent from the managed clone —
  and the user removes it with `chosko-llm rm`.
- **The rest of the Unity story.** Kept unchanged: `/project-setup`'s Unity
  detection (`ProjectSettings/ProjectVersion.txt`), its test-suite question
  (widened to every project by [setup-sync](./setup-sync.md)), the Unity
  editor dirty-tree noise template, the Plastic SCM VCS mapping, and
  `targets.md`'s Unity worked example for `claude+human` tasks.
- **README.md, `docs/reference.md` and other user docs.** Rewritten when the
  experiment ships, not here.

## Architecture

Built on the repo's existing shape per `technical-direction.md`: shipped
markdown features installed by copy. The change deletes two features and one
supporting file, rewrites one supporting file, and edits the bodies that cite
them. No CLI script changes.

### What is deleted

- `skills/unity-mcp-skill/` — the vendored operator guide and its two
  references (see `.claude/context/setup-commands.md`).
- `commands/unity-mcp-setup.md` — the setup command, with everything it
  wrote into a project: the package line, the `CLAUDE.md` marker and the
  `.claude/context/mcp-tools.md` context file.
- `skills/task-implement/unity-mcp-checkpoints.md` — the enhanced checkpoint
  file and its row in `/task-implement`'s supporting-files table.
- The marker `Unity MCP for /task-implement:` as a contract: no shipped body
  reads, writes or names it afterwards.

### What moves into the human-in-the-loop protocol

`/task-implement`'s `human-in-loop.md` loses its *Unity MCP gate* and gains
a tool-agnostic passage, applying to any checkpoint whose manual step a tool
connected this session can perform:

1. **Automatic or manual, asked once per task.** When the checkpoints of the
   task could be driven by a connected tool, ask once at task start whether
   the agent performs them (more tokens; the user verifies) or the user does
   (the agent verifies). One answer settles the task. Under the interaction
   policy this is a real decision, never auto-picked.
2. **After a compile, read the tool's console.** A checkpoint whose only ask
   is "let it compile and check for errors" is done by the agent through the
   tool; errors from this task's changes are fixed and re-checked before
   moving on; errors the agent cannot resolve stop the task.
3. **Wait out a reload.** After a change that makes the external tool reload
   (a domain reload, an asset re-import, a restart), wait until the tool
   reports it is ready before the next action or check — never act on a
   half-reloaded state.
4. **Verify the outcome, not the claim.** An action the agent performed is
   re-queried through the tool or the filesystem before the checkpoint
   counts as done; "looks done" — the agent's or the user's — is a second
   check, never the only one. A step the tool cannot perform falls back to
   the standard manual protocol for that step alone.

The passage names no server, no package and no tool prefix; tool discovery
is from the live tool set. The explain-first, end-the-turn-with-no-tool-call
and independent-verification rules of the standard protocol stay as they
are.

### What is updated

Every reference, in the same change: `/project-setup` (its Unity MCP offer,
its plan line and step 7, its header comment), `/task-implement`
(`SKILL.md`'s supporting-files row and Step 1 mention, `human-in-loop.md`),
`task-engine`'s `targets.md` (the `/task-implement` consumer note's Unity MCP
gate clause), the context layer (`setup-commands.md`, `task-implement.md`,
`features.md`, `feature-contract.md` and `INDEX.md` where they name the
removed features), the domain layer (`product-design.md`'s *Unity/MCP
integration* section, `task-workflow.md`, the feature documents that name
the marker), and the repo-local `rule-overlap` and `context-budget` skills,
which exclude or budget `unity-mcp-skill` by name.

## Data and state

- Removed from projects (by the user, per the `CHANGELOG` entry): the
  `Unity MCP for /task-implement:` line in `CLAUDE.md` and
  `.claude/context/mcp-tools.md` with its `INDEX.md` row. Nothing reads them
  once this change ships, so a project that keeps them is unaffected.
- The `com.coplaydev.unity-mcp` package line in a Unity project's
  `Packages/manifest.json` and the machine-local `UnityMCP` server
  registration are the user's to remove; the `CHANGELOG` names them.
- No new state.

## Interfaces and contracts

| Contract today | After this feature |
|---|---|
| `chosko-llm add unity-mcp-setup`, `add unity-mcp-skill` | Not available; `ls` shows an installed copy as `local only` |
| `/project-setup` offers `/unity-mcp-setup` on Unity projects | No offer; the Unity detection, test-suite question and dirty-tree section stay |
| `/task-implement` reads the marker and `unity-mcp-checkpoints.md` | Reads neither; `human-in-loop.md` carries the tool-agnostic automatic/manual passage |

The `CHANGELOG` entry tells users to run `chosko-llm rm unity-mcp-setup` and
`chosko-llm rm unity-mcp-skill` (with `--local` where installed locally),
delete the old `CLAUDE.md` marker and `.claude/context/mcp-tools.md` from
their projects, and switch to Unity's official MCP.

Failure contract: a project still carrying the marker runs exactly as one
without it. An installed `unity-mcp-setup` copy keeps working as a stale
copy until removed; nothing the repo ships calls it.

## Dependencies

- [interaction-policy](./interaction-policy.md) — the automatic/manual
  question follows its question rules and is a real decision, never
  auto-picked. The interaction-policy document leaves `/unity-mcp-setup` out
  of its adoption list because this feature deletes it.
- [setup-sync](./setup-sync.md) — touches the same `/project-setup`
  passages (the test-suite question widens to every project); whichever lands
  second rebases on the first.
- [repo-local-audits](./repo-local-audits.md) — `rule-overlap` and
  `context-budget` name the vendored skill.

