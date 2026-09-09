# Task archive

`/task-clean` stops deleting. A pruned task's body moves to
`.claude/tasks/archive/<N>.md`, carrying the summary block it had at the
moment it left the backlog, and stays there indefinitely. The feature that
generated the task keeps naming it in its `Tasks:` line. No command lists
the archive, probes it, or opens a file in it; an archived task is read only
when the user names it and asks. A one-off `--backfill` mode recovers tasks
that earlier runs deleted, from git history, into the same archive.

## Purpose

Two costs of today's `/task-clean`, both paid later than they are incurred.
The body is the only record of what a task was, and once deleted it is
reachable only through git archaeology by someone who already knows the
commit. And the prune drops the task's id from its feature's `Tasks:` line,
so a `[PLANNED]` feature whose work all resolved reads `Tasks: none`,
indistinguishable from a feature never planned. The iterate guard and the
status readout each carry a special case to paper over that ambiguity,
keyed on `Status:` because `Tasks:` can no longer discriminate.

Retaining the body under an archive folder removes the first cost, and
leaving `Tasks:` alone removes the second: a feature keeps every id it ever
generated, so `Tasks: none` again means what it says. The rule that nothing
reads the archive keeps the token cost of the usual session exactly where it
is, since a folder no command traverses costs the same as a folder that is
not there. Serves the director, who can ask what task 150 was a year later,
and Claude as operator, who no longer has to reason about ids that resolve
to nothing. High-level feature: [product-design.md § Task
backlog](../product-design.md#task-backlog).

## Scope and non-goals

In scope: the archive folder and the archived-file form; `/task-clean`
moving instead of deleting and no longer touching `FEATURES.md` on a prune;
the resolution rule that makes a referenced-but-absent id mean "archived,
terminal"; the read prohibition and its single exception; the archived
count in `/production-status`'s task rollup; the `--backfill` recovery mode
and its supporting file; the kind migration of `/task-clean` from command to
skill that the supporting file forces.

Deliberately out:

- **A read surface.** No `/task-list archived`, no `/task-archive` command,
  no listing of the folder by any command. The archive is reached by the
  user naming a task and asking to see it, and by nothing else. A listing
  would need each file's title, which means opening every one — bending the
  one rule the feature exists to keep.
- **A purge.** Nothing deletes from the archive. Whether a permanent
  deletion path should exist is an open question below, not a scope
  decision made silently.
- **Distinguishing archived from dead.** An id absent from `TASKS.md` is
  assumed archived. No command checks whether the file is actually there;
  a hand-deleted body and an archived one look the same to every reader,
  and the difference matters only when the user asks to read the task, at
  which point the missing file says so itself.
- **Backfilling non-git projects.** Recovery reads git history. A Plastic
  SCM project gets a plain stop, not a `cm` port.
- **Restoring an archived task to the live backlog.** A task that was
  resolved stays resolved; follow-up work is a new task, the same rule
  `[DONE]` already carries.

## Architecture

Built on the existing markdown-prompt stack per
[technical-direction.md](../technical-direction.md): the writer is a
prompt, the archive is a folder, the rule lives in the reference library
the `task-*` suite already shares. No shell script gains archive awareness;
the CLI's export selection already prunes `.claude/tasks/` from traversal
and the archive folder sits inside it, so nothing there changes.

### The archive folder and the archived file

`.claude/tasks/archive/`, created by `/task-clean` on its first archive.
One file per archived task, `<N>.md`, keeping the task's id as its name
exactly as the live body did. The file is the original body, unchanged,
plus a frozen header: the lines the summary block carried in `TASKS.md` at
archive time — `Status:`, `Files:`, `Preconditions:`, and `Feature:` when
the task had one — and an `Archived:` date, all written as the same
`Key: value` lines the body already uses for `Target:`, directly under the
title. Nothing else is derived or added. The folder is append-only: the
archiving run is the only writer, and no feature removes from it.

### `/task-clean` as a skill

The command becomes a skill folder, `skills/task-clean/SKILL.md`, declaring
`replaces: command:task-clean` so `chosko-llm add` and `update` retire the
command file per the kind-migration path
([features.md](../../context/features.md)). The migration exists for one
reason: `--backfill`'s procedure must sit in a supporting file that the
ordinary prune never loads, and a command is a single file that can carry
nothing beside it. `SKILL.md` keeps the whole of today's prune flow and
adds only the archive move; `backfill.md` is read exactly when the flag is
present. The skill keeps `requires: skill:task-engine`.

In the prune flow, the change is confined to the apply step and to what
the plan renders. The body is moved rather than removed — a rename the VCS
records, so history follows the file — and the frozen header is written
into it from the summary block the plan already parsed. The summary block
still leaves `TASKS.md`; survivors' `Preconditions:` still drop the pruned
ids, since an archived precondition is a satisfied one and no reader should
have to resolve into the archive to know a task is ready. The step that
rewrote `FEATURES.md` `Tasks:` lines is removed outright: on a prune,
`/task-clean` no longer opens `FEATURES.md` at all. Non-terminal prune sets
named explicitly archive the same way; the frozen `Status:` records that
the task was pruned live.

### The resolution rule

`task-engine`'s `resolution.md` is the authority, in the discipline
[shared-phase-engine](./shared-phase-engine.md) set: it gains the archive
location, the archived-file form, and one rule every consumer cites —
**an id referenced anywhere but absent from `TASKS.md` is archived and
terminal; no command probes the folder, opens an archived file, or reports
on its contents, except when the user names a task and asks to read it.**
Consumers state only their deviations, and there are few, because most
readers already tolerate an id that resolves to nothing:

- `/task-add feature=<slug>` reconciliation leaves absent ids
  unclassified, as today, and keeps them when it rewrites the `Tasks:`
  line at the end of the run. Today's wording, that `/task-clean`
  normally prunes them, goes.
- `/task-implement <N>` on an absent id stops and names the archive path
  it would be at, without opening it; it reads the file only on the user's
  explicit ask, and never re-implements it.
- `/task-review` and `/task-iterate` resolve a task, in their weakest
  fallback, from the most recently modified live body; the archive folder
  is excluded from that search.
- `/architect`'s iterate guard already ignores unresolvable ids and keys
  its status flip on `Status:`. Behaviour is unchanged; its rationale,
  which explains the special case by `/task-clean` pruning ids from
  `Tasks:`, is rewritten to say the ids are archived and the special case
  is kept for backlogs cleaned before this feature.
- `/production-status`'s rollup counts absent ids as `archived: N`
  alongside the per-status counts, and under `--task-ids` names each with
  `[archived]`. The zero-task split on `Status:` stays, for the same
  legacy reason. Readiness and the Next value are untouched: an archived
  task is terminal, which is what both already assumed.
- `/task-list`, `/task-setup`, `/session-save`, `/session-resume` and the
  CLI change nothing.

### Backfill

`/task-clean --backfill` recovers what earlier runs deleted, for projects
that pruned before the archive existed. It is exclusive with a status set,
runs behind the same plan-and-Apply gate, and commits per the same
protocol. `backfill.md` carries the procedure:

- find every body under `.claude/tasks/` that git history records as
  deleted, taking the latest deletion per path, and drop the ids that are
  live in `TASKS.md` or already in the archive;
- recover each body from the deleting commit's parent, and its frozen
  header from that parent's `TASKS.md` summary block; `Archived:` is the
  deleting commit's date, so the header tells the truth about when the
  task left the backlog. A body whose block cannot be found — a hand
  deletion — is archived with `Archived:` alone and flagged in the plan;
- restore the feature link: a recovered block carrying `Feature: <slug>`
  whose slug still exists puts the id back on that feature's `Tasks:`
  line. This is the one `FEATURES.md` write left in the skill, and it
  exists only here. A slug that no longer exists is reported, not written.

A second run finds nothing to recover and says so. Backfill is an explicit
act, never triggered by a prune, in the register `/pipeline-check` set for
one-off checks.

## Data and state

- **`.claude/tasks/archive/<N>.md`** — persisted, versioned, one file per
  archived task. Original body plus frozen header. Source of truth for what
  a resolved task was. Append-only.
- **Frozen header** — `Archived:`, `Status:`, `Files:`, `Preconditions:`,
  `Feature:` (when present), written once at archive time and never
  updated. `Preconditions:` is recorded as it stood, and may itself name
  archived ids.
- **`TASKS.md`** — unchanged in schema. An archived task has no block.
- **`FEATURES.md` `Tasks:`** — now the complete list of ids a feature ever
  generated. `Tasks: none` on a `[PLANNED]` or `[DONE]` feature survives
  only on backlogs cleaned before this feature, or after a backfill could
  not restore the link.
- **Archived-ness** — derived, never stored: absence from `TASKS.md` is
  the whole signal. No index of the archive, no count, no marker file.
- **Backfill inputs** — git history, read at run time, stored nowhere.

## Interfaces and contracts

- `/task-clean [<STATUS> ...] [--no-commit] [--no-push]` — unchanged
  surface; the effect changes from delete to archive. The plan names each
  destination path. A destination that already exists is refused in the
  plan rather than overwritten; ids are unique, so it can only mean a
  hand-placed file.
- `/task-clean --backfill [--no-commit] [--no-push]` — recovery mode.
  Refused when combined with a status set. Stops on a project whose VCS is
  not git, naming the limit.
- `replaces: command:task-clean` on the skill's frontmatter; `requires:
  skill:task-engine` kept.
- The resolution rule, cited by path from `resolution.md` by every
  consumer that resolves an id from `Tasks:` or `Preconditions:`.
- The archived count in `/production-status` is a new value inside an
  existing rollup line, not a new column or section.

Failure contract: a body already missing at prune time is noted in the
plan and archived as nothing, exactly as its deletion is noted today; the
summary block still leaves `TASKS.md`. A missing `.claude/tasks/archive/`
is created, never an error. A user asking to read an archived task whose
file is absent is told the file is not there, with no guess at why. Under
`--no-commit`, the move is still a VCS rename in the working tree.

## Dependencies

- **[shared-phase-engine](./shared-phase-engine.md)** — `resolution.md`
  as the single home of the rule, and the consumers-cite-and-deviate
  discipline.
- **[pipeline-engine](./pipeline-engine.md)** — its lint catalogue lists
  "a feature's `Tasks:` id absent from `TASKS.md`" as a finding. Under
  this feature that state is normal, not drift, and the finding must be
  dropped or redefined before `/task-add feature=pipeline-engine` runs;
  that feature is `[NEW]` and its document needs the amendment.
- **[backlog-ordering](./backlog-ordering.md)** — states that an id
  resolving to nothing is ignored; consistent with the rule here, no
  change needed.
- **[plan-readout](./plan-readout.md)** — owner of the rollup line the
  archived count joins.
- The kind-migration path (`replaces:`) in `cmd-add` / `cmd-update`,
  already shipped; no CLI change.
- Documentation to update when this lands: `README.md`,
  `docs/reference.md`, `.claude/domain/task-workflow.md`,
  `.claude/domain/product-workflow.md` (the illegal-transition rationale
  and the who-writes-what row for `/task-clean`),
  `.claude/context/features.md` (the command-to-skill migration).

## Open questions

- **A purge path.** "Retained indefinitely" is the decision; whether a
  `--purge` on `/task-clean` or a separate command should ever delete from
  the archive is undecided. Blocks nothing; the archive is small text.
- **Backfill on Plastic SCM.** Deferred until a Plastic project has a
  deleted backlog worth recovering.
- **Whether a listing is ever wanted.** Ruled out now to protect the
  no-read rule. If the director keeps asking "what did I archive", the
  cheapest answer is a folder listing by id, with titles only on request.
