# Smoke test: task-setup

**Type:** command
**Source:** commands/task-setup.md

## Setup

- A project with no `.claude/TASKS.md` and no `.claude/tasks/`
  directory (fresh state).

## Steps

1. Invoke `/task-setup`.
2. Inspect the filesystem: `.claude/TASKS.md` exists; `.claude/tasks/`
   exists as an empty directory.
3. Open `.claude/TASKS.md` and verify it contains the header
   `# Tasks` and the line `Last task number: 0`, and nothing else.
4. Re-invoke `/task-setup` on the now-initialized project.

## Expected

- First invocation creates both artifacts; reports the paths.
- Stub `TASKS.md` has `Last task number: 0` and no task entries.
- Re-invocation reports "already initialized" and writes nothing.
- No git commit is made.

## Notes

- Test partial state: delete only `.claude/tasks/` (leave TASKS.md).
  `/task-setup` should re-create the missing directory without
  touching TASKS.md.
- Test partial state in the other direction: delete `TASKS.md` only.
  `/task-setup` should create a fresh stub without touching the
  existing tasks directory.
