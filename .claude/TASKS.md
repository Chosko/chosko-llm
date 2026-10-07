# Tasks

Last task number: 311

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

Status: [DONE]
Target: claude
Files: skills/task-engine/references/parking.md, skills/task-engine/references/status.md, skills/task-engine/references/resolution.md, skills/task-engine/references/commit.md, skills/task-engine/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: unattended-parking

---

## 261. `/task-implement --unattended`: park at a question, unpark when reached, pre-ask at launch

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/no-test-suite.md, skills/task-engine/references/parking.md, VERSION, CHANGELOG.md
Preconditions: 260
Feature: unattended-parking

---

## 262. Delegated runs relay questions when attended and return `[PARKED]` when not

Status: [DONE]
Target: claude
Files: skills/task-implement/delegated-runs.md, skills/task-implement/SKILL.md, skills/task-engine/references/targets.md, VERSION, CHANGELOG.md
Preconditions: 261
Feature: unattended-parking

---

## 263. Runbook schema: `[P]` marker, `Parked:` index line, `Execution policy:` header

Status: [DONE]
Target: claude
Files: skills/runbook-run/references/runbook-schema.md, commands/runbook-create.md, commands/runbook-list.md, commands/runbook-describe.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: unattended-parking

---

## 264. `/runbook-run` parks a step under the `unattended` policy

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/runbook-run/references/parking.md, skills/runbook-run/references/subagent-contract.md, skills/runbook-run/references/inline-contract.md, VERSION, CHANGELOG.md
Preconditions: 259, 263
Feature: unattended-parking

---

## 265. Closing reports end with one Follow-ups list

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/task-implement/review-rounds.md, commands/follow-ups.md, VERSION, CHANGELOG.md
Preconditions: 261, 264
Feature: unattended-parking

---

## 266. Parked items across the read-only and lint commands

Status: [DONE]
Target: claude
Files: commands/task-list.md, skills/task-clean/SKILL.md, commands/pipeline-check.md, skills/pipeline-engine/references/lints.md, skills/pipeline-engine/references/routing.md, skills/task-engine/references/stale.md, commands/task-add.md, VERSION, CHANGELOG.md
Preconditions: 261, 264
Feature: unattended-parking

---

## 267. Update documentation for feature `unattended-parking`

Status: [DONE]
Target: claude
Files: README.md, docs/reference.md, docs/cli-help.txt, .claude/domain/task-workflow.md, .claude/context/features.md, .claude/domain/features/runbook-suite.md, .claude/domain/features/task-implement-launcher.md, .claude/domain/features/runbook-inline.md, .claude/domain/features/task-peer-review.md
Preconditions: 259, 260, 261, 262, 263, 264, 265, 266
Feature: unattended-parking

---

## 268. `/task-review`'s report closes on For the record then Follow-ups

Status: [DONE]
Target: claude
Files: skills/task-review/SKILL.md, docs/reference.md, .claude/domain/features/task-peer-review.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: 265
Feature: unattended-parking

---

## 269. `/runbook-run` mid-step chat: progress line and subagent-WIP stop-hook reply

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, .claude/domain/features/runbook-suite.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 270. `follow-ups-resolve` skill: the general protocol for answering a Follow-ups list

Status: [DONE]
Target: claude
Files: skills/follow-ups-resolve/SKILL.md, commands/follow-ups.md, skills/runbook-run/SKILL.md, skills/task-implement/SKILL.md, skills/runbook-suggest/SKILL.md, skills/pipeline-suggest/SKILL.md, README.md, docs/reference.md, docs/cli-help.txt, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 271. Follow-ups while a runbook runs

Status: [DONE]
Target: claude
Files: skills/follow-ups-resolve/SKILL.md, skills/runbook-run/SKILL.md, commands/follow-ups.md, .claude/domain/features/runbook-suite.md, docs/reference.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: 269, 270

---

## 272. Unpark deletes the parking branch after the task's commit, and `/task-clean` sweeps orphaned park branches

Status: [DONE]
Target: claude
Files: skills/task-engine/references/parking.md, skills/task-engine/references/status.md, skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/task-clean/SKILL.md, skills/pipeline-engine/references/routing.md, .claude/domain/features/unattended-parking.md, docs/reference.md, .claude/context/features.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 273. `/runbook-run` progress line counts finished steps and reads the index's `Steps:` counter

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: runbook-suite

---

## 274. Update documentation for feature `runbook-suite`

Status: [DONE]
Target: claude
Files: docs/reference.md, .claude/context/features.md
Preconditions: 273
Feature: runbook-suite

---

## 275. A re-park deletes the leftover park branch first, and the `/task-clean` sweep spares `[IN PROGRESS]` tasks

Status: [DONE]
Target: claude
Files: skills/task-engine/references/parking.md, skills/task-clean/SKILL.md, skills/pipeline-engine/references/routing.md, skills/task-implement/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: unattended-parking

---

## 276. Update documentation for feature `unattended-parking`

Status: [DONE]
Target: claude
Files: docs/reference.md, .claude/context/features.md
Preconditions: 275
Feature: unattended-parking

---

## 277. Harden the spawn relay against relay children that reply in-turn

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/runbook-run/references/subagent-contract.md, skills/task-review/SKILL.md, .claude/domain/features/runbook-suite.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 278. Stop shipped bodies from citing `docs/authoring-guide.md`

Status: [DONE]
Target: claude
Files: commands/refactor-codebase.md, commands/refactor-tests.md, commands/unity-mcp-setup.md, commands/task-setup.md, commands/domain-setup.md, commands/project-setup.md, skills/product-design/SKILL.md, skills/product-roadmap/SKILL.md, skills/architect/SKILL.md, skills/task-engine/references/commit.md, skills/task-engine/SKILL.md, VERSION, CHANGELOG.md
Preconditions: none

---

## 279. Accept a bare `--commit` as a silent no-op on every commit-by-default feature

Status: [DONE]
Target: claude
Files: skills/task-engine/references/commit.md, skills/task-engine/SKILL.md, commands/task-add.md, skills/task-clean/SKILL.md, skills/task-implement/SKILL.md, skills/task-iterate/SKILL.md, skills/context-update/SKILL.md, skills/runbook-run/SKILL.md, commands/runbook-clean.md, commands/runbook-prune.md, docs/authoring-guide.md, docs/reference.md, VERSION, CHANGELOG.md
Preconditions: 278

---

## 280. Remove history wording from `/refactor-codebase`, `/refactor-tests` and `/context-build`

Status: [DONE]
Target: claude
Files: commands/refactor-codebase.md, commands/refactor-tests.md, skills/context-build/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 278

---

## 281. Add the `interaction-engine` reference skill

Status: [DONE]
Target: claude
Files: skills/interaction-engine/SKILL.md, skills/interaction-engine/references/policy.md, skills/interaction-engine/references/gates.md, skills/interaction-engine/references/messages.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: interaction-policy

---

## 282. Adopt the interaction policy in the `task-*` suite

Status: [DONE]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/task-implement/no-test-suite.md, skills/task-engine/SKILL.md, skills/task-engine/references/parking.md, skills/task-engine/references/stale.md, skills/task-engine/references/amend.md, commands/task-add.md, commands/task-setup.md, skills/task-iterate/SKILL.md, skills/task-clean/SKILL.md, skills/task-clean/backfill.md, VERSION, CHANGELOG.md
Preconditions: 281
Feature: interaction-policy

---

## 283. Adopt the interaction policy in the runbook suite

Status: [DONE]
Target: claude
Files: skills/runbook-run/SKILL.md, skills/runbook-run/references/subagent-contract.md, skills/runbook-run/references/inline-contract.md, skills/runbook-run/references/parking.md, skills/runbook-run/references/step-amend.md, commands/runbook-create.md, commands/runbook-clean.md, commands/runbook-prune.md, VERSION, CHANGELOG.md
Preconditions: 281
Feature: interaction-policy

---

## 284. Adopt the interaction policy in the pipeline's authoring stages

Status: [DONE]
Target: claude
Files: skills/architect/SKILL.md, skills/architect/amend.md, skills/product-design/SKILL.md, skills/product-design/amend.md, skills/product-roadmap/SKILL.md, skills/product-roadmap/amend.md, skills/production-plan/SKILL.md, skills/production-plan/amend.md, skills/production-plan/reconciling.md, commands/domain-setup.md, VERSION, CHANGELOG.md
Preconditions: 281
Feature: interaction-policy

---

## 285. Rewrite `/pipeline-revise`'s gate and `/pipeline-check`'s findings to the interaction policy

Status: [DONE]
Target: claude
Files: skills/pipeline-revise/SKILL.md, skills/pipeline-revise/amend.md, skills/pipeline-revise/delete.md, skills/pipeline-revise/insert.md, skills/pipeline-revise/reorder.md, commands/pipeline-check.md, skills/pipeline-engine/references/lint.md, VERSION, CHANGELOG.md
Preconditions: 281
Feature: interaction-policy

---

## 286. Adopt the interaction policy in the context, refactor, setup and session features

Status: [DONE]
Target: claude
Files: skills/context-build/SKILL.md, skills/context-build/nested.md, skills/context-update/SKILL.md, skills/context-convert/SKILL.md, commands/refactor-codebase.md, commands/refactor-tests.md, skills/doc-consolidate/SKILL.md, commands/project-setup.md, commands/session-save.md, skills/follow-ups-resolve/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 281
Feature: interaction-policy

---

## 287. Update documentation for feature `interaction-policy`

Status: [DONE]
Target: claude
Files: CLAUDE.md, .claude/context/INDEX.md, .claude/context/features.md, .claude/context/interaction-engine.md, .claude/context/task-engine.md, .claude/context/task-implement.md, .claude/context/task-implement-delegation.md, .claude/context/runbook-run-loop.md, .claude/context/runbook-run-contracts.md, .claude/context/pipeline.md, .claude/context/pipeline-revise-plan.md, .claude/domain/task-workflow.md, .claude/domain/product-workflow.md, .claude/domain/features/unattended-parking.md, .claude/domain/features/runbook-suite.md, .claude/domain/features/runbook-inline.md, .claude/domain/features/pipeline-revision.md, .claude/domain/features/owner-amend-arms.md
Preconditions: 281, 282, 283, 284, 285, 286
Feature: interaction-policy

---

## 288. Move `/task-implement`'s checkpoint automation out of Unity MCP into a tool-agnostic human-in-the-loop passage

Status: [DONE]
Target: claude
Files: skills/task-implement/human-in-loop.md, skills/task-implement/SKILL.md, skills/task-implement/unity-mcp-checkpoints.md, skills/task-engine/references/targets.md, VERSION, CHANGELOG.md
Preconditions: 282
Feature: unity-mcp-removal

---

## 289. Delete `/unity-mcp-setup` and `unity-mcp-skill`, and drop `/project-setup`'s Unity MCP offer

Status: [DONE]
Target: claude
Files: commands/unity-mcp-setup.md, skills/unity-mcp-skill/SKILL.md, skills/unity-mcp-skill/references/tools-reference.md, skills/unity-mcp-skill/references/workflows.md, commands/project-setup.md, .claude/skills/rule-overlap/SKILL.md, .claude/skills/context-budget/SKILL.md, .claude/skills/task-implement/SKILL.md, .claude/skills/task-implement/human-in-loop.md, .claude/skills/task-implement/unity-mcp-checkpoints.md, .claude/skills/task-engine/references/targets.md, VERSION, CHANGELOG.md
Preconditions: 288
Feature: unity-mcp-removal

---

## 290. Update documentation for feature `unity-mcp-removal`

Status: [MISSING]
Target: claude
Files: .claude/context/INDEX.md, .claude/context/setup-commands.md, .claude/context/task-implement.md, .claude/context/features.md, .claude/context/feature-contract.md, .claude/context/product-design.md, docs/authoring-guide.md, .claude/domain/technical-direction.md, .claude/domain/features/authoring-commit-default.md, .claude/domain/features/repo-local-audits.md
Preconditions: 288, 289
Feature: unity-mcp-removal

---

## 291. Replace `/task-setup`'s and `/domain-setup`'s schema copies with citations and fix `/task-setup`'s drift

Status: [MISSING]
Target: claude
Files: commands/task-setup.md, commands/domain-setup.md, VERSION, CHANGELOG.md
Preconditions: 282, 284
Feature: setup-sync

---

## 292. Bring `/project-setup`'s wizard in line with the features it sets up

Status: [MISSING]
Target: claude
Files: commands/project-setup.md, VERSION, CHANGELOG.md
Preconditions: 286, 289
Feature: setup-sync

---

## 293. Add the `project-policy:` frontmatter key, its declarations and the `check-setup.sh` guard

Status: [MISSING]
Target: claude
Files: scripts/lib.sh, scripts/check-setup.sh, skills/interaction-engine/SKILL.md, skills/task-implement/SKILL.md, skills/doc-consolidate/SKILL.md, skills/task-engine/SKILL.md, skills/task-clean/SKILL.md, skills/context-convert/SKILL.md, commands/session-save.md, skills/task-review/SKILL.md, skills/task-iterate/SKILL.md, CLAUDE.md, VERSION, CHANGELOG.md
Preconditions: 281, 291, 292
Feature: setup-sync

---

## 294. Update documentation for feature `setup-sync`

Status: [MISSING]
Target: claude
Files: .claude/context/setup-commands.md, .claude/context/task-backlog.md, .claude/context/shared-lib-frontmatter.md, .claude/context/feature-contract.md, docs/authoring-guide.md
Preconditions: 291, 292, 293
Feature: setup-sync

---

## 295. Add slug resolution to `/session-resume`

Status: [MISSING]
Target: claude
Files: commands/session-resume.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: session-readers

---

## 296. Add `/session-list`

Status: [MISSING]
Target: claude
Files: commands/session-list.md, VERSION, CHANGELOG.md
Preconditions: none
Feature: session-readers

---

## 297. Add `/session-describe`

Status: [MISSING]
Target: claude
Files: commands/session-describe.md, VERSION, CHANGELOG.md
Preconditions: 295
Feature: session-readers

---

## 298. Update documentation for feature `session-readers`

Status: [MISSING]
Target: claude
Files: .claude/context/session-handoff.md, .claude/context/features.md, .claude/context/INDEX.md, .claude/domain/features/session-continuity.md
Preconditions: 295, 296, 297
Feature: session-readers

---

## 299. Move `/task-add`'s design-change check, reconciliation and orphan question into `task-engine`
Status: [MISSING]
Target: claude
Files: skills/task-engine/references/design-change.md, skills/task-engine/references/reconciliation.md, skills/task-engine/references/orphan-question.md, skills/task-engine/SKILL.md, commands/task-add.md, skills/task-engine/references/amend.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 282
Feature: quick-implement

---

## 300. Move `/task-implement`'s testing-policy resolution, tests-first sequence and closing report into `task-engine`
Status: [MISSING]
Target: claude
Files: skills/task-engine/references/testing-policy.md, skills/task-engine/references/tests-first.md, skills/task-engine/references/closing-report.md, skills/task-engine/references/test-runner.md, skills/task-engine/references/no-test-suite.md, skills/task-engine/SKILL.md, skills/task-implement/SKILL.md, skills/task-implement/test-runner.md, skills/task-implement/no-test-suite.md, skills/task-implement/delegated-runs.md, skills/task-implement/review-rounds.md, commands/task-setup.md, VERSION, CHANGELOG.md
Preconditions: 282, 288, 293
Feature: quick-implement

---

## 301. Add `spec=<path>` to `/task-review` and `/task-iterate`
Status: [MISSING]
Target: claude
Files: skills/task-review/SKILL.md, skills/task-iterate/SKILL.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 282, 293
Feature: quick-implement

---

## 302. Add the `/quick-implement` skill and its routing row
Status: [MISSING]
Target: claude
Files: skills/quick-implement/SKILL.md, skills/quick-implement/spec.md, skills/quick-implement/drift-check.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 281, 299, 300, 301
Feature: quick-implement

---

## 303. Add `/pipeline-revise --catch-up`
Status: [MISSING]
Target: claude
Files: skills/pipeline-revise/SKILL.md, skills/pipeline-revise/catch-up.md, skills/pipeline-engine/references/routing.md, VERSION, CHANGELOG.md
Preconditions: 285, 302
Feature: quick-implement

---

## 304. Probe `.claude/specs/` and report a leftover spec in `/pipeline-check`
Status: [MISSING]
Target: claude
Files: skills/pipeline-engine/references/probes.md, skills/pipeline-engine/references/lint.md, commands/pipeline-check.md, VERSION, CHANGELOG.md
Preconditions: 285, 302, 303
Feature: quick-implement

---

## 305. Update documentation for feature `quick-implement`
Status: [MISSING]
Target: claude
Files: .claude/context/INDEX.md, .claude/context/quick-implement.md, .claude/context/features.md, .claude/context/task-engine.md, .claude/context/task-add.md, .claude/context/task-implement.md, .claude/context/task-review-iterate.md, .claude/context/pipeline.md, .claude/context/pipeline-revise.md, .claude/context/pipeline-readers.md, .claude/domain/product-workflow.md, .claude/domain/task-workflow.md, .claude/domain/features/task-peer-review.md, .claude/domain/features/pipeline-revision.md, .claude/domain/features/pipeline-engine.md
Preconditions: 299, 300, 301, 302, 303, 304
Feature: quick-implement

---

## 306. Add the `/orchestrate-mode` skill and `interaction-engine`'s mode check

Status: [MISSING]
Target: claude
Files: skills/orchestrate-mode/SKILL.md, skills/orchestrate-mode/brief.md, skills/orchestrate-mode/handoff.md, skills/orchestrate-mode/failures.md, skills/interaction-engine/SKILL.md, skills/interaction-engine/references/mode.md, VERSION, CHANGELOG.md
Preconditions: 281
Feature: orchestrate-mode

---

## 307. Make `/task-implement`, `/quick-implement` and `pipeline-suggest` honour orchestrate mode

Status: [MISSING]
Target: claude
Files: skills/task-implement/SKILL.md, skills/task-implement/delegated-runs.md, skills/quick-implement/SKILL.md, skills/pipeline-suggest/SKILL.md, VERSION, CHANGELOG.md
Preconditions: 300, 302, 306
Feature: orchestrate-mode

---

## 308. Move area handoffs in `/session-save` and list them in `/session-resume`

Status: [MISSING]
Target: claude
Files: commands/session-save.md, commands/session-resume.md, VERSION, CHANGELOG.md
Preconditions: 286, 293, 295, 306
Feature: orchestrate-mode

---

## 309. Update documentation for feature `orchestrate-mode`

Status: [MISSING]
Target: claude
Files: .claude/context/INDEX.md, .claude/context/features.md, .claude/context/orchestrate-mode.md, .claude/context/interaction-engine.md, .claude/context/task-implement-delegation.md, .claude/context/quick-implement.md, .claude/context/session-handoff.md, .claude/domain/features/session-continuity.md, .claude/domain/features/task-implement-launcher.md
Preconditions: 306, 307, 308
Feature: orchestrate-mode

---
## 310. Add the `/objective-run` skill

Status: [MISSING]
Target: claude
Files: skills/objective-run/SKILL.md, skills/objective-run/references/log-schema.md, VERSION, CHANGELOG.md
Preconditions: 281, 283, 303
Feature: objective-run

---
## 311. Update documentation for feature `objective-run`

Status: [MISSING]
Target: claude
Files: .claude/context/INDEX.md, .claude/context/features.md, .claude/context/objective-run.md, .claude/context/interaction-engine.md, .claude/context/runbook-run.md, .claude/domain/features/interaction-policy.md
Preconditions: 310
Feature: objective-run

---
