# Runbooks

A new asset kind and the five shipped artifacts that author, execute, read and
prune it. A **runbook** is an ordered list of self-contained prompts, each
written to be executed by a fresh agent that has none of the conversation the
prompts came out of. `/runbook-run` walks one top to bottom, spawning one
subagent per step, relaying that subagent's questions to the user and the
user's answers back to the same subagent, recording what each step actually did,
and committing after every step.

## Purpose

On 2026-08-24 a hand-written file listed seven follow-up prompts produced by an
`/architect` run. A session then executed them by hand: paste a prompt into a
fresh subagent, carry its questions back to the user, tick the step with a note
recording the commit sha and the decisions taken, commit, and fold the facts
learned into the prompts still to come. It worked far better than running the
same seven prompts in one long session, for three reasons worth naming:

- **Each step got a clean context.** No accumulated half-decisions, no drift
  from step 1's framing into step 6.
- **Every step's outcome was written down at the moment it was known** — the
  commit sha, the divergences from the plan, the premises that turned out to be
  wrong. Step 4's prompt was corrected by what step 1 discovered.
- **The user stayed in one question stream.** Steps ran one at a time, so
  clarifications arrived in order and in context.

The loop is mechanical and was performed by hand seven times. That is the case
for shipping it.

The second half of the case is subtler and lives in the authoring side. The hard
part of a runbook is not the file format; it is that a prompt written inside a
rich conversation reads as complete and is not. It leans on decisions made an
hour ago and written down nowhere, on a document everyone present had already
read, and on shared knowledge of which options were already rejected. Handed to
a fresh agent, that prompt produces confident work against the wrong premise.
The reference file survived seven fresh sessions because each prompt named the
document to read first, carried the decisions that existed nowhere on disk, said
what must not be re-proposed, and stated its own place in the order and why.
Those properties are a checklist, not natural output, and the one moment to
apply it is while the conversation that produced the material is still open.

## Scope and non-goals

In scope: the asset kind (store, body schema, step markers, status vocabulary,
index block), the execution protocol, the authoring rules including incremental
appends, the read and prune commands, the auto-triggering suggestion, and the
two reference files the suite shares.

Deliberately out:

- **Parallel execution.** Steps run one at a time, always, even where the
  runbook declares them independent. Two reasons, both sufficient: the user gets
  one question stream rather than interleaved clarifications from three agents,
  and two agents writing `Done:` lines into the same runbook race on the same
  file. Independence is recorded in `Depends on:` because it documents the real
  constraint and permits `--only`, not because anything runs at once.
- **The orchestrator doing any of the work itself.** It edits exactly two files
  — the runbook and the index. Every other change in the tree is made by a
  subagent. An orchestrator that starts patching things is one that has lost
  track of what it delegated.
- **Coupling to any upstream skill.** Nothing here knows about `/architect`,
  `/product-design` or `/product-roadmap`, and none of them reference this
  suite. A runbook is a list of prompts; where the prompts came from is
  provenance, not structure.
- **Rewriting a step's prompt.** The fenced prompt block is written once, by the
  author. New facts are appended to `Context:`; the prompt itself is immutable.
- **Deletion on completion.** Finishing a runbook flips a status and nothing
  else. Removal is `/runbook-clean`'s explicit, confirmed act.
- **Nested runbooks.** A step whose prompt runs `/runbook-run` is forbidden —
  see the decision under the orchestrator.
- **Being a session-handoff mechanism.** That is
  [session-continuity](./session-continuity.md), a different store with a
  different shape. A runbook is a plan for work not yet done; a session file is
  a snapshot of work in flight.
- **State the CLI reads.** No `chosko-llm` subcommand walks `.claude/runbooks/`.
  Runbooks are input to agents, never to tooling; the rule that the filesystem
  plus frontmatter is the CLI's only state is unchanged.
- **Reviewing a step's work.** The orchestrator reads `QUESTIONS FOR USER` and
  `DONE`; it does not review, re-test, or second-guess a subagent's commit.
  Review is [task-peer-review](./task-peer-review.md)'s job and is invoked, when
  wanted, from inside a step's prompt.

## Architecture

Built on the repo's existing shape per [product-design.md](../product-design.md):
shipped commands and skill folders under `commands/` and `skills/`, installed by
copy into `$CLAUDE_HOME`.

### The five shipped artifacts

| Artifact | Kind | Job |
|---|---|---|
| `skills/runbook-run/` | skill | the orchestrator, plus the two shared reference files |
| `commands/runbook-create.md` | command | authors a runbook, or appends steps to one |
| `commands/runbook-list.md` | command | read-only listing with status and progress |
| `commands/runbook-clean.md` | command | plan-and-confirm removal of `[DONE]` runbooks |
| `skills/runbook-suggest/` | skill | auto-triggering one-line suggestion, asks nothing |

Five separate features in the shipped catalogue, each with its own frontmatter
and `version:`, exactly like every other feature in this repo — not one skill
with verbs. They are one *production* feature because they share an artifact and
are useless apart; `/task-add` splits them into at least one task per artifact
plus documentation.

**Ship order: `runbook-run` first**, then `runbook-create`, then `runbook-list`
and `runbook-clean` in either order, then `runbook-suggest` last. The order is
forced by the dependency graph below: three artifacts cite files that live
inside the runbook-run skill folder, and `runbook-suggest` proposes a command
that must exist.

### Why the shared files live in a skill

`cmd-add` installs a skill with `cp -R` of the whole folder, so any file beside
`SKILL.md` ships with it; a command is a single `.md` file and can carry nothing
(see [shared-phase-engine](./shared-phase-engine.md)). The schema and the
subagent contract are needed by more than one artifact, so they must live in a
skill folder, and runbook-run is the natural host:

```
skills/runbook-run/
  SKILL.md                        the orchestration protocol
  references/
    runbook-schema.md             the artifact: store, body, index, statuses
    subagent-contract.md          the preamble and OPERATING RULES, verbatim
```

Consumers cite them by installed path, honouring the `CLAUDE_HOME` override rule
rather than hardcoding `~/.claude`:

```
${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md
```

This is the pattern the vendored `claude-council` skill already uses for its own
install location, and the one `shared-phase-engine` generalizes.

Two reference files, not three. The prompt-quality rules stay in
`runbook-create`'s body: they have exactly one consumer, and a shared file with
one consumer is indirection without benefit.

### The store

One file per runbook, uniquely named, many coexisting, all committed:

```
.claude/runbooks/<name>.md          the runbook
.claude/RUNBOOKS.md                 the index, mirroring TASKS.md's shape
```

`<name>` is kebab-case and is the identifier. Runbooks are committed — the
deliberate opposite of the open question hanging over `.claude/sessions/` —
because the work is executed across machines and cloud sessions and the `Done:`
lines are the record of what happened.

### The body schema

````markdown
# Runbook: <name>

Created: 2026-08-24 · Source: /architect run · Model: opus
Sequencing: 1–4 ordered (all three edit skills/task-implement/SKILL.md); 5–7 independent.
Companion: .claude/sessions/2026-08-24-1430-ecc-import-architecture.md

## [ ] 1. <title>

Depends on: none

Context: none

```prompt
<self-contained prompt: names the document to read first, carries every
decision that exists nowhere on disk, may open with a slash command>
```

## [ ] 2. <title>

Depends on: 1

...

## Do not re-propose

- <option already assessed and rejected, with its reason>
````

Header fields: `Created:` and `Source:` are provenance; `Model:` is the model
every step is spawned with; `Sequencing:` is one line of prose stating the order
and *why* it is the order, which is the part a reader needs and a bare
dependency graph does not carry. `Companion:` is optional — a background
document offered to every step, which in the reference file was pasted into all
seven prompts by hand.

`## Do not re-propose` is optional, global to the runbook, and appended to every
spawned prompt. The reference file carried exactly such a section and it was
load-bearing: without it a fresh agent re-proposes what a council already
rejected.

Step markers, in the `##` heading:

| Marker | Meaning |
|---|---|
| `[ ]` | pending |
| `[~]` | in progress |
| `[x]` | done — a `Done:` line follows |
| `[!]` | failed — a `Done:` line follows, opening with the reason |

The `Done:` line does not exist until a run writes it. It records the commit
sha, the decisions taken while executing, and any premise in the step that
turned out to be wrong — the three things the hand-run version recorded and the
three that were re-read most often.

A step carries no `Produces:` field declaring whether it ends in a commit or a
report. It was considered, for classifying an ambiguous result more
confidently; it is not adopted, because the classification rule below is
already unambiguous without it and a field the author must predict correctly is
a field that will be wrong.

### Status vocabulary

Four statuses, in `.claude/RUNBOOKS.md`, deliberately distinct from both
`TASKS.md`'s and `FEATURES.md`'s vocabularies so a grep never confuses them:

| Status | Meaning | Written by |
|---|---|---|
| `[PENDING]` | authored, not started, or started and interrupted | `/runbook-create`, `/runbook-run` |
| `[RUNNING]` | a step is executing now | `/runbook-run` |
| `[FAILED]` | a step reported failure or an unreadable result; the run halted | `/runbook-run` |
| `[DONE]` | every step is `[x]` | `/runbook-run` |

There is no `[SKIP]`: a runbook is authored complete and a step nobody wants is
deleted before the run, not carried as a tombstone.

### The index block

`.claude/RUNBOOKS.md` mirrors `.claude/TASKS.md`'s block shape, minus its
counter — names are the identifiers, so there is nothing to count, exactly as in
`FEATURES.md`:

```
---

## <name> — <one-line title>

Status: [PENDING]
File: .claude/runbooks/<name>.md
Created: 2026-08-24
Source: /architect run
Steps: 0/7

---
```

`Steps:` is `<done>/<total>`, where done counts `[x]` only. A fifth line,
`Failed at: step <n> — <reason>`, is present only while the status is
`[FAILED]`, and is removed when a re-run clears it. The index is a summary: it
holds nothing that is not derivable from the body, so a hand-edited body is
reconciled by re-reading it, and `/runbook-list` never has to open a body.

---

### `/runbook-run` — the orchestrator

**The execution loop.**

1. **Resolve.** Read the index block and the body. An unknown name reports the
   available ones. A `[DONE]` runbook with no `--only`/`--from` says so and
   stops rather than doing nothing quietly.
2. **Re-read the body.** At the start of *every* step, not once per run. This
   is deliberate and does two jobs: it reconciles a body edited by hand between
   steps, and it is what makes steps appended mid-run by `/runbook-create
   --append` picked up by the run already in progress. There is no separate
   reconciliation mechanism because this one is free.
3. **Select.** The first step whose marker is `[ ]`, `[~]` or `[!]` and whose
   every `Depends on:` step is `[x]`. A `[~]` step is one a previous run was
   interrupted in; it is reported as such and re-run. A `[!]` step is re-run
   with its failure already recorded in `Context:` by the run that failed. If
   steps remain but none are selectable, that is a dependency deadlock: report
   the blocked steps and their unmet dependencies, and stop.
4. **Mark.** Set the step to `[~]` and the index status to `[RUNNING]`.
5. **Spawn** one subagent, fresh context, with the assembled prompt below and
   the model from the header (`--model` overrides for the whole run).
6. **Wait.** A spawn returns asynchronously — the call yields an id and the
   result arrives later as a separate notification. Nothing else happens until
   it does. This is the single most dangerous point in the whole feature: a body
   that treats the spawn's return value as the result will tick a step that
   never ran and commit the lie.
7. **Handle the result** — the three cases under Interfaces and contracts.
8. **Commit** the runbook and the index, then loop to 2. When no `[ ]` steps
   remain, set the index to `[DONE]` and report.

**The spawned prompt**, assembled in this order so the operating rules are the
last thing the agent reads:

1. **Preamble** — orient in a fresh session: read the project's `CLAUDE.md` and
   follow its navigation instructions as written — the index of each navigation
   layer, then only the files relevant to this step, never a whole layer. It
   also names the runbook and step this agent is executing, which is what lets a
   step's subagent use `/runbook-create --append` with no name. The
   orchestrator itself reads `CLAUDE.md`, the runbook and the index, and nothing
   else — it never opens a navigation layer, since it touches no source.
2. **Background** — the `Companion:` document, if the header names one.
3. **Do not re-propose** — the runbook's trailing section, if present.
4. **Context** — the step's `Context:` bullets, if any.
5. **The prompt** — the fenced block, verbatim. Never paraphrased, never
   trimmed, never merged with the surrounding material.
6. **OPERATING RULES** — verbatim from `references/subagent-contract.md`.

The contract block is fixed text, which is why it is a reference file rather
than prose the orchestrator composes. It tells the subagent that it cannot talk
to the user; that at any clarifying question or approval gate it must stop and
end its turn with `QUESTIONS FOR USER` followed by the questions, the options, a
recommendation for each, and — at an approval gate — the full draft; that it
must follow the default commit behaviour of whatever skill it invokes and add no
flag the user did not type; that it must never edit the runbook or the index;
which runbook and step it is executing; and that it must end with `DONE` and a
concise report naming the commit sha, the decisions taken, and any premise in
the prompt that proved wrong.

**The question relay.** The orchestrator compresses, it does not answer. A
relayed question is rendered as one fixed block:

```
Step 3 of 7 — Peer review — the agent is asking (round 1):

  <the question in one or two lines>

  a) <option> — <what it costs>
  b) <option> — <what it costs>

Recommendation: (b), because <one line>.
```

At an approval gate the full draft follows the block verbatim, unabridged — the
one place the orchestrator must not compress, since a summarized draft cannot be
approved. The user's answer is relayed to the **same** subagent, whose context is
intact, and the loop repeats for as many rounds as it takes. The orchestrator
may add facts it already holds — a `Done:` line from an earlier step that
answers the question — and must say that it is doing so. It may never invent a
decision on the user's behalf, and it never asks the user to re-state something
an earlier step already settled.

**Fact propagation.** When a step's report changes a fact a later step relies
on, the orchestrator appends a dated bullet to that step's `Context:` naming the
correction. This is the mechanism that made the hand-run version work: step 1
discovered that `parse_frontmatter` gates emission on a key allowlist,
contradicting a "verified fact" carried by step 4, and the correction was folded
in before step 4 ran. The prompt block itself is never edited — a reader must
always be able to see what was originally asked and what was learned since,
separately.

**One run per runbook.** Two concurrent runs of the same runbook are forbidden.
A `[RUNNING]` status in the index blocks a second `/runbook-run` of that name,
which reports the runbook as already running and stops. The single exception is
resuming in the same session and the same working tree, signalled by a `[~]`
marker present in the tree: `[~]` is deliberately never committed, so its
presence locally means this tree is the one that was interrupted. `[RUNNING]` in
the index plus `[~]` in the tree is the whole resume signal — there is no
staleness heuristic, no timestamp, and no lock file, which would be state this
repo does not keep.

**Nested runbooks are forbidden.** A step whose prompt invokes `/runbook-run` is
rejected by `/runbook-create` at authoring time and refused by `/runbook-run` at
spawn time, so a hand-written runbook cannot smuggle one in either. The reason
is the depth budget: the orchestrator occupies one level and the step's agent a
second, and a nested orchestrator would leave nothing for the work.

**Depth budget.** With the orchestrator at one level and the step's agent at a
second, one confirmed level remains for anything that agent spawns (nesting to
depth 3 was verified 2026-08-24). A step whose prompt itself spawns subagents —
`/task-implement --review`, which wants an implementor and then a reviewer —
would need depth 4, which has not been probed. This is not a blocker and nothing
refuses it; the runbook-run body states it plainly so an author who writes such
a step knows they are past verified ground.

---

### `/runbook-create` — authoring and appending

Two orthogonal axes: **where the steps go** (a new runbook, or appended to an
existing one) and **where the material comes from** (the current conversation,
or a from-scratch description).

**Target: new or append.**

- `/runbook-create <name>` — a new runbook under that name. A single kebab-case
  token is read as a name; anything longer is read as a description.
- `/runbook-create --append <name>` — appends steps after the last existing step
  of that runbook.
- `/runbook-create --append` with no name targets the **current** runbook when
  the session is running one. The orchestrator session knows which that is; a
  step's subagent knows because the spawned prompt names its runbook. With no
  current runbook it is an error naming `--append <name>`.
- `/runbook-create` with no arguments asks which: a new runbook (name given
  free-form) or an append to an existing one, listed from `.claude/RUNBOOKS.md`
  with non-`[DONE]` runbooks first and the currently running one first of all.

Appending is a flag rather than a separate `/runbook-append` command because the
interview, the prompt-quality rules and the confirmation gate are identical in
both directions; only the write target differs. A second command would duplicate
the entire authoring apparatus to change one path.

**Append rules.**

- Numbering continues from the last existing step.
- `Depends on:` may reference existing steps, including completed ones.
- The `Sequencing:` header line is extended, not replaced — it describes the
  whole runbook and the appended steps are now part of it.
- Existing steps are never edited. Ownership stays by line; an append adds
  material after the last step and touches nothing above it.
- Appending to a `[DONE]` runbook flips it back to `[PENDING]`: there is
  unfinished work again, and the status has to say so.
- Appending to a `[FAILED]` runbook leaves it `[FAILED]`. The halt still needs a
  decision and adding steps does not resolve it.
- Appending to a `[RUNNING]` runbook is allowed **only from the running session
  itself** — one session, one tree, no race. The run picks the new steps up at
  its next step re-read.
- The index `Steps: <done>/<total>` is updated.

**Source: conversation or from scratch.**

*Conversation mode* is the default when no description is given, and the mode
the feature exists for: the decisions, the rejected options and the verified
probes are all still in context, and every one of them is a candidate for a
prompt body. The source is the **most recent** enumerated follow-up list in the
conversation. Earlier lists are superseded and ignored, except for items still
outstanding, which are carried forward. The confirmation gate shows the
resulting list so the user can strike or add, which is what makes a wrong pick
cheap.

*From-scratch mode* takes a free-form description. Nothing is in context, so the
material is gathered by a short interview, asked as one batch with a recommended
answer for each so it can be settled in a sentence:

1. **What must be true when this runbook is finished?** The end state, which is
   what makes the last step recognizable as the last step.
2. **What are the steps, in order?** Titles are enough at this stage.
3. **Which steps must precede which, and why?** The reason is the part that goes
   on the `Sequencing:` line — "1–4 all edit the same file" is worth more to a
   future reader than a dependency graph.
4. **For each step, which document should the agent read first?** A step with no
   such document needs its evidence inline instead, which is worth knowing now
   rather than at write time.
5. **What has already been decided, tried, or rejected?** This becomes the
   material for the prompts and for the optional `## Do not re-propose` section.
   It is the question from-scratch mode exists to ask, because unlike
   conversation mode there is nothing else to harvest it from.

A sixth question — the model — is asked only when the default (`opus`) is not
wanted.

**The prompt-quality rules**, enforced against every step before the file is
written and stated in the command body so the authoring agent applies them
rather than approximating them:

1. **Self-contained.** An agent with no history of this conversation can execute
   it. This is the rule the other eight serve. Self-contained means *complete
   given what the invoked command reads*, not exhaustive: a prompt that invokes
   a skill which reads its own inputs from disk is complete as the bare
   invocation.
2. **Names the document to read first.** Or, where there is none, carries the
   evidence inline — the reference file's step 1 opened with "This has no
   feature document. All its evidence is here" and then supplied it. When the
   invoked command names that document itself (`/task-implement 134` reads
   `.claude/tasks/134.md`), the prompt does not repeat it.
3. **Carries every decision that exists nowhere on disk — and nothing that
   already does.** Anything settled in conversation and not yet written to a
   file is invisible to a fresh agent and will be re-litigated, usually
   differently. The converse is equally binding: restating what a task body, a
   feature document or `CLAUDE.md` already says duplicates it, and the duplicate
   drifts. The correct prompt for an authored task is one line —
   `/task-implement 134` — because the body carries its decisions, its
   pre-authorisations and its verification, and `/task-implement` checks its
   preconditions. One-line prompts are the expected case, not a shortcut.
4. **States its sequencing and why.** Not "do this third" but "this goes last of
   the four that touch `skills/task-implement/SKILL.md`".
5. **States what must not be re-proposed.** Options already assessed and
   rejected, and recommendations already overruled. Step-specific ones go in the
   prompt; runbook-wide ones go in `## Do not re-propose`.
6. **Uses an existing slash command where one fits**, in its real argument form
   — `/task-add feature=<slug>`, not a paraphrase of what it does.
7. **References no path that will not exist at run time.** In particular nothing
   under `docs/`, which is authoring-time-only and never installed.
8. **Produces one deliverable.** A step that lands two unrelated artifacts is
   two steps, because half of it succeeding has no honest marker.
9. **Never invokes `/runbook-run`.** Nested runbooks are forbidden; a step
   proposing one is rejected here rather than at spawn time.

A step failing a rule is fixed before the file is written, and the fix is named
in the confirmation report rather than applied silently — the user is the only
one who knows whether a missing decision was an omission or a deliberate
delegation.

**Where authoring-time facts go.** `Context:` is written as `none` at authoring
time in the common case. The decisions a prompt needs belong **inside** the
prompt, which keeps the fenced block pasteable into a fresh session on its own —
the property the reference file had, and the reason a runbook remains executable
by hand if `/runbook-run` is unavailable or the user simply prefers to drive it.
`Context:` is the run's field: corrections, failure notes, and facts learned by
earlier steps.

**First use and naming.** `.claude/runbooks/` and `.claude/RUNBOOKS.md` are
created on first use, the index with its title and nothing else — no counter,
because names are the identifiers. Creation is silent and idempotent; a project
needs no setup step and `/task-setup` and `/project-setup` are untouched. A name
already present is refused with a suggested alternative rather than
disambiguated automatically, since a runbook is referred to by name for the
length of its execution and two similar names are a real hazard. Names of
removed runbooks are not reserved: nothing holds a persistent pointer to a
runbook the way `Preconditions:` lines point at task IDs.

**The confirmation gate.** Before writing, the command reports the proposed
shape — target runbook, step titles, sequencing line, dependencies, and any
rule-8 splits it made — and stops for approval. Only the shape: showing every
full prompt back is a wall of text that gets skimmed, and the prompts are in the
file a moment later, uncommitted and open to review. The gate exists to catch a
wrong order or a missing step, both expensive after the first step has run and
cheap now.

As an authoring command it leaves its output uncommitted for one review pass;
`--commit` opts in, `--commit --no-push` commits without pushing. The review
pass matters more here than usual: the prompts are the whole product, and they
are cheapest to fix before the first step runs.

---

### `/runbook-list` — the read side

One pass: read `.claude/RUNBOOKS.md`, parse each block's five fields, apply an
optional status filter, print. It never opens a body file — everything printed
comes from the index, which is why the index carries `Steps:` at all. This is
`/task-list`'s discipline of never opening a file under `.claude/tasks/`, and it
keeps the cost flat in the number of runbooks rather than in their size.

A missing or empty index is not an error: one line saying no runbooks exist and
naming `/runbook-create`.

```
  [DONE]     ecc-import-landing      7/7   2026-08-24  /architect run
  [FAILED]   cli-dependency-field    2/5   2026-08-25  manual
             ↳ failed at step 3 — the managed clone was on the wrong channel
  [PENDING]  context-layer-refresh   0/3   2026-08-26  /product-design run

  3 runbooks: 1 done, 1 failed, 1 pending.
```

The `Failed at:` continuation is printed only for `[FAILED]` runbooks and is why
the field is carried in the index: the one thing a reader of a halted runbook
needs is why it halted, and making them open the file for a single sentence is
the friction that stops the listing being used.

The optional status argument is matched without brackets and
case-insensitively — `/task-list`'s existing convention. An unknown status names
the four valid ones rather than printing nothing, since a silent empty result is
indistinguishable from having no matching runbooks.

The listing writes nothing, runs no shell, and corrects no status however wrong
it looks. Reconciliation belongs to the command that already has the body open.

---

### `/runbook-clean` — pruning

Removal is an explicit act because completion deletes nothing: the `Done:` lines
are the record of what was decided while the work was being done, and they are
re-read more often than anyone expects. But the store is committed and grows
without bound, and a directory holding a year of finished runbooks makes
`/runbook-list` useless for the one question it exists to answer.

It behaves exactly like `/task-clean`. Three stages:

1. **Resolve.** With no argument, every `[DONE]` runbook. With names, exactly
   those — and a named runbook that is not `[DONE]` is refused by name with its
   actual status rather than silently skipped, since the user asked for it
   explicitly and a silent skip reads as a successful removal.
2. **Plan and confirm.** Print each runbook to be deleted with its name, created
   date, and steps done/total, plus both paths — the body file and the index
   block — and ask. Nothing is written before an explicit answer. An empty plan
   says so and stops without asking anything.
3. **Remove and commit.** Delete each body file, remove each index block
   including its surrounding `---` rules, then stage exactly the deleted paths
   and `.claude/RUNBOOKS.md` and commit. Never a catch-all stage.

Only `[DONE]` is eligible. `[PENDING]` is unstarted work, `[RUNNING]` is a run
someone is in the middle of, and `[FAILED]` is the status most likely to be
misread as finished — it is the record of a halt that still needs a decision.
There is no `--force` and no status argument widening the set: a user who
genuinely wants a `[FAILED]` runbook gone flips its status by hand first, one
visible committed edit. This is narrower than `/task-clean`, which prunes
`[DONE]` and `[SKIP]`; runbooks have no second terminal status.

It commits and pushes by default, with `--no-commit` and `--no-push` to opt out —
the cleanup-command convention rather than the authoring one, for `/task-clean`'s
reason: a deletion left uncommitted is the change most likely to be lost, and the
confirmation gate has already served as the review pass.

An unknown name aborts the whole run before anything is deleted rather than
removing the names it did recognize — a partial deletion from a mistyped list is
the worst outcome available here.

---

### `/runbook-suggest` — the trigger

The suite has one usability problem and it is not in the other four artifacts:
the moment a runbook is worth writing is the moment nobody thinks of it. A design
conversation ends with seven follow-ups, the session closes, and a week later
they are re-derived from scratch — which is exactly what happened before the
reference file was written by hand.

`skills/runbook-suggest/SKILL.md`, and nothing else in the folder; roughly thirty
lines of body, small enough that its cost when loaded is negligible, which
matters for a skill that by design loads on a guess.

**It asks nothing.** No `AskUserQuestion`, no gate, no waiting. It is
auto-triggered, and a question from an auto-triggered skill becomes an
interruption at exactly the wrong moment. It emits one or two lines suggesting
`/runbook-create` — mentioning `--append <name>` when `RUNBOOKS.md` lists
non-`[DONE]` runbooks, and naming the current runbook if one is running — and
stops. `/runbook-create` invoked with no options is what asks new-versus-append;
that gate belongs to the command the user chose to run.

**The trigger is the description.** Claude Code selects a skill from its
`description`, so the description *is* the mechanism — there is no hook, no
`Stop` handler, and no event registration. The threshold is carried in both the
description and the body, and it is the part that decides whether the skill is
useful or noise: suggest only when the follow-ups would be **lost with the
conversation** — three or more actions, or two or more with an ordering
constraint, or any prompt that depends on decisions not recorded on disk. Never
for a two-step list of simple prompts.

Description, to be adapted at authoring time:

> Suggest creating a runbook. Trigger whenever a conversation produces an
> ordered list of follow-up actions meant for later, separate sessions — the
> tail of an /architect, /product-design or /product-roadmap run, a "next steps"
> or "landing prompts" list, "do these in order" — when there are three or more
> actions, or two or more with ordering, or any that depends on decisions not
> written down. Suggests /runbook-create (or --append) in one line and stops;
> asks nothing. Not for: a single follow-up, a two-step list of simple prompts,
> a task backlog (that is /task-add), or steps to do right now in this session.

The anti-triggers are named explicitly, the way `claude-council`'s description
already does with its "not for factual questions, coding help, debugging"
clause: a single next action; a list of things already done; a checklist the
current session is about to work through; an enumeration inside an explanation;
and a list of tasks that belong in the backlog.

Its fire rate cannot be settled on paper and will not be: the description is
tuned after observing real sessions. That is the accepted method for this
artifact, not an open question — and the fix, if it is noisy, is a narrower
description rather than a suppression flag.

It reads no file, writes no file, proposes once, and never creates a runbook
itself.

## Data and state

The runbook body and the index block. Both are markdown, both are committed, and
the body is the source of truth: `Status:` and `Steps:` in the index are derived
and can be rebuilt by re-reading the body.

Ownership is split **by line**, the same discipline that keeps `FEATURES.md`
safe with two writers:

| Line | Written by | Never touched by |
|---|---|---|
| the header, `Sequencing:`, `Companion:` | `/runbook-create` | `/runbook-run` |
| a step's title and its ```prompt``` block | `/runbook-create` | `/runbook-run` |
| `Depends on:` | `/runbook-create` | `/runbook-run` |
| the step marker, `Done:`, `Context:` appendices | `/runbook-run` | `/runbook-create` |
| `## Do not re-propose` | `/runbook-create` | `/runbook-run` |

An append writes only new steps and the `Sequencing:` extension; it never edits a
line above the append point, which is what makes appending safe during a run.

`Context:` is the one field with a shared history: the author writes it as `none`
in the common case, and what accumulates there afterwards belongs to the run.

Commit cadence: one commit per completed step, staging exactly the runbook and
the index and never a catch-all, then a push. `--no-commit` and `--no-push`
follow the repo's usual meaning. The `[~]` marker is deliberately *not*
committed — it is in-run working state, and an interrupted run leaving `[~]` in
the working tree is both the resume signal and the same-tree exception to the
one-run-per-runbook rule. A subagent that commits its own work produces a
separate commit; the runbook commit is bookkeeping and is expected to sit beside
it.

## Interfaces and contracts

```
/runbook-create                          ask: new runbook, or append to which
/runbook-create <name>                   new runbook, material from the conversation
/runbook-create <free-form description>  new runbook, material from the interview
/runbook-create --append <name>          append steps to that runbook
/runbook-create --append                 append to the runbook this session is running
/runbook-create <args> --commit [--no-push]

/runbook-run <name>                      run from the first selectable step
/runbook-run <name> --from N             begin selection at step N
/runbook-run <name> --only N             run exactly step N, then stop
/runbook-run <name> --model sonnet       override the header model for this run
/runbook-run <name> --no-commit          write the bookkeeping, commit nothing
/runbook-run <name> --no-push            commit as usual, skip the push

/runbook-list [<STATUS>]
/runbook-clean [<name> ...] [--no-commit] [--no-push]
```

`--from` and `--only` do not weaken dependencies: a selected step whose
`Depends on:` are not all `[x]` stops the run with the unmet dependency named. A
user who completed that work elsewhere marks it `[x]` by hand, which is a
visible, committed act rather than a silent flag.

The three result cases:

| Result | Action |
|---|---|
| `QUESTIONS FOR USER` | relay, collect the answer, send it to the same subagent, repeat |
| `DONE` + report | mark `[x]`, write `Done:`, propagate facts, update `Steps:`, commit, continue |
| anything else, or a report of failure | mark `[!]`, write `Done:` with the reason, set the index to `[FAILED]` with `Failed at:`, halt, report |

An ambiguous report is a failure, not a success. A report the orchestrator cannot
confidently classify halts the run — the alternative is ticking a step on a
guess, and the whole value of the `Done:` line is that it is true.

The `requires:` graph, using the field from
[shared-phase-engine](./shared-phase-engine.md):

```yaml
# skills/runbook-run/SKILL.md          (none — it is the dependency)
# commands/runbook-create.md
requires: skill:runbook-run
# commands/runbook-list.md
requires: skill:runbook-run
# commands/runbook-clean.md
requires: skill:runbook-run
# skills/runbook-suggest/SKILL.md
requires: command:runbook-create
```

`runbook-suggest`'s edge is the one judgment call in that graph: it cites no
shared file and needs no schema, so unlike the other three it has no mechanical
dependency. What it has is a proposal that is useless if the command it names is
not installed, and `requires:` exists to stop exactly that — an agent following a
path, or here a command name, that does not resolve. It depends on the command
alone and does not pull the whole suite in.

`runbook-list`'s edge is about vocabulary rather than parsing: the status set and
the index block shape are specified once, in `references/runbook-schema.md`, and
a listing carrying its own copy is the second copy that drifts.

Hard contracts:

- Steps are sequential. Always.
- The orchestrator writes exactly two files.
- A prompt block is never edited by a run.
- No step is ticked before its subagent's result has actually arrived.
- Never two concurrent runs of one runbook.
- No step invokes `/runbook-run`.
- Shipped bodies reference `${CLAUDE_HOME:-...}` paths, never `~/.claude`, and
  never any path under `docs/`.

All five artifacts need `name`, `version`, `type`, `description` frontmatter per
[docs/authoring-guide.md](../../../docs/authoring-guide.md), starting at
`version: 0.1.0`. Root `VERSION` takes a minor bump.

## Dependencies

- **Task 125** — the `requires:` frontmatter field and its install-time
  resolution, from [shared-phase-engine](./shared-phase-engine.md). **Every task
  derived from this feature preconditions on it.** Four of the five artifacts
  declare `requires:`, and without the field they can be installed with their
  dependency absent — a command citing a schema file that is not there, or a
  skill proposing a command that does not exist.
- **Internal ship order**, forced by that graph: `runbook-run` first (it is the
  dependency and ships the two reference files), then `runbook-create`, then
  `runbook-list` and `runbook-clean`, then `runbook-suggest` last.
- Subagent spawning, with results arriving asynchronously and nesting confirmed
  to depth 3 (verified 2026-08-24). Depth 3 means the orchestrator may itself be
  a subagent, which is what allows a runbook to be driven from a batch parent.

## Open questions

None outstanding. Every question raised while architecting this feature was
settled with the user on 2026-08-24 and is recorded above as a decision: the
depth-4 warning, the header-only `Model:`, per-step re-reading as the
reconciliation mechanism, the one-run-per-runbook rule and its same-tree
exception, most-recent-list selection in conversation mode, the absence of a
`Produces:` field, the prohibition on nested runbooks, the absence of a
`[RUNNING]` staleness signal, `/runbook-clean`'s parity with `/task-clean`, and
tuning `runbook-suggest`'s description after observation rather than before.
