---
name: project-setup
version: 0.10.2
type: command
description: Interactive first-time project initialization wizard — gathers every choice up front (VCS, CLAUDE.md content, AGENTS.md, task backlog, domain layer, context layer), confirms once, then runs /task-setup, /domain-setup and /context-build in a fixed order. Use it once, on a project the chosko-llm tooling has not been set up on yet.
disable-model-invocation: true
requires: skill:interaction-engine
---

# /project-setup
# Global command: a single entry point for initializing a project with the
# chosko-llm tooling. Two phases: a conversational GATHER phase that collects
# every choice upfront, then a silent EXECUTE phase that applies them in a
# fixed order with no further questions. Runs /task-setup, then
# /domain-setup (before the context layer, since context files
# cross-reference domain docs), then /context-build in its default flat
# layout — never nested; /context-convert restructures a layer later.
# Injects a VCS-mapping section into CLAUDE.md for non-git projects (e.g.
# Plastic SCM), and a "Tasks implementation" section carrying the
# testing-policy line for /task-implement when one is chosen (plus editor
# dirty-tree noise handling on Unity projects). Offers the interaction-policy
# line, the shipped claude-md sections and the remote-session-protocol hook.
# Authoring command — leaves all output uncommitted for one review pass
# unless `--commit` is passed.
# Usage: /project-setup
# Usage with hint: /project-setup "source lives under lib/, we use Plastic"
# Usage with commit: /project-setup --commit
#   (commit and push the wizard's own artifacts, and run the sub-commands with --commit)
# Usage without push: /project-setup --commit --no-push
#   (commit locally only — forwarded to the sub-commands too)
# Usage with a policy: /project-setup --attended | --unattended
#   (forwarded to the sub-commands too)

GOAL
Walk a first-time user through configuring this project: detect the VCS;
optionally seed CLAUDE.md with project information (and an AGENTS.md
pointer); inject a VCS-mapping section so the other chosko-llm commands work
under a non-git VCS; optionally initialize the task backlog, the domain
knowledge layer and the navigation context layer.

Orchestrate existing features; never reimplement them. The `/context-build`
SKILL, `/task-setup` and `/domain-setup` stay independently usable — run
their logic on the user's behalf. The wizard's own artifacts are the
CLAUDE.md project-info, VCS, Tasks-implementation and interaction-policy
lines and sections, and AGENTS.md; it installs the claude-md sections and the
hook the user picks through `chosko-llm add --local`.

Flow, strictly: GATHER (ask everything) → CONFIRM (one approval) → EXECUTE
(apply in order) → commit-or-review-reminder. Write no file before the user
confirms the gathered plan.

$ARGUMENTS

ARGUMENT NOTE — scan $ARGUMENTS for flags, strip each one found; any
remaining text is a structure/VCS hint.
- `--commit` → set COMMIT = true. COMMIT drives COMMIT POLICY and PHASE 3
  below.
- `--commit` with `--no-commit` → stop with:
  `--commit and --no-commit cannot be combined. Pick one.`
- `--no-push` → set NO_PUSH = true. It matters only when COMMIT is true: it
  skips the pull at start and Step 4c's pre-push re-sync and push, and is
  forwarded to every nested command invoked with `--commit`.
- Pull at start: when COMMIT is true, NO_PUSH is not set, and the chosen VCS
  is git (not a non-git `## VCS` exemption), run `git pull` on the current
  branch before PHASE 2 (EXECUTE) begins. On a conflict, stop the run there:
  report the conflict output and tell the user to resolve manually and
  re-run.
- `--attended` / `--unattended` → resolve the run's interaction policy from
  them, a policy handed down by a parent run and the project's `CLAUDE.md`,
  per `../skills/interaction-engine/references/policy.md`, which holds their
  argument errors. Hand the resolved policy down to every nested command, as
  its flag.
- Under `unattended`, read
  `../skills/interaction-engine/references/gates.md` — this wizard has no
  parking mechanism, its GATHER questions are real decisions, and a stopped
  run writes nothing.
- Before the first question, read
  `../skills/interaction-engine/references/messages.md`; every question, the
  PHASE 2 plan and the closing report follow it.

COMMIT POLICY — project-setup is an AUTHORING command.
- Default (no `--commit`): commit NOTHING. Leave every file the wizard writes
  — and everything the sub-commands it invokes write — UNCOMMITTED in the
  working tree for the user to review and commit in one pass at the end,
  like the other authoring features (`/context-build`, `/context-convert`,
  the `/refactor-*` commands). The generated CLAUDE.md prose in particular is
  synthesized from the user's pasted material and deserves a human read
  before it lands in history.
- Shell out for exactly two things: read-only VCS detection in PHASE 1, and —
  ONLY with `--commit` — the commit step in PHASE 3 (`git add -- <paths>` /
  `git commit`, or the `## VCS`-mapped equivalents). Without `--commit`,
  never stage, commit, or otherwise mutate VCS state, and run no other VCS
  command at all.
- With `--commit`: commit (and push) the wizard's OWN artifacts (the
  CLAUDE.md seeding + VCS section, AGENTS.md) first, then run the nested
  commands WITH `--commit` so each commits (and pushes) its own output — a
  small series of focused commits (PHASE 3).
- With `--commit --no-push`: every commit in the run is local-only. Step 4c
  skips the pull/re-sync/push cycle, and `--no-push` is forwarded to each
  nested command alongside `--commit` (`/task-setup --commit --no-push`,
  etc.).
- Under a non-git VCS, the wizard's own commit and the sub-commands' honor
  the `## VCS` mapping (including its push exemption).
- Commit only the explicit paths each step wrote — never a catch-all. Never
  force-push, retry a failed push, branch, tag, or use hook-skipping flags.

ORDERING PRINCIPLE — do the wizard's OWN fast, deterministic work first,
THEN run the heavy sub-commands last:
- The wizard's own artifacts (CLAUDE.md seeding, VCS section,
  Tasks-implementation section, interaction-policy line, AGENTS.md, and the
  `chosko-llm add --local` installs) rely only on what the user provides;
  write them before any sub-command runs.
- `/task-setup` runs next (Step 5) — mechanical and low-context.
- `/domain-setup` runs after it and BEFORE `/context-build` (Step 5b) — also
  mechanical and low-context. `/context-build` emits DOMAIN DEPENDENCIES
  sections that link to domain files, so the domain index should already
  exist when it runs.
- `/context-build` runs LAST (Step 6). It is a SKILL, invoked by name,
  `/context-build`. It is the most context-hungry step and has its own
  interactive STOP-and-approve gates, so it could otherwise capture the run
  and strand the wizard's later steps.
- Always build the context layer in its default FLAT layout. Never offer,
  ask about, or pass the `nested` argument — a first-time setup has no basis
  for choosing unit seams, and `/context-convert` can restructure the layer
  later at any time. Never run or offer `/context-convert` — there is no
  layer to convert during a first-time setup.

---

PHASE 1 — GATHER (conversational; no files written)

1. State this once, upfront, before asking anything — pick the variant that
   matches the flag:

   - DEFAULT (no `--commit`):

     > Heads up: this wizard leaves everything it writes UNCOMMITTED. I'll set
     > up the files (and run any sub-commands you choose), then hand the working
     > tree back to you to review and commit in one pass. I won't make any
     > commits myself — the sub-commands I run (task-setup, domain-setup,
     > context-build) leave their output uncommitted too.

   - WITH `--commit`:

     > Heads up: you passed --commit, so I'll commit as I go — first my own
     > artifacts (CLAUDE.md seeding, AGENTS.md), then each sub-command commits
     > its own output (task-setup, domain-setup, context-build). You'll get a
     > small series of
     > focused commits rather than one working tree to review.

2. Ask the questions 1a–1j below ONE AT A TIME — ask one, wait for the
   reply, then ask the next. Never batch them into one message or ask the
   user to answer them all in one go.
3. Suggest the answer you'd pick, so the user can confirm with a single word.
4. If $ARGUMENTS carried hints (e.g. "we use Plastic", "source under lib/"),
   pre-fill the relevant defaults from them and say so.
5. Carry every answer forward into the CONFIRM summary — act on none yet.
6. Ask only these questions — improvise no extra prompts.

### 1a. Detect the VCS

- Probe the working tree (read-only):
  - `.git/` present, or `git rev-parse --is-inside-work-tree` succeeds → git.
  - `.plastic/` present, or a `cm` binary resolves and `cm status` succeeds
    → Plastic SCM.
  - Neither → unknown.
- Report what you found and ask which VCS to configure, with the
  auto-detected one as the default:

  > Detected VCS: <git | Plastic SCM | none>. Configure for this VCS?
  > [Y / specify another]

- The chosen VCS decides whether a VCS-mapping section is injected into
  CLAUDE.md: injected for any non-git VCS, omitted for git (its commands need
  no override), skipped for "none". It maps git→`cm` for the committing
  commands and states that `cm checkin` already syncs to the server, so no
  push cycle ever runs there. Detection serves no other purpose; it does not
  decide whether the wizard commits.

### 1b. Seed CLAUDE.md (from user-provided material only)

> Seed CLAUDE.md with project information? [Y/n]

- If **yes**, start an optional iterative input phase. This material is the
  ONLY input the seeding step uses — never read the codebase to fill
  CLAUDE.md (codebase-derived structure is context-build's job, and it runs
  later):

  > Paste or type any documentation, README excerpts, or notes you'd like
  > folded into CLAUDE.md. (Whatever you provide is synthesized into concise
  > prose, never inserted verbatim.)

- After each entry, accumulate it and invite more:

  > Added. Keep pasting or typing more, or say "done" when you've finished.

- Repeat until the user says "done", accumulating everything across the loop.
  "done" with nothing provided → treat seeding as declined.

### 1c. AGENTS.md

> Create an AGENTS.md that points other agents at CLAUDE.md? [Y/n]

Independent of every other choice.

### 1d. Task backlog

> Initialize the task backlog now (runs /task-setup)? [Y/n]

If yes, note that task-setup leaves its scaffolding uncommitted by default —
its files sit in the working tree with everything else for one review pass.
Under `--commit`, the wizard runs `/task-setup --commit` (plus `--no-push`
if set) so it commits (and pushes) its own scaffolding.

### 1e. Domain knowledge layer

- Probe read-only for an existing `.claude/domain/` (Glob
  `.claude/domain/**/*.md`) and ask the matching variant (default yes):
  - Nothing there yet:

    > Initialize the domain knowledge layer now (runs /domain-setup)? [Y/n]

  - Documents already there:

    > You already have docs under `.claude/domain/`. Index the docs you
    > already have, and add the missing scaffolding around them (runs
    > /domain-setup)? [Y/n]

- Either way, explain in one line: the domain layer holds what the product
  is and why it's built that way — the counterpart to the context layer's
  codebase structure — and `/product-design` and `/architect` both write into
  it, so they need it to exist. `/domain-setup` never touches existing
  documents; it indexes them.
- Note that it runs after the task backlog and BEFORE `/context-build`, and
  leaves its scaffolding uncommitted by default; under `--commit` the wizard
  runs `/domain-setup --commit` (plus `--no-push` if set) so it commits (and
  pushes) its own scaffolding.

### 1f. Context layer

> Build the navigation context layer now (runs /context-build)? [Y/n]

- Ask exactly that — one yes/no question, no layout sub-question.
- Note for the user: context-build runs LAST and has its own approval gates —
  it will pause for input during its phases, and it leaves its output
  uncommitted for you to review afterward. Under `--commit`, the wizard runs
  `/context-build --commit` (plus `--no-push` if set) so it commits (and
  pushes) its own output. It builds the FLAT layout (one `INDEX.md` with every
  context file beside it), which is `/context-build`'s default; if the repo
  later outgrows a single index, `/context-convert` restructures the layer
  into per-unit leaves without rebuilding it.

### 1g. Testing policy

Ask on every project:

> Which testing policy should /task-implement record for this project?
>
> a. none — write no line; /task-implement detects the test runner itself
>    (default)
> b. `full-tdd` — the project has a test suite; always run the tests-first
>    sequence
> c. `skip-tests` — no test suite; implement without tests, confirming
>    before each task
> d. `skip-tests-unattended` — no test suite; implement without tests, no
>    per-task confirmation

A chosen value becomes the testing-policy line of a `## Tasks
implementation` section (Step 3b).

### 1h. Unity projects — editor noise

- Probe read-only for Unity: `ProjectSettings/ProjectVersion.txt` exists →
  Unity project. Not Unity → skip this subsection entirely.
- Unity → tell the user the `## Tasks implementation` section will carry
  guidance on Unity's editor dirty-tree noise; the noise guidance is generic
  and the project-specific list grows on its own as later sessions notice
  recurring noise files. Ask nothing.

### 1i. Interaction policy

> Should interactive chosko-llm features wait for you at their gates
> (`attended`, the default — no line is written) or pass confirmation gates
> on their own and stop at real questions (`unattended`)? [attended /
> unattended]

`unattended` is written as the line `Interaction policy: unattended`
(Step 3c); keeping `attended` writes nothing.

### 1j. CLAUDE.md sections and hook

Offer each shipped claude-md section and the hook, one yes/no each, every
one installed with `chosko-llm add --local` (Step 4b):

> Install these into this project?
>
> - `editing-discipline` — the editing rules for rules documents;
>   `/doc-consolidate` requires it and stops without it [Y/n]
> - `git-commit-style` — the commit-message style [y/N]
> - `tool-usage-policy` — prefer the built-in file tools over shell [y/N]
> - `remote-session-protocol` (hook) — in remote cloud sessions, Claude asks
>   in one numbered text batch instead of a question dialog [y/N]

That's the full set of questions.

---

PHASE 2 — CONFIRM (present the full plan, one approval)

1. Render every gathered choice and the exact EXECUTE order in one message,
   using the block below. Header and closing line depend on COMMIT:
   - Without `--commit`: use the "nothing is committed" wording shown.
   - With `--commit`: say "commits as it goes" in the header and replace the
     closing line with "Each step commits its own output — you'll get a
     series of focused commits."

```
PLAN — project setup     (nothing is committed; all output left for review)

Commit mode:    <off — leave everything for review | on (--commit) — commit and push each step | on --no-push — commit each step locally only>
VCS:            <git | Plastic SCM | none>
Seed CLAUDE.md: <yes, synthesizing N pasted source(s) | skip>
VCS section:    <inject Plastic mapping into CLAUDE.md | none needed (git) | skip (none)>
Testing policy: <none (runner detected) | full-tdd | skip-tests | skip-tests-unattended>
Tasks section:  <inject Tasks-implementation section (testing policy and/or Unity noise) | n/a>
Interaction:    <attended (no line) | unattended (write the line)>
CLAUDE.md sections: <list of claude-md sections to install --local | none>
Hook:           <remote-session-protocol --local | skip>
AGENTS.md:      <create | skip>
Task backlog:   <initialize via /task-setup | skip>
Domain layer:   <initialize via /domain-setup | index existing docs via /domain-setup | skip>
Context layer:  <build via /context-build, flat layout (runs last) | skip>

Execution order:
  -- wizard's own artifacts --
  1. CLAUDE.md skeleton    (only if CLAUDE.md missing AND step 2, 3, 3b, 3c or 4b needs it)
  2. Seed CLAUDE.md prose  (if requested; from pasted material only)
  3. Inject VCS section    (if non-git VCS)
  3b. Tasks-implementation section (if a testing policy was chosen, or a Unity project)
  3c. Interaction-policy line (if unattended)
  4. AGENTS.md             (if requested)
  4b. chosko-llm add --local  (claude-md sections and hook, if any picked)
  4c. Commit and push own artifacts (only with --commit; commits steps 1-4b)
  -- heavy sub-commands, last --
  5. /task-setup           (if requested; --commit [--no-push] passed through when set)
  5b. /domain-setup        (if requested; before context-build; --commit [--no-push] passed through when set)
  6. /context-build        (if requested; interactive; --commit [--no-push] passed through when set)

All changes are left UNCOMMITTED for you to review and commit in one pass.
(With --commit: each step commits its own output as a focused commit, then pushes unless --no-push.)
```

2. End with: **"Approve and run?"** Gate class: `confirmation` — under
   `unattended` it passes on its own, and the closing report names the
   commits or, without `--commit`, the uncommitted files.
3. Wait for explicit approval. Silence is not approval.
4. After any change, iterate and re-present the full plan.

---

PHASE 3 — EXECUTE (only after the PHASE 2 gate is approved or passes on its own)

- Run the steps in this exact order; skip any step the user opted out of.
- Report each step's result as you go.
- Steps 1-4c are the wizard's own work; Steps 5-6 are the heavy
  sub-commands.
- Without `--commit`, commit nothing at any step — leave everything,
  sub-command output included, in the working tree for the final review.
- With `--commit`, Step 4c commits (and pushes) the wizard's own artifacts,
  and each sub-command (Steps 5, 5b, 6) is invoked WITH `--commit` (plus
  `--no-push` if set) — `/task-setup --commit`, `/domain-setup --commit`,
  `/context-build --commit` — so it commits (and pushes) its own output.

### Step 1 — CLAUDE.md skeleton

- Act only when CLAUDE.md does not exist yet AND a later wizard step needs
  it: seeding requested, a VCS section, a Tasks-implementation section or
  the interaction-policy line will be injected, or a claude-md section or
  the hook will be installed (`chosko-llm add --local` refuses without a
  `CLAUDE.md`).
- Then use the Write tool to create a minimal CLAUDE.md containing just a
  title and a one-line "see AGENTS.md / the context layer" pointer.
- CLAUDE.md already exists → do nothing. Missing but nothing in Steps 2-4b
  needs it → also do nothing; context-build (Step 6) will create it if the
  user asked for the context layer.

### Step 2 — Seed CLAUDE.md with project info (user material only)

- If requested, synthesize ONLY the material the user pasted in GATHER 1b
  into a concise project-information section in CLAUDE.md — what the
  project is, its layout, its key conventions.
- Synthesize into prose; never paste the source material verbatim, and
  never read the codebase to invent content here (codebase structure is
  context-build's job in Step 6).
- An existing project-info section is updated in place — never clobbered,
  never duplicated.
- User pasted nothing → skip this step.

### Step 3 — Inject the VCS-mapping section

- Git → inject nothing; the commands already work as authored. Unknown /
  "none" → skip this step.
- Non-git VCS (e.g. Plastic SCM) → append a `## VCS` section to CLAUDE.md
  that tells any command to substitute the VCS's equivalents for git
  commands. For Plastic SCM, write exactly this section. If a `## VCS`
  section already exists, update it in place rather than duplicating (adjust
  the heading prose only then):

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
- `git mv <src> <dst>`        -> `cm move <src> <dst>`
- `git rm <paths>`            -> `cm remove <paths>`
- `git show <rev>:<path>`     -> `cm cat <path>#cs:<changeset>`
- `git branch <name>`         -> `cm branch create <name>`

Stage and check in only the explicit paths a command names — never a
catch-all. Plastic has no staging area, so the git "add then commit"
two-step maps to a single `cm checkin` of the listed paths: an instruction
to stage is not a separate command here, it selects which paths the later
check-in names.

`git push` has no Plastic equivalent, because `cm checkin` already syncs
the changeset to the central server — commands never run a pull/re-sync/push
cycle in this project. Perform the checkin above and stop there.
```

- After injecting it, tell the user in one line that a non-git VCS disables
  parking: `--unattended` is refused by the parking features, and an
  unattended run stops at a question instead of parking.

### Step 3b — Inject the Tasks-implementation section

- Skip this step when GATHER 1g chose no testing policy and the project is
  not Unity (GATHER 1h).
- Otherwise append a `## Tasks implementation` section to CLAUDE.md; if one
  already exists, update it in place rather than duplicating. This section
  is the PERMANENT home for /task-implement guidance in this project — later
  notes belong here, not in a new section.
- Unity project → write the section from this template. The text is fixed;
  adapt only `<commit|checkin>`, using the VCS vocabulary chosen in 1a —
  "commit" for git, "checkin" for Plastic SCM:

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

- Never ask the user for noise files and never pre-fill the list — it starts
  empty by design and future sessions maintain it per the instruction
  embedded in the section itself. Never write the Unity editor-noise bullets
  into a non-Unity project.
- Any other project → the section is the `## Tasks implementation` heading
  alone, followed by the testing-policy line.
- GATHER 1g chose a value → end the section with the testing-policy line —
  the phrase must match EXACTLY what /task-implement scans for — followed by
  the human-readable sentence for that value:

```
Testing policy for /task-implement: <full-tdd | skip-tests | skip-tests-unattended>

<full-tdd:              This project has a test suite. Always run the tests-first sequence.>
<skip-tests:            This project has no test suite. Skip the test phases, confirming before each task.>
<skip-tests-unattended: This project has no test suite. Skip the test phases without asking for confirmation.>
```

- GATHER 1g chose none → write no testing-policy line; /task-implement
  detects the runner itself.

### Step 3c — Interaction-policy line

- Only when GATHER 1i chose `unattended`: add the line
  `Interaction policy: unattended` to CLAUDE.md on its own line, where
  `../skills/interaction-engine/references/policy.md` says it is read;
  update an existing `Interaction policy:` line in place.
- `attended` → write nothing.

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

### Step 4b — Install the claude-md sections and the hook

- Run from the project root, after Step 1 has made sure CLAUDE.md exists.
- For each claude-md section picked at GATHER 1j, run
  `chosko-llm add claude-md:<name> --local`.
- For the hook, run `chosko-llm add hook:remote-session-protocol --local`,
  and relay the `.claude/settings.json` wiring prompt the CLI prints for it
  to the user in the final report. Never edit `settings.json` yourself.
- A failed install → report it and continue the run.

### Step 4c — Commit and push the wizard's own artifacts (only with `--commit`)

Without `--commit`, skip this step entirely. With it (the pull-at-start from
the ARGUMENT NOTE has already run):

1. Stage EXACTLY the files Steps 1-4b wrote — CLAUDE.md (the skeleton,
   seeded prose, injected `## VCS` section, `## Tasks implementation`
   section, interaction-policy line and installed claude-md sections),
   AGENTS.md, and the installed hook script, as applicable — and make one
   commit:

```
git add -- <only the files Steps 1-4b actually wrote>
git commit -m "Initialize project with chosko-llm scaffolding"
```

2. Stage only the explicit paths written — never a catch-all
   (`git add -A`/`.`/`-u`).
3. Steps 1-4b wrote nothing (e.g. CLAUDE.md already complete, AGENTS.md
   already present) → make no commit and no push.
4. Non-git VCS → use the `## VCS` mapping (git→`cm`) and skip the push step
   entirely (per that section's push exemption).
5. On commit success, unless NO_PUSH is true: re-sync with `git pull`
   immediately before pushing — other commits may have landed upstream
   during the run — then `git push`.
6. Push failure or a pre-push conflict → surface the exact output; never
   retry or force-push. The commit exists locally and needs a manual sync +
   push.
7. Commit failure (e.g. a pre-commit hook) → surface the output; never
   retry, amend, or use hook-skipping flags.

### Step 5 — Task backlog

- If requested, run the `/task-setup` workflow; it creates the backlog
  scaffolding.
- CLAUDE.md is already written (Steps 1-4b), so task-setup's convention
  reading sees the completed file.

### Step 5b — Domain layer (before context-build)

- If requested at GATHER 1e, run the `/domain-setup` workflow. It creates
  the domain-layer scaffolding — `.claude/domain/`,
  `.claude/domain/features/`, the domain `INDEX.md`, `.claude/FEATURES.md`,
  and a CLAUDE.md pointer — and, on a project that already has hand-written
  domain docs, indexes them instead of writing an empty index.
- Run it BEFORE Step 6, so that `/context-build` can cross-reference an
  existing domain index — never after `/context-build`.
- Delegate entirely: the wizard holds no domain-layer logic of its own and
  writes no domain-layer artifact itself.

### Step 6 — Context build (LAST)

- If requested, run the `/context-build` skill — LAST, never before this
  step.
- Invoke it with NO layout argument, so it builds its default flat layer and
  stamps `Layout: flat` into the `INDEX.md` it writes. Never pass `nested` /
  `nested=…` from this wizard.
- Treat its phases as authoritative — it has its own STOP-and-approve gates,
  which follow the policy this run hands it; honor them, do not flatten
  them.
- It creates CLAUDE.md if missing and adds its navigation instruction at the
  top (additive to anything Steps 1-2 wrote) — that instruction points at
  `.claude/context/INDEX.md`, which is the entry point in either layout, so
  a later `/context-convert` run will not need to revisit it.

### Final report

- Summarize every step's outcome and the files written by each: the
  wizard's own artifacts, task-setup's scaffolding if run, domain-setup's
  scaffolding if run — naming any pre-existing domain docs it indexed — and
  context-build's output if run.
- Without `--commit`: remind the user that NOTHING was committed — the
  entire working tree is theirs to review and commit in one pass. Suggest
  next steps (e.g. review the synthesized CLAUDE.md prose, then commit;
  `/task-add` once the backlog is committed).
- With `--commit`: list the commits made (Step 4c's own-artifacts commit,
  plus each sub-command's commit) with their short hashes, note whether each
  was pushed (or stayed local-only under `--no-push` / the non-git VCS
  exemption), and note that the synthesized CLAUDE.md prose is worth a
  post-hoc review even though it was committed.
- Either way, when the hook was installed, relay the `.claude/settings.json`
  wiring prompt the CLI printed for it (Step 4b).
- Either way, when the domain layer was set up, suggest the pipeline's entry
  points: `/product-design` to design the product, `/architect` to turn
  features into feature documents.

---

DO NOT:
- Clobber an existing AGENTS.md or an existing CLAUDE.md project-info /
  VCS / Tasks-implementation section — update in place, never duplicate.
