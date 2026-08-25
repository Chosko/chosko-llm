# Tasks

Last task number: 149

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

Status: [DONE]
Target: claude
Files: scripts/cmd-task-impl.sh, scripts/lib-task-external.sh, scripts/check-task-parity.sh, scripts/cmd-help.sh, bin/chosko-llm, commands/task-enrich.md, commands/task-add.md, commands/task-setup.md, commands/domain-setup.md, commands/project-setup.md, commands/unity-mcp-setup.md, skills/task-implement/SKILL.md, skills/task-implement/body-schemas.md, skills/architect/iterating.md, docs/cli-help.txt, docs/authoring-guide.md, README.md, CLAUDE.md, VERSION, .claude/external/implement-prompt.md, .claude/external/tests-prompt.md, .claude/context/INDEX.md, .claude/context/features.md, .claude/context/cli-entry.md, .claude/context/cmd-help.md, .claude/context/cmd-task-impl.md, .claude/context/lib-task-external.md, .claude/domain/INDEX.md, .claude/domain/task-workflow.md, .claude/domain/product-design.md, .claude/domain/product-workflow.md, .claude/domain/technical-direction.md
Preconditions: none

---

## 119. Turn /task-implement's batch parent into a launcher

Status: [DONE]
Target: claude
Files: skills/task-implement/delegated-runs.md, skills/task-implement/SKILL.md, VERSION
Preconditions: 118
Feature: task-implement-launcher

---

## 120. Update documentation for feature task-implement-launcher

Status: [DONE]
Target: claude
Files: .claude/context/features.md, .claude/context/INDEX.md, .claude/domain/task-workflow.md, .claude/domain/features/task-implement-launcher.md, VERSION
Preconditions: 119
Feature: task-implement-launcher

---

## 121. Add the /task-review skill

Status: [DONE]
Target: claude
Files: skills/task-review/SKILL.md, skills/task-review/remote-diffs.md, VERSION
Preconditions: 118
Feature: task-peer-review

---

## 122. Add the /task-iterate skill

Status: [DONE]
Target: claude
Files: skills/task-iterate/SKILL.md, VERSION
Preconditions: 118, 121
Feature: task-peer-review

---

## 123. Add the --review / --rounds loop to /task-implement

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/review-rounds.md, skills/task-implement/delegated-runs.md, VERSION
Preconditions: 118, 119, 121, 122
Feature: task-peer-review

---

## 124. Update documentation for feature task-peer-review

Status: [DONE]
Target: claude
Files: README.md, docs/authoring-guide.md, .claude/context/features.md, .claude/context/INDEX.md, .claude/domain/task-workflow.md, .claude/domain/features/task-peer-review.md, VERSION
Preconditions: 121, 122, 123
Feature: task-peer-review

---

## 125. Add the `requires:` frontmatter field and its install-time resolution

Status: [DONE]
Target: claude
Files: scripts/lib.sh, scripts/cmd-add.sh, scripts/cmd-rm.sh, docs/authoring-guide.md, docs/cli-help.txt, VERSION
Preconditions: none
Feature: shared-phase-engine

---

## 126. Create the task-engine skill by verbatim extraction

Status: [DONE]
Target: claude
Files: skills/task-engine/SKILL.md, skills/task-engine/references/resolution.md, skills/task-engine/references/status.md, skills/task-engine/references/targets.md, skills/task-engine/references/stale.md, skills/task-engine/references/tree.md, skills/task-engine/references/commit.md, VERSION
Preconditions: 118, 125
Feature: shared-phase-engine

---

## 127. Migrate /task-list onto the task-engine

Status: [DONE]
Target: claude
Files: commands/task-list.md, VERSION
Preconditions: 125, 126
Feature: shared-phase-engine

---

## 128. Migrate /task-clean onto the task-engine

Status: [DONE]
Target: claude
Files: commands/task-clean.md, VERSION
Preconditions: 125, 126, 127
Feature: shared-phase-engine

---

## 129. Migrate /task-add onto the task-engine

Status: [DONE]
Target: claude
Files: commands/task-add.md, VERSION
Preconditions: 125, 126, 128
Feature: shared-phase-engine

---

## 130. Migrate /task-implement onto the task-engine

Status: [MISSING]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/dirty-tree.md, skills/task-implement/body-schemas.md, skills/task-implement/delegated-runs.md, skills/task-implement/review-rounds.md, VERSION
Preconditions: 118, 119, 123, 125, 126, 129
Feature: shared-phase-engine

---

## 131. Update documentation for feature shared-phase-engine

Status: [MISSING]
Target: claude
Files: README.md, docs/authoring-guide.md, .claude/context/shared-lib.md, .claude/context/cmd-add.md, .claude/context/cmd-rm.md, .claude/context/features.md, .claude/context/INDEX.md, .claude/domain/task-workflow.md, .claude/domain/features/shared-phase-engine.md, VERSION
Preconditions: 125, 126, 127, 128, 129, 130
Feature: shared-phase-engine

---

## 132. Add the /session-save command

Status: [DONE]
Target: claude
Files: commands/session-save.md, VERSION
Preconditions: none
Feature: session-continuity

---

## 133. Add the /session-resume command

Status: [DONE]
Target: claude
Files: commands/session-resume.md, VERSION
Preconditions: 132
Feature: session-continuity

---

## 134. Update documentation for feature session-continuity

Status: [DONE]
Target: claude
Files: README.md, .claude/context/features.md, .claude/domain/features/session-continuity.md, docs/authoring-guide.md, VERSION
Preconditions: 132, 133
Feature: session-continuity

---

## 135. Record the `.claude/skills/` exemption to the VERSION bump rule

Status: [DONE]
Target: claude
Files: CLAUDE.md, VERSION
Preconditions: none
Feature: repo-local-audits

---

## 136. Add the repo-local /context-budget audit skill

Status: [DONE]
Target: claude
Files: .claude/skills/context-budget/SKILL.md
Preconditions: 135
Feature: repo-local-audits

---

## 137. Add the repo-local /rule-overlap audit skill

Status: [DONE]
Target: claude
Files: .claude/skills/rule-overlap/SKILL.md
Preconditions: 135
Feature: repo-local-audits

---

## 138. Update documentation for feature repo-local-audits

Status: [DONE]
Target: claude
Files: README.md, docs/authoring-guide.md, .claude/context/features.md, .claude/domain/features/repo-local-audits.md, VERSION
Preconditions: 135, 136, 137
Feature: repo-local-audits

---

## 139. Replace /task-add's ownership notice with a pre-authorisation gate

Status: [MISSING]
Target: claude
Files: commands/task-add.md, .claude/domain/product-workflow.md, .claude/domain/task-workflow.md, .claude/context/features.md, .claude/context/INDEX.md, VERSION
Preconditions: 129

---

## 140. Add the /runbook-run skill with the schema and subagent-contract references

Status: [MISSING]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/runbook-run/references/runbook-schema.md, skills/runbook-run/references/subagent-contract.md, VERSION
Preconditions: 125
Feature: runbook-suite

---

## 141. Add the /runbook-create command

Status: [MISSING]
Target: claude
Files: commands/runbook-create.md, VERSION
Preconditions: 125, 140
Feature: runbook-suite

---

## 142. Add the /runbook-list command

Status: [MISSING]
Target: claude
Files: commands/runbook-list.md, VERSION
Preconditions: 125, 140
Feature: runbook-suite

---

## 143. Add the /runbook-clean command

Status: [MISSING]
Target: claude
Files: commands/runbook-clean.md, VERSION
Preconditions: 125, 140
Feature: runbook-suite

---

## 144. Add the /runbook-suggest skill

Status: [MISSING]
Target: claude
Files: skills/runbook-suggest/SKILL.md, VERSION
Preconditions: 125, 140, 141
Feature: runbook-suite

---

## 145. Update documentation for feature runbook-suite

Status: [MISSING]
Target: claude
Files: README.md, .claude/context/features.md, docs/authoring-guide.md, .claude/domain/features/runbook-suite.md, VERSION
Preconditions: 125, 140, 141, 142, 143, 144
Feature: runbook-suite

---

## 146. Backfill CHANGELOG.md and make a VERSION bump require an entry

Status: [DONE]
Target: claude
Files: CHANGELOG.md, CLAUDE.md, docs/authoring-guide.md, VERSION
Preconditions: none
Feature: version-changelog

---

## 147. Add the check-changelog.sh authoring guard

Status: [DONE]
Target: claude
Files: scripts/check-changelog.sh, docs/authoring-guide.md, CHANGELOG.md, VERSION
Preconditions: 146
Feature: version-changelog

---

## 148. Print what changed on upgrade, from CHANGELOG.md

Status: [DONE]
Target: claude
Files: scripts/lib.sh, scripts/cmd-upgrade.sh, CHANGELOG.md, VERSION
Preconditions: 146
Feature: version-changelog

---

## 149. Update documentation for feature version-changelog

Status: [DONE]
Target: claude
Files: README.md, docs/cli-help.txt, .claude/context/shared-lib.md, .claude/context/cmd-upgrade.md, .claude/context/INDEX.md, CHANGELOG.md, VERSION
Preconditions: 146, 147, 148
Feature: version-changelog

---
