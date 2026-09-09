# Runbook: pipeline-revision-planning

Created: 2026-09-09 · Source: /architect run · Model: opus
Sequencing: 1–5 in build order — each later feature's tasks carry Preconditions: on tasks the earlier steps created, so those tasks must exist in TASKS.md first; 1 and 2 are independent of each other but run in order for one question stream.

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

## [ ] 2. Plan tasks for pipeline-engine

Depends on: none

Context: none

```prompt
/task-add feature=pipeline-engine
```

## [ ] 3. Plan tasks for owner-amend-arms

Depends on: 1, 2

Context:
- 2026-09-09 (from step 1): backlog-ordering tasks are 169–174 (169 next/all honour Preconditions:, 170 production-status Next rule, 171 task-add --before/--after, 172 task-add feature=<slug> --single + orphan prompt, 173 runbook-create --append positional --before/--after, 174 docs). Use these ids on Preconditions: lines.

```prompt
/task-add feature=owner-amend-arms

Tasks for backlog-ordering and pipeline-engine already exist in
.claude/TASKS.md. Where this feature's document names either as a
dependency, sequence across features by putting the relevant earlier task
ids on the new tasks' Preconditions: lines rather than by prose.
```

## [ ] 4. Plan tasks for pipeline-revision

Depends on: 1, 2, 3

Context:
- 2026-09-09 (from step 1): backlog-ordering tasks are 169–174 (169 next/all honour Preconditions:, 170 production-status Next rule, 171 task-add --before/--after, 172 task-add feature=<slug> --single + orphan prompt, 173 runbook-create --append positional --before/--after, 174 docs). Use these ids on Preconditions: lines.

```prompt
/task-add feature=pipeline-revision

Tasks for backlog-ordering, pipeline-engine and owner-amend-arms already
exist in .claude/TASKS.md. Where this feature's document names any of them
as a dependency, sequence across features by putting the relevant earlier
task ids on the new tasks' Preconditions: lines rather than by prose.
```

## [ ] 5. Plan tasks for pipeline-suggest

Depends on: 4

Context: none

```prompt
/task-add feature=pipeline-suggest

Tasks for pipeline-revision already exist in .claude/TASKS.md. The shape
table points at /pipeline-patch and /pipeline-revise, so put the task ids
that create those two surfaces on the new tasks' Preconditions: lines.
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
