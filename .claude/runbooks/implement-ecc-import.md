# Runbook: implement-ecc-import

Created: 2026-08-24 · Source: manual · Model: opus
Sequencing: strictly ordered 1→32, one task per step. version-changelog (1–4) lands first so every later VERSION bump writes its CHANGELOG entry; the dual-LLM deletion (5) precedes everything that edits skills/task-implement/SKILL.md; session-continuity (6–8) and repo-local-audits (9–12) are independent of the rest and go next; then the launcher → peer-review → shared-phase-engine chain (13–25) in dependency order because all three features edit skills/task-implement/SKILL.md; 139 (26) needs the post-engine task-add; runbook-suite (27–32) needs `requires:` from 125.
Companion: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md

## [x] 1. Backfill CHANGELOG.md and land the versioning rule (task 146)

Depends on: none

Context: none

```prompt
/task-implement 146
```

Done: 2026-08-25 — commit 9477b1f (pushed). CHANGELOG.md created with 105 sections (0.1.0…0.62.2), rule + converse added to CLAUDE.md § Versioning and docs/authoring-guide.md; VERSION 0.62.1→0.62.2. Decisions: 0.53.0 dated 2026-08-07 (ee926e2) carrying 13e01c3 content; 0.52.1 claims shared claude-council commits; 0.59.0 records merge in one bullet; pure-backlog commits yield no bullets. No reference to scripts/check-changelog.sh anywhere yet (deliberately deferred to task 147). Premises held; nuance: 13e01c3 is on master first-parent, roadmap work is the side branch.

## [x] 2. Add the check-changelog.sh guard (task 147)

Depends on: 1

Context:
- 2026-08-25 (from step 1): CLAUDE.md § Versioning and the CHANGELOG.md preamble deliberately do not yet mention `scripts/check-changelog.sh`; task 147 should add that reference when it creates the guard. CHANGELOG.md has 105 sections, top section `0.62.2` = VERSION; strictly descending semver, no sub-headings, no shas.

```prompt
/task-implement 147
```
Done: 2026-08-25 — commit 47de381 (pushed). scripts/check-changelog.sh added (four invariants, numeric semver compare, silent on success, not a subcommand); authoring guide gained #### The guard under ### The changelog rule; CLAUDE.md § Versioning names the script (out-of-Files edit, on step 1's fact); VERSION 0.62.2→0.62.3. Premises: scripts/check-task-parity.sh is already red on this branch (unknown status tags [PLANNED]/[NEW]/[ITERATED] on the prompt side) independent of this task; running bin/chosko-llm trips the daily auto-upgrade hook (harmless, leaves gitignored .auto-upgrade-state). Orchestrator follow-up (user request, commit after 47de381): CHANGELOG.md preamble cut to one line, domain doc § 1 and authoring-guide section schema amended, VERSION 0.62.3→0.62.4.

## [x] 3. Print what changed on upgrade (task 148)

Depends on: 2

Context:
- 2026-08-25 (from steps 1–2): VERSION is now 0.62.4; CHANGELOG.md top section is `0.62.4` and its preamble is a single line (everything above the first `## ` is still preamble and never printed). scripts/check-changelog.sh exists — run it after the bump. Running bin/chosko-llm in the working repo trips the daily auto-upgrade hook (harmless).

```prompt
/task-implement 148
```
Done: 2026-08-25 — commit 2b28518 (pushed). lib.sh gained raw_version, src_changelog_path, print_changelog_range <old> <new> (return 0 = printed, 1 = nothing printed; single buffered awk pass; internal exit codes 10/11/12; cyan accent); resolve_version refactored onto raw_version; cmd-upgrade.sh prints the range after git pull and dumps git log --oneline only when the printer returns non-zero. VERSION 0.62.4→0.63.0. Premise correction: resolve_version is no longer byte-for-byte identical in one degenerate case — an empty/whitespace-only VERSION file now yields "unknown (sha)" instead of " (sha)"; accepted as the more correct answer. Verified against a throwaway clone in the scratchpad, never the real ~/.chosko-llm.

## [x] 4. Documentation for version-changelog (task 149)

Depends on: 3

Context:
- 2026-08-25 (orchestrator): .claude/domain/features/version-changelog.md § 1 was deliberately amended after the task body was written — the CHANGELOG.md preamble is one line, rules live in CLAUDE.md and the authoring guide. The body's "feature document is deliberately NOT changed" refers to task 149's own scope; do not revert that amendment. CLAUDE.md § Versioning already names scripts/check-changelog.sh (step 2).
- 2026-08-25 (from step 3): VERSION is now 0.63.0. lib.sh helpers landed as raw_version, src_changelog_path (in the src_*_path family) and print_changelog_range under a `# ---------- changelog ----------` section; the printer writes to stderr, returns 0 when it printed and 1 otherwise; cmd-upgrade.sh suppresses the git log dump exactly when the printer returned 0. Accent colour is cyan.

```prompt
/task-implement 149
```
Done: 2026-08-25 — commits 58192e4 (task 149) and e79f583 (feature version-changelog marked [DONE] in FEATURES.md, user-approved), both pushed. README (upgrade readout, versioning rule + guard pointer, repo-layout rows), docs/cli-help.txt, .claude/context/shared-lib.md (new Version and Changelog readout sections), .claude/context/cmd-upgrade.md, .claude/context/INDEX.md (CHANGELOG.md canonical doc, Last updated 2026-08-25). VERSION 0.63.0→0.63.1. Premises: README line hints off by a few lines; shared-lib.md had no existing version section (created one). Feature version-changelog fully shipped.

## [x] 5. Delete the dead dual-LLM lane (task 118)

Depends on: 4

Context:
- 2026-08-25 (from step 2): scripts/check-task-parity.sh is already red on this branch before any deletion — it reports [PLANNED], [NEW], [ITERATED] as unknown status tags on the prompt side. Not a regression to fix; relevant only if the task expects a green baseline.
- 2026-08-25 (from step 4): VERSION is now 0.63.1; every VERSION bump from here on writes its CHANGELOG.md section and runs scripts/check-changelog.sh. Subagents so far have used the repo's trailer-free commit style. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator step marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 118
```
Done: 2026-08-25 — commit dc4f951 (pushed). 36 files, +156/−1681. Deleted scripts/cmd-task-impl.sh, scripts/lib-task-external.sh, scripts/check-task-parity.sh, commands/task-enrich.md, .claude/context/cmd-task-impl.md, .claude/context/lib-task-external.md, .claude/external/{implement,tests}-prompt.md; task-impl subcommand removed from bin/chosko-llm, help, cli-help.txt; /task-add --enrich and enriched-body schema gone; Target: keeps exactly claude / claude+human / human; /task-setup reduced to TASKS.md + tasks/ + two wrappers (# CHOSKO_TASK_IMPL_STUB kept). VERSION 0.63.1→1.0.0; frontmatter: task-add 2.0.0, task-setup 2.0.0, task-implement 1.0.0 (skills/task-implement/SKILL.md), patch bumps on domain-setup, project-setup, unity-mcp-setup, architect. Extra decisions: design-process.md and technical-direction.md CI-guard examples repointed at check-changelog.sh; context INDEX Conventions marker now says eleven files. Premises: body said VERSION 0.62.0→1.0.0, actual start 0.63.1; skills/task-implement/body-schemas.md has no frontmatter (bump went on SKILL.md).

## [x] 6. Add the /session-save command (task 132)

Depends on: 5

Context:
- 2026-08-25 (from step 5): VERSION is now 1.0.0; skills/task-implement/SKILL.md is at 1.0.0, commands/task-add.md and task-setup at 2.0.0. The dual-LLM lane is gone (no cmd-task-impl.sh, lib-task-external.sh, check-task-parity.sh, task-enrich, --enrich, Target: local). Every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 132
```
Done: 2026-08-25 — commit 722c4fd (pushed). commands/session-save.md at 0.1.0: writes .claude/sessions/YYYY-MM-DD-HHMM-<slug>.md, shared header (Work:/Running:), full form (nine sections) and pointer form (Resume from:), known-artifact table with the single /product-design → .claude/domain/design-process.md row (task body removed the /task-implement row; body is authority over the feature document), supersession delete, no commit/push, exactly one shell call (clock read for HHMM). VERSION 1.0.0→1.1.0. Premises held.

## [x] 7. Add the /session-resume command (task 133)

Depends on: 6

Context:
- 2026-08-25 (from step 6): VERSION is now 1.1.0. commands/session-save.md (0.1.0) landed with: shared header block (`# Session: …`, `Work:` four-value table with `none` first-class, `Running:`), full form = optional preamble + nine sections in the feature document's order, pointer form = header + `Resume from:` + one sentence; known-artifact table has ONE row (/product-design → .claude/domain/design-process.md) per task 132's Decisions; the command makes exactly one shell call (clock read). Read that file for the exact header shape /session-resume must parse. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 133
```
Done: 2026-08-25 — commit 890c3ef (pushed). commands/session-resume.md at 0.1.0: three argument forms (none / YYYY-MM-DD / path), candidacy by Work: line, pointer form followed via Resume from:, 14-day staleness flag, fixed-shape briefing ending with the deletion handover sentence, read-only (at most one clock read). VERSION 1.1.0→1.2.0. Decisions: CHANGELOG.md edited though not in Files: (rule landed after the body); unrecognized argument falls back to newest candidate, explicit missing path stops. Disclosure: the agent amended an unpushed commit (eb4af56) to fix a mangled subject line — no hook skipped, no force push. Note: ./bin/chosko-llm ls --available reads the managed clone unless CHOSKO_LLM_HOME points at the working tree.

## [x] 8. Documentation for session-continuity (task 134)

Depends on: 7

Context:
- 2026-08-25 (from steps 6–7): VERSION is now 1.2.0. commands/session-save.md and commands/session-resume.md both at 0.1.0. Known-artifact table has ONE row (/product-design → .claude/domain/design-process.md) per task 132's Decisions — the feature document lists two; the body is authority. /session-resume takes no task-number selector; deletion handover is a closing sentence naming the resumed file. Verify with CHOSKO_LLM_HOME=E:/projects/chosko-llm ./bin/chosko-llm ls --available (without the override it reads the managed clone). The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 134
```
Done: 2026-08-25 — commits b5476b1 (task 134) and 2d6e3c7 (feature session-continuity [DONE], pre-approved), both pushed. README gained "Hand off a conversation — /session-save and /session-resume"; .claude/context/features.md gained two shipped entries; authoring guide cross-reference; feature document reconciled (seven authorized items + <date|path> signature; Open questions: none outstanding). VERSION 1.2.0→1.2.1. Premises held; CHANGELOG.md edited as collateral of the bump (not in Files:).

## [x] 9. Record the .claude/skills/ exemption in CLAUDE.md (task 135)

Depends on: 8

Context:
- 2026-08-25 (from steps 1–8): VERSION is now 1.2.1; every VERSION bump writes its CHANGELOG.md section and runs scripts/check-changelog.sh (CHANGELOG.md is legitimate collateral even when absent from Files:). CLAUDE.md § Versioning already carries the changelog rule and its converse (a change that does not bump VERSION gets no entry — repo-local .claude/ artifacts never bump VERSION); the exemption task 135 records must sit consistently beside that bullet. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 135
```
Done: 2026-08-25 — commit 66adc0b (pushed). CLAUDE.md § Versioning gained the narrow .claude/skills/ exemption bullet (repo-local dev tooling: no version: frontmatter, invisible to CLI verbs, never bumps VERSION; the rest of .claude/ — context, domain, backlog — bumps as usual). VERSION 1.2.1→1.2.2. Premise correction: the section had four bullets, not three (changelog bullet landed at step 1); its converse clause was surgically reworded to "artifacts exempt from the bump (next bullet) never get one" so it no longer contradicts the exemption. No .claude/skills/ created yet.

## [x] 10. Add the repo-local /context-budget audit skill (task 136)

Depends on: 9

Context:
- 2026-08-25 (from step 9): VERSION is now 1.2.2. CLAUDE.md § Versioning has the .claude/skills/ exemption: a change confined to .claude/skills/ does NOT bump VERSION and gets no CHANGELOG entry; anything else in .claude/ or the repo still bumps. Repo-local skills carry no version: frontmatter and no CLI verb sees them. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 136
```
Done: 2026-08-25 — commit f7f436b (pushed). .claude/skills/context-budget/SKILL.md created (first repo-local skill; frontmatter name/type/description, no version:), no VERSION bump, no CHANGELOG entry, per the exemption. Decisions: estimated saving = (lines − threshold) × (est. tokens ÷ lines); inventory find carries -size +0c (empty .gitkeep files divide by zero); description: extraction accumulates multi-line YAML plain scalars. Premises: line figures in the body are stale (task-setup now 351 lines, unflagged; production-plan/product-design/product-roadmap/architect now flag; task-add 834, task-implement SKILL 697); first-line-only description count undercounts.

## [x] 11. Add the repo-local /rule-overlap audit skill (task 137)

Depends on: 10

Context:
- 2026-08-25 (from step 10): VERSION is still 1.2.2 (repo-local skills bump nothing). .claude/skills/context-budget/SKILL.md exists — follow its frontmatter shape (name, type, description; no version:, with the one-line reason) and its register. Inventory tip from that skill: `find` needs `-size +0c` because skills/.gitkeep and skills/claude-council/journal/.gitkeep are empty; description: fields are multi-line YAML plain scalars, so accumulate continuation lines. The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 137
```
Done: 2026-08-25 — commit 0c6a5d9 (pushed). .claude/skills/rule-overlap/SKILL.md created (no version:, no VERSION bump, no CHANGELOG entry). Deterministic grep/awk collection of headings + normative lines over commands/*.md, skills/**/*.md, claude-md/*.md; model judges sameness; threshold three or more features (features counted, not occurrences); disagreement ranked first; vendored skills, hooks/, statusline/, docs/, scripts/, bin/, .claude/ excluded; read-only. Verified: surfaces "Never retry, never force-push" at task-add.md:784, task-clean.md:270, task-implement/SKILL.md:532. Premises held.

## [ ] 12. Documentation for repo-local-audits (task 138)

Depends on: 11

Context:
- 2026-08-25 (from steps 9–11): VERSION is 1.2.2 (task 135 bumped it; 136 and 137 bumped nothing per the exemption). Both repo-local skills exist: .claude/skills/context-budget/SKILL.md and .claude/skills/rule-overlap/SKILL.md, frontmatter name/type/description only. CLAUDE.md § Versioning holds the exemption bullet and a reworded converse clause ("artifacts exempt from the bump (next bullet) never get one"). Task 138's own doc changes DO bump VERSION (README, authoring guide, context/domain layers are not under .claude/skills/). The working tree will show .claude/runbooks/implement-ecc-import.md modified (orchestrator marker) — proceed past the dirty-tree gate without staging it.

```prompt
/task-implement 138
```

## [ ] 13. Turn /task-implement's batch parent into a launcher (task 119)

Depends on: 12

Context:
- 2026-08-25 (from step 5): skills/task-implement/SKILL.md is at 1.0.0 after task 118 removed the Target: local warning and the dual-LLM lane; skills/task-implement/body-schemas.md carries no frontmatter (the SKILL.md version covers the folder). check-task-parity.sh no longer exists.

```prompt
/task-implement 119
```

## [ ] 14. Documentation for task-implement-launcher (task 120)

Depends on: 13

Context: none

```prompt
/task-implement 120
```

## [ ] 15. Add the /task-review skill (task 121)

Depends on: 14

Context: none

```prompt
/task-implement 121
```

## [ ] 16. Add the /task-iterate skill (task 122)

Depends on: 15

Context: none

```prompt
/task-implement 122
```

## [ ] 17. Add the --review / --rounds loop to /task-implement (task 123)

Depends on: 16

Context: none

```prompt
/task-implement 123
```

## [ ] 18. Documentation for task-peer-review (task 124)

Depends on: 17

Context: none

```prompt
/task-implement 124
```

## [ ] 19. Add the `requires:` frontmatter field (task 125)

Depends on: 18

Context: none

```prompt
/task-implement 125
```

## [ ] 20. Create the task-engine skill by verbatim extraction (task 126)

Depends on: 19

Context: none

```prompt
/task-implement 126
```

## [ ] 21. Migrate /task-list onto the task-engine (task 127)

Depends on: 20

Context: none

```prompt
/task-implement 127
```

## [ ] 22. Migrate /task-clean onto the task-engine (task 128)

Depends on: 21

Context: none

```prompt
/task-implement 128
```

## [ ] 23. Migrate /task-add onto the task-engine (task 129)

Depends on: 22

Context: none

```prompt
/task-implement 129
```

## [ ] 24. Migrate /task-implement onto the task-engine (task 130)

Depends on: 23

Context: none

```prompt
/task-implement 130
```

## [ ] 25. Documentation for shared-phase-engine (task 131)

Depends on: 24

Context: none

```prompt
/task-implement 131
```

## [ ] 26. Replace /task-add's ownership notice with a pre-authorisation gate (task 139)

Depends on: 25

Context: none

```prompt
/task-implement 139
```

## [ ] 27. Add the /runbook-run skill with its two references (task 140)

Depends on: 26

Context: none

```prompt
/task-implement 140
```

## [ ] 28. Add the /runbook-create command (task 141)

Depends on: 27

Context: none

```prompt
/task-implement 141
```

## [ ] 29. Add the /runbook-list command (task 142)

Depends on: 28

Context: none

```prompt
/task-implement 142
```

## [ ] 30. Add the /runbook-clean command (task 143)

Depends on: 29

Context: none

```prompt
/task-implement 143
```

## [ ] 31. Add the /runbook-suggest skill (task 144)

Depends on: 30

Context: none

```prompt
/task-implement 144
```

## [ ] 32. Documentation for runbook-suite (task 145)

Depends on: 31

Context: none

```prompt
/task-implement 145
```

## Do not re-propose

- Freezing chosko-llm feature work (a council recommendation, rejected: job-hunter-cli repeatedly requires chosko-llm features to be created or updated, so tooling work here is demand-driven).
- Any ECC feature assessed and discarded in the companion document: config-gc, rules-distill as a shipped skill, inherit-legacy-style, update-codemaps, intent-driven-development, spec-miner, harness-audit, delivery-gate, prompt-optimizer, token-budget-advisor, code-explorer, and every ECC dimension-reviewer agent except `code-reviewer`.
- A PLAN.md, product roadmap or milestones for this repo (CLAUDE.md: it is tooling, not a product).
- Re-opening any decision recorded in a task body's Decisions section; the bodies are the authority.
