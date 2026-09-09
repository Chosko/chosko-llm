# Pipeline suggest

An auto-triggering skill that reads a free-form request on a project with a
pipeline and says, in one or two lines, which pipeline command fits it, then
stops. "Add a login to the page" earns a pointer at `/architect`; "fix this
bug" earns a pointer at `/task-add`; a change to something already planned
earns a pointer at `/pipeline-patch` or `/pipeline-revise`. It asks nothing,
reads nothing beyond two file-existence probes, writes nothing and never
invokes what it suggests. It is the cheapest tier of the revision suite and
the only one selected by the harness rather than by the user.

## Purpose

Most requests that should enter the pipeline do not arrive phrased as a
command. The director describes what they want and Claude starts doing it,
and the feature index, the backlog and the plan learn about the work late or
never. A one-line nudge at the moment the request arrives is the cheapest
possible correction, and it must stay that cheap or it becomes the thing
users learn to ignore. The shape is `runbook-suggest`'s, already shipped and
already tolerated: a description narrow enough to trigger rarely, a body short
enough to cost nothing when it does, an output the parent conversation
continues past.

Serves the director, who is reminded once and decides, and Claude-as-operator,
whose default of doing the work directly is interrupted only by a sentence.

## Scope and non-goals

In scope: the skill, its trigger description, its ten-row shape table, its
silence rules, its two-probe gate and its fixed output shape.

Deliberately out:

- **Doing anything.** No invocation, no question, no file read past the
  probes, no write. The parent conversation proceeds exactly as it would have.
- **Routing knowledge.** The body carries a table from request shape to
  command. It does not carry what each command consumes or produces; that is
  the engine's routing table, and this skill reads no reference file at all.
  The two tables differ in content and are noted as such for the overlap
  audit.
- **Blocking.** The suggestion is never a gate. A user who ignores it has
  ignored it.
- **Suggesting on projects without a pipeline.** No feature index and no
  backlog means no suggestion, silently.
- **Replacing `runbook-suggest`.** That skill keeps its own trigger for
  follow-up lists; this one's table points at it for that shape rather than
  restating it.

## Architecture

Built on the existing markdown-prompt stack per `technical-direction.md`. A
skill because only a skill is selected from its description; a command is
invoked by name and cannot auto-trigger.

### The trigger

The description is the whole trigger, as with every auto-selected skill, and
it is written narrow: a free-form request to build, change, fix, remove or
sequence work, on a project that has a feature index or a backlog, when the
request does not already name a slash command. Its "not for" list is longer
than its "for" list, deliberately: not for a question, not for a request that
names a command, not for "just do it" or "directly", not for work already
under way in a `/task-implement` run, not for an enumeration inside an
explanation, not for a follow-up list, which `runbook-suggest` owns.

### The gate

Two probes, nothing more: does `.claude/FEATURES.md` exist, does
`.claude/TASKS.md` exist. Both absent, the skill says nothing and ends. This
is cheaper than the engine's full probe on purpose; the skill needs to know
only whether a pipeline exists, not its shape.

### The shape table

Ten rows at most, in the body:

- a new capability or feature-sized addition → `/architect`;
- a bug, a small change or a chore → `/task-add`;
- a small change to something already planned → `/pipeline-patch`;
- a large change, an insertion at a point in sequence, a deletion or a
  reorder of planned work → `/pipeline-revise`;
- "what should I build next" → `/production-status`;
- "is the backlog consistent" → `/pipeline-check`;
- an ordered list of follow-ups → `/runbook-suggest` already fires;
- a design-level decision → `/product-design`;
- a milestone or release question → `/product-roadmap` or
  `/production-plan`.

A request that matches no row produces no output. A request that matches two
names both in one line.

### The output

One line naming the command and the phrase in the request that matched, and
optionally a second line saying the parent can proceed directly instead. Then
the skill ends. Nothing about the request's substance is restated.

## Data and state

None. The skill has no memory of having suggested; a repeated request earns a
repeated line, which the silence rules bound rather than a suppression list,
because a suppression list would be a state file.

## Interfaces and contracts

- Selected by description; no arguments; `requires: skill:pipeline-engine`
  so the commands it names are installed, and the two revision surfaces.
- Output: at most two lines, then end of turn for this skill; the parent
  continues.
- Hard contracts: body under about forty-five lines like `runbook-suggest`;
  zero reference reads; exactly two probes; never invokes, asks, or writes.

Failure contract: a probe that errors is treated as absent; a request that
matches no row is silence. There is no failure that produces more than two
lines.

## Dependencies

- **[pipeline-revision](./pipeline-revision.md)** — the two surfaces the
  table points at must exist first, or the suggestion names commands that
  are not installed.
- **[pipeline-engine](./pipeline-engine.md)** — `/pipeline-check` as a row;
  the overlap audit note about the two tables.
- **[runbook-suite](./runbook-suite.md)** — the `runbook-suggest` shape this
  skill copies, and the row it delegates to.
- Documentation to update when this lands: `README.md`, `docs/reference.md`,
  `.claude/domain/product-workflow.md` (a note that the pipeline has an
  auto-suggested entry point).

## Open questions

- **Does it nag?** The silence rules are a design; whether they suffice is an
  observation to make after the first weeks of use. If it fires too often the
  first lever is the description, not the table.
- **Should "fix this bug" suggest anything?** On a project with a backlog it
  points at `/task-add`; a director who wants the fix now will say so. If that
  row turns out to be the noisy one, it goes.
