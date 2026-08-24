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

## [ ] 2. Add the check-changelog.sh guard (task 147)

Depends on: 1

Context:
- 2026-08-25 (from step 1): CLAUDE.md § Versioning and the CHANGELOG.md preamble deliberately do not yet mention `scripts/check-changelog.sh`; task 147 should add that reference when it creates the guard. CHANGELOG.md has 105 sections, top section `0.62.2` = VERSION; strictly descending semver, no sub-headings, no shas.

```prompt
/task-implement 147
```

## [ ] 3. Print what changed on upgrade (task 148)

Depends on: 2

Context: none

```prompt
/task-implement 148
```

## [ ] 4. Documentation for version-changelog (task 149)

Depends on: 3

Context: none

```prompt
/task-implement 149
```

## [ ] 5. Delete the dead dual-LLM lane (task 118)

Depends on: 4

Context: none

```prompt
/task-implement 118
```

## [ ] 6. Add the /session-save command (task 132)

Depends on: 5

Context: none

```prompt
/task-implement 132
```

## [ ] 7. Add the /session-resume command (task 133)

Depends on: 6

Context: none

```prompt
/task-implement 133
```

## [ ] 8. Documentation for session-continuity (task 134)

Depends on: 7

Context: none

```prompt
/task-implement 134
```

## [ ] 9. Record the .claude/skills/ exemption in CLAUDE.md (task 135)

Depends on: 8

Context: none

```prompt
/task-implement 135
```

## [ ] 10. Add the repo-local /context-budget audit skill (task 136)

Depends on: 9

Context: none

```prompt
/task-implement 136
```

## [ ] 11. Add the repo-local /rule-overlap audit skill (task 137)

Depends on: 10

Context: none

```prompt
/task-implement 137
```

## [ ] 12. Documentation for repo-local-audits (task 138)

Depends on: 11

Context: none

```prompt
/task-implement 138
```

## [ ] 13. Turn /task-implement's batch parent into a launcher (task 119)

Depends on: 12

Context: none

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
