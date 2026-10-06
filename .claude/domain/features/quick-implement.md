# Quick implement

`/quick-implement` takes a change from conversation to commit in one run: a
`/task-add`-style spec conversation, one gate, then implementation with
`/task-implement`'s sequence — no backlog entry in between. The spec is
committed beside the change and removed later by the follow-up that brings
the documentation up to date, so nothing the run decided is lost and nothing
lingers.

## Purpose

The pipeline makes a small change pay for the whole path: a task written,
committed and listed, then implemented in a second command, with the backlog
carrying an entry that lived for minutes. For a change one person can
describe and one commit can hold, that ceremony buys nothing — yet skipping
it with a bare "just do it" loses the spec conversation, the drift check
against the documented design, the testing policy and the tests-first
sequence.

`/quick-implement` keeps all of those and drops only the backlog round trip.
It also leaves an honest trail: the spec rides in the commit, and the
closing report names the documentation that now lags the code and the
follow-up that fixes it.

## Scope and non-goals

In scope: the command; the spec file and its lifecycle; the drift check;
the task-engine references holding the checks it shares with `/task-add` and
`/task-implement`;
`spec=<path>` on `/task-review` and `/task-iterate`; the `--catch-up` mode of
`/pipeline-revise`; the leftover-spec finding in `/pipeline-check`; the
routing row.

Deliberately out:

- **A backlog entry.** No `TASKS.md` block, no body file, no task id.
- **Splitting.** One spec is one commit. A spec too big for one change gets a
  pointer to `/task-add` and the run stops; it never splits itself into
  several commits or tasks.
- **Feature status.** Never flips a `FEATURES.md` status; the documentation
  catch-up follow-up owns that.
- **Blocking on drift.** A spec that diverges from the documented design is
  mentioned at the gate, never refused. Design breaks and already-implemented
  code are dealt with at follow-up time.
- **Review by default.** `--review` / `--rounds` are opt-in, as in
  `/task-implement`.
- **Other names.** The command is `/quick-implement`.
- **Holding the commit back.** No `--no-commit` or `--no-push`: one spec is
  one commit, and the spec's lifecycle depends on that commit existing.

## Architecture

Built on the repo's existing shape per `technical-direction.md`: a markdown
skill whose runtime is Claude Code, reading shared rules from `task-engine`
and `interaction-engine` by relative path. `skills/quick-implement/` with a
`SKILL.md` and supporting files read on demand.

### The run

1. **Spec conversation.** The same conversation `/task-add` holds for a
   free-form task: goal, acceptance criteria, decisions, hints. Optionally
   anchored on a feature (`feature=<slug>`) for context.
2. **Drift check, during the spec phase.** With or without a feature
   document: search the project's documentation (domain layer, context
   layer, `CLAUDE.md`, README) with search commands for the identifiers,
   files and terms the spec touches, pinpoint the exact files and sections,
   and read only those parts. Each hit is classified with the task-engine
   design-change check (*settles* a point the document leaves open, or
   *diverges* from it). Divergences are listed at the gate; they never block.
3. **One gate.** A plain summary of the spec and any drift, per the
   interaction policy. It is class 1 when the spec has no open question,
   class 2 otherwise. A spec judged too big for one commit ends here with a
   `/task-add` suggestion.
4. **Implement.** `/task-implement`'s per-task sequence, read from
   `task-engine`: the dirty-tree check, testing-policy resolution, tests
   first, implementation, then one commit and push. `--review` / `--rounds`
   run the existing review loop, with `/task-review` and `/task-iterate`
   pointed at the spec by `spec=<path>`.
5. **Close.** The closing report, per the interaction policy: what landed,
   which documents now lag the code (from the drift check plus what the
   implementation changed), and the proposed follow-ups — `/architect amend`
   for a design change, or `/pipeline-revise --catch-up` for editorial
   catch-up.

Under orchestrate-mode, step 1 runs in one fresh subagent whose questions
the orchestrator relays, and step 4 is split into areas; the run still makes
one commit ([orchestrate-mode](./orchestrate-mode.md)).

### The spec file

`.claude/specs/<YYYY-MM-DD>-<slug>.md`, written at the gate and staged in
the implementation commit. Its body follows the task body schema — goal,
acceptance criteria, decisions, hints — plus a *Drift* section listing the
documents and sections the drift check flagged and how each was classified.
It is the one record of what the run decided, and the input
`/task-review spec=<path>` audits against.

It is deleted, in the same commit, only by `/pipeline-revise --catch-up`,
the follow-up that brings the documentation up to date. `/pipeline-check`
reports any spec still present.

### Plumbing: one copy of each shared check

The checks `/quick-implement` shares with `/task-add` and
`/task-implement` live in `task-engine` references, and all three cite
them:

- from `/task-add`: the **design-change check** (the owner list, *settles*
  vs *diverges*), **reconciliation**, and the **orphan question**;
- from `/task-implement`: **testing-policy resolution**, the **tests-first
  sequence**, and the **closing report**.

Moving them changes neither existing command's behaviour.

### `spec=<path>` on the review pair

`/task-review` and `/task-iterate` gain `spec=<path>`: the acceptance
criteria come from the spec file instead of a task body. It ranks with
`task=<n>` (the two are mutually exclusive), so a spec run never falls back
to the most recently modified task body.

### `/pipeline-revise --catch-up`

A new editorial mode: amend the documentation to match code that has
already landed. Its input is a spec path, or a free-form description of the
landed change. It walks impact as the other modes do, then drives owner
amend steps classified editorial — the code already does what the amended
text will say, so no task is marked stale for a point the code settled. A
point where the code breaks the design is not editorial: it is listed in
the plan as a question (accept the code by amending the design, or keep the
design and add a task to bring the code back), and the user's answer takes
the ordinary amend or insert path. The run's commit deletes the spec it was
given. Where a context layer exists and the landed change touched files it
describes, the plan's last step is `/context-update`.

### `/pipeline-check` and routing

`pipeline-engine` gains a probe for `.claude/specs/` and a lint finding for
a spec still present (`WARNING`, fixed by `/pipeline-revise --catch-up
<spec>`). `routing.md` gains a `/quick-implement` row: consumes the
conversation, the documentation sections the drift check found and
`CLAUDE.md`'s testing policy; produces code, tests and the spec file; owns
the spec file; amend `—`. `scripts/check-routing.sh` checks the row names a
shipped feature.

## Data and state

- **Spec file** — `.claude/specs/<date>-<slug>.md`, created by
  `/quick-implement`, committed with the change, deleted by
  `/pipeline-revise --catch-up`. Source of truth for what the run decided until the
  documentation carries it.
- **Code and tests** — the change itself, in one commit with the spec.
- **In memory only:** the drift hits, the resolved testing policy, the
  review rounds' ledger.

No `TASKS.md` or `FEATURES.md` write, ever.

## Interfaces and contracts

```
/quick-implement "<change>" [feature=<slug>] [--review [--rounds N]]
/task-review spec=<path> …      criteria from the spec; exclusive with task=<n>
/task-iterate spec=<path> …     same
/pipeline-revise --catch-up <spec-path | "<landed change>">
```

Failure contract: the dirty-tree and testing-policy outcomes are
`/task-implement`'s; a failed commit leaves the change and the spec staged
and stops, exactly as a task commit failure does; a spec too big for one
commit stops before anything is written; `spec=` beside `task=` is an
argument error; a `spec=` path that does not exist stops the review.

## Dependencies

- [interaction-policy](./interaction-policy.md) — the gate's class, the
  summary and closing-report shape, plain-language questions.
- [shared-phase-engine](./shared-phase-engine.md) — `task-engine`, which
  receives the six moved checks.
- [task-peer-review](./task-peer-review.md) — the review pair gaining
  `spec=`, and the `--review --rounds` loop reused.
- [pipeline-revision](./pipeline-revision.md) — `/pipeline-revise`, which
  gains `--catch-up`.
- [owner-amend-arms](./owner-amend-arms.md) — the editorial classification
  catch-up's amend steps use.
- [pipeline-engine](./pipeline-engine.md) — the spec probe, the lint
  finding, the routing row and its guard.
- [orchestrate-mode](./orchestrate-mode.md) — how the run splits under the
  mode.
