# Tasks

Last task number: 328

---

## 323. Trim the git-commit-style policy to one short form and ban the Claude trailer lines

Status: [DONE]
Target: claude
Files: claude-md/git-commit-style.md, VERSION, CHANGELOG.md, README.md, docs/reference.md, .claude/context/claude-md-hook-statusline.md
Preconditions: none

---

## 324. `/context-update`: split oversized context files automatically and suggest `/context-convert` for large flat layers

Status: [DONE]
Target: claude
Files: skills/context-update/SKILL.md, skills/context-update/nested.md, VERSION, CHANGELOG.md, .claude/domain/context-workflow.md, .claude/context/
Preconditions: none

---

## 325. Add the worktree protocol to task-engine and wire its consumers

Status: [DONE]
Target: claude
Files: skills/task-engine/references/worktree.md, skills/task-engine/SKILL.md, skills/task-engine/references/commit.md, skills/task-engine/references/parking.md, skills/runbook-run/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: worktree-isolation

---

## 326. Sweep finished units' worktrees in /task-clean and /runbook-clean

Status: [DONE]
Target: claude
Files: skills/task-clean/SKILL.md, commands/runbook-clean.md, VERSION, CHANGELOG.md
Preconditions: 325
Feature: worktree-isolation

---

## 327. Show in-flight units from the worktree list in the statusline and the dashboard

Status: [DONE]
Target: claude
Files: statusline/pipeline-statusline.sh, skills/pipeline-dashboard/scripts/generate.sh, VERSION, CHANGELOG.md
Preconditions: 325
Feature: worktree-isolation

---

## 328. Update documentation for feature `worktree-isolation`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, .claude/context/task-engine.md, .claude/context/task-backlog.md, .claude/context/runbook-pruners.md, .claude/context/claude-md-hook-statusline.md, .claude/context/pipeline-dashboard.md, .claude/context/features.md, .claude/context/INDEX.md, .claude/domain/task-workflow.md
Preconditions: 325, 326, 327
Feature: worktree-isolation

---
