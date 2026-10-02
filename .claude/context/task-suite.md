# Features: task suite

## Overview

Covers the backlog's shipped artifacts: the `task-*` commands and skills and
the `task-engine` reference library they read. Feature kinds and the
frontmatter contract every one of them follows: [features.md](./features.md).

- `commands/task-setup.md` — initializes backlog: `.claude/TASKS.md`
  stub, `.claude/tasks/` directory, and the project's **test-dispatch
  convention** — `.claude/external/run-affected-tests.sh` +
  `run-full-tests.sh`, thin wrappers inferred from project files giving
  one stable pair of entry points for the affected and full suites.
  Nothing in the `task-*` suite invokes them; `/task-implement`
  resolves its own test command and never reads them. No-test-suite
  projects get no-op stubs carrying the `# CHOSKO_TASK_IMPL_STUB`
  sentinel, which is what marks a wrapper as a stub on a re-run.
  Required before `/task-add`. Idempotent — re-runs only fill missing
  artifacts, never overwrite a non-stub wrapper. **Authoring command —
  leaves scaffolding uncommitted for user review by default;
  `--commit` opts in to committing exactly paths run wrote.**
- `skills/task-engine/` — reference library the `task-*` suite reads;
  **not user-invocable**, takes no arguments, runs nothing, produces no
  output. Exists because a rule stated in four bodies is four things to
  update and three chances to forget. `SKILL.md` is a MAP, not a rule
  holder — it says which reference file owns what and repeats the
  not-invocable statement, as a two-line "read by path; not invoked" `#`
  header, for an agent that opened the file without reading frontmatter;
  that frontmatter carries `disable-model-invocation: true` ([features.md](./features.md) § Public API).
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
- `commands/task-add.md` — plans and writes new task conversationally:
  writes summary block to `.claude/TASKS.md` and thin body file at
  `.claude/tasks/<N>.md`. **Placement**: new blocks append at the end by
  default; `--before <N>` writes above task N's block and appends the new
  id to N's `Preconditions:` (the one sanctioned edit to another task's
  line), `--after <N>` writes below it and puts N on the new task's
  `Preconditions:` — position and edge ALWAYS together (position for the
  reader, edge for `next`/`all`), flags mutually exclusive, unknown N
  stops, next id from the counter exactly as an append, no existing id
  moves; with several new tasks the flag places the first and the rest
  follow it. **`feature=<slug> --single`**: exactly one task attached to a
  `[PLANNED]` feature (any other status stops) — `Feature:` line plus the
  id appended to `Tasks:`, but NO reconciliation, `Status:` untouched, no
  documentation task, no split; mutually exclusive with `--short`; the
  report ends with a fixed write-back line naming
  `/pipeline-revise feature=<slug>`; commits under the single-task/split
  message plus `FEATURES.md` (`commit.md`'s fourth, "attached" form, never
  `Plan feature`). **Orphan question**: a free-form run (not `--short`) on a
  project with `.claude/FEATURES.md` asks inside PHASE 3's existing gate
  whether the task belongs to a `[PLANNED]` feature, none the default; a
  slug takes the `--single` path. No `FEATURES.md` → nothing asked.
  **Approval digest**: PHASE 3 renders per task only the `## <N>. <Title>`
  heading, `Target:`, `## Goal`, `## Decisions` when present and
  `## Manual interventions` in full when the target is `claude+human` /
  `human` — plus one `Order:` line on a split and the `Placement:` line
  under `--before` / `--after`, the only wiring the gate shows. The summary
  block's fields, the acceptance criteria and the Hints are authored in full
  and written by PHASE 4, whose report names the IDs, both paths and the
  counter advance. Default body schema (target: claude) contains
  Goal, Acceptance criteria, Decisions (when applicable), Hints.
  When work includes steps
  only human can perform in external tool (e.g. Unity editor),
  sets `Target: claude+human` (or `human`) and authors
  `## Manual interventions` checkpoint section — the pairing rule is
  `targets.md`'s. Refuses if `/task-setup` not run. May propose splitting
  description into multiple tasks (independent deliverables, or one
  task too large); on acceptance writes every part with sequential
  IDs and auto-wired `Preconditions:` in one run. `--no-split` always
  writes exactly one task. Auto-commits written files (all parts in
  one commit for split); `--no-commit` leaves uncommitted.
  With `feature=<slug>` plans from `/architect` feature document
  instead of prose description (stage 5 of pipeline): resolves slug
  through `.claude/FEATURES.md`, reads `Doc:` path as primary context
  source, inverts split check (design unit usually several
  implementation units), tags every new summary block `Feature: <slug>`,
  sets entry's `Tasks:` and `Status: [PLANNED]` — never `Doc:` or
  `Source:`. On feature already with tasks RECONCILES under same
  single approval gate: leave-untouched / update-body-in-place (preferred; a
  `[STALE]` task flips back to `[MISSING]`) / `[SKIP]`-and-replace, with
  `[DONE]` never touched. When run drafts at least one new task, it
  appends one final documentation-update task (`Target: claude`,
  `Preconditions:` listing run's other new task IDs) whose Hints point at
  affected README.md / authoring-guide.md / domain / context-layer docs;
  skipped on reconciliation-only run. Owned documents MAY appear in any
  drafted task's Hints or `Files:` — doc task, free-form, split part,
  reconciled body alike — but never silently and never un-adjudicated:
  detection off command's own four-row owner list
  (`domain/features/*.md` → `/architect`; `product-design.md` /
  `technical-direction.md` / `business-model.md` → `/product-design`;
  `product-roadmap.md` → `/product-roadmap`; `PLAN.md` →
  `/production-plan`; `FEATURES.md` / `TASKS.md` excluded), specific
  points enumerated per file as *settles* (document leaves it open) or
  *diverges* (design change). DESIGN-CHANGE CHECK asks one question per
  task inside PHASE 3's single gate, only when a point diverges — before →
  after, agree? — settling points listed for the record. Agreement covers
  the whole design change (every passage stating the old design), recorded
  as an acceptance criterion plus a dated Decisions bullet, path joins
  `Files:`; disagreement returns to PHASE 2 questions. No read-only marker,
  no drop answer. Silence is not agreement; PHASE 4 refuses a task with an
  unanswered diverging point. A rewritten body (reconciliation or
  `task-engine/references/amend.md`) re-checks only points it adds.
  Agreement authorises that task's implementer — `/task-add` still never
  edits an owned document. Free-form text alongside slug narrows scope;
  feature document read-only to `/task-add` itself.
  Documents two product-pipeline additions to backlog schema: optional
  `Feature: <slug>` summary-block line (feature-derived tasks
  only; absent, not `none`, on free-form ones) and `[STALE]` status
  (resolved by `/task-add feature=<slug>` reconciliation).
  Declares `requires: skill:task-engine` and is the largest consumer of it:
  PHASE 0's setup check and the index-file format reference
  `references/resolution.md`, the status-tag block `status.md`, target values
  and manual interventions `targets.md`, the `[STALE]` and
  reconciliation-classification rules `stale.md`, and PHASE 5 `commit.md`.
  What stays inline is what is unique to authoring.
- `skills/task-clean/` — archives terminal-status tasks. Carries
  `replaces: command:task-clean`, so `add` / `update` retire an installed
  command copy. `--backfill`'s procedure sits in supporting file
  `backfill.md`, read ON DEMAND only when the flag is present, so an
  ordinary prune never pays its tokens. Terminal means
  `[DONE]` and `[SKIP]` and nothing else — `[STALE]` is live work awaiting
  reconciliation and `[PARKED]` live work awaiting an answer, and neither is
  ever pruned by default (naming either explicitly warns and confirms; for
  `[PARKED]` the plan says the prune discards the question and orphans the
  `park/task-<N>` branch, named per task, for the next run's sweep); a
  non-terminal status named
  explicitly archives the same
  way, its frozen `Status:` recording that it was pruned live. Removes
  summary blocks and MOVES each body to `.claude/tasks/archive/<N>.md`
  (`mkdir -p` + `git mv`, so history follows the file; plain `mv` for an
  untracked body), then writes a frozen header under its title — `Archived:`
  date plus the summary block's `Status:` / `Files:` / `Preconditions:` /
  `Feature:` as they stood. No body is ever deleted. PHASE 1 probes source
  and destination by exact-path Glob, never a folder listing: a missing
  source is noted and its block still leaves; an existing destination is
  refused (task stays in the backlog), never overwritten. Survivors'
  `Preconditions:` drop archived ids — an archived precondition is a
  satisfied one. Never renumbers — task IDs stable across project's
  lifetime; `Last task number` counter never decreases. A prune never
  opens `.claude/FEATURES.md`, so a feature keeps every id it generated on
  `Tasks:` and `Tasks: none` means never planned. `--backfill` (exclusive with a status set, git only — a `## VCS`
  override stops it — same **"Apply?"** gate) recovers bodies earlier runs
  deleted: `git log --diff-filter=D` under `.claude/tasks/`, latest deletion
  per path, ids live or already archived dropped; body from the deleting
  commit's parent, header from that parent's `TASKS.md` block, `Archived:`
  the deletion date (no block → hand deletion, `Archived:` alone, flagged);
  each id put back on its feature's `Tasks:` line at its ascending position
  — the skill's only `FEATURES.md` write, on that path alone; a vanished
  slug reported, not written. Never writes `TASKS.md` under `--backfill`; a
  second run reports nothing to recover. THE PARK-BRANCH SWEEP runs on every
  prune (not `--backfill`, not under a `## VCS` override): `git branch --list
  'park/task-*'` plus `git ls-remote --heads origin` (remote skipped under
  NO_PUSH), orphan = no summary block or `Status:` neither `[PARKED]` nor
  `[IN PROGRESS]` as PHASE 1 read it (a resumed task keeps its branch as
  rollback source until its commit); orphans get a plan section (none → nothing said), are deleted in
  PHASE 2 step 7 on the same gate (`git branch -D` / `git push origin
  --delete`), a failed delete reported, not fatal; "No tasks to prune." only
  when there are neither tasks nor orphans; a sweep-only run commits nothing.
  Commits automatically:
  `task-clean: archive tasks <N>, …` staging `.claude/TASKS.md` + each
  `.claude/tasks/archive/<N>.md` (`git mv` already staged both halves of the
  rename); backfill `task-clean: backfill <N> archived tasks`, adding
  `.claude/FEATURES.md` when a line was restored. `--no-commit` leaves them
  uncommitted, the move still made. Declares `requires: skill:task-engine`:
  backlog parsing and the archive form and
  rule reference `references/resolution.md` (§ *The archive*; its
  `/task-clean` note makes the skill the archive's only writer and its one
  exception to the read prohibition — a per-destination existence check),
  the prune-set vocabulary `status.md`, the `[STALE]` warning `stale.md`,
  and the commit/push gating `commit.md`.
- `skills/task-implement/` — implements backlog tasks end-to-end with
  tests-first sequence. `SKILL.md` carries common path (clean
  tree, known test runner, numbered `target: claude` task) and declares
  `requires: skill:task-engine` —
  backlog resolution and selectors reference
  `references/resolution.md`, implementable/terminal statuses `status.md`,
  `Target:` handling and the delegation guard `targets.md`, the STALE
  protocol `stale.md`, the dirty-tree check `tree.md`, and PRE-FLIGHT step 5
  plus Step 7 `commit.md`. Seven supporting files are read only when their
  branch fires — `test-runner.md` (runner must
  be inferred; mirrors task-setup's table), `no-test-suite.md`,
  `human-in-loop.md`, `unity-mcp-checkpoints.md` (Unity-MCP-driven
  checkpoints), `body-schemas.md`
  (non-current body schema), `delegated-runs.md` (2+-task run user delegated to subagents),
  and `review-rounds.md` (`--review` passed; read once after argument
  parsing, before the first task, never otherwise) — plus `task-engine`'s
  `parking.md`, read at ARGUMENT PARSING when UNATTENDED is true or at
  PRE-FLIGHT step 2 when a resolved task is `[PARKED]`, never on an attended
  run that meets no parked task.
  Also declares `requires: command:follow-ups`: its CLOSING THE RUN section
  applies that command's rules — the body read by name, never invoked — as
  the *Follow-ups* group of the closing report, once per run, after the
  feature-completion proposal, at a user-requested stop between tasks and at
  a failure halt too, reading the per-agent returns under `--agents`, adding
  no commit; with the command absent the group holds the run's own items
  only, silently. **`--unattended`** (PARKED TASKS; the `unattended`
  execution policy, `attended` the default under which nothing changes):
  UNATTENDED is true when the flag was passed OR the conversation declares
  the run unattended — the one sentence a runbook step's preamble or a
  delegated-agent prompt carries; a merely *non-interactive* notice is not
  that. Refusals: `parking.md` § Refusals. Under it every prompt with a default takes it
  (delegation → no, dirty tree → abort, `Proceed?` → yes, …), each a *For the
  record* line; an ambiguous test runner aborts. A question about the work —
  inside the per-task workflow only — runs `parking.md`'s park sequence,
  question printed under the run's next `P<n>` handle, on to BETWEEN
  TASKS. PRE-FLIGHT step 2a
  **pre-asks**: one block of every `[PARKED]` task, each under its `P<n>` handle, in the resolved
  list with its `Question:` verbatim — the one pre-flight body read, handoff
  section only — answered by handle (`P1: Q1a, Q2b`) or `skip` / `skip P<n>` / `skip all`,
  approval-gate items skip-only, answers held in run memory; silence is `skip
  all`; `--skip-parked` (requires `--unattended`) suppresses it. BETWEEN
  TASKS step 2a reads chat replies by handle, records the answer and moves
  the task to the front; a number never printed or a second answer is
  rejected with one line. Step 1 on a `[PARKED]` task decides the answerer
  (an attended session, or a held answer): none → skipped with one line, no
  branch touched; else the unpark transaction, handoff removed, resumed at
  the step named, both edits riding in Step 7's commit; a cherry-pick
  conflict leaves it `[PARKED]` (skipped after a bookkeeping commit under
  UNATTENDED, halt-and-ask under attended). A park that cannot make its
  branch is a Step 7 failure; a parked task never is.
  Reads each task's body file from `.claude/tasks/<N>.md` only when
  needed, treats it as primary context source — only fans out to
  CLAUDE.md and context layer when body doesn't cover what's
  needed. Status flips happen in `.claude/TASKS.md`. Human-in-the-loop
  tasks: on
  `target: claude+human` pauses at each `## Manual interventions`
  checkpoint, walks user through manual step, independently
  verifies outcome before continuing; on `target: human` task runs
  as guided walkthrough (no production edits by Claude, bookkeeping
  still Claude's). When project declares Unity MCP plugin
  (`Unity MCP for /task-implement:` marker in CLAUDE.md) and
  `mcp__UnityMCP__*` tools connected this session, `human-in-loop.md`'s
  gate reads `unity-mcp-checkpoints.md` instead: Claude checks Unity
  Console after compilation, performs editor actions itself, rewrites
  each checkpoint into verification step — opt-outable per run, no-op
  (standard manual protocol) when MCP not connected. Honors `Testing policy for /task-implement:
  skip-tests|full-tdd|skip-tests-unattended` marker in project's
  CLAUDE.md (checked before heuristic test-suite detection) so
  no-test-suite decision persists across runs instead of re-asked
  each time. In skip-tests mode, per-task "Proceed?" confirmation can
  be suppressed with `-y` flag for single run, or permanently via
  `skip-tests-unattended` marker value. On `[STALE]` task
  warns naming originating feature and offers implement-anyway or stop
  (`all` / `next` skip stale tasks, report them, rather than deciding
  for user). `next` / `all` honour `Preconditions:` per `resolution.md`'s
  eligibility clause — `all` orders its list so nothing starts ahead of
  what it waits on and names blocked tasks by id; on a run resolved by
  `all`, BETWEEN TASKS step 2 (and `delegated-runs.md`'s between-agents
  re-read, which then spawns no agent for it) re-checks the upcoming task's
  `Preconditions:` and skips it with one line when they no longer hold,
  adding no read; an explicit-number list is never re-checked. On run resolving to 2+ tasks, offers
  to implement each task in fresh subagent so later tasks don't inherit
  earlier ones' context; agents spawned one at a time, never
  parallel (shared working tree, branch, `TASKS.md`), each owning own
  task's status flips, commit, push, while `claude+human` / `human` /
  explicitly requested `[STALE]` tasks stay in parent conversation
  since need user present. `--agents` / `--no-agents`
  pre-answer prompt; single-task runs never see it. On such run parent
  is **launcher**, not orchestrator: evaluates delegation guard
  (`Target:`, `Status:`, `Feature:`) from `TASKS.md` summary blocks
  PRE-FLIGHT step 2 already read, so never opens `.claude/tasks/<N>.md`
  for delegated task on any path; hands every agent same fixed-size
  prompt — task number + repo's absolute path + run's resolved flags
  (open list, not closed set: NO_COMMIT/NO_PUSH/AUTO_CONFIRM, resolved
  testing mode w/ concrete test command, DIRTY_FOLD /
  DIRTY_FOLD_UNTRACKED, UNATTENDED — attended: a question ends the agent's
  turn under `QUESTIONS FOR USER` and the launcher relays it in the runbook's
  fixed block, answer sent back to the same agent; unattended: the agent
  parks and returns `[PARKED]` with its question, recorded, never a halt —
  plus a held answer for a `[PARKED]` task) + instruction to read
  body, CLAUDE.md, context layer itself; keeps exactly six values per
  return, the last two optional (task number, terminal status, commit hash or
  nothing-committed, one-line failure reason only on failure, at most
  three follow-ups, omitted when empty, which is almost every task, and at
  most three *For the record* lines). The
  field applies `/follow-ups`' rules, **not a format of its own** — the agent
  reads that command's own body and applies what is there; what counts, what
  is excluded and how an item is written are that command's and are
  deliberately not restated in either `delegated-runs.md` or SKILL.md,
  leaving only the cap and the omit-when-empty to the channel. **Named, never
  pathed** (`../../docs/authoring-guide.md` § "Asking whether a feature is
  installed: name it"): the agent is handed a prompt rather than a file and
  has no anchor to resolve a relative path against, so the command's
  **name** is what resolves in both scopes.
  **Reads the rules, never invokes the command** — invoking would be the
  per-task call the DO NOT list forbids, and a read degrades where an
  invocation would not: no file to read means skip the field silently, the
  same rule the closing report follows, never a failed task. The lines feed
  the report's *Follow-ups* group and nothing else, and the parent neither acts on nor
  verifies one. Prompt O(1) in batch size and in task size, so the
  parent's context does not grow with the batch; tasks the parent keeps
  get their body read in Step 1. Commits each task
  separately; `--no-commit` runs full sequence but skips
  per-task commits, leaving every task's changes uncommitted. When a
  `Feature:`-tagged task lands `[DONE]` and leaves every task for that
  feature `[DONE]`/`[SKIP]`, records it as a completion candidate; once, at
  the very end of the run (batched across the whole run, never per-task),
  proposes flipping each candidate's `FEATURES.md` `Status:` from
  `[PLANNED]` to `[DONE]` — user decides per feature, one commit covers
  every flip approved. Non-interactive run (delegated agent, `/runbook-run`
  step) never proposes: names candidates in its closing report, outermost run
  asks. THE CLOSING REPORT: two groups, **For the record** (one line each,
  `<what deviated> — <why> — <resolved by whom>`) then **Follow-ups** — last,
  nearest the prompt — one numbered list, `1.`/`2.`/…, any length: the run's
  own items (unresolved `BLOCKING` finding, task left `[IN PROGRESS]`, owner
  follow-up with anchor, precondition that no longer held, declined slug,
  every task parked or skipped-unanswered with its `Question:` verbatim) plus
  what `/follow-ups`' rules yield applied to the run's reading, de-duplicated
  by action with the command form kept; the number is the reply handle,
  restarting at 1 per report, a lone item still numbered, and a number naming
  a parked task's question is its answer for the next run; an empty group
  prints `none`. Under `--agents` the sixth field feeds *For the record*, the
  fifth and each `[PARKED]` return's question feed *Follow-ups*. Consequential edits — a passage brought into agreement with an
  approved change, no meaning added — are in scope in any file, same commit,
  reported For the record; new meaning in an owned document goes under
  Follow-ups as a precise `/architect amend` follow-up.
  `--review` (with optional `--rounds N`, default 1) runs a review/iterate
  loop per task. Availability gate first: both `task-review` and
  `task-iterate` must be present in the session or the run stops BEFORE any
  `[IN PROGRESS]` flip — never silently skipped, since "implemented" and
  "implemented and reviewed" are different claims. `--rounds` without
  `--review` errors (`--rounds requires --review.`); a non-positive integer
  errors (`--rounds needs a positive integer.`).
  Two cost-control flags steer the spawned reviewer, both defaulting to
  `auto` and both erroring without `--review` in the same shape `--rounds`
  uses: `--review-model <name>|same|auto` (`--review-model requires
  --review.`) and `--review-effort shallow|standard|deep|same|auto`
  (`--review-effort requires --review.`, plus a value check naming the five
  legal levels). Model names pass VERBATIM to the Agent tool — no local
  allow-list, since a hardcoded roster would refuse a model that works.
  The pair resolves **per task, at the top of each round**, never once per
  run, from that round's own diff plus the criteria count already in hand,
  which is what keeps a batch O(1); the two values feed exactly two places —
  the model decides whether the Agent call carries `model:` (omitted on
  `same`, so the child inherits), the effort decides whether the spawn
  prompt carries a budget block (omitted on `same`, so the reviewer reads
  unbounded). Neither the tier table nor the budget table is restated in the
  skill: `task-engine`'s `references/review-budget.md` is their single
  authority and `review-rounds.md` reads it. Loop sits after Step 5 and
  **before Step 6**, on the uncommitted tree — before, not between 6 and 7,
  so a halt on unresolved findings leaves the task `[IN PROGRESS]` rather
  than `[DONE]`-and-halted. Each round spawns `/task-review` as a
  **subagent** (`subagent_type: general-purpose`) — fresh context is the
  mechanism, not an optimizable detail — with an eight-item prompt (repo path,
  `task=<n>`, this round's diff scope, round number, prior rejection ledger
  from round 2 on, and the statement that it was spawned by
  `/task-implement --review`, which selects `/task-review`'s spawned output
  destination rather than restating its rule, the test-suite
  state — green under the resolved policy, or skip-tests and nothing ran,
  handed in because the reviewer runs no test command itself — and the
  budget block, omitted entirely when the effort resolved to `same`). That spawn
  returns **asynchronously**: the call yields an agent id and the findings
  arrive later as a separate notification, so the round waits for them and
  Steps 6/7 are unreachable until the final round's result has actually
  arrived — treating the call's return value as the findings would commit
  unreviewed work while reporting it reviewed. `/task-iterate` then runs in
  **this** session (its edits must land in the tree Step 7 commits), told
  explicitly it is inside a round and must not commit. Loop continues only
  while `BLOCKING` findings remain unresolved and only up to `ROUNDS`; later
  rounds re-review only the hunks the last iterate changed; rejections are
  sticky across rounds. Unresolved `BLOCKING` after the last round stops the
  whole run per FAILURE HANDLING (tree uncommitted, task `[IN PROGRESS]`, no
  next task). Exactly one commit per task either way — the fixes ride in the
  task's own commit, never a second one. In a delegated run REVIEW/ROUNDS
  plus REVIEW_MODEL/REVIEW_EFFORT
  ride through the fixed-size hand-off prompt as two more strings and each
  implementor spawns
  its own reviewer, measuring its own diff (launcher → implementor →
  reviewer; the launcher measures nothing); no finding travels up to the
  parent through the return contract: `/follow-ups`' exclusion rule keeps a
  finding out of the fifth field, a finding not being an unrecorded piece
  of work. What its reading does catch is a deferral
  `/task-iterate` noted should become a task and that never did.
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
- `commands/task-list.md` — prints backlog as compact read-only
  summary. Marks `claude+human` / `human` tasks with `⚠ <target>`, shows
  `[<slug>]` for tasks with `Feature:` line, appends `⚠ stale` to
  `[STALE]` tasks and `⚠ parked` to `[PARKED]` ones in that same slot (a
  task is never both; `PARKED` filters like any status; nine tags, the
  padded column still sized to `[IN PROGRESS]`). When `.claude/PLAN.md` exists, also groups tasks under
  milestone headings in plan order, resolving each task's `Feature:` slug
  through the milestones' `Features:` lists, and appends `⚠ blocked by <slug>`
  when the task's feature is blocked — same readiness rule as
  `/production-status`, duplicated rather than shared (one paragraph of logic
  in a markdown prompt), with an unresolvable edge slug ignored rather than
  treated as a blocker. Tasks with no `Feature:` line and slugs no milestone
  lists (including `Unscheduled` ones) fall under one trailing `Unplanned`
  heading; empty milestones get no heading. Marker order stated explicitly in
  the body: `⚠ <target>`, `[<slug>]`, `(deps: N, M)`, `⚠ stale` |
  `⚠ parked`, `⚠ blocked by <slug>`. Filter applies before grouping, so it works within
  groups; the summary line is the same with or without grouping. NO
  `PLAN.md` → no grouping, a silent no-op with no warning and no pointer at `/production-plan`. Reads
  `.claude/TASKS.md`, plus `PLAN.md` and `FEATURES.md` when a plan exists;
  never opens body files, feature docs or the roadmap. Declares
  `requires: skill:task-engine`: backlog
  resolution references `references/resolution.md` and the status vocabulary
  `status.md`, leaving only the rendering rules inline.

## Public API

Each feature's contract is its bullet in § Overview. Frontmatter,
`description` contract and loading-control keys:
[features.md](./features.md) § Public API.

## Internal patterns

- None of their own: [features.md](./features.md) § Internal patterns.

## Domain dependencies

- `../domain/task-workflow.md` — backlog schema and the author/implementer
  split.
- Frontmatter schema: [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds, frontmatter contract, the
  home-path guard.
- [pipeline.md](./pipeline.md) — the pipeline stages that feed `/task-add`
  and the `pipeline-engine` library beside `task-engine`.
- [runbook-suite.md](./runbook-suite.md) — the runbook suite, which shares
  `/task-implement`'s execution policy.

## When to read the source

- [features.md](./features.md) § When to read the source.
