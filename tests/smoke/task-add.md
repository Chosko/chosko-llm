# Smoke test: task-add

**Type:** command
**Source:** commands/task-add.md

## Setup

- A project that has already been initialized with `/task-setup` (so
  `.claude/TASKS.md` and `.claude/tasks/` exist). For the
  not-yet-initialized scenario, also test against a project where
  neither artifact is present.

## Steps

1. **Not-yet-initialized**: in a fresh project, invoke
   `/task-add fix the login redirect to preserve the return URL`.
   Verify the agent refuses and instructs the user to run
   `/task-setup` first. Confirm no file was created.
2. Run `/task-setup`, then re-invoke the same `/task-add` command.
3. Observe the READ phase: agent reports what it's reading (one line),
   including the current `Last task number` value.
4. If questions arise (PHASE 2), answer them.
5. Observe the PLAN output: index file path, body file path, the new
   ID (= previous Last + 1), the draft summary block (limited fields),
   and the draft body file content showing the full schema —
   Description, Files to modify, Required reading, Conventions to
   follow, Out of scope, Tests, Definition of done (with Relevant
   snippets and Behavior change as applicable).
6. Confirm with "yes".
7. Observe the WRITE report: assigned task ID, both file paths,
   counter advanced.

## Expected

- Without `/task-setup` having been run, `/task-add` writes nothing
  and prints the setup-required message.
- After setup, no file is written until explicit approval.
- The summary block in `.claude/TASKS.md` contains only number,
  title, `Status: [MISSING]`, `Files:`, `Preconditions:` — no
  description, no behavior-change section, etc.
- The full body content lives in `.claude/tasks/<N>.md` and contains
  the required sections: `## Description`, `### Files to modify`,
  `### Required reading`, `### Conventions to follow`, `### Out of
  scope`, `### Tests`, `### Definition of done`. Optional sections
  (`### Relevant snippets`, `### Root cause`, `### Behavior change`,
  `### Doc updates`) appear when applicable.
- `### Files to modify` in the body matches the `Files:` field of the
  same task's summary block in TASKS.md verbatim (same comma-separated
  list, same order).
- `Status:` and `Preconditions:` are NOT duplicated in the body file.
- The `Last task number:` line in TASKS.md is incremented by 1.
- Adding two tasks in a row produces sequential IDs (e.g. 1 then 2).
- No git commit is made.

## Notes

- Test the "no questions" fast path with a very specific description.
- Test repeated invocation: each call increments the counter; IDs
  never collide.
- Verify silence is not treated as approval — agent must wait.
- **Aider sanity check (qualitative, manual).** After creating a real
  task, run:
  `aider --model ollama/qwen2.5-coder:14b \`
  `      --read .claude/external/implement-prompt.md \`
  `      --read .claude/tasks/<N>.md`
  Confirm the local model identifies the right files (those listed in
  Files to modify), opens the files cited in Required reading via
  `/add`, and proposes a plausible diff. Pass criterion is
  qualitative: model navigates to the right places and respects Out
  of scope. This is a sanity check, not a regression gate.
