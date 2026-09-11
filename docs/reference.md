# chosko-llm reference

The complete reference for everything `chosko-llm` ships: every flag, every
document each feature reads and writes, every commit rule and edge case. The
[README](../README.md) explains what the workflow is and when to reach for
each feature; this file is where the detail lives. Sections follow the same
order.

Everything here is opt-in. Install a feature with `chosko-llm add <feature>`,
then run it as a slash command (`/<name>`) inside Claude Code. Two commit
conventions recur throughout: **authoring** features (those that write a
document you review) leave their output uncommitted by default and commit
under `--commit` (`--commit --no-push` commits without pushing); **working**
features (those that advance a backlog) commit and push by default and take
`--no-commit` / `--no-push` to hold back.

---

## 1. Setting up a project

### `/project-setup`

One-pass setup for a new repo. Seeds `CLAUDE.md` from pasted material, adds an
optional `AGENTS.md` pointer, injects a VCS-mapping section for non-git
projects, and can kick off the task backlog, the domain layer and the context
layer. Gathers every choice up front, confirms once, then executes. Leaves
everything uncommitted by default; `--commit` commits (and pushes) its own
artifacts and forwards `--commit` (plus `--no-push`, if set) to the
sub-commands it runs. On a non-git VCS (e.g. Plastic SCM), the injected
`## VCS` section notes that `cm checkin` already syncs to the server, so no
push cycle ever runs there. On a Unity project it offers to run
[`/unity-mcp-setup`](#unity-mcp-setup-and-unity-mcp-skill).

### `/task-setup`

Initializes the backlog: creates `.claude/TASKS.md`, the `.claude/tasks/`
directory, and the project's test-dispatch convention under
`.claude/external/` (`run-affected-tests.sh`, `run-full-tests.sh`), which
`/task-implement` calls instead of guessing the test command. Authoring
command: uncommitted by default, `--commit` to commit and push,
`--commit --no-push` to commit without pushing.

### `/domain-setup`

Scaffolds `.claude/domain/`, the counterpart to the context layer: where the
context layer records *codebase structure*, the domain layer records what the
product is, how its features are designed, and why. `/domain-setup` creates
the directory, a `features/` folder, a domain `INDEX.md`, the
`.claude/FEATURES.md` feature index, and a `CLAUDE.md` pointer, then stops.
It never writes design documents; those come from `/product-design` and
`/architect`.

Idempotent and safe to run on an existing project: if you already have
hand-written docs under `.claude/domain/`, it indexes them instead of
replacing them. Leaves everything uncommitted by default; `--commit`
commits and pushes it (`--commit --no-push` to skip the push).

---

## 2. Keeping Claude oriented

### `/context-build`, `/context-update`, `/context-convert`

Build a *navigation layer*: small structured summaries under
`.claude/context/` that let future Claude Code sessions open only the source
files they need, saving tokens. All three ship as **skills**.

- `/context-build` — create the layer once (`/project-setup` can invoke it
  for you). Commits only under `--commit`, and pushes too unless `--no-push`
  is also passed.
- `/context-update` — refresh only the parts the latest diffs touched.
  Commits and pushes automatically; `--no-commit` skips both, `--no-push`
  commits without pushing.
- `/context-convert` — restructure a layer you already have from one layout
  to the other, without rebuilding it from source. Plan-first: it reports
  every move, date decision and link rewrite, then stops for approval (`-y`
  skips the gate). Commits only under `--commit`.

#### Two layouts: flat by default, nested on demand

- **Flat** (the default) — one `.claude/context/INDEX.md` with every context
  file beside it. Nothing to opt into; this is what `/context-build`
  produces when you pass no layout argument.
- **Nested** (opt in with `/context-build nested`, or
  `/context-build nested=api,worker` to name the units yourself) — a *router*
  `INDEX.md` that lists units, plus one *leaf* `INDEX.md` per unit that owns
  that unit's context files. Worth it on a repo big enough that a single
  index is itself an expensive read. Nesting is capped at two levels: router
  plus one rank of leaves.

Each leaf carries its own `Last updated` date, so refreshing one unit does not
make the others look fresher than they are; `/context-update unit=<name>`
scopes a run to a single leaf. The per-file six-section schema, the 150-line
file cap and the snippet cap are identical in both layouts; only *where the
index files live* changes.

A layer declares its own shape with a `Layout: flat` / `Layout: nested` line
directly under the title of `.claude/context/INDEX.md`. Detection is that line
and nothing else: a missing marker means flat, so pre-existing layers keep
working and `/context-update` backfills the marker on its next run.
`/context-build` will not convert an existing layer; that is
`/context-convert`'s job.

---

## 3. Designing the product

### `/product-design`

Brainstorm a product from the ground up with Claude and write the result into
the domain layer: what it is, who it's for, the key flows, the big decisions,
and the high-level feature set described from the user's side, plus a
technical direction (stack, topology, data, hosting) covering the product as
a whole, not feature-by-feature. A business model is optional and opt-in.
Requires `/domain-setup` to have run.

It works on an existing codebase as well as a blank one: it reads what's
there and opens with "here's what I see you've built; is this still the
intent?". The technical-direction round follows the same rule: on an
existing codebase it confirms and records what's already there rather than
re-opening the stack.

Designing a product takes more than one sitting, so the process is
**resumable**: its state lives in `.claude/domain/design-process.md`, not in
the conversation. Run `/product-design` again weeks later and it tells you
where the last session stopped and offers to pick up there. There's no flag
to remember. Before it stops after write-back, it also sweeps the
conversation for anything the written documents don't yet cover and folds
it in automatically, so detail raised in the interview doesn't quietly die
with the session.

On a greenfield project, when PHASE 6 hits a technical fork that genuinely
matters, it can route the decision through the
[council](#claude-council).

The output, including `technical-direction.md`, is `/architect`'s input.
Nothing is committed by default; `--commit` commits and pushes what the run
wrote (`--commit --no-push` to skip the push).

### `/product-roadmap`

Writes `.claude/domain/product-roadmap.md`: an ordered list of milestones,
each with the outcome it delivers (`Goal:`), what makes it shippable
(`Exit criteria:`), why it comes where it does (`Rationale:`), and the
**scope slices** saying which share of a high-level feature it takes on
(`Covers:`). Plus a `Not now` list where every deferral carries the trigger
that would pull it back in, and the sequencing questions you couldn't close.

A slice names a `product-design.md` section and states its scope in prose,
and what really matters is the exclusions: "email and password only; no
third-party providers, no SSO". `§ Authentication` can appear in an early
milestone and again in a much later one, because how a feature splits across
releases is a business call, not an architectural one. `Covers:` is a
*decomposition instruction for `/architect`*, not a promise about what ships,
so a section spread over several milestones is normal and nothing checks that
the slices add up.

Milestone slugs (`m1-mvp`) are stable and never renumbered; order is just
list position, so you can insert a milestone between two others freely. The
roadmap carries **no status, no dates and no estimates**: it records intent,
not progress. It reads `.claude/FEATURES.md` and never writes it. When you
edit a slice whose section has already been architected, it says so and
points you at `/architect <slug>` rather than changing anything downstream.

Requires `/domain-setup`. `product-design.md` is optional: you can draft a
roadmap from a bare description. Re-run it whenever the plan moves. The
document is its own resume state, so a later run proposes changes against
what's already there, behind the same single approval gate. Nothing is
committed by default; `--commit` commits and pushes what the run wrote
(`--commit --no-push` to skip the push).

### `/architect`

Takes a high-level feature and decides how it will actually be built, then
writes that down as a low-level feature document under
`.claude/domain/features/`, indexed in `.claude/FEATURES.md`. One product
feature often becomes several architectural ones.

It grounds the design in `technical-direction.md` when `/product-design` has
recorded one, adopting it exactly like an existing codebase stack: no
re-arguing it, no tech-stack proposal step, just a one-line note that it's
designing within the recorded direction. Otherwise it grounds the design in
the code you already have (reading the context layer first), and proposes a
tech stack only when there isn't one either way. It stops at components,
data, and contracts: no code, no file-by-file plans. Those come from
`/task-add`, which reads the code as it stands at planning time.

You can run it from a `/product-design` feature, from a feature name, or from
a bare description with no design documents at all.

**Slice mode.** If you've written a roadmap, `/architect` doesn't decompose a
whole product feature at once; it architects one *scope slice*, the share of
that feature a single milestone takes on. It switches into this mode purely
on finding `.claude/domain/product-roadmap.md` with a milestone that has a
`Covers:` line; there is no flag to turn on and nothing to configure. The
slice's scope statement becomes the boundary, its exclusions become the
feature document's non-goals, and the milestone is recorded on the
`FEATURES.md` entry as `Source: product-design.md § Authentication (m1-mvp)`.
Every low-level feature then belongs to exactly one milestone.

The choice is made **per feature, not per run**: a section your roadmap
doesn't slice takes the ordinary path even on a roadmapped project, and it
tells you when it does. If a section is sliced across several milestones it
asks which one you mean rather than guessing, and it never architects the
union of two slices. A project with no roadmap behaves exactly as it always
has, silently. Pass `--no-slices` to ignore the roadmap for a run; on a
project without one, the flag does nothing.

Re-architecting a feature that already produced tasks is guarded: if any of
those tasks is `[IN PROGRESS]` it refuses outright, and otherwise it asks
before marking the surviving tasks `[STALE]` and the feature `[ITERATED]`,
then tells you to reconcile with `/task-add feature=<slug>`.

**Amending instead of re-architecting.** `/architect amend feature=<slug>
"<change>"` makes one targeted change to one feature document and skips the
clarify and architecture phases, because the change is described, not
designed. The change has to name the sections it lands in, or quote a
passage that lives in them. A change it can't pin to named sections is
refused, with a pointer to `/architect <slug>`. When the change moves a
decision `product-design.md` records, the matching high-level edit is
drafted there too.

It then runs a **precision guard** in place of the blanket one. Each
unfinished task is classified as touched or untouched by the change, from its
title and `Files:` line alone. Its body is opened only when those can't
decide, and a task still undecided after that counts as touched. Only a
*touched* `[IN PROGRESS]` task refuses the amendment, where the blanket guard
refuses on any. Only the touched tasks go `[STALE]`, where the blanket guard
stales every unfinished one. `[DONE]` and `[SKIP]` tasks are never looked at.

There is exactly one gate. It shows the drafted edit and the touched set,
with the untouched live tasks listed too so you can overrule a
classification, and the outcome of each answer. Then it asks the **editorial
question**, on every amendment and never inferred: is this change wording
only, with nothing any task builds changing?

- *Editorial* edits the document, stales nothing, and leaves the feature's
  status where it was.
- *Not editorial* stales the touched tasks. It moves the feature to
  `[ITERATED]` when anything was staled or when the change adds scope no
  existing task covers.
- *Stop* writes nothing.

A `[NEW]` feature has no tasks, so it gets no guard, but it still gets the
question and stays `[NEW]` either way. An amendment writes no progress
marker, and `--commit` / `--no-push` work as on any other run.

At a genuine design fork (the stack choice, the shape of the architecture,
or where the low-level split falls) it can route the decision through the
[council](#claude-council).

Nothing committed by default; `--commit` commits and pushes exactly the
written paths (`--commit --no-push` to skip the push).

### `claude-council`

`/product-design` and `/architect` both reach forks where two or three
options are genuinely defensible and the wrong pick is expensive to undo.
Both can hand that decision to `claude-council`: a skill that runs the
question through five thinking lenses (Red Team, First Principles,
Expansionist, Outsider, Executor), peer-reviews them anonymously, forces an
adversarial debate when the consensus looks too clean, and returns a verdict
that keeps any minority dissent intact.

chosko-llm ships it, vendored from the upstream project
[TorpedoD/claude-council](https://github.com/TorpedoD/claude-council). Credit
and the design are theirs; this repo carries a copy so it installs and
upgrades like any other feature:

```sh
chosko-llm add skill:claude-council
```

It's **entirely optional**: shipping is not installing. When it's installed,
the two commands offer to convene it at a real fork and wait for your yes.
When it isn't, they say nothing and behave exactly as they always have. No
prompt, no warning, no missing-dependency error.

It needs `jq` on your `PATH`: the council's journal append (Step 10) and
`/claude-council meta` both use it. The rest of the run works without it.

- **The council advises; you still decide.** Its verdict feeds the
  recommendation you're shown. `/architect` still won't leave PHASE 2 without
  your confirmation, and `/product-design`'s PHASE 6 still ends when you say
  it ends.
- **Dissent is kept, not resolved.** A minority view that survives the
  synthesis lands in the feature document's open questions, or in
  `product-design.md`'s design decisions, recorded as a live concern rather
  than quietly dropped.

The council writes its own HTML report and markdown transcript into the
working directory. Neither command commits them or deletes them; you're told
where they landed and can keep or bin them.

---

## 4. Planning the work

### `/production-plan`

Writes `.claude/PLAN.md`: a third index beside `TASKS.md` and `FEATURES.md`
saying which low-level feature belongs to which milestone, **in what order**,
and after what. The roadmap says which outcomes come first; this says which
architected features that implies and which one you can actually start.

Each milestone block carries a `Status:`, a derived `Covers:` line, and an
ordered `Features:` list, and that order **is** the priority. There is no
`P0`/`P1` label, no size, no estimate and no date, because a second ordering
alongside the list would eventually contradict it. Everything not yet placed
sits in an `Unscheduled` block. All the dependency edges live in one flat
`## Dependencies` list at the foot of the document, where a cycle is visible
to a human reader.

A feature's milestone is **inherited, not guessed**: it comes from the
parenthetical `/architect` writes on the `FEATURES.md` `Source:` line
(`… § Authentication (m1-mvp)`). Features architected without a roadmap start
in `Unscheduled`. You can place any feature by hand and that wins; an
override is reported plainly at the approval gate, never refused.

The edges come from prose. Each feature document already has a
`## Dependencies` section; the skill proposes the edge set it implies, you
confirm or edit it, and `PLAN.md` stores the result. The prose stays the
human-facing statement and is never rewritten, which is also what lets you
record an edge the documents never stated.

Then it **refuses the two arrangements that cannot be built**: a dependency
cycle (reported as the actual cycle path, with no override flag) and a feature
scheduled before something it needs (reported with both features and both
milestones). Validation runs before anything is written.

Milestone status is `[PLANNED]` / `[ACTIVE]` / `[SHIPPED]`, at most one
`[ACTIVE]` at a time. `[SHIPPED]` is only ever *proposed*, when every feature
in the milestone is `[PLANNED]` and all their tasks are `[DONE]` or `[SKIP]`,
and it never reopens; follow-up work is a new milestone.

Requires `/domain-setup` and at least one architected feature. A roadmap is
**optional**: without one everything lands in `Unscheduled` and the dependency
ordering still works. Re-run it whenever features or milestones move; it
reconciles against the current `FEATURES.md` and roadmap behind the same
single approval gate, keeping the orderings and edges you set. It is the sole
writer of `PLAN.md` and reads `FEATURES.md`, the feature documents, the
roadmap and `TASKS.md` without writing any of them. Nothing is committed by
default; `--commit` commits and pushes what the run wrote (`--commit
--no-push` to skip the push).

### `/production-status`

Reports what to build next by joining `PLAN.md`, `FEATURES.md` and `TASKS.md`:
the active milestone with its roadmap goal and exit criteria, its features
in plan order with their task rollup and a Next column naming the one concrete
action each needs, the ready set, the single recommended next feature,
blocked features named with their blocker, coverage gaps, features missing
from the plan, and the remaining milestones. It writes nothing.

The plan says what belongs where and in what order, `FEATURES.md` says whether
a feature's tasks match its design, and `TASKS.md` says whether the work is
done. The useful answer is in the join of the three and in none of them alone,
so this command computes it **on every read** and stores nothing:

- **Ready** — every dependency edge pointing at the feature comes from a
  feature that is `[PLANNED]` with all of its tasks `[DONE]` or `[SKIP]`. No
  dependencies means ready.
- **Blocked** — anything else, and always *named with what blocks it* and why,
  so a blocked list is somewhere to go rather than a dead end.
- **Recommended** — the first ready feature in plan order. Exactly one, and
  the command stops there: it reports the next thing to build, it doesn't
  start it.

The **Next** column names one action per feature: `/task-add feature=<slug>`
for a feature not yet planned, `/task-implement <N>` when work is left and
nothing blocks it, `blocked by <slug>` when a dependency does,
`flip to [DONE] in FEATURES.md` when every task is finished, and `-` on a
feature already `[DONE]`. `<N>` is the first of the feature's open tasks in
backlog order (the order of `TASKS.md`, not the id) whose `Preconditions:`
are all `[DONE]` or `[SKIP]`, the same rule `/task-implement next` follows,
so the report and `next` agree. When every open task of an unblocked feature
waits on something unfinished, Next reads `waits on task <id>` instead,
naming what to finish first.

Task rollups are counts per status by default (`4 tasks — DONE: 2, MISSING:
2`); pass `--task-ids` to name each task instead. `milestone=<slug>` reports a
named milestone rather than the active one.

Staleness is **structural, not temporal**: rather than checking dates, the
report simply names every `FEATURES.md` slug missing from `PLAN.md` and points
you at `/production-plan`. A plan that has fallen behind says so by having
gaps.

Nothing here refuses. No roadmap drops the goals and exit criteria, no
`TASKS.md` drops the rollups, no active milestone reports the first planned
one, and a dependency edge naming a feature that doesn't exist is reported as
a plan inconsistency with the feature treated as ready, failing open, because
a hand-edited plan must never make the report claim there's nothing to do. The
only thing it won't do is run without a `PLAN.md`, and then it tells you to
run `/production-plan`.

Read-only in the strict sense: no writes, no commits, no shell commands, and
it never opens a task body under `.claude/tasks/`.

### `/pipeline-check`

Reports **structural drift** across the pipeline's indexes: `FEATURES.md`,
`TASKS.md`, `PLAN.md` and `RUNBOOKS.md`. Drift here means a reference between
two indexes that doesn't resolve, or an index state its owner hasn't acted on
yet. Whether a feature document still describes what its tasks build is a
judgement, not structure, and this command doesn't attempt it.

The catalogue is closed. It has eleven findings and no others:

| Severity | Finding | Fix it names |
| --- | --- | --- |
| `ERROR` | a task's `Feature:` slug has no entry in `FEATURES.md` | `/pipeline-patch` |
| `WARNING` | a task has no `Feature:` line, on a project that has a `FEATURES.md` | `/pipeline-patch` |
| `ERROR` | a `Preconditions:` id was never assigned (it is above `Last task number:`) | `/pipeline-patch` |
| `ERROR` | a `Preconditions:` id names a `[SKIP]` task | `/pipeline-patch` |
| `ERROR` | a precondition cycle | `/pipeline-revise` |
| `WARNING` | an `[ITERATED]` feature, whose backlog hasn't been re-planned | `/task-add feature=<slug>` |
| `WARNING` | a `[STALE]` task | `/pipeline-revise` |
| `WARNING` | a `FEATURES.md` slug that appears nowhere in `PLAN.md` | `/production-plan` |
| `ERROR` | a `PLAN.md` line naming a slug that isn't in `FEATURES.md` | `/pipeline-patch` |
| `WARNING` | a runbook still `[PENDING]` with every step done (`Steps: <n>/<n>`) | `/pipeline-patch` |
| `WARNING` | a `[PLANNED]` feature whose every task is `[DONE]`, `[SKIP]` or archived | `flip to [DONE]` |

`ERROR` means something a pipeline command will act on wrongly if it's left;
`WARNING` means a legal state that needs its owner's attention.
`/pipeline-patch` and `/pipeline-revise` are the pipeline's revision
commands; see [`/pipeline-patch`](#pipeline-patch) and
[`/pipeline-revise`](#pipeline-revise) below.

Two things are deliberately **not** findings. A feature's `Tasks:` id with no
`TASKS.md` block is an archived task (the normal state of a feature after
`/task-clean`), and a precondition on an archived id counts as satisfied. A
pending runbook step naming a task that is already finished would need a
runbook body opened to detect, and no finding opens one; `/runbook-run`
prints each step before running it, which is where that shows up.

A clean project prints one line naming the indexes it read. Otherwise the
findings print grouped by artifact (`FEATURES.md`, `PLAN.md`, `TASKS.md`,
`RUNBOOKS.md`), one line each with its severity, the offending task, feature
or runbook, and its fix, closing on a count of both severities. There is no
exit code to gate on, no `--fix` and no `--quiet`.

`feature=<slug>` narrows the report to that feature: its own entry, the tasks
that name it or that its `Tasks:` line lists (with their precondition
findings), and the plan lines that name it. Runbook findings are out of scope
there, because `RUNBOOKS.md` doesn't tie a runbook to a feature. An unknown
slug is reported in one line and the full report runs instead.

Nothing here refuses except a project with none of the four indexes, which is
pointed at `/task-setup` and `/domain-setup`. An absent index simply drops its
findings, a block it can't read is reported as an `ERROR` of its own, and an
argument it doesn't recognise is named and ignored.

Read-only in the strict sense: no writes, no commits, no status flips, and no
fixes. It never opens a file under `.claude/tasks/` (the archive included),
`.claude/runbooks/` or `.claude/domain/features/`, and the only shell command
it runs is the engine's probe of the project's setup. It runs when you invoke
it; no pipeline command runs it for you. Requires `skill:pipeline-engine`
(see [`pipeline-engine`](#pipeline-engine)), which `chosko-llm add` installs
with it.

### `/task-add`

Plan a task and write it down. Invoke it with a very short description, let
Claude investigate and expand it conversationally: it asks every question
needed to fill the gaps, then writes everything down for later
implementation. It may propose splitting the description into several tasks
when that gives better units (independent deliverables, or one task that's
too large); pass `--no-split` to always get exactly one task.

`/task-add feature=<slug>` plans from an `/architect` feature document
instead of a description. The document is the input, so you don't re-explain
the work in prose; a feature usually becomes several tasks. Run it again after
re-architecting and it *reconciles* rather than duplicating: each existing
task is either left alone, updated in place, or skipped with a reason and
replaced, and `[DONE]` tasks are never touched. When the run drafts any new
task, it appends one more at the end to update the affected documentation
once the others land. You approve the whole plan, reconciliation included, in
one pass.

New tasks go at the end of `TASKS.md` by default. **`--before <N>`** writes
the new task immediately above task N and adds its id to N's
`Preconditions:`; **`--after <N>`** writes it immediately below task N and puts
N on the new task's `Preconditions:`. Each flag always writes the position and
the edge together: the position is for whoever reads the file top to bottom,
the edge is what `/task-implement next` and `all` follow, and either one alone
would leave the two disagreeing. The two flags are mutually exclusive, and an
N that names no task stops the run before anything is written. No existing id
changes, so a higher id sitting above a lower one is expected. When the run
writes several tasks (a split, or a feature's drafts), the flag places the
first and the rest follow it.

**`feature=<slug> --single "<description>"`** attaches exactly one task to a
`[PLANNED]` feature without re-planning it. The task is planned against the
feature document, tagged `Feature: <slug>`, and its id is added to the
feature's `Tasks:` line; nothing else about the feature changes. No
reconciliation runs over its other tasks, its status stays `[PLANNED]`, and
no documentation task is added. The feature document isn't updated either,
and the report says so in one closing line naming
`/pipeline-patch feature=<slug>` as the write-back, so the drift is announced
the moment it's created. `--single` needs `feature=<slug>` and can't be
combined with `--short`.

On a project with a `.claude/FEATURES.md`, a free-form `/task-add` also asks,
at its usual approval step, whether the task belongs to a feature, listing
every `[PLANNED]` one with *none* as the default. Naming a slug takes the
`--single` path; *none* writes the task exactly as before. A project without a
feature index never sees the question.

Tasks can be **human-in-the-loop**: when part of the work only a human can
perform in an external tool (a Unity editor step, a cloud console, hardware),
`/task-add` marks the task `Target: claude+human` (or `human` for fully
manual work) and records the checkpoints in a `## Manual interventions`
section.

Commits and pushes automatically (`--no-commit` to skip both, `--no-push` to
commit without pushing).

### `/pipeline-patch`

Applies a change that touches **exactly one** feature document, task or
runbook step through that owner's amend step, then re-checks it. Anything
else it refuses.

```
/pipeline-patch <anchor> "<change>" [--commit] [--no-push]
```

The anchor is required, in one of three forms:

- `feature=<slug>` — an entry in `FEATURES.md`;
- `task=<N>` — a live summary block in `TASKS.md`;
- `runbook=<name|id> step=<n>` — one step of a runbook listed in
  `RUNBOOKS.md`.

An anchor that resolves to nothing stops the run and lists what exists. A
task id that has been archived is reported as archived; one that was never
assigned is reported as that.

It decides from the indexes alone (`FEATURES.md`, `TASKS.md`, `PLAN.md`,
`RUNBOOKS.md`) and never opens a task body, a feature document or a runbook
body. The **single-owner rule** is a count and a checklist, not a judgement
about whether the change feels small. It goes ahead only when the change
writes exactly one owner and none of these five structural signals is
present:

1. more than one owner;
2. a dependency edge changing: an id added to, dropped from or re-pointed on
   a `Preconditions:` line, or a plan dependency moving;
3. scope added that no task covers: a new promise in a feature document that
   no live task answers to, or any new task at all;
4. a deletion that crosses artifacts: removing a task another line points
   at, or a whole feature;
5. a reorder of existing entries.

Writes an owner's amend step makes as its own consequence, such as the
`[STALE]` flips `/architect amend` makes, don't count as a second owner.

When it goes ahead, it loads the owner's amend step by path and runs it with
that step's own approval gate. That step is `/architect amend` for a
feature document, `task-engine`'s `references/amend.md` for a task, and
`runbook-run`'s `references/step-amend.md` for a runbook step. Then it runs
`/pipeline-check` scoped to the anchor: the feature itself, the task's
feature for a task anchor, or unscoped for a runbook step. When it refuses,
it prints one line and stops:

```
Not a patch — <signal>: <what in the change set it off>. Run /pipeline-revise <anchor> "<change>".
```

There is no escalation and no second question, and nothing is written. A
change that writes none of the three owners, only a line another command
owns (a milestone's order in `PLAN.md`, say), is refused too, naming that
line's owner.

It makes no commit of its own. `--commit` and `--no-push` are passed on to
the amend step, which then commits exactly what it wrote; without `--commit`
nothing is committed and the report reminds you. Requires
`skill:pipeline-engine`, `skill:architect`, `skill:task-engine` and
`skill:runbook-run`, which `chosko-llm add` installs with it.

### `/pipeline-revise`

The heavier tool, for a change that reaches more than one artifact: new
scope, a task or runbook step inserted, removed or moved, or a dependency
edge changing. It traces the change's impact, proposes one plan, then runs
each owner's own step in order. It writes nothing itself.

```
/pipeline-revise [<anchor>] "<change>" [--commit] [--no-push]
```

The anchor takes the same three forms as `/pipeline-patch` and is optional.
Without one, the change itself must name exactly one feature slug, one task
id, or one runbook together with a step, and the skill says which it picked.
If the change names none, or more than one, the skill stops and lists what
exists; it never picks between two.

**Four branches.** Each request is classified into exactly one branch,
tested in this order, and only that branch's instructions are read:

- **reorder** — an existing task or runbook step is to run at a different
  position. This is done as skip-and-insert: the old entry is marked `[SKIP]`
  (or struck) with a reason naming the move, and a replacement goes in at the
  new place under a new id. Nothing is renumbered.
- **delete** — a live task, a pending runbook step or a whole feature is to
  stop being work. A task becomes `[SKIP]` with a dated reason, the
  `Preconditions:` edges its successors had on it are dropped with that
  reason recorded, and its feature document stops promising it. A runbook
  step is struck. For a feature, every live task is skipped and
  `/production-plan` drops its edges, while its `FEATURES.md` entry stays.
  `[DONE]` work is never touched, and actually removing anything stays
  `/task-clean`'s and `/runbook-clean`'s job.
- **insert** — a new task or runbook step is to exist. This is the case the
  skill was built for: `/architect amend` writes the new scope into the
  feature document first, `/task-add feature=<slug> --single --after <N>`
  attaches and places the task, the successors' `Preconditions:` gain its
  id, and `/runbook-create --append --after <n>` inserts the step that runs
  it.
- **amend** — anything else that changes what already exists, including a
  `Preconditions:` change that moves no entry. Owners run upstream first: a
  `product-design.md` decision, then each feature document, then each task,
  then each runbook step.

A request of two kinds is two runs: the skill does the first and tells you
the rest is a separate run.

**The impact walk.** From the anchor it follows the links between the
indexes in both directions: down from a feature document to its tasks, its
plan edges and the runbook steps that name them, and up from a task to the
feature document that promised it, when the task's `Feature:` resolves.
Unlike `/pipeline-patch` it may open bodies, but only within the anchor's
scope: the target itself, the tasks whose `Preconditions:` name it or whose
`Files:` overlap with it, and the runbook steps that name it. It never reads
the backlog in bulk.

**Lint before and after.** `/pipeline-check`, scoped to the anchor, runs
before the plan is built, so the plan starts from the true state. It runs
again after the steps have run, even when they stopped part-way, and the
report shows the difference: findings cleared, findings created, findings
unchanged. Where an insertion or a deletion changed a precondition, the
skill also reads the successor tasks' bodies afterwards to confirm the
sequence still reads as a sequence, and reports any gap without fixing it.

**Three tiers.** The plan names one:

- **editorial** — wording only, nothing downstream changes meaning. Only the
  step that writes the anchored artifact runs.
- **local** — the artifact plus the entries that merely cite it. No status
  moves and no edge changes.
- **structural** — the scope changes, or the contract of something
  downstream does. The full sequence the walk reached runs. A reorder is
  always structural.

**One gate.** Nothing is written before it. It shows the probe's verdict
line, the anchor, the branch and the tier, and every touched artifact with
how it was reached. The artifacts judged untouched are listed too, so you
can overrule the call. It numbers the owner steps in order and shows which
`/pipeline-check` findings each is expected to clear or create. Then it asks
the **editorial question**, on every run and never inferred: is this change
wording only, with nothing downstream changing meaning?

- *Editorial* runs the short sequence.
- *Not editorial, here* runs the full sequence in this session.
- *Not editorial, as a runbook* hands the full sequence to `/runbook-create`
  and stops.
- *Stop* writes nothing.

The runbook option is offered only when the sequence has **four or more**
owner steps and `/runbook-create` is installed; otherwise it simply isn't
shown. Three steps or fewer always run in the session. You can overrule the
tier or a touched/untouched call in the same answer, and the gate is shown
again.

**Running the steps.** One at a time, in order, never in parallel and never
in a subagent, each with its owner's own approval gate intact. If an owner
refuses (a touched `[IN PROGRESS]` task, say), or you stop at an owner's
gate, the sequence ends there. Earlier steps' writes stay and are reported,
never rolled back, and the lint after still runs. A step whose owner isn't
installed stops the run before the gate.

It makes no commit of its own. `--commit` and `--no-push` are passed on to
each owner step. An amend step commits its own writes; `/product-design`,
`/production-plan` and `/runbook-create --append` get `--commit`; and
`/task-add`, which commits by default, gets `--no-commit` when you didn't
pass `--commit`. Requires the same four skills as `/pipeline-patch`.

### `pipeline-suggest`

A skill nobody invokes. Most requests that belong in the pipeline arrive as
prose, not as a command: "add a login to the page", "fix this bug", "drop the
export step". When one does, `pipeline-suggest` fires on its own description,
names the pipeline command that fits in a line or two, and stops. The
conversation carries on exactly as it would have.

**When it fires.** Its description is the whole trigger: there is no hook,
no event registration and no flag. It fires on a free-form request to build,
change, fix, remove or sequence work that doesn't already name a slash
command. It stays out of the way for:

- a question;
- a request that names a command;
- a request that says "just do it" or "directly";
- work already under way in a `/task-implement` run;
- an enumeration inside an explanation;
- a list of follow-ups meant for later sessions, which is `runbook-suggest`'s;
- a project with neither a feature index nor a backlog.

If it fires too often, the fix is a narrower description, never a setting.

**Two probes, nothing more.** It checks whether `.claude/FEATURES.md` exists
and whether `.claude/TASKS.md` exists. When neither does, it says nothing. A
probe that errors counts as absent. It never opens either file, and it reads
no reference file, `pipeline-engine`'s `probes.md` and `routing.md`
included: it needs to know whether a pipeline exists, not its shape.

**Which command.** A fixed table in its body maps the shape of the request to
a command:

| Request shape | Command |
| --- | --- |
| A new capability or a feature-sized addition | `/architect` |
| A bug, a small change or a chore | `/task-add` |
| A small change to something already planned | `/pipeline-patch` |
| A large change, an insertion at a point in the sequence, a deletion or a reorder of planned work | `/pipeline-revise` |
| "What should I build next" | `/production-status` |
| "Is the backlog consistent" | `/pipeline-check` |
| An ordered list of follow-ups | none — `runbook-suggest` already fires |
| A design-level decision | `/product-design` |
| A milestone or release question | `/product-roadmap` or `/production-plan` |

It isn't `pipeline-engine`'s routing table, which records what each feature
consumes, produces and owns. The two do different jobs.

**What it prints.** Nothing, when the request matches no row or only the
follow-up row. Otherwise **two lines at most**: the first names the command
(both, when two rows match) and quotes the phrase in your request that
matched; an optional second says you can go ahead directly instead. It
restates nothing of what you asked, and no failure adds a third line.

It **never invokes** the command it names, **never asks** a question or gates
anything, and **never writes**. It keeps no memory of having suggested,
deliberately, since a suppression list would be a state file: a repeated
request earns a repeated line. Requires `skill:pipeline-engine`,
`skill:pipeline-revise` and `command:pipeline-patch`, which `chosko-llm add`
installs with it. The other commands its table names aren't required; a
project with a feature index or a backlog is already using them.

---

## 5. Building and reviewing

### `/task-implement`

Build a task end-to-end, test-first, one commit (and push) each.

Name tasks by number, or pass `next` or `all`. `next` implements the first
eligible task in backlog order and `all` works through every eligible one.
Both honour `Preconditions:`: a task is eligible only once every task it
names is `[DONE]` or `[SKIP]`, and `all` is `next` repeated, so it never
starts a task ahead of one it waits on. An `all` run names by id any task it
left blocked, a precondition cycle included, and between tasks skips, with one
line, a task whose preconditions no longer hold. A task you name by number is
never blocked: naming it is choosing its moment.

Pass `--review [--rounds N]` to have each task reviewed before it's
committed: after the tests and before the status flip, the run spawns
`/task-review` in a fresh subagent, waits for its findings, and runs
`/task-iterate` in the session to triage and apply them. The fixes ride in
the task's own single commit. The reviewer's cost is steerable with
`--review-model <name>|same|auto` and
`--review-effort shallow|standard|deep|same|auto` (both default `auto`, and
both require `--review`): `auto` resolves the model and the read budget
deterministically, per task, from that task's own diff. A light diff (a few
small files, nothing executable) gets a cheaper Sonnet reviewer on the
`shallow` budget, and only a heavy one gets Opus on `deep`, while `same` on
either axis restores the inherit-the-implementer behaviour (no `model:` on
the spawn, no budget at all). The resolved pair is reported per task, so
`auto` is auditable rather than magic.

When a feature-derived task finishes the last task for its feature, it
proposes, once, at the end of the run, flipping that feature to `[DONE]` in
`FEATURES.md`; you decide. A many-task run batches every feature it finished
into one proposal at the very end, never one per task.

On a human-in-the-loop task it pauses at each checkpoint, walks you through
the manual step, and verifies the outcome itself (the promised file exists,
the project compiles) before moving on; saying "done" isn't enough.

On a Unity project set up with
[`/unity-mcp-setup`](#unity-mcp-setup-and-unity-mcp-skill), those
checkpoints can flip around: when the `UnityMCP` server is connected,
`/task-implement` makes the editor changes itself (checking the Console after
compilation and creating GameObjects, components, and references via MCP),
then hands you a *verification* step ("I created Foo under Bar — confirm you
see it") instead of an instruction. It asks once per task whether you want it
to drive Unity or pause for you to do the steps manually, and steps MCP
genuinely can't perform stay manual. When the server isn't connected, the
standard manual protocol runs unchanged.

Commits and pushes once per task (`--no-commit` to skip both, `--no-push` to
commit without pushing).

### `/task-review`

Audit a diff against the acceptance criteria of the task that produced it.
Three input forms: no argument reviews the uncommitted tree, a branch name
reviews that branch against the repo's default branch (`base=<ref>`
overrides), a PR number or URL reviews that pull request through `gh`.

It reports only findings it holds at 80% confidence or better, each citing a
`file:line` and a concrete failure mode, at `BLOCKING` / `IMPORTANT` /
`ADVISORY`. An unmet acceptance criterion is always blocking, and finding
nothing is a valid, complete review.

A run spawned by `/task-implement --review` may carry a **read budget**
naming a tier (`shallow` / `standard` / `deep`), and it honours it: the
navigation layer (`CLAUDE.md`, the context layer, the task body, the feature
document) is read in full and never counted at any tier, only distinct source
and test files beyond the diff count against the cap, and a cap that actually
binds is reported in one line so it can be retuned. Under `shallow` the
reviewer says plainly that it could not read callers, which the confidence
gate then uses to demote or drop the finding: a cheaper review is a more
conservative one, never a more confident-and-wrong one. A manual run, and a
spawn whose `--review-effort` resolved to `same`, carry no budget and read
unbounded; the skill has no cost-control flags of its own.

It **invokes no test command**, in any mode, under any budget, under any
testing policy, on either invocation path: a green suite is an input its
caller hands it, and where the caller reports skip-tests mode it says nothing
ran and marks a criterion that depends on runtime behaviour `unverifiable`
rather than re-deriving it. Read-only: it never edits, never commits, and
never opens a PR.

### `/task-iterate`

Triage the findings `/task-review` produced, apply the ones that survive, and
record why the rest didn't. Every finding gets exactly one of `fix`, `defer`
or `reject`, written out in full before the first edit. That table is the
point of the skill, and its rejections travel into the next review round as
binding context so a rejected finding can't simply be re-raised. It never
invents a finding of its own.

Run standalone it commits and pushes like the rest of the suite, but run
*inside* `/task-implement --review` it commits nothing and leaves the
corrected tree for that run's own commit step. Otherwise a reviewed task
would land an implementation commit plus a separate fix commit for work
nobody reviewed separately; this way a task stays at exactly one commit,
reviewed or not.

### `/task-list`

Show what's pending, optionally filtered by status. Human-in-the-loop tasks
are marked with a ⚠ so you know they need you present.

On a project with a `.claude/PLAN.md` it groups the backlog **by milestone in
plan order**, resolving each task's `Feature:` slug through the plan, and
flags any task whose feature is blocked with `⚠ blocked by <slug>` alongside
the existing markers; tasks with no feature, or one the plan doesn't list,
fall under a trailing `Unplanned` heading. With no plan, the output has no
grouping, no flags, and no message about the missing plan.

### `/task-clean`

Clear finished tasks out of the backlog without losing them. By default it
takes the terminal statuses, `[DONE]` and `[SKIP]` only; name statuses to
prune those instead (`[STALE]` is never in the default set, and naming a
non-terminal status is flagged in the plan). Each task's summary block leaves
`TASKS.md` and its body **moves** to `.claude/tasks/archive/<N>.md` — a
`git mv`, so history follows the file — under a frozen header: an `Archived:`
date plus the `Status:`, `Files:`, `Preconditions:` and (when it had one)
`Feature:` lines its summary block carried at that moment. No body is
deleted, no id is renumbered or reused, and survivors' `Preconditions:` drop
the archived ids, since an archived precondition is a satisfied one. It shows
the plan, naming each destination, and asks before writing anything; a
destination that already exists is refused rather than overwritten.

A prune never touches `.claude/FEATURES.md`. A feature keeps every task id it
ever generated on its `Tasks:` line, so `Tasks: none` means the feature was
never planned. An id that a feature, a precondition or anything else names
but `TASKS.md` no longer holds is archived and terminal.

**Nothing lists or reads the archive.** No command traverses
`.claude/tasks/archive/`, so it costs a session nothing; an archived task is
read only when you name it and ask to see it. `/task-implement <N>` on an
archived id stops and names the path instead of opening it, and
`/production-status` counts such ids as `archived: N` from their absence
alone.

**`--backfill`** recovers what earlier `/task-clean` runs deleted, for a
project that pruned before the archive existed. It finds every task body git
history records as deleted, restores each from the deleting commit's parent
into the archive under the same frozen header (dated to the deletion), and
puts each id back on its feature's `Tasks:` line — the one `FEATURES.md`
write the skill makes. It can't be combined with a status set, plans and asks
the same way, says there is nothing to recover on a second run, and stops on
a project whose version control isn't git.

Commits and pushes by default (`--no-commit` / `--no-push`), as
`task-clean: archive tasks <N>, …` (or `task-clean: backfill <N> archived
tasks`). It is a skill now (`skill:task-clean`); installing or updating it
retires the old command copy.

### `task-engine`

The rules the task features share (how a task is resolved from `TASKS.md`,
where an archived task lives and what an id missing from `TASKS.md` means,
what each status means, what `Target:` gates, how `[STALE]` is handled, the
dirty-tree prompt, how commits and pushes are gated, and the review cost
controls behind `--review-model` / `--review-effort`) live once, in the
`task-engine` skill, and each feature references them instead of restating
them. `task-engine` is not a command you invoke; it is a reference library
the others read while they run. `/task-add`, `/task-list`, `/task-clean`,
`/task-implement` and `/task-review` all declare
`requires: skill:task-engine`, so installing any one of them installs the
engine too, and `chosko-llm rm skill:task-engine` refuses while any of them
is still installed.

An eighth reference file, `references/amend.md`, holds the rules for
changing one existing task in place. It refuses a task that is
`[IN PROGRESS]`, `[DONE]` or `[SKIP]`. It sends a change to what the task's
feature promises through `/architect amend` instead. It deletes a live task
only by marking it `[SKIP]` with a reason, and it requires a dropped
`Preconditions:` edge to be explained in the task's `## Decisions`. No
`task-*` command reads it itself: `/pipeline-patch` and `/pipeline-revise`
read it by path whenever they change a task.

### `pipeline-engine`

What the pipeline features need to know about the pipeline *as a whole* lives
once, in a second reference skill beside `task-engine`: `pipeline-engine`.
Four reference files, each the single authority for its rule:

- `references/probes.md` — the cheap filesystem probes that describe a
  project's pipeline setup (which indexes exist, whether the roadmap is
  sliced, the testing-policy marker, which pipeline features are installed),
  the one-line verdict every consumer prints, and when a verdict already in
  the conversation may be reused;
- `references/graph.md` — how `FEATURES.md`, `TASKS.md`, `PLAN.md` and
  `RUNBOOKS.md` point at each other, and which links vanish when an index is
  absent;
- `references/routing.md` — one row per pipeline feature: what it consumes,
  what it produces, which lines it owns, its preconditions, its argument
  shape, and where its amend entry is. Those entries are
  `skills/architect/amend.md` for `/architect`,
  `skills/task-engine/references/amend.md` for `/task-add`'s task lines,
  `skills/runbook-run/references/step-amend.md` for both runbook writers,
  and the resume menu's amend arm for `/product-design`. `/product-roadmap`
  and `/production-plan` have none by design, because each one diffs and
  proposes on every run. Every other feature's entry is `—`;
- `references/lint.md` — the drift catalogue `/pipeline-check` evaluates.

Like `task-engine`, `pipeline-engine` is **not invocable**: it takes no
arguments, runs nothing and produces no output, and nothing should suggest
it. It's a reference library that other features read while they run.
`/pipeline-check`, `/pipeline-patch`, `/pipeline-revise` and
`pipeline-suggest` declare `requires: skill:pipeline-engine`, so installing
any of them installs the engine too, and `chosko-llm rm skill:pipeline-engine`
refuses while any of them is still installed. (`pipeline-suggest` reads none
of the four files; it declares the engine so it installs with it, and so it
has a routing row.) The two engines sit side by side; neither absorbs
the other.

### Stale tasks

Tasks generated from a feature document carry a `Feature: <slug>` line and
can go **stale**: if the feature is re-architected afterwards, its unfinished
tasks are flipped to `[STALE]`, meaning the spec may no longer match the
design. A default `/task-clean` never archives a stale task; they're live work
awaiting reconciliation, normally by re-running `/task-add feature=<slug>`.
`/task-implement` warns before starting one and lets you implement it anyway
or stop; `all` and `next` skip them so a batch run never guesses.

### Commit behaviour across the suite

`/task-add`, `/task-clean`, `/task-implement`, and `/task-iterate` commit
automatically and then push, once per task for `/task-implement` (pass
`--no-commit` to skip both, or `--no-push` to commit without pushing).
`/task-review` commits nothing at all; it is read-only by contract.
`/task-setup` only commits under `--commit`, at which point it pushes too
(`--commit --no-push` commits without pushing). `/task-iterate` inside
`/task-implement --review` is the one exception, described above.

---

## 6. Working across sessions

### The `runbook-*` commands

A design conversation ends with seven follow-up prompts. Run them in one long
session and step 6 drifts from step 1's framing; save them for later and they
stop making sense, because each one leaned on a decision made an hour earlier
and written down nowhere. A **runbook** is that list made durable: an ordered
set of self-contained prompts, each written to be executed by a *fresh* agent
that has none of the conversation the prompts came out of.

- `/runbook-create` — author one from the conversation you're in (the
  default: the decisions, the rejected options and the verified probes are
  all still in context), or from a free-form description through one batched
  interview. `--append <name>` adds steps to an existing runbook, including
  one a run is in the middle of; `--append` with no name targets the runbook
  this session is running. Appended steps go at the foot unless
  `--before <step>` or `--after <step>` places them at that step's position
  instead (the two can't be combined, and an unknown step id is answered with
  the runbook's step list). Either way they take the next unused step id: a
  step's number is a stable id, not its position, so a runbook may list step
  6 above step 3. No existing step is edited, moved or renumbered.
- `/runbook-run <name>` — execute it, one step at a time, top to bottom in
  list order. `--from N`, `--to N`
  (they compose: `--from X --to Y` runs that range, inclusive), `--only N` and
  `--model <model>` narrow or redirect the run; the bounds name steps by id
  and cut the list at those steps' positions. `--relay-spawns` forces the
  spawn relay described below. A run that stops at its `--to` bound leaves
  the runbook `[PENDING]`, never `[DONE]`: a bounded run leaves work behind
  by design.
- `/runbook-list` — every runbook as one line: id, status, name, steps done
  over total, created date, source, and its one-line title.
- `/runbook-describe <name|id>` — one runbook in depth: the header, and every
  step with its marker, dependencies, whether it needs a person, and the
  `Done:` line a run wrote for it. The one read-only runbook command that
  opens a body, and it opens exactly one.
- `/runbook-clean` — delete finished runbooks, planning and confirming first.
- `runbook-suggest` — a skill nobody invokes. It fires on its own description
  when a conversation produces a list worth capturing, points at
  `/runbook-create` in one line, and stops.

Every command that takes a runbook name takes its **id** instead: a bare
number, as with tasks. A kebab-case name is never all digits, so the two
can't be confused: `/runbook-run 3` and `/runbook-run ecc-import-landing` are
the same command.

The store is committed, like the backlog: `.claude/runbooks/<name>.md` per
runbook, plus a `.claude/RUNBOOKS.md` index mirroring `TASKS.md`'s block shape
and its `Last runbook number:` counter. The **body is the source of truth**;
the index's `Status:` and `Steps: <done>/<total>` are derived from it and can
be rebuilt by re-reading it. The id is the one thing that isn't: it's
assigned, it only ever increases, and a pruned one is never reused, so a
number you wrote down last month still means the runbook you meant. The name
stays canonical throughout: it names the file, and it's what every message
calls the runbook. No `chosko-llm` subcommand walks `.claude/runbooks/`;
runbooks are input to agents, never to tooling.

**The execution loop.** `/runbook-run` re-reads the body at the start of
*every* step, which is what reconciles a hand-edited body and what makes
steps appended mid-run get picked up by the run already in progress. It
selects the first step whose dependencies are all done, marks it `[~]`,
spawns **one** subagent with a fixed prompt (a preamble telling it to orient
from `CLAUDE.md`, the companion document, the runbook's
`## Do not re-propose` section, the step's `Context:` bullets, the prompt
block verbatim, then the operating rules), and then waits. It ticks nothing
before that agent's result actually arrives. On `DONE` it writes a `Done:`
line recording the commit sha, the decisions taken and any premise that
proved wrong, then commits the runbook and the index: one commit per
completed step. The `[~]` marker is never committed, so finding one in your
tree is the signal that this is the tree an interrupted run left behind.

**When a step needs a subagent of its own.** In some environments, cloud
sessions among them, a subagent can't spawn a subagent, which breaks any step
whose prompt invokes something that wants a child agent, like
`/task-implement --review --rounds 2`. Rather than let that agent review its
own diff or drop the reviewer silently, the contract tells it to write the
child's prompt to a temp file and end its turn with `SPAWN REQUEST`. The
orchestrator spawns that child **at its own level** (sideways rather than
down, which is why it works), waits for it, and tells the caller its result
is ready. It forwards the two paths and opens neither file, so the child's
output never enters the orchestrator's context. Detection sits with the
subagent, because only the agent that needs the tool can tell whether it has
it. Where you already know the environment is flat, `--relay-spawns` skips
the discovery.

Three things it deliberately does not do. It **never runs steps in
parallel**, even where the runbook says they're independent: you get one
question stream instead of interleaved clarifications from three agents, and
two agents writing `Done:` lines into one file would race. (A relayed child
is the one exception, and a narrow one: its caller is suspended the whole
time it runs, so only one agent is ever working.) It **does the work of no
step itself**: it writes exactly two files, the runbook and the index, and
every other change in the tree comes from a subagent. And it **doesn't
review** what a step did: it reads three markers (`QUESTIONS FOR USER`,
`SPAWN REQUEST` and `DONE`) and takes the report at its word. Review is
`/task-review`'s job, invoked from inside a step's prompt when you want it.

**The question relay** is what keeps you in the loop without keeping you in
the session. A subagent can't talk to you, so it stops at any question or
approval gate and ends its turn; the orchestrator renders it as a fixed block
(the question, the options with what each costs, a recommendation) and relays
your answer back to the *same* agent, whose context is still intact. It
compresses, it never answers for you, and at an approval gate the full draft
is shown unabridged, since a summarized draft can't be approved. When a step's
report changes a fact a later step relies on, the orchestrator appends a
dated bullet to that step's `Context:`; the prompt block itself is never
edited, so you can always see what was originally asked and what was learned
since, separately.

**Writing prompts that survive a fresh session** is the hard part, and it's
the authoring side that enforces it. `/runbook-create` checks ten rules
before it writes: each step is self-contained, names the document to read
first (or carries its evidence inline), carries every decision that exists
nowhere on disk *and nothing that already does*, states its sequencing and
why, states what must not be re-proposed, uses real slash commands in their
real argument form, references no path that won't exist at run time (nothing
under `docs/`, which is never installed), produces one deliverable, and never
invokes `/runbook-run`; nested runbooks are forbidden at both authoring and
spawn time. The tenth prefers two steps to one that would need a nested
spawn: implement, then review, each spawned by the orchestrator directly.
That one's a preference rather than a rejection, since a skill that spawns
internally can't be split by an author who doesn't know it will, which is the
case the spawn relay covers at run time. Rule three is why one-line prompts
are the expected case rather than a shortcut: `/task-implement 134` is
complete, because the task body already carries the decisions and
`/task-implement` reads it.

**Amending a step.** `skills/runbook-run/references/` holds three reference
files the suite reads by path. `runbook-schema.md` defines the asset kind,
`subagent-contract.md` holds the operating rules every spawned prompt ends
with, and `step-amend.md` holds the rules for changing one step of a runbook
after it was authored.

- **What can be amended.** Only a pending `[ ]` step. A step that's done,
  failed or in a subagent's hands right now is the record, and stays as it
  is.
- **Strike.** A step nobody should run is struck, not deleted. It becomes
  `[x]` with a `Done:` line opening `struck — <reason>` and no commit sha,
  keeps its number, and releases every step that depended on it. Nothing is
  ever deleted or renumbered, because another step's `Depends on:` may name
  it.
- **Insert.** A new step goes in through `/runbook-create --append --before
  <step>` or `--after <step>`, the suite's only step writer.
- **A wrong prompt.** A prompt block is immutable, so a step whose prompt is
  wrong is struck and a corrected step is inserted after it.
- **Context.** A pending step's `Context:` can gain dated facts.
- **A running runbook.** On a `[RUNNING]` runbook, every amendment lands
  after the current step and is made from the running session.

Commit behaviour follows each command's family: `/runbook-create` is an
authoring command and leaves the runbook uncommitted for one review pass
(`--commit`, or `--commit --no-push`), `/runbook-clean` commits and pushes
the deletion by default (`--no-commit` / `--no-push`), `/runbook-run` commits
after every step, and `/runbook-list`, `/runbook-describe` and
`runbook-suggest` write nothing at all.

A runbook is not a [session handoff](#session-save-and-session-resume): a
session file is a snapshot of work in flight, a runbook is a plan for work
not yet done. It's not a backlog either: a task is a unit of work with
acceptance criteria, a runbook step is a prompt.

### `/session-save` and `/session-resume`

A conversation ends and its context dies with it. The backlog records *what*
was done and `.claude/context/` records *where things are*; neither records
the middle: what was tried and failed, what was deliberately not tried, which
files are half-finished, and what the exact next step was. That knowledge is
otherwise re-derived from scratch every time a session ends mid-flight, at
full token cost and with no guarantee the re-derivation matches.

- `/session-save` — write what this conversation knows into
  `.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md`. Pass a slug to override the
  generated one.
- `/session-resume` — brief the current conversation from one of those
  files, then stop.

The store is **per-project**, not global: session files sit beside the
project's other `.claude/` artifacts rather than mixing every project into
one bucket under your home directory. Nothing in the CLI reads them: no
`chosko-llm` subcommand walks `.claude/sessions/`, and nothing derives from
what's written there. They are context for a human or an agent, never input
to tooling.

A save takes one of **two forms**. The full form is nine sections (what we're
building, what worked and the evidence for it, what didn't work and why, what
hasn't been tried, the state of each file, decisions with their reasons,
blockers, the exact next step, and environment notes) and *every* section is
written even when it's empty, `N/A` rather than silence, because a skipped
section is indistinguishable from an overlooked one. The pointer form is
written instead when the work already has its own resume artifact: a
project-scoped state document carrying a current-stage marker, such as
`/product-design`'s `.claude/domain/design-process.md`. Then the session file
is a header block and one sentence saying where the state actually lives; two
accounts of the same state that can disagree is worse than one.

Both forms carry a **`Work:` line**, the one typed link from the session to
the document the work belongs to: `task <n>`, `feature <slug>`,
`document <path>`, or `none`. `none` is a first-class value, not a failure. A
debugging session that touched no backlog document is exactly what it's for,
and inventing a link there would make the link untrustworthy everywhere else.

`/session-resume` takes the newest file, the newest from a date you name, or
a path. It flags a handoff older than 14 days as stale and names any path the
file mentions that no longer exists, both *before* the briefing, not after,
then reports what was being built, what must not be retried, and the exact
next step verbatim, **and stops**. It starts no work, edits no file, and takes
no step of the plan it just described, not even the obvious one. The value is
entirely in the stopping: you asked to be told where things stood, not to
have the next step taken for you while you were reading.

Old handoffs are pruned by **finishing the work**, not by a flag.
`/session-resume` closes by naming the file it resumed from and handing over
its deletion: delete it once the `Work:` it describes is finished, deletion
being part of finishing rather than cleanup afterwards. If the session ends
first, the next `/session-save` in a conversation that resumed from a file
writes its new snapshot and deletes the one it superseded, so two snapshots
of the same work never coexist. A file that was never resumed is never
deleted automatically; the stale flag is the only signal it will ever get.
There is no `--prune`.

Neither command commits. `/session-save` writes the file, reports the path,
and notes in one line that it's untracked; whether a handoff belongs in the
repo's history is your call.

### `hook:remote-session-protocol`

In a Claude Code cloud session, a question asked with the `AskUserQuestion`
tool can be re-asked while you're away from the keyboard, burning tokens and
occasionally leaving two agents doing the same work. This hook denies that
tool in cloud sessions and hands Claude a plain-text protocol instead: batch
every open question into one numbered message with lettered options and a
recommendation each, then end the turn and wait. Nothing polls, so a slow
reply costs nothing; and because the batch is one self-contained message, a
session picked back up later gets the questions and their answers as a whole.

```sh
chosko-llm add hook:remote-session-protocol --local
# paste the printed prompt into a Claude Code session to wire settings.json
git add .claude/hooks .claude/settings.json && git commit -m "Add remote session protocol"
```

**Install it `--local` and commit both halves.** A cloud container clones
your repo and nothing else, so only the project's own committed `.claude/`
arrives, which is why hooks are local-only. `add` prints a prompt for a
Claude Code session to merge the wiring into `.claude/settings.json`; this
CLI never edits that file itself. Claude Code reads hook config at session
start, so restart the session (or start a fresh cloud one) before expecting
it to fire.

Detection is positive-only, and the shell does it rather than the model: the
hook engages when `CLAUDE_CODE_REMOTE` is `true` or
`CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE` is non-empty, and prints nothing at all
otherwise, so local sessions keep the normal question UI untouched. Those
variable names are not a public API, so if they change the hook quietly stops
firing rather than blocking the tool everywhere; edit the script when that
happens.

Because it is a hook rather than a `CLAUDE.md` section, it costs zero tokens
in every session where it doesn't fire.

---

## 7. Keeping the codebase healthy

### `/refactor-codebase` and `/refactor-tests`

Behaviour-preserving cleanup under a safety net: plan first, get approval,
then proceed phase by phase, running the test suite between steps and halting
on the first failure.

- `/refactor-codebase` — constants, duplication, oversized files, imports,
  naming.
- `/refactor-tests` — split bloated test files.

Both leave the result uncommitted by default; `--commit` commits and pushes
it (`--commit --no-push` to commit without pushing).

---

## 8. Editor and shell extras

### `/unity-mcp-setup` and `unity-mcp-skill`

For Unity projects, wire up MCP so `/task-implement` can drive the editor
itself instead of pausing for you at every manual step. Idempotent and
re-runnable: it adds the `com.coplaydev.unity-mcp` package to
`Packages/manifest.json` if missing, records a marker in `CLAUDE.md` (and a
`.claude/context/mcp-tools.md` doc when the project has a context layer), and
registers + verifies the `UnityMCP` server on your machine
(`claude mcp add` / `claude mcp list`). The project-side artifacts are
versioned and shared; the Claude-side registration is machine-local (in
`~/.claude.json`) and stays per-machine. `/project-setup` offers to run it on
Unity projects. Leaves its versioned artifacts uncommitted by default;
`--commit` commits and pushes them (`--commit --no-push` to skip the push).

The repo also ships a `unity-mcp-skill` skill: a Unity-MCP operator guide
(resource-first workflow, tool categories, and reference files for tool
schemas and extended workflows) that Claude can lean on when driving the
editor over the `UnityMCP` server. Install it like any other feature with
`chosko-llm add skill:unity-mcp-skill`.

### CLAUDE.md snippets

claude-md features inject a managed section into `CLAUDE.md` (global with
`~/.claude/CLAUDE.md`, or the project's own with `--local`) rather than
copying a standalone file. The section is delimited by HTML comment markers,
so your own content around it is preserved.

- `claude-md:git-commit-style` — short imperative subject, an optional body
  of at most 2–3 lines that says why rather than restating the diff, and
  `Co-Authored-By` / `Claude-Session` trailers only on big commits (5+
  files or 200+ changed lines, checked mechanically). A repo's own
  convention wins over all of it.
- `claude-md:tool-usage-policy` — use Claude Code's built-in Read / Write /
  Edit / Glob / Grep tools for file operations rather than shell commands,
  and never mix PowerShell syntax into the Bash tool or vice versa.

### `statusline:session-statusline`

A status-bar script showing model, working directory, git branch, context
usage, session cost and the 5-hour / 7-day rate-limit usage. Installed to
`~/.claude/statusline/session-statusline.sh`; `add` prints a prompt for a
Claude Code session to wire that path into `settings.json`'s `statusLine`
key, since the CLI never edits `settings.json` itself. Needs `jq`.
Global-only: a status bar belongs to your terminal, not a repository.

---

## 9. The CLI

### Install

```sh
curl -fsSL https://raw.githubusercontent.com/Chosko/chosko-llm/master/install.sh | bash
```

The installer clones a managed copy of the repo to `~/.chosko-llm/` and puts
the `chosko-llm` CLI at `~/bin/chosko-llm`. If `~/bin` isn't on your `$PATH`
the installer will tell you how to add it. It does **not** install any
features; features are opt-in.

**Windows (cmd.exe / PowerShell).** Run the installer from **Git Bash**, not
cmd.exe or PowerShell. On Windows the installer also drops a
`chosko-llm.cmd` shim so you can call `chosko-llm` from cmd.exe and
PowerShell, and prints the native Windows directory you need to add to your
**Windows** PATH (System Properties → Advanced → Environment Variables →
Path). Two caveats: the shim targets Git for Windows' `bash.exe`, so WSL
users should run `chosko-llm` from inside WSL, where `~/.chosko-llm` is the
WSL home; and colour and interactive suggestions are muted in cmd/PowerShell
because they don't allocate a TTY.

### Browsing features

```sh
chosko-llm ls                  # all features: installed vs available versions
chosko-llm ls --installed      # only what's installed
chosko-llm ls --available      # only what's in the managed clone
chosko-llm show <feature>      # inspect one feature in detail
chosko-llm show <feature> --diff --content   # preview changes before updating
chosko-llm --version           # print the installed version (also: -v, version)
```

### Installing and removing

```sh
chosko-llm add <feature>       # install a feature into ~/.claude/
chosko-llm add <f1> <f2> ...   # several in one call (best-effort: one bad name doesn't block the rest)
chosko-llm add --all           # everything not yet installed
chosko-llm rm <feature>        # remove an installed feature
chosko-llm rm <feature> --force  # remove it even when something installed still requires it
```

Some features read a file out of another feature, and say so in their
frontmatter (`requires:`). `add` installs those requirements first, one level
deep, naming each as it goes, so `chosko-llm add command:task-add` also
installs `skill:task-engine`. A requirement that can't be installed aborts
that feature before anything is copied for it; the other names in the same
call still run. `rm` is the mirror: it refuses to remove a feature that an
installed feature still declares in `requires:`, naming every dependent,
unless you pass `--force` (which removes it anyway and warns about what you
just broke). `add --all` needs neither, since it installs everything.

### Keeping up to date

```sh
chosko-llm upgrade             # pull the latest source from the repo
chosko-llm update --all        # re-copy all installed features from the updated source
chosko-llm update <feature>    # re-copy one feature
chosko-llm update <f1> <f2> ...  # several in one call (same best-effort semantics as add)
```

Run `upgrade` first, then `update --all` to pick up new versions. `upgrade`
only refreshes the source; it does not touch installed features. `update
--all` also completes a kind migration: when an installed artifact has no
source in the clone but another feature there declares it as `replaces:`,
the replacement is installed and the stale copy removed.

When the pull moves the repo-level version, `upgrade` prints what changed:
the `CHANGELOG.md` sections for exactly the versions just pulled, newest
first. That readout replaces the raw commit list: you get the curated bullets
when the version moved, and the `git log --oneline` subjects when it did not
(or when the clone is old enough to have no `CHANGELOG.md`). The same block
appears when the daily auto-upgrade runs.

#### Daily auto-upgrade

The first `chosko-llm` command you run each day quietly runs
`chosko-llm upgrade` for you before doing its job. You're opted in at install
time; it runs at most once per calendar day and never blocks your command if
the pull fails.

```sh
chosko-llm upgrade --disable-auto   # opt out of the daily auto-upgrade
chosko-llm upgrade --enable-auto    # opt back in
```

These flags only change the preference; they don't perform an upgrade. The
opt-in/opt-out state and the last-run date live in a gitignored file in the
managed clone (`~/.chosko-llm/.auto-upgrade-state`). Set
`CHOSKO_LLM_NO_AUTO_UPGRADE` to skip the automatic run entirely (handy in CI
or scripts).

### Reading the changelog on demand

```sh
chosko-llm changelog                  # open CHANGELOG.md in your editor
chosko-llm changelog --since 1.10.0   # that version's section and everything newer
chosko-llm changelog --since 2026-08-01   # every section dated on or after that day
chosko-llm changelog --since 30d      # ...or 2w, 6mo, 1y — counted back from today
chosko-llm changelog --print          # the whole file on stdout, no editor, no pager
```

With no arguments it opens the managed clone's `CHANGELOG.md` in `$VISUAL`,
else `$EDITOR`, else whatever `git var GIT_EDITOR` reports, and when none of
those resolves it falls back to a pager, and then to plain output. It never
fails just because you have no editor configured; `--print` is there for
scripts that must not spawn anything.

`--since` takes one value in any of three shapes and works out which it is
(a version, a date, or a duration), so there's no flag to remember per form.
Its output goes to **stdout**, unlike `upgrade`'s readout, so it pipes into
`grep` and friends. It's paged only when the block doesn't fit one screen
*and* stdout is a terminal: a redirect or a pipe stays a plain stream
whatever the length, and `--print` forces that too. A value that matches no
section isn't an error; it says so and exits 0. The version form is inclusive
of the version you name (`--since 1.10.0` includes 1.10.0), where `upgrade`'s
range excludes the version you came from, because there you already had it.

`changelog` reads and nothing more: it never pulls, and it's one of the
subcommands the daily auto-upgrade skips.

### Channels: trying unmerged work

A **channel** is just the branch the managed clone is checked out on. Switch
onto a feature branch to try it before it lands on `master`, then switch
back:

```sh
chosko-llm channel                # print the channel the clone is on
chosko-llm channel --list         # fetch origin and list channels you can switch to
chosko-llm channel my-feature     # switch to a branch: fetch, checkout, fast-forward, refresh proxy
chosko-llm update --all           # deploy that channel's features into ~/.claude/
chosko-llm channel master         # back to stable
```

Switching does a full fetch + checkout + `pull --ff-only` + proxy refresh,
but only *suggests* `update --all`: deploying features into `~/.claude/`
stays an explicit step, same as `upgrade`. There's no state file: the
checked-out branch is the whole persistence mechanism, and the daily
auto-upgrade's `pull --ff-only` already follows it. Once a feature branch is
merged and deleted upstream its `pull --ff-only` will fail; recover with
`chosko-llm channel master`.

### Exporting a repo's Claude config

`chosko-llm export` packages a repo's Claude config (`CLAUDE.md`,
`AGENTS.md`, `README.md`, and the curated Markdown/JSON/TOML/shell subset of
`.claude/`; the shell part covers hooks and the task-setup test runners,
which `settings.json` and the backlog wiring reference) into a single
hand-off artifact:

```sh
chosko-llm export                 # writes ~/claude-exports/<repo>-claude-config.md
chosko-llm export /path/to/repo   # export a different repo; defaults to $PWD
chosko-llm export --archive       # writes a .zip instead, for uploading to a Claude chat
```

The default Markdown shape concatenates every selected file into one
document, suited to a Claude Project's knowledge base, where the whole thing
gets ingested at once. `--archive` writes a zip with the files under a
top-level `<repo>/` directory plus a root `MANIFEST.md`, suited to a Claude
chat, where the assistant reads members selectively. Both shapes draw from
the same file-selection rules, so they never disagree about what a repo's
config is. Output goes to `$CHOSKO_LLM_EXPORT_DIR` (default
`~/claude-exports`), created if missing; the written path is printed on
success.

### Per-repository installs

`ls`, `show`, `add`, `rm`, and `update` all accept `--local` / `--global`.
`--global` (the default) targets `$CLAUDE_HOME` as usual. `--local` targets
`<cwd>/.claude` instead, so a feature can be installed into a single
repository rather than globally:

```sh
chosko-llm add refactor-codebase --local   # install into <cwd>/.claude/ instead of ~/.claude/
chosko-llm ls --local                      # list what's installed in <cwd>/.claude
chosko-llm update --all --local            # refresh everything installed locally
chosko-llm rm refactor-codebase --local    # remove it again
```

`--local` requires `<cwd>/CLAUDE.md` to already exist: run it from the
project root (or run `/project-setup` first on an empty directory). claude-md
artifacts are the one exception to the `.claude/` target: they inject their
managed section into `<cwd>/CLAUDE.md` itself, since that's the file Claude
Code actually reads for the project.

### Feature names and kinds

A bare name like `refactor-codebase` matches commands, skills, claude-md
artifacts, statusline scripts, and hooks. If a name is ambiguous,
disambiguate with `command:<name>`, `skill:<name>`, `claude-md:<name>`,
`statusline:<name>`, or `hook:<name>`.

| Kind | Installs to | Scope |
| --- | --- | --- |
| command | `~/.claude/commands/<name>.md` | global or `--local` |
| skill | `~/.claude/skills/<name>/` | global or `--local` |
| claude-md | a managed section inside `CLAUDE.md` | global or `--local` |
| statusline | `~/.claude/statusline/<name>.sh` | global-only |
| hook | `<cwd>/.claude/hooks/<name>.sh` | local-only |

statusline scripts are global-only: a status bar belongs to your terminal,
not a repository. A single-feature `add`/`update`/`rm` naming a statusline
feature fails with `--local`; `add --all --local` and `update --all --local`
skip the statusline pass instead of failing; `ls --local` omits it entirely;
`show --local` on a statusline feature reports it as global-only.

hooks are local-only, the mirror of statusline's rule: a hook only fires
where it is committed, and a cloud container clones the repository and
nothing else, so a globally wired hook could never reach the agent it
governs. A single-feature hook request without `--local` fails; `add --all` /
`update --all` in global scope skip the hook pass; `ls --global` omits hooks;
`show --global` on a hook reports it as local-only.

For both statusline and hook features, `add` prints a copy-pasteable prompt
for a Claude Code session to merge the installed path into `settings.json`.
The CLI never edits `settings.json` itself, since that file's shape isn't
this repo's to own.

### Uninstall

```sh
chosko-llm uninstall
```

(or, from a working copy, the standalone `./uninstall.sh`, same flow).

Asks for an up-front confirmation, then prompts before each destructive step:

1. Remove the CLI proxy at `~/bin/chosko-llm` (and `chosko-llm.cmd` on
   Windows).
2. Optionally delete every installed feature under `~/.claude/` that matches
   a feature in the managed clone (user-authored files are left alone).
3. Optionally remove the managed clone at `~/.chosko-llm/`.

Pass `-y` (or `--yes`) to answer every prompt yes for non-interactive use.

### Configuration

| Env var           | Default         | Purpose                                              |
| ----------------- | --------------- | ---------------------------------------------------- |
| `CHOSKO_LLM_HOME` | `~/.chosko-llm` | Managed clone location.                              |
| `CLAUDE_HOME`     | `~/.claude`     | Where features get installed.                        |
| `BIN_DIR`         | `~/bin`         | Where the CLI proxy lives. Used by `install.sh`.     |
| `NO_COLOR`        | unset           | Set to any value to disable colored output.          |
| `CHOSKO_LLM_NO_AUTO_UPGRADE` | unset | Set to any value to skip the daily auto-upgrade.     |
| `CHOSKO_LLM_EXPORT_DIR` | `~/claude-exports` | Where `chosko-llm export` writes its output. |
| `VISUAL` / `EDITOR` | unset | Which editor `chosko-llm changelog` opens the file in. Falls back to git's. |
| `PAGER`           | `less -R`       | Which pager `chosko-llm changelog --since` overflows into. |
