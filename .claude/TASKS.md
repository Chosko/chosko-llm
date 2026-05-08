# Tasks

Last task number: 3

---

## 1. Task workflow — make backlog consumable by external LLMs (aider + Ollama)

Status: [DONE]
Files: commands/task-add.md, commands/task-setup.md, tests/smoke/task-add.md, tests/smoke/task-setup.md
Preconditions: none

---

## 2. Task workflow — `task-implement` uses the richer body as a context starting point

Status: [DONE]
Files: commands/task-implement.md, tests/smoke/task-implement.md
Preconditions: 1

---

## 3. Task workflow — automate the 8-step `/task-implement` sequence for external LLMs (aider + Ollama)

Status: [MISSING]
Files: commands/task-setup.md, scripts/lib-task-external.sh, scripts/cmd-task-impl.sh, bin/chosko-llm, docs/cli-help.txt, .claude/domain/task-workflow.md, tests/smoke/task-setup.md, tests/smoke/cmd-task-impl.md
Preconditions: 1, 2
