# Inline runbook execution

An opt-in execution mode for `/runbook-run`. Under `--inline`, every step the
run selects is executed by the orchestrating session itself instead of by a
freshly spawned subagent. Selection, step markers, `Done:` lines, the index,
fact propagation and the commit cadence are exactly those of the default mode;
only *who executes the step* changes. The default — one fresh subagent per
step — is unchanged.

## Purpose

Spawning a subagent per step buys a clean context and a hard boundary between
orchestration and work, and costs a full re-orientation per step (CLAUDE.md,
navigation indexes, the step's documents) plus the spawn itself. For a short
run of small, closely related steps — a runbook of one-line `/task-implement`
prompts over the same area, or a run the user wants to watch and steer turn by
turn — that cost dominates and the boundary buys little. `--inline` lets the
user trade the fresh context away, knowingly, for that run only.

It restates no part of [runbook-suite](./runbook-suite.md); it names the
contracts of that feature which become mode-scoped under the flag, and what
replaces each.

## Scope and non-goals

In scope: the `--inline` flag, its argument composition, the rules the session
follows while executing a step, and how the default mode's contracts (depth
budget, spawn relay, question relay, reads/writes, fresh context) map onto a
run with no step subagent.

Deliberately out:

- **Making inline the default.** Rejected by the user; opt-in only.
- **Per-step mode.** No `Inline:` step field and no mixing modes within one
  run. The mode is a property of a run, like `--model` is today, and a runbook
  stays executable by either mode without re-authoring.
- **Recording the mode in the artifact.** `Done:` lines, markers and the index
  are written exactly as in spawned mode; nothing says which mode produced
  them. A runbook partly run inline and resumed spawned (or the reverse) is
  therefore consistent by construction.
- **Changing the model.** A skill cannot switch its own session's model;
  `--inline` does not pretend to.
- **Lifting the nested-runbook ban.** A step invoking `/runbook-run` is
  refused under `--inline` exactly as today — it is refused for the
  orchestration it duplicates, which inlining does not change.
- **Parallelism.** Steps stay sequential; inlining makes that trivially true.
- **A context cap.** No automatic limit on how many steps run inline;
  `--steps N` is the user's lever.

## Architecture

Built on the repo's existing shape per the codebase: a change to the shipped
`skills/runbook-run/` skill (see `.claude/context/features.md`), plus its row in
the pipeline-engine routing table.

### The flag and its composition

`--inline` alters step 5 (Spawn) and step 6 (Wait) of the execution loop and
nothing else. It composes with `--from`, `--to`, `--only`, `--steps N`,
`--no-commit` and `--no-push`, because those govern selection and committing,
which inlining does not touch.

Two new argument errors, in the register of the existing ones (name the
problem, stop, run nothing):

- `--inline` beside `--relay-spawns`. There is no step subagent to relay for.
- `--inline` beside `--model`. The session's model cannot be changed from
  inside the run.

### The two phases of an inline step

The session alternates between two roles, and the boundary between them is
what preserves the default mode's "orchestrator never patches work" discipline
without a second agent:

- **Bookkeeping phase** — steps 1–4 and 7–8 of the loop: resolve, re-read,
  select, mark, classify, write `Done:`, propagate facts, commit. Here the
  session behaves exactly as the orchestrator does today: it reads only
  `CLAUDE.md`, the runbook and the index, and writes only the runbook and the
  index.
- **Execution phase** — replaces spawn-and-wait. The session executes the
  step's brief as a step agent would: it orients per `CLAUDE.md`'s navigation
  instructions, reads what the step needs, and makes the step's changes and
  commits through whatever skill the prompt invokes. During this phase it
  never edits the runbook or the index — the subagent contract's rule, applied
  to the session.

The execution phase ends with the session composing its own outcome as a
distinct act — a `DONE` report naming the commit sha(s), the decisions taken
and any premise that proved wrong, or a plain statement of failure — before
any bookkeeping is written. Step 7 then classifies that outcome by the same
four result cases. The *no step ticked before its result exists* rule carries
over: the analogue of treating a spawn's return value as its result is ticking
a step whose work did not finish, and an outcome the session cannot state
confidently is a failure.

### The brief

The session assembles the same brief the spawned prompt carries — preamble,
`Companion:` background, `## Do not re-propose`, `Context:`, the verbatim
prompt block — and executes against it in that order. In place of the
subagent contract's OPERATING RULES it follows a fixed inline rule set, kept
in a reference file beside the contract,
`skills/runbook-run/references/inline-contract.md`, and read only when `--inline` is
passed, so a default run never loads it.

### Replacing the fresh context

A fresh subagent could not carry a half-decision from step 1 into step 4; an
inline session can. The mode replaces the structural guarantee with three
rules and one disclosure:

1. **The brief is the authority.** Each step is executed against its own
   assembled brief. What the session remembers of an earlier step is not an
   instruction.
2. **Records win.** Where the session's memory of an earlier step disagrees
   with that step's `Done:` line or a later step's `Context:` bullet, the
   record is right.
3. **Facts are still written down.** Fact propagation into later steps'
   `Context:` happens exactly as in spawned mode even though the session
   already knows the fact — the record must be true for a resumed or spawned
   run, and rule 2 depends on it existing.
4. **Disclosure.** The run's opening line states that steps share one context
   and that `--steps N` bounds how many do.

### Depth budget and spawn relay

With no step subagent, the step's work runs at the orchestrator's own level.
A step that wants a child (e.g. `/task-implement --review`) has the session
spawn it directly, one level down — the level the step agent occupied in
spawned mode. A top-level session can always do this, which is why the relay,
whose job was reaching that level sideways, has no role and `--relay-spawns`
is refused.

When the session cannot spawn — it is itself a subagent in an environment
that forbids nesting — the step's child has nowhere to go. The session follows
whatever contract its own parent gave it (a runbook-style parent offering
`SPAWN REQUEST` is served that way); otherwise the step fails `[!]`, its
`Done:` line naming the child that could not be spawned and that re-running
the step without `--inline` is the remedy. The session never does the child's
work in its own context — the rule and reason are the subagent contract's,
unchanged.

The eight-relay-rounds cap has nothing to count under `--inline`. The step's
own skill bounds its own children.

### The question relay

At a clarifying question or approval gate reached while executing a step, a
top-level session asks the user directly, rendered in the same fixed block
(`Step <n> of <total> — <title> — asking (round <r>)`) so the user can tell
which step is asking, with any approval-gate draft verbatim and unabridged.
There is no relay hop and no compression step, because the asker and the
user's interlocutor are the same agent — but the prohibition carries: the
session never answers its own question on the user's behalf, and a gate the
step's skill defines is never skipped because the session "already knows"
the answer.

When the inline session is itself a subagent, the default mode's
subagent-position rule applies unchanged: it emits the block as its own final
turn under `QUESTIONS FOR USER` and resumes when the answer returns.

The Stop-hook reply applies unchanged.

### `--model` and the header `Model:`

An explicit `--model` is refused. The header's `Model:` is not applied —
every runbook has one, so refusing on it would make most runbooks
un-inlinable — and the run's opening line names it as not applied, once.
Children the step spawns choose their own models as they would in spawned
mode.

## Data and state

None new. The runbook body and the index are written exactly as in spawned
mode — the `[~]` mark before execution, `[x]`/`[!]` and the `Done:` line
after, `Context:` fact propagation, `Steps:`, `[RUNNING]`/`[PENDING]`/
`[FAILED]`/`[DONE]` with `Failed at:`. `[~]` is never committed.

The resume signal is unchanged: `[RUNNING]` in the index plus `[~]` in the
tree. An inline run is more likely than a spawned one to be interrupted
mid-step (the session is the worker), and resumption — in either mode —
re-runs that step as any `[~]` step is re-run.

Commit cadence is unchanged: one bookkeeping commit per completed step,
staging exactly the runbook and the index, beside whatever commits the step's
own work produced. The step's work commits through its own skill's explicit
staging; the bookkeeping commit never captures it, and the work never captures
the runbook or the index.

## Interfaces and contracts

```
/runbook-run <name|id> --inline                  execute every selected step in this session
/runbook-run <name|id> --inline --from X --steps N
/runbook-run <name|id> --inline --only N
/runbook-run <name|id> --inline --relay-spawns   error
/runbook-run <name|id> --inline --model sonnet   error
```

Composition with `--steps N` (task 208): orthogonal. `--steps` decides how
many selected steps run; `--inline` decides how each is executed. The count's
definition generalises from "its subagent was spawned and its result reached
step 8 as `DONE`" to "it was executed and its outcome reached step 8 as
`DONE`", covering both modes with one sentence.

Contracts of the default mode, and their scope under `--inline`:

| Default-mode contract | Under `--inline` |
|---|---|
| Orchestrator reads only CLAUDE.md, runbook, index | Holds in the bookkeeping phase; the execution phase reads what the step needs |
| Orchestrator writes only runbook and index | Holds in the bookkeeping phase; the execution phase never writes those two |
| Orchestrator does not review | Holds: classification runs on the session's stated outcome, never on a re-inspection of its own diff |
| One fresh subagent per step | Replaced by the brief/records-win/write-it-down rules |
| Spawn relay, `--relay-spawns`, 8-round cap | No role; `--relay-spawns` refused |
| Question relay | Direct ask in the same fixed block; subagent position unchanged |
| `--model` / header `Model:` | `--model` refused; header not applied, stated once |
| Markers, `Done:`, index, commit cadence, resume signal | Identical |
| Nested runbook refusal | Identical |

The skill's frontmatter description, usage header, arguments table and DO NOT
list must reflect that the "never does a step's work" contracts are
default-mode contracts with this one opt-in exception, and the
pipeline-engine routing row lists the flag.

## Dependencies

- [runbook-suite](./runbook-suite.md) — the orchestrator, schema and subagent
  contract this mode is a variant of. Its document describes the
  never-does-the-work contracts unconditionally; reconciling it with the
  exception is part of implementing this feature.
- **Task 208** (`--steps N`) — land first. `--inline`'s composition sentence
  and the generalised count definition are written against it; the tasks
  generated from this feature precondition on it.
- [pipeline-engine](./pipeline-engine.md) — its routing table's `/runbook-run`
  row gains the flag, guarded by `check-routing.sh`.

## Open questions

None outstanding. The mode's scope, composition, refusals, context rules,
relay mapping and model handling are recorded above as decisions.
