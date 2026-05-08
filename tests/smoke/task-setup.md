# Smoke test: task-setup

**Type:** command
**Source:** commands/task-setup.md

## Setup

- A project with no `.claude/TASKS.md`, no `.claude/tasks/` directory,
  and no `.claude/external/implement-prompt.md` (fully fresh state).

## Steps

1. Invoke `/task-setup`.
2. Inspect the filesystem: `.claude/TASKS.md` exists; `.claude/tasks/`
   exists as an empty directory; `.claude/external/implement-prompt.md`
   exists.
3. Open `.claude/TASKS.md` and verify it contains the header
   `# Tasks` and the line `Last task number: 0`, and nothing else.
4. Open `.claude/external/implement-prompt.md` and verify it contains
   the role line ("You are an engineer implementing one task ..."),
   the Procedure section, the Output discipline section, and the Stop
   conditions section.
5. Re-invoke `/task-setup` on the now-initialized project.
6. Manually edit `.claude/external/implement-prompt.md` (e.g. add a
   custom note at the bottom). Re-invoke `/task-setup` and verify the
   edit is preserved — the file is NOT overwritten.

## Expected

- First invocation creates all three artifacts; reports each path.
- Stub `TASKS.md` has `Last task number: 0` and no task entries.
- `implement-prompt.md` is the static template verbatim; no
  project-specific interpolation.
- Re-invocation on a fully initialized project reports "already
  initialized" and writes nothing.
- A user-edited implement-prompt is never overwritten.
- No git commit is made.

## Notes

- Test partial state: delete only `.claude/tasks/` (leave TASKS.md and
  implement-prompt). `/task-setup` should re-create the missing
  directory without touching the others.
- Test partial state: delete only `TASKS.md`. `/task-setup` should
  create a fresh stub without touching the existing tasks directory or
  implement-prompt.
- Test partial state: delete only `.claude/external/implement-prompt.md`.
  `/task-setup` should re-create it from the template without touching
  TASKS.md or the tasks directory.
