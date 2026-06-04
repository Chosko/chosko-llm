---
name: project-setup
version: 0.1.0
type: command
description: Interactive first-time project initialization wizard. Gathers all choices upfront (VCS, CLAUDE.md content, AGENTS.md, task backlog, context layer), confirms once, then executes them in a fixed order. Orchestrates /task-setup and /context-build; injects a VCS-mapping section into CLAUDE.md for non-git projects (e.g. Plastic SCM). Pure authoring command — makes no commits; leaves all output uncommitted for one review pass.
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

COMMIT POLICY — project-setup is a pure AUTHORING command. It NEVER commits
anything. Every file it writes — and everything the sub-commands it invokes
write — is left UNCOMMITTED in the working tree for the user to review and
commit in one pass at the end. This matches the other authoring commands
(`/context-build`, `/context-update`, `/task-enrich`, the `/refactor-*`
commands), all of which leave their output for review. The generated
CLAUDE.md prose in particular is synthesized from the user's pasted material
and deserves a human read before it lands in history.

Because project-setup makes no commits, it never runs a VCS commit command,
so it works identically under git, Plastic SCM, or any VCS. VCS detection
exists for ONE purpose only: deciding whether to inject the VCS-mapping
section into CLAUDE.md (that section exists for the OTHER commands — the
task-* lifecycle commands that DO commit).

ORDERING PRINCIPLE — the wizard does its OWN fast, deterministic work first,
THEN runs the heavy sub-commands last:

- The wizard's own artifacts (CLAUDE.md seeding, VCS section, AGENTS.md) rely
  only on what the user provides and are written before any sub-command runs.
- `/task-setup` runs next — it is mechanical and low-context. Its built-in
  "commit scaffolding? [y/N]" offer is DECLINED by this wizard so the run
  stays uniformly uncommitted (see Step 6).
- `/context-build` runs LAST. It is the most context-hungry command and has
  its own interactive STOP-and-approve gates, so it could otherwise capture
  the run and strand the wizard's later steps. Running it last guarantees the
  wizard's other steps have already executed before context-build starts.
  context-build has no commit phase of its own anyway.

CLAUDE.md seeding relies ONLY on material the user supplies — pasted docs,
README excerpts, notes. The wizard does NOT read the codebase to synthesize
project info; codebase-derived structure is context-build's job, and it runs
later. If the user supplies nothing, the seeding step is a no-op.

The flow is strictly: GATHER (ask everything) → CONFIRM (one approval) →
EXECUTE (apply in order, no commits) → final review reminder.

Never write to any file before the user confirms the gathered plan.

$ARGUMENTS

---

TOOL DISCIPLINE

- File reads: always use the Read tool. Never use `cat`, `type`,
  `Get-Content`, or any shell command to read file content.
- File writes: use the Edit tool for targeted changes to an existing file;
  use the Write tool only when creating a new file from scratch. Never use
  shell redirection, `tee`, `Set-Content`, or `Out-File`.
- Bash / PowerShell are used for ONE narrow purpose: read-only VCS detection
  in the GATHER phase (see below). This command never stages, commits, or
  otherwise mutates VCS state — it makes no commits at all.

---

PHASE 1 — GATHER (conversational; no files written)

State this once, upfront, before asking anything:

> Heads up: this wizard leaves everything it writes UNCOMMITTED. I'll set up
> the files (and run any sub-commands you choose), then hand the working tree
> back to you to review and commit in one pass. I won't make any commits
> myself — including suppressing the task-setup commit prompt if you enable
> the backlog.

Then ask the questions below in order. Suggest the answer you'd pick so the
user can confirm with a single word. Carry every answer forward into the
CONFIRM summary — do NOT act on any answer yet.

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

The chosen VCS drives ONE thing: whether a VCS-mapping section is injected
into CLAUDE.md (injected for any non-git VCS; omitted for git, whose commands
need no override). It does NOT affect committing — project-setup never
commits. If the user picks "none", skip VCS-section injection.

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

If yes, note that task-setup's own "commit scaffolding?" prompt will be
declined automatically — its files are left uncommitted with everything else.

### 1e. Context layer

> Build the navigation context layer now (runs /context-build)? [Y/n]

Note for the user: context-build runs LAST and has its own approval gates —
it will pause for input during its phases, and it leaves its output
uncommitted for you to review afterward.

That's the full set of questions. Keep it to these — do not improvise extra
prompts. If $ARGUMENTS carried hints (e.g. "we use Plastic", "source under
lib/"), apply them to pre-fill the relevant defaults and say so.

---

PHASE 2 — CONFIRM (present the full plan, one approval)

Render every gathered choice and the exact EXECUTE order in one message:

```
PLAN — project setup     (nothing is committed; all output left for review)

VCS:            <git | Plastic SCM | none>
Seed CLAUDE.md: <yes, synthesizing N pasted source(s) | skip>
VCS section:    <inject Plastic mapping into CLAUDE.md | none needed (git) | skip (none)>
AGENTS.md:      <create | skip>
Task backlog:   <initialize via /task-setup | skip>
Context layer:  <build via /context-build (runs last) | skip>

Execution order:
  -- wizard's own artifacts --
  1. CLAUDE.md skeleton    (only if CLAUDE.md missing AND step 2 or 3 needs it)
  2. Seed CLAUDE.md prose  (if requested; from pasted material only)
  3. Inject VCS section    (if non-git VCS)
  4. AGENTS.md             (if requested)
  -- heavy sub-commands, last --
  5. /task-setup           (if requested; its commit prompt is declined)
  6. /context-build        (if requested; interactive)

All changes are left UNCOMMITTED for you to review and commit in one pass.
```

End with: **"Approve and run?"**

Wait for explicit approval. Silence is not approval. Iterate and re-present
the full plan after any change.

---

PHASE 3 — EXECUTE (only after explicit approval)

Run the steps in this exact order. Skip any step the user opted out of.
Report each step's result as you go. Steps 1-4 are the wizard's own work;
Steps 5-6 are the heavy sub-commands. Nothing is committed at any step —
everything is left in the working tree for the final review.

### Step 1 — CLAUDE.md skeleton

Only when CLAUDE.md does not exist yet AND a later wizard step needs to write
to it (seeding requested, or a VCS section will be injected). Use the Write
tool to create a minimal CLAUDE.md containing just a title and a one-line
"see AGENTS.md / the context layer" pointer. If CLAUDE.md already exists, do
nothing here. If nothing in Steps 2-3 will write to CLAUDE.md and it is
missing, also do nothing — context-build (Step 6) will create it if the user
asked for the context layer.

### Step 2 — Seed CLAUDE.md with project info (user material only)

If requested, synthesize ONLY the material the user pasted in GATHER 1b into
a concise project-information section in CLAUDE.md — what the project is, its
layout, its key conventions. Synthesize into prose; do NOT paste the source
material verbatim, and do NOT read the codebase to invent content here
(codebase structure is context-build's job in Step 6). If the user pasted
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

### Step 5 — Task backlog

If requested, run the `/task-setup` workflow. It creates the backlog
scaffolding. When it reaches its built-in "commit scaffolding? [y/N]" offer,
DECLINE it (answer no) — its files stay uncommitted with everything else, so
the whole run ends in one uniform reviewable state. Because CLAUDE.md is
already written (Steps 1-4), task-setup's convention reading sees the
completed file.

### Step 6 — Context build (LAST)

If requested, run the `/context-build` workflow. Run it LAST and treat its
phases as authoritative — it has its own STOP-and-approve gates that pause
for user input; honor them, do not flatten them. It creates CLAUDE.md if
missing and adds its navigation instruction at the top (additive to anything
Steps 1-2 wrote). context-build has no commit phase; its output stays
uncommitted, exactly as it behaves standalone.

### Final report

Summarize every step's outcome and the files written by each (the wizard's
own artifacts, task-setup's scaffolding if run, context-build's output if
run). Remind the user that NOTHING was committed: the entire working tree is
theirs to review and commit in one pass. Suggest next steps (e.g. review the
synthesized CLAUDE.md prose, then commit; `/task-add` once the backlog is
committed).

---

DO NOT:
- Write to any file before PHASE 3 (after explicit approval).
- Commit, stage, or otherwise mutate VCS state — project-setup makes NO
  commits. Everything it and its sub-commands write is left uncommitted.
- Accept `/task-setup`'s commit offer — decline it so the run stays
  uniformly uncommitted.
- Reimplement `/context-build` or `/task-setup` — invoke their workflows.
- Run `/context-build` before Step 6 — it runs LAST.
- Read the codebase to seed CLAUDE.md — seeding uses ONLY user-pasted
  material; codebase structure is context-build's job.
- Paste user-provided documentation verbatim into CLAUDE.md — synthesize it.
- Inject a VCS section for a git project.
- Clobber an existing AGENTS.md or an existing CLAUDE.md project-info /
  VCS section — update in place, never duplicate.
