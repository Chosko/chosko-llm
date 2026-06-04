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
optionally seed CLAUDE.md with project information (and an AGENTS.md
pointer), inject a VCS-mapping section so the other chosko-llm commands work
under non-git VCS, optionally initialize the task backlog, and optionally
build the navigation context layer.

This command ORCHESTRATES the existing commands — it does not reimplement
them. `/context-build` and `/task-setup` remain independently usable; this
wizard runs their logic on the user's behalf and adds two artifacts of its
own (the CLAUDE.md project-info + VCS sections and AGENTS.md).

ORDERING PRINCIPLE — the wizard does its OWN deterministic work first and
commits it atomically, THEN runs the heavy sub-commands last:

- The wizard's own artifacts (CLAUDE.md seeding, VCS section, AGENTS.md) are
  fast, deterministic, and rely only on what the user provides. They are
  written and committed BEFORE any sub-command runs.
- `/task-setup` runs next — it is mechanical and low-context.
- `/context-build` runs LAST. It is the most context-hungry command and has
  its own interactive STOP-and-approve gates, so it could otherwise capture
  the run and strand the wizard's later steps. Running it last guarantees the
  wizard's irreplaceable work is already on disk and committed before
  context-build starts. context-build has NO commit phase of its own; it
  leaves its output for the user to review and commit, exactly as it does
  standalone.

CLAUDE.md seeding relies ONLY on material the user supplies — pasted docs,
README excerpts, notes. The wizard does NOT read the codebase to synthesize
project info; codebase-derived structure is context-build's job, and it runs
later. If the user supplies nothing, the seeding step is a no-op.

The flow is strictly: GATHER (ask everything) → CONFIRM (one approval) →
EXECUTE (apply in order) → COMMIT (own artifacts only) → run sub-commands.

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

### 1b. Seed CLAUDE.md (from user-provided material only)

> Seed CLAUDE.md with project information? [Y/n]

If **yes**, invite the source material — this is the ONLY input the seeding
step uses; the wizard does not read the codebase to fill CLAUDE.md:

> Paste the documentation, README excerpts, or notes you'd like folded into
> CLAUDE.md. (Whatever you paste is synthesized into concise prose, never
> inserted verbatim. If you paste nothing, I'll skip seeding — the context
> layer in step 1d can populate codebase structure instead.)

Capture whatever they paste. If they paste nothing, treat seeding as
declined.

### 1c. AGENTS.md

> Create an AGENTS.md that points other agents at CLAUDE.md? [Y/n]

This is independent of every other choice.

### 1d. Task backlog

> Initialize the task backlog now (runs /task-setup)? [Y/n]

### 1e. Context layer

> Build the navigation context layer now (runs /context-build)? [Y/n]

Note for the user: context-build runs LAST and has its own approval gates —
it will pause for input during its phases, and it leaves its output for you
to review and commit afterward.

That's the full set of questions. Keep it to these — do not improvise extra
prompts. If $ARGUMENTS carried hints (e.g. "we use Plastic", "source under
lib/"), apply them to pre-fill the relevant defaults and say so.

---

PHASE 2 — CONFIRM (present the full plan, one approval)

Render every gathered choice and the exact EXECUTE order in one message:

```
PLAN — project setup

VCS:            <git | Plastic SCM | none>   (commit via <git|cm|—>)
Seed CLAUDE.md: <yes, synthesizing N pasted source(s) | skip>
VCS section:    <inject Plastic mapping into CLAUDE.md | none needed (git) | skip (none)>
AGENTS.md:      <create | skip>
Task backlog:   <initialize via /task-setup | skip>
Context layer:  <build via /context-build (runs last) | skip>

Execution order:
  -- wizard's own artifacts, committed atomically --
  1. CLAUDE.md skeleton    (only if CLAUDE.md missing AND step 2 or 3 needs it)
  2. Seed CLAUDE.md prose  (if requested; from pasted material only)
  3. Inject VCS section    (if non-git VCS)
  4. AGENTS.md             (if requested)
  5. Commit own artifacts  (CLAUDE.md edits from 2-3 + AGENTS.md)
  -- heavy sub-commands, last --
  6. /task-setup           (if requested; commits its own scaffolding)
  7. /context-build        (if requested; interactive; left uncommitted for
                            your review)
```

End with: **"Approve and run?"**

Wait for explicit approval. Silence is not approval. Iterate and re-present
the full plan after any change.

---

PHASE 3 — EXECUTE (only after explicit approval)

Run the steps in this exact order. Skip any step the user opted out of.
Report each step's result as you go. Steps 1-5 are the wizard's own work and
are committed together at Step 5. Steps 6-7 are the heavy sub-commands and
run afterward.

### Step 1 — CLAUDE.md skeleton

Only when CLAUDE.md does not exist yet AND a later wizard step needs to write
to it (seeding requested, or a VCS section will be injected). Use the Write
tool to create a minimal CLAUDE.md containing just a title and a one-line
"see AGENTS.md / the context layer" pointer. If CLAUDE.md already exists, do
nothing here. If nothing in Steps 2-3 will write to CLAUDE.md and it is
missing, also do nothing — context-build (Step 7) will create it if the user
asked for the context layer.

### Step 2 — Seed CLAUDE.md with project info (user material only)

If requested, synthesize ONLY the material the user pasted in GATHER 1b into
a concise project-information section in CLAUDE.md — what the project is, its
layout, its key conventions. Synthesize into prose; do NOT paste the source
material verbatim, and do NOT read the codebase to invent content here
(codebase structure is context-build's job in Step 7). If the user pasted
nothing, skip this step.

### Step 3 — Inject the VCS-mapping section

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

### Step 4 — AGENTS.md

If requested, use the Write tool to create AGENTS.md with a minimal pointer:

```
# AGENTS.md

This project's agent and contributor guidance lives in CLAUDE.md. Read
CLAUDE.md first; it is the source of truth for conventions, layout, and
VCS rules.
```

If AGENTS.md already exists, do not clobber it — report that it was left
as-is.

### Step 5 — Commit the wizard's own artifacts

Commit ONLY the artifacts this command wrote directly in Steps 1-4: the
CLAUDE.md skeleton/seeding/VCS edits and AGENTS.md. This commit happens
BEFORE the heavy sub-commands run, so the wizard's irreplaceable work is
captured atomically regardless of what happens in Steps 6-7.

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
`git add .`, `git add -u`, or a Plastic catch-all. If nothing was written in
Steps 1-4 (e.g. git VCS, no seeding, no AGENTS.md), skip the commit. If the
commit fails (e.g. a pre-commit hook), surface the exact output, do not
retry, do not use `--no-verify` or `--amend`, and tell the user the files
are left in place. Report the resulting commit hash / changeset number.

### Step 6 — Task backlog

If requested, run the `/task-setup` workflow. It creates the backlog
scaffolding and offers to commit its own artifacts — let it manage its own
commit. Because CLAUDE.md is already final and committed (Steps 1-5),
task-setup's convention reading sees the completed file.

### Step 7 — Context build (LAST)

If requested, run the `/context-build` workflow. Run it LAST and treat its
phases as authoritative — it has its own STOP-and-approve gates that pause
for user input; honor them, do not flatten them. It creates CLAUDE.md if
missing and adds its navigation instruction at the top (additive to anything
Steps 1-2 wrote).

context-build has NO commit phase. When it finishes, its output (the
`.claude/context/` files and the CLAUDE.md navigation edit) is left
UNCOMMITTED — exactly as context-build behaves standalone. Do NOT fold it
into the Step 5 commit (which already happened) and do NOT auto-commit it
here; tell the user to review context-build's report and commit its output
themselves.

### Final report

Summarize every step's outcome: the Step 5 commit hash/changeset (if any),
task-setup's result and commit (if run), and context-build's result with a
reminder that its output is uncommitted and awaiting review. Suggest next
steps (e.g. `/task-add` once the backlog is initialized; commit the context
layer once reviewed).

---

DO NOT:
- Write to any file before PHASE 3 (after explicit approval).
- Reimplement `/context-build` or `/task-setup` — invoke their workflows.
- Run `/context-build` before Step 5 — it runs LAST, after the wizard's own
  artifacts are committed.
- Auto-commit `/context-build`'s output — it has no commit phase; leave it
  for the user to review and commit.
- Re-commit artifacts `/task-setup` already committed.
- Read the codebase to seed CLAUDE.md — seeding uses ONLY user-pasted
  material; codebase structure is context-build's job.
- Paste user-provided documentation verbatim into CLAUDE.md — synthesize it.
- Inject a VCS section for a git project.
- Clobber an existing AGENTS.md or an existing CLAUDE.md project-info /
  VCS section — update in place, never duplicate.
- Use `git add -A`, `git add .`, `git add -u`, or a Plastic catch-all in
  Step 5 — only the explicit paths this command wrote.
- Use `--amend`, `--no-verify`, `--no-gpg-sign`, or any hook-skipping flag.
- Push, branch, tag, or otherwise touch shared/visible VCS state.
