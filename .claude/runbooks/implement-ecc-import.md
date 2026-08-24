# Runbook: implement-ecc-import

Created: 2026-08-24 · Source: manual · Model: opus
Sequencing: strictly ordered 1→14. version-changelog (1–2) lands first so every later VERSION bump writes its CHANGELOG entry; the dual-LLM deletion (3) precedes everything that edits skills/task-implement/SKILL.md; session-continuity (4) and repo-local-audits (5) are independent and go next; then the launcher → peer-review → shared-phase-engine chain (6–11) in dependency order because all three edit skills/task-implement/SKILL.md; 139 (12) needs the post-engine task-add; runbook-suite (13–14) needs `requires:` from 125.
Companion: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md

## [ ] 1. Backfill CHANGELOG.md and land the versioning rule (task 146)

Depends on: none

Context: none

```prompt
/task-implement 146 --no-agents

Read .claude/tasks/146.md first. This is the first task of the version-changelog feature and is implemented before every other open task on purpose: from the moment it lands, every later VERSION bump must add a CHANGELOG.md section. The body carries the descending-semver ordering, the "every distinct VERSION value gets a section" rule, and the attribution rule across the bd2a1cf merge (side branch 13e01c3 reset VERSION to 0.53.0 and ran to 0.59.0 while master ran 0.53.1–0.58.2). Follow them; do not re-derive them. Verify by checking the four invariants listed in the body by hand — the guard script does not exist yet. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 2. Changelog guard, upgrade readout, docs (tasks 147–149)

Depends on: 1

Context: none

```prompt
/task-implement 147 148 149 --no-agents

Read .claude/tasks/147.md, 148.md and 149.md first. 147 adds scripts/check-changelog.sh (standalone — it must not reference or share code with scripts/check-task-parity.sh, which a later task deletes). 148 adds the colored range readout to `chosko-llm upgrade` via three lib.sh helpers; color is gated on `_use_color` (stderr), never on the stdout-gated `C_*` variables; the raw `git log --oneline` dump is suppressed exactly when a range printed. 149 is documentation. Each task bumps VERSION and adds its own CHANGELOG.md section per the rule task 146 made live; run ./scripts/check-changelog.sh after each bump once it exists. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 3. Delete the dead dual-LLM lane (task 118)

Depends on: 2

Context: none

```prompt
/task-implement 118 --no-agents

Read .claude/tasks/118.md first. It deletes the local-model (aider/Ollama) implementation lane, the whole /task-enrich apparatus and `Target: local`, scripts/check-task-parity.sh, and the two aider prompt files /task-setup emits — while keeping the `Target:` field with `claude` / `claude+human` / `human`, and keeping /task-setup's two test wrappers (job-hunter-cli uses them as its real test dispatcher). VERSION goes to 1.0.0 (user decision). `task-impl` is a substring of `task-implement`: never sed on the bare substring. Nothing downstream is modified. Add the 1.0.0 CHANGELOG.md section and run ./scripts/check-changelog.sh. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 4. Session continuity (tasks 132–134)

Depends on: 3

Context: none

```prompt
/task-implement 132 133 134 --no-agents

Read .claude/tasks/132.md, 133.md and 134.md first. They ship /session-save and /session-resume. Binding decisions already in the bodies: /task-implement writes no resume marker, so its sessions take the full form; /session-resume has no task-number selector; only files with a `Work:` line are resume candidates; a session file is deleted by the resumed session once the work it describes is finished, and a /session-save in a resumed session deletes the file it resumed from; never-resumed files are never auto-deleted. Task 134 is pre-authorised in its Decisions to reconcile the /architect-owned feature document on its enumerated points — do not stop to ask. Each task bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 5. Repo-local audits (tasks 135–138)

Depends on: 4

Context: none

```prompt
/task-implement 135 136 137 138 --no-agents

Read .claude/tasks/135.md through 138.md first. 135 adds the CLAUDE.md exemption (files under this repo's own .claude/skills/ never bump VERSION — narrow wording, rest of .claude/ still bumps) and MUST land before 136/137, which create .claude/skills/context-budget/ and .claude/skills/rule-overlap/ with no `version:` frontmatter and no VERSION bump and therefore no CHANGELOG.md section. 137's known-positive check is written for both before and after the shared-phase-engine refactor. 138 is documentation and is pre-authorised to reconcile the feature document on its listed points. 135 and 138 bump VERSION and add CHANGELOG.md sections; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 6. task-implement launcher (tasks 119–120)

Depends on: 3

Context: none

```prompt
/task-implement 119 120 --no-agents

Read .claude/tasks/119.md and 120.md first. 119 turns /task-implement's batch parent into a launcher: fixed-size hand-off prompt, the parent never opens a delegated task's body, guard fields (`Target:`/`Status:`/`Feature:`) read from the TASKS.md summary block, `[STALE]` read directly (no FEATURES.md join), the flag list described as "the run's resolved flags" — an open list, never a closed enumeration. Written against the post-118 shape of skills/task-implement/SKILL.md. 120 is documentation and is pre-authorised to reconcile the feature document on exactly two points. Each task bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 7. /task-review and /task-iterate skills (tasks 121–122)

Depends on: 6

Context: none

```prompt
/task-implement 121 122 --no-agents

Read .claude/tasks/121.md and 122.md first. 121 ships skills/task-review/ (SKILL.md + remote-diffs.md): reviews a diff against the task's acceptance criteria, ≥80% confidence gate, four-question Pre-Report gate, BLOCKING requires proof, zero findings is a valid review, read-only. 122 ships skills/task-iterate/: mandatory explicit triage of every finding (fix/defer/reject), never invents findings, commits and pushes when standalone but NEVER commits inside a /task-implement --review round (one-commit-per-task contract) — caller mode is asserted by the caller, never inferred. The finding schema is deliberately duplicated between the two skills until `requires:` ships. Each task bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 8. --review / --rounds loop in /task-implement, and docs (tasks 123–124)

Depends on: 7

Context: none

```prompt
/task-implement 123 124 --no-agents

Read .claude/tasks/123.md and 124.md first. 123 adds `--review [--rounds N]` to /task-implement in a new supporting file review-rounds.md: the loop runs after Step 5 and BEFORE Step 6 on the uncommitted tree; the reviewer is spawned as a subagent and RETURNS ASYNCHRONOUSLY — the body must wait for the notification and must never reach Step 6/7 before the final round's result arrives; iterate runs in the main session and is told not to commit; exactly one commit per task; `--rounds` without `--review` is an error; the availability gate for the two skills is a runtime check, not `requires:`; `--review`/`--rounds` ride delegated-runs.md's open flag list. A run without `--review` is byte-identical to today. 124 is documentation and is pre-authorised to reconcile the feature document on four listed points. Each task bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 9. `requires:` field and the task-engine extraction (tasks 125–126)

Depends on: 8

Context: none

```prompt
/task-implement 125 126 --no-agents

Read .claude/tasks/125.md and 126.md first. 125 adds the `requires:` frontmatter field: parse_frontmatter in scripts/lib.sh gates emission on a key allowlist (line ~182), so `requires` must be added to that allowlist — one token, no parser rewrite; cmd-add installs declared requirements before the first copy, one level deep; cmd-rm refuses to remove a required feature unless --force; `--all` unchanged; the field is documented in docs/authoring-guide.md and docs/cli-help.txt; no feature declares it yet. 126 creates skills/task-engine/ with six reference files extracted VERBATIM from the post-118 bodies — no rewording, divergences recorded per consumer, SKILL.md holds no rules. No consumer is migrated. Each task bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 10. Migrate task-list, task-clean, task-add onto the engine (tasks 127–129)

Depends on: 9

Context: none

```prompt
/task-implement 127 128 129 --no-agents

Read .claude/tasks/127.md, 128.md and 129.md first, in that order — each migration builds on the reference form the previous one established. Each command gains `requires: skill:task-engine` and replaces restated rules with references of the form `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<file>.md`, keeping only its own deviations. Observable behaviour is unchanged, verified by the before/after comparison each body specifies (task-list output, task-clean dry-run plan, a throwaway task with /task-add --no-commit --short). 129 is written against the post-118 shape of commands/task-add.md and does not touch its phase structure. Each task takes a minor frontmatter bump and a patch root VERSION bump with its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 11. Migrate task-implement onto the engine, and docs (tasks 130–131)

Depends on: 10

Context: none

```prompt
/task-implement 130 131 --no-agents

Read .claude/tasks/130.md and 131.md first. 130 migrates skills/task-implement/SKILL.md onto the engine last, on top of 118, 119 and 123: cites all six reference files; states the one-commit-under---review rule exactly once (commit.md or SKILL.md, not both); dirty-tree.md becomes a reference to tree.md or is deleted; delegated-runs.md keeps its fixed-size open flag list; /task-review and /task-iterate are NOT migrated and the --review availability gate stays a runtime check, not `requires:`. 131 is documentation — it qualifies (does not delete) the authoring guide's council-gate prohibition, and is pre-authorised to reconcile the feature document on five listed points. Each task bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 12. /task-add ownership pre-authorisation gate (task 139)

Depends on: 11

Context: none

```prompt
/task-implement 139 --no-agents

Read .claude/tasks/139.md first. It replaces /task-add's ownership notice with a pre-authorisation gate: an in-command owner list (features/*.md → /architect; product-design.md, technical-direction.md, business-model.md → /product-design; product-roadmap.md → /product-roadmap; .claude/PLAN.md → /production-plan — no runtime read of any table), detection on every task the run drafts, one question per owned file inside the existing PHASE 3 gate, a grant written into Decisions with date and enumerated points or the file dropped with the deferral noted, silence never a grant. Written against the post-129 shape of commands/task-add.md. Bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 13. /runbook-run and /runbook-create (tasks 140–141)

Depends on: 12

Context: none

```prompt
/task-implement 140 141 --no-agents

Read .claude/tasks/140.md and 141.md first. 140 ships skills/runbook-run/ with exactly two reference files (runbook-schema.md, subagent-contract.md): the orchestrator re-reads the body at every step, spawns one subagent per step, WAITS for the asynchronous result before ticking anything, relays questions with the fixed block, propagates facts into later steps' Context:, writes exactly two files, refuses nested runbooks, and treats an ambiguous report as failure. 141 ships commands/runbook-create.md with `requires: skill:runbook-run`, the four target forms including --append, the two source modes, the nine prompt-quality rules in full, and the shape-only confirmation gate. The runbook you are executing right now (.claude/runbooks/implement-ecc-import.md) is the read-only reference shape both tasks cite — do not edit it. Each task bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 14. /runbook-list, /runbook-clean, /runbook-suggest, docs (tasks 142–145)

Depends on: 13

Context: none

```prompt
/task-implement 142 143 144 145 --no-agents

Read .claude/tasks/142.md through 145.md first. 142 lists from .claude/RUNBOOKS.md only, never opening a body. 143 mirrors /task-clean, deletes [DONE] runbooks only, no --force. 144 is a ~30-line auto-triggering skill whose description is the trigger: it suggests running /runbook-create in one or two lines, asks nothing, reads no file, names no runbook. 145 is documentation and is pre-authorised to reconcile the feature document on three listed points. Each task bumps VERSION and adds its CHANGELOG.md section; run ./scripts/check-changelog.sh after each. The task bodies carry every decision and pre-authorisation grant; do not re-open or re-derive any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## Do not re-propose

- Freezing chosko-llm feature work (a council recommendation, rejected: job-hunter-cli repeatedly requires chosko-llm features to be created or updated, so tooling work here is demand-driven).
- Any ECC feature assessed and discarded in the companion document: config-gc, rules-distill as a shipped skill, inherit-legacy-style, update-codemaps, intent-driven-development, spec-miner, harness-audit, delivery-gate, prompt-optimizer, token-budget-advisor, code-explorer, and every ECC dimension-reviewer agent except `code-reviewer`.
- A PLAN.md, product roadmap or milestones for this repo (CLAUDE.md: it is tooling, not a product).
- Re-opening any decision recorded in a task body's Decisions section; the bodies are the authority.
