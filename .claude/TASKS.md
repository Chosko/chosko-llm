# Tasks

Last task number: 226

---

## 215. Route staled tasks to `/task-add feature=<slug>` reconciliation in `/pipeline-revise`'s amend branch

Status: [DONE]
Target: claude
Files: skills/pipeline-revise/amend.md, skills/pipeline-revise/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 216. Carry `/pipeline-revise`'s editorial answer into the `/architect amend` step as a confirmation

Status: [DONE]
Target: claude
Files: skills/architect/amend.md, skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/delete.md, .claude/domain/features/pipeline-revision.md, VERSION, CHANGELOG.md
Preconditions: 215

---

## 217. Recommend an answer at `/architect amend`'s editorial gate, derived from its own touched set and scope call

Status: [DONE]
Target: claude
Files: skills/architect/amend.md, skills/architect/SKILL.md, skills/pipeline-engine/references/routing.md, .claude/domain/features/owner-amend-arms.md, .claude/context/features.md, README.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 218. Recommend an answer at `/pipeline-revise`'s editorial gate by letting the branch judge the `editorial` tier

Status: [DONE]
Target: claude
Files: skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/delete.md, skills/pipeline-revise/reorder.md, .claude/domain/features/pipeline-revision.md, .claude/context/features.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: 217

---

## 219. Cap the runbook `Done:` line to a terse default form

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/runbook-schema.md, skills/runbook-run/SKILL.md, skills/runbook-run/references/subagent-contract.md, .claude/domain/features/runbook-suite.md, .claude/context/features.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 220. Make `Sequencing:` optional and one line, and stop appends extending it

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/runbook-schema.md, skills/runbook-run/references/step-amend.md, commands/runbook-create.md, skills/pipeline-engine/references/routing.md, .claude/domain/features/runbook-suite.md, .claude/context/features.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 221. Keep the orchestrator-authored part of a spawned prompt minimal

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, .claude/domain/features/runbook-suite.md, .claude/context/features.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 222. Rename the `stop hook refused` literal to `stop hook ignored on runbook WIP`

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, docs/reference.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 223. Auto-answer `/task-implement`'s dirty-tree prompt under `--inline` when only runbook bookkeeping is dirty

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/inline-contract.md, skills/runbook-run/SKILL.md, .claude/context/features.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 224. Restore the exec bit on this repo's own `.claude/hooks/remote-session-protocol.sh`

Status: [DONE]
Target: claude
Files: .claude/hooks/remote-session-protocol.sh, VERSION, CHANGELOG.md
Preconditions: none

---

## 225. Let an owned document stay in a task's Hints as a read-only Reference

Status: [DONE]
Target: claude
Files: commands/task-add.md, skills/task-engine/references/amend.md, skills/task-engine/SKILL.md, skills/task-implement/SKILL.md, .claude/domain/product-workflow.md, .claude/domain/task-workflow.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 226. Make `/pipeline-revise`'s impact walk explicit on continuing from forward-reached tasks

Status: [DONE]
Target: claude
Files: skills/pipeline-revise/amend.md, skills/pipeline-revise/delete.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/SKILL.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none
