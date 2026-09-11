# Runbook: pipeline-revision-planning

Created: 2026-09-09 · Source: /architect run · Model: opus
Sequencing: 1–5 in build order — each later feature's tasks carry Preconditions: on tasks the earlier steps created, so those tasks must exist in TASKS.md first; 1 and 2 are independent of each other but run in order for one question stream. 6–7 land the task-archive feature and wire it into the pipeline-engine lint task: 6 follows 2 because 7 needs both features' task ids, and 7 is bookkeeping on ids 2 and 6 created.

## [x] 1. Plan tasks for backlog-ordering

Depends on: none

Context: none

```prompt
/task-add feature=backlog-ordering

This repository has no PLAN.md and no product-roadmap.md by design (see
CLAUDE.md), so the /production-status change in this feature is specified
against the command body in commands/production-status.md only; do not
propose creating either document here to exercise it.
```

Done: commit cda77e3 (pushed) — tasks 169–174 written, TASKS.md counter 168→174, FEATURES.md backlog-ordering → [PLANNED] with Tasks: 169, 170, 171, 172, 173, 174. Decisions: 6-task split accepted (169 next/all honour Preconditions:, 170 production-status Next rule, 171 --before/--after on task-add, 172 feature=<slug> --single + orphan prompt, 173 positional --before/--after on runbook-create --append, 174 docs); `all` resolves once up front by simulating repeated `next`; feature doc open question 2 answered at planning time (task-implement BETWEEN TASKS re-read is the re-evaluation point, no new read); backlog-ordering.md read-only in 169–173 Hints; task 174 carries dated grants to edit runbook-suite.md (3 points) and backlog-ordering.md (2 points) only; 174 takes no VERSION bump and no CHANGELOG entry; VERSION minor on 169/171/172/173, patch on 170. Premises corrected: plan-readout.md has nothing to reconcile, product-workflow.md does carry the "lowest-numbered" wording; task-add DO NOT list forbids editing other tasks Preconditions: which --before requires (171 narrows it); the foot-of-file invariant is stated twice in runbook-create and twice in runbook-suite.md (enumerated in 173 and 174). Prompt premise about no PLAN.md/product-roadmap.md held.

## [x] 2. Plan tasks for pipeline-engine

Depends on: none

Context: none

```prompt
/task-add feature=pipeline-engine
```

Done: commit 3efc79a (pushed) — tasks 175–181 written, TASKS.md counter 174→181, FEATURES.md pipeline-engine → [PLANNED] with Tasks: 175, 176, 177, 178, 179, 180, 181; no domain document edited. Tasks: 175 skill scaffold + probes.md, 176 graph.md, 177 routing.md, 178 lint.md, 179 commands/pipeline-check.md, 180 scripts/check-routing.sh, 181 docs. Decisions (four question rounds): 7-task split; runbook-step-names-resolved-task finding dropped (needs runbook-body read, /runbook-run prints step before spawning), sibling [PENDING]-with-all-steps-done finding ships from RUNBOOKS.md Steps: alone; check-routing.sh verifies two mechanical invariants only (every row names existing command or skill, every feature with requires: skill:pipeline-engine has a row), no membership list, no new frontmatter key; severity two levels ERROR/WARNING, not /task-review vocabulary; task-archive folded in — "Tasks: id absent from TASKS.md" never enters catalogue, absent id reads archived-and-terminal citing task-engine/references/resolution.md, nothing probes .claude/tasks/archive/, [PLANNED]-fully-resolved finding counts archived ids as resolved; two dated disjoint grants on pipeline-engine.md — task 178 (2 points: drop the Tasks:-id finding, add Graph sentence) and task 181 (4 points: runbook finding note, open question 2 wording, routing-check narrowing, severity vocabulary); 175–177, 179, 180 carry the doc read-only. VERSION minor on 175 and 179, patch on 176–178 and 180, none on 181. Premises corrected: feature doc read-only register contradicted its findings list, only one finding affected not two; "every pipeline command has a row" not mechanically checkable; severity vocabulary unspecified in doc; two ownership tables now coexist (routing.md Owns vs /task-add pre-authorisation), 177 carries tie-break (fix routing.md, never /task-add); 178 cites a resolution.md rule task-archive has not yet written — no precondition id invented, runbook step 7 wires it.

## [x] 3. Plan tasks for owner-amend-arms

Depends on: 1, 2

Context:
- 2026-09-09 (from step 1): backlog-ordering tasks are 169–174 (169 next/all honour Preconditions:, 170 production-status Next rule, 171 task-add --before/--after, 172 task-add feature=<slug> --single + orphan prompt, 173 runbook-create --append positional --before/--after, 174 docs). Use these ids on Preconditions: lines.
- 2026-09-09 (from step 2): pipeline-engine tasks are 175–181 (175 skill scaffold + probes.md, 176 graph.md, 177 routing.md, 178 lint.md, 179 /pipeline-check command, 180 check-routing.sh, 181 docs). Use these ids on Preconditions: lines. Lint severity is two levels, ERROR/WARNING. routing.md rows exist only for shipped features; /pipeline-patch, pipeline-revise and pipeline-suggest add their own rows when they land.

```prompt
/task-add feature=owner-amend-arms

Tasks for backlog-ordering and pipeline-engine already exist in
.claude/TASKS.md. Where this feature's document names either as a
dependency, sequence across features by putting the relevant earlier task
ids on the new tasks' Preconditions: lines rather than by prose.
```

Done: commit 05850cd (pushed) — tasks 182–186 written, TASKS.md counter 181→186, FEATURES.md owner-amend-arms → [PLANNED] with Tasks: 182, 183, 184, 185, 186; no reconciliation (Tasks: was none). Tasks: 182 /architect amend arm (skills/architect/amend.md + SKILL wiring, Preconditions: none), 183 single-task amend reference skills/task-engine/references/amend.md (none), 184 single-step amend reference skills/runbook-run/references/step-amend.md (173), 185 record each owner amend entry in pipeline routing table (177, 182, 183, 184), 186 docs (182–185). Decisions: three arm tasks + one bookkeeping + one docs, routing entries kept out of the arms so no pipeline-engine block on them; nothing depends on 179 — /pipeline-check deliberately kept out of the arms; struck runbook step = [x] with Done: line opening "struck — <reason>" and no commit sha ([!] rejected: halts the run, drives index to [FAILED]); free-form /architect amend change naming no sections is refused; Files:-coarseness question left open on purpose; task 186 carries dated grant (2026-09-09) on runbook-suite.md (3 points) and owner-amend-arms.md (3 points), pipeline-engine.md and backlog-ordering.md excluded; no unshipped command named in shipped content (183 widens task-engine "only these five may open it" sentence generically); 186 no VERSION bump, 182–185 bump both. Premises corrected: feature doc says a struck step reuses existing marker vocabulary but none of the four markers means skipped, so [x] is overloaded with a Done: reason; feature doc Dependencies omits task-workflow.md § One authority per rule whose counts go stale with an eighth task-engine reference (folded into 186); task-engine SKILL.md "only they should ever open it" sentence breaks by design (183 handles); /architect arm writing product-design.md is not a breach of "never writes another owner line" since the full skill already does (recorded on 182).

## [x] 4. Plan tasks for pipeline-revision

Depends on: 1, 2, 3

Context:
- 2026-09-09 (from step 1): backlog-ordering tasks are 169–174 (169 next/all honour Preconditions:, 170 production-status Next rule, 171 task-add --before/--after, 172 task-add feature=<slug> --single + orphan prompt, 173 runbook-create --append positional --before/--after, 174 docs). Use these ids on Preconditions: lines.
- 2026-09-09 (from step 2): pipeline-engine tasks are 175–181 (175 skill scaffold + probes.md, 176 graph.md, 177 routing.md, 178 lint.md, 179 /pipeline-check command, 180 check-routing.sh, 181 docs). Use these ids on Preconditions: lines. Lint severity is two levels, ERROR/WARNING. routing.md rows exist only for shipped features; /pipeline-patch, pipeline-revise and pipeline-suggest add their own rows when they land.
- 2026-09-09 (from step 3): owner-amend-arms tasks are 182–186 (182 /architect amend arm at skills/architect/amend.md, 183 skills/task-engine/references/amend.md, 184 skills/runbook-run/references/step-amend.md, 185 owner amend entries in routing.md, 186 docs). Use these ids on Preconditions: lines. Struck runbook step = [x] with Done: line opening "struck — <reason>", no commit sha. Arms do not invoke /pipeline-check; running the lint before and after an action belongs to the reviser. Shipped content names no unshipped command: /pipeline-patch and /pipeline-revise add their own routing.md rows and their own names in task-engine SKILL.md when they land.

```prompt
/task-add feature=pipeline-revision

Tasks for backlog-ordering, pipeline-engine and owner-amend-arms already
exist in .claude/TASKS.md. Where this feature's document names any of them
as a dependency, sequence across features by putting the relevant earlier
task ids on the new tasks' Preconditions: lines rather than by prose.
```

Done: commit c7ff8b5 (pushed) — tasks 187–193 written, TASKS.md counter 186→193, FEATURES.md pipeline-revision → [PLANNED] with Tasks: 187, 188, 189, 190, 191, 192, 193 (Doc:/Source: untouched). Tasks: 187 skills/pipeline-revise/SKILL.md + routing row (Preconditions: 176, 177, 178, 179), 188 amend.md (182, 183, 184, 187), 189 insert.md (171, 172, 173, 182, 187), 190 delete.md (183, 184, 187), 191 reorder.md (189, 190), 192 commands/pipeline-patch.md + routing row (176, 177, 179, 182, 183, 184, 187), 193 docs (187–192). Decisions (one question round): reorder branch ships now, closing /pipeline-patch's "reorder of existing entries" refuse path (user chose A over deferring); reviser ships before patcher because the patcher's refuse line names /pipeline-revise and shipped content never names an unshipped command; each surface adds its own routing.md row in its own task so check-routing.sh (task 180) never fails in between; branch files sit flat beside SKILL.md (architect pattern), not under references/; /pipeline-patch takes [--commit] [--no-push] forwarded to the arm it executes; amend branch owner sequence is upstream-first (/product-design → /architect amend → task bodies → runbook steps); task 193 carries dated grant (user chose A) to edit pipeline-revision.md on exactly 3 points (shipped paths replace abstract naming, patcher flags, reorder open question settled), open questions 1 and 3 left open; 193 no VERSION bump, 187–192 bump. Premises corrected: feature doc Interfaces omits commit flags on /pipeline-patch, inconsistent with every arm it executes (reconciled via 193); doc's Architecture (four branches) and Open questions (reorder may defer) contradicted each other, resolved for four. CONTEXT ids 169–186 all resolved in TASKS.md as stated.

## [x] 5. Plan tasks for pipeline-suggest

Depends on: 4

Context:
- 2026-09-10 (from step 4): pipeline-revision tasks are 187–193 (187 skills/pipeline-revise/SKILL.md + routing row, 188 amend.md, 189 insert.md, 190 delete.md, 191 reorder.md, 192 commands/pipeline-patch.md + routing row, 193 docs). /pipeline-revise is created by task 187 (its branches by 188–191); /pipeline-patch by task 192. Use these ids on Preconditions: lines.

```prompt
/task-add feature=pipeline-suggest

Tasks for pipeline-revision already exist in .claude/TASKS.md. The shape
table points at /pipeline-patch and /pipeline-revise, so put the task ids
that create those two surfaces on the new tasks' Preconditions: lines.
```

Done: commit 59e0367 (pushed) — tasks 194–195 written, TASKS.md counter 193→195, FEATURES.md pipeline-suggest → [PLANNED] with Tasks: 194, 195 (Doc:/Source: untouched, no domain document edited). Tasks: 194 skills/pipeline-suggest/SKILL.md + routing.md row (Preconditions: 177, 179, 187, 192), 195 docs (193, 194). Decisions (one question round): one implementation task, not a split — the feature ships one file under ~45 lines, small-feature exception applies; Preconditions carry 187 (/pipeline-revise) and 192 (/pipeline-patch) as the prompt directed plus 177 (routing table the row joins) and 179 (/pipeline-check, a row the table names), transitive ids omitted; requires: skill:pipeline-engine, skill:pipeline-revise, command:pipeline-patch (user chose A over engine-only or every named command), the seven other commands the shape table names stay unrequired; routing row lands with the skill per check-routing.sh completeness invariant; task 195 carries dated grant (user chose A) to edit pipeline-suggest.md on exactly 3 points (requires: names the two surfaces; routing row is part of what ships; abstract shape table replaced by shipped rows), both open questions left open; task 194 keeps the doc as read-only Hint (user chose A); 195 also preconditions on 193 because it writes beside README/docs sections 193 creates; 195 no VERSION bump, 194 minor bump. Premises corrected: none in the prompt (187 and 192 are the creators of the two surfaces); feature doc Interfaces records requires: skill:pipeline-engine alone yet expects the two surfaces installed, impossible since requires: is flat and non-transitive, and never mentions the routing row the requires: obliges — both reconciled via 195.

## [x] 6. Plan tasks for task-archive

Depends on: 2

Context:
- 2026-09-09 (from step 2): pipeline-engine tasks 175–181 exist. Task 176 (graph.md) and task 178 (lint.md) cite skills/task-engine/references/resolution.md as the authority for the archived-and-terminal rule without restating it; task 177 (routing.md) keys rows on feature name not kind, so the /task-clean command-to-skill migration invalidates no row; task 180 (check-routing.sh) accepts commands/<name>.md or skills/<name>/SKILL.md.

```prompt
/task-add feature=task-archive

Read .claude/domain/features/task-archive.md first; it is the primary
source. Decisions already settled there, do not re-open: /task-clean is
rewritten as skills/task-clean/SKILL.md with `replaces: command:task-clean`
and `requires: skill:task-engine`; the --backfill procedure goes in a
supporting file backfill.md read only when the flag is passed, never in
SKILL.md; the archive resolution rule (an id referenced but absent from
TASKS.md is archived and terminal; no command probes the folder or opens a
file in it unless the user names a task and asks) has its single home in
skills/task-engine/references/resolution.md, and every consumer cites that
path and states only its deviation; the prune path no longer opens
FEATURES.md; /production-status renders absent ids as `archived: N`.

Expected seams, one task each unless the split check says otherwise: the
resolution.md rule; the command-to-skill migration with the archive move
and the frozen header; backfill.md; the consumer edits (/task-add
reconciliation keeps absent ids on Tasks:, /task-implement <N> stops on an
absent id naming the archive path, /task-review and /task-iterate exclude
archive/ from the most-recent-body fallback, /architect iterating.md
rationale, /production-status rollup); the documentation task. The
resolution.md task must precede every other task of the feature on
Preconditions:. This repository has no PLAN.md by design; do not propose
one.
```

Done: commit 4ace457 (pushed) — tasks 196–201 written, TASKS.md counter 195→201, FEATURES.md task-archive → [PLANNED] with Tasks: 196, 197, 198, 199, 200, 201 (Doc:/Source: untouched, no domain document edited). Tasks: 196 archive rule + archived-file form + /task-clean and /task-add per-consumer notes in skills/task-engine/references/resolution.md and the task-engine map row (Preconditions: none, VERSION patch), 197 commands/task-clean.md → skills/task-clean/SKILL.md with replaces: command:task-clean, requires: skill:task-engine, version 0.9.0, VCS-rename archive move with frozen header, every FEATURES.md read/write removed from the prune (196, minor), 198 --backfill + skills/task-clean/backfill.md read only under the flag, the one remaining FEATURES.md write (197, minor), 199 the five id readers state their deviation — /task-add reconciliation, /task-implement stop naming the archive path, /task-review + /task-iterate fallback exclusion, /architect iterating.md and SKILL.md items 5–6 (196, patch), 200 /production-status renders archived: N / [archived], zero-task case narrowed to literal Tasks: none, archived counts as resolved in readiness and Next (196, patch), 201 docs (196–200, no bump). Decisions (one question round, all as recommended): six-task split with /production-status separate from the other readers; commit-message form becomes "task-clean: archive tasks …" (rippling to commit.md and claude-md/git-commit-style.md in 197, docs/authoring-guide.md in 201) with "task-clean: backfill <N> archived tasks" in 198; /task-iterate gains no requires: and states the exclusion bare, /task-review cites resolution.md; task 201 carries dated grant (2026-09-11) to edit task-archive.md on exactly 2 points (stale pipeline-engine Dependencies bullet replaced by what shipped; docs list gains authoring-guide.md and context INDEX.md), three open questions untouched. Decided without asking: resolution.md has exactly one writer (196); skill continues the command version line 0.8.0→0.9.0→0.10.0 per context-build/context-update precedent; backfill.md referenced relatively as ./backfill.md. Premises corrected: feature doc Dependencies bullet on pipeline-engine is stale (says finding must be dropped before /task-add feature=pipeline-engine runs and feature is [NEW]; it is [PLANNED] 175–181 and step 2 folded the drop into 178); Dependencies docs list omits docs/authoring-guide.md and .claude/context/INDEX.md; product-design.md needs nothing because its § Task backlog already describes the archive. Prompt premises all held; .claude/tasks/ already pruned from cmd-export.sh traversal, no CLI change in scope. Wiring 196 onto pipeline-engine Preconditions: deliberately left to step 7.

## [ ] 7. Wire the archive rule into the pipeline-engine lint task

Depends on: 2, 6

Context:
- 2026-09-09 (from step 2): the pipeline-engine lint-catalogue task is 178 (Preconditions: 175, 176, 177). Its Decisions already say a later runbook step wires the precondition on the resolution.md task.
- 2026-09-11 (from step 6): task-archive tasks are 196–201; the task that adds the archive rule to skills/task-engine/references/resolution.md is 196 (Preconditions: none). Step 6's agent noted that task 176 (graph.md) also cites resolution.md for the archived-and-terminal rule, alongside the lint task 178.

```prompt
Bookkeeping edit on .claude/TASKS.md, no slash command fits. Read the file.
Find the pipeline-engine task that implements the lint catalogue (written
by runbook step 2) and the task-archive task that adds the archive rule to
skills/task-engine/references/resolution.md (written by step 6). Add the
resolution.md task's id to the lint task's Preconditions: line, keeping
the ids already there. Edit only that one line, nothing else in the file.
Commit as "Task <lint id>: precondition on task <resolution id>" and push.
Reason: the lint task cites resolution.md's archive rule by path, and the
finding "a feature's Tasks: id absent from TASKS.md" was dropped from the
catalogue because that state now means archived, so the rule must exist
before the lint is implemented.
```

## Do not re-propose

- A separate `/amend` command — folded into `pipeline-revise`; the reviser's
  impact walk subsumes it.
- Running `/pipeline-check` automatically at the end of every pipeline
  writer — rejected; the lint stays an explicit act so no writer depends on
  the engine.
- Trusting a classifier for the editorial tier — rejected; the editorial
  question is asked on every amendment.
- A prose "pipeline explainer" reference file in `pipeline-engine` —
  rejected; the engine ships graph and table only, and a line consumed by no
  routing decision, impact-walk step or lint rule is cut.
- A new status value or a change ledger for revisions — rejected; existing
  vocabularies (`[STALE]`, `[ITERATED]`, `[SKIP]`), commits and runbook
  `Done:` lines are the provenance.
- Offering a runbook for fewer than four owner steps, or writing one without
  the user's explicit choice — rejected.
- A `/task-list archived` filter or any read surface over the task archive —
  rejected; it would bend the no-read rule the feature exists to keep.
- A Glob probe of `.claude/tasks/archive/` in any command — rejected; an id
  absent from `TASKS.md` is assumed archived, never checked.
- Keeping the `--backfill` procedure inside `skills/task-clean/SKILL.md` —
  rejected; it is read on demand from `backfill.md` so the ordinary prune
  pays nothing for it.
- A purge path for the archive — an open question in task-archive.md, not
  scope.
