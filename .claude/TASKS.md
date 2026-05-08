# Tasks

Last task number: 5

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

Status: [DONE]
Files: commands/task-setup.md, scripts/lib-task-external.sh, scripts/cmd-task-impl.sh, bin/chosko-llm, docs/cli-help.txt, .claude/domain/task-workflow.md, tests/smoke/task-setup.md, tests/smoke/cmd-task-impl.md
Preconditions: 1, 2

---

## 4. Task workflow — `/task-add` offers to commit the new task at the end

Status: [DONE]
Files: commands/task-add.md, tests/smoke/task-add.md
Preconditions: none

---

## 5. Task workflow — `/task-implement` prompts on dirty tree instead of hard-aborting

Status: [DONE]
Files: commands/task-implement.md, tests/smoke/task-implement.md
Preconditions: none
