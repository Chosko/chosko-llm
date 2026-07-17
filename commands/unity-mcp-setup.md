---
name: unity-mcp-setup
version: 0.1.0
type: command
description: Make a Unity project ready for MCP-assisted task implementation. Idempotent and re-runnable — detects the project, installs the Unity-side com.coplaydev.unity-mcp package into Packages/manifest.json if missing, records the project-side fact in versioned artifacts (a terse CLAUDE.md marker plus, when a context layer exists, .claude/context/mcp-tools.md and an INDEX.md row), and registers + verifies the machine-local Claude-side UnityMCP server via claude mcp add / claude mcp list. Configures only what is missing. Authoring command — leaves its versioned artifacts uncommitted for review by default; pass --commit to commit them. The Claude-side registration is machine-local config (in ~/.claude.json), not a repo change, so it happens regardless of the flag.
---

# /unity-mcp-setup
# Global command: wire a Unity project up for MCP-assisted /task-implement.
# It has two sides — a VERSIONED project side (the Unity package, a CLAUDE.md
# marker, and an optional context-layer doc) and a MACHINE-LOCAL Claude side
# (the `claude mcp add` registration in ~/.claude.json). The command is the
# single, re-runnable entry point that fills in only what is missing and
# carries a from-nothing project all the way to a tested connection.
# Usage: /unity-mcp-setup
# Usage with commit: /unity-mcp-setup --commit
#   (commit the versioned artifacts this command writes)

GOAL
Make the current Unity project ready for `/task-implement` to drive the
Unity editor over MCP. The command:
1. Confirms the project is Unity (refuses otherwise).
2. Ensures the Unity-side package `com.coplaydev.unity-mcp` is present in
   `Packages/manifest.json` (offers to add it if missing).
3. Records the project-side fact in versioned artifacts: a terse marker in
   CLAUDE.md, plus — when the project has a navigation context layer —
   `.claude/context/mcp-tools.md` and a matching `INDEX.md` row.
4. Registers and verifies the machine-local Claude-side `UnityMCP` server
   via `claude mcp add` / `claude mcp list`.

Everything is IDEMPOTENT: a second run on a fully-configured project makes
no changes and reports "already set up". Configure only what is missing —
never duplicate a marker, a manifest entry, a context row, or a
registration.

COMMIT POLICY — this is an AUTHORING command. By DEFAULT (no `--commit`) it
leaves every VERSIONED file it writes — `Packages/manifest.json`,
`CLAUDE.md`, `.claude/context/mcp-tools.md`, `.claude/context/INDEX.md` —
UNCOMMITTED in the working tree for you to review and commit in one pass,
matching the other authoring commands (`/project-setup`, `/context-build`,
`/task-enrich`, the `/refactor-*` commands). With `--commit` it commits
exactly those written paths in one focused commit. `--commit` and
`--no-commit` are mutually exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`

The Claude-side `claude mcp add` registration is NOT a repo change — it
writes machine-local, per-project config into `~/.claude.json` (local
scope). It is performed the same way regardless of `--commit`, and it is
never staged or committed.

$ARGUMENTS

ARGUMENT NOTE — scan $ARGUMENTS for the optional `--commit` flag. If
present, set COMMIT = true and strip it. `--commit` and `--no-commit` are
mutually exclusive — if both appear, stop with the message above. COMMIT
drives PHASE 3's Step F only.

The flow is strictly: DETECT (probe read-only) → CONFIRM (one approval) →
EXECUTE (apply only what's missing) → commit-or-review-reminder. Never
write to any file, and never run `claude mcp add`, before the user confirms
the gathered plan.

Bash / PowerShell in this command are only for the read-only VCS/Unity
probes, the `claude mcp list` / `claude mcp add` calls, and — under
`--commit` only — the final commit.

---

PHASE 0 — UNITY CHECK (must pass before anything else)

Probe read-only for Unity: `ProjectSettings/ProjectVersion.txt` exists →
Unity project (the same signal `/project-setup` uses). If it is absent,
stop:

> This is not a Unity project — no `ProjectSettings/ProjectVersion.txt`
> found. `/unity-mcp-setup` only applies to Unity projects.

Do not proceed. This rule has no exceptions.

---

PHASE 1 — DETECT (read-only; no files written, no registration run)

Gather the current state of all four concerns. Report each finding as you
go; act on none of them yet.

1. **Unity-side package.** Read `Packages/manifest.json`. Look for a
   `com.coplaydev.unity-mcp` key inside the `dependencies` object.
   - Present → note "Unity package already declared".
   - Absent → note "Unity package missing — will offer to add it".

2. **CLAUDE.md marker.** Read `CLAUDE.md` if it exists. Look for a line
   beginning `Unity MCP for /task-implement:`.
   - Present and equal to the canonical marker (below) → note "marker
     present".
   - Present but different → note "marker present but will be updated in
     place".
   - Absent → note "marker missing — will add it".

3. **Context layer.** Check whether `.claude/context/INDEX.md` exists.
   - Exists → the project has a navigation context layer; note whether
     `.claude/context/mcp-tools.md` already exists (present → leave as-is
     unless stale; absent → will create it and add an INDEX row).
   - Missing → there is NO context layer; the CLAUDE.md marker alone is the
     project-side record. Do NOT create an orphan `mcp-tools.md`.

4. **Claude-side registration.** Run `claude mcp list` (read-only). Look
   for a `UnityMCP` entry and its connection state.
   - Registered and connected → note "Claude side ready".
   - Registered but disconnected → note "registered, but not reachable
     (likely Unity is closed or on a non-default port)".
   - Not registered → note "not registered on this machine — will run
     `claude mcp add`".

The canonical CLAUDE.md marker is, EXACTLY:

```
Unity MCP for /task-implement: com.coplaydev.unity-mcp (UnityMCP, http)
```

This is the phrase `/task-implement` scans for — do not alter its wording.

---

PHASE 2 — CONFIRM (present the plan, one approval)

Render the detected state and the exact set of actions — listing only what
is missing, and explicitly marking what is already in place as "skip". If
NOTHING is missing, say so and stop without asking for approval:

> Everything is already set up: the Unity package is declared, the CLAUDE.md
> marker is present, the context doc exists (if applicable), and `UnityMCP`
> is registered and connected. Nothing to do.

Otherwise present:

```
PLAN — unity-mcp-setup     (versioned artifacts left for review unless --commit)

Commit mode:      <off — leave versioned files for review | on (--commit)>
Unity package:    <add com.coplaydev.unity-mcp to manifest.json | already present (skip)>
CLAUDE.md marker: <add | update in place | already present (skip)>
Context doc:      <create .claude/context/mcp-tools.md + INDEX row | already present (skip) | n/a (no context layer)>
Claude side:      <run `claude mcp add` then verify | already registered — verify only | registered+connected (skip)>

Notes:
  - After adding the package, you'll need to open the Unity Editor so it
    imports and starts the MCP HTTP server before the connection can verify.
  - After a fresh `claude mcp add`, this running session's tool index does
    NOT refresh — the `mcp__UnityMCP__*` tools only appear after you restart
    the session. `claude mcp list` reflects the registration immediately.
```

End with: **"Approve and run?"**

Wait for explicit approval. Silence is not approval. Iterate and re-present
the full plan after any change.

---

PHASE 3 — EXECUTE (only after explicit approval)

Run the steps in order. Skip any step whose concern is already satisfied
(PHASE 1). Report each step's result.

### Step A — Unity-side package (if missing)

If `com.coplaydev.unity-mcp` is absent from `Packages/manifest.json`, add
exactly this entry to the `dependencies` object (preserving the file's
existing formatting and trailing-comma correctness):

```
"com.coplaydev.unity-mcp": "https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#main"
```

Use the Read tool to open the file, the Edit tool to insert the single
dependency line. Do not reorder or reformat other entries. If the key is
already present, do nothing (idempotent).

After adding it, tell the user they must open the Unity Editor so the
package imports and its MCP HTTP server starts (default endpoint
`http://127.0.0.1:8080/mcp`). This is a genuine manual step — pause and ask
them to confirm Unity is open and the "MCP for Unity" window reports the
server running before you attempt to verify the connection in Step E. If
the package was already present, no pause is needed.

### Step B — CLAUDE.md marker (if missing or different)

Ensure `CLAUDE.md` contains the canonical marker line exactly:

```
Unity MCP for /task-implement: com.coplaydev.unity-mcp (UnityMCP, http)
```

- If CLAUDE.md has no such line, add it. Prefer to place it inside the
  project's existing `## Tasks implementation` section if one exists (that
  section is the permanent home for `/task-implement` guidance in a
  project); otherwise add a short `## Unity MCP` section containing the
  marker plus a one-line pointer to `.claude/context/mcp-tools.md` when that
  doc exists.
- If a `Unity MCP for /task-implement:` line already exists but differs,
  update it in place. Never duplicate the marker.
- If CLAUDE.md does not exist at all, create a minimal one with a title and
  the marker (mirroring how `/project-setup` seeds a skeleton).

### Step C — Context doc + INDEX row (only when a context layer exists)

Run this step ONLY when `.claude/context/INDEX.md` exists AND
`.claude/context/mcp-tools.md` is not already present. Write
`.claude/context/mcp-tools.md` — Unity-only — from this template:

```
# MCP tools — UnityMCP

The `UnityMCP` server is registered **per machine, project-local**
(`claude mcp add` default/local scope). Local-scope entries live in the
user's own `~/.claude.json` and are **not** versioned — a fresh clone or a
different machine will not have them until someone runs the registration
command below there. Check what a given session already has with:

```
claude mcp list
```

## UnityMCP

Bridges to the Unity Editor over HTTP. Requires the "MCP for Unity" package
(`com.coplaydev.unity-mcp`) installed in the Unity project and the Editor
open (it hosts the HTTP endpoint — usually `http://127.0.0.1:8080/mcp`). If
`claude mcp list` doesn't show `UnityMCP` connected, register it:

```
claude mcp add --transport http UnityMCP http://127.0.0.1:8080/mcp
```

If port 8080 is taken, the actual port is shown in Unity's "MCP for Unity"
window/console — use that instead.

Once connected, tools appear under `mcp__UnityMCP__*` (e.g.
`manage_gameobject`, `manage_scene`, `find_gameobjects`,
`import_model_file`). Resources live under `mcpforunity://…` — read
`mcpforunity://project/info` for the Unity version and project root, and
`mcpforunity://instances` if more than one Editor instance is running.

### Gotchas learned in practice

- After `claude mcp add`, a **running** Claude Code session's tool index
  does not refresh — new tools only appear after closing and reopening the
  session (or starting a new one). `claude mcp list` reflects the
  registration immediately; the live tool list does not.
```

Then add a row to `.claude/context/INDEX.md` referencing the new file in
its file table (matching the table's existing column shape), e.g.:

```
| [mcp-tools.md](./mcp-tools.md) | UnityMCP MCP server — registration (`claude mcp add`), `mcp__UnityMCP__*` tools, `mcpforunity://…` resources, and refresh gotchas. Machine-local, not versioned. |
```

Refresh the `Last updated:` date near the top of `INDEX.md` to today. Do
not create `mcp-tools.md` when there is no context layer — the CLAUDE.md
marker is the sole project-side record in that case.

### Step D — Claude-side registration (if not registered)

If PHASE 1 found no `UnityMCP` registration, run:

```
claude mcp add --transport http UnityMCP http://127.0.0.1:8080/mcp
```

This registers at local scope (per machine, per project) in
`~/.claude.json` — it is machine-local config, not a repo change, so it is
never staged or committed. If the user reported (Step A) that Unity is on a
non-default port, substitute that port in the URL. If `UnityMCP` is already
registered, skip the `add` and go straight to verification.

### Step E — Verify the connection

Run `claude mcp list` and read the `UnityMCP` line:
- **Connected** → report success.
- **Disconnected / failed** → the endpoint isn't reachable. Most likely the
  Unity Editor is closed, still importing the package, or listening on a
  different port. Guide the user: open Unity, wait for the "MCP for Unity"
  window to report the server running, confirm/correct the port, and re-run
  verification. If the port differs, re-register with the correct URL
  (`claude mcp add` again after removing the stale entry if needed).

Whenever a FRESH `claude mcp add` was performed in this run, tell the user
that the `mcp__UnityMCP__*` tools will not be visible to Claude until the
session is restarted (per the gotcha) — `claude mcp list` confirms the
registration now, but the live tool index only refreshes on a new session.

### Step F — Commit the versioned artifacts (only with `--commit`)

Run this step ONLY when `--commit` was passed. Stage EXACTLY the versioned
files Steps A–C wrote — any of `Packages/manifest.json`, `CLAUDE.md`,
`.claude/context/mcp-tools.md`, `.claude/context/INDEX.md` — by explicit
path, and make one commit:

```
git add -- <only the files actually written>
git commit -m "Set up Unity MCP for /task-implement"
```

If Steps A–C wrote nothing (everything was already in place), make no
commit. Never stage a catch-all (`git add -A`/`.`/`-u`). The Claude-side
registration is NOT part of this commit — it lives outside the repo. On a
non-git VCS, use the project's `## VCS` mapping (git→`cm`). On commit
failure (e.g. a pre-commit hook), surface the output; do NOT retry, amend,
or use hook-skipping flags. Without `--commit`, skip this step entirely.

### Final report

Summarize what changed and what was already in place. Then, depending on
COMMIT:
- Without `--commit`: list the versioned files written and remind the user
  they are UNCOMMITTED for review; note that the Claude-side registration
  was applied to `~/.claude.json` (machine-local, nothing to commit).
- With `--commit`: report the commit's short hash and the paths it covered;
  note the Claude-side registration separately as machine-local config.

If a fresh registration happened, end by reminding the user to restart the
session so the `mcp__UnityMCP__*` tools become available.

---

DO NOT:
- Write to any file, or run `claude mcp add`, before PHASE 2 approval.
- Run on a non-Unity project (PHASE 0 refuses).
- Duplicate the CLAUDE.md marker, the manifest entry, the context row, or
  the registration — update/skip in place; the command is idempotent.
- Create `.claude/context/mcp-tools.md` when the project has no context
  layer (no `.claude/context/INDEX.md`).
- Stage or commit the Claude-side `claude mcp add` registration — it is
  machine-local config in `~/.claude.json`, never a repo change.
- Commit anything unless `--commit` was passed; then commit only the
  explicit versioned paths written — never a catch-all, never push, branch,
  tag, or use hook-skipping flags.
- Reformat or reorder unrelated entries in `Packages/manifest.json`.
