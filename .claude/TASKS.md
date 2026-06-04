# Tasks

Last task number: 22

---

## 17. Add `show` command to inspect a single feature

Status: [DONE]
Target: claude
Files: scripts/cmd-show.sh, bin/chosko-llm, docs/cli-help.txt, README.md, tests/smoke/cmd-show.md
Preconditions: none

---

## 18. Print actionable suggestions at the end of `ls` output

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, tests/smoke/cmd-ls.md
Preconditions: none

---

## 19. Add semantic color to chosko-llm command output

Status: [DONE]
Target: claude
Files: scripts/lib.sh, scripts/cmd-ls.sh, scripts/cmd-add.sh, scripts/cmd-rm.sh, scripts/cmd-update.sh, scripts/cmd-upgrade.sh, scripts/cmd-help.sh, .claude/context/shared-lib.md, tests/smoke/colors.md
Preconditions: none

---

## 20. Add Windows cmd/PowerShell entry point (`chosko-llm.cmd` shim)

Status: [DONE]
Target: claude
Files: bin/chosko-llm.cmd, install.sh, .gitattributes, README.md, .claude/context/cli-entry.md, tests/smoke/windows-shim.md
Preconditions: none

---

## 21. Improve colours: color-code feature kinds and implement colors for `show` command

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, scripts/cmd-show.sh, scripts/lib.sh, .claude/context/shared-lib.md, tests/smoke/colors.md, tests/smoke/cmd-show.md
Preconditions: 19

---

## 22. Add `project-setup` command: interactive wizard for first-time project initialization

Status: [DONE]
Target: claude
Files: commands/project-setup.md, tests/smoke/project-setup.md, .claude/context/features.md
Preconditions: none

---
