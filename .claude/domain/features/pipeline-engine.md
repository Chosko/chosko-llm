# Pipeline engine and lint

A shared reference skill, `pipeline-engine`, holding the four things every
revision-suite feature needs to know about the pipeline as a whole — how to
probe a project's setup, how the indexes link to each other, what each pipeline
command consumes and produces, and what counts as drift — plus a read-only
command, `/pipeline-check`, that reports drift across the whole set of indexes.
The engine is graph and table, never prose restating another skill. The lint
is what makes the silent cost of a mishandled amendment loud.

## Purpose

An amendment that is not propagated correctly costs nothing until production:
a task whose `Feature:` names a slug that no longer exists, a precondition
pointing at a skipped task, a runbook step still naming a task already done, a
`[PLANNED]` feature whose every task has resolved. None of the pipeline's
indexes read the others for consistency, so the drift sits there until an
implementer hits it. `/pipeline-check` reads all of them and names each
inconsistency with the command that fixes it.

The engine exists for the same reason `task-engine` does: the probing, the
graph and the routing knowledge would otherwise be restated by
[pipeline-revision](./pipeline-revision.md)'s two surfaces,
[pipeline-suggest](./pipeline-suggest.md) and the lint itself, and four copies
of a rule is three chances to forget one. Serves Claude-as-operator, who reads
the engine at run time, and the director, who reads the lint's output.

## Scope and non-goals

In scope: the `pipeline-engine` skill folder with four reference files; the
`/pipeline-check` command; the probe verdict line and its in-session reuse
rule; a repo-local check script that keeps the routing table honest.

Deliberately out:

- **A pipeline explainer.** No reference file narrates the pipeline. The
  product-workflow document does that in the domain layer, where it is not
  installed. Every line in the engine must be consumed by a routing decision,
  an impact-walk step or a lint rule; a line that is not, is cut.
- **Auto-running the lint.** No pipeline writer runs `/pipeline-check` at its
  end. Each writer would otherwise depend on the engine, and the user chose
  to keep the lint an explicit act.
- **Fixing anything.** The lint reports; every fix is the named owner's.
  The register is `/production-status`'s: writes nothing, runs no shell beyond
  the probe, never opens a file under `.claude/tasks/` or `.claude/runbooks/`.
- **Absorbing `task-engine`.** The two engines sit beside each other. Merging
  them is recorded as an open question, not done speculatively.
- **Semantic drift.** The lint detects structural inconsistency between
  indexes. Whether a feature document still describes what its tasks build is
  a judgement, made by `/architect amend`'s precision guard, not here.

## Architecture

Built on the existing markdown-prompt stack per `technical-direction.md`. A
shared file can only ship inside a skill folder, so the engine is a skill,
non-invocable in the same way `task-engine` is, and its consumers declare
`requires: skill:pipeline-engine`. Every consumer reads it at the
`${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/` path and
never a `docs/` path.

### The reference files

- **Probes** — the set of cheap filesystem probes that describe a project's
  pipeline setup: feature index present, backlog present, roadmap present and
  sliced, plan present, runbook index present, council skill installed, the
  testing-policy marker in CLAUDE.md, and which pipeline features are
  installed under `CLAUDE_HOME`. The file fixes a one-line verdict format that
  every consumer prints identically, and the reuse rule: a verdict already in
  the conversation is reused unless a pipeline writer has run since, and the
  file names the writers that invalidate it. Subagents re-probe, since they
  share no conversation. The saving is one round-trip and one definition, not
  tokens, and the file says so, so nobody optimises it further.
- **Graph** — how the indexes point at each other, and nothing else: a
  feature's `Source:` to a design section and optional milestone; `Tasks:`
  and `Feature:` between the feature index and the backlog; `PLAN.md`'s
  milestone lists and its edge list; runbook steps that name task ids or
  feature slugs. This is the impact walk's only input. Reading a body is a
  consumer's decision and is never required to traverse the graph. A `Tasks:`
  id with no `TASKS.md` block resolves as archived and terminal, per
  [task-archive](./task-archive.md).
- **Routing** — one row per pipeline command or skill: what it consumes, what
  it produces, which artifact lines it owns, its preconditions, its argument
  shape. Owner-of is the column [pipeline-revision](./pipeline-revision.md)
  keys on; consumes and produces are what its impact walk uses to order steps.
- **Lint** — the finding catalogue: each finding's detection rule over the
  indexes, its severity — two levels, `ERROR` and `WARNING` — and the one
  command that resolves it. The command
  and the two revision surfaces read this file so a finding is defined once.

### The findings

The initial catalogue, all derivable from indexes alone:

- a task's `Feature:` slug absent from `FEATURES.md`;
- a task with no `Feature:` line on a project whose `FEATURES.md` exists;
- a `Preconditions:` id that is unknown, or names a `[SKIP]` task; a
  precondition cycle;
- a `[ITERATED]` feature; a `[STALE]` task; a `FEATURES.md` slug absent from
  `PLAN.md`; a plan edge naming an unknown slug;
- a runbook `[PENDING]` with no unticked step, derived from `Steps: <n>/<n>`
  and `Status:` in `RUNBOOKS.md` alone;
- a `[PLANNED]` feature whose every task is `[DONE]` or `[SKIP]` and which
  has not been flipped.

A pending runbook step naming a task already `[DONE]` or `[SKIP]` is not in
the shipped catalogue: detecting it means reading a step's prompt, which means
opening a runbook body, and no finding opens one. `/runbook-run` surfaces the
same problem when it prints each step before spawning it. See the second open
question.

Each finding names its fix: `/task-add feature=<slug>` for the iterated
feature, `/production-plan` for the missing slug, `flip to [DONE]` for the
resolved feature, `/pipeline-patch` or `/pipeline-revise` for the rest.

### The command

`/pipeline-check` probes, reads exactly the indexes the probe found, evaluates
the catalogue and prints findings grouped by artifact, each with its fix. A
clean project prints one line. Every absent index removes its findings rather
than failing the run; the only stop is a project with none of the indexes at
all, which is pointed at `/task-setup` and `/domain-setup`. An optional
`feature=<slug>` scopes the walk to one feature and the tasks, edges and steps
that name it, which is the form the revision surfaces call before and after
they act.

### The routing check

A repo-local script beside `check-changelog.sh` verifies two invariants:
every row in the routing table names a feature that exists as a command or a
skill, and every feature declaring `requires: skill:pipeline-engine` has a
row. Semantics cannot be checked mechanically;
existence can, and a routing table that names a deleted skill is exactly the
drift this feature is meant to catch elsewhere. Same register as the other
repo-local audits: authoring-time only, never installed.

## Data and state

No new file in a project. The engine is prose read at run time. The probe
verdict lives in the conversation for the length of a session and nowhere
else. Every finding is derived on every read and never stored; the lint has no
cache, no last-run stamp and no baseline file. The routing table is shipped
content, versioned with the skill.

## Interfaces and contracts

- `/pipeline-check [feature=<slug>]` — read-only report; exit is a printed
  summary, never a status flip.
- `requires: skill:pipeline-engine` — declared by `/pipeline-check`,
  `/pipeline-patch`, `pipeline-revise` and `pipeline-suggest`.
- The verdict line — a single line, fixed field order, printed by any
  consumer that probes and reused by any that finds it.
- Hard contracts: the engine states no rule that any other skill also
  states; the lint never writes; a finding's fix is always a real command the
  routing table lists; consumers cite the engine by path and state only their
  deviations, the `task-engine` discipline verbatim.

Failure contract: a missing index drops its findings; a malformed block is
reported as a finding of its own rather than aborting; an uninstalled
consumer is the CLI's problem at install time, through `requires:`, never the
lint's at run time.

## Dependencies

- **[shared-phase-engine](./shared-phase-engine.md)** — the `requires:` field
  and the non-invocable-skill pattern this engine reuses unchanged.
- **[plan-readout](./plan-readout.md)** — the read-only register and the
  degrade-never-refuse failure contract `/pipeline-check` copies.
- **[repo-local-audits](./repo-local-audits.md)** — where the routing check
  belongs.
- Documentation to update when this lands: `README.md`, `docs/reference.md`,
  `.claude/domain/product-workflow.md` (a fourth read-side entry),
  `docs/authoring-guide.md` if the routing check becomes part of the
  authoring checklist.

## Open questions

- **Should `pipeline-engine` absorb `task-engine`?** Resolution and commit
  rules are already useful outside `task-*`. Two engines with one consumer set
  is a smell; one engine with two audiences may be worse. Decide after both
  have shipped and the overlap is measurable.
- **Should the runbook index carry per-step task ids?** One named finding — a
  pending runbook step naming a task already `[DONE]` or `[SKIP]` — needs a
  step's contents, which today means opening a runbook body, so it is left out
  of the shipped catalogue. Adding a
  summary of step targets to `RUNBOOKS.md` would keep the lint index-only,
  at the cost of a derived field the schema currently avoids.
- **Does a second non-invocable skill change harness behaviour?** The same
  unverified assumption `task-engine` shipped on. Watch on the first real
  install.
