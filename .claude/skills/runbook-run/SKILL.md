---
name: runbook-run
version: 0.20.1
type: skill
description: Execute a runbook under .claude/runbooks/ one step at a time, each in a fresh subagent by default, relaying its questions to the user — or, under the `unattended` policy, parking the step that asked and going on — recording what each did and committing after every step. Use it to carry out a runbook, whole or a range of its steps.
requires: command:follow-ups, skill:follow-ups-resolve, skill:interaction-engine
---

# /runbook-run
# Global skill: execute a runbook one step at a time — each step in a fresh
# subagent, or under --inline in this session — relaying its questions to the
# user (or, under the `unattended` policy, parking the step that asked and
# going on), recording what each step did and committing after every step.
# `references/` also holds the files the rest of the runbook suite and the
# pipeline revision surface read by path: `runbook-schema.md`,
# `subagent-contract.md`, `body-migration.md` and `step-amend.md`.
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
#        /runbook-run <id|name|id-name> --unattended    (park a step at a question instead of waiting; pre-ask the parked steps in range first)
#        /runbook-run <id|name|id-name> --attended      (relay and wait, overriding a header `Execution policy: unattended`)
#        /runbook-run <id|name|id-name> --unattended --skip-parked  (no pre-ask; a parked step stays parked)
#        /runbook-run <id|name|id-name> --no-commit     (write the bookkeeping, commit nothing)
#        /runbook-run <id|name|id-name> --no-push       (commit as usual, skip the push)
# Examples: /runbook-run implement-ecc-import
#           /runbook-run 3-implement-ecc-import
#           /runbook-run 3 --from 12
#           /runbook-run 3 --from 4 --to 9
#           /runbook-run 3 --from 4 --steps 2
#           /runbook-run implement-ecc-import --only 4 --model sonnet
#           /runbook-run 3 --inline --from 4 --steps 2
#           /runbook-run 3 --unattended
#           /runbook-run 3 --unattended --skip-parked
#           /runbook-run 3 --inline --unattended

GOAL
Execute a runbook. For each step, in order: spawn one subagent with a fresh
context and the assembled prompt, wait for its result, relay any question it
asks to the user and the answer back to it, then record what it did and commit.

That is the default mode. Its one opt-in exception is `--inline`: this session
executes each selected step itself in place of the spawn-and-wait, and
everything else is unchanged — see THE INLINE MODE.

> **Install path assumption:** this skill installs beside the files it reads
> (`chosko-llm add skill:runbook-run` writes it under the same home as those
> features). Every path below is **relative to the citing body**, never an
> absolute home path — correct in either scope with no probing and no
> fallback: `./references/<file>.md`
> from this body, `../runbook-run/references/<file>.md` from a file at another
> skill's root, `../../runbook-run/references/<file>.md` from a file under
> another skill's `references/`, and `../skills/runbook-run/…` from a command.
>
> | Reference file | Read when |
> | --- | --- |
> | `./references/runbook-schema.md` | Always — before parsing or writing the body or the index. |
> | `./references/subagent-contract.md` | Always — THE SPAWNED PROMPT part 6, and a relay child's rules. |
> | `./references/inline-contract.md` | **Only under `--inline`**, once, in step 1. It holds the inline rule set that replaces the subagent contract's OPERATING RULES under that flag; a default run never loads it. |
> | `./references/parking.md` | **Once, on two triggers only**: when the policy resolves to `unattended` (step 1), or when step 3 selects a `[P]` step or finds one blocking selection. It holds the fifth result row, the end branch that is not a deadlock, unparking, the pre-ask, mid-run answers and the rejections. A default attended run that meets no `[P]` step never loads it. |
> | `../interaction-engine/references/policy.md` | Always — in step 1, to resolve the run's policy. |
> | `../interaction-engine/references/messages.md` | Always — before the first relayed question, gate or closing report. |
> | `../interaction-engine/references/gates.md` | **Only when the policy resolves to `unattended`**, in step 1. |
> | `./references/body-migration.md` | **Only when the migration check fires** in step 1 — a legacy body to rename. A run with nothing to migrate never loads it. |
> | `./references/step-amend.md` | **Never by this body.** It sits beside the others, holding the rules for amending one step, read by path by whatever amends one. |

---

## WHAT THIS SKILL READS AND WRITES

- **Read three files.** The project's `CLAUDE.md`, the runbook (the body at
  the path its index block's `File:` line holds) and the index
  (`.claude/RUNBOOKS.md`) — plus the reference files above, which are part of
  this skill. Do **not** open `.claude/context/`, `.claude/domain/` or any
  source file: orienting in the codebase is each step's subagent's job, and
  the spawned prompt tells it to.
- **Write two files.** The runbook and the index, nothing else. Every other
  change in the tree is made by a subagent. This is a hard contract.
- **Never do a step's work.** One fresh subagent per step does it.
- These three are **default-mode contracts**. Under `--inline` — their one
  opt-in exception — they hold for the session's **bookkeeping phase** and
  give way only in its **execution phase**, where the session reads what the
  step needs and makes the step's changes itself, but still never writes the
  runbook or the index. See THE INLINE MODE.
- **Never review**, in either mode. Classify on three markers only —
  `QUESTIONS FOR USER`, `SPAWN REQUEST` and `DONE`. Do not re-test, re-read a
  subagent's diff, or second-guess its commit; under `--inline`, classify on
  the session's own stated outcome and **never re-inspect the session's own
  diff**. Review is `/task-review`'s job, invoked when wanted from inside a
  step's own prompt.

---

## CHAT OUTPUT

**Quiet between steps, exhaustive at the end.** While the loop runs, print two
lines per step and nowhere else.

**At each step's start** — when the step is spawned, or under `--inline` when
its execution phase begins, the run's first step included — print the
progress line:

```
Step <n> running. Current run progress (<k>/<m>). Total runbook progress (<x>/<y>).
```

- `k` — the steps this run has finished (`[x]` in this run), plus the step now
  starting. A step that parked or failed earlier in the run adds nothing.
- `m` — the steps this run will touch: every step in range marked `[ ]`, `[~]`
  or `[!]` whose every `Depends on:` is `[x]` or is itself one of these steps,
  capped by `N` of `--steps N` when that is smaller — the same steps `--steps N`
  counts, in the same terms (ARGUMENTS). A step the run will not execute — out
  of range, or waiting on a dependency no step of this run completes — is not
  in it.
  - Count it once at launch, after any pre-ask is answered and before the
    first progress line, and never recompute it: a step that parks or fails
    leaves it unchanged, and a step that joins the run later — appended inside
    the range, or unparked by a reply in chat — runs without raising it.
  - `k` never exceeds `m`; on such a late step it holds at `m`.
- `x` — the done half of this runbook's `Steps:` counter in
  `.claude/RUNBOOKS.md` as it stood at launch, raised by each step this run has
  finished, plus the step now starting. A step that parked or failed adds
  nothing.
- `y` — the total half of that counter at launch, archived ids included
  (`runbook-schema.md` § *The index block*).

**At that step's end** — `Step 4 done (abc1234). Starting step 5.`, or the
failure line the halt already calls for.

- Do not narrate spawning, waiting, classifying a result, writing a `Done:`
  line or committing.
- A forced mid-step turn — a Stop hook firing on the in-flight step's dirty
  tree, a notification arriving while the step runs — explains nothing: the
  progress line is the only status line it may print besides the spawn relay's
  own lines, and COMMIT CADENCE § *The Stop-hook reply* gives the hook its
  fixed answer.
- Never suppress three things:
  - a relayed `QUESTIONS FOR USER` block, verbatim, because a run that needs
    an answer asks for it at once — under `unattended`, the parked step's
    question under its `P<n>` handle, for the same reason;
  - the spawn relay's own lines;
  - the one line that prints a follow-up when it arises mid-run, per the
    `follow-ups-resolve` skill § DURING A RUNBOOK RUN.
- The record of the run is the closing report, not the transcript above it.
- The same rules hold under `--inline`.

---

## ARGUMENTS

| Argument | Effect |
| --- | --- |
| `<id>` \| `<name>` \| `<id>-<name>` | The runbook to run. Required. The numeric id the index assigns it, its kebab-case name, or the two joined as in its body's file name — resolved by the rule in `runbook-schema.md` § *The store*. |
| `--from N` | Begin selection at step N — steps listed above it are not considered. |
| `--to N` | Stop after step N — steps listed below it are not considered. Inclusive: step N itself runs. |
| `--only N` | Run exactly step N, then stop. |
| `--steps N` | Run at most N steps in this run, then stop. N is a positive integer. Composes with `--from`; refused beside `--to` or `--only`. |
| `--model <model>` | Override the runbook header's `Model:` for **this whole run**. There is no per-step model. |
| `--inline` | Execute every selected step in **this session** instead of in a fresh subagent, for the whole run. Composes with `--from`, `--to`, `--only`, `--steps N`, `--no-commit`, `--no-push`, `--attended`, `--unattended` and `--skip-parked`, and changes nothing about selection, committing or the policy. Refused beside `--relay-spawns` or `--model`; the header `Model:` is not applied. See THE INLINE MODE. |
| `--relay-spawns` | Force the spawn relay for the whole run, for an environment already known to be flat. Without it the relay still works — the step's own subagent triggers it when it finds it cannot spawn. See THE SPAWN RELAY. |
| `--unattended` | Run under the `unattended` policy for this whole run: a step that asks a question is parked and the run goes on (`./references/parking.md`). At launch, unless `--skip-parked`, the `[P]` steps in range are pre-asked. |
| `--attended` | Run under the `attended` policy for this whole run: a question is relayed and the run waits. |
| `--skip-parked` | No pre-ask at launch: a `[P]` step in range stays parked unless a reply in chat answers it. For a launch no human sees — a routine, a scheduler, an orchestrator that is itself a subagent. Requires the policy to resolve to `unattended`. |
| `--commit` | Accepted and stripped, a silent no-op: committing is the default. Refused beside `--no-commit` with `--commit and --no-commit cannot be combined. Pick one.` |
| `--no-commit` | Do the work and write the bookkeeping, but commit nothing. Implies `--no-push`. |
| `--no-push` | Commit each step as usual, skip the push. |

**The execution policy** is the run's interaction policy, resolved per
`../interaction-engine/references/policy.md` — the runbook header's
`Execution policy:` line ranks second there, after a flag or a parent's policy
and before the project's `CLAUDE.md` line.

- Resolve it in step 1, once the body is read. Never write it back to the
  header.
- Under `attended`, nothing in this body changes, and `./references/parking.md`
  is opened only for a `[P]` step an earlier run left behind (step 3).
- Under `unattended`, read `./references/parking.md` in step 1. It holds the
  three changes: the fifth result row parks a step at its question instead of
  relaying it, the spawned preamble carries the one sentence that tells the
  step's agent so, and the launch pre-asks the parked steps in range.

**Bounds.**

- `--from` and `--to` compose: `--from X --to Y` runs steps X through Y
  inclusive and stops. Either bound stands alone — `--from X` with no `--to`
  runs to the end, `--to Y` with no `--from` starts wherever selection
  normally would.
- There is one selection model, not three: `--only N` **is** `--from N --to N`,
  and everything said about the bounds holds for it unchanged.
- Each bound names a step **by id** and cuts the list **at that step's
  position**: order is list position and the id carries none, per
  `runbook-schema.md` § *A step*. On a body carrying a step inserted with
  `/runbook-create --append --before` / `--after`, this keeps the range the
  stretch of steps the run actually walks.
- `--steps N` limits the run by count, not by id, inside the same selection
  model: selection works no differently, and once N steps have run in this
  run, the run stops.
  - Count only steps **actually executed in this run**: a step counts when it
    was executed and its outcome reached step 8 as `DONE` — by a spawned
    subagent or, under `--inline`, by this session.
  - Steps already `[x]` never count, because selection never picks them; a
    resumed `[~]` step or a re-run `[!]` step counts like any other selected
    step.
  - The progress line's `k` and `m` are made of this same count (CHAT OUTPUT).
  - Fewer than N selectable steps is not an error: the ordinary branches apply
    unchanged (completion, deadlock, or a failure's halt).
- `--from`, `--to`, `--only` and `--steps` **do not weaken dependencies.** A
  step selected under any of them whose `Depends on:` are not all `[x]` stops
  the run, naming the unmet dependency. The remedy is not a flag: the user
  marks that step `[x]` by hand, a visible, committed act rather than a silent
  override.
- A bound naming a step the body does not hold yet is **not** an error. Steps
  are appended mid-run by `/runbook-create --append`, and step 2 re-reads the
  body every step, so `--to 20` on a runbook with ten steps today means
  "through step 20, however many exist by then": until step 20 exists the
  bound cuts nothing, and from the re-read where it appears the run stops
  after it, wherever in the list it was written.
- A bound that selects nothing — every step in range is already `[x]`, or the
  `--from` step does not exist yet — is not an error either, but is never
  silent: say which range was asked for and that nothing in it remained, and
  stop.

Nine argument errors — name the problem and stop, having run nothing:

- `--only` together with `--from` or `--to`. It is already both of them.
- `--to Y` naming a step listed above step X of `--from X`.
- `--steps` together with `--to` or `--only`. `--steps` composes with `--from`
  alone.
- `--steps` with a missing value, or a value that is not a positive integer
  (`0`, `-1`, `abc`).
- `--inline` together with `--relay-spawns`. There is no step subagent to relay
  for.
- `--inline` together with `--model`. The session's model cannot be changed
  from inside the run.
- `--attended` together with `--unattended`, or a `CLAUDE.md`
  `Interaction policy:` value outside the two words — `policy.md`
  § *Argument errors*, with its messages.
- `--skip-parked` on a run whose policy does not resolve to `unattended`.
  There is no pre-ask to skip under `attended`; it asks when it reaches the
  step.
- A header `Execution policy:` value that is neither `attended` nor
  `unattended`, named in the error. It holds whether or not a flag was passed
  — a typo in the header is fixed, not routed around — and is caught in
  step 1, once the body is read, before anything is written.

---

## THE ARTIFACT

Read `./references/runbook-schema.md` before parsing or writing either file.
It specifies the store, the body schema, the five step markers and the `Done:`
line, the four-status vocabulary, and the index block. Restate none of it
here.

---

## THE EXECUTION LOOP

### 1. Resolve

- **Resolve the argument** to exactly one runbook by the resolution rule in
  `runbook-schema.md` § *The store*, then read that runbook's block in
  `.claude/RUNBOOKS.md` and the body at the path the block's `File:` line
  holds. Use the resolved block's name for the rest of the run: reports,
  relay blocks and the spawned prompt all name the runbook, never its id.
- **If the index predates ids**, backfill it per `runbook-schema.md`
  § *Backfilling an index written before ids* before resolving, and read
  `File:` only after that. This skill writes the index every step, so it is
  one of the three commands that performs the backfill rather than working
  around it.
- **Stop or proceed:**
  - **Unknown argument** — report the available runbooks (from the index) and
    stop. Never guess at a near match, and never fall back from an id that
    matched nothing to a name that looks similar.
  - **A compound whose halves disagree, or an ambiguity** — report it as the
    schema's rule says, and stop.
  - **`File:` naming a file that does not exist** — report it and stop.
  - **`[DONE]` runbook, with no `--only` / `--from` / `--to`** — say so and
    stop. `--steps` is a count, not a range: `--steps` alone on a `[DONE]`
    runbook stops here too.
  - **`[RUNNING]` runbook** — see ONE RUN PER RUNBOOK. Usually this stops the
    run.
  - **`[FAILED]` runbook** — proceed. The failed step is re-runnable and its
    failure is already recorded in its `Context:`.
- **Pull.** Run the pull-at-start half of the commit-and-push protocol (COMMIT
  CADENCE) unless `--no-commit` or `--no-push` was passed. Nothing but an id
  backfill has been written at this point, so a pull conflict stops the run
  before any rename.
- **The migration check** — after that pull, never before it.
  1. Re-read the runbook's block from the index as it now stands — a pull may
     have brought another machine's `[RUNNING]` or a changed `File:` — and
     re-apply the stops above to it.
  2. Then, on a runbook that is not `[RUNNING]`, and before step 4 first marks
     it `[RUNNING]`, apply the check in `runbook-schema.md` § *The store*:
     when the file name in `File:` does not begin with `<id>-`, read
     `./references/body-migration.md` and migrate the body as it says. On no
     hit, never open that file.
  3. Do not migrate under a condition that stops the run.
- **The resolved path** — the `File:` path as read, or the new one after a
  migration. Use it for the run's whole life: every re-read, every write and
  every commit. Step 1 is not redone mid-run.
- **Under `--inline`**, read `./references/inline-contract.md` here, once, and
  give the run's opening line — see THE INLINE MODE § *The opening line*.
- **Resolve the execution policy** last in this step, from the header as it
  now stands at the resolved path, per ARGUMENTS § *The execution policy*. A
  header value outside the two words is the ninth argument error.
  - Under `unattended`, read `../interaction-engine/references/gates.md` and
    `./references/parking.md` here, once, and run its § *The pre-ask* unless
    `--skip-parked` was passed. The pre-ask is the one thing that writes to
    the body before step 4, and its commit is its own.
  - Under `attended`, nothing more happens here.

### 2. Re-read the body

**At the start of every step, not once per run**, re-open the body at the
resolved path from step 1 and re-parse it.

- This re-read is the reconciliation of a body edited by hand between steps
  (the body is the source of truth, the index a summary); there is no separate
  mechanism.
- It is also what makes steps appended mid-run by `/runbook-create --append`
  visible to the run already in progress.

### 3. Select

Select the first step in list order — top to bottom, whatever its id — whose
marker is `[ ]`, `[~]` or `[!]`, and whose every `Depends on:` step is `[x]`.

- Under `--from N`, skip the steps listed above step N. Under `--to N`, skip
  the steps listed below step N. Under `--only N`, consider only step N.
- Re-apply the bounds against the body step 2 just re-read, every step; never
  resolve them once into a fixed list. A step appended mid-run inside the
  range is therefore run, and one appended outside it is not.
- `--steps N` changes nothing here: it selects no differently, and is checked
  in step 8 after each commit.
- A `Depends on:` id with **no step in the body** is satisfied when it is on
  the header's `Archive:` line: `/runbook-prune` removed that step and an
  archived id counts as `[x]` (`runbook-schema.md` § *An archived id counts as
  `[x]`*). Resolve it from the header, not as a dangling reference, and do not
  rewrite the `Depends on:` line.
- A **`[~]`** step is one a previous run was interrupted in. Report it as such
  and re-run it.
- A **`[!]`** step is re-run with its failure already recorded in `Context:`
  by the run that failed. Do not re-record it.
- A **`[P]`** step is never selected as it stands: it runs only once it is
  `[ ]` again, which its answer makes it.
  - Under `attended`, when it is the step this rule would otherwise pick —
    first in range, every dependency `[x]` — read `./references/parking.md`
    (if not yet read this run) and ask its question as § *A parked step
    reached under `attended`* says; answered, it is `[ ]` and selected now.
  - Under `unattended`, pass it over and go on down the list to the next
    candidate. A step that depends on it is unselectable by the ordinary rule,
    untouched, not parked.
- **Steps remain but none is selectable, and none of them is `[P]`** — a
  dependency deadlock. Report the blocked steps and, for each, the
  dependencies that are not `[x]`, and stop. Do not pick one anyway.
- **Steps remain, none is selectable, and at least one remaining step is
  `[P]`** — not a deadlock and not a failure: the run is waiting on an answer.
  Read `./references/parking.md` (if not yet read this run) and end the run as
  its § *The end branch* says.
- **No steps remain** — every step is `[x]` — go to step 8's completion
  branch.
- **Steps remain but none of them is in range** — the bounded run is over: go
  to step 8's `--to` branch, not the completion branch and not the deadlock
  branch. Nothing is blocked; the range simply ran out.

### 4. Mark

- Set the selected step's marker to `[~]` in the body, and the index `Status:`
  to `[RUNNING]`.
- Write both to disk now, before spawning — or, under `--inline`, before the
  execution phase begins.
- `[~]` is in-run working state: never committed, and the resume signal — see
  COMMIT CADENCE and ONE RUN PER RUNBOOK.

### 5. Spawn

- **Refuse a nested runbook first.** If the step's prompt block invokes
  `/runbook-run`, do not spawn it. Mark the step `[!]`, write a `Done:` line
  opening with the reason, set the index to `[FAILED]` with `Failed at:`, and
  stop. The reason to give: a runbook inside a runbook is refused for the
  orchestration it duplicates, not for the depth it costs. (`/runbook-create`
  rejects such a step at authoring time; this check stops a hand-written
  runbook smuggling one in.)
- Spawn **one** subagent with fresh context, the assembled prompt (see THE
  SPAWNED PROMPT), and the model from the runbook header — or from `--model`,
  which overrides it for the whole run — and print the step's progress line
  (CHAT OUTPUT).
- One at a time, never two — THE SPAWN RELAY holds the one exception, a
  relayed child running while its caller is suspended. Steps are sequential
  always, even where the runbook declares them independent.
- **Under `--inline`**, spawn nothing. The **execution phase** takes the place
  of this step and step 6: the session assembles the step's brief and executes
  it itself, under the inline contract (THE INLINE MODE), printing the
  progress line as it begins. No other loop step changes. The nested-runbook
  refusal still applies unchanged: check it before the execution phase begins,
  and refuse the step exactly as written.

### 6. Wait

**This is the single most dangerous point in the whole feature.**

- A spawn returns **asynchronously**: the call yields an id, and the agent's
  result arrives later as a separate notification. The return value of the
  spawn call is *not* the result.
- Until the result actually arrives, do nothing: do not mark, do not write a
  `Done:` line, do not commit, do not select the next step. **No step is
  ticked before its subagent's result has actually arrived.**
- **Under `--inline`** there is no spawn and no notification. The execution
  phase instead ends with the session **writing out its own outcome as a
  separate act**, before any bookkeeping is written — see THE INLINE MODE
  § *Ending the execution phase*. The rule carries over unchanged in
  substance: **no step is ticked before its outcome exists.** The inline form
  of treating a spawn's return value as the result is ticking a step whose
  work did not finish.

### 7. Handle the result

Classify by the four cases, and only four — see THE FOUR RESULT CASES — plus,
under `unattended` and only then, the fifth row that parks the step at a
`QUESTIONS FOR USER` result (`./references/parking.md` § *The fifth result
row*). Under `--inline`, classify the outcome the execution phase wrote out by
those same cases.

### 8. Commit and loop

- Commit the runbook and the index per COMMIT CADENCE. A step the fifth row
  parked is committed here exactly as a `[x]` or `[!]` step is — `[P]` on its
  heading and `Parked:` in the index.
- When `./references/parking.md` has been read this run, apply its § *Mid-run
  answers* to any reply that arrived during the step.
- Loop back to step 2 and re-read the body.

Three branches end the loop:

- **Completion.** When no `[ ]` steps remain — every step is `[x]` — set the
  index `Status:` to `[DONE]`, commit, and give the closing report (THE
  CLOSING REPORT), naming the runbook and the number of steps.
- **Reaching a `--to` bound is not completion.** When the selected step was
  the last one in range, stop there instead of looping, and set the index back
  to `[PENDING]` unless every step in the *whole* runbook is now `[x]`. The
  report says which range ran, and carries the steps remaining
  outside it as a *Follow-ups* item. `--only N` stops this way too; it is the
  bound `--to N` doing it.
- **Reaching the `--steps` count is not completion either.** When the step
  just committed is the N-th step executed in this run, stop there instead of
  looping, exactly as at a `--to` bound: set the index back to `[PENDING]`
  unless every step in the whole runbook is now `[x]` (then it is `[DONE]` by
  the completion rule), and report how many steps ran, with the steps
  remaining as a *Follow-ups* item.

Whichever of those three ended the run, the closing report is the last thing
the run does — see CLOSING THE RUN.

---

## THE INLINE MODE

`--inline` is opt-in and a property of the **whole run**: every step the run
selects is executed by this session, none by a subagent. There is no per-step
mode and no mixing modes within one run.

### The opening line

Before the first step, give one line, once, saying that the selected steps
**share one context** — this session's — and that `--steps N` is what limits
how many run. The same line names the runbook header's `Model:` as **not
applied**, once: the session runs on its own model and cannot switch it.

### The two phases

Each inline step alternates between two roles; the boundary keeps the default
mode's *the orchestrator never patches work* discipline without a second
agent:

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

Assemble the same brief THE SPAWNED PROMPT describes — parts 1–5: preamble,
`Companion:` background, `## Do not re-propose`, `Context:`, the verbatim
prompt block — and work through it in that order. In place of part 6, the
OPERATING RULES, follow the fixed rule set in
`./references/inline-contract.md`, read once in step 1.

### Ending the execution phase

End the execution phase by writing out the session's own outcome, as a
**separate act**, before any bookkeeping is written — either a `DONE` report
naming the commit sha(s) with their diffstat, plus any decision or wrong
premise a later reader would be misled without, or a plain statement of
failure. Step 7 classifies that written outcome by THE FOUR RESULT CASES.

### What does not change

Nothing records the mode. `Done:` lines, step markers, `Steps:`, index
statuses, `Failed at:`, the resume signal and COMMIT CADENCE are identical to
the default mode, so a runbook partly run inline and resumed spawned (or the
reverse) is consistent by construction.

---

## THE SPAWNED PROMPT

Assemble it in this fixed order, so the operating rules are the last thing the
agent reads.

**Parts 1–4 are the only text the orchestrator writes; keep them minimal.**

- Never restate anything the step's own prompt will cause the agent to read —
  a task body that `/task-implement <N>` opens anyway, the feature document
  behind it, context files, the backlog.
- **Never open a step's task body, or any document the step names, in order to
  compose them**: the read scope (WHAT THIS SKILL READS AND WRITES) bounds what
  the orchestrator may read to write the prompt. The agent does the reading.
- The preamble carries exactly what the agent cannot derive: the navigation
  instruction, the runbook name and the step number — plus the one
  `--relay-spawns` sentence below, when that flag is passed. Parts 2–4 carry
  what the runbook itself holds, under their own rules below.
- Parts 5 and 6 are outside this rule: one is verbatim, the other fixed text.

1. **Preamble.** Orient in a fresh session: tell the agent to read the
   project's `CLAUDE.md` and follow its navigation instructions **as written**
   — the index of each navigation layer, then only the files relevant to this
   step, never a whole layer. Name the runbook and the step number this agent
   is executing; that is what lets a step's subagent call
   `/runbook-create --append` with no name argument.

   **Under `--relay-spawns`, and only then, the preamble also carries one
   sentence**: do not spawn a subagent even if you can — route every child
   through the relay, exactly as OPERATING RULES describes for an agent that
   cannot spawn. This is the flag's only effect on the assembly; part 6 stays
   fixed text, never edited per run.

   **The preamble states the run's policy, under both values, in that same
   slot** — the policy a skill the step invokes resolves as handed down by its
   parent, per `../interaction-engine/references/policy.md`:
   - under `attended`: *This run is attended: a question about the work is
     relayed to the user and waited on, and a skill you invoke reads it as
     attended too.*
   - under `unattended`: *This run is unattended: a question about the work
     parks this step, and a skill you invoke reads it as unattended too.*

   The sentence says **attended** or **unattended** — never
   *non-interactive*, which an attended step's agent is too. The unattended
   one is what turns on the two conditional OPERATING RULES in part 6.
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
   never "improved". A bare slash command is passed as a bare slash command.
6. **OPERATING RULES.** Verbatim from `./references/subagent-contract.md`,
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

- **Under the `unattended` policy a fifth row replaces the first**, and it is
  the only change the policy makes to this table: `QUESTIONS FOR USER` → park
  the step, per `./references/parking.md` § *The fifth result row* — `[P]`,
  the question into `Context:`, printed in chat under a `P<n>` handle,
  committed, and the run continues. The other three rows are unchanged under
  either policy; an attended run never reaches the fifth.
- **An ambiguous report is a failure, not a success.** A report the
  orchestrator cannot confidently classify halts the run — never tick a step
  on a guess. A report with no `DONE` marker, no commit sha where one was
  clearly expected, or a narrative that trails off is ambiguous — halt.
- **Under `--inline`** the result is the outcome the execution phase wrote out
  (THE INLINE MODE § *Ending the execution phase*), classified by the same
  four rows; an outcome the session cannot state confidently is ambiguous, and
  therefore a failure. A top-level inline session asks its questions directly
  rather than producing a `QUESTIONS FOR USER` result — under `unattended` it
  parks the step at that question instead, by the fifth row, exactly as it
  would classify a subagent's block — and spawns a wanted child itself rather
  than producing a `SPAWN REQUEST` — see the relays below.

### On `DONE`

1. Write the `Done:` line from the agent's report, in the terse default form
   `runbook-schema.md` § *The `Done:` line* gives, taking the sha and the
   diffstat from the report, never from git. What that section adds to the
   one-line default only on its test — a decision taken, a premise that proved
   wrong — and what it keeps off the line hold here unchanged, even when the
   report carries the excluded material. The same form applies under
   `--inline`.
2. Set the marker to `[x]`.
3. Update the index's `Steps:` count (`[x]` steps plus every id on the
   header's `Archive:` line — `runbook-schema.md` § *The index block*).
4. Propagate facts (FACT PROPAGATION).

### On failure

Do not retry the step, do not attempt the work yourself, and do not continue
to the next step. Give the closing report (THE CLOSING REPORT), its
*Follow-ups* group included. See CLOSING THE RUN.

---

## THE QUESTION RELAY

**The orchestrator compresses; it does not answer.**

Render a relayed question as one fixed block:

```
Step 3 of 7 — Peer review — the agent is asking (round 1):

  <the question in one or two lines>

  a) <option> — <what it costs>
  b) <option> — <what it costs>

Recommendation: (b), because <one line>.
```

- At an **approval gate**, the block carries the agent's plain summary of the
  draft, per `../interaction-engine/references/messages.md`. Relay a `show`
  reply to the agent like any answer; its next turn carries the full draft,
  relayed unchanged in the same block's next round.
- Relay the user's answer to the **same** subagent, whose context is intact —
  never to a fresh one. Repeat for as many rounds as it takes; the round number in the
  block tells the user where they are.
- You **may** add facts you already hold — a `Done:` line from an earlier step
  that answers the question — and must say that you are doing so, so the user
  can see which part of the block came from the agent and which from the
  runbook. You **may never** invent a decision on the user's behalf, and never
  ask the user to re-state something an earlier step already settled.
- **This relay is the `attended` policy's.** Under `unattended` the same
  result takes the fifth row instead (THE FOUR RESULT CASES) and nothing is
  relayed: the block's question and options are stored and printed, and the
  run goes on. The one question an attended run asks that no agent of its own
  raised — a `[P]` step parked by an earlier run and reached now — is put in
  this same fixed block, per `./references/parking.md` § *A parked step
  reached under `attended`*.
- **When the orchestrator is itself a subagent** — a runbook driven from a
  batch parent, which the depth budget permits — there is no user to ask.
  Emit the same fixed relay block as your own final turn, under a
  `QUESTIONS FOR USER` heading, for your parent to carry, and resume when the
  answer comes back. Never answer on the user's behalf in either position.
- **Under `--inline`** there is no relay hop: the asker is the session itself.
  - A top-level session **asks the user directly**, in the fixed block headed
    `Step <n> of <total> — <title> — asking (round <r>)`, with a plain summary
    of any approval-gate draft and the full draft on `show`.
  - It never answers its own question, and never skips a gate the step's
    skill defines because it "already knows" the answer. That holds under
    `attended`, and under `unattended` for every gate but a `confirmation`
    one, which passes on its own as its owner says
    (`../interaction-engine/references/gates.md`): that is the gate's own
    behaviour under that policy, not a skipped gate. The same holds in a
    spawned step.
  - The subagent-position rule above is unchanged: an inline session that is
    itself a subagent ends its turn under `QUESTIONS FOR USER` and resumes
    when the answer returns.

---

## THE SPAWN RELAY

**The orchestrator forwards; it does not read.**

**Under `--inline` this section has no role** — the relay, its eight-round
cap and `--relay-spawns` alike. A step that wants a child has the session
spawn it directly, one level down, per the inline contract, and the step's own
skill bounds its own children. That is why `--relay-spawns` beside `--inline`
is an argument error.

Where a subagent cannot spawn a subagent (cloud sessions among them), the
subagent contract has a step's agent that wants a child (e.g.
`/task-implement --review --rounds 2`) write the child's prompt to a file
under `$TMPDIR` and end its turn with `SPAWN REQUEST`. This section is the
other half.

### Why it works

The orchestrator spawns the child at the caller's own nesting level, not one
below it — sideways, not downward — so it needs no extra depth and works
identically wherever the run is driven from.

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
3. **Classify the child's returned turn on its marker**, never on the result
   file's content. Only a `DONE` child whose result file is in place reaches
   step 4. A relay child's unmarked turn is the one departure from THE FOUR
   RESULT CASES: it is re-prompted rather than failed. A step's own agent is not a relay child, and
   its unmarked turn still fails the step.
   - `QUESTIONS FOR USER` or `SPAWN REQUEST` — handle them for the child, as
     *What is preserved* below says, then come back here.
   - **A report of failure** — the step has failed. Mark it `[!]`, write a
     `Done:` line opening with the reason and naming which relayed child failed,
     set the index to `[FAILED]` with `Failed at:`, halt and report. Do **not**
     tell the caller its child is finished — it would finish its step on work
     that never happened.
   - **A miss** — a `DONE` turn whose `<result path>` is absent or empty (an
     existence check, opening nothing), or a turn carrying no marker that does
     not plainly declare its own failure. Re-prompt that same child once
     ("Your result file at `<result path>` is missing. Write your full report
     there and end your turn with `DONE`.") and classify its next turn by these
     same bullets. The re-prompt is not a relay round and does not count toward
     the cap.
   - **A second miss** from the same child fails the step exactly as a report
     of failure does, the `Done:` line naming the relayed child and the missing
     result file.
4. **Reply to the same caller subagent** — the one that is suspended awaiting
   this — with one line: the child is finished, and its report is at
   `<result path>`. The caller reads the file and continues.

**Open neither file** — not the prompt, not the result, not "just to check"
(an existence check is not opening). Classification runs on the child's
returned marker, so it never needs to, and the child's content stays out of
the orchestrator's context.

### What is preserved

- **Sequencing.** The caller is suspended for the entire time the child runs,
  exactly as during a `QUESTIONS FOR USER` relay, so only one agent is doing
  work at any moment. This is the one stated exception to *one subagent at a
  time, never two* — two exist, one of them idle — and it is not a wider
  licence: never spawn a child while the caller is still working, and never
  two children at once.
- **The question relay.** Relay a child's own `QUESTIONS FOR USER` to the user
  exactly as a caller's, in the same fixed block, and send the answer back to
  the **child**. Say which agent is asking when a child is the one asking.
- **Flat fan-out.** Handle a `SPAWN REQUEST` from a *child* identically — spawn
  that grandchild at your own level too. Nothing nests, however deep the
  logical call chain goes.
- **Failure.** A child that fails fails the step, per protocol step 3. The
  relay gives a step no second chance, and never converts a child's failure
  into a caller's success.

### The cap

**Eight relay rounds per step.** A round is one `SPAWN REQUEST` served. On the
ninth, stop: mark the step `[!]`, write a `Done:` line saying the relay cap was
reached and naming how many children ran, set the index to `[FAILED]` with
`Failed at:`, and halt. A step that wants a ninth child is looping.

### The files

- Relay files live under the OS temp directory, **never inside the
  repository**.
- The subagent contract dictates their names —
  `<runbook>-step<n>-round<r>-prompt.md` and `-result.md` — so two runs sharing
  a `$TMPDIR` cannot collide. Take the paths the request gives; do not
  relocate or rename them.
- Commit nothing about them: what a step's commit stages is COMMIT CADENCE's
  rule, unchanged. They are transient message-passing, not state, and are
  gone with the session.

### `--relay-spawns`

Forces the relay for the whole run, through the one sentence it adds to the
**preamble** of every spawned prompt (THE SPAWNED PROMPT part 1): the step's
agent does not spawn at all and routes every child through the relay. Use it
where the environment is already known to be flat. **Without it nothing is
lost** — the subagent's own detection is the trigger, and where nesting works
a run behaves exactly as it always did. The flag does not enable the relay.

---

## FACT PROPAGATION

When a step's report changes a fact a later step relies on, append a **dated
bullet** to that later step's `Context:` naming the correction:

```
Context:
- 2026-08-25 (from step 1): parse_frontmatter gates emission on a key
  allowlist — step 4's "verified fact" that it emits every key is wrong.
```

What step 1 discovers is folded into step 4 before step 4 runs, instead of
step 4 proceeding on a premise already known to be false.

**Never edit the prompt block itself.** A reader must always be able to see
what was originally asked and what was learned since, separately. New facts go
to `Context:`; the fenced block is the author's, and is immutable for the life
of the runbook.

---

## ONE RUN PER RUNBOOK

Two concurrent runs of the same runbook are forbidden — they race on the same
file.

- `[RUNNING]` in the index blocks a second `/runbook-run` of that name: report
  the runbook as already running and stop.
- The single exception is resuming in the same working tree. The signal is a
  `[~]` marker present in the tree — never committed (COMMIT CADENCE), so its
  presence locally means **this tree is the one that was interrupted**.

> `[RUNNING]` in the index **plus** `[~]` in the tree is the whole resume
> signal.

There is no staleness heuristic, no timestamp, and no lock file.

---

## THE DEPTH BUDGET

Where verified ground ends:

- The orchestrator occupies **one** nesting level.
- The step's agent occupies a **second**.
- Whether anything the step's agent spawns has a level to occupy **depends on
  the environment**. Nesting to depth 3 was verified locally; in a cloud
  session a subagent cannot spawn at all, and depth 4 has never been probed
  anywhere.

**THE SPAWN RELAY makes the depth question mostly moot**: a step whose prompt
itself wants a subagent (`/task-implement --review`) needs no third level,
because its agent routes the child sideways.

What remains true:

- The relay only fires when the step's agent **notices** it cannot spawn, or
  when `--relay-spawns` forces it. Where nesting works, a step's agent nests,
  and depth 3 remains the verified bound on that path.
- An agent that nests to depth 3 and then wants a fourth level is past verified
  ground, and its own contract tells it what to do there: request the relay
  rather than improvise.
- Depth 3 also means the orchestrator may itself be a subagent, which is what
  allows a runbook to be driven from a batch parent — see the question relay's
  subagent-position rule. The spawn relay works from that position too: the
  orchestrator spawns the child at its own level either way.
- Nested runbooks are the one case that *is* refused, and the relay does not
  change that — see step 5.

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
`.claude/RUNBOOKS.md`, by explicit path.

- On the step whose commit follows a migration in step 1, that commit also
  stages the old path — held from the migration, since `File:` no longer names
  it — so its removal and the rename land in that commit and no other, per
  `body-migration.md` § *Staging*.
- Never a catch-all (`git add -A` / `git add .` / `git add -u`).
- A subagent that commits its own work produces a separate commit; the runbook
  commit is bookkeeping and is expected to sit beside it.
- Never commit the `[~]` marker. By the time a step is committed its marker is
  `[x]`, `[!]` or `[P]`; if a commit would capture `[~]`, the step is not
  finished and must not be committed.
- A parked step's commit is the step's one commit for this run. An unpark — at
  the pre-ask or mid-run — is a bookkeeping commit of its own, staging the
  same two files, so the marker on disk never lags the answer
  (`./references/parking.md` § *Unparking a step*).

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

- `--no-commit` writes the bookkeeping into the tree and commits nothing; it
  implies `--no-push`. `--no-push` commits every step as usual and skips
  steps 1, 3 and 4.
- On a non-git VCS — a project whose `CLAUDE.md` defines a `## VCS` section
  overriding git — skip the pull → re-sync → push sequence entirely; only the
  commit (checkin) step runs.

**The Stop-hook reply.** A cloud sandbox's Stop hook refuses to end a turn on a
dirty tree, and an in-flight step is dirty by design — the uncommittable `[~]`
heading and `[RUNNING]` index, plus, in spawned mode, whatever the step's
subagent has not committed yet. It fires at each step start, at every question
relayed to the user, and at every notification that wakes the run while a
step is in flight, and cannot be cleared from here.

In each of two cases, reply with exactly the line given and end the turn — no
tool call, no `git status`, no explanation: you already know what is dirty.

- **Runbook WIP** — the only uncommitted changes are the runbook and the index
  **you yourself just wrote**:

  ```
  stop hook ignored on runbook WIP
  ```

- **Subagent WIP** — a spawned step is in flight: spawned in step 5, its result
  not yet arrived (step 6). Whatever is dirty, since nothing but the step's
  subagent and the two bookkeeping files can have written the tree then:

  ```
  stop hook ignored on subagent WIP
  ```

  Spawned mode only. Under `--inline` there is no subagent, and the session's
  own dirty files are its own work to track, so the runbook-WIP case alone
  applies.

In any other state this is neither case — handle it normally, so a genuinely
forgotten commit still gets thought about.

The runbook-WIP condition answers one more prompt, in either mode — a step command's
dirty-tree prompt, answered `proceed` by whoever executes the step: the step's
agent under OPERATING RULES (`subagent-contract.md`), or the session under
`inline-contract.md`.

---

## THE CLOSING REPORT

Every run ends with one closing report — at completion, at a `--to` / `--only`
/ `--steps` bound, at the end branch and at a failure halt alike — in two
groups, in this order, each under its heading.

- Draw every entry from a step's `Done:` line and its own report, both already
  in hand, and from the run's own conversation.
- Its length and what it names follow
  `../interaction-engine/references/messages.md` § *Output*; every question in
  it follows § *Questions*.

The two groups:

- **For the record** — one line per step the run executed, in list order, in
  exactly this shape: `<step n> — <outcome, commit sha and diffstat> — <what
  changed in one line; decision or wrong premise flagged; questions relayed and
  their answers>`. Any run-level deviation follows on one line of its own. No
  item in this group runs past one line, and none is a question.
- **Follow-ups** — one numbered list, `1.`, `2.`, …, each item as long as it
  needs to be, holding two kinds of item under the one numbering:
  - The run's own items:
    - the feature completion candidates — every slug a step report named as
      having all its tasks `[DONE]`/`[SKIP]`, with the one question, "Flip to
      `[DONE]` in FEATURES.md? Name the slugs, or say all / none.";
    - a failed step, with its reason and what the agent said;
    - a step left `[~]`, to resume;
    - every step left `[P]`, with its question verbatim and multi-line under
      its `P<n>` handle in place of an item number, options included, and the
      steps waiting on it;
    - the steps left outside the range, outside the `--steps` count, or never
      started.
  - The items the `/follow-ups` command's rules yield when applied to the
    run's reading — the command's body read by name and applied, never
    invoked (CLOSING THE RUN).
  - Two items naming the same action are one item, in the command form where
    either had it.

An empty group prints its heading and `none`.

**The numbering is the reply handle.** It starts at 1 in every report, carries
no meaning beyond the handle, and a report with a single item still numbers
it.

- A reply by number — "execute 2", "insert 3 as the next step" — is acted on
  by the `follow-ups-resolve` skill when it is available, and otherwise
  handled as any other request is.
- A parked step keeps its `P<n>` handle (`./references/parking.md` § *The
  handles*). A reply by it is that step's answer, recorded exactly as a
  mid-run reply is (`./references/parking.md` § *Mid-run answers*), and the
  next run selects the step.

Ask the flip question once, here. The answer is acted on in conversation after
the run: the orchestrator never writes `FEATURES.md`.

The report reads the same way under `--inline`. There is no opt-out flag.

---

## CLOSING THE RUN

**The closing report is the last thing a run does**, and its *Follow-ups*
group is where the `/follow-ups` command's rules are applied — **once per
run, never per step** — inside the report, not as a call after it. Never
invoke the command: read its body by name and apply its rules to the run's
reading, so what they yield folds into one list with the run's own items,
under one numbering. What counts as a follow-up, what is excluded and how an
item is written are that body's alone and are restated nowhere here.

Give the report at every point a run stops, not only at completion:

- when no `[ ]` steps remain and the index went `[DONE]`;
- at a `--to`, `--only` or `--steps` bound;
- at the end branch — steps remain, none selectable, at least one `[P]` —
  with the index back at `[PENDING]`;
- at a failure halt — the `[!]` marker and the index `[FAILED]`;
- when the user asks to stop after a step mid-run, **even when the run
  carried no bound to that step**.

A single-step run is not a special case: the end of the one step is the end
of the run.

**What the reading covers.**

- In the default spawned mode, read your own conversation *and the step
  subagents' result reports* — agents routinely name their own follow-ups
  there.
- Open no file to get them: a step's result is already in hand from step 7.
  THE SPAWN RELAY's rule against reading a child's output covers only the
  relay's request and result *files*.
- Under `--inline` nothing changes — there are no step reports, and the
  session's own conversation is the whole reading.

When a listed follow-up that came from a step subagent is executed or
planned, forwarding it to that same subagent is often the convenient thing to
do, and is allowed. Judgement, not a rule — this is not a new relay protocol
and adds no round to the cap.

**It changes no bookkeeping.** The report sits outside COMMIT CADENCE: it adds
no commit, and is printed after the index `Status:` (`[DONE]` / `[FAILED]` /
`[PENDING]`) and the run's final commit are already written.

**When a working list exists** — the user resolved or approved follow-ups
during the run, per the `follow-ups-resolve` skill § DURING A RUNBOOK RUN —
the *Follow-ups* group is that list in its two-section shape:

- **Approved** first, then **Awaiting approval**, the run's own items and what
  `/follow-ups`' rules yield folded into the second, one numbering running
  across both.
- After the report, the approved items are executed under
  `follow-ups-resolve`. That is conversation after the run, so the report's
  contract holds as stated: it adds no commit and flips no status, and a
  `FEATURES.md` flip among the items is a delegated item — the orchestrator
  never writes that file itself.

**When `/follow-ups` is not installed, the group holds the run's own items
only, silently** — no message, no error, not a run failure. (The frontmatter's
`requires: command:follow-ups` makes the dependency helpers install it
alongside this skill; only a hand removal leaves it absent.)

---

## DO NOT

- Answer a `SPAWN REQUEST` by doing the child's work, by telling the caller to
  do it inline, or by declining it. Spawn the child.
- Edit the header, `Sequencing:`, `Companion:`, a step title, a
  `Depends on:` or a `Needs:` line — those are `/runbook-create`'s, by line.
