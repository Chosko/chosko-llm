---
name: runbook-run
version: 0.15.0
type: skill
description: Execute a runbook under .claude/runbooks/ one step at a time, each in a fresh subagent by default, relaying its questions to the user, recording what each did and committing after every step. Use it to carry out a runbook, whole or a range of its steps.
requires: command:follow-ups
---

# /runbook-run
# Global skill: execute a runbook, one step at a time, each in a fresh
# subagent (or, under --inline, in this session). Relays questions to the
# user, records what each step did, and commits after every step. Steps run
# one at a time, never in parallel; list position is the order, a step's
# number a stable id. In the default mode the orchestrator reads only
# CLAUDE.md, the runbook and the index, writes only the runbook and the
# index, and never does a step's work or second-guesses a subagent. It is
# quiet between steps — one line per step, no narration — and its closing
# report is the record of the run. Under
# --inline this session executes each selected step itself under the fixed
# rule set in `references/inline-contract.md`, with the bookkeeping
# unchanged; --inline is refused beside --relay-spawns or --model, and the
# header `Model:` is not applied. --steps composes with --from and is
# refused beside --to or --only. Where a subagent cannot spawn a subagent, a
# step's agent ends with a SPAWN REQUEST that the orchestrator serves at its
# own nesting level. A legacy body at `.claude/runbooks/<name>.md` is
# renamed to `<id>-<name>.md` lazily, never while [RUNNING], per
# `references/body-migration.md`. Also carries, under `references/`, the
# files the rest of the runbook suite and the pipeline revision surface
# read by path: `runbook-schema.md`, `subagent-contract.md`,
# `body-migration.md` and `step-amend.md`. Every run ends with one
# /follow-ups call, skipped silently when that command is not installed.
# Usage: /runbook-run <id|name|id-name>
#        /runbook-run <id|name|id-name> --from N        (begin selection at step N)
#        /runbook-run <id|name|id-name> --to N          (stop after step N)
#        /runbook-run <id|name|id-name> --from X --to Y (run steps X through Y inclusive)
#        /runbook-run <id|name|id-name> --only N        (run exactly step N, then stop)
#        /runbook-run <id|name|id-name> --steps N       (run at most N steps, then stop)
#        /runbook-run <id|name|id-name> --from X --steps N (start at step X, run N steps)
#        /runbook-run <id|name|id-name> --model sonnet  (override the header model)
#        /runbook-run <id|name|id-name> --inline        (execute the selected steps in this session)
#        /runbook-run <id|name|id-name> --relay-spawns  (force the spawn relay for this run)
#        /runbook-run <id|name|id-name> --no-commit     (write the bookkeeping, commit nothing)
#        /runbook-run <id|name|id-name> --no-push       (commit as usual, skip the push)
# Examples: /runbook-run implement-ecc-import
#           /runbook-run 3-implement-ecc-import
#           /runbook-run 3 --from 12
#           /runbook-run 3 --from 4 --to 9
#           /runbook-run 3 --from 4 --steps 2
#           /runbook-run implement-ecc-import --only 4 --model sonnet
#           /runbook-run 3 --inline --from 4 --steps 2

GOAL
Take a runbook and execute it. For each step, in order: spawn one subagent
with a fresh context and the assembled prompt, wait for its result, relay any
question it asks to the user and the answer back to it, then record what it
did and commit.

That is the default mode. The one opt-in exception is `--inline`: the
orchestrating session executes each selected step itself, in place of the
spawn-and-wait, and everything else — selection, markers, `Done:` lines, the
index, fact propagation, commit cadence — is exactly as above. See THE INLINE
MODE.

> **Install path assumption:** this skill installs beside the features that
> read it — `chosko-llm add skill:runbook-run` writes it under the same home
> those features are installed into, whichever home that is. The two
> reference files this
> body reads are
> `./references/runbook-schema.md`
> and
> `./references/subagent-contract.md`.
> A third,
> `./references/inline-contract.md`,
> is read **only when `--inline` is passed** — it holds the inline rule set
> that replaces the subagent contract's OPERATING RULES under that flag — so a
> default run never loads it.
> Another,
> `./references/body-migration.md`,
> is read **only when the migration check fires** in step 1 — a legacy body
> to rename — so a run with nothing to migrate never loads it.
> A fifth,
> `./references/step-amend.md`,
> sits beside them: this body never reads it — it holds the rules for
> amending one step, read by path by whatever amends one.
>
> Every one of those paths is **relative to the citing body**, never an
> absolute home path — `./references/<file>.md` from this body,
> `../runbook-run/references/<file>.md` from a file at another skill's root,
> `../../runbook-run/references/<file>.md` from a file under another skill's
> `references/`, and `../skills/runbook-run/…` from a command. That is scope-proof by construction.
> `CLAUDE_HOME` still governs where `install.sh` and the `scripts/cmd-*.sh`
> verbs *write* — including `--local`, which repoints the whole home to
> `$PWD/.claude` — but a shipped body cannot re-derive it at run time,
> because the executing agent expands `${CLAUDE_HOME:-$HOME/.claude}` itself
> and always lands on the global home. Citing body and cited file are always
> siblings under one root, so a relative path is correct in either scope with
> no probing and no fallback.

---

## WHAT THIS SKILL READS AND WRITES

**It reads three files.** The project's `CLAUDE.md`, the runbook (the body
at the path its index block's `File:` line holds), and the index (`.claude/RUNBOOKS.md`) — plus
the reference files above, which are part of this skill. It does **not**
open `.claude/context/`, `.claude/domain/`, or any source file. It touches no
source, so orienting in the codebase would be wasted tokens; orienting is each
step's subagent's job, and the spawned prompt tells it to.

**It writes two files.** The runbook and the index. Nothing else. Every other
change in the tree is made by a subagent. This is a hard contract: an
orchestrator that starts patching things is one that has lost track of what it
delegated.

**It never does a step's work.** One fresh subagent per step does it.

These three are **default-mode contracts**. Under `--inline` — their one
opt-in exception — they hold for the session's **bookkeeping phase** and give
way only in its **execution phase**, where the session reads what the step
needs and makes the step's changes itself, but still never writes the runbook
or the index. See THE INLINE MODE.

**It does not review** — in either mode. It reads three markers — `QUESTIONS FOR USER`,
`SPAWN REQUEST` and `DONE` — and classifies on them. It does not re-test, re-read a subagent's
diff, or second-guess its commit. Under `--inline` it classifies on the
session's own stated outcome and never re-inspects the session's own diff.
Review is `/task-review`'s job and is
invoked, when it is wanted, from inside a step's own prompt.

---

## CHAT OUTPUT

**Quiet between steps, exhaustive at the end.** While the loop runs, print one
line per step, at that step's end and nowhere else — `Step 4 done (abc1234).
Starting step 5.`, or the failure line the halt already calls for. Do not
narrate spawning, waiting, classifying a result, writing a `Done:` line or
committing: those happen every step, and the fragments are hard to read back
once the run is over. Two things are never suppressed and go through exactly as
today: a relayed `QUESTIONS FOR USER` block, verbatim, because a run that needs
an answer asks for it at once, and the spawn relay's own lines. The record of
the run is the closing report, not the transcript above it. The same rule holds
under `--inline`.

---

## ARGUMENTS

| Argument | Effect |
| --- | --- |
| `<id>` \| `<name>` \| `<id>-<name>` | The runbook to run. Required. The numeric id the index assigns it, its kebab-case name, or the two joined as in its body's file name — resolved by the rule in `runbook-schema.md` § *The store*. |
| `--from N` | Begin selection at step N — steps listed above it are not considered. |
| `--to N` | Stop after step N — steps listed below it are not considered. Inclusive: step N itself runs. |
| `--only N` | Run exactly step N, then stop. Exactly equivalent to `--from N --to N`. |
| `--steps N` | Run at most N steps in this run, then stop. N is a positive integer. Composes with `--from`; refused beside `--to` or `--only`. |
| `--model <model>` | Override the runbook header's `Model:` for **this whole run**. There is no per-step model. |
| `--inline` | Execute every selected step in **this session** instead of in a fresh subagent, for the whole run. Composes with `--from`, `--to`, `--only`, `--steps N`, `--no-commit` and `--no-push`, and changes nothing about selection or committing. Refused beside `--relay-spawns` or `--model`; the header `Model:` is not applied. See THE INLINE MODE. |
| `--relay-spawns` | Force the spawn relay for the whole run, for an environment already known to be flat. Without it the relay still works — the step's own subagent triggers it when it finds it cannot spawn. See THE SPAWN RELAY. |
| `--no-commit` | Do the work and write the bookkeeping, but commit nothing. Implies `--no-push`. |
| `--no-push` | Commit each step as usual, skip the push. |

`--from` and `--to` compose: `--from X --to Y` runs steps X through Y
inclusive and stops. Either bound stands alone — `--from X` with no `--to` runs
to the end, `--to Y` with no `--from` starts wherever selection normally would.
There is one selection model, not three: `--only N` **is** `--from N --to N`,
and everything said about the bounds below holds for it unchanged.

Each bound names a step **by id** and cuts the list **at that step's
position**: order is list position and the id carries none, per
`runbook-schema.md` § *A step*. On a body whose ids run in numeric order that
is the same as comparing numbers; on one carrying a step inserted with
`/runbook-create --append --before` / `--after`, it is what keeps the range
the stretch of steps the run actually walks.

`--steps N` limits the run by count rather than by id, inside the same
selection model: selection works exactly as it would without it, and once N
steps have run in this run, the run stops. It composes with `--from` only —
`--from X --steps N` begins selection at step X and runs at most N steps from
there. The count is of steps **actually executed in this run**: a step counts
when it was executed and its outcome reached step 8 as `DONE` — by a spawned
subagent or, under `--inline`, by this session. Steps
already `[x]` never count, because selection never picks them; a resumed `[~]`
step or a re-run `[!]` step counts like any other selected step. The count is
applied against the body re-read every step, like the bounds — no fixed list is
resolved up front, so a step appended mid-run is selectable and counted.
Reaching the count stops the run the way reaching a `--to` bound does — see
step 8. Fewer than N selectable steps is not an error: the ordinary branches
apply unchanged (completion, deadlock, or a failure's halt).

`--from`, `--to`, `--only` and `--steps` **do not weaken dependencies.** A step
selected under any of them whose `Depends on:` are not all `[x]` stops the run,
naming the unmet dependency. The remedy is not a flag: the user marks that step
`[x]` by hand, which is a visible, committed act rather than a silent override.

`--inline` decides how each selected step is executed, never which steps are
selected or how many run: it is orthogonal to all four selection flags and to
`--no-commit` / `--no-push`.

Six argument errors — name the problem and stop, having run nothing:

- `--only` together with `--from` or `--to`. It is already both of them.
- `--to Y` naming a step listed above step X of `--from X`. An empty range is
  a typo, not a request.
- `--steps` together with `--to` or `--only`. Two stopping conditions at once
  would need a precedence rule; `--steps` composes with `--from` alone.
- `--steps` with a missing value, or a value that is not a positive integer
  (`0`, `-1`, `abc`). `--steps 0` would be a silent do-nothing run.
- `--inline` together with `--relay-spawns`. There is no step subagent to relay
  for.
- `--inline` together with `--model`. The session's model cannot be changed
  from inside the run.

A bound naming a step the body does not hold yet is **not** an error. Steps are
appended mid-run by `/runbook-create --append`, and step 2 re-reads the body
every step, so `--to 20` on a runbook that has ten steps today is a legitimate
way to say "through step 20, however many exist by then": until step 20
exists the bound cuts nothing, and from the re-read where it appears the run
stops after it, wherever in the list it was written.

A bound that selects nothing — every step in range is already `[x]`, or the
`--from` step does not exist yet — is not an error either, but it is never
silent: say which range was asked for and that nothing in it remained, and
stop. Doing nothing quietly is indistinguishable from a bug.

---

## THE ARTIFACT

The store, the body schema, the four step markers and the `Done:` line, the
four-status vocabulary, and the index block are all specified in
`./references/runbook-schema.md`.
Read it before parsing or writing either file. Nothing about the artifact is
restated here — a second copy is the copy that drifts.

---

## THE EXECUTION LOOP

### 1. Resolve

Resolve the argument to exactly one runbook by the resolution rule in
`runbook-schema.md` § *The store*, then read that runbook's block in
`.claude/RUNBOOKS.md` and the body at the path the block's `File:` line holds —
never a path built from the name. The name of the resolved block is what the
rest of the run uses: reports, relay blocks and the spawned prompt all name the
runbook, never its id.

If the index predates ids, backfill it per `runbook-schema.md`
§ *Backfilling an index written before ids* before resolving, and read `File:`
only after that. This skill writes the index every step, so it is one of the
three commands that performs the backfill rather than working around it.

- **Unknown argument** — report the available runbooks (from the index) and
  stop. Never guess at a near match, and never fall back from an id that
  matched nothing to a name that looks similar.
- **A compound whose halves disagree, or an ambiguity** — report it as the
  schema's rule says, and stop.
- **`File:` naming a file that does not exist** — report it and stop.
- **`[DONE]` runbook, with no `--only` / `--from` / `--to`** — say so and stop.
  Doing nothing quietly is indistinguishable from a bug. `--steps` is a count,
  not a range: `--steps` alone on a `[DONE]` runbook stops here too.
- **`[RUNNING]` runbook** — see ONE RUN PER RUNBOOK below. Usually this stops
  the run.
- **`[FAILED]` runbook** — proceed. The failed step is re-runnable and its
  failure is already recorded in its `Context:`.

Then run the pull-at-start half of the commit-and-push protocol (see COMMIT
CADENCE) unless `--no-commit` or `--no-push` was passed. Nothing but an id
backfill has been written at this point, so a pull conflict stops the run
before any rename.

**The migration check** comes after that pull, never before it. Re-read the
runbook's block from the index as it now stands — a pull may have brought
another machine's `[RUNNING]` or a changed `File:` — and re-apply the stops
above to it. Then, on a runbook that is not `[RUNNING]`, and before step 4
first marks it `[RUNNING]`, apply the check in `runbook-schema.md` § *The
store*: when the file name in `File:` does not begin with `<id>-`, read
`./references/body-migration.md`
and migrate the body as it says. On no hit, that file is never opened. A
`[RUNNING]` runbook — a resume — never migrates. Do not migrate under a
condition that stops the run.

Whatever path results — the `File:` path as read, or the new one after a
migration — is **the resolved path**, and the run uses it for its whole life:
every re-read, every write and every commit. Step 1 is not redone mid-run.

Under `--inline`, read
`./references/inline-contract.md`
here, once, and give the run's opening line — see THE INLINE MODE
§ *The opening line*.

### 2. Re-read the body

**At the start of every step, not once per run.** Re-open the body at the
resolved path from step 1 and re-parse it.

This is deliberate and does two jobs. It reconciles a body edited by hand
between steps — the index is a summary and the body is the source of truth, so
re-reading *is* the reconciliation. And it is what makes steps appended
mid-run by `/runbook-create --append` visible to the run already in progress.
There is no separate reconciliation mechanism because this one is free.

### 3. Select

The first step in list order — top to bottom, whatever its id — whose marker
is `[ ]`, `[~]` or `[!]`, and whose every `Depends on:` step is `[x]`. Under
`--from N`, skip the steps listed above step N. Under `--to N`, skip the steps
listed below step N. Under `--only N`, consider only step N — which is those
two rules with the same N, not a third rule.

The bounds are re-applied against the body step 2 just re-read, every step, not
resolved once into a fixed list. A step appended mid-run inside the range is
therefore run, and one appended outside it is not. `--steps N` changes nothing
here: it selects no differently, and is checked in step 8 after each commit.

- A `Depends on:` id with **no step in the body** is satisfied when it is on
  the header's `Archive:` line: `/runbook-prune` removed that step and an
  archived id counts as `[x]` (`runbook-schema.md` § *An archived id counts as
  `[x]`*). Resolve it from the header, not as a dangling reference, and do not
  rewrite the `Depends on:` line.
- A **`[~]`** step is one a previous run was interrupted in. Report it as such
  and re-run it.
- A **`[!]`** step is re-run with its failure already recorded in `Context:`
  by the run that failed. Do not re-record it.
- If steps remain but **none is selectable**, that is a dependency deadlock:
  report the blocked steps and, for each, the dependencies that are not `[x]`,
  and stop. Do not pick one anyway.
- If **no steps remain** — every step is `[x]` — go to step 8's completion
  branch.
- If steps remain but **none of them is in range**, the bounded run is over:
  go to step 8's `--to` branch, not the completion branch and not the deadlock
  branch. Nothing is blocked; the range simply ran out.

### 4. Mark

Set the selected step's marker to `[~]` in the body, and the index `Status:`
to `[RUNNING]`. Write both to disk now, before spawning — or, under
`--inline`, before the execution phase begins.

The `[~]` marker is **never committed** — it is in-run working state, and it
is the resume signal (see ONE RUN PER RUNBOOK).

### 5. Spawn

Spawn **one** subagent with fresh context, the assembled prompt (see THE
SPAWNED PROMPT), and the model from the runbook header — or from `--model`,
which overrides it for the whole run.

One at a time. Never two — see THE SPAWN RELAY for the one exception, a
relayed child running while its caller is suspended. Steps are sequential
always, even where the runbook declares them independent: the user gets one question stream rather than
interleaved clarifications from three agents, and two agents writing `Done:`
lines into the same runbook race on the same file.

**Refuse a nested runbook.** If the step's prompt block invokes
`/runbook-run`, do not spawn it. Mark the step `[!]`, write a `Done:` line
opening with the reason, set the index to `[FAILED]` with `Failed at:`, and
stop. The reason to give: the orchestrator occupies one nesting level and the
step's agent a second, so a nested orchestrator would leave nothing for the
work. `/runbook-create` rejects such a step at authoring time; this check is
what stops a hand-written runbook smuggling one in.

**Under `--inline`**, spawn nothing. The **execution phase** takes the place of
this step and step 6: the session assembles the step's brief and executes it
itself, under the inline contract — see THE INLINE MODE. No other loop step
changes. The nested-runbook refusal above still applies, unchanged: check it
before the execution phase begins, and refuse the step exactly as written.

### 6. Wait

**This is the single most dangerous point in the whole feature.**

A spawn returns **asynchronously**: the call yields an id, and the agent's
result arrives later as a separate notification. The return value of the spawn
call is *not* the result. A body that treats it as the result ticks a step
that never ran and commits the lie.

Nothing happens until the result actually arrives. Do not mark, do not write a
`Done:` line, do not commit, do not select the next step. **No step is ticked
before its subagent's result has actually arrived.**

**Under `--inline`** there is no spawn and no notification. The execution
phase instead ends with the session **writing out its own outcome as a
separate act**, before any bookkeeping is written — see THE INLINE MODE
§ *Ending the execution phase*. The rule carries over unchanged in substance:
**no step is ticked before its outcome exists.** The inline form of treating a
spawn's return value as the result is ticking a step whose work did not
finish.

### 7. Handle the result

Four cases, and only four — see THE FOUR RESULT CASES below. Under `--inline`,
the outcome the execution phase wrote out is classified by those same four
cases.

### 8. Commit and loop

Commit the runbook and the index per COMMIT CADENCE, then loop back to step 2
and re-read the body.

When no `[ ]` steps remain — every step is `[x]` — set the index `Status:` to
`[DONE]`, commit, and give the closing report (THE CLOSING REPORT), naming the
runbook and the number of steps.

**Reaching a `--to` bound is not completion.** When the selected step was the
last one in range, stop there instead of looping, and set the index back to
`[PENDING]` unless every step in the *whole* runbook is now `[x]` — a bounded
run leaves work behind by design, and marking that `[DONE]` would be a lie. The
report says which range ran, and carries the steps remaining outside it as a
*Needs you* item. `--only N` stops this way too; it is the bound `--to N`
doing it.

**Reaching the `--steps` count is not completion either.** When the step just
committed is the N-th step executed in this run, stop there instead of looping,
exactly as at a `--to` bound: set the index back to `[PENDING]` unless every
step in the whole runbook is now `[x]` (then it is `[DONE]` by the completion
rule above), and report how many steps ran, with the steps remaining as a
*Needs you* item.

Whichever of those three ended the run, the closing report is not the last
thing the run does — CLOSING THE RUN is.

---

## THE INLINE MODE

`--inline` is opt-in and a property of the **whole run**: every step the run
selects is executed by this session, none by a subagent. There is no per-step
mode and no mixing modes within one run. It is never the default.

### The opening line

An `--inline` run opens with one line, given once, before the first step,
saying that the selected steps **share one context** — this session's — and
that `--steps N` is what limits how many run. The same line names the runbook
header's `Model:` as **not applied**, once: the session runs on its own model
and cannot switch it.

### The two phases

Each inline step alternates between two roles, and the boundary between them
is what keeps the default mode's *the orchestrator never patches work*
discipline without a second agent:

- **Bookkeeping phase** — loop steps 1–4 and 7–8: resolve, re-read, select,
  mark, classify, write `Done:`, propagate facts, commit. Here the session is
  the orchestrator, exactly as in the default mode: it reads only `CLAUDE.md`,
  the runbook and the index, and writes only the runbook and the index.
- **Execution phase** — in place of steps 5 and 6. The session executes the
  step as a step's agent would: it orients per `CLAUDE.md`'s navigation
  instructions, reads what the step needs, and makes the step's changes and
  commits through whatever skill the prompt invokes. **It never edits the
  runbook or the index** during this phase.

### The brief and the inline contract

The session assembles the same brief THE SPAWNED PROMPT describes — parts 1–5:
preamble, `Companion:` background, `## Do not re-propose`, `Context:`, the
verbatim prompt block — and works through it in that order. In place of part
6, the OPERATING RULES, it follows the fixed rule set in
`./references/inline-contract.md`,
read once in step 1. Nothing else in the brief changes; the prompt block is
still verbatim and still immutable.

### Ending the execution phase

The execution phase ends with the session writing out its own outcome, as a
**separate act**, before any bookkeeping is written: either a `DONE` report
naming the commit sha(s) with their diffstat, plus any decision or wrong
premise a later reader would be misled without, or a plain statement of
failure. Step 7 classifies that written outcome
by THE FOUR RESULT CASES.

- An outcome the session cannot state confidently is a **failure**, exactly as
  an ambiguous subagent report is.
- Classification runs on the written outcome alone. It **never re-inspects the
  session's own diff** — the orchestrator does not review, in either mode.

### What does not change

Nothing records the mode. `Done:` lines, step markers, `Steps:`, index
statuses, `Failed at:`, the resume signal and COMMIT CADENCE are identical to
the default mode, so a runbook partly run inline and resumed spawned (or the
reverse) is consistent by construction. `[~]` is never committed. The
bookkeeping commit stages only the runbook and the index; the step's own work
commits through its own skill's explicit staging, beside it.

---

## THE SPAWNED PROMPT

Assembled in this fixed order, so the operating rules are the last thing the
agent reads.

**Parts 1–4 are the only text the orchestrator writes, and they stay
minimal.** They never restate anything the step's own prompt will cause the
agent to read — a task body that `/task-implement <N>` opens anyway, the
feature document behind it, context files, the backlog. The agent does the
reading; the orchestrator orchestrates. So the orchestrator **never opens a
step's task body, or any document the step names, in order to compose these
parts** — the same read scope that keeps it from doing the step's work
(`CLAUDE.md`, the runbook and the index) bounds what it may read to write the
prompt. The preamble carries exactly what the agent cannot derive: the
navigation instruction, the runbook name and the step number — plus the one
`--relay-spawns` sentence below, when that flag is passed. Parts 2–4 carry
what the runbook itself holds, under their own rules below. Parts 5 and 6 are
outside this rule: one is verbatim, the other fixed text.

1. **Preamble.** Orient in a fresh session: tell the agent to read the
   project's `CLAUDE.md` and follow its navigation instructions **as written**
   — the index of each navigation layer, then only the files relevant to this
   step, never a whole layer. Name the runbook and the step number this agent
   is executing; that is what lets a step's subagent call
   `/runbook-create --append` with no name argument.

   **Under `--relay-spawns`, and only then, the preamble also carries one
   sentence**: do not spawn a subagent even if you can — route every child
   through the relay, exactly as OPERATING RULES describes for an agent that
   cannot spawn. This is the flag's only effect on the assembly, and it lives
   here because part 6 is fixed text: its relay rule fires on *cannot spawn*,
   which is precisely not this case, and editing it per run would break the
   one property that makes it a contract.
2. **Background.** The `Companion:` document named in the runbook header, if
   there is one. Offer it as background to read if needed, not as required
   reading.
3. **Do not re-propose.** The runbook's trailing `## Do not re-propose`
   section, if present. It is global to the runbook and goes into **every**
   spawned prompt, not only the next one.
4. **Context.** The step's `Context:` bullets, if any. Skip the section
   entirely when `Context:` is `none`.
5. **The prompt.** The step's fenced ```prompt``` block, **verbatim**. Never
   paraphrased, never trimmed, never merged with the surrounding material, and
   never "improved". If it is a bare slash command, it is passed as a bare
   slash command.
6. **OPERATING RULES.** Verbatim from
   `./references/subagent-contract.md`,
   with only that block's three placeholders filled in: `<RUNBOOK>` with the
   runbook's name, `<N>` with the step id, and `<FILE>` with the resolved path
   from step 1. It is fixed text and goes last.

---

## THE FOUR RESULT CASES

| Result | Action |
| --- | --- |
| `QUESTIONS FOR USER` | Relay to the user, collect the answer, send it to the **same** subagent, repeat. |
| `SPAWN REQUEST` | Spawn the child it asks for, and reply to the **same** subagent when the child is finished. See THE SPAWN RELAY. |
| `DONE` + report | Mark `[x]`, write the `Done:` line, propagate facts, update `Steps:`, commit, continue. |
| Anything else, or a report of failure | Mark `[!]`, write a `Done:` line opening with the reason, set the index to `[FAILED]` with `Failed at: step <n> — <reason>`, halt, report. |

**An ambiguous report is a failure, not a success.** A report the orchestrator
cannot confidently classify halts the run. The alternative is ticking a step
on a guess, and the whole value of the `Done:` line is that it is true. A
report with no `DONE` marker, no commit sha where one was clearly expected, or
a narrative that trails off is ambiguous — halt.

**Under `--inline`** the result is the outcome the execution phase wrote out
(THE INLINE MODE § *Ending the execution phase*), classified by the same four
rows. An outcome the session cannot state confidently is ambiguous and
therefore a failure, and classification never re-inspects the session's own
diff. A top-level inline session asks its questions directly rather than
producing a `QUESTIONS FOR USER` result, and spawns a wanted child itself
rather than producing a `SPAWN REQUEST` — see the relays below.

### On `DONE`

Write the `Done:` line from the agent's report, in the terse default form
`runbook-schema.md` § *The `Done:` line* gives —
`Done: <YYYY-MM-DD>, commit `<sha>` (<N> files, +<X>/-<Y>).` — taking the sha
and the diffstat from the report, never from git. Add a decision or a wrong
premise only when it passes that section's test: a later reader of this runbook
would be misled without it. Review tallies, touched files, restated prompt or
task content and resumption narrative stay off the line even when the report
carries them. The same form applies under `--inline`. Then set
the marker to `[x]`, update the index's `Steps:` count (`[x]` steps plus every
id on the header's `Archive:` line — `runbook-schema.md` § *The index block*), and
propagate facts (below).

### On failure

Do not retry the step, do not attempt the work yourself, and do not continue
to the next step. Give the closing report (THE CLOSING REPORT): which step
failed, its reason and what the agent said, and which steps were never started,
as *Needs you* items; one line for each step that did complete before it under
*For the record*. Then make the closing
call — a halted run is a run that ended, and it is the one most likely to
strand unrecorded work. See CLOSING THE RUN.

---

## THE QUESTION RELAY

**The orchestrator compresses; it does not answer.**

A relayed question is rendered as one fixed block:

```
Step 3 of 7 — Peer review — the agent is asking (round 1):

  <the question in one or two lines>

  a) <option> — <what it costs>
  b) <option> — <what it costs>

Recommendation: (b), because <one line>.
```

At an **approval gate**, the full draft follows the block **verbatim and
unabridged**. This is the one place the orchestrator must not compress: a
summarized draft cannot be approved, and an approval given against a summary
approves something the user never saw.

The user's answer is relayed to the **same** subagent, whose context is
intact — never to a fresh one, which would have to be re-briefed and would
answer differently. The loop repeats for as many rounds as it takes; the round
number in the block is what tells the user where they are.

The orchestrator **may** add facts it already holds — a `Done:` line from an
earlier step that answers the question — and must say that it is doing so, so
the user can see which part of the block came from the agent and which from
the runbook. It **may never** invent a decision on the user's behalf, and it
never asks the user to re-state something an earlier step already settled.

**When the orchestrator is itself a subagent** — a runbook driven from a batch
parent, which the depth budget permits — there is no user to ask. It emits the
same fixed relay block as its own final turn, under a `QUESTIONS FOR USER`
heading, for its parent to carry, and resumes when the answer comes back. It
never answers on the user's behalf in either position.

**Under `--inline`** there is no relay hop: the asker is the session itself.
A top-level session **asks the user directly**, in the fixed block headed
`Step <n> of <total> — <title> — asking (round <r>)`, with any approval-gate
draft verbatim and unabridged. It never answers its own question, and never
skips a gate the step's skill defines because it "already knows" the answer.
The subagent-position rule above is unchanged: an inline session that is itself
a subagent ends its turn under `QUESTIONS FOR USER` and resumes when the answer
returns.

---

## THE SPAWN RELAY

**The orchestrator forwards; it does not read.**

**Under `--inline` this section has no role** — the relay, its eight-round
cap and `--relay-spawns` alike. There is no step subagent to relay for: a step
that wants a child has the session spawn it directly, one level down, per the
inline contract, and the step's own skill bounds its own children. That is why
`--relay-spawns` beside `--inline` is an argument error.

In some environments — cloud sessions among them — a subagent cannot spawn a
subagent. A step whose prompt invokes something that wants a child agent
(`/task-implement --review --rounds 2` is the case this exists for) then has
nowhere to put it. The subagent contract tells the step's agent what to do
instead: write the child's prompt to a file under `$TMPDIR`, and end its turn
with `SPAWN REQUEST`. This section is the other half.

### Why it works

The child is spawned **by the orchestrator**, so it sits at the same nesting
level as the caller rather than one below it. That is the whole mechanism: a
level the caller cannot reach downward, the orchestrator reaches sideways. It
needs no extra depth and works identically wherever the run is driven from.

### The protocol

On a `SPAWN REQUEST` result, read only the marker and the three lines under it
— `prompt:`, `result:` and `model:`. Then:

1. **Spawn one child subagent**, with the model the request names (or the run's
   model where it says `same`). Its prompt is the `RELAY CHILD RULES` block
   followed by the `OPERATING RULES` block, both **verbatim** from
   `./references/subagent-contract.md`, in the form THE SPAWNED PROMPT part 6
   uses: `<PROMPT>` and `<RESULT>` filled with the request's two paths, and
   `<RUNBOOK>`, `<N>` and `<FILE>` as for any spawn. Compose nothing else.
2. **Wait for the child's result**, exactly as for a step's own agent. The
   spawn call returns an id, not the result.
3. **Classify the child's returned turn exactly as a step's own agent's**, by
   THE FOUR RESULT CASES — on its marker alone, never on the result file. Only
   a `DONE` child reaches step 4.
   - `QUESTIONS FOR USER` or `SPAWN REQUEST` — handle them for the child, as
     *What is preserved* below says, then come back here.
   - **Anything else, or a report of failure** — the step has failed. Mark it
     `[!]`, write a `Done:` line opening with the reason and naming which
     relayed child failed, set the index to `[FAILED]` with `Failed at:`, halt
     and report. Do **not** tell the caller its child is finished: a caller
     told that reads an absent or failure-noting file, finishes its step, and
     the runbook gets a `Done:` line for work that never happened — the one
     outcome this suite exists to prevent.
   - **A `DONE` child, before step 4** — check `<result path>` exists and is
     non-empty, opening nothing; if absent or empty, re-prompt that same child
     once ("Your result file at `<result path>` is missing. Write your full
     report there and end your turn with `DONE`.") and, if it is still absent or
     empty, fail the step exactly as above, the `Done:` line naming the missing
     result file. The re-prompt is not a relay round and does not count toward
     the cap.
4. **Reply to the same caller subagent** — the one that is suspended awaiting
   this — with one line: the child is finished, and its report is at
   `<result path>`. The caller reads the file and continues.

**Open neither file.** Not the prompt, not the result, not "just to check" (an
existence check is not opening) — classification runs on the child's returned
marker, which is why it never needs to.
Forwarding paths is what keeps this cheap: the whole point of routing a child's
work through a file is that its content never passes through the orchestrator's
context. This is the same discipline as the question relay's *compresses, does
not answer* — here it is *forwards, does not read*. It is also what keeps the
orchestrator out of work it delegated: an orchestrator that reads a child's
report is one step from reviewing it.

### What is preserved

- **Sequencing.** The caller is suspended for the entire time the child runs,
  exactly as it is during a `QUESTIONS FOR USER` relay, so only one agent is
  doing work at any moment. This is the one stated exception to *one subagent
  at a time, never two* — two exist, one of them idle — and it is not a wider
  licence: never spawn a child while the caller is still working, and never
  two children at once.
- **The question relay.** A child's own `QUESTIONS FOR USER` is relayed to the
  user exactly as a caller's is, in the same fixed block, and the answer goes
  back to the **child**. Say which agent is asking when a child is the one
  asking.
- **Flat fan-out.** A `SPAWN REQUEST` from a *child* is handled identically —
  the orchestrator spawns that grandchild at its own level too. Nothing nests,
  however deep the logical call chain goes.
- **Failure.** A child that fails fails the step, per protocol step 3. The
  relay extends a step's reach; it does not give it a second chance, and it
  never converts a child's failure into a caller's success.

### The cap

**Eight relay rounds per step.** A round is one `SPAWN REQUEST` served. On the
ninth, stop: mark the step `[!]`, write a `Done:` line saying the relay cap was
reached and naming how many children ran, set the index to `[FAILED]` with
`Failed at:`, and halt. A step that wants a ninth child is looping, and the
alternative to a cap is an unbounded run nobody is watching.

### The files

Relay files live under the OS temp directory, **never inside the repository**.
The subagent contract dictates their names —
`<runbook>-step<n>-round<r>-prompt.md` and `-result.md` — so two runs sharing a
`$TMPDIR` cannot collide; the orchestrator takes the paths the request gives it
and does not relocate or rename them. Nothing about them
is committed — the staging rule under COMMIT CADENCE is unchanged and exact:
the runbook and the index, by explicit path, and nothing else. They are
transient message-passing, not state, and they are gone with the session.

### `--relay-spawns`

Passing it forces the relay for the whole run: the **preamble** of every
spawned prompt — part 1 of THE SPAWNED PROMPT, which is where the flag's one
sentence goes — tells that step's agent not to spawn at all and to route every
child through the relay. The OPERATING RULES block is untouched by it.
Use it where the environment is already known to be flat. **Without it nothing
is lost** — the subagent's own detection is the trigger, and a run in an
environment where nesting works behaves exactly as it always did. The flag
saves an agent discovering the limit for itself; it does not enable the relay.

---

## FACT PROPAGATION

When a step's report changes a fact a later step relies on, append a **dated
bullet** to that later step's `Context:` naming the correction:

```
Context:
- 2026-08-25 (from step 1): parse_frontmatter gates emission on a key
  allowlist — step 4's "verified fact" that it emits every key is wrong.
```

This is the mechanism that makes the whole loop work: what step 1 discovers is
folded into step 4 before step 4 runs, instead of step 4 proceeding on a
premise that is already known to be false.

**The prompt block itself is never edited.** A reader must always be able to
see what was originally asked and what was learned since, separately. New
facts go to `Context:`; the fenced block is the author's, and is immutable for
the life of the runbook.

---

## ONE RUN PER RUNBOOK

Two concurrent runs of the same runbook are forbidden — they race on the same
file.

`[RUNNING]` in the index blocks a second `/runbook-run` of that name: report
the runbook as already running and stop.

The single exception is resuming in the same working tree, and the signal is a
`[~]` marker present in the tree. `[~]` is deliberately never committed, so
its presence locally means **this tree is the one that was interrupted**.

> `[RUNNING]` in the index **plus** `[~]` in the tree is the whole resume
> signal.

There is no staleness heuristic, no timestamp, and no lock file — that would
be state this repo does not keep.

---

## THE DEPTH BUDGET

Stated plainly, because an author needs to know where verified ground ends:

- The orchestrator occupies **one** nesting level.
- The step's agent occupies a **second**.
- Whether anything the step's agent spawns has a level to occupy **depends on
  the environment**. Nesting to depth 3 was verified locally on 2026-08-24; in
  a cloud session a subagent cannot spawn at all, and depth 4 has never been
  probed anywhere.

**The spawn relay is the answer to all of that, and it makes the depth
question mostly moot.** A step whose prompt itself wants a subagent —
`/task-implement --review`, which wants an implementor and then a reviewer —
does not need a third level: its agent routes the child through THE SPAWN
RELAY and the orchestrator spawns it sideways, at the orchestrator's own
level. Nothing nests, however deep the logical call chain goes, so no author
has to know which environment their runbook will run in.

What remains true, and is why this section still exists:

- The relay only fires when the step's agent **notices** it cannot spawn, or
  when `--relay-spawns` forces it. Where nesting works, a step's agent nests as
  it always did — that path is unchanged, and depth 3 remains the verified
  bound on it.
- An agent that nests to depth 3 and then wants a fourth level is past verified
  ground, and its own contract tells it what to do there: request the relay
  rather than improvise.

Depth 3 also means the orchestrator may itself be a subagent, which is what
allows a runbook to be driven from a batch parent — see the question relay's
subagent-position rule above. The spawn relay works from that position too:
the orchestrator spawns the child at its own level either way.

Nested runbooks are the one case that *is* refused; see step 5. The relay does
not change that — a runbook inside a runbook is refused for the orchestration
it duplicates, not for the depth it costs.

**Under `--inline`** there is no second level for the step: the step's work
runs at the **orchestrator's own level**, and any child the step wants is
spawned **one level down** — the level a step's agent occupies in the default
mode. A top-level session can always do that. A session that cannot spawn
follows its own parent's contract, and failing that the step fails, per the
inline contract. The nested-runbook refusal is unchanged.

---

## COMMIT CADENCE

**One commit per completed step**, staging **exactly** the runbook and the
index — the body at the resolved path (its `File:` path) and
`.claude/RUNBOOKS.md`, by explicit path. On the step whose commit follows a
migration in step 1, that commit also stages the old path — held from the
migration, since `File:` no longer names it — so its removal and the rename
land in that commit and no other, per `body-migration.md` § *Staging*. The run still writes only the runbook and the index. Never a
catch-all (`git add -A` / `git add .` / `git add -u`). A
subagent that commits its own work produces a separate commit; the runbook
commit is bookkeeping and is expected to sit beside it.

The `[~]` marker is never committed. By the time a step is committed its
marker is `[x]` or `[!]`; if a commit would capture `[~]`, the step is not
finished and must not be committed.

Then push, following **the commit-and-push protocol** — the repo-wide
convention every committing feature shares:

1. **Pull at start.** Once per run, in step 1, before any step's work begins.
   A conflict stops the run there — report it and tell the user to resolve
   manually and re-run.
2. Commit as specified above: explicit paths only, no empty commits, never
   `--no-verify` / `--amend` / `--no-gpg-sign`. A hook failure is surfaced,
   not bypassed.
3. **Pre-push re-sync.** `git pull` immediately before pushing. A conflict:
   abort the merge, leave the local commit intact, do not push, and report
   that the commit exists locally but could not be synced.
4. **Push.** On failure (rejected, no upstream, no remote) report the exact
   output and stop. Never retry, never force-push.

`--no-commit` writes the bookkeeping into the tree and commits nothing; it
implies `--no-push`. `--no-push` commits every step as usual and skips
steps 1, 3 and 4.

On a non-git VCS — a project whose `CLAUDE.md` defines a `## VCS` section
overriding git — skip the pull → re-sync → push sequence entirely; only the
commit (checkin) step runs.

**The Stop-hook reply.** A cloud sandbox's Stop hook refuses to end a turn on a
dirty tree, and an in-flight step is dirty by design — the `[~]` heading and the
index's `[RUNNING]`, which this section forbids committing. That block cannot
be cleared from here, and it costs one forced turn every time it fires: at each
step start, and at every question relayed to the user.

When that feedback arrives and the only uncommitted changes are the runbook and
the index **you yourself just wrote**, spend nothing on it. Reply with exactly

```
stop hook ignored on runbook WIP
```

and end the turn. No tool call, no `git status`, no explanation — you wrote
those two files one step ago and already know what is dirty. Re-deriving it
costs a few hundred tokens every time and changes nothing.

If anything else is dirty, this is not that case — handle it normally. That
fall-through is the point: the condition is your own two writes, so a genuinely
forgotten commit still gets thought about.

Under `--inline` the same condition answers one more prompt — a step command's
dirty-tree prompt, answered `proceed` — see `inline-contract.md`.

---

## THE CLOSING REPORT

Every run ends with one closing report — at completion, at a `--to` / `--only`
/ `--steps` bound and at a failure halt alike — in two groups, in this order,
each under its heading. It costs no extra reading: every entry is drawn from a
step's `Done:` line and its own report, both already in hand, so the
orchestrator opens no file here that it does not open anywhere else.

- **Needs you** — every item awaiting a decision, numbered `1.`, `2.`, … and as
  long as it needs to be. The feature completion candidates go here: every slug
  a step report named as having all its tasks `[DONE]`/`[SKIP]`, with the one
  question, "Flip to `[DONE]` in FEATURES.md? Name the slugs, or say all /
  none." So do a failed step, with its reason and what the agent said; a step
  left `[~]`, to resume; and the steps left outside the range, outside the
  `--steps` count, or never started.
- **For the record** — one line per step the run executed, in list order, in
  exactly this shape: `<step n> — <outcome, commit sha and diffstat> — <what
  changed in one line; decision or wrong premise flagged; questions relayed and
  their answers>`. Any run-level deviation follows on one line of its own. No
  item in this group runs past one line, and none is a question.

An empty group prints its heading and `none`.

**The numbering is the reply handle**, the same way `/follow-ups`' numbering
is. It starts at 1 in every report, carries no meaning beyond the handle, and a
report with a single item still numbers it.

The flip question is asked once, here. The answer is acted on in conversation
after the run: the write set stays the runbook and the index, and the
orchestrator never writes `FEATURES.md`.

The report reads the same way under `--inline`. There is no opt-out flag.

---

## CLOSING THE RUN

**Every run ends with one `/follow-ups` call.** It fires **once per run —
never per step** — after the run's own closing report is printed, and it is
the last thing the run does.

It fires at every point a run stops, not only at completion:

- when no `[ ]` steps remain and the index went `[DONE]`;
- at a `--to`, `--only` or `--steps` bound;
- at a failure halt — the `[!]` marker and the index `[FAILED]`;
- when the user asks to stop after a step mid-run, **even when the run
  carried no bound to that step**.

A single-step run is not a special case: the end of the one step is the end
of the run.

**What the reading covers.** In the default spawned mode, the orchestrator
reads its own conversation *and the step subagents' result reports* — agents
routinely name their own follow-ups there, and that report is the
orchestrator's only window onto the step. No file is opened to get them, so
WHAT THIS SKILL READS AND WRITES' "It reads three files" is untouched: a
step's result is already in hand by then — step 7 classifies it and the
`Done:` line is written from it. THE SPAWN RELAY's rule against reading a
child's output is about the relay's request and result *files*, which this
never touches. Under `--inline`
nothing changes — there are no step reports, and the session's own
conversation is the whole reading.

Where the user then asks to execute or plan one of the listed follow-ups
that came from a step subagent, forwarding it to that same subagent is often
the convenient thing to do, and is allowed. Judgement, not a rule — this is
not a new relay protocol and adds no round to the cap.

**It changes no bookkeeping.** The call sits outside COMMIT CADENCE: it adds
no commit, and it runs after the index `Status:` (`[DONE]` / `[FAILED]` /
`[PENDING]`) and the run's final commit are already written, so it never
dirties a tree the run just cleaned. The `[~]`-marker rule and the Stop-hook
reply are untouched.

**When `/follow-ups` is not installed, skip the call silently.** The
frontmatter declares `requires: command:follow-ups`, so the dependency
helpers install it alongside this skill; a user who removed it by hand gets
no message and no error. An absent optional closing step is not a run
failure.

---

## DO NOT

- Treat a spawn call's return value as the step's result — or a relayed
  child's. It is an id. Wait for the notification.
- Tick a step before its subagent's result has arrived — or, under `--inline`,
  before the execution phase has written out its outcome.
- In the default mode, execute a step any way but in one fresh subagent.
- Run two steps at once, or two runs of one runbook at once. A relayed child
  running while its caller is suspended is the one stated exception, and it
  does not extend to spawning a child while its caller is still working, or to
  two children at once.
- Open a relay request or result file, relocate one, or stage one. The
  orchestrator forwards paths; reading them is the cost the relay exists to
  avoid, and it is the first step toward reviewing work it delegated.
- Answer a `SPAWN REQUEST` by doing the child's work, by telling the caller to
  do it inline, or by declining it. Spawn the child.
- Let a step exceed eight relay rounds. The ninth is a failure, not a spawn.
- Edit a step's fenced prompt block. Ever. Corrections go to `Context:`.
- Re-derive or re-explain the Stop hook's block on an in-flight step. It fires
  at every step start and every relayed question, and the answer is fixed — see
  **The Stop-hook reply** under COMMIT CADENCE.
- Edit the header, `Sequencing:`, `Companion:`, a step title, a
  `Depends on:` or a `Needs:` line — those are `/runbook-create`'s, by line.
- In the default mode, do a step's work yourself, patch a file a subagent
  should have patched, or fix up a subagent's commit.
- Review, re-test or second-guess a subagent's work — or, under `--inline`,
  re-inspect the session's own diff to classify its outcome. Review is
  `/task-review`'s job, invoked from inside a step's prompt.
- Record the mode anywhere in the runbook or the index.
- Apply `--model` or the header `Model:` under `--inline`.
- Edit the runbook or the index during an `--inline` execution phase.
- Answer the session's own question on the user's behalf under `--inline`, or
  skip a gate because the answer seems known.
- Do the work of a child the session cannot spawn under `--inline`. Follow the
  parent's contract, or fail the step naming the child.
- Answer a subagent's question on the user's behalf, or ask the user to
  re-state something an earlier step already settled.
- Compress a draft at an approval gate.
- Classify an ambiguous report as success.
- Call `/follow-ups` per step. It is once per run, after the closing report —
  see CLOSING THE RUN.
- Skip the closing call because the run stopped at a bound, was stopped by the
  user, or halted on a failure. Those are the runs that most need it.
- Spawn a step whose prompt invokes `/runbook-run`.
- Weaken a `Depends on:` because `--from`, `--to`, `--only` or `--steps` was
  passed.
- Run a step outside `--from` / `--to`, run more than N steps under
  `--steps N`, or mark a runbook `[DONE]` because a bounded run reached its
  `--to` or its `--steps` count. Steps left behind are untouched work, not
  finished work.
- Stage anything but the runbook and the index in a bookkeeping commit.
- In the default mode, or in an `--inline` bookkeeping phase, read anything but
  `CLAUDE.md`, the runbook, the index and this skill's reference files — no
  `.claude/context/`, `.claude/domain/`, or source file — or write anything but
  the runbook and the index.
