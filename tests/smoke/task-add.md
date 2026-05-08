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
8. Observe the PHASE 5 prompt: `Task <N> written. Commit
   .claude/TASKS.md + .claude/tasks/<N>.md now? [y/N]`.

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
- No git commit is made unless the user explicitly answers `y` (or
  equivalent) at the PHASE 5 prompt.

## PHASE 5 (commit) scenarios

### Commit-yes path

1. Run `/task-add` end-to-end on a clean working tree.
2. Approve the draft (PHASE 3) and let PHASE 4 write the two files.
3. At the PHASE 5 prompt, answer `y`.
4. Verify a single new commit exists with message `Add task <N>: <title>`.
5. Run `git show --stat HEAD` and verify it lists exactly two files —
   `.claude/TASKS.md` and `.claude/tasks/<N>.md` — and nothing else.
6. Verify `git status` is clean.

### Commit-no path

1. Run `/task-add` end-to-end on a clean working tree.
2. At the PHASE 5 prompt, answer `n` (or just press enter).
3. Verify the two files are written but unstaged: `git status` shows
   `.claude/TASKS.md` modified and `.claude/tasks/<N>.md` untracked.
4. No new commit appears in `git log`.
5. The agent reports `Skipped commit. Files left unstaged.`

### Dirty-tree safety

1. Pre-create an unrelated modified file in the working tree (e.g.
   `echo "junk" >> README.md`). Do NOT stage it.
2. Run `/task-add` end-to-end and answer `y` at PHASE 5.
3. Verify the new commit lists ONLY `.claude/TASKS.md` and
   `.claude/tasks/<N>.md` — the dirty `README.md` change is still in
   the working tree, unstaged, untouched.

### Pre-commit hook failure

1. Install a pre-commit hook that always exits non-zero (e.g. a
   `.git/hooks/pre-commit` that runs `exit 1`).
2. Run `/task-add` end-to-end and answer `y` at PHASE 5.
3. Verify the commit fails. The agent surfaces the hook output.
4. Verify the agent does NOT retry, does NOT use `--no-verify`, and
   does NOT amend any prior commit.
5. Verify the two files remain on disk (whatever git left them in is
   acceptable: typically still staged); the user is told that and
   left to fix the hook.

## Notes

- Test the "no questions" fast path with a very specific description.
- Test repeated invocation: each call increments the counter; IDs
  never collide.
- Verify silence is not treated as approval — agent must wait.
- Verify silence at the PHASE 5 prompt is treated as `n` (no commit).
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
