# Runbook: implement-ecc-import

Created: 2026-08-24 · Source: manual · Model: opus
Sequencing: strictly ordered 1→32, one task per step. version-changelog (1–4) lands first so every later VERSION bump writes its CHANGELOG entry; the dual-LLM deletion (5) precedes everything that edits skills/task-implement/SKILL.md; session-continuity (6–8) and repo-local-audits (9–12) are independent of the rest and go next; then the launcher → peer-review → shared-phase-engine chain (13–25) in dependency order because all three features edit skills/task-implement/SKILL.md; 139 (26) needs the post-engine task-add; runbook-suite (27–32) needs `requires:` from 125.
Companion: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md

## [ ] 1. Backfill CHANGELOG.md and land the versioning rule (task 146)

Depends on: none

Context: none

```prompt
/task-implement 146

Read .claude/tasks/146.md first. This is the first task of the version-changelog feature and is implemented before every other open task on purpose: from the moment it lands, every later VERSION bump must add a CHANGELOG.md section. The body carries the descending-semver ordering, the "every distinct VERSION value gets a section" rule, and the attribution rule across the bd2a1cf merge (side branch 13e01c3 reset VERSION to 0.53.0 and ran to 0.59.0 while master ran 0.53.1–0.58.2). Follow them; do not re-derive them. Verify by checking the four invariants listed in the body by hand — the guard script does not exist yet. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 2. Add the check-changelog.sh guard (task 147)

Depends on: 1

Context: none

```prompt
/task-implement 147

Read .claude/tasks/147.md first. It adds scripts/check-changelog.sh, an author-run guard over four invariants, silent on success. It must be standalone: it must not reference, source or share code with scripts/check-task-parity.sh, which a later task deletes. Bump VERSION, add the CHANGELOG.md section per the rule task 146 made live, and run ./scripts/check-changelog.sh before committing. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 3. Print what changed on upgrade (task 148)

Depends on: 2

Context: none

```prompt
/task-implement 148

Read .claude/tasks/148.md first. It adds three scripts/lib.sh helpers (raw VERSION reader that resolve_version is refactored through, changelog path helper, colored range printer) and the readout in scripts/cmd-upgrade.sh: VERSION read raw before and after the pull, never via resolve_version; two-sided descending-semver range; color gated on `_use_color` (stderr), never on the stdout-gated `C_*` variables; the raw `git log --oneline` dump suppressed exactly when a range printed; degrade, never fail. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 4. Documentation for version-changelog (task 149)

Depends on: 3

Context: none

```prompt
/task-implement 149

Read .claude/tasks/149.md first. Documentation only: README, docs/cli-help.txt, .claude/context/shared-lib.md, .claude/context/cmd-upgrade.md, .claude/context/INDEX.md. The files it names as deliberately unchanged stay unchanged. Bump VERSION (patch), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 5. Delete the dead dual-LLM lane (task 118)

Depends on: 4

Context: none

```prompt
/task-implement 118

Read .claude/tasks/118.md first. It deletes the local-model (aider/Ollama) implementation lane, the whole /task-enrich apparatus and `Target: local`, scripts/check-task-parity.sh, and the two aider prompt files /task-setup emits — while keeping the `Target:` field with `claude` / `claude+human` / `human`, and keeping /task-setup's two test wrappers (job-hunter-cli uses them as its real test dispatcher). VERSION goes to 1.0.0 (user decision). `task-impl` is a substring of `task-implement`: never sed on the bare substring. Nothing downstream is modified. Add the 1.0.0 CHANGELOG.md section and run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 6. Add the /session-save command (task 132)

Depends on: 5

Context: none

```prompt
/task-implement 132

Read .claude/tasks/132.md first. It ships commands/session-save.md: per-project store under .claude/sessions/, full and pointer forms, the `Work:` line. Binding decisions in the body: /task-implement writes no resume marker, so its sessions take the full form; a /session-save in a session that resumed from a file deletes the file it resumed from. Bump VERSION, add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 7. Add the /session-resume command (task 133)

Depends on: 6

Context: none

```prompt
/task-implement 133

Read .claude/tasks/133.md first. It ships commands/session-resume.md: no task-number selector; only files with a `Work:` line are candidates; deterministic tie-break on the full filename; follows a pointer-form `Resume from:`; briefs then stops; tells the resumed session to delete the file once the work it describes is finished. Bump VERSION, add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 8. Documentation for session-continuity (task 134)

Depends on: 7

Context: none

```prompt
/task-implement 134

Read .claude/tasks/134.md first. Documentation only. Its Decisions pre-authorise editing the /architect-owned feature document on the enumerated points — do not stop to ask. Bump VERSION (patch), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 9. Record the .claude/skills/ exemption in CLAUDE.md (task 135)

Depends on: 8

Context: none

```prompt
/task-implement 135

Read .claude/tasks/135.md first. It adds one bullet to CLAUDE.md's Versioning section: files under this repo's own .claude/skills/ never bump VERSION (narrow wording — the rest of .claude/ still bumps). It must land before the two audit skills. This task itself bumps VERSION (patch), adds the CHANGELOG.md section, and runs ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 10. Add the repo-local /context-budget audit skill (task 136)

Depends on: 9

Context: none

```prompt
/task-implement 136

Read .claude/tasks/136.md first. It creates .claude/skills/context-budget/SKILL.md with no `version:` frontmatter. Per the exemption task 135 recorded, this task does NOT bump VERSION and therefore adds NO CHANGELOG.md section. Its verification figures are labelled "as of 2026-08-24, before task 118"; the invariant shape is what must hold. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 11. Add the repo-local /rule-overlap audit skill (task 137)

Depends on: 10

Context: none

```prompt
/task-implement 137

Read .claude/tasks/137.md first. It creates .claude/skills/rule-overlap/SKILL.md with no `version:` frontmatter: inline grep/awk collection, exhaustive, vendored skills excluded, model judges overlaps across three or more features. No VERSION bump and no CHANGELOG.md section (exemption from task 135). Its known-positive check is written for both before and after the shared-phase-engine refactor. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 12. Documentation for repo-local-audits (task 138)

Depends on: 11

Context: none

```prompt
/task-implement 138

Read .claude/tasks/138.md first. Documentation only. Its Decisions pre-authorise editing the /architect-owned feature document on five listed points — do not stop to ask. Bump VERSION (patch), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 13. Turn /task-implement's batch parent into a launcher (task 119)

Depends on: 12

Context: none

```prompt
/task-implement 119

Read .claude/tasks/119.md first. Fixed-size hand-off prompt; the parent never opens a delegated task's body; guard fields (`Target:`/`Status:`/`Feature:`) read from the TASKS.md summary block; `[STALE]` read directly, no FEATURES.md join; the flag list described as "the run's resolved flags" — an open list, never a closed enumeration. Written against the post-118 shape of skills/task-implement/SKILL.md. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 14. Documentation for task-implement-launcher (task 120)

Depends on: 13

Context: none

```prompt
/task-implement 120

Read .claude/tasks/120.md first. Documentation only. Its Decisions pre-authorise editing the /architect-owned feature document on exactly two points — do not stop to ask. Bump VERSION (patch), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 15. Add the /task-review skill (task 121)

Depends on: 14

Context: none

```prompt
/task-implement 121

Read .claude/tasks/121.md first. It ships skills/task-review/ (SKILL.md + remote-diffs.md): reviews a diff against the task's acceptance criteria, ≥80% confidence gate, four-question Pre-Report gate, BLOCKING requires proof, zero findings is a valid review, read-only, one reviewer with no fan-out. The finding schema is deliberately duplicated into /task-iterate later. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 16. Add the /task-iterate skill (task 122)

Depends on: 15

Context: none

```prompt
/task-implement 122

Read .claude/tasks/122.md first. It ships skills/task-iterate/: mandatory explicit triage of every finding (fix/defer/reject), never invents findings, commits and pushes when standalone but NEVER commits inside a /task-implement --review round (one-commit-per-task contract) — caller mode is asserted by the caller, never inferred; returns the rejection ledger. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 17. Add the --review / --rounds loop to /task-implement (task 123)

Depends on: 16

Context: none

```prompt
/task-implement 123

Read .claude/tasks/123.md first. New supporting file review-rounds.md; the loop runs after Step 5 and BEFORE Step 6 on the uncommitted tree; the reviewer is spawned as a subagent and RETURNS ASYNCHRONOUSLY — the body must wait for the notification and must never reach Step 6/7 before the final round's result arrives; iterate runs in the main session and is told not to commit; exactly one commit per task; `--rounds` without `--review` is an error; the availability gate for the two skills is a runtime check, not `requires:`; `--review`/`--rounds` ride delegated-runs.md's open flag list. A run without `--review` is byte-identical to before. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 18. Documentation for task-peer-review (task 124)

Depends on: 17

Context: none

```prompt
/task-implement 124

Read .claude/tasks/124.md first. Documentation only. Its Decisions pre-authorise editing the /architect-owned feature document on four listed points — do not stop to ask. Bump VERSION (patch), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 19. Add the `requires:` frontmatter field (task 125)

Depends on: 18

Context: none

```prompt
/task-implement 125

Read .claude/tasks/125.md first. parse_frontmatter in scripts/lib.sh gates emission on a key allowlist (line ~182), so `requires` must be added to that allowlist — one token, no parser rewrite; cmd-add installs declared requirements before the first copy, one level deep; cmd-rm refuses to remove a required feature unless --force; `--all` unchanged; documented in docs/authoring-guide.md and docs/cli-help.txt; no feature declares it yet. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 20. Create the task-engine skill by verbatim extraction (task 126)

Depends on: 19

Context: none

```prompt
/task-implement 126

Read .claude/tasks/126.md first. It creates skills/task-engine/ with six reference files extracted VERBATIM from the post-118 bodies — no rewording, divergences recorded per consumer, SKILL.md holds no rules. No consumer is migrated. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 21. Migrate /task-list onto the task-engine (task 127)

Depends on: 20

Context: none

```prompt
/task-implement 127

Read .claude/tasks/127.md first. commands/task-list.md gains `requires: skill:task-engine` and replaces restated rules with references of the form `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<file>.md`, keeping only its own deviations. Observable behaviour unchanged — verify by diffing /task-list output before and after. Minor frontmatter bump, patch root VERSION bump, CHANGELOG.md section, ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 22. Migrate /task-clean onto the task-engine (task 128)

Depends on: 21

Context: none

```prompt
/task-implement 128

Read .claude/tasks/128.md first. Same migration pattern as task 127 established; first writing consumer, first reader of commit.md. Verify by diffing the dry-run confirmation plan before and after; do not confirm the prune. Minor frontmatter bump, patch root VERSION bump, CHANGELOG.md section, ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 23. Migrate /task-add onto the task-engine (task 129)

Depends on: 22

Context: none

```prompt
/task-implement 129

Read .claude/tasks/129.md first. Written against the post-118 shape of commands/task-add.md; the phase structure is not touched, text moves out and nothing else moves. Verify with one throwaway task via /task-add --no-commit --short before and after, then discard it. Minor frontmatter bump, patch root VERSION bump, CHANGELOG.md section, ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 24. Migrate /task-implement onto the task-engine (task 130)

Depends on: 23

Context: none

```prompt
/task-implement 130

Read .claude/tasks/130.md first. Lands last, on top of 118, 119 and 123: cites all six reference files; states the one-commit-under---review rule exactly once (commit.md or SKILL.md, not both); dirty-tree.md becomes a reference to tree.md or is deleted; delegated-runs.md keeps its fixed-size open flag list; /task-review and /task-iterate are NOT migrated and the --review availability gate stays a runtime check, not `requires:`. Minor frontmatter bump, patch root VERSION bump, CHANGELOG.md section, ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 25. Documentation for shared-phase-engine (task 131)

Depends on: 24

Context: none

```prompt
/task-implement 131

Read .claude/tasks/131.md first. Documentation only: it qualifies (does not delete) the authoring guide's council-gate prohibition, and its Decisions pre-authorise editing the /architect-owned feature document on five listed points — do not stop to ask. Bump VERSION (patch), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 26. Replace /task-add's ownership notice with a pre-authorisation gate (task 139)

Depends on: 25

Context: none

```prompt
/task-implement 139

Read .claude/tasks/139.md first. In-command owner list (features/*.md → /architect; product-design.md, technical-direction.md, business-model.md → /product-design; product-roadmap.md → /product-roadmap; .claude/PLAN.md → /production-plan — no runtime read of any table), detection on every task the run drafts, one question per owned file inside the existing PHASE 3 gate, a grant written into Decisions with date and enumerated points or the file dropped with the deferral noted, silence never a grant. Written against the post-129 shape of commands/task-add.md. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 27. Add the /runbook-run skill with its two references (task 140)

Depends on: 26

Context: none

```prompt
/task-implement 140

Read .claude/tasks/140.md first. It ships skills/runbook-run/ with exactly two reference files (runbook-schema.md, subagent-contract.md): the orchestrator reads CLAUDE.md, the runbook and the index and nothing else; re-reads the body at every step; spawns one subagent per step; WAITS for the asynchronous result before ticking anything; relays questions with the fixed block; propagates facts into later steps' Context:; writes exactly two files; refuses nested runbooks; treats an ambiguous report as failure. The runbook you are executing right now (.claude/runbooks/implement-ecc-import.md, with its .claude/RUNBOOKS.md block) is the read-only reference shape the task cites — do not edit it. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 28. Add the /runbook-create command (task 141)

Depends on: 27

Context: none

```prompt
/task-implement 141

Read .claude/tasks/141.md first. commands/runbook-create.md with `requires: skill:runbook-run`, citing the schema by installed path and never restating it; the four target forms including --append; the two source modes; the nine prompt-quality rules stated in full; the shape-only confirmation gate; authoring-command commit convention. The runbook you are executing is the read-only reference shape — do not edit it. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 29. Add the /runbook-list command (task 142)

Depends on: 28

Context: none

```prompt
/task-implement 142

Read .claude/tasks/142.md first. Reads .claude/RUNBOOKS.md only, never opens a body; one line per runbook plus a `↳ failed at` continuation for [FAILED]; bracketless case-insensitive status filter; writes nothing. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 30. Add the /runbook-clean command (task 143)

Depends on: 29

Context: none

```prompt
/task-implement 143

Read .claude/tasks/143.md first. Mirrors /task-clean: resolve, plan-and-confirm naming both paths, remove and commit explicit paths; [DONE] only, no --force; a named non-[DONE] runbook refused by name; an unknown name aborts the whole run. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 31. Add the /runbook-suggest skill (task 144)

Depends on: 30

Context: none

```prompt
/task-implement 144

Read .claude/tasks/144.md first. A ~30-line skill whose description is the trigger: it suggests running /runbook-create in one or two lines, asks nothing, reads no file, names no runbook; threshold and anti-triggers in both description and body; `requires: command:runbook-create`. Bump VERSION (minor), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## [ ] 32. Documentation for runbook-suite (task 145)

Depends on: 31

Context: none

```prompt
/task-implement 145

Read .claude/tasks/145.md first. Documentation only. Its Decisions pre-authorise editing the /architect-owned feature document on three listed points — do not stop to ask. Bump VERSION (patch), add the CHANGELOG.md section, run ./scripts/check-changelog.sh. The task body carries every decision; do not re-open any. If a precondition is not [DONE], stop and report. Do not add --no-commit or --no-push.
```

## Do not re-propose

- Freezing chosko-llm feature work (a council recommendation, rejected: job-hunter-cli repeatedly requires chosko-llm features to be created or updated, so tooling work here is demand-driven).
- Any ECC feature assessed and discarded in the companion document: config-gc, rules-distill as a shipped skill, inherit-legacy-style, update-codemaps, intent-driven-development, spec-miner, harness-audit, delivery-gate, prompt-optimizer, token-budget-advisor, code-explorer, and every ECC dimension-reviewer agent except `code-reviewer`.
- A PLAN.md, product roadmap or milestones for this repo (CLAUDE.md: it is tooling, not a product).
- Re-opening any decision recorded in a task body's Decisions section; the bodies are the authority.
