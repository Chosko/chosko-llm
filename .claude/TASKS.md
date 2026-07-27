# Tasks

Last task number: 78

---

## 35. Propose splitting a /task-add description into multiple tasks when useful

Status: [DONE]
Target: claude
Files: commands/task-add.md, tests/smoke/task-add.md, .claude/domain/task-workflow.md, .claude/context/features.md, README.md, VERSION
Preconditions: none

---

## 36. Add a git-log substitute to the Plastic `## VCS` snippet so context-update incremental mode works

Status: [DONE]
Target: claude
Files: commands/project-setup.md, tests/smoke/project-setup.md, VERSION
Preconditions: none

---

## 37. Support human-in-the-loop tasks: claude+human / human targets and a Manual interventions body section

Status: [DONE]
Target: claude
Files: commands/task-add.md, commands/task-implement.md, commands/task-enrich.md, commands/task-list.md, .claude/domain/task-workflow.md, .claude/context/features.md, tests/smoke/task-add.md, tests/smoke/task-implement.md, tests/smoke/task-enrich.md, tests/smoke/task-list.md, README.md, VERSION
Preconditions: none

---

## 38. Split the dirty-tree "proceed" option in /task-implement into commit vs. leave-uncommitted

Status: [DONE]
Target: claude
Files: commands/task-implement.md, tests/smoke/task-implement.md, VERSION
Preconditions: none

---

## 39. Persist a project's "no automated test suite" testing policy so /task-implement stops asking every run

Status: [DONE]
Target: claude
Files: commands/task-implement.md, CLAUDE.md, tests/smoke/task-implement.md, VERSION
Preconditions: none

---

## 40. Make /task-implement explain the manual step before asking the human to confirm it

Status: [DONE]
Target: claude
Files: commands/task-implement.md, tests/smoke/task-implement.md, VERSION
Preconditions: none

---

## 41. Remove the smoke-test suite and update docs that reference it

Status: [DONE]
Target: claude
Files: tests/smoke/, CLAUDE.md, README.md, docs/authoring-guide.md, .claude/context/features.md, .claude/context/INDEX.md, .claude/domain/context-workflow.md, VERSION
Preconditions: none

---

## 42. Fix the double test run in cmd-task-impl.sh — capture once, branch on exit status

Status: [DONE]
Target: claude
Files: scripts/cmd-task-impl.sh, .claude/context/cmd-task-impl.md, VERSION
Preconditions: none

---

## 43. Add "mirrored copy" sync markers to the duplicated test-runner tables

Status: [DONE]
Target: claude
Files: commands/task-implement.md, commands/task-setup.md, VERSION
Preconditions: none

---

## 44. Convert /task-implement from a command into a skill with on-demand supporting files

Status: [DONE]
Target: claude
Files: commands/task-implement.md, skills/task-implement/, docs/authoring-guide.md, README.md, .claude/context/features.md, VERSION
Preconditions: 43

---

## 45. Add a parity guard between the /task-implement prompt and cmd-task-impl.sh

Status: [DONE]
Target: claude
Files: scripts/check-task-parity.sh, docs/authoring-guide.md, VERSION
Preconditions: 44

---

## 46. Remove the redundant TOOL DISCIPLINE blocks — the global tool-usage-policy already covers them

Status: [DONE]
Target: claude
Files: commands/, docs/authoring-guide.md, README.md, VERSION
Preconditions: none

---

## 47. Single-source the non-git VCS rule — strengthen the injected ## VCS section, remove the per-command pointers

Status: [DONE]
Target: claude
Files: commands/project-setup.md, commands/task-setup.md, commands/task-enrich.md, commands/context-build.md, commands/context-update.md, commands/refactor-codebase.md, commands/refactor-tests.md, VERSION
Preconditions: none

---

## 48. Add /unity-mcp-setup — detect, install, and register the Unity MCP plugin, and record it per-project

Status: [DONE]
Target: claude
Files: commands/unity-mcp-setup.md, .claude/context/features.md, README.md, docs/cli-help.txt, VERSION
Preconditions: none

---

## 49. Teach /task-implement to drive Unity via MCP at manual checkpoints, gated and opt-outable

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/unity-mcp-checkpoints.md, skills/task-implement/human-in-loop.md, scripts/check-task-parity.sh, .claude/context/features.md, README.md, VERSION
Preconditions: 48

---

## 50. Offer to run /unity-mcp-setup from /project-setup on Unity projects

Status: [DONE]
Target: claude
Files: commands/project-setup.md, .claude/context/features.md, VERSION
Preconditions: 48

---

## 51. Add `chosko-llm channel` — point the managed clone at a branch to test unmerged work

Status: [DONE]
Target: claude
Files: scripts/cmd-channel.sh, bin/chosko-llm, scripts/auto-upgrade.sh, docs/cli-help.txt, README.md, .claude/context/cmd-channel.md, .claude/context/cli-entry.md, .claude/context/INDEX.md, VERSION
Preconditions: none

---

## 52. Add the unity-mcp-skill skill as a shipped feature

Status: [DONE]
Target: claude
Files: skills/unity-mcp-skill/SKILL.md, skills/unity-mcp-skill/references/tools-reference.md, skills/unity-mcp-skill/references/workflows.md, .claude/context/features.md, README.md, VERSION
Preconditions: none

---

## 53. Author the product-workflow domain doc — the design→architecture→task pipeline contract

Status: [DONE]
Target: claude
Files: .claude/domain/product-workflow.md, .claude/context/INDEX.md, CLAUDE.md, VERSION
Preconditions: none

---

## 54. Extend the backlog schema — the [STALE] status and the Feature: slug line

Status: [DONE]
Target: claude
Files: commands/task-add.md, commands/task-list.md, commands/task-clean.md, commands/task-setup.md, skills/task-implement/SKILL.md, scripts/check-task-parity.sh, scripts/cmd-task-impl.sh, .claude/domain/task-workflow.md, .claude/context/cmd-task-impl.md, .claude/context/features.md, README.md, VERSION
Preconditions: 53

---

## 55. Add /domain-setup — scaffold the domain knowledge layer and the FEATURES.md index

Status: [DONE]
Target: claude
Files: commands/domain-setup.md, .claude/context/features.md, README.md, VERSION
Preconditions: 53

---

## 56. Wire /domain-setup into the /project-setup wizard

Status: [DONE]
Target: claude
Files: commands/project-setup.md, .claude/context/features.md, VERSION
Preconditions: 55

---

## 57. Add the /product-design skill — resumable high-level product and business-model design

Status: [DONE]
Target: claude
Files: skills/product-design/SKILL.md, skills/product-design/document-templates.md, skills/product-design/business-model.md, skills/product-design/resuming.md, .claude/context/features.md, README.md, VERSION
Preconditions: 53, 55

---

## 58. Add the /architect skill — turn high-level features into low-level feature docs

Status: [DONE]
Target: claude
Files: skills/architect/SKILL.md, skills/architect/tech-stack-selection.md, skills/architect/feature-doc-template.md, skills/architect/iterating.md, .claude/context/features.md, README.md, VERSION
Preconditions: 54, 57

---

## 59. Teach /task-add to author and reconcile tasks from a feature doc via feature=<slug>

Status: [DONE]
Target: claude
Files: commands/task-add.md, .claude/domain/task-workflow.md, .claude/context/features.md, README.md, VERSION
Preconditions: 54, 58

---

## 60. Teach /task-clean to prune pruned task IDs from FEATURES.md

Status: [DONE]
Target: claude
Files: commands/task-clean.md, .claude/context/features.md, VERSION
Preconditions: 59

---

## 61. Document the product pipeline end-to-end in README and the authoring guide

Status: [DONE]
Target: claude
Files: README.md, docs/authoring-guide.md, .claude/context/features.md, .claude/context/INDEX.md, VERSION
Preconditions: 60

---

## 62. Add `chosko-llm export` — package a repo's Claude config as Markdown or a zip

Status: [DONE]
Target: claude
Files: scripts/cmd-export.sh, scripts/lib.sh, bin/chosko-llm, docs/cli-help.txt, README.md, .claude/context/cmd-export.md, .claude/context/cli-entry.md, .claude/context/shared-lib.md, .claude/context/INDEX.md, VERSION
Preconditions: none

---

## 63. Exclude .claude/TASKS.md and .claude/tasks/ from export; add clear file separators to the Markdown output

Status: [DONE]
Target: claude
Files: scripts/cmd-export.sh, .claude/context/cmd-export.md, VERSION
Preconditions: none

---

## 64. Add a `statusline` feature kind — ship the status bar config, installable via chosko-llm

Status: [MISSING]
Target: claude
Files: scripts/lib.sh, scripts/cmd-add.sh, scripts/cmd-rm.sh, scripts/cmd-update.sh, scripts/cmd-ls.sh, scripts/cmd-show.sh, statusline/session-statusline.sh, docs/authoring-guide.md, docs/cli-help.txt, README.md, .claude/context/features.md, .claude/context/shared-lib.md, .claude/context/cmd-add.md, .claude/context/cmd-ls.md, .claude/context/cmd-rm.md, .claude/context/cmd-update.md, .claude/context/cmd-show.md, .claude/context/INDEX.md, VERSION
Preconditions: none

---

## 65. Print a file-count/line-count report at the end of export, before the open-folder prompt

Status: [MISSING]
Target: claude
Files: scripts/cmd-export.sh, .claude/context/cmd-export.md, VERSION
Preconditions: none

---

## 66. Run /context-update full to refresh the navigation context layer

Status: [MISSING]
Target: claude
Files: .claude/context/*.md
Preconditions: none

---

## 67. Add exported repo Version and Created date to the export manifest

Status: [MISSING]
Target: claude
Files: scripts/cmd-export.sh, .claude/context/cmd-export.md, VERSION
Preconditions: none

---

## 68. Author the shared commit-then-push protocol and update the authoring guide's commit-control convention

Status: [MISSING]
Target: claude
Files: docs/authoring-guide.md, VERSION
Preconditions: none

---

## 69. Add push (with --no-push) to the task-backlog commands: task-add, task-setup, task-clean, task-enrich

Status: [MISSING]
Target: claude
Files: commands/task-add.md, commands/task-setup.md, commands/task-clean.md, commands/task-enrich.md, .claude/domain/task-workflow.md, README.md, VERSION
Preconditions: 68

---

## 70. Add push (with --no-push) to context-build and context-update

Status: [MISSING]
Target: claude
Files: commands/context-build.md, commands/context-update.md, .claude/domain/context-workflow.md, README.md, VERSION
Preconditions: 68

---

## 71. Add push (with --no-push) to refactor-codebase and refactor-tests

Status: [MISSING]
Target: claude
Files: commands/refactor-codebase.md, commands/refactor-tests.md, .claude/domain/refactor-workflow.md, README.md, VERSION
Preconditions: 68

---

## 72. Add push (with --no-push) to domain-setup, product-design, and architect

Status: [MISSING]
Target: claude
Files: commands/domain-setup.md, skills/product-design/SKILL.md, skills/architect/SKILL.md, .claude/domain/product-workflow.md, README.md, VERSION
Preconditions: 68

---

## 73. Add push (with --no-push) to project-setup, and document the Plastic push exemption in the injected VCS section

Status: [MISSING]
Target: claude
Files: commands/project-setup.md, README.md, VERSION
Preconditions: 68

---

## 74. Add push (with --no-push) to unity-mcp-setup

Status: [MISSING]
Target: claude
Files: commands/unity-mcp-setup.md, README.md, VERSION
Preconditions: 68

---

## 75. Add per-task push to /task-implement (skill + script), with --no-push

Status: [MISSING]
Target: claude
Files: skills/task-implement/SKILL.md, scripts/cmd-task-impl.sh, scripts/check-task-parity.sh, .claude/domain/task-workflow.md, README.md, VERSION
Preconditions: 68

---

## 76. Add a technical-direction phase and write-back to /product-design

Status: [MISSING]
Target: claude
Files: skills/product-design/SKILL.md, skills/product-design/technical-direction.md, skills/product-design/document-templates.md, skills/product-design/resuming.md, commands/domain-setup.md, .claude/domain/product-workflow.md, .claude/context/features.md, README.md, VERSION
Preconditions: none

---

## 77. Make /architect adopt technical-direction.md as the established stack

Status: [MISSING]
Target: claude
Files: skills/architect/SKILL.md, skills/architect/tech-stack-selection.md, .claude/domain/product-workflow.md, .claude/context/features.md, README.md, VERSION
Preconditions: 76

---

## 78. Sweep the conversation for uncaptured design detail at the end of /product-design PHASE 3

Status: [MISSING]
Target: claude
Files: skills/product-design/SKILL.md, .claude/context/features.md, .claude/domain/product-workflow.md, README.md, VERSION
Preconditions: none

---
