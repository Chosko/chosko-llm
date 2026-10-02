# Features: pipeline readers — production-status and pipeline-check

## Overview

Covers the pipeline's two read-only reporters, `/production-status` and
`/pipeline-check`. The rest of the pipeline family: [pipeline.md](./pipeline.md).

- `commands/production-status.md` — read side of the planning layer. Thin
  read-only reporter (a command, not a skill: no conversation, no supporting
  files) joining `.claude/PLAN.md`, `.claude/FEATURES.md`, `.claude/TASKS.md`
  and `.claude/domain/product-roadmap.md`, all read-only. Eight output
  sections in fixed order: the milestone (slug, title, `Status:`, plus `Goal:`
  and `Exit criteria:` echoed verbatim from the roadmap); its features in plan
  order as a five-column markdown table (`#`, `Feature`, `Status`, `Tasks`,
  `Next`) — the rendering is prescribed in the body, not left to the agent;
  the ready set;
  the ONE recommended next feature (first ready in plan order); blocked
  features each named with what blocks it and why; coverage gaps (milestones
  with `Features: none`, plus `product-design.md` sections no `Covers:` names);
  unplanned features (`FEATURES.md` slugs missing from the plan, plus
  `Unscheduled`); remaining milestones one line each. Section 4 ECHOES the
  recommended feature's section-2 Next value rather than recomputing a next
  step from the rollup — one action rule per report, so the recommendation
  cannot contradict the row above it. A `[DONE]` feature has
  no readiness of its own computed — reported plainly, never in the ready
  set, the blocked list, or the recommendation, though it still satisfies
  edges dependents point at it. READINESS otherwise is the only computation
  and is derived every read, never stored: ready when every edge
  pointing at the feature comes from a feature `[DONE]` in `FEATURES.md`, or
  `[PLANNED]` with all tasks `[DONE]`/`[SKIP]` or archived; no edges → ready; else
  blocked. An edge
  slug resolving to no feature FAILS OPEN — reported as a plan inconsistency,
  feature treated as ready. Section 2's last column is NOT readiness but
  **Next**, derived from status + rollup + readiness and exactly one of
  `-` (`[DONE]`), `/task-add feature=<slug>` (`[NEW]`/`[ITERATED]`), `flip to
  [DONE] in FEATURES.md` (`[PLANNED]`, nothing left but `[DONE]`/`[SKIP]`/
  archived tasks, an all-archived `Tasks:` line and the zero-task case
  included), `/task-implement <N>` (`[PLANNED]`, work
  left, not blocked — N the first open task, never an archived id —
  `task-engine`'s eligibility clause stated inline, fed by the
  summary blocks already read, so no new read and still never a body),
  `blocked by <slug>` (checked first, whatever the preconditions say) or
  `waits on task <id>` (not blocked, but every open task has an unmet
  precondition; names the first such task's unmet ids) — blockedness
  suppresses ONLY `/task-implement`, since planning and a bookkeeping flip are
  never blocked by a dependency. Task rollup is counts per status by default,
  `--task-ids` names each ID; an ID absent from `TASKS.md` is archived and
  terminal (`resolution.md` § *The archive*, named as the rule's home, never
  opened) and is REPORTED, not ignored — `archived: N` joins the same rollup
  line and its total (`[archived]` per ID under `--task-ids`), lowercase
  because it is not a status, counted from absence alone with nothing probed
  under `.claude/tasks/archive/`. Zero tasks is a literal `Tasks: none` only
  (an all-archived line renders `archived: N`): `-` on a `[DONE]`/`[PLANNED]`
  feature (those states are post-`/task-add`, so `none` there means a
  backlog cleaned before task archiving, when `/task-clean` dropped IDs from
  the line) and `no tasks yet` only on `[NEW]`/`[ITERATED]`, in both rollup
  modes; `milestone=<slug>` scopes sections 1–5 and an
  unknown slug stops listing available slugs (matching `/task-add
  feature=<slug>`). Staleness is STRUCTURAL, never temporal — names slugs
  missing from `PLAN.md`, never compares `Last reconciled:` against dates or
  mtimes. Failure contract is degradation throughout (no roadmap omits
  goal/exit criteria, no `TASKS.md` drops rollups, no `[ACTIVE]` reports the
  first `[PLANNED]`); the only stops are a missing `PLAN.md` and an unknown
  `milestone=`. Writes nothing, runs NO shell command of any kind, never opens
  a file under `.claude/tasks/` (the archive included), and never starts the
  work it recommends.
- `commands/pipeline-check.md` — second read-only reporter of the pipeline,
  beside `/production-status`, and like it spanning the whole pipeline
  rather than a stage. Command not skill (single pass, no supporting files);
  declares `requires: skill:pipeline-engine` and restates no probe, edge or
  finding — cites all four engine files by path. Probes (or reuses a verdict
  already in the conversation), reads each of `.claude/FEATURES.md`,
  `.claude/TASKS.md`, `.claude/PLAN.md`, `.claude/RUNBOOKS.md` that exists,
  evaluates `lint.md` over `graph.md`'s edges, prints findings in one fenced
  block grouped by artifact in fixed order (`FEATURES.md`, `PLAN.md`,
  `TASKS.md`, `RUNBOOKS.md`), each line from its `lint.md` template with its
  fix verbatim, closing on a count of both severities; clean run prints
  exactly ONE line naming the indexes read. `feature=<slug>` keeps only the
  findings touching that feature — its entry, tasks whose `Feature:` names it
  or whose id is on its `Tasks:` with their precondition findings and
  cycles, plan lines naming it; no runbook finding in scope (`RUNBOOKS.md`
  ties no runbook to a slug). Unknown slug, or no `FEATURES.md`, said in one
  line and the unscoped report runs. Failure contract is degradation: absent
  index drops its findings, malformed block reported, unrecognised argument
  named and ignored; ONLY stop is a project with none of the four indexes,
  pointed at `/task-setup` / `/domain-setup`. Reports, never fixes: writes
  nothing, commits nothing, flips no status; no exit-code contract, no
  `--fix`, no `--quiet`. Opens no file under `.claude/tasks/archive/` or
  `.claude/domain/features/`; under `.claude/tasks/` and `.claude/runbooks/`
  it opens exactly the bodies `lint.md`'s two parking findings name — L12, a
  `[PARKED]` task with no `## Parking handoff` (`ERROR`, fix
  `/task-implement <N>` attended), reading each parked task's body for the
  heading; L13, a runbook whose `[P]` steps and index `Parked:` line disagree
  (`WARNING`, fix `/runbook-run <id>`), reading each non-`[DONE]` runbook's
  body for its markers, never a prompt block — and no branch probe; `feature=`
  keeps L12 on a parked task in scope. The filesystem probe is
  its only shell use — the one stated departure from `/production-status`,
  which runs none. Runs only when invoked; no pipeline writer auto-runs it.

## Public API

- See [pipeline.md](./pipeline.md) § Public API.

## Internal patterns

- See [pipeline.md](./pipeline.md) § Internal patterns.

## Domain dependencies

- See [pipeline.md](./pipeline.md) § Domain dependencies.

## Cross-references

- [pipeline.md](./pipeline.md) — the pipeline family hub, incl.
  `pipeline-engine`, whose four files `/pipeline-check` cites.
- [pipeline-planning.md](./pipeline-planning.md) — `/production-plan`, the
  writer of the `PLAN.md` `/production-status` reads.
- [pipeline-revise.md](./pipeline-revise.md) — `pipeline-revise`, which
  brackets its run with `/pipeline-check`.

## When to read the source

- See [pipeline.md](./pipeline.md) § When to read the source.
