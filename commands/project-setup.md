---
name: project-setup
version: 0.5.0
type: command
description: Interactive first-time project initialization wizard. Gathers all choices upfront (VCS, CLAUDE.md content, AGENTS.md, task backlog, context layer), confirms once, then executes them in a fixed order. Orchestrates /task-setup and /context-build; injects a VCS-mapping section into CLAUDE.md for non-git projects (e.g. Plastic SCM). On Unity projects, also injects a "Tasks implementation" section into CLAUDE.md covering editor dirty-tree noise handling (with a self-updating known-noise-files list maintained by future sessions) and, when the project has no test suite, the permanent skip-tests testing-policy marker for /task-implement, and offers to run /unity-mcp-setup (as the last step, after the context layer) to wire up MCP-assisted task implementation. Authoring command — leaves all output uncommitted for one review pass by default; pass --commit to commit its own artifacts and delegate --commit to the nested commands.
---

# /project-setup
# Global command: a single entry point for initializing a project with the
# chosko-llm tooling. Two phases: a conversational GATHER phase that collects
# every choice upfront, then a silent EXECUTE phase that applies them in a
# fixed order with no further questions.
# Usage: /project-setup
# Usage with hint: /project-setup "source lives under lib/, we use Plastic"
# Usage with commit: /project-setup --commit
#   (commit the wizard's own artifacts, and run the sub-commands with --commit)

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

COMMIT POLICY — project-setup is an AUTHORING command. By DEFAULT (no
`--commit`) it NEVER commits anything: every file it writes — and everything
the sub-commands it invokes write — is left UNCOMMITTED in the working tree
for the user to review and commit in one pass at the end. This matches the
other authoring commands (`/context-build`, `/context-update`,
`/task-enrich`, the `/refactor-*` commands), all of which leave their output
for review. The generated CLAUDE.md prose in particular is synthesized from
the user's pasted material and deserves a human read before it lands in
history.

With `--commit`, project-setup commits its OWN artifacts (the CLAUDE.md
seeding + VCS section, AGENTS.md) first, then runs the nested commands WITH
`--commit` so each commits its own output (`/task-setup --commit`,
`/context-build --commit`). The result is a small series of focused commits
rather than one uncommitted working tree. `--commit` and `--no-commit` are
mutually exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`

VCS detection exists for ONE purpose only: deciding whether to inject the
VCS-mapping section into CLAUDE.md (that section maps git→`cm` for the
committing commands under a non-git VCS). When `--commit` is used, the
wizard's own commit — and the sub-commands' — honor that same `## VCS`
mapping. Without `--commit`, project-setup runs no VCS command at all.

ORDERING PRINCIPLE — the wizard does its OWN fast, deterministic work first,
THEN runs the heavy sub-commands last:

- The wizard's own artifacts (CLAUDE.md seeding, VCS section, AGENTS.md) rely
  only on what the user provides and are written before any sub-command runs.
- `/task-setup` runs next — it is mechanical and low-context. It leaves its
  scaffolding uncommitted by default; under `--commit` the wizard passes
  `--commit` through so it commits its own scaffolding (see Step 5).
- `/context-build` runs LAST. It is the most context-hungry command and has
  its own interactive STOP-and-approve gates, so it could otherwise capture
  the run and strand the wizard's later steps. Running it last guarantees the
  wizard's other steps have already executed before context-build starts. It
  leaves its output uncommitted by default; under `--commit` the wizard
  passes `--commit` through so it commits its own output (see Step 6).

CLAUDE.md seeding relies ONLY on material the user supplies — pasted docs,
README excerpts, notes. The wizard does NOT read the codebase to synthesize
project info; codebase-derived structure is context-build's job, and it runs
later. If the user supplies nothing, the seeding step is a no-op.

The flow is strictly: GATHER (ask everything) → CONFIRM (one approval) →
EXECUTE (apply in order) → commit-or-review-reminder.

Never write to any file before the user confirms the gathered plan.

$ARGUMENTS

ARGUMENT NOTE — scan $ARGUMENTS for the optional `--commit` flag. If present,
set COMMIT = true and strip it (any remaining text is a structure/VCS hint).
`--commit` and `--no-commit` are mutually exclusive — if both appear, stop
with: `--commit and --no-commit cannot be combined. Pick one.` COMMIT drives
the commit behavior described in COMMIT POLICY above and PHASE 3 below.

---

PHASE 1 — GATHER (conversational; no files written)

This command shells out for exactly two things: read-only VCS detection in
this phase, and — ONLY when `--commit` was passed — the commit step in
PHASE 3 (`git add -- <paths>` / `git commit`, or the `## VCS`-mapped
equivalents). Without `--commit`, it never stages, commits, or otherwise
mutates VCS state.

State this once, upfront, before asking anything. Pick the variant that
matches the flag:

- DEFAULT (no `--commit`):

  > Heads up: this wizard leaves everything it writes UNCOMMITTED. I'll set
  > up the files (and run any sub-commands you choose), then hand the working
  > tree back to you to review and commit in one pass. I won't make any
  > commits myself — the sub-commands I run (task-setup, context-build) leave
  > their output uncommitted too.

- WITH `--commit`:

  > Heads up: you passed --commit, so I'll commit as I go — first my own
  > artifacts (CLAUDE.md seeding, AGENTS.md), then each sub-command commits
  > its own output (task-setup, context-build). You'll get a small series of
  > focused commits rather than one working tree to review.

Then ask the questions below ONE AT A TIME — ask one, wait for the reply,
then ask the next. Do not batch them into a single message or ask the user to
answer them all in one go. Suggest the answer you'd pick so the user can
confirm with a single word. Carry every answer forward into the CONFIRM
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

The chosen VCS drives ONE thing: whether a VCS-mapping section is injected
into CLAUDE.md (injected for any non-git VCS; omitted for git, whose commands
need no override). It does NOT affect committing — project-setup never
commits. If the user picks "none", skip VCS-section injection.

### 1b. Seed CLAUDE.md (from user-provided material only)

> Seed CLAUDE.md with project information? [Y/n]

If **yes**, start an optional iterative input phase — this material is the
ONLY input the seeding step uses; the wizard does not read the codebase to
fill CLAUDE.md:

> Paste or type any documentation, README excerpts, or notes you'd like
> folded into CLAUDE.md. (Whatever you provide is synthesized into concise
> prose, never inserted verbatim.)

After each entry, accumulate it and invite more:

> Added. Keep pasting or typing more, or say "done" when you've finished.

Repeat until the user says "done". Accumulate everything they provided across
the loop. If they say "done" without having provided anything, treat seeding
as declined.

### 1c. AGENTS.md

> Create an AGENTS.md that points other agents at CLAUDE.md? [Y/n]

This is independent of every other choice.

### 1d. Task backlog

> Initialize the task backlog now (runs /task-setup)? [Y/n]

If yes, note that task-setup leaves its scaffolding uncommitted by default —
its files sit in the working tree with everything else for one review pass.
Under `--commit`, the wizard runs `/task-setup --commit` so it commits its
own scaffolding.

### 1e. Context layer

> Build the navigation context layer now (runs /context-build)? [Y/n]

Note for the user: context-build runs LAST and has its own approval gates —
it will pause for input during its phases, and it leaves its output
uncommitted for you to review afterward. Under `--commit`, the wizard runs
`/context-build --commit` so it commits its own output.

### 1f. Unity projects — tasks-implementation section

Probe read-only for Unity: `ProjectSettings/ProjectVersion.txt` exists →
Unity project. If it is NOT a Unity project, skip this subsection entirely
and ask nothing.

If it IS a Unity project, tell the user a `## Tasks implementation` section
will be added to CLAUDE.md — it teaches /task-implement how to handle
Unity's editor dirty-tree noise; the noise guidance is generic and the
project-specific list grows on its own as later sessions notice recurring
noise files. Ask ONE thing:

> Does this project have a test suite /task-implement should run? [y/N]

If **no**, the section will carry the permanent skip-tests
testing-policy marker (see Step 3b).

Then, still only on Unity projects, offer to set up Unity MCP:

> Set up Unity MCP now so /task-implement can drive the Unity editor at
> manual checkpoints instead of pausing for you (runs /unity-mcp-setup)?
> [Y/n]

Note for the user: /unity-mcp-setup runs as the LAST step (after the context
layer, if you build one, so it can add a context doc), it's idempotent, and
it will need the Unity Editor open to verify the connection. This wizard
only offers and delegates — all the MCP logic lives in /unity-mcp-setup.

That's the full set of questions. Keep it to these — do not improvise extra
prompts. If $ARGUMENTS carried hints (e.g. "we use Plastic", "source under
lib/"), apply them to pre-fill the relevant defaults and say so.

---

PHASE 2 — CONFIRM (present the full plan, one approval)

Render every gathered choice and the exact EXECUTE order in one message:

The header and closing line depend on COMMIT. Without `--commit` use the
"nothing is committed" wording shown; with `--commit` say
"commits as it goes" in the header and replace the closing line with
"Each step commits its own output — you'll get a series of focused commits."

```
PLAN — project setup     (nothing is committed; all output left for review)

Commit mode:    <off — leave everything for review | on (--commit) — commit each step>
VCS:            <git | Plastic SCM | none>
Seed CLAUDE.md: <yes, synthesizing N pasted source(s) | skip>
VCS section:    <inject Plastic mapping into CLAUDE.md | none needed (git) | skip (none)>
Unity section:  <inject Tasks-implementation section (skip-tests policy: yes/no) | n/a (not a Unity project)>
Unity MCP:      <set up via /unity-mcp-setup (runs last) | skip | n/a (not a Unity project)>
AGENTS.md:      <create | skip>
Task backlog:   <initialize via /task-setup | skip>
Context layer:  <build via /context-build (runs last) | skip>

Execution order:
  -- wizard's own artifacts --
  1. CLAUDE.md skeleton    (only if CLAUDE.md missing AND step 2, 3, or 3b needs it)
  2. Seed CLAUDE.md prose  (if requested; from pasted material only)
  3. Inject VCS section    (if non-git VCS)
  3b. Tasks-implementation section (Unity projects only)
  4. AGENTS.md             (if requested)
  4c. Commit own artifacts (only with --commit; commits steps 1-4)
  -- heavy sub-commands, last --
  5. /task-setup           (if requested; --commit passed through when set)
  6. /context-build        (if requested; interactive; --commit passed through when set)
  7. /unity-mcp-setup      (Unity + if requested; runs after context-build; --commit passed through when set)

All changes are left UNCOMMITTED for you to review and commit in one pass.
(With --commit: each step commits its own output as a focused commit.)
```

End with: **"Approve and run?"**

Wait for explicit approval. Silence is not approval. Iterate and re-present
the full plan after any change.

---

PHASE 3 — EXECUTE (only after explicit approval)

Run the steps in this exact order. Skip any step the user opted out of.
Report each step's result as you go. Steps 1-4 are the wizard's own work;
Steps 5-6 are the heavy sub-commands. Without `--commit`, nothing is
committed at any step — everything is left in the working tree for the final
review. With `--commit`, Step 4c commits the wizard's own artifacts and the
sub-commands are invoked WITH `--commit` so they commit their own output.

### Step 1 — CLAUDE.md skeleton

Only when CLAUDE.md does not exist yet AND a later wizard step needs to write
to it (seeding requested, a VCS section will be injected, or a Unity
tasks-implementation section will be injected). Use the Write
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

This project uses Plastic SCM, not git.

**This section OVERRIDES literal git commands.** Any command, skill, or
instruction you follow in this project that names a git command is to be
read as naming its Plastic equivalent below — even when it spells the git
command out verbatim, and even when it does not mention this section. Never
run `git` here.

- `git add -- <paths>`        -> `cm add <paths>`
- `git commit -m "<msg>"`     -> `cm checkin -m "<msg>" <paths>`
- `git status --porcelain`    -> `cm status --machinereadable`
- `git rev-parse --short HEAD`-> report the changeset from `cm log --limit=1`
- `git diff --name-only HEAD` -> `cm diff --format={path}`
- `git log --after="<date>" --name-only --pretty=format:` -> `cm find revision "where date >= '<date>'" --format="{item}" | sort -u`

Stage and check in only the explicit paths a command names — never a
catch-all. Plastic has no staging area, so the git "add then commit"
two-step maps to a single `cm checkin` of the listed paths: an instruction
to stage is not a separate command here, it selects which paths the later
check-in names.
```

For git, inject nothing — the commands already work as authored. For an
unknown/"none" VCS, skip this step.

### Step 3b — Inject the Tasks-implementation section (Unity projects only)

Skip this step entirely when the project is not Unity (GATHER 1f). For a
Unity project, append a `## Tasks implementation` section to CLAUDE.md (if
one already exists, update it in place rather than duplicating). This
section is the PERMANENT home for /task-implement guidance in this project
— later notes such as the testing-policy marker belong here, not in a new
section.

Write the section from this template. The text is fixed — the only part
to adapt is `<commit|checkin>`:

```
## Tasks implementation

When implementing tasks using the `/task-implement` command, consider the
following:

- Unity tends to change files even when no explicit operation is made by
  the user, so a dirty working tree is normal. The noise forms a
  recognizable family that sits permanently modified in the workspace —
  typical members are editor-regenerated caches such as
  `Assets/Plugins/FMOD/Cache/Editor/FMODStudioCache.asset` (touched
  almost every editor session) and regenerated TextMesh Pro font SDF
  atlases (the exact variants drift between sessions as atlases
  regenerate). During the pre-flight `Working-tree check`, don't stop
  for these: if no unfinished task is detected among the changed files,
  choose `proceed` automatically and just write a warning to the user.
  Leave the noise files exactly as they are — never bundle them into a
  task's <commit|checkin>, and don't re-ask about them on dirty-tree
  prompts. Exception: assets newly integrated *for* a task (e.g. a new
  font family added while building a UI) are real task content and DO
  go into that task's <commit|checkin>.
- Known noise files in this project — keep this list updated: whenever
  a session notices a file that repeatedly shows up modified without any
  task touching it, add it here so future sessions don't have to
  re-discover it:
  - (none recorded yet)
```

Use the VCS vocabulary chosen in 1a for `<commit|checkin>` — "commit" for
git, "checkin" for Plastic SCM. Do not ask the user for noise files and do
not pre-fill the list — it starts empty by design and is maintained by
future sessions per the instruction embedded in the section itself.

If the user answered **no test suite** in GATHER 1f, end the section with
the testing-policy marker — the phrase must match EXACTLY what
/task-implement scans for — followed by the human-readable sentence:

```
Testing policy for /task-implement: skip-tests

This project has no test suite. Skip the test phases by default without
asking for confirmation.
```

If the user answered yes (a test suite exists), write no testing-policy
line — /task-implement will detect the runner as usual.

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

### Step 4c — Commit the wizard's own artifacts (only with `--commit`)

Run this step ONLY when `--commit` was passed. Stage EXACTLY the files
Steps 1-4 wrote — CLAUDE.md (the skeleton, seeded prose, injected `## VCS`
section, and/or Unity `## Tasks implementation` section) and AGENTS.md, as
applicable — and make one commit:

```
git add -- <CLAUDE.md and/or AGENTS.md, only the files actually written>
git commit -m "Initialize project with chosko-llm scaffolding"
```

If Steps 1-4 wrote nothing (e.g. CLAUDE.md already complete, AGENTS.md
already present), make no commit. Stage only the explicit paths written —
never a catch-all (`git add -A`/`.`/`-u`). On a non-git VCS, use the
`## VCS` mapping (git→`cm`). On commit failure (e.g. a pre-commit hook),
surface the output; do NOT retry, amend, or use hook-skipping flags. Without
`--commit`, skip this step entirely.

### Step 5 — Task backlog

If requested, run the `/task-setup` workflow. It creates the backlog
scaffolding. Without `--commit` it leaves the scaffolding uncommitted with
everything else; with `--commit`, invoke it as `/task-setup --commit` so it
commits its own scaffolding. Because CLAUDE.md is already written (Steps
1-4), task-setup's convention reading sees the completed file.

### Step 6 — Context build (LAST)

If requested, run the `/context-build` workflow. Run it LAST and treat its
phases as authoritative — it has its own STOP-and-approve gates that pause
for user input; honor them, do not flatten them. It creates CLAUDE.md if
missing and adds its navigation instruction at the top (additive to anything
Steps 1-2 wrote). Without `--commit` its output stays uncommitted; with
`--commit`, invoke it as `/context-build --commit` so it commits its own
output.

### Step 7 — Unity MCP setup (Unity projects only; runs after context-build)

Run this step ONLY on a Unity project AND only if the user opted in at
GATHER 1f. Invoke the `/unity-mcp-setup` workflow. It runs AFTER
`/context-build` on purpose: if the user built a context layer in this run,
it now exists, so `/unity-mcp-setup` can add its `.claude/context/mcp-tools.md`
doc and INDEX row. This wizard does NOT reimplement any of that logic — it
delegates entirely to `/unity-mcp-setup`, which is idempotent and interactive
(it may pause for the user to open the Unity Editor so the connection can be
verified). Without `--commit`, `/unity-mcp-setup` leaves its versioned
artifacts uncommitted with everything else; with `--commit`, invoke it as
`/unity-mcp-setup --commit` so it commits its own versioned artifacts (its
machine-local `claude mcp add` registration is never committed either way).

### Final report

Summarize every step's outcome and the files written by each (the wizard's
own artifacts, task-setup's scaffolding if run, context-build's output if
run). Then, depending on COMMIT:
- Without `--commit`: remind the user that NOTHING was committed — the entire
  working tree is theirs to review and commit in one pass. Suggest next steps
  (e.g. review the synthesized CLAUDE.md prose, then commit; `/task-add` once
  the backlog is committed).
- With `--commit`: list the commits made (Step 4c's own-artifacts commit, plus
  each sub-command's commit) with their short hashes, and note that the
  synthesized CLAUDE.md prose is worth a post-hoc review even though it was
  committed.

---

DO NOT:
- Write to any file before PHASE 3 (after explicit approval).
- Commit, stage, or otherwise mutate VCS state UNLESS `--commit` was passed.
  By default project-setup makes NO commits; everything it and its
  sub-commands write is left uncommitted. With `--commit`, commit only the
  explicit paths each step wrote — never a catch-all — and never push,
  branch, tag, or use hook-skipping flags.
- Reimplement `/context-build`, `/task-setup`, or `/unity-mcp-setup` —
  invoke their workflows.
- Run `/context-build` before Step 6 — the heavy sub-commands run last.
- Offer or run `/unity-mcp-setup` on a non-Unity project, or run it before
  `/context-build` — it is Unity-only and runs after the context layer (Step 7).
- Read the codebase to seed CLAUDE.md — seeding uses ONLY user-pasted
  material; codebase structure is context-build's job.
- Paste user-provided documentation verbatim into CLAUDE.md — synthesize it.
- Inject a VCS section for a git project.
- Clobber an existing AGENTS.md or an existing CLAUDE.md project-info /
  VCS / Tasks-implementation section — update in place, never duplicate.
- Inject the Tasks-implementation section into a non-Unity project.
