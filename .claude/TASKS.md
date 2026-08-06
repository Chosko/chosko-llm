# Tasks

Last task number: 104

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

Status: [MISSING]
Target: claude
Files: scripts/cmd-ls.sh, scripts/cmd-show.sh, scripts/lib.sh, docs/cli-help.txt, .claude/context/cmd-ls.md, .claude/context/cmd-show.md, .claude/context/shared-lib.md, VERSION
Preconditions: none

---
