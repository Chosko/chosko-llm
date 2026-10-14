# Tasks

Last task number: 336

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

## 329. Add --parallel <N|max> to /task-implement with the scheduler, barriers and landing

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/task-engine/references/resolution.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 325
Feature: parallel-task-runs

---

## 330. Add the Files: overlap rule and the Parallel-safe files marker

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, CLAUDE.md, VERSION, CHANGELOG.md
Preconditions: 329
Feature: parallel-task-runs

---

## 331. Update documentation for feature `parallel-task-runs`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, docs/cli-help.txt, .claude/context/task-implement.md, .claude/context/task-implement-delegation.md, .claude/context/task-engine.md, .claude/context/features.md, .claude/context/INDEX.md, .claude/domain/task-workflow.md
Preconditions: 329, 330
Feature: parallel-task-runs

---

## 332. Add Parallelism: to the runbook schema and the worktree rules to the subagent contract

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/runbook-schema.md, skills/runbook-run/references/subagent-contract.md, skills/runbook-run/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 325
Feature: parallel-runbooks

---

## 333. Add --parallel <N|max> and graph scheduling to /runbook-run

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 332
Feature: parallel-runbooks

---

## 334. Author parallel runbooks in /runbook-create

Status: [DONE]
Target: claude
Files: commands/runbook-create.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 332
Feature: parallel-runbooks

---

## 335. Read parallel runbooks in /runbook-describe and lint them in /pipeline-check

Status: [DONE]
Target: claude
Files: commands/runbook-describe.md, skills/pipeline-engine/references/lint.md, skills/pipeline-engine/SKILL.md, commands/pipeline-check.md, VERSION, CHANGELOG.md
Preconditions: 332
Feature: parallel-runbooks

---

## 336. Update documentation for feature `parallel-runbooks`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, docs/cli-help.txt, .claude/context/runbook-suite.md, .claude/context/runbook-run.md, .claude/context/runbook-run-loop.md, .claude/context/runbook-run-contracts.md, .claude/context/runbook-create.md, .claude/context/runbook-readers.md, .claude/context/pipeline-readers.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 332, 333, 334, 335
Feature: parallel-runbooks

---
