# Tasks

Last task number: 92

---

## 81. Make /task-implement auto-skip TDD phases for documentation-only tasks

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, .claude/domain/task-workflow.md
Preconditions: none

---

## 82. Add --short option to /task-add for lightweight tasks

Status: [DONE]
Target: claude
Files: commands/task-add.md, .claude/domain/task-workflow.md
Preconditions: none

---

## 83. Fix stale task-body schema in task-setup.md's external prompt templates

Status: [MISSING]
Target: claude
Files: commands/task-setup.md
Preconditions: none

---

## 84. Remove dead reference links in unity-mcp-skill

Status: [MISSING]
Target: claude
Files: skills/unity-mcp-skill/SKILL.md, skills/unity-mcp-skill/references/tools-reference.md, skills/unity-mcp-skill/references/workflows.md
Preconditions: none

---

## 85. Hard-refuse non-claude Target tasks in the unattended task-impl orchestrator

Status: [MISSING]
Target: claude
Files: scripts/cmd-task-impl.sh, scripts/lib-task-external.sh
Preconditions: none

---

## 86. Extend check-task-parity.sh to guard Target-field gating

Status: [MISSING]
Target: claude
Files: scripts/check-task-parity.sh
Preconditions: 85

---

## 88. Remove vestigial --no-commit checks from authoring commands

Status: [MISSING]
Target: claude
Files: commands/context-build.md, commands/domain-setup.md, commands/task-setup.md, commands/refactor-codebase.md, commands/refactor-tests.md, commands/task-enrich.md, commands/unity-mcp-setup.md
Preconditions: none

---

## 89. Trim oversized frontmatter descriptions to match the authoring guide's spec

Status: [MISSING]
Target: claude
Files: commands/task-add.md, commands/project-setup.md, commands/unity-mcp-setup.md, docs/authoring-guide.md
Preconditions: none

---

## 90. Add a lightweight resume marker to /architect for interrupted PHASE 2 sessions

Status: [MISSING]
Target: claude
Files: skills/architect/SKILL.md
Preconditions: none

---

## 91. Document that docs/ is not deployed and must not be a runtime source for authored features

Status: [MISSING]
Target: claude
Files: docs/authoring-guide.md, CLAUDE.md
Preconditions: none

---

## 92. Offer per-task subagent delegation on multi-task /task-implement runs

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, .claude/domain/task-workflow.md, .claude/context/features.md, VERSION
Preconditions: none
