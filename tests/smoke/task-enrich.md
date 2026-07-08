# Smoke test: task-enrich

**Type:** command
**Source:** commands/task-enrich.md

## Setup

- A project with an initialized task backlog (`.claude/TASKS.md` and
  `.claude/tasks/` exist).
- At least one task body file with `Target: claude` (or no `Target:` line).
- A second task body file with `Target: local` (for the already-enriched
  guard test).

## Steps

### Happy path

1. Pick a `Target: claude` task — note its number `<N>`.
2. Invoke `/task-enrich <N>`.
3. Observe PHASE 1 (silent context gather — no output expected).
4. Observe PHASE 2 draft: the proposed `## Context bundle` and
   `## Implementation steps` sections are presented, followed by
   "Approve and write?".
5. Review the draft: confirm context bundle contains only what is
   necessary (no unrelated file dumps), and that implementation steps
   are concrete enough to follow without additional reads.
6. Approve with "yes".
7. Observe the write report: task number/title confirmed, `Target:`
   updated to `local`, and (no `--commit`) a reminder that no commit was made.

### Verify the written file

8. Open `.claude/tasks/<N>.md` and confirm:
   - Line 2 reads `Target: local`.
   - `## Goal`, `## Acceptance criteria`, `## Decisions` (if present),
     and `## Hints` sections are unchanged.
   - `## Context bundle` section is present and non-empty.
   - `## Implementation steps` section is present and non-empty.
   - No other sections were added or removed.

### Already-enriched guard

9. Invoke `/task-enrich <N>` again on the same (now enriched) task.
10. Verify the skill exits immediately with the "already enriched" message
    and does not modify the file.

### Non-existent task guard

11. Invoke `/task-enrich 9999`.
12. Verify the skill exits with a "body file not found" message and does
    not create or modify any file.

### Human-in-the-loop guard

13. Create a task body whose second line reads `Target: claude+human`
    (with a `## Manual interventions` section). Invoke `/task-enrich <N>`.
14. Verify the command stops immediately with the "requires human
    intervention" message pointing the user at `/task-implement`, and the
    file is unchanged.
15. Repeat with `Target: human` — same refusal, file unchanged.

### --commit flag

16. On a fresh `Target: claude` task `<M>`, invoke `/task-enrich <M> --commit`
    and approve the draft.
17. Verify a single new commit exists (subject `Enrich task <M>: …`) and
    `git show --stat HEAD` lists ONLY `.claude/tasks/<M>.md`.
18. Invoke `/task-enrich <M> --commit --no-commit`: the command stops with
    "`--commit and --no-commit cannot be combined. Pick one.`" and changes
    nothing.

## Expected

- The body file transitions from `Target: claude` to `Target: local`.
- Goal, Acceptance criteria, Decisions, and Hints are byte-for-byte
  unchanged.
- `## Context bundle` is selective: it contains excerpts from source
  files relevant to the task, not wholesale file dumps.
- `## Implementation steps` are actionable and self-contained: a local
  LLM fed only the enriched body should be able to implement without
  additional reads.
- Without `--commit`, no commit is made and the user is explicitly reminded.
  With `--commit`, exactly one commit of `.claude/tasks/<N>.md` is made (no
  catch-all staging, no hook-skipping flags).
- `.claude/TASKS.md` is not modified.
- Re-enriching an already-enriched task is a no-op with a clear message.
- Enriching a `Target: claude+human` or `Target: human` task is refused
  with a message directing the user to `/task-implement`; the body file
  is untouched.

## Notes

- Qualitative check: after enriching a real task, run the aider
  invocation from `task-workflow.md` and observe whether the local LLM
  navigates correctly using only the enriched body plus `implement-prompt.md`.
- Verify that a task with no `Target:` line is treated the same as
  `Target: claude` (enrichment proceeds, `Target: local` is inserted).
- Check that a lean context bundle (minimal excerpts) outperforms a
  bloated one (full file dumps) when fed to the local LLM.
