# Smoke test: chosko-llm task-impl

**Type:** cli subcommand
**Source:** scripts/cmd-task-impl.sh, scripts/lib-task-external.sh, bin/chosko-llm

The orchestrator drives aider against the project's task backlog,
running the same 8-step sequence as `/task-implement` but for an
external LLM (qwen2.5-coder:14b via Ollama). Each scenario assumes
`aider` is on PATH and Ollama is reachable; if not, scenarios
involving aider invocations should fail loudly with a clear message.

## Setup

- A clean git working tree.
- A project that has been initialized via `/task-setup` — i.e. has all
  four artifacts under `.claude/external/`: `implement-prompt.md`,
  `tests-prompt.md`, `run-affected-tests.sh`, `run-full-tests.sh`.
- One or more tasks in `.claude/TASKS.md` with status `[MISSING]` and
  matching body files under `.claude/tasks/<N>.md`.
- The orchestrator accepts three optional CLI flags — `--model`,
  `--retries`, `--map-tokens` — that override their respective env vars
  (`CHOSKO_TASK_IMPL_MODEL`, `CHOSKO_TASK_IMPL_RETRIES`,
  `CHOSKO_TASK_IMPL_AIDER_MAP_TOKENS`). Flags may appear at any
  position relative to positional task numbers.
- When neither `--map-tokens` nor `CHOSKO_TASK_IMPL_AIDER_MAP_TOKENS`
  is set, the `--map-tokens` flag is omitted entirely from the aider
  invocation (aider falls back to its own default).

## Scenarios

### 1. Happy path (single task, real wrappers)

1. Pick a `[MISSING]` task whose Files: list includes at least one
   real test file.
2. Run `chosko-llm task-impl <N>`.
3. Observe: status flips to `[IN PROGRESS]`, aider is invoked with
   `tests-prompt.md`, affected tests are run and observed to fail,
   aider is invoked with `implement-prompt.md`, affected tests pass,
   full suite passes, status flips to `[DONE]`.
4. Inspect `git log -1` — exactly one new commit, message
   `Task <N>: <title>`, files staged include `.claude/TASKS.md` plus
   everything in the task's Files: list.
5. Inspect aider's stdout / banner output for both invocations
   (tests pass and impl pass). Verify the `--message` string passed
   in each case ends with the literal line `Respond in English.`.

**Expected:** working tree is clean after the run. No
"(no tests …)" parenthetical in the commit body.

### 2. Multi-task and `all`

1. Have at least 3 implementable tasks in the backlog.
2. Run `chosko-llm task-impl all`.
3. Observe a one-line "Will implement (in order): …" summary, then
   per-task execution. After each task, `git status` is clean before
   the next starts.

**Expected:** N commits, one per task, in the order printed in the
summary line. `[DONE]` and `[SKIP]` and `[IN PROGRESS]` tasks are
silently skipped.

### 3. Retry path (impl pass)

1. Tamper with a task body to introduce a constraint the model is
   likely to miss on the first try (e.g. a renamed function the body
   spec demands).
2. Run with `CHOSKO_TASK_IMPL_RETRIES=2 chosko-llm task-impl <N>`.
3. Observe up to two impl-pass aider invocations, each fed the
   previous failure log via `--message`. If the second still fails,
   the run halts with status left as `[IN PROGRESS]` and no commit
   made.

**Expected:** on halt, `git status` shows the impl pass's
in-flight edits as uncommitted changes; the user is told status is
left as `[IN PROGRESS]` and the run was halted.

### 4. Skip-tests path (stub wrappers)

1. Initialize a project via `/task-setup` choosing option B
   (no-test-suite, write stubs).
2. Confirm both wrappers carry `# CHOSKO_TASK_IMPL_STUB`.
3. Add a `[MISSING]` task and run `chosko-llm task-impl <N>`.
4. Observe a "skip-tests mode" warning at startup, then a per-task
   confirmation prompt ("About to implement task N — <title>.
   Proceed? [y/N]"). Answer `y`.
5. Observe: aider is invoked once (impl pass only), no test runs,
   status flips to `[DONE]`, single commit is created.
6. `git show -1 --format=%B` includes
   `(no tests — manual verification pending)`.

### 5. Dirty-tree refusal

1. Modify any file in the working tree (don't stage).
2. Run `chosko-llm task-impl <N>`.
3. Observe: `[error] Working tree is dirty.` exit non-zero, no
   status flip, no aider invocation.

### 6. Missing-artifacts refusal

1. Delete `.claude/external/run-full-tests.sh`.
2. Run `chosko-llm task-impl <N>`.
3. Observe: clear error naming the missing file and pointing the user
   at `/task-setup`. Exit non-zero. No status flip.

Repeat with each of the four required artifacts.

### 7. Bad task number

1. Run `chosko-llm task-impl 9999` against a backlog without that
   task.
2. Observe a clear error naming the missing task. Exit non-zero. No
   status flip on any other task.

### 8. Already-DONE task requested by number

1. Run `chosko-llm task-impl <N>` where task N is already `[DONE]`.
2. Observe: a warning is logged and the task is skipped (no aider
   invocation, no commit). The `all` form silently skips DONE tasks.

### 9. CLI flag overrides

1. `chosko-llm task-impl --model ollama/some-other:7b <N>` — aider's
   banner shows the overriding model name (`some-other:7b`).
2. `CHOSKO_TASK_IMPL_MODEL=ollama/env-pick chosko-llm task-impl --model ollama/flag-pick <N>` —
   flag wins; banner shows `flag-pick`.
3. `chosko-llm task-impl --retries=1 <N>` against a body crafted to
   fail twice — observe exactly one impl-pass aider invocation, then
   a halt with status left as `[IN PROGRESS]`.
4. `chosko-llm task-impl --map-tokens 4096 <N>` — aider's invocation
   log includes `--map-tokens 4096`.
5. `CHOSKO_TASK_IMPL_AIDER_MAP_TOKENS=8192 chosko-llm task-impl <N>` —
   aider's invocation log includes `--map-tokens 8192`.
6. `chosko-llm task-impl <N>` with neither flag nor env var — aider's
   invocation log does **not** contain `--map-tokens`.
7. `chosko-llm task-impl --retries abc <N>` — fails fast with a clear
   error naming `--retries`; exit non-zero; no aider invocation, no
   status flip.
8. `chosko-llm task-impl --bogus <N>` — fails fast with "Unknown flag"
   error; exit non-zero; no status flip.
9. Interleaved form: `chosko-llm task-impl 3 --retries 2 4` — both
   tasks 3 and 4 are queued, retry budget for both is 2.

## Expected (cross-cutting)

- Working tree is clean after every successful task and every refusal.
- One commit per task. Never two tasks in one commit.
- `aider` is never invoked with `--auto-commits` enabled —
  the orchestrator owns the commit step.
- All errors that halt the run leave the in-flight task's status as
  `[IN PROGRESS]` (so the user can see where it stopped) and stop
  before starting subsequent tasks.
