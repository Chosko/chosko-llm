# Tasks

Last task number: 103

---

## 94. Run /cavecompress full on shipped commands and skills, with peer-review before commit

Status: [MISSING]
Target: claude+human
Files: commands/context-build.md, commands/context-update.md, commands/domain-setup.md, commands/project-setup.md, commands/refactor-codebase.md, commands/refactor-tests.md, commands/task-add.md, commands/task-clean.md, commands/task-enrich.md, commands/task-list.md, commands/task-setup.md, commands/unity-mcp-setup.md, skills/architect/SKILL.md, skills/architect/feature-doc-template.md, skills/architect/iterating.md, skills/architect/tech-stack-selection.md, skills/product-design/SKILL.md, skills/product-design/business-model.md, skills/product-design/document-templates.md, skills/product-design/resuming.md, skills/product-design/technical-direction.md, skills/task-implement/SKILL.md, skills/task-implement/body-schemas.md, skills/task-implement/delegated-runs.md, skills/task-implement/dirty-tree.md, skills/task-implement/human-in-loop.md, skills/task-implement/no-test-suite.md, skills/task-implement/test-runner.md, skills/task-implement/unity-mcp-checkpoints.md, skills/unity-mcp-skill/SKILL.md, skills/unity-mcp-skill/references/tools-reference.md, skills/unity-mcp-skill/references/workflows.md, claude-md/tool-usage-policy.md
Preconditions: none

---

## 95. Support feature kind migration (command → skill) in the CLI

Status: [DONE]
Target: claude
Files: scripts/lib.sh, scripts/cmd-update.sh, scripts/cmd-add.sh, docs/authoring-guide.md, .claude/context/shared-lib.md, .claude/context/cmd-update.md, .claude/context/cmd-add.md, VERSION
Preconditions: none

---

## 96. Spec the nested context-layer layout in the domain layer

Status: [DONE]
Target: claude
Files: .claude/domain/context-workflow.md, VERSION
Preconditions: none

---

## 97. Convert /context-build and /context-update to skills and emit the Layout marker

Status: [DONE]
Target: claude
Files: skills/context-build/SKILL.md, skills/context-update/SKILL.md, commands/context-build.md, commands/context-update.md, .claude/domain/context-workflow.md, VERSION
Preconditions: 95, 96

---

## 98. Add nested-layout support to /context-build

Status: [DONE]
Target: claude
Files: skills/context-build/SKILL.md, skills/context-build/nested.md, VERSION
Preconditions: 97

---

## 99. Add nested-layout support to /context-update

Status: [DONE]
Target: claude
Files: skills/context-update/SKILL.md, skills/context-update/nested.md, VERSION
Preconditions: 97

---

## 100. Add the /context-convert skill (flat ↔ nested)

Status: [DONE]
Target: claude
Files: skills/context-convert/SKILL.md, .claude/domain/context-workflow.md, VERSION
Preconditions: 98, 99

---

## 101. Document the context skill family and refresh its context layer

Status: [DONE]
Target: claude
Files: README.md, docs/cli-help.txt, docs/authoring-guide.md, .claude/context/features.md, .claude/context/INDEX.md, commands/project-setup.md, .claude/domain/context-workflow.md, VERSION
Preconditions: 97, 98, 99, 100

---

## 102. Add install-scope resolution (--local / --global) to lib.sh

Status: [MISSING]
Target: claude
Files: scripts/lib.sh, .claude/context/shared-lib.md, VERSION
Preconditions: none

---

## 103. Wire --local / --global into ls, add, rm, update, show

Status: [MISSING]
Target: claude
Files: scripts/cmd-ls.sh, scripts/cmd-add.sh, scripts/cmd-rm.sh, scripts/cmd-update.sh, scripts/cmd-show.sh, docs/cli-help.txt, README.md, .claude/context/cmd-ls.md, .claude/context/cmd-add.md, .claude/context/cmd-rm.md, .claude/context/cmd-update.md, .claude/context/cmd-show.md, .claude/context/INDEX.md, VERSION
Preconditions: 102
