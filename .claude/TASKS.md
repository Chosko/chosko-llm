# Tasks

Last task number: 16

---

## 10. cmd-ls — add STATUS column with up-to-date / updatable / not-installed / local-only labels

Status: [DONE]
Files: scripts/cmd-ls.sh, tests/smoke/cmd-ls.md, docs/cli-help.txt
Preconditions: none

---

## 11. cmd-update — skip already-up-to-date and locally-ahead features in --all mode

Status: [DONE]
Files: scripts/cmd-update.sh, tests/smoke/cmd-update.md, docs/cli-help.txt
Preconditions: none

---

## 12. task-clean — auto-commit pruned tasks after apply

Status: [DONE]
Files: commands/task-clean.md, tests/smoke/task-clean.md, .claude/context/features.md
Preconditions: none

---

## 13. task schema — introduce thin body format and target field

Status: [PENDING]
Target: claude
Files: .claude/domain/task-workflow.md
Preconditions: none

---

## 14. task-enrich — new skill to expand thin tasks for local LLM

Status: [PENDING]
Target: claude
Files: skills/task-enrich/SKILL.md, tests/smoke/task-enrich.md, .claude/context/features.md, .claude/domain/task-workflow.md
Preconditions: 13

---

## 15. task-add — thin body by default, --enrich option

Status: [PENDING]
Target: claude
Files: commands/task-add.md, tests/smoke/task-add.md
Preconditions: 13, 14

---

## 16. task-implement — warn on target: local tasks

Status: [PENDING]
Target: claude
Files: commands/task-implement.md, tests/smoke/task-implement.md
Preconditions: 13
