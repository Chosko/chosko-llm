# Tasks

Last task number: 156

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

Status: [MISSING]
Target: claude
Files: scripts/cmd-ls.sh, scripts/lib.sh, VERSION, CHANGELOG.md, .claude/context/cmd-ls.md, .claude/context/shared-lib.md, .claude/context/INDEX.md
Preconditions: none

---

## 156. Re-sync the domain layer's `/production-status` description with the Next field

Status: [MISSING]
Target: claude
Files: .claude/domain/product-workflow.md, .claude/domain/features/plan-readout.md, VERSION, CHANGELOG.md
Preconditions: none
