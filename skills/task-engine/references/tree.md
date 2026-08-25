# The dirty-tree protocol

Authority for: what a feature does when `git status --porcelain` is
non-empty before it starts work, and how the answer is carried into that
run's commit.

Extracted verbatim from `/task-implement`'s supporting file
`dirty-tree.md`. Its step labels (`Step 7`, `PRE-FLIGHT CHECKS step 1`,
`BETWEEN TASKS step 1`) are that skill's own and are kept as they stood;
a feature adopting this protocol substitutes its own commit step.

---

## The check

Run `git status --porcelain` once, before any work begins.

- If output is empty (clean tree — the common path), continue silently.
  Set DIRTY_FOLD = false.
- If non-empty, follow the prompt protocol below before going further. It
  sets DIRTY_FOLD and DIRTY_FOLD_UNTRACKED, which the commit step consumes,
  and may halt the run.

## The prompt

List the dirty files to the user (truncated to the first 20 entries with a
`(+N more)` tail when there are more) and prompt. The default (NO_COMMIT
false) shows all four options; under `--no-commit` there is no task commit
for option 2 to fold into, so it is dropped and the remaining three are
renumbered 1/2/3:

Default (committing) mode:
```
Working tree has uncommitted changes. Choose:
  [1] proceed   — run the task anyway; these changes stay uncommitted, exactly as they are now
  [2] include   — run the task anyway; these changes will be staged and folded into the task's commit
  [3] commit    — commit the current changes first, then run the task
  [4] abort     — stop now, leave everything as-is
```

`--no-commit` mode:
```
Working tree has uncommitted changes. Choose:
  [1] proceed   — run the task anyway; these changes stay uncommitted, exactly as they are now
  [2] commit    — commit the current changes first, then run the task
  [3] abort     — stop now, leave everything as-is
```

Wait for an explicit typed answer. In default mode accept `1`/`proceed`,
`2`/`include`, `3`/`commit`, or `4`/`abort` (case-insensitive). Under
`--no-commit` accept `1`/`proceed`, `2`/`commit`, or `3`/`abort`. EOF, an
empty line, an unrelated reply, or silence is treated as **abort**.

- **On proceed:** continue silently — no warning needed. Set
  DIRTY_FOLD = false. Step 7 will stage only the task's own files,
  exactly as on a clean tree; these pre-existing changes stay in the
  working tree untouched by the task's commit.
- **On include** (default mode only): if the porcelain output
  included untracked files, list them and ask
  `Also fold untracked files into the task's commit? [y/N]`. On
  explicit yes, set DIRTY_FOLD_UNTRACKED = true and remember the
  untracked paths; on anything else, set DIRTY_FOLD_UNTRACKED = false.
  Set DIRTY_FOLD = true. Print a one-line warning: "Step 7 (Commit)
  will stage these pre-existing changes together with this task's own
  changes." Then continue — the fold happens in Step 7, not here.
- **On commit:** ask `Commit message?` and read the answer.
  Accept either a single line or a multi-line answer terminated by
  an empty line. Then:
    1. Stage tracked dirty files: `git add -u`.
    2. If the porcelain output included untracked files, list them
       and ask `Also include untracked? [y/N]`. On explicit yes,
       stage them by listing each path explicitly
       (`git add -- <path1> <path2> …`); on anything else, leave
       them unstaged.
    3. Create one commit using the user's message via HEREDOC
       (`git commit -m "$(cat <<'EOF'\n…\nEOF\n)"`).
    4. If the commit fails (e.g. pre-commit hook), surface the
       failure to the user, do NOT retry, do NOT use `--no-verify`,
       do NOT amend, and halt the run before any task work begins.
    5. On success, continue to step 2 of the pre-flight checks. Set
       DIRTY_FOLD = false.
- **On abort / silence / EOF:** stop. Do not flip any `Status:`
  line, do not stage, do not commit. The user is left exactly where
  they started.

DIRTY_FOLD (and DIRTY_FOLD_UNTRACKED) apply only to the Step 7 of the task
that immediately follows this check. When this runs in PRE-FLIGHT, that is
the first task of the run; later tasks in the same invocation are
unaffected and always fold nothing.

Notes:
- `.gitignore`-excluded files are ignored as today
  (`git status --porcelain` already respects gitignore).
- The commit option NEVER stages untracked files without explicit
  user opt-in, and NEVER uses `git add -A`/`-u .`/`.` in a way that
  would catch the user's untracked files implicitly.

## Folding in Step 7 (when DIRTY_FOLD is true)

Fold the pre-existing dirty changes into the task's commit alongside the
task's own changes:
1. Stage tracked files with `git add -u` — this covers both the task's
   own tracked edits and the pre-existing tracked dirty files in one step.
2. If DIRTY_FOLD_UNTRACKED is true, also stage the pre-existing untracked
   files identified during the prompt above, explicitly by path
   (`git add -- <path1> <path2> …`).
3. Stage any new untracked files this task itself created, explicitly by
   path.

---

## Per-consumer notes

- **`/task-implement`** — the only consumer today, and the source of every
  word above. It runs the check twice: once in `PRE-FLIGHT CHECKS step 1`
  before the first task, and again in `BETWEEN TASKS step 1` after each
  commit, where a non-empty result is "unusual — the previous task's Step 7
  should have committed everything it changed". Under `--no-commit` the
  between-tasks check is skipped entirely: "the previous task's changes are
  deliberately left uncommitted and will accumulate, so a non-empty
  `git status` is expected, not a surprise." On a delegated run, an agent is
  told the dirty-tree decision the parent already made and must not re-run
  this prompt protocol.
- **`/task-add`, `/task-list`, `/task-clean`** — no dirty-tree check. They
  stage only the explicit paths they wrote (`/task-list` writes nothing at
  all), so a dirty tree cannot reach their commits — see
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md`.
