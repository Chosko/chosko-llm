# Smoke test: task-add

**Type:** command
**Source:** commands/task-add.md

## Setup

- A project that has already been initialized with `/task-setup` (so
  `.claude/TASKS.md` and `.claude/tasks/` exist).
- For the not-yet-initialized scenario, also test against a project where
  neither artifact is present.
- For `--enrich` tests, `skills/task-enrich/SKILL.md` must be installed.

## Steps

### Default mode

1. **Not-yet-initialized**: in a fresh project, invoke
   `/task-add fix the login redirect to preserve the return URL`.
   Verify the agent refuses and instructs the user to run `/task-setup`
   first. Confirm no file was created.
2. Run `/task-setup`, then re-invoke the same `/task-add` command.
3. Observe the READ phase: agent reports what it's reading (one line).
4. If questions arise (PHASE 2), answer them.
5. Observe the PLAN output: index file path, body file path, new ID,
   draft summary block, and draft body with Goal, Acceptance criteria,
   Hints — and Decisions only if non-obvious choices were made.
6. Confirm with "yes".
7. Observe the WRITE report: assigned task ID, both file paths,
   counter advanced.
8. Observe PHASE 5 commit automatically — no prompt — and the commit
   hash reported.

### `--enrich` mode

9. Invoke `/task-add --enrich add a CSV export feature`.
10. Observe PHASE 1 reads `skills/task-enrich/SKILL.md` in addition to
    the normal reads.
11. Observe the PLAN output includes `Target: local`, plus
    `## Context bundle` and `## Implementation steps` sections.
12. Confirm with "yes" and verify the written body contains all six
    sections (Goal, Acceptance criteria, Decisions if applicable,
    Hints, Context bundle, Implementation steps).

### `--enrich` without task-enrich installed

13. Uninstall or rename `skills/task-enrich/SKILL.md` temporarily.
14. Invoke `/task-add --enrich some task`.
15. Verify the agent stops at PHASE 0 with a clear message directing
    the user to install the skill. No file is written.

## Expected

- Without `/task-setup` having run, `/task-add` writes nothing and
  prints the setup-required message.
- No file is written before explicit approval.
- Default summary block contains: number, title, `Status: [MISSING]`,
  `Target: claude`, `Files:`, `Preconditions:`. Nothing else.
- Default body contains: `Target: claude` on line 2, then Goal,
  Acceptance criteria, Hints (always present). Decisions present only
  when non-obvious choices were made.
- `--enrich` body contains `Target: local` on line 2, the same four
  base sections, plus Context bundle and Implementation steps.
- `Last task number:` incremented by 1.
- A git commit is made automatically at PHASE 5. It covers exactly the
  two files PHASE 4 wrote and nothing else.

## Commit scenarios

### Normal commit path

1. Run `/task-add` end-to-end on a clean working tree.
2. Approve the draft and let PHASE 4 write the two files.
3. Verify PHASE 5 commits automatically and reports the hash.
4. Run `git show --stat HEAD` — confirm exactly two files:
   `.claude/TASKS.md` and `.claude/tasks/<N>.md`.
5. Verify `git status` is clean.

### Dirty-tree safety

1. Pre-create an unrelated modified file (e.g. `echo "junk" >> README.md`).
2. Run `/task-add` end-to-end and approve.
3. Verify the commit includes ONLY the two task files — the dirty
   `README.md` is still in the working tree, unstaged.

### Pre-commit hook failure

1. Install a hook that always exits non-zero.
2. Run `/task-add` end-to-end and approve.
3. Verify the commit fails, the agent surfaces the hook output, does
   NOT retry or use `--no-verify`, and leaves the files staged.

## Notes

- Test the "no questions" fast path with a very specific description.
- Test that Decisions is omitted when no ambiguous choices were made.
- Verify silence at PHASE 3 is not treated as approval.
- Verify adding two tasks in a row produces sequential IDs.
