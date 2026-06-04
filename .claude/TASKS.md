# Tasks

Last task number: 34

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

## 23. Remove the commit-scaffolding prompt from `/task-setup`; leave changes uncommitted

Status: [DONE]
Target: claude
Files: commands/task-setup.md, commands/project-setup.md, tests/smoke/task-setup.md, tests/smoke/project-setup.md, .claude/context/features.md
Preconditions: none

---

## 24. Make `/context-update` auto-commit its changes

Status: [DONE]
Target: claude
Files: commands/context-update.md, tests/smoke/context-update.md, .claude/context/features.md, .claude/domain/context-workflow.md
Preconditions: none

---

## 25. Add a `--commit` flag to commands that leave changes uncommitted

Status: [DONE]
Target: claude
Files: commands/context-build.md, commands/task-enrich.md, commands/refactor-codebase.md, commands/refactor-tests.md, commands/task-setup.md, commands/project-setup.md, tests/smoke/context-build.md, tests/smoke/task-enrich.md, tests/smoke/refactor-codebase.md, tests/smoke/refactor-tests.md, tests/smoke/task-setup.md, tests/smoke/project-setup.md, .claude/context/features.md
Preconditions: 23, 24

---

## 26. Add a `--no-commit` flag to commands that auto-commit changes

Status: [DONE]
Target: claude
Files: commands/task-add.md, commands/task-clean.md, commands/task-implement.md, commands/context-update.md, tests/smoke/task-add.md, tests/smoke/task-clean.md, tests/smoke/task-implement.md, tests/smoke/context-update.md, .claude/context/features.md
Preconditions: 23, 24

---

## 27. Audit and update user- and developer-facing docs to reflect recent changes

Status: [DONE]
Target: claude
Files: README.md, docs/cli-help.txt, docs/authoring-guide.md, tests/smoke/README.md
Preconditions: 23, 24, 25, 26

---

## 28. Add a `show` suggestion to `chosko-llm ls` output

Status: [DONE]
Target: claude
Files: scripts/cmd-ls.sh, tests/smoke/cmd-ls.md
Preconditions: none

---

## 29. Add a "Workflows" section to README before "Development"

Status: [DONE]
Target: claude
Files: README.md
Preconditions: none

---

## 30. Daily auto-upgrade for the `chosko-llm` CLI

Status: [DONE]
Target: claude
Files: bin/chosko-llm, scripts/auto-upgrade.sh, scripts/lib.sh, scripts/cmd-upgrade.sh, install.sh, .gitignore, docs/cli-help.txt, README.md, .claude/context/cli-entry.md, tests/smoke/auto-upgrade.md
Preconditions: none

---

## 31. Make /project-setup GATHER ask one question at a time and seed CLAUDE.md iteratively

Status: [DONE]
Target: claude
Files: commands/project-setup.md, tests/smoke/project-setup.md
Preconditions: none

---

## 32. Document a versioning policy for the root VERSION file in CLAUDE.md

Status: [DONE]
Target: claude
Files: CLAUDE.md, README.md
Preconditions: none

---

## 33. Make `uninstall` invokable via the chosko-llm proxy

Status: [MISSING]
Target: claude
Files: scripts/cmd-uninstall.sh, bin/chosko-llm, uninstall.sh, docs/cli-help.txt, README.md, .claude/context/cli-entry.md, tests/smoke/cmd-uninstall.md
Preconditions: none

---

## 34. Add a `--version` flag to the base `chosko-llm` command

Status: [MISSING]
Target: claude
Files: bin/chosko-llm, scripts/lib.sh, install.sh, docs/cli-help.txt, README.md, .claude/context/cli-entry.md, tests/smoke/version.md
Preconditions: none

---
