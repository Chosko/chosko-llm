# Non-current task-body schemas

Read this only when a task body does not match the current schema
(**Goal / Acceptance criteria / Decisions / Hints**), which SKILL.md's
USING THE TASK BODY section already covers.

## Older schema

`Description` / `Required reading` / `Conventions to follow` / `Out of
scope` / `Tests` / `Definition of done`. Treat the body as a high-quality
starting point per those old conventions. Fall back to the context layer
(`CLAUDE.md`, `.claude/context/`, `.claude/domain/`) when the body is
insufficient.

Under this schema, Step 2 of the per-task workflow draws its assertions
from the `### Tests` section, and its regression guards from `Definition
of done`.

In all cases: use judgment, not a checklist.
