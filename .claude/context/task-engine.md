# Features: task engine

## Overview

Covers `task-engine`, the non-invocable reference library the `task-*`
suite reads. The rest of the suite: [task-suite.md](./task-suite.md).

- `skills/task-engine/` — reference library the `task-*` suite reads;
  **not user-invocable**, takes no arguments, runs nothing, produces no
  output. Exists because a rule stated in four bodies is four things to
  update and three chances to forget. `SKILL.md` is a MAP, not a rule
  holder — it says which reference file owns what and repeats the
  not-invocable statement, as a two-line "read by path; not invoked" `#`
  header, for an agent that opened the file without reading frontmatter;
  that frontmatter carries `disable-model-invocation: true` ([feature-contract.md](./feature-contract.md) § Public API).
  Nineteen files under `references/`, one authority each:
  `resolution.md` (`.claude/TASKS.md` schema and parsing — appearance
  order is the backlog's order and need not be numeric, since
  `/task-add --before`/`--after` insert mid-file under the next id — the
  `all` / `next` / explicit-list selectors and the **eligibility clause**
  the batch two honour: implementable status AND every `Preconditions:` id
  `[DONE]`/`[SKIP]`, an id resolving to no task ignored; `all` is `next`
  repeated, resolved once up front by simulating the repetition so the run
  keeps one resolution report and one delegation count; implementable tasks
  left blocked, a precondition cycle included, named by id in the report;
  a task named by number never blocked (a parallel run's in-flight reading
  is `worktree.md`'s, not this file's); body-file location, the
  `/task-setup`-has-run gate, and § *The archive* —
  `.claude/tasks/archive/<N>.md`, the frozen-header form, and the
  archived-and-terminal rule every id reader cites: an id referenced but
  absent from `TASKS.md` is archived, and nothing probes the folder or opens
  an archived file unless the user names a task and asks; a `[PARKED]` task
  eligible for `all` / `next` exactly when an answerer exists, and the
  `## Parking handoff` named as the one body section `/task-implement`
  writes), `status.md` (the nine-value status
  vocabulary — `[PARKED]` the ninth: non-terminal, written and unparked
  only by `/task-implement`, `[IN PROGRESS]` →
  `[PARKED]` → `[IN PROGRESS]` its transitions, `[PARKED]` → `[SKIP]`
  reconciliation's — which statuses are terminal, which implementable, legal
  transitions), `targets.md` (`Target:` values, the `## Manual
  interventions` pairing rule, the delegation guard, per-consumer notes),
  `stale.md` (`[STALE]` detection, who writes and clears it, the
  implement-anyway/stop protocol in a plain-language prompt, reconciliation
  classification),
  `tree.md` (the dirty-tree prompt protocol, four options, `DIRTY_FOLD` /
  `DIRTY_FOLD_UNTRACKED` and the Step-7 fold; `/quick-implement` runs it once,
  before its spec conversation), `commit.md` (pull-at-start,
  per-task commit and push, `--no-commit` / `--no-push` gating; never
  branch, tag or rebase, the exceptions /task-implement's parking branch
  (`parking.md`) and a parallel run's worktree branch (`worktree.md`) — the
  one always-read mention of the worktree protocol),
  `design-change.md` (the design-change check: the
  owner table of paths another pipeline command owns, *settles* vs *diverges*,
  the question, agreement and disagreement, the hard rules — `/task-add`,
  `amend.md`, `routing.md` and `/quick-implement`'s drift check cite it),
  `reconciliation.md` (applying reconciliation: classify every task the
  feature generated per `stale.md`, a one-line reason each, apply the approved
  plan and nothing beyond it), `orphan-question.md` (offering a free-form task
  to a `[PLANNED]` feature; `/task-add`'s `--single` path in its note),
  `testing-policy.md` (the
  `Testing policy for /task-implement:` marker, wording unchanged, its three
  values and the runner resolution — marker, project convention, inference,
  no-test-suite branch — plus which tests count as affected; this skill's
  frontmatter carries the marker's `project-policy: line:` declaration),
  `test-runner.md` (the runner-inference heuristics, mirrored in
  `/task-setup`'s TEST RUNNER INFERENCE), `no-test-suite.md` (the
  scaffold-or-skip question and skip-tests mode), `tests-first.md` (Steps 2–5:
  update tests, implement within the declared files, run the affected tests,
  run the full suite — step labels kept so citations of "Step 3" still land),
  `closing-report.md` (the two-group closing report, *For the record* and
  one numbered *Follow-ups* list, the numbering as the reply handle;
  `/task-implement`'s items, review-pair line and `P<n>` handles in its
  note), and
  `review-budget.md` (review cost controls: the `--review-model` /
  `--review-effort` values, their `same` / `auto` reserved words, the
  deterministic three-row `auto` tier table keyed on lines/files/criteria
  and whether the diff touches a non-`.md` file, the read budget behind the
  effort axis — navigation layer full and uncounted at every tier, only
  distinct source/test files beyond the diff counted, `shallow` at zero —
  the no-test-command-at-any-tier clause, and the cap-bound and
  resolved-pair reports), and `amend.md` (changing one existing task in
  place: two checks before writing — not `[IN PROGRESS]`, and no change to
  what its feature promises, else route to `/architect amend` — which body
  sections and summary-block fields may change, a dropped `Preconditions:`
  edge named in `## Decisions`, deleting a live task as `[SKIP]` never by
  removal, `Feature:` added only to an orphan, one `confirmation` gate
  showing a plain summary (`show` prints the draft; an owned-document
  question still waits), a closed write set, an "Amended …" line
  plain-language-first;
  read by NO `task-*` feature — only by whatever amends a single task, by path:
  `pipeline-revise`), and `parking.md` (task parking under the `unattended`
  policy: the ONE event that parks — a question
  the agent asked, nothing else; the prompts that take their default instead,
  each a *For the record* line — the feature-flip proposal and skip-tests
  `Proceed?` among them as `confirmation` gates that pass on their own;
  parked-question lines plain-language-first; the trailing `## Parking handoff` — `Parked:`,
  `Parking Branch:`, `Question:` verbatim and multi-line, `Answer:` only after
  a failed unpark; the `park/task-<N>` branch holding the work-in-progress in
  one commit, minus `TASKS.md` and the body, pushed unless `--no-push`, never
  overwritten; the park sequence — first deleting a leftover `park/task-<N>`
  (the task's own unpark branch, met by a resumed task asking again), local
  and remote, a failed delete failing the park as a Step 7 failure — ending
  in a bookkeeping commit that leaves the base tree clean; the transactional unpark — ask first, gates
  cherry-pick first, cherry-pick without committing, resume at the step
  named, rollback on conflict, then delete the branch as the task's last act
  — after its Step 7 commit and push, best-effort, a failed delete a
  Follow-ups item (a delegated agent's fifth field) and never a halt, the
  branch kept under `--no-commit`; the answerer rule; the two
  refusals, `--unattended` beside `--no-commit` and on a non-git VCS, for a
  flag or handed-down policy only, never the `CLAUDE.md` line), and
  `worktree.md` (worktree isolation for a unit of work — `task-<N>` or
  `runbook-<id>-step-<n>`, named by its orchestrator: the derived
  `.claude/worktrees/<unit>` path and `wt/<unit>` branch, never recorded,
  git's worktree list the registry; `git worktree add -b` from the base tip
  right before the spawn, `.claude/worktrees/` added to `.git/info/exclude`
  once; the agent's five integration steps — commit on `wt/<unit>`, rebase
  onto the base tip, resolve a conflict by re-applying its own intent,
  re-verify when the base moved, return naming the tip — never pushing the
  base, its own `park/task-<N>` the one branch it pushes (`parking.md`), the
  base's pull/re-sync/push skipped as under `--no-push`; the orchestrator's landing
  — `git merge --ff-only`, one re-rebase round through the same agent when
  the tip moved, push per `commit.md`, `git worktree remove` + `git branch
  -d` whose refusal fails the unit; the two invariants, one writer and, at
  every landing, no change in the base tree to a file the unit touched (a
  runbook body and index the orchestrator keeps dirty may stay); a worktree
  as the in-flight signal every reader consults and the skip-while-present
  rule; § *Eligibility while a unit is in flight* — neither done nor
  eligible, a unit whose `Preconditions:` / `Depends on:` name it blocked
  until it lands, the in-flight set the orchestrator's run memory, nothing
  in an index; failure keeping the worktree; § *Parking inside a worktree*,
  the one home of that reading. Read only through `/task-implement`'s
  `parallel-runs.md` and `/runbook-run`'s `references/parallel.md`, when a
  run's parallelism is above one; authored in the engine like `amend.md`
  and `parking.md`), and `worktree-sweep.md` (the single authority for the
  worktree sweep: runs only when `.claude/worktrees/` exists — one Glob, no
  shell — and never on a `## VCS` project; lists `git worktree list
  --porcelain` entries and `wt/<prefix>*` branches of the consumer's units;
  finished per consumer — `/task-clean`: task `[DONE]`/`[SKIP]` or archived;
  `/runbook-clean`: runbook resolved for removal or step `[x]`, a vanished
  runbook or step left in place and reported; a `Worktrees to remove (W):`
  plan section that keeps "nothing to prune" from firing; removal after the
  one "Apply?", `git worktree remove` + safe `git branch -d`, a failure a
  Follow-ups item; local throughout, runs whole under `--no-commit` /
  `--no-push`, adds nothing to a commit. Read by `/task-clean` and
  `/runbook-clean` only when `.claude/worktrees/` exists, never with
  `worktree.md`).
  The reference files cite [interaction-engine.md](./interaction-engine.md)'s
  files, but the engine itself takes no `requires:` — its consumers carry
  it. A
  consumer cites the file by a path **relative to the citing body** and
  states only its own deviations. Installed like any other skill (`cp -R`
  of the folder) — see `../domain/features/shared-phase-engine.md`. Its
  consumers — the five `task-*` readers, `/quick-implement` and
  `/runbook-run`, the last for `worktree.md` alone — declare
  `requires: skill:task-engine`; `/runbook-clean` reads `worktree-sweep.md`
  through its `requires: skill:runbook-run`.

## Public API

- Each feature's contract is its text in § Overview. Frontmatter,
  `description` contract and loading-control keys:
  [task-suite.md](./task-suite.md) § Public API.

## Internal patterns

- [task-suite.md](./task-suite.md) § Internal patterns.

## Domain dependencies

- [task-suite.md](./task-suite.md) § Domain dependencies.

## Cross-references

- [task-suite.md](./task-suite.md) — the task-suite hub and its file list.
- Consumers: [task-add.md](./task-add.md), [task-backlog.md](./task-backlog.md),
  [task-implement.md](./task-implement.md),
  [task-review-iterate.md](./task-review-iterate.md),
  [quick-implement.md](./quick-implement.md),
  [runbook-run.md](./runbook-run.md) (`worktree.md` only),
  [runbook-pruners.md](./runbook-pruners.md) (`worktree-sweep.md` only).
- Readers of the in-flight signal: [claude-md-hook-statusline.md](./claude-md-hook-statusline.md)
  (`pipeline-statusline`), [pipeline-dashboard.md](./pipeline-dashboard.md);
  the sweeps of `worktree-sweep.md`: [task-backlog.md](./task-backlog.md)
  (`task-clean`), [runbook-pruners.md](./runbook-pruners.md) (`runbook-clean`).

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
