# Commit and push gating

Authority for: the `--no-commit` / `--no-push` flags, pull-at-start, what
may be staged, how many commits a unit of work produces, and what happens
when a commit or a push fails.

Extracted verbatim from `/task-add`'s `ARGUMENT NOTE` and `PHASE 5 — COMMIT
AND PUSH`, `/task-clean`'s `ARGUMENT NOTE` and `PHASE 3 — COMMIT AND PUSH`,
and `/task-implement`'s `ARGUMENT PARSING`, `PRE-FLIGHT` step 5 and
`Step 7`.

> **A note on the protocol's name.** The consumers all defer to
> `docs/authoring-guide.md`'s commit-and-push protocol *by name*, and this
> file keeps that wording. It is a citation of where the protocol was
> authored, for a reader working on the `chosko-llm` repo — never an
> instruction to open that path at run time. `docs/` is authoring-time-only
> and is not installed, so the four numbered steps under **The push
> protocol** below stand on their own and nothing needs fetching.

---

## The flags

`--no-commit`: skip committing (and pushing) entirely; the changes stay
uncommitted in the working tree. `--commit` and `--no-commit` are mutually
exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.` NO_COMMIT true
implies NO_PUSH true — nothing is committed to push.

`--no-push`: only matters when NO_COMMIT is false. It skips the
pull-at-start / re-sync / push steps of the commit-and-push protocol
(docs/authoring-guide.md) while still committing as always.

Under `--no-commit`, report what was written or changed and remind the user
that nothing was committed — they should commit when ready. Do not run any
git command.

## Pull at start

Unless NO_COMMIT is true (nothing will be committed this run, so nothing to
push) or the project's CLAUDE.md carries a `## VCS` override (non-git — no
push step exists there either), run `git pull` on the current branch once,
right after the feature's own precondition/setup checks and before any of
its normal work begins. A conflict stops the run here — report the conflict
output and tell the user to resolve manually and re-run. This runs once per
invocation, not once per unit of work; each unit's own re-sync happens right
before its push.

## Staging

Stage ONLY the explicit paths this run wrote or changed, by path
(`git add -- <path> <path>`). Never use `git add -A`, `git add .`, or
`git add -u` — anything that could pull in unrelated dirty files from the
working tree.

Make no empty commit: if the run wrote nothing, commit nothing.

The one sanctioned use of `git add -u` is the dirty-tree fold, and only when
the user explicitly chose to include their pre-existing changes — see
`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/tree.md`.

## One commit per unit of work

A run makes exactly one commit per unit of work — one task added, one prune,
one task implemented — even when several units were requested in the same
invocation, and never bundles two units into one commit.

Do NOT use `--no-verify`, `--amend`, `--no-gpg-sign`, or skip any hooks
unless the user explicitly asked for it. If a pre-commit hook fails,
investigate and fix the underlying issue, then create a NEW commit (do
not amend). Never branch or tag.

## The push protocol

Every command that commits (whether by default or under `--commit`) also
pushes, once it has actually committed something, per
docs/authoring-guide.md's commit-and-push protocol:

1. **Pull at start**, as above.
2. Do the command's own work and commit exactly as already specified above.
3. **Pre-push re-sync.** Immediately before pushing, run `git pull` again —
   other commits may have landed upstream while the command was running. A
   clean fast-forward/merge: continue to push. A conflict: abort the merge,
   leave the local commit intact, do **not** push, and report that the
   commit exists locally but could not be synced — the user must resolve and
   push manually.
4. **Push.** `git push`. On failure (rejected, no upstream, no remote):
   report the exact output and stop. Never retry, never force-push.

On commit success, report the resulting commit hash to the user
(`git rev-parse --short HEAD`).

**Non-git VCS exemption.** When the project's CLAUDE.md defines a `## VCS`
section overriding git (e.g. Plastic SCM), skip the entire pull → re-sync →
push sequence unconditionally — only the commit (checkin) step runs.

## Failure

- **On commit failure** (e.g. a pre-commit hook rejects the commit):
  surface the exact failure output to the user. Do NOT retry, do NOT amend,
  do NOT use `--no-verify` or any hook-skipping flag. The files remain
  in whatever state git left them (typically staged but uncommitted);
  tell the user that and let them decide.
- **On push failure** (rejected, no upstream, no remote) or a pre-push
  conflict: surface the exact output. Never retry, never force-push. The
  commit exists locally; tell the user it needs a manual sync + push.

---

## Per-consumer notes

- **`/task-list`** — never commits and never shells out. It has neither
  flag: it is read-only by contract.
- **`/task-add`** — pulls at start inside `PHASE 0 — SETUP CHECK`; `PHASE 5`
  is "the only phase that shells out". Three commit-message forms, one
  commit each:
  - single task — `git add -- .claude/TASKS.md .claude/tasks/<N>.md` then
    `git commit -m "Add task <N>: <title>"`;
  - split — every file PHASE 4 wrote, ONE commit covering every task ID
    created, `git commit -m "Add tasks <N>-<N+k-1>: <short summary of the
    split>"`;
  - feature — additionally stage `.claude/FEATURES.md` plus the body file of
    every existing task the reconciliation rewrote,
    `git commit -m "Plan feature <slug>: tasks <N>-<M>"`. "The backlog
    change and the feature entry only make sense together, so they belong in
    one commit."
- **`/task-clean`** — pulls at start before PHASE 1; `PHASE 3` commits with
  `git commit -m "task-clean: remove tasks <N>[, <M>, …]"`, the pruned IDs in
  ascending order. It stages `.claude/TASKS.md` plus each deleted body file
  path — "Staging a deleted file via `git add -- path` works identically to
  staging a modified one" — and adds `.claude/FEATURES.md` only when a
  feature `Tasks:` line was rewritten. Apart from the `rm` of the body files
  in PHASE 2, PHASE 3 is its only shell use.
- **`/task-implement`** — pulls at start in `PRE-FLIGHT` step 5; `Step 7`
  commits and pushes once per task, "immediately after that task's commit,
  mirroring 'each task gets exactly one commit' with 'each task gets exactly
  one push.'" Never defer a task's push to end-of-run. Its message format
  "follows the repo's existing style — read the last few `git log` entries
  first", falling back to:

  ```
  Task <N>: <task title>

  <one-paragraph summary of what changed>
  ```

  In skip-tests mode it appends `(no tests — manual verification pending)`
  to the body. Staging is by explicit path including the `.claude/TASKS.md`
  status flip; the per-task body file "is typically NOT modified during
  implementation — do not include it in the commit unless you genuinely
  changed it". When DIRTY_FOLD is true it folds instead, per `tree.md`.
  Two departures from the one-commit rule are deliberate and are its own:
  - under `--review`, "the loop's fixes are already in the tree and are
    staged as part of this task's own commit, never as a second one", and
    `/task-iterate` commits nothing inside a round;
  - the `FEATURE COMPLETION` flip is "separate from, and in addition to, the
    per-task commits already made" — exactly ONE commit covering every flip
    approved in the run, `Mark feature(s) <slug>[, <slug> …] [DONE]`, pushed
    the same way.

  A `Step 7` push failure or pre-push conflict is distinct from any other
  failure: the commit already succeeded, so do not revert it or flip the
  status back — stop the run and report that the commit exists locally and
  needs a manual sync + push.
