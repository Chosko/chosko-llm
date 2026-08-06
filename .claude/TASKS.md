# Tasks

Last task number: 96

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

Status: [DONE]
Target: claude
Files: commands/task-setup.md
Preconditions: none

---

## 84. Remove dead reference links in unity-mcp-skill

Status: [DONE]
Target: claude
Files: skills/unity-mcp-skill/SKILL.md, skills/unity-mcp-skill/references/tools-reference.md, skills/unity-mcp-skill/references/workflows.md
Preconditions: none

---

## 85. Hard-refuse non-claude Target tasks in the unattended task-impl orchestrator

Status: [DONE]
Target: claude
Files: scripts/cmd-task-impl.sh, scripts/lib-task-external.sh
Preconditions: none

---

## 86. Extend check-task-parity.sh to guard Target-field gating

Status: [DONE]
Target: claude
Files: scripts/check-task-parity.sh
Preconditions: 85

---

## 88. Remove vestigial --no-commit checks from authoring commands

Status: [DONE]
Target: claude
Files: commands/context-build.md, commands/domain-setup.md, commands/task-setup.md, commands/refactor-codebase.md, commands/refactor-tests.md, commands/task-enrich.md, commands/unity-mcp-setup.md
Preconditions: none

---

## 89. Trim oversized frontmatter descriptions to match the authoring guide's spec

Status: [DONE]
Target: claude
Files: commands/task-add.md, commands/project-setup.md, commands/unity-mcp-setup.md, docs/authoring-guide.md
Preconditions: none

---

## 90. Add a lightweight resume marker to /architect for interrupted PHASE 2 sessions

Status: [DONE]
Target: claude
Files: skills/architect/SKILL.md
Preconditions: none

---

## 91. Document that docs/ is not deployed and must not be a runtime source for authored features

Status: [DONE]
Target: claude
Files: docs/authoring-guide.md, CLAUDE.md
Preconditions: none

---

## 92. Offer per-task subagent delegation on multi-task /task-implement runs

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, .claude/domain/task-workflow.md, .claude/context/features.md, VERSION
Preconditions: none

---

## 93. Run /cavecompress lite on CLAUDE.md and .claude/context and .claude/domain files

Status: [MISSING]
Target: claude
Files: CLAUDE.md, .claude/context/cmd-upgrade.md, .claude/context/cmd-help.md, .claude/context/lib-task-external.md, .claude/context/cmd-channel.md, .claude/context/cli-entry.md, .claude/context/INDEX.md, .claude/context/cmd-add.md, .claude/context/cmd-export.md, .claude/context/cmd-ls.md, .claude/context/cmd-rm.md, .claude/context/cmd-show.md, .claude/context/cmd-task-impl.md, .claude/context/cmd-update.md, .claude/context/shared-lib.md, .claude/context/features.md, .claude/domain/context-workflow.md, .claude/domain/product-workflow.md, .claude/domain/refactor-workflow.md, .claude/domain/task-workflow.md
Preconditions: none

---

## 94. Add an optional claude-council decision gate to /architect

Status: [DONE]
Target: claude
Files: skills/architect/council-gate.md, skills/architect/SKILL.md, skills/architect/tech-stack-selection.md
Preconditions: none

---

## 95. Add the claude-council decision gate to /product-design PHASE 6

Status: [DONE]
Target: claude
Files: skills/product-design/council-gate.md, skills/product-design/SKILL.md, skills/product-design/technical-direction.md
Preconditions: 94

---

## 96. Document the claude-council gate and bump the repo version

Status: [DONE]
Target: claude
Files: docs/authoring-guide.md, .claude/domain/product-workflow.md, .claude/context/features.md, README.md, VERSION
Preconditions: 94, 95
