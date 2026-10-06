# Features

---

## product-roadmap — Milestones, outcomes, and the scope slices that decompose them

Status: [DONE]
Doc: .claude/domain/features/product-roadmap.md
Source: product-design.md § Roadmap and planning
Tasks: none

---

## slice-aware-architecture — `/architect` resolves a scope slice when the project has a roadmap

Status: [DONE]
Doc: .claude/domain/features/slice-aware-architecture.md
Source: product-design.md § Roadmap and planning
Tasks: none

---

## production-plan — `PLAN.md`: milestone membership, ordering, and the dependency graph

Status: [DONE]
Doc: .claude/domain/features/production-plan.md
Source: product-design.md § Roadmap and planning
Tasks: none

---

## plan-readout — What to build next, and the backlog read through the plan

Status: [DONE]
Doc: .claude/domain/features/plan-readout.md
Source: product-design.md § Roadmap and planning
Tasks: none

---

## session-continuity — Per-project session handoff, linked to the work it belongs to

Status: [DONE]
Doc: .claude/domain/features/session-continuity.md
Source: prompt
Tasks: none

---

## task-peer-review — Review and iterate on implemented work, in a fresh context

Status: [DONE]
Doc: .claude/domain/features/task-peer-review.md
Source: prompt
Tasks: 158, 159, 160, 161

---

## task-implement-launcher — The batch parent stops orchestrating and becomes a launcher

Status: [DONE]
Doc: .claude/domain/features/task-implement-launcher.md
Source: prompt
Tasks: none

---

## shared-phase-engine — One authority per rule for the `task-*` suite, and the `requires:` field that makes it safe

Status: [DONE]
Doc: .claude/domain/features/shared-phase-engine.md
Source: prompt
Tasks: none

---

## repo-local-audits — Unshipped audits for building this product, not part of it

Status: [DONE]
Doc: .claude/domain/features/repo-local-audits.md
Source: prompt
Tasks: none

---

## runbook-suite — Ordered self-contained prompts, executed by orchestrated subagents

Status: [DONE]
Doc: .claude/domain/features/runbook-suite.md
Source: prompt
Tasks: 273, 274

---

## version-changelog — A curated CHANGELOG, enforced at every VERSION bump and replayed on upgrade

Status: [DONE]
Doc: .claude/domain/features/version-changelog.md
Source: prompt
Tasks: 150

---

## backlog-ordering — Selection honours `Preconditions:`; tasks and runbook steps can be inserted, not only appended

Status: [DONE]
Doc: .claude/domain/features/backlog-ordering.md
Source: prompt
Tasks: 169, 170, 171, 172, 173, 174

---

## pipeline-engine — Shared probes, index graph, routing table and the `/pipeline-check` lint

Status: [DONE]
Doc: .claude/domain/features/pipeline-engine.md
Source: prompt
Tasks: 175, 176, 177, 178, 179, 180, 181

---

## owner-amend-arms — Standalone amend files per artifact owner, with a precision iterate guard for `/architect`

Status: [DONE]
Doc: .claude/domain/features/owner-amend-arms.md
Source: prompt
Tasks: 182, 183, 184, 185, 186

---

## pipeline-revision — `/pipeline-revise`: change planned work as one change set, through its owners

Status: [DONE]
Doc: .claude/domain/features/pipeline-revision.md
Source: prompt
Tasks: 187, 188, 189, 190, 191, 192, 193

---

## pipeline-suggest — One-line auto-triggered pointer from a free-form request to the pipeline command that fits

Status: [DONE]
Doc: .claude/domain/features/pipeline-suggest.md
Source: prompt
Tasks: 194, 195

---

## task-archive — `/task-clean` archives pruned bodies instead of deleting them; features keep every id

Status: [DONE]
Doc: .claude/domain/features/task-archive.md
Source: product-design.md § Task backlog
Tasks: 196, 197, 198, 199, 200, 201

---

## authoring-commit-default — `/architect`, `/product-design`, `/product-roadmap` and `/production-plan` commit by default

Status: [DONE]
Doc: .claude/domain/features/authoring-commit-default.md
Source: prompt
Tasks: 202, 203, 204, 205

---

## runbook-inline — `/runbook-run --inline` executes selected steps in the orchestrating session

Status: [DONE]
Doc: .claude/domain/features/runbook-inline.md
Source: prompt
Tasks: 209, 210

---

## runbook-id-filenames — Runbook bodies named `<id>-<name>.md`, resolved by id, name or both

Status: [DONE]
Doc: .claude/domain/features/runbook-id-filenames.md
Source: prompt
Tasks: 211, 212, 213, 214

---

## unattended-parking — Park a question instead of halting the run under an `unattended` policy

Status: [DONE]
Doc: .claude/domain/features/unattended-parking.md
Source: product-design.md § Task backlog
Tasks: 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 275, 276

---

## interaction-policy — One opt-in policy for gates, gate summaries, reports and questions across every interactive feature

Status: [PLANNED]
Doc: .claude/domain/features/interaction-policy.md
Source: prompt
Tasks: 281, 282, 283, 284, 285, 286, 287

---

## unity-mcp-removal — Delete the Unity MCP integration; keep its generic checkpoint behaviour in the human-in-the-loop protocol

Status: [NEW]
Doc: .claude/domain/features/unity-mcp-removal.md
Source: product-design.md § Unity/MCP integration
Tasks: none

---

## setup-sync — Setup commands offer every per-project fact a feature reads, guarded by `project-policy:` and `check-setup.sh`

Status: [NEW]
Doc: .claude/domain/features/setup-sync.md
Source: prompt
Tasks: none

---

## session-readers — `/session-list` and `/session-describe`, and path/date/slug resolution for every session command

Status: [NEW]
Doc: .claude/domain/features/session-readers.md
Source: prompt
Tasks: none

---

## quick-implement — `/quick-implement`: spec conversation to one commit, no backlog entry, docs caught up by `/pipeline-revise --catch-up`

Status: [NEW]
Doc: .claude/domain/features/quick-implement.md
Source: prompt
Tasks: none

---

## orchestrate-mode — `/orchestrate-mode`: a conversation that delegates every change to per-area agents with handoff files

Status: [NEW]
Doc: .claude/domain/features/orchestrate-mode.md
Source: prompt
Tasks: none

---

## objective-run — `/objective-run`: worker and checker rounds toward checkable criteria, with a committed, resumable log

Status: [NEW]
Doc: .claude/domain/features/objective-run.md
Source: prompt
Tasks: none

---
