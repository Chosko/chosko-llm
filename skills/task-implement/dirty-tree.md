# Dirty working tree — prompt protocol

Read this only when `git status --porcelain` returned a non-empty result,
either in PRE-FLIGHT CHECKS step 1 or in BETWEEN TASKS step 1.

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
  DIRTY_FOLD = false. Step 8 will stage only the task's own files,
  exactly as on a clean tree; these pre-existing changes stay in the
  working tree untouched by the task's commit.
- **On include** (default mode only): if the porcelain output
  included untracked files, list them and ask
  `Also fold untracked files into the task's commit? [y/N]`. On
  explicit yes, set DIRTY_FOLD_UNTRACKED = true and remember the
  untracked paths; on anything else, set DIRTY_FOLD_UNTRACKED = false.
  Set DIRTY_FOLD = true. Print a one-line warning: "Step 8 (Commit)
  will stage these pre-existing changes together with this task's own
  changes." Then continue — the fold happens in Step 8, not here.
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

DIRTY_FOLD (and DIRTY_FOLD_UNTRACKED) apply only to the Step 8 of the task
that immediately follows this check. When this runs in PRE-FLIGHT, that is
the first task of the run; later tasks in the same invocation are
unaffected and always fold nothing.

Notes:
- `.gitignore`-excluded files are ignored as today
  (`git status --porcelain` already respects gitignore).
- The commit option NEVER stages untracked files without explicit
  user opt-in, and NEVER uses `git add -A`/`-u .`/`.` in a way that
  would catch the user's untracked files implicitly.

## Folding in Step 8 (when DIRTY_FOLD is true)

Fold the pre-existing dirty changes into the task's commit alongside the
task's own changes:
1. Stage tracked files with `git add -u` — this covers both the task's
   own tracked edits and the pre-existing tracked dirty files in one step.
2. If DIRTY_FOLD_UNTRACKED is true, also stage the pre-existing untracked
   files identified during the prompt above, explicitly by path
   (`git add -- <path1> <path2> …`).
3. Stage any new untracked files this task itself created, explicitly by
   path.
