# Runbook: revision-side-overhaul

Created: 2026-09-21 · Source: conversation (tasks 247–253 authored this session) · Model: opus
Last step number: 13
Sequencing: Steps 8–11 run last so each body is consolidated once, after every implementation step that edits it.

## [x] 1. Implement 247 — editing discipline claude-md

Depends on: none

Context: none

```prompt
/task-implement 247 --review
```

Done: 2026-09-21, commit `565509d` (12 files, +146/-57). Decision: `skills/architect/SKILL.md` bumped to 0.12.6 too, since the template is installed as part of the skill folder.

## [x] 2. Implement 249 — /task-add design-change question

Depends on: none

Context: none

```prompt
/task-implement 249 --review
```

Done: 2026-09-21, commit `d8ca4d9` (13 files, +140/-215). Decision: `docs/reference.md` gained a paragraph on the question; the repo's own dogfood copies under `.claude/commands` and `.claude/skills` were left for their own refresh commit.

## [x] 3. Implement 251 — /architect amend precision, multi-feature

Depends on: none

Context: none

```prompt
/task-implement 251 --review
```

Done: 2026-09-21, commit `d76ccb1` (13 files, +283/-234). Decision: on a multi-feature ask, an asked feature the reply leaves unnamed is Stop for that feature, never its marked letter; a missing `Doc:` stops the whole run.

## [x] 4. Implement 252 — three headless amend arms

Depends on: none

Context: none

```prompt
/task-implement 252 --review
```

Done: 2026-09-21, commit `35ef556` (18 files, +459/-85). Wrong premise: task 252 asked for a roadmap owner step in `/pipeline-revise`'s sequences, but no branch file reaches `product-roadmap.md`; the clause is void until step 7's change sets can name a roadmap item.

## [x] 5. Implement 248 — /doc-consolidate

Depends on: 1

Context: none

```prompt
/task-implement 248 --review
```

Done: 2026-09-21, commit `7fc1fd4` (8 files, +300/-3). Decision: ships with `disable-model-invocation: true` like the two `/refactor-*` features, and names the schema-owning skills instead of pathing into them, so it installs alone.

## [x] 6. Implement 250 — two-group report, consequential edits

Depends on: 2

Context: none

```prompt
/task-implement 250 --review
```

Done: 2026-09-21, commit `a735c9f` (12 files, +150/-37). Decision: end-of-run order is FEATURE COMPLETION proposal, closing report, `/follow-ups`; delegated agents return a bounded sixth field of *For the record* lines. Wrong premise: `/runbook-run`'s closing report has no Needs you / For the record groups; aligning it is a follow-up.

## [x] 7. Implement 253 — change-set /pipeline-revise, patch retired

Depends on: 3, 4

Context:
- 2026-09-21 (from step 4): `/product-roadmap amend` (`../product-roadmap/amend.md`) has no consumer in the branch files yet — no owner sequence reaches `product-roadmap.md`. A change-set item that names a milestone is where a roadmap owner step first exists; route it through that arm.

```prompt
/task-implement 253 --review
```

Done: 2026-09-21, commit `e9f6b13` (37 files, +983/-1315). Decision: `task-engine/references/amend.md` and `runbook-run/references/step-amend.md` gained the passed-in-draft clause so their steps run headless; `/pipeline-revise` carries no `replaces:` for the retired command — `chosko-llm rm command:pipeline-patch` is the removal path.

## [x] 12. Implement 254 — /task-add approval digest

Depends on: 2

Context: none

```prompt
/task-implement 254 --review
```

Done: 2026-09-21, commit `e5018b9` (6 files, +64/-69). Wrong premise: task 254's criterion 7 names an OWNERSHIP PRE-AUTHORISATION section of `commands/task-add.md`; no such heading exists — the section it describes is DESIGN-CHANGE CHECK.

## [x] 13. Implement 255 — closing reports: two groups in /runbook-run, numbered Needs you

Depends on: 6

Context: none

```prompt
/task-implement 255 --review
```

Done: 2026-09-21, commit `dc58f43` (12 files, +154/-81). Wrong premise: task 255 asked to number the sixth return field in `delegated-runs.md`, but that field carries only For the record lines, which are never numbered; only its wording changed.

## [x] 8. Consolidate commands/task-add.md

Depends on: 2, 5, 7

Context: none

```prompt
/doc-consolidate commands/task-add.md --commit
```

Done: 2026-09-21, commit `07868b4` (3 files, +59/-134). Decision: `version:` bumped to 2.5.5 with `VERSION` 1.66.1 and a CHANGELOG section, although `/doc-consolidate` leaves frontmatter untouched — `cmd-update` is version-aware, so an unbumped body never reaches a user.

## [x] 9. Consolidate skills/runbook-run/SKILL.md

Depends on: 5

Context:
- 2026-09-21 (from step 8): `/doc-consolidate` leaves frontmatter untouched and its COMMITTING section stages "exactly the files written", but on this repo a shipped body ships only with a `version:` bump, a root `VERSION` bump and a CHANGELOG section in the same commit — step 8 did that, and each consolidation step does the same.

```prompt
/doc-consolidate skills/runbook-run/SKILL.md --commit
```

Done: 2026-09-21, commit `ecf962d` (3 files, +101/-201). Decision: the nested-runbook refusal now gives one reason, at THE EXECUTION LOOP step 5 — refused for the orchestration it duplicates, not for the depth it costs; the depth-based reason is gone.

## [ ] 10. Consolidate skills/task-implement/SKILL.md

Depends on: 5, 6

Context:
- 2026-09-21 (from step 8): `/doc-consolidate` leaves frontmatter untouched and its COMMITTING section stages "exactly the files written", but on this repo a shipped body ships only with a `version:` bump, a root `VERSION` bump and a CHANGELOG section in the same commit — step 8 did that, and each consolidation step does the same.
- 2026-09-21 (from step 9): a consolidation commit over 200 changed lines carries the `Co-Authored-By` and `Claude-Session` trailers per the global commit style — check `git diff --cached --shortstat` rather than copying step 8's trailer-less shape.

```prompt
/doc-consolidate skills/task-implement/SKILL.md --commit
```

## [ ] 11. Consolidate commands/runbook-create.md

Depends on: 5, 7

Context:
- 2026-09-21 (from step 8): `/doc-consolidate` leaves frontmatter untouched and its COMMITTING section stages "exactly the files written", but on this repo a shipped body ships only with a `version:` bump, a root `VERSION` bump and a CHANGELOG section in the same commit — step 8 did that, and each consolidation step does the same.
- 2026-09-21 (from step 9): a consolidation commit over 200 changed lines carries the `Co-Authored-By` and `Claude-Session` trailers per the global commit style — check `git diff --cached --shortstat` rather than copying step 8's trailer-less shape.

```prompt
/doc-consolidate commands/runbook-create.md --commit
```

## Do not re-propose

- Keeping `/pipeline-patch` as an alias of `/pipeline-revise` — rejected: fewer
  names to remember is the point of the fusion, and an alias keeps two names.
