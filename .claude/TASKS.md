# Tasks

Last task number: 243

---

## 227. Make `/runbook-create` commit by default

Status: [DONE]
Target: claude
Files: commands/runbook-create.md, commands/pipeline-patch.md, skills/pipeline-revise/SKILL.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 228. Make `/session-save` commit by default

Status: [DONE]
Target: claude
Files: commands/session-save.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 229. Make `/pipeline-patch` and `/pipeline-revise` commit once, at the end

Status: [DONE]
Target: claude
Files: commands/pipeline-patch.md, skills/pipeline-revise/SKILL.md, skills/pipeline-revise/delete.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 227

---

## 230. Update documentation for the new commit defaults

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, docs/authoring-guide.md, .claude/domain/product-workflow.md, .claude/domain/features/authoring-commit-default.md, .claude/domain/features/pipeline-revision.md, .claude/domain/features/session-continuity.md, .claude/domain/features/runbook-suite.md, .claude/domain/product-design.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 227, 228, 229

---

## 231. Decide the editorial question when the evidence is clear, ask only when it isn't

Status: [DONE]
Target: claude
Files: skills/architect/amend.md, skills/architect/SKILL.md, skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/delete.md, skills/pipeline-revise/reorder.md, .claude/domain/features/owner-amend-arms.md, .claude/domain/features/pipeline-revision.md, .claude/domain/product-workflow.md, docs/reference.md, README.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 232. Store a per-runbook step counter in the body header

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/runbook-schema.md, commands/runbook-create.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 233. Add `/runbook-prune` — remove done steps, keep their ids in an `Archive:` line

Status: [DONE]
Target: claude
Files: commands/runbook-prune.md, skills/runbook-run/references/runbook-schema.md, skills/runbook-run/SKILL.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 232

---

## 234. Document `/runbook-prune` and the two new runbook header fields

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, .claude/domain/features/runbook-suite.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 232, 233

---

## 235. Surface a runbook's archived step ids in `/runbook-describe`

Status: [DONE]
Target: claude
Files: commands/runbook-describe.md, .claude/domain/features/runbook-suite.md, docs/reference.md, .claude/context/features.md, .claude/context/INDEX.md, VERSION, CHANGELOG.md
Preconditions: 232, 233

---

## 236. Add `/follow-ups` — list what this conversation left unhandled

Status: [DONE]
Target: claude
Files: commands/follow-ups.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 237. Call `/follow-ups` at the end of every `/runbook-run` and `/task-implement` run

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/task-implement/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 236

---

## 238. Document `/follow-ups` and the runners' closing call

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, .claude/domain/features/runbook-suite.md, .claude/domain/features/task-implement-launcher.md, .claude/context/features.md, .claude/context/INDEX.md
Preconditions: 236, 237

---

## 239. Cite reference files relative to the citing body, so they resolve under `--local`

Status: [DONE]
Target: claude
Files: docs/authoring-guide.md, scripts/check-home-paths.sh, CLAUDE.md, README.md, commands/pipeline-check.md, commands/pipeline-patch.md, commands/runbook-clean.md, commands/runbook-create.md, commands/runbook-describe.md, commands/runbook-list.md, commands/runbook-prune.md, commands/task-add.md, commands/task-list.md, skills/architect/council-gate.md, skills/claude-council/SKILL.md, skills/pipeline-engine/SKILL.md, skills/pipeline-engine/references/graph.md, skills/pipeline-engine/references/lint.md, skills/pipeline-engine/references/probes.md, skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/delete.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/reorder.md, skills/product-design/council-gate.md, skills/runbook-run/SKILL.md, skills/runbook-run/references/runbook-schema.md, skills/runbook-run/references/step-amend.md, skills/task-clean/SKILL.md, skills/task-clean/backfill.md, skills/task-engine/SKILL.md, skills/task-engine/references/amend.md, skills/task-engine/references/commit.md, skills/task-engine/references/resolution.md, skills/task-engine/references/stale.md, skills/task-engine/references/status.md, skills/task-engine/references/tree.md, skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/task-implement/review-rounds.md, skills/task-review/SKILL.md, .claude/domain/features/shared-phase-engine.md, .claude/domain/features/runbook-suite.md, .claude/domain/features/pipeline-engine.md, .claude/context/features.md, .claude/context/INDEX.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 240. Set the description contract: short what+when in frontmatter, flags in the body header

Status: [MISSING]
Target: claude
Files: docs/authoring-guide.md, scripts/cmd-show.sh, commands/runbook-clean.md, skills/claude-council/SKILL.md, skills/unity-mcp-skill/SKILL.md, skills/task-engine/SKILL.md, skills/pipeline-engine/SKILL.md, .claude/skills/context-budget/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 241. Rewrite the pipeline-core descriptions to the contract; hide the two reference libraries

Status: [MISSING]
Target: claude
Files: commands/task-add.md, commands/task-list.md, commands/task-setup.md, commands/follow-ups.md, commands/production-status.md, commands/pipeline-check.md, commands/pipeline-patch.md, commands/domain-setup.md, skills/task-clean/SKILL.md, skills/task-implement/SKILL.md, skills/task-review/SKILL.md, skills/task-iterate/SKILL.md, skills/task-engine/SKILL.md, skills/pipeline-revise/SKILL.md, skills/pipeline-suggest/SKILL.md, skills/pipeline-engine/SKILL.md, skills/production-plan/SKILL.md, skills/product-design/SKILL.md, skills/product-roadmap/SKILL.md, skills/architect/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 240

---

## 242. Rewrite the runbook-suite and remaining descriptions; hide the wizards; refresh the local install

Status: [MISSING]
Target: claude
Files: commands/runbook-create.md, commands/runbook-list.md, commands/runbook-describe.md, commands/runbook-clean.md, commands/runbook-prune.md, commands/session-save.md, commands/session-resume.md, commands/refactor-codebase.md, commands/refactor-tests.md, commands/project-setup.md, commands/unity-mcp-setup.md, skills/runbook-run/SKILL.md, skills/context-build/SKILL.md, skills/context-update/SKILL.md, skills/context-convert/SKILL.md, skills/unity-mcp-skill/SKILL.md, skills/claude-council/SKILL.md, skills/runbook-suggest/SKILL.md, .claude/commands/, .claude/skills/, VERSION, CHANGELOG.md
Preconditions: 240

---

## 243. Document the description contract and the hidden-feature set

Status: [MISSING]
Target: claude
Files: README.md, docs/reference.md, .claude/domain/features/repo-local-audits.md, .claude/domain/features/pipeline-suggest.md, .claude/domain/features/shared-phase-engine.md, .claude/context/features.md, .claude/context/cmd-show.md, .claude/context/INDEX.md
Preconditions: 241, 242
