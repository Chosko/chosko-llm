# Tasks

Last task number: 120

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

Status: [DONE]
Target: claude
Files: scripts/lib.sh, .claude/context/shared-lib.md, VERSION
Preconditions: none

---

## 103. Wire --local / --global into ls, add, rm, update, show

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, scripts/cmd-add.sh, scripts/cmd-rm.sh, scripts/cmd-update.sh, scripts/cmd-show.sh, docs/cli-help.txt, README.md, .claude/context/cmd-ls.md, .claude/context/cmd-add.md, .claude/context/cmd-rm.md, .claude/context/cmd-update.md, .claude/context/cmd-show.md, .claude/context/INDEX.md, VERSION
Preconditions: 102

---

## 104. Surface pending kind migrations in `ls` and `show`

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, scripts/cmd-show.sh, scripts/lib.sh, docs/cli-help.txt, .claude/context/cmd-ls.md, .claude/context/cmd-show.md, .claude/context/shared-lib.md, VERSION
Preconditions: none

---

## 105. Make `add` and `update` accept multiple feature names in one invocation

Status: [DONE]
Target: claude
Files: scripts/cmd-add.sh, scripts/cmd-update.sh, docs/cli-help.txt, README.md, .claude/context/cmd-add.md, .claude/context/cmd-update.md, VERSION
Preconditions: none

---

## 106. Add the /product-roadmap skill and the roadmap document schema

Status: [DONE]
Target: claude
Files: skills/product-roadmap/SKILL.md, VERSION
Preconditions: none
Feature: product-roadmap

---

## 107. Update documentation for feature product-roadmap

Status: [DONE]
Target: claude
Files: README.md, docs/cli-help.txt, .claude/context/features.md, .claude/domain/product-workflow.md, VERSION
Preconditions: 106
Feature: product-roadmap

---

## 108. Extract /architect's input resolution into sectioned-input.md

Status: [DONE]
Target: claude
Files: skills/architect/SKILL.md, skills/architect/sectioned-input.md, VERSION
Preconditions: none
Feature: slice-aware-architecture

---

## 109. Add slice-aware input resolution to /architect

Status: [DONE]
Target: claude
Files: skills/architect/SKILL.md, skills/architect/sliced-input.md, skills/architect/feature-doc-template.md, VERSION
Preconditions: 106, 108
Feature: slice-aware-architecture

---

## 110. Update documentation for feature slice-aware-architecture

Status: [DONE]
Target: claude
Files: README.md, .claude/domain/product-workflow.md, .claude/context/features.md, .claude/domain/features/slice-aware-architecture.md, VERSION
Preconditions: 108, 109
Feature: slice-aware-architecture

---

## 111. Add the /production-plan skill and the PLAN.md schema

Status: [DONE]
Target: claude
Files: skills/production-plan/SKILL.md, skills/production-plan/reconciling.md, VERSION
Preconditions: 106, 109
Feature: production-plan

---

## 112. Update documentation for feature production-plan

Status: [DONE]
Target: claude
Files: README.md, docs/cli-help.txt, .claude/context/features.md, .claude/domain/product-workflow.md, .claude/domain/features/production-plan.md, VERSION
Preconditions: 111
Feature: production-plan

---

## 113. Add the /production-status command

Status: [DONE]
Target: claude
Files: commands/production-status.md, VERSION
Preconditions: 111
Feature: plan-readout

---

## 114. Add milestone grouping to /task-list

Status: [DONE]
Target: claude
Files: commands/task-list.md, VERSION
Preconditions: 111
Feature: plan-readout

---

## 115. Update documentation for feature plan-readout

Status: [DONE]
Target: claude
Files: README.md, docs/cli-help.txt, .claude/context/features.md, .claude/domain/product-workflow.md, .claude/domain/task-workflow.md, .claude/domain/features/plan-readout.md, VERSION
Preconditions: 113, 114
Feature: plan-readout

---

## 116. Delete-not-append design-process.md content once a run ends

Status: [DONE]
Target: claude
Files: skills/product-design/SKILL.md, skills/product-design/document-templates.md, skills/product-design/resuming.md, docs/authoring-guide.md, .claude/domain/product-workflow.md, .claude/context/features.md
Preconditions: none

---

## 117. Vendor the claude-council skill as a shipped chosko-llm feature

Status: [DONE]
Target: claude
Files: skills/claude-council/ (SKILL.md, references/, scripts/, assets/, evals/, journal/), README.md, .claude/context/features.md, .claude/domain/product-workflow.md, docs/authoring-guide.md, skills/architect/council-gate.md, skills/architect/SKILL.md, skills/product-design/council-gate.md, skills/product-design/SKILL.md, VERSION
Preconditions: none

---

## 118. Delete the dead dual-LLM local-model implementation lane

Status: [MISSING]
Target: claude
Files: scripts/cmd-task-impl.sh, scripts/lib-task-external.sh, scripts/check-task-parity.sh, scripts/cmd-help.sh, bin/chosko-llm, commands/task-enrich.md, commands/task-add.md, commands/task-setup.md, commands/domain-setup.md, commands/project-setup.md, commands/unity-mcp-setup.md, skills/task-implement/SKILL.md, skills/task-implement/body-schemas.md, skills/architect/iterating.md, docs/cli-help.txt, docs/authoring-guide.md, README.md, CLAUDE.md, VERSION, .claude/external/implement-prompt.md, .claude/external/tests-prompt.md, .claude/context/INDEX.md, .claude/context/features.md, .claude/context/cli-entry.md, .claude/context/cmd-help.md, .claude/context/cmd-task-impl.md, .claude/context/lib-task-external.md, .claude/domain/INDEX.md, .claude/domain/task-workflow.md, .claude/domain/product-design.md, .claude/domain/product-workflow.md, .claude/domain/technical-direction.md
Preconditions: none

---

## 119. Turn /task-implement's batch parent into a launcher

Status: [MISSING]
Target: claude
Files: skills/task-implement/delegated-runs.md, skills/task-implement/SKILL.md, VERSION
Preconditions: 118
Feature: task-implement-launcher

---

## 120. Update documentation for feature task-implement-launcher

Status: [MISSING]
Target: claude
Files: .claude/context/features.md, .claude/context/INDEX.md, .claude/domain/task-workflow.md, .claude/domain/features/task-implement-launcher.md, VERSION
Preconditions: 119
Feature: task-implement-launcher

---
