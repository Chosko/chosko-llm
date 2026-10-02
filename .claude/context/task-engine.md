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
  Nine files under `references/`, one authority each:
  `resolution.md` (`.claude/TASKS.md` schema and parsing — appearance
  order is the backlog's order and need not be numeric, since
  `/task-add --before`/`--after` insert mid-file under the next id — the
  `all` / `next` / explicit-list selectors and the **eligibility clause**
  the batch two honour: implementable status AND every `Preconditions:` id
  `[DONE]`/`[SKIP]`, an id resolving to no task ignored; `all` is `next`
  repeated, resolved once up front by simulating the repetition so the run
  keeps one resolution report and one delegation count; implementable tasks
  left blocked, a precondition cycle included, named by id in the report;
  a task named by number never blocked; body-file location, the
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
  implement-anyway/stop protocol, reconciliation classification),
  `tree.md` (the dirty-tree prompt protocol, four options, `DIRTY_FOLD` /
  `DIRTY_FOLD_UNTRACKED` and the Step-7 fold), `commit.md` (pull-at-start,
  per-task commit and push, `--no-commit` / `--no-push` gating), and
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
  removal, `Feature:` added only to an orphan, one gate, a closed write set;
  read by NO `task-*` feature — only by whatever amends a single task, by path:
  `pipeline-revise`), and `parking.md` (task parking under the `unattended`
  policy: the ONE event that parks — a question
  the agent asked, nothing else; the prompts that take their default instead,
  each a *For the record* line; the trailing `## Parking handoff` — `Parked:`,
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
  refusals, `--unattended` beside `--no-commit` and on a non-git VCS). A
  consumer cites the file by a path **relative to the citing body** and
  states only its own deviations. Installed like any other skill (`cp -R`
  of the folder) — see `../domain/features/shared-phase-engine.md`. Its
  five consumers declare `requires: skill:task-engine`.

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
  [task-review-iterate.md](./task-review-iterate.md).

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
