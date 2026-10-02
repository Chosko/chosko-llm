# Features: task-review and task-iterate

## Overview

Covers `/task-review` and `/task-iterate`, the review pair. The rest of the
suite: [task-suite.md](./task-suite.md).

- `skills/task-review/` — audits a diff against the acceptance criteria of
  the task that produced it and reports structured findings; on a
  documentation diff also an untraceable documentation edit (a decision the
  task never approved, `IMPORTANT` by default); report closes in the two
  groups For the record / Follow-ups (numbered, the reply handle). Exists beside
  Claude Code's built-in `/code-review` because of that one difference:
  generic review asks *is this good code*, this asks *does this satisfy task
  N's criteria*; where the two overlap it defers to the built-in rather than
  reimplementing it. Declares `requires: skill:task-engine` — the only
  consumer that reads the engine for a single file:
  `references/review-budget.md`, and only when the invocation carried a
  budget block. Three input forms resolved from the argument after
  stripping `task=<n>` and `base=<ref>`: empty → local (`git diff HEAD`), a
  branch name → branch (`git diff <base>...<branch>`, three dots), a bare
  integer or GitHub PR URL → pr (`gh pr diff <N>`). One supporting file,
  `remote-diffs.md`, read ON DEMAND — only when that remaining input is
  non-empty; a local run never opens it. Task resolved first-hit-wins from
  `task=<n>`, a number in the branch name, the PR title, then the most
  recently modified `.claude/tasks/*.md` (weakest signal, so the report says
  which and why); **no resolution stops the run** rather than degrading into
  a generic code review. Three gates before any finding is written:
  ≥80% confidence, the four-question Pre-Report Gate (exact line; concrete
  failure mode; callers/imports/tests read; severity defensible — any "no"
  or "unsure" demotes or drops), and BLOCKING-requires-proof (snippet,
  scenario, why existing guards miss it; missing one ⇒ demote).
  A spawn from `/task-implement --review` may carry a **budget block**
  naming a read tier (`shallow` / `standard` / `deep`), honoured off
  `review-budget.md`, which owns what a tier counts and what it reports.
  **No budget block
  means no budget** — a manual run and a spawn whose effort resolved to
  `same` both read unbounded, and a tier is never assumed unnamed. The
  budget caps reads, never admissibility: **no fourth gate is added**, and
  `shallow`'s ban on reading callers simply answers Pre-Report Gate question
  3 with "no", which the existing gate already demotes or drops — cheaper
  review, more conservative, never more confident-and-wrong. The skill has
  no cost-control flags of its own; the axes live on `/task-implement`.
  Separate contract clause, NOT a budget setting: **it invokes no test
  command** — any mode, any budget, any testing policy, either invocation
  path; a green suite is an input the caller hands it (spawn-prompt item 7),
  and under a skip-tests caller a criterion depending on runtime behaviour
  is `unverifiable` rather than re-derived. Reading test *files* as source
  is a different thing, governed by the budget table.
  **Zero findings is a valid, complete review** — stated explicitly, because
  a reviewer under implicit pressure to justify itself invents findings.
  Exactly three severities — `BLOCKING` (bugs, data loss, security, or an
  unmet acceptance criterion), `IMPORTANT`, `ADVISORY` (reported once, never
  re-reviewed); an unmet criterion is ALWAYS blocking. Findings carry stable
  `R<round>-<n>` ids, never renumbered, since that is how a rejection stays
  rejected across rounds; the report also carries a per-criterion verdict
  (`met` / `not met` / `unverifiable`) and one overall line, and the two
  halves must agree. Output destination branches on invocation: spawned by
  `/task-implement --review` → structured return through the channel the
  run's rules name, nothing else on disk — the result file for a relay child
  under `/runbook-run`'s RELAY CHILD RULES, the reply otherwise; invoked
  manually → asks once whether to also write
  `.claude/reviews/<task>-R<round>.md`, chat-only being the default on
  silence or EOF. No `--rounds` flag — the loop belongs to
  `/task-implement`. Read-only contract: its only writes are that opted-into
  review file or a spawned run's named result file; no edit to any source/
  test/task/status/feature file, no `git add`/`commit`/`checkout`/`stash`/`push`, no
  `gh` write, no PR opened, and no subagents of its own (one reviewer, one
  pass — a dimension-reviewer fan-out is the token cost this repo exists to
  avoid).
- `skills/task-iterate/` — triages findings it did NOT produce, applies what
  survives, records why the rest did not. Same three input forms and same
  `task=` / `base=` parsing as `/task-review`, plus `--no-commit` /
  `--no-push`; fixes always land in the working tree in front of it (branch
  mode assumes that branch is checked out and stops rather than switching).
  **No supporting files** — everything including PR mode is in `SKILL.md`,
  and it never reads a file from another skill's folder, since each skill
  installs as a self-contained folder. Findings come from exactly ONE of
  three sources, in order: passed in by the caller (the `--review` path),
  a `.claude/reviews/<task>-R<n>.md` file (highest round; ambiguity asks),
  or PR review comments via `gh` (one thread = one finding; already-resolved
  threads are prior context, not findings). **Never invents a finding**, not
  as a bonus or an "also noticed" — a skill that both finds and fixes grades
  its own work. Triage is mandatory and explicit: every finding gets exactly
  one of `fix`, `defer` (needs a follow-up task number or a one-line note of
  what the task would be) or `reject` (needs an arguable one-line reason),
  and **the whole verdict table is written out before the first edit** —
  triage decided while editing is triage rationalised by the edit. A
  BLOCKING finding naming an unmet acceptance criterion cannot be deferred;
  a finding arguing against the task body's Decisions is a `reject` with the
  decision as the reason. A `fix` discovered to be wrong once in the file
  flips to `reject` with what was found, reported as a changed verdict. In
  PR mode it replies on each thread and resolves the `fix`ed and `defer`red
  ones while **leaving rejected threads open** for the human. Committing is
  **caller-dependent and the caller asserts the mode, never inferred**:
  standalone it follows the repo's pull/commit/re-sync/push protocol; inside
  a `/task-implement --review` round it commits and pushes nothing, leaving
  the tree for that run's Step 7 so the task keeps exactly one commit. That
  asymmetry is load-bearing and flagged as such in the body against a future
  editor "fixing" it. Returns three things: the triage summary, the sticky
  rejection ledger for the next round, and an explicit yes/no on unresolved
  `BLOCKING` findings — the field `/task-implement`'s loop reads to decide
  whether another round is warranted. Never opens a pull request, in any
  mode.

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
- [task-implement-review.md](./task-implement-review.md) — the
  `--review` rounds that spawn `/task-review` and run `/task-iterate`.
- [task-engine.md](./task-engine.md) — `references/review-budget.md`.

## When to read the source

- [task-suite.md](./task-suite.md) § When to read the source.
