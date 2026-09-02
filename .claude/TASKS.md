# Tasks

Last task number: 168

---

## 150. Add a `changelog` subcommand and point `--version` and `upgrade` at it

Status: [DONE]
Target: claude
Files: bin/chosko-llm, scripts/cmd-changelog.sh, scripts/lib.sh, scripts/cmd-version.sh, scripts/cmd-upgrade.sh, scripts/auto-upgrade.sh, docs/cli-help.txt, README.md, VERSION, CHANGELOG.md, .claude/context/cmd-changelog.md, .claude/context/INDEX.md, .claude/context/cli-entry.md, .claude/context/cmd-upgrade.md, .claude/context/shared-lib.md, .claude/domain/features/version-changelog.md
Preconditions: none
Feature: version-changelog

---

## 151. Add a `git-commit-style` claude-md snippet and cap task-engine's commit body

Status: [DONE]
Target: claude
Files: claude-md/git-commit-style.md, skills/task-engine/references/commit.md, skills/task-engine/SKILL.md, docs/authoring-guide.md, .claude/context/features.md, .claude/context/INDEX.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 152. Add a REQUIRES column to `ls`

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, scripts/lib.sh, docs/cli-help.txt, VERSION, CHANGELOG.md, .claude/context/cmd-ls.md, .claude/context/shared-lib.md, .claude/context/INDEX.md
Preconditions: 153

---

## 153. Order `ls` output by feature name instead of by kind

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, docs/cli-help.txt, VERSION, CHANGELOG.md, .claude/context/cmd-ls.md, .claude/context/INDEX.md
Preconditions: none

---

## 154. Fix zero-task rollup and replace `/production-status`'s Ready column with a Next column

Status: [DONE]
Target: claude
Files: commands/production-status.md, .claude/context/features.md, .claude/context/INDEX.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 155. Parse each feature's frontmatter once per `ls` row

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, scripts/lib.sh, VERSION, CHANGELOG.md, .claude/context/cmd-ls.md, .claude/context/shared-lib.md, .claude/context/INDEX.md
Preconditions: none

---

## 156. Re-sync the domain layer's `/production-status` description with the Next field

Status: [DONE]
Target: claude
Files: .claude/domain/product-workflow.md, .claude/domain/features/plan-readout.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 157. Key the iterate guard's status flip on the feature's status, not its `Tasks:` line

Status: [DONE]
Target: claude
Files: skills/architect/iterating.md, skills/architect/SKILL.md, .claude/domain/product-workflow.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 158. Add the review-budget protocol to `task-engine`

Status: [DONE]
Target: claude
Files: skills/task-engine/references/review-budget.md, skills/task-engine/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: task-peer-review

---

## 159. Add `--review-model` and `--review-effort` to `/task-implement`

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/review-rounds.md, skills/task-implement/delegated-runs.md, VERSION, CHANGELOG.md
Preconditions: 158
Feature: task-peer-review

---

## 160. Make `/task-review` honour the read budget and never run tests

Status: [DONE]
Target: claude
Files: skills/task-review/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 158
Feature: task-peer-review

---

## 161. Update documentation for feature `task-peer-review`

Status: [DONE]
Target: claude
Files: README.md, .claude/context/features.md, .claude/context/INDEX.md, VERSION, CHANGELOG.md
Preconditions: 158, 159, 160
Feature: task-peer-review

---

## 162. Record the Next field's omission case in the domain layer

Status: [DONE]
Target: claude
Files: .claude/domain/product-workflow.md, .claude/domain/features/plan-readout.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 163. Find and fix what made `ls` slow

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, scripts/lib.sh, .claude/context/cmd-ls.md, .claude/context/shared-lib.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 164. Rewrite CHANGELOG to terse one-liner bullets and stop bumping VERSION for doc-only changes

Status: [DONE]
Target: claude
Files: CLAUDE.md, docs/authoring-guide.md, scripts/lib.sh, CHANGELOG.md, VERSION
Preconditions: none

---

## 165. Give runbooks incremental IDs and show them in `/runbook-list`

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/runbook-schema.md, skills/runbook-run/SKILL.md, commands/runbook-create.md, commands/runbook-clean.md, commands/runbook-list.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 166. Add `/runbook-describe`

Status: [DONE]
Target: claude
Files: commands/runbook-describe.md, skills/runbook-run/references/runbook-schema.md, commands/runbook-create.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: 165

---

## 167. Relay a subagent's spawns through the orchestrator when nesting is unavailable

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/subagent-contract.md, skills/runbook-run/SKILL.md, commands/runbook-create.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 168. Reconcile the runbook suite's documentation with IDs, describe and the spawn relay

Status: [MISSING]
Target: claude
Files: .claude/domain/features/runbook-suite.md, README.md
Preconditions: 165, 166, 167
