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

### Split suggestion

16. Invoke `/task-add add a CSV export command and a PDF export command`
    (two independent deliverables). Observe PHASE 1.5 proposes a 2-task
    split with a title + one-line scope for each, then asks "Split into N
    tasks, keep as one, or adjust the breakdown?".
17. Accept the split. Observe PHASE 2 asks at most 1–4 questions across
    the whole breakdown (not a full round per part), PHASE 3 renders both
    parts' full drafts (summary block + body) in one message, and a single
    "Approve and write?" gate.
18. Approve. Observe PHASE 4 writes both body files with sequential IDs in
    one `.claude/TASKS.md` edit, `Last task number` advances by 2, and
    PHASE 5 makes exactly ONE commit whose message covers both task IDs.
    Verify `git show --stat HEAD` lists `.claude/TASKS.md` and both new
    `.claude/tasks/<N>.md` files.
19. Invoke `/task-add fix a typo in the login error message` (a small,
    single-deliverable description). Verify PHASE 1.5 stays silent — no
    split proposal — and the normal single-task flow runs.
20. Invoke `/task-add add CSV export and PDF export commands` again and
    decline the proposed split ("keep as one"). Verify it falls back to
    the normal single-task flow with the original description.
21. Invoke `/task-add --no-split add a CSV export command and a PDF export
    command`. Verify PHASE 1.5 is skipped entirely — no split proposal —
    and exactly one task is written.
22. Repeat steps 16-18 with a description where part 2 depends on part 1
    (e.g. "add a data model, then add an API endpoint that uses it").
    Verify the accepted split auto-wires part 2's `Preconditions:` to
    part 1's task ID, and part 1's `Preconditions:` is `none`.

### Human-in-the-loop authoring

23. Invoke `/task-add` with a description whose work clearly includes
    editor-only steps (e.g. "add an input system to this Unity project —
    the .inputactions importer and prefab wiring happen in the editor").
    Observe the draft carries `Target: claude+human` in both the summary
    block and the body, plus a `## Manual interventions` section between
    `## Decisions` (if present) and `## Hints`.
24. Verify the section format: it opens with a
    `⚠ REQUIRES MANUAL INTERVENTION` warning line, followed by numbered
    checkpoints, each anchored to a trigger point ("After X: …") and
    ending with a verifiable outcome.
25. Invoke `/task-add` with a description that is entirely manual (nothing
    agent-executable, e.g. "configure the store listing in the Google Play
    console"). Observe the draft carries `Target: human` and the
    `## Manual interventions` section covers the whole task.
26. Verify consistency both ways: no draft ever pairs
    `Target: claude+human`/`human` with a missing section, or a
    `## Manual interventions` section with `Target: claude`/`local`.
27. Invoke `/task-add` with an ordinary, fully agent-executable
    description. Verify the body has NO `## Manual interventions` section
    and `Target: claude`.

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
- A git commit is made automatically at PHASE 5 (default, no `--no-commit`).
  It covers exactly the two files PHASE 4 wrote and nothing else.
- With `--no-commit`, the two files are written but NO commit is made; the
  report reminds the user that nothing was committed.
- PHASE 1.5 proposes a split only when the description bundles independent
  deliverables or would be too large as one task; it stays silent otherwise.
- On an accepted split, all parts are written with sequential IDs in one
  `.claude/TASKS.md` edit, dependent parts' `Preconditions:` point at the
  earlier part's ID, and exactly ONE commit covers every part.
- `--no-split` suppresses PHASE 1.5 entirely; exactly one task is always
  written.
- Work with editor-only / manual steps yields `Target: claude+human` (or
  `human` when nothing is agent-executable) plus a `## Manual
  interventions` section; the target and the section always appear
  together, and ordinary tasks get neither.

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

### `--no-commit`

1. Run `/task-add --no-commit <description>` end-to-end and approve the draft.
2. Verify PHASE 4 writes both files, PHASE 5 runs NO git command, and the
   report reminds the user nothing was committed.
3. Verify `git status` shows the two new/modified task files uncommitted and
   `git log` has no new commit.
4. Run `/task-add --commit --no-commit <description>`: the command stops with
   "`--commit and --no-commit cannot be combined. Pick one.`" and writes
   nothing.

## Notes

- Test the "no questions" fast path with a very specific description.
- Test that Decisions is omitted when no ambiguous choices were made.
- Verify silence at PHASE 3 is not treated as approval.
- Verify adding two tasks in a row produces sequential IDs.
- Verify a split proposal's parts are also assigned sequential IDs.
