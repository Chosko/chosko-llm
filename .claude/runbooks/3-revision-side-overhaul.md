# Runbook: revision-side-overhaul

Created: 2026-09-21 · Source: conversation (tasks 247–253 authored this session) · Model: opus
Last step number: 11
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

## [ ] 4. Implement 252 — three headless amend arms

Depends on: none

Context: none

```prompt
/task-implement 252 --review
```

## [ ] 5. Implement 248 — /doc-consolidate

Depends on: 1

Context: none

```prompt
/task-implement 248 --review
```

## [ ] 6. Implement 250 — two-group report, consequential edits

Depends on: 2

Context: none

```prompt
/task-implement 250 --review
```

## [ ] 7. Implement 253 — change-set /pipeline-revise, patch retired

Depends on: 3, 4

Context: none

```prompt
/task-implement 253 --review
```

## [ ] 8. Consolidate commands/task-add.md

Depends on: 2, 5, 7

Context: none

```prompt
/doc-consolidate commands/task-add.md --commit
```

## [ ] 9. Consolidate skills/runbook-run/SKILL.md

Depends on: 5

Context: none

```prompt
/doc-consolidate skills/runbook-run/SKILL.md --commit
```

## [ ] 10. Consolidate skills/task-implement/SKILL.md

Depends on: 5, 6

Context: none

```prompt
/doc-consolidate skills/task-implement/SKILL.md --commit
```

## [ ] 11. Consolidate commands/runbook-create.md

Depends on: 5, 7

Context: none

```prompt
/doc-consolidate commands/runbook-create.md --commit
```

## Do not re-propose

- Keeping `/pipeline-patch` as an alias of `/pipeline-revise` — rejected: fewer
  names to remember is the point of the fusion, and an alias keeps two names.
