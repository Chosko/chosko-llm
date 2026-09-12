# Tasks

Last task number: 205

---

## 169. Backlog ordering on the task side: selectors honour `Preconditions:`, `/production-status` agrees, `/task-add` can insert and attach

Status: [DONE]
Target: claude
Files: skills/task-engine/references/resolution.md, skills/task-engine/SKILL.md, skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, commands/production-status.md, commands/task-add.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: backlog-ordering

---

## 173. Add positional `--before` / `--after` to `/runbook-create --append`

Status: [DONE]
Target: claude
Files: commands/runbook-create.md, skills/runbook-run/references/runbook-schema.md, skills/runbook-run/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: backlog-ordering

---

## 174. Update documentation for feature `backlog-ordering`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, .claude/domain/task-workflow.md, .claude/domain/product-workflow.md, .claude/domain/features/runbook-suite.md, .claude/domain/features/backlog-ordering.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 169, 173
Feature: backlog-ordering

---

## 175. Ship the `pipeline-engine` skill, the `/pipeline-check` command and the repo-local routing check

Status: [DONE]
Target: claude
Files: skills/pipeline-engine/SKILL.md, skills/pipeline-engine/references/probes.md, skills/pipeline-engine/references/graph.md, skills/pipeline-engine/references/routing.md, skills/pipeline-engine/references/lint.md, commands/pipeline-check.md, scripts/check-routing.sh, .claude/domain/features/pipeline-engine.md, VERSION, CHANGELOG.md
Preconditions: 196
Feature: pipeline-engine

---

## 181. Update documentation for feature `pipeline-engine`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, docs/authoring-guide.md, CLAUDE.md, .claude/domain/product-workflow.md, .claude/domain/features/pipeline-engine.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 175
Feature: pipeline-engine

---

## 182. Add the three owner amend arms and record them in the pipeline routing table

Status: [DONE]
Target: claude
Files: skills/architect/amend.md, skills/architect/SKILL.md, skills/task-engine/references/amend.md, skills/task-engine/SKILL.md, skills/runbook-run/references/step-amend.md, skills/runbook-run/SKILL.md, skills/pipeline-engine/references/routing.md, skills/pipeline-engine/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 173, 175
Feature: owner-amend-arms

---

## 186. Update documentation for feature `owner-amend-arms`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, .claude/domain/product-workflow.md, .claude/domain/task-workflow.md, .claude/domain/features/runbook-suite.md, .claude/domain/features/owner-amend-arms.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 182
Feature: owner-amend-arms

---

## 187. Ship the `pipeline-revise` skill with its four branches and the `/pipeline-patch` command

Status: [DONE]
Target: claude
Files: skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/delete.md, skills/pipeline-revise/reorder.md, commands/pipeline-patch.md, skills/pipeline-engine/references/routing.md, skills/pipeline-engine/SKILL.md, skills/task-engine/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 169, 173, 175, 182
Feature: pipeline-revision

---

## 193. Update documentation for feature `pipeline-revision`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, .claude/domain/product-workflow.md, .claude/domain/task-workflow.md, .claude/domain/features/pipeline-revision.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 187
Feature: pipeline-revision

---

## 194. Add the `pipeline-suggest` skill

Status: [DONE]
Target: claude
Files: skills/pipeline-suggest/SKILL.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 175, 187
Feature: pipeline-suggest

---

## 195. Update documentation for feature `pipeline-suggest`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, .claude/domain/product-workflow.md, .claude/domain/features/pipeline-suggest.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 193, 194
Feature: pipeline-suggest

---

## 196. Put the archive rule in `resolution.md`, rewrite `/task-clean` as a skill that archives, and add `--backfill`

Status: [DONE]
Target: claude
Files: skills/task-engine/references/resolution.md, skills/task-engine/SKILL.md, skills/task-clean/SKILL.md, skills/task-clean/backfill.md, commands/task-clean.md, skills/task-engine/references/commit.md, claude-md/git-commit-style.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: task-archive

---

## 199. State the archive deviation in every id reader, including `/production-status`'s rollup

Status: [DONE]
Target: claude
Files: commands/task-add.md, skills/task-implement/SKILL.md, skills/task-review/SKILL.md, skills/task-iterate/SKILL.md, skills/architect/SKILL.md, skills/architect/iterating.md, commands/production-status.md, VERSION, CHANGELOG.md
Preconditions: 169, 196
Feature: task-archive

---

## 201. Update documentation for feature `task-archive`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, docs/authoring-guide.md, .claude/domain/task-workflow.md, .claude/domain/product-workflow.md, .claude/domain/features/task-archive.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 196, 199
Feature: task-archive

---

## 202. Flip `/architect` to commit by default

Status: [DONE]
Target: claude
Files: skills/architect/SKILL.md, skills/architect/amend.md, skills/architect/iterating.md, skills/architect/council-gate.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: authoring-commit-default

---

## 203. Flip `/product-design`, `/product-roadmap` and `/production-plan` to commit by default

Status: [DONE]
Target: claude
Files: skills/product-design/SKILL.md, skills/product-design/council-gate.md, skills/product-design/resuming.md, skills/product-roadmap/SKILL.md, skills/production-plan/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: authoring-commit-default

---

## 204. Move `/product-design` and `/production-plan` into the commits-by-default row of both forwarding tables

Status: [MISSING]
Target: claude
Files: commands/pipeline-patch.md, skills/pipeline-revise/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 202, 203
Feature: authoring-commit-default

---

## 205. Update documentation for feature `authoring-commit-default`

Status: [MISSING]
Target: claude
Files: README.md, docs/reference.md, docs/authoring-guide.md, .claude/domain/product-workflow.md, .claude/domain/features/authoring-commit-default.md, .claude/domain/features/owner-amend-arms.md, .claude/domain/features/production-plan.md, .claude/domain/features/product-roadmap.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 202, 203, 204
Feature: authoring-commit-default
