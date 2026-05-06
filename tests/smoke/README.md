# Smoke tests

Manual checklists, one markdown file per feature, named `<feature-name>.md`.
There is no automation in v1 — these are scripts a human runs to confirm a
feature still works after edits.

## Format

Each file should follow this shape:

```markdown
# Smoke test: <feature-name>

**Type:** command | skill
**Source:** commands/<name>.md  (or skills/<name>/SKILL.md)

## Setup

- Any required state (env vars, fixture files, current branch, etc.).

## Steps

1. Run/invoke the feature: `/<name>` or describe the trigger.
2. ...

## Expected

- What output, behavior, or side effect should appear.
- Note anything that would count as a regression.

## Notes

- Edge cases worth checking opportunistically.
```

## Conventions

- One file per feature. Named exactly after the feature's `name` frontmatter
  field, with `.md` appended.
- Update the smoke test in the same commit that bumps the feature's version.
- Keep steps short; assume the runner is familiar with Claude Code.
