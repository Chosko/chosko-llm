---
name: project-setup
version: 0.1.0
type: command
description: Interactive first-time project initialization wizard. Gathers all choices upfront (VCS, context layer, CLAUDE.md content, AGENTS.md, task backlog), confirms once, then executes them in a fixed order. Orchestrates /context-build and /task-setup; injects a VCS-mapping section into CLAUDE.md for non-git projects (e.g. Plastic SCM).
---

# /project-setup
# Global command: a single entry point for initializing a project with the
# chosko-llm tooling. Two phases: a conversational GATHER phase that collects
# every choice upfront, then a silent EXECUTE phase that applies them in a
# fixed order with no further questions.
# Usage: /project-setup
# Usage with hint: /project-setup "source lives under lib/, we use Plastic"

GOAL
Walk a first-time user through configuring this project: detect the VCS,
optionally build the navigation context layer, optionally seed CLAUDE.md
with project information (and an AGENTS.md pointer), inject a VCS-mapping
section so the other chosko-llm commands work under non-git VCS, and
optionally initialize the task backlog.

This command ORCHESTRATES the existing commands — it does not reimplement
them. `/context-build` and `/task-setup` remain independently usable; this
wizard runs their logic on the user's behalf and adds two artifacts of its
own (the CLAUDE.md VCS section and AGENTS.md).

The flow is strictly: GATHER (ask everything) → CONFIRM (one approval) →
EXECUTE (apply in order) → COMMIT (own artifacts only).

Never write to any file before the user confirms the gathered plan.

$ARGUMENTS

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to an existing file;
  use the Write tool only when creating a new file from scratch. Never use
  shell redirection, `tee`, `Set-Content`, or `Out-File`.
- Bash / PowerShell are used for two narrow purposes:
  - VCS detection in the GATHER phase (read-only probes — see below).
  - The final COMMIT phase: `cm`/`git` staging and check-in of this
    command's own artifacts. No other phases shell out.

---

PHASE 1 — GATHER (conversational; no files written)

Ask the questions below in order. Suggest the answer you'd pick so the user
can confirm with a single word. Carry every answer forward into the CONFIRM
summary — do NOT act on any answer yet.

### 1a. Detect the VCS

Probe the working tree (read-only) to detect the version-control system:
- `.git/` present, or `git rev-parse --is-inside-work-tree` succeeds → git.
- `.plastic/` present, or a `cm` binary resolves and `cm status` succeeds
  → Plastic SCM.
- Neither → unknown.

Report what you found and ask which VCS to configure, presenting the
auto-detected one as the default:

> Detected VCS: <git | Plastic SCM | none>. Configure for this VCS?
> [Y / specify another]

The chosen VCS drives two things later: which commit command the EXECUTE
phase uses, and whether a VCS-mapping section is injected into CLAUDE.md
(injected for any non-git VCS; omitted for git, whose commands need no
override). If the user picks "none", skip VCS-section injection and do the
final commit with whatever VCS is actually present (or skip the commit and
report the files as left uncommitted).

### 1b. Context layer

> Build the navigation context layer now (runs /context-build)? [Y/n]

If **yes**, ask the two follow-ups:

> Seed CLAUDE.md with synthesized project information? [Y/n]

If they want CLAUDE.md seeded, invite (optional) source material now:

> Paste any documentation, README excerpts, or notes you'd like folded
> into CLAUDE.md (or say "skip" to let me synthesize from the codebase
> alone).

Capture whatever they paste — it will be SYNTHESIZED into prose during
EXECUTE, never inserted verbatim.

> Also create an AGENTS.md that points other agents at CLAUDE.md? [Y/n]

If the user declines the context layer (1b = no), still ask the AGENTS.md
question on its own — it is independent of context-build.

### 1c. Task backlog

> Initialize the task backlog now (runs /task-setup)? [Y/n]

That's the full set of questions. Keep it to these — do not improvise extra
prompts. If $ARGUMENTS carried hints (e.g. "we use Plastic", "source under
lib/"), apply them to pre-fill the relevant defaults and say so.

---

PHASE 2 — CONFIRM (present the full plan, one approval)

Render every gathered choice and the exact EXECUTE order in one message:

```
PLAN — project setup

VCS:            <git | Plastic SCM | none>   (commit via <git|cm|—>)
Context layer:  <build via /context-build | skip>
Seed CLAUDE.md: <yes, synthesizing N pasted source(s) | yes, from codebase | skip>
AGENTS.md:      <create | skip>
Task backlog:   <initialize via /task-setup | skip>
VCS section:    <inject Plastic mapping into CLAUDE.md | none needed (git) | skip (none)>

Execution order:
  1. CLAUDE.md skeleton    (only if context-build skipped AND no CLAUDE.md)
  2. /context-build        (if requested)
  3. Seed CLAUDE.md prose  (if requested)
  4. Inject VCS section    (if non-git VCS)
  5. AGENTS.md             (if requested)
  6. /task-setup           (if requested)
  7. Commit own artifacts  (CLAUDE.md edits from 3-4 + AGENTS.md)
```

End with: **"Approve and run?"**

Wait for explicit approval. Silence is not approval. Iterate and re-present
the full plan after any change.

---

PHASE 3 — EXECUTE (only after explicit approval)

Run the steps in this exact order. Skip any step the user opted out of.
Report each step's result as you go.

### Step 1 — CLAUDE.md skeleton

Only when context-build was SKIPPED and no CLAUDE.md exists yet. Use the
Write tool to create a minimal CLAUDE.md containing just a title and a
one-line "see AGENTS.md / context layer" pointer. (When context-build runs,
it creates CLAUDE.md itself — do not pre-create it here in that case.)

### Step 2 — Context build

If requested, run the `/context-build` workflow. It owns CLAUDE.md's
navigation section and commits its own artifacts. Treat its phases as
authoritative — do not duplicate or override them here. After it finishes,
CLAUDE.md exists and carries the navigation instruction.

### Step 3 — Seed CLAUDE.md with project info

If requested, synthesize the pasted material (and your own reading of the
codebase) into a concise project-information section in CLAUDE.md — what the
project is, its layout, and its key conventions. Synthesize into prose; do
NOT paste the source material verbatim. Place this section so it does not
disturb the navigation instruction context-build added (append below it, or
create the section if CLAUDE.md came only from the Step 1 skeleton).

### Step 4 — Inject the VCS-mapping section

If the chosen VCS is non-git (e.g. Plastic SCM), append a `## VCS` section
to CLAUDE.md that tells any command to substitute the VCS's equivalents for
git commands. For Plastic SCM, write exactly this section (adjust the
heading prose only if a `## VCS` section already exists — then update it in
place rather than duplicating):

```
## VCS

This project uses Plastic SCM, not git. When any command instructs you to
run a git command, substitute the Plastic equivalent:

- `git add -- <paths>`        -> `cm add <paths>`
- `git commit -m "<msg>"`     -> `cm checkin -m "<msg>" <paths>`
- `git status --porcelain`    -> `cm status --machinereadable`
- `git rev-parse --short HEAD`-> report the changeset from `cm log --limit=1`
- `git diff --name-only HEAD` -> `cm diff --format={path}`

Stage and check in only the explicit paths a command names — never a
catch-all. Plastic has no staging area, so the git "add then commit"
two-step maps to a single `cm checkin` of the listed paths.
```

For git, inject nothing — the commands already work as authored. For an
unknown/"none" VCS, skip this step.

### Step 5 — AGENTS.md

If requested, use the Write tool to create AGENTS.md with a minimal pointer:

```
# AGENTS.md

This project's agent and contributor guidance lives in CLAUDE.md. Read
CLAUDE.md first; it is the source of truth for conventions, layout, and
VCS rules.
```

If AGENTS.md already exists, do not clobber it — report that it was left
as-is.

### Step 6 — Task backlog

If requested, run the `/task-setup` workflow. It creates the backlog
scaffolding and offers to commit its own artifacts. Let it manage its own
commit. Because CLAUDE.md is now final (Steps 1-5 done), task-setup's
test-runner inference and convention reading see the completed file.

### Step 7 — Commit own artifacts

Commit ONLY the artifacts this command wrote directly: the CLAUDE.md edits
from Steps 3-4 (the project-info section and the VCS section) and AGENTS.md
from Step 5. The Step 1 skeleton is included only if context-build did not
run (otherwise context-build already committed CLAUDE.md). Do NOT re-commit
anything `/context-build` or `/task-setup` already committed.

Use the chosen VCS:
- **git:**
  ```
  git add -- CLAUDE.md AGENTS.md        # only the paths actually written
  git commit -m "Configure project via /project-setup"
  ```
- **Plastic SCM:**
  ```
  cm add CLAUDE.md AGENTS.md            # only paths not already controlled
  cm checkin -m "Configure project via /project-setup" CLAUDE.md AGENTS.md
  ```
- **none:** skip the commit; report the written files as left uncommitted.

Stage only the explicit paths this command wrote. Never use `git add -A`,
`git add .`, `git add -u`, or a Plastic catch-all. If the commit fails
(e.g. a pre-commit hook), surface the exact output, do not retry, do not
use `--no-verify` or `--amend`, and tell the user the files are left in
place.

On success, report the resulting commit hash / changeset number plus a
summary of every step's outcome and any suggested next steps (e.g.
`/task-add` once the backlog is initialized).

---

DO NOT:
- Write to any file before PHASE 3 (after explicit approval).
- Reimplement `/context-build` or `/task-setup` — invoke their workflows.
- Re-commit artifacts a sub-command already committed.
- Paste user-provided documentation verbatim into CLAUDE.md — synthesize it.
- Inject a VCS section for a git project.
- Clobber an existing AGENTS.md or an existing CLAUDE.md project-info /
  VCS section — update in place, never duplicate.
- Use `git add -A`, `git add .`, `git add -u`, or a Plastic catch-all in
  Step 7 — only the explicit paths this command wrote.
- Use `--amend`, `--no-verify`, `--no-gpg-sign`, or any hook-skipping flag.
- Push, branch, tag, or otherwise touch shared/visible VCS state.
