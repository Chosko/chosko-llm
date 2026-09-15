# Tasks

Last task number: 231

---

## 227. Make `/runbook-create` commit by default

Status: [DONE]
Target: claude
Files: commands/runbook-create.md, commands/pipeline-patch.md, skills/pipeline-revise/SKILL.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 228. Make `/session-save` commit by default

Status: [DONE]
Target: claude
Files: commands/session-save.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 229. Make `/pipeline-patch` and `/pipeline-revise` commit once, at the end

Status: [DONE]
Target: claude
Files: commands/pipeline-patch.md, skills/pipeline-revise/SKILL.md, skills/pipeline-revise/delete.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 227

---

## 230. Update documentation for the new commit defaults

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, docs/authoring-guide.md, .claude/domain/product-workflow.md, .claude/domain/features/authoring-commit-default.md, .claude/domain/features/pipeline-revision.md, .claude/domain/features/session-continuity.md, .claude/domain/features/runbook-suite.md, .claude/domain/product-design.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 227, 228, 229

---

## 231. Decide the editorial question when the evidence is clear, ask only when it isn't

Status: [MISSING]
Target: claude
Files: skills/architect/amend.md, skills/architect/SKILL.md, skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/delete.md, skills/pipeline-revise/reorder.md, .claude/domain/features/owner-amend-arms.md, .claude/domain/features/pipeline-revision.md, .claude/domain/product-workflow.md, docs/reference.md, README.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none
