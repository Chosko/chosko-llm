# Runbook: runbook-suite-improvements

Created: 2026-09-14 · Source: conversation (pipeline-suggest) · Model: opus
Sequencing: 1–6 plan everything before any code moves, so each later planning step puts earlier task ids on its Preconditions: lines (runbook-inline and runbook-id-filenames edit skills/runbook-run/SKILL.md, which the step-count task also edits; runbook-id-filenames also touches /runbook-describe's resolution). 7–10 implement in dependency order; runbook-id-filenames goes last because it renames bodies and changes resolution in every runbook command.

## [x] 1. Plan the runbook-describe rework (brainstorm)

Depends on: none

Needs: agent+human

Context: none

```prompt
/task-add Rework /runbook-describe (commands/runbook-describe.md)

Read commands/runbook-describe.md and the /runbook-describe section of
.claude/domain/features/runbook-suite.md first.

Problem observed on first real use: /runbook-describe spent a large number
of tokens printing every step's prompt verbatim and pulling in the bodies of
related tasks. That is not what the user wants. /runbook-describe should
describe ONE runbook with moderately more information than /runbook-list
(which gives every runbook in a few words) — a middle ground, not a dump of
the body.

Settled by the user, do not re-open:
- It must not print step prompts verbatim.
- It must not open task bodies (.claude/tasks/*.md).
- The "body included" / "deep read" framing in runbook-suite.md is the
  premise being reversed; the task(s) must carry a dated grant to update
  that section of the domain document accordingly.

Before writing any task, run a short brainstorming round with the user on
the output shape: which per-runbook and per-step facts are worth showing
(e.g. header, Sequencing:, per-step marker/title/Depends on:/Needs:, a
one-line summary of Done: or Context:, Do not re-propose count), and what
the read budget is. Offer a recommended shape so it can be settled in one
answer. Then write the task(s).
```

Done: 5d42edc (pushed to pipeline) — added task 207, a single task (no split). Decisions from the brainstorm and approval: the render is a heading line, one header line (Created/Source/Model), and one line per step (marker, number, title, deps: only when present, needs: only when authored and not agent), plus at most one done: line (sha, short summary, wrong-premise count). Sequencing:, Companion:, Context: and the Do-not-re-propose count are dropped. The command reads the index plus targeted lines from the one body, never a full Read of the body, never task bodies, never other runbooks or the domain/context layers. Needs: inference is removed. Versions: feature 0.1.0 → 0.2.0, root VERSION patch bump. A dated 2026-09-14 grant allows edits to runbook-suite.md on 3 points: the table row, the section and the usage line. Wrong premise: 0.1.0 already forbade printing prompts and never mentioned task bodies. The real cost came from reading the whole body, the Needs: inference, printing Done:/Sequencing:/Context: in full, and no ban on following task ids.

## [x] 2. Plan the step-count flag for /runbook-run

Depends on: none

Context: none

```prompt
/task-add Add a step-count flag to /runbook-run

Read skills/runbook-run/SKILL.md (ARGUMENT NOTE and the selection rules
for --from / --to / --only) first.

Settled by the user, do not re-open:
- A new flag runs a given number of selected steps, then stops.
- It composes with --from (start at step X, run N steps).
- It is refused together with --to or --only, with an explicit error, the
  same way --only with --from/--to is refused today.

Recommended, confirm or adjust while planning: name it --steps N; reaching
the count stops the run the way a --to bound does (not completion, the
runbook stays [PENDING] if steps remain); the count counts steps actually
executed in this run, not steps already [x]; dependencies are never
weakened by it.

Other planned work also edits skills/runbook-run/SKILL.md (an --inline
execution mode and id-prefixed body filenames); those are planned by later
steps and will take Preconditions: on this task, so do not fold them in.
```

Done: b10de3c (pushed) — added task 208, a single task: a --steps N flag. Decisions confirmed by the user: the name is --steps N. It counts steps executed in this run (not [x] steps; a resumed [~] or re-run [!] step counts). Reaching the count stops the run like a --to bound ([PENDING] unless every step is [x]). Fewer than N steps left is not an error. Dependencies are never weakened. It composes with --from only. New argument errors: --steps with --to or --only, and a missing or non-positive value. Versions: skill minor bump (0.8.0 → 0.9.0), root VERSION minor bump. A dated 2026-09-14 grant allows edits to runbook-suite.md on 2 points: the usage block and the selection paragraphs. Scope added beyond the prompt: the /runbook-run row in skills/pipeline-engine/references/routing.md (check-routing.sh must pass), plus docs/reference.md and .claude/context/features.md. .claude/skills/runbook-run/ is an older tracked installed snapshot (0.7.0) that the task says to leave alone; only skills/runbook-run/ is edited. Premise note: SKILL.md has no "ARGUMENT NOTE" section; the ARGUMENTS section is the equivalent.

## [x] 3. Architect runbook-inline (--inline)

Depends on: none

Needs: agent+human

Context: none

```prompt
/architect runbook-inline "Add an --inline option to /runbook-run: execute every selected step in the orchestrating session itself instead of spawning a fresh subagent per step. Opt-in only; the default stays one subagent per step."

Read skills/runbook-run/SKILL.md and .claude/domain/features/runbook-suite.md
first.

Settled by the user, do not re-open: the feature slug is runbook-inline; it
is opt-in via a flag (recommended spelling --inline); the subagent-per-step
default is unchanged.

Questions the design must answer, not assume: how the depth budget and the
spawn relay apply when there is no step subagent (and whether
--relay-spawns becomes meaningless or refused under --inline); what
replaces the fresh-context property between steps; how QUESTIONS FOR USER
is handled when the step runs in the session; whether --model can be
honoured inline or must be refused; that Done: lines, markers and index
status are still written exactly as in the spawned mode.

A step-count flag for /runbook-run (recommended --steps N, composes with
--from, refused with --to/--only) is already planned as a task; the design
must compose with it.
```

Done: 27287f7 (pushed) — wrote .claude/domain/features/runbook-inline.md, added the FEATURES.md entry ([NEW], Source: prompt, Tasks: none) and a domain INDEX row. Decisions approved by the user: --inline changes only how a step is executed (steps 5–6 of the loop) and composes with --from/--to/--only/--steps/--no-commit/--no-push. --relay-spawns and --model are both argument errors beside --inline. The header Model: is not applied, and the opening line says so once. Replacing fresh context: the brief is the authority, the written records win over memory, facts are still propagated, and the opening line discloses the shared context (no cap). The session alternates a bookkeeping phase (today's read/write rules) with an execution phase (never edits the runbook or index). Questions are asked directly in the same fixed block. The inline rules go in a reference file read only under --inline. Markers, Done:, index, commits, resume and the nested-runbook ban are identical. runbook-suite.md was not edited; reconciling it is left to the generated tasks. Premises: none wrong.

## [x] 4. Plan tasks for runbook-inline

Depends on: 2, 3

Context:
- 2026-09-14 (from step 2): the step-count flag task is id 208 (--steps N). It edits skills/runbook-run/SKILL.md and skills/pipeline-engine/references/routing.md. .claude/skills/runbook-run/ is an older installed snapshot (0.7.0), not the source; edit only skills/runbook-run/.
- 2026-09-14 (from step 3): the runbook-inline design (27287f7) says: every generated task preconditions on task 208; task 208's --steps count definition generalises to "executed and reached step 8 as DONE"; the inline rule set lives in a new reference file under skills/runbook-run/references/, read only under --inline; reconciling runbook-suite.md (its never-does-the-work contracts become default-mode contracts) and the pipeline-engine routing row (check-routing.sh) are part of the generated work.

```prompt
/task-add feature=runbook-inline

The step-count flag task for /runbook-run already exists in
.claude/TASKS.md (written earlier in this runbook). Both edit
skills/runbook-run/SKILL.md, and implementation of all planned work happens
only after every plan is written, so sequence across the two by putting the
step-count task's id on the Preconditions: line of every runbook-inline task
that edits skills/runbook-run/SKILL.md, rather than by prose. This
repository has no PLAN.md by design; do not propose one.
```

Done: bb948e0 (pushed) — added tasks 209 and 210. runbook-inline is now [PLANNED] with Tasks: 209, 210. Task 209 is the single implementation task, not split. It covers the --inline flag and its two argument errors (beside --relay-spawns or --model), the inline branch in loop steps 5–6, a new skills/runbook-run/references/inline-contract.md (name chosen by the agent), the broadened --steps count wording, the routing.md row, and the skill minor bump plus VERSION/CHANGELOG. Its Preconditions: is 208 because it edits SKILL.md. Task 210 covers the docs: README, docs/reference.md, the context layer, and dated 2026-09-14 grants to edit runbook-suite.md on 3 points (opening paragraph, orchestrator contracts scoped to the default mode, --inline usage line) and runbook-inline.md on 1 point (the shipped reference path). Its Preconditions: is 209. 209 edits no /architect-owned document. The user approved both grants and the drafts as written. Premises: none wrong; the README Runbooks paragraph was added to 210's scope.

## [ ] 5. Architect runbook-id-filenames

Depends on: none

Needs: agent+human

Context: none

```prompt
/architect runbook-id-filenames "Runbook body files are named with their id prepended, as assigned in .claude/RUNBOOKS.md: .claude/runbooks/<name>.md becomes .claude/runbooks/<id>-<name>.md (e.g. runbook-slug with id 3 becomes 3-runbook-slug.md). Every runbook command that takes a runbook argument resolves it by id alone, by the slug alone (without the id prefix), or by <id>-<slug>."

Read skills/runbook-run/references/runbook-schema.md (§ The store and
§ The index block) and .claude/domain/features/runbook-suite.md first.

Settled by the user, do not re-open: the slug is runbook-id-filenames; the
three accepted argument forms are id, bare slug, and <id>-<slug>; the id is
the one recorded in RUNBOOKS.md.

Questions the design must answer: how the "a bare all-digits argument is an
id, anything else is a name" rule extends to recognise <id>-<slug> without
ambiguity; whether the index File: line changes; which commands and
references need the new resolution (runbook-run, runbook-create --append,
runbook-clean, runbook-describe, runbook-list, pipeline-check / pipeline
engine if they name body paths); how existing body files are migrated.

Migration constraint: this very runbook will still be running when the
implementation lands, and its orchestrator re-reads its body by the old path
to write Done: lines and index status. The migration design must never
rename the body of a runbook that is [RUNNING] (or must otherwise keep an
in-flight run working); state the chosen mechanism explicitly.
```

## [ ] 6. Plan tasks for runbook-id-filenames

Depends on: 1, 2, 4, 5

Context:
- 2026-09-14 (from step 1): the /runbook-describe rework task is id 207.
- 2026-09-14 (from step 2): the step-count flag task is id 208 (--steps N). Besides skills/runbook-run/SKILL.md it edits skills/pipeline-engine/references/routing.md and runbook-suite.md. .claude/skills/runbook-run/ is an older installed snapshot (0.7.0), not the source.
- 2026-09-14 (from step 4): the runbook-inline tasks are 209 and 210. Task 209 edits skills/runbook-run/SKILL.md, adds skills/runbook-run/references/inline-contract.md, and edits routing.md, VERSION and CHANGELOG.md. Task 210 edits runbook-suite.md, runbook-inline.md, README.md, docs/reference.md and .claude/context/features.md + INDEX.md.

```prompt
/task-add feature=runbook-id-filenames

Tasks for the /runbook-describe rework, the /runbook-run step-count flag and
feature runbook-inline already exist in .claude/TASKS.md (written earlier in
this runbook). Implementation of all planned work happens only after every
plan is written, so wherever a runbook-id-filenames task edits a file one of
those tasks also edits (commands/runbook-describe.md,
skills/runbook-run/SKILL.md, runbook-schema.md), put the relevant earlier
task ids on its Preconditions: line rather than sequencing by prose. This
repository has no PLAN.md by design; do not propose one.
```

## [ ] 7. Implement the runbook-describe rework

Depends on: 1

Context:
- 2026-09-14 (from step 1): step 1 created a single task, id 207.

```prompt
/task-implement <the task id(s) step 1 created, as recorded in this step's Context:> -y

If Context: is empty, read step 1's Done: line in
.claude/runbooks/runbook-suite-improvements.md for the ids.
```

## [ ] 8. Implement the step-count flag

Depends on: 2

Context:
- 2026-09-14 (from step 2): step 2 created a single task, id 208.

```prompt
/task-implement <the task id(s) step 2 created, as recorded in this step's Context:> -y

If Context: is empty, read step 2's Done: line in
.claude/runbooks/runbook-suite-improvements.md for the ids.
```

## [ ] 9. Implement runbook-inline tasks

Depends on: 4, 8

Context:
- 2026-09-14 (from step 4): step 4 created tasks 209 (implementation, Preconditions: 208) and 210 (docs, Preconditions: 209).

```prompt
/task-implement <the task ids step 4 created, as recorded in this step's Context:> -y --no-agents

If Context: is empty, read step 4's Done: line in
.claude/runbooks/runbook-suite-improvements.md for the ids.
```

## [ ] 10. Implement runbook-id-filenames tasks

Depends on: 6, 7, 9

Context: none

```prompt
/task-implement <the task ids step 6 created, as recorded in this step's Context:> -y --no-agents

If Context: is empty, read step 6's Done: line in
.claude/runbooks/runbook-suite-improvements.md for the ids. This runbook
(.claude/runbooks/runbook-suite-improvements.md) is [RUNNING] while this
step executes: its body must not be renamed by this step, whatever the
migration does to other runbooks.
```

## Do not re-propose

- Making inline execution the default mode of /runbook-run — rejected; the
  user wants it opt-in behind a flag.
- Letting the step-count flag combine with --to or --only — rejected by the
  user; it composes with --from only.
- Printing full step prompts or task bodies in /runbook-describe output —
  rejected; that token cost is the problem being fixed.
