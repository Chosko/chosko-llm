# Tasks

Last task number: 52

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

Status: [MISSING]
Target: claude
Files: skills/unity-mcp-skill/SKILL.md, skills/unity-mcp-skill/references/tools-reference.md, skills/unity-mcp-skill/references/workflows.md, .claude/context/features.md, README.md, VERSION
Preconditions: none

---
