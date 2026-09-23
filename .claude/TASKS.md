# Tasks

Last task number: 267

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

Status: [DONE]
Target: claude
Files: docs/authoring-guide.md, scripts/cmd-show.sh, commands/runbook-clean.md, skills/claude-council/SKILL.md, skills/unity-mcp-skill/SKILL.md, skills/task-engine/SKILL.md, skills/pipeline-engine/SKILL.md, .claude/skills/context-budget/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 241. Rewrite the pipeline-core descriptions to the contract; hide the two reference libraries

Status: [DONE]
Target: claude
Files: commands/task-add.md, commands/task-list.md, commands/task-setup.md, commands/follow-ups.md, commands/production-status.md, commands/pipeline-check.md, commands/pipeline-patch.md, commands/domain-setup.md, skills/task-clean/SKILL.md, skills/task-implement/SKILL.md, skills/task-review/SKILL.md, skills/task-iterate/SKILL.md, skills/task-engine/SKILL.md, skills/pipeline-revise/SKILL.md, skills/pipeline-suggest/SKILL.md, skills/pipeline-engine/SKILL.md, skills/production-plan/SKILL.md, skills/product-design/SKILL.md, skills/product-roadmap/SKILL.md, skills/architect/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 240

---

## 242. Rewrite the runbook-suite and remaining descriptions; hide the wizards; refresh the local install

Status: [DONE]
Target: claude
Files: commands/runbook-create.md, commands/runbook-list.md, commands/runbook-describe.md, commands/runbook-clean.md, commands/runbook-prune.md, commands/session-save.md, commands/session-resume.md, commands/refactor-codebase.md, commands/refactor-tests.md, commands/project-setup.md, commands/unity-mcp-setup.md, skills/runbook-run/SKILL.md, skills/context-build/SKILL.md, skills/context-update/SKILL.md, skills/context-convert/SKILL.md, skills/unity-mcp-skill/SKILL.md, skills/claude-council/SKILL.md, skills/runbook-suggest/SKILL.md, .claude/commands/, .claude/skills/, VERSION, CHANGELOG.md
Preconditions: 240

---

## 243. Document the description contract and the hidden-feature set

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, .claude/domain/features/repo-local-audits.md, .claude/domain/features/pipeline-suggest.md, .claude/domain/features/shared-phase-engine.md, .claude/context/features.md, .claude/context/cmd-show.md, .claude/context/INDEX.md
Preconditions: 241, 242

---

## 244. Make `/runbook-run` quiet between steps and exhaustive in its closing report

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, docs/reference.md, .claude/domain/features/runbook-suite.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: 242

---

## 245. Bind the relay child with a fixed contract block; check the result file exists before replying

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/runbook-run/references/subagent-contract.md, docs/reference.md, .claude/domain/features/runbook-suite.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: 244

---

## 246. Defer the feature-flip proposal to the outermost run

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/runbook-run/SKILL.md, skills/runbook-run/references/subagent-contract.md, .claude/domain/task-workflow.md, .claude/domain/features/task-implement-launcher.md, .claude/domain/features/runbook-suite.md, docs/reference.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: 245

---

## 247. Ship `claude-md:editing-discipline` and cite it from the authoring guide, the feature template and `/task-review`

Status: [DONE]
Target: claude
Files: claude-md/editing-discipline.md, CLAUDE.md, docs/authoring-guide.md, skills/architect/feature-doc-template.md, skills/architect/SKILL.md, skills/task-review/SKILL.md, docs/reference.md, README.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 248. Add `/doc-consolidate`: rewrite a document under the editing discipline, with a drops-only ledger and an independent verifier

Status: [DONE]
Target: claude
Files: skills/doc-consolidate/SKILL.md, skills/doc-consolidate/verifier.md, docs/reference.md, README.md, docs/cli-help.txt, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: 247

---

## 249. Reframe `/task-add`'s ownership question as a design-change check and drop the read-only marker

Status: [DONE]
Target: claude
Files: commands/task-add.md, skills/task-implement/SKILL.md, skills/task-engine/SKILL.md, skills/task-engine/references/amend.md, skills/pipeline-engine/SKILL.md, skills/pipeline-engine/references/routing.md, .claude/domain/task-workflow.md, .claude/domain/product-workflow.md, .claude/context/features.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 250. Two-group closing report for `/task-implement` and `/task-review`; consequential edits are in scope, untraceable doc edits are a finding

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/review-rounds.md, skills/task-implement/delegated-runs.md, skills/task-review/SKILL.md, commands/task-add.md, .claude/domain/task-workflow.md, .claude/domain/features/task-peer-review.md, .claude/context/features.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: 249

---

## 251. `/architect amend`: a body read classifies, the stricter carried classification wins, several features per run

Status: [DONE]
Target: claude
Files: skills/architect/amend.md, skills/architect/SKILL.md, skills/pipeline-revise/SKILL.md, skills/pipeline-engine/SKILL.md, skills/pipeline-engine/references/routing.md, .claude/domain/features/owner-amend-arms.md, .claude/domain/product-workflow.md, docs/reference.md, README.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 252. Direct, headless-capable amend arms for `/product-roadmap`, `/production-plan` and `/product-design`

Status: [DONE]
Target: claude
Files: skills/product-roadmap/SKILL.md, skills/product-roadmap/amend.md, skills/production-plan/SKILL.md, skills/production-plan/amend.md, skills/product-design/SKILL.md, skills/product-design/amend.md, skills/product-design/resuming.md, skills/pipeline-engine/SKILL.md, skills/pipeline-engine/references/routing.md, skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/delete.md, .claude/domain/features/owner-amend-arms.md, docs/reference.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 253. `/pipeline-revise` takes a change set behind one numbered plan gate; `/pipeline-patch` retired

Status: [DONE]
Target: claude
Files: skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/delete.md, skills/pipeline-revise/reorder.md, commands/pipeline-patch.md, skills/pipeline-engine/SKILL.md, skills/pipeline-engine/references/lint.md, skills/pipeline-engine/references/routing.md, skills/pipeline-suggest/SKILL.md, commands/pipeline-check.md, commands/runbook-create.md, commands/task-add.md, skills/task-engine/SKILL.md, skills/task-engine/references/amend.md, skills/runbook-run/SKILL.md, skills/runbook-run/references/step-amend.md, .claude/FEATURES.md, .claude/domain/INDEX.md, .claude/domain/product-design.md, docs/reference.md, docs/authoring-guide.md, README.md, .claude/domain/features/pipeline-revision.md, .claude/domain/features/pipeline-suggest.md, .claude/domain/product-workflow.md, .claude/domain/task-workflow.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: 251, 252

---

## 254. Render `/task-add`'s approval plan as a digest: heading, target, goal, decisions

Status: [DONE]
Target: claude
Files: commands/task-add.md, docs/reference.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 255. Give `/runbook-run`'s closing report the two groups, and number every closing report's Needs you items

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/task-review/SKILL.md, docs/reference.md, .claude/domain/task-workflow.md, .claude/domain/features/runbook-suite.md, .claude/domain/features/task-peer-review.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 256. `/doc-consolidate`: one gate per run, judgement calls only, auto-approved when there are none

Status: [DONE]
Target: claude
Files: skills/doc-consolidate/SKILL.md, docs/reference.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 257. `/follow-ups` renders its list under a `Follow-ups` heading

Status: [DONE]
Target: claude
Files: commands/follow-ups.md, docs/reference.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 258. `chosko-llm`: a `skills/<dir>` with no `SKILL.md` is unmanaged, not a missing feature

Status: [DONE]
Target: claude
Files: scripts/lib.sh, scripts/cmd-ls.sh, scripts/cmd-show.sh, scripts/cmd-rm.sh, scripts/cmd-update.sh, .claude/context/cmd-ls.md, .claude/context/cmd-show.md, .claude/context/shared-lib.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 259. Spawned step agents answer the runbook-WIP dirty-tree prompt themselves

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/subagent-contract.md, skills/runbook-run/references/inline-contract.md, skills/runbook-run/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: unattended-parking

---

## 260. `[PARKED]` status and the task parking protocol in `task-engine`

Status: [MISSING]
Target: claude
Files: skills/task-engine/references/parking.md, skills/task-engine/references/status.md, skills/task-engine/references/resolution.md, skills/task-engine/references/commit.md, skills/task-engine/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: unattended-parking

---

## 261. `/task-implement --unattended`: park at a question, unpark when reached, pre-ask at launch

Status: [MISSING]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/no-test-suite.md, skills/task-engine/references/parking.md, VERSION, CHANGELOG.md
Preconditions: 260
Feature: unattended-parking

---

## 262. Delegated runs relay questions when attended and return `[PARKED]` when not

Status: [MISSING]
Target: claude
Files: skills/task-implement/delegated-runs.md, skills/task-implement/SKILL.md, skills/task-engine/references/targets.md, VERSION, CHANGELOG.md
Preconditions: 261
Feature: unattended-parking

---

## 263. Runbook schema: `[P]` marker, `Parked:` index line, `Execution policy:` header

Status: [MISSING]
Target: claude
Files: skills/runbook-run/references/runbook-schema.md, commands/runbook-create.md, commands/runbook-list.md, commands/runbook-describe.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: unattended-parking

---

## 264. `/runbook-run` parks a step under the `unattended` policy

Status: [MISSING]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/runbook-run/references/parking.md, skills/runbook-run/references/subagent-contract.md, skills/runbook-run/references/inline-contract.md, VERSION, CHANGELOG.md
Preconditions: 259, 263
Feature: unattended-parking

---

## 265. Closing reports end with one Follow-ups list

Status: [MISSING]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/task-implement/review-rounds.md, commands/follow-ups.md, VERSION, CHANGELOG.md
Preconditions: 261, 264
Feature: unattended-parking

---

## 266. Parked items across the read-only and lint commands

Status: [MISSING]
Target: claude
Files: commands/task-list.md, skills/task-clean/SKILL.md, commands/pipeline-check.md, skills/pipeline-engine/references/lints.md, skills/pipeline-engine/references/routing.md, skills/task-engine/references/stale.md, commands/task-add.md, VERSION, CHANGELOG.md
Preconditions: 261, 264
Feature: unattended-parking

---

## 267. Update documentation for feature `unattended-parking`

Status: [MISSING]
Target: claude
Files: README.md, docs/reference.md, docs/cli-help.txt, .claude/domain/task-workflow.md, .claude/context/features.md, .claude/domain/features/runbook-suite.md, .claude/domain/features/task-implement-launcher.md, .claude/domain/features/runbook-inline.md, .claude/domain/features/task-peer-review.md
Preconditions: 259, 260, 261, 262, 263, 264, 265, 266
Feature: unattended-parking

---
