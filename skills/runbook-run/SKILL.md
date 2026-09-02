---
name: runbook-run
version: 0.4.0
type: skill
description: Execute a runbook — an ordered list of self-contained prompts under .claude/runbooks/<name>.md — by walking it top to bottom, spawning one fresh subagent per step, relaying that subagent's questions to the user and the user's answers back to the same subagent, recording what each step actually did in a Done: line, and committing the runbook and its .claude/RUNBOOKS.md index after every step. Steps run one at a time, never in parallel. The orchestrator reads only CLAUDE.md, the runbook and the index, and writes only the runbook and the index — every other change in the tree is made by a subagent, and it never reviews or second-guesses one. Usage: /runbook-run <name|id> — a bare all-digits argument is the numeric id the index assigns each runbook, anything else its kebab-case name — with --from N to begin selection at step N, --only N to run exactly one step, --model <model> to override the runbook's header model for this run, --relay-spawns to force the spawn relay for a whole run, and --no-commit / --no-push with their usual meanings. Where a subagent cannot spawn a subagent — cloud sessions among them — a step's agent ends its turn with SPAWN REQUEST naming a prompt file and a result file under the OS temp dir; the orchestrator spawns that child at its own nesting level, waits for it, and tells the caller the result is ready, without ever opening either file. Also carries, in references/, the two files the rest of the runbook suite reads by path: runbook-schema.md (the asset kind — store, body schema, step markers, status vocabulary, the optional per-step Needs: field, the index block with its id and Last runbook number: counter, and the backfill an index written before ids gets from the first command that writes it) and subagent-contract.md (the OPERATING RULES block pasted verbatim into every spawned prompt).
---

# /runbook-run
# Global skill: execute a runbook, one step at a time, each in a fresh
# subagent. Relays questions to the user, records what each step did, and
# commits after every step.
# Usage: /runbook-run <name>
#        /runbook-run <name> --from N        (begin selection at step N)
#        /runbook-run <name> --only N        (run exactly step N, then stop)
#        /runbook-run <name> --model sonnet  (override the header model)
#        /runbook-run <name> --no-commit     (write the bookkeeping, commit nothing)
#        /runbook-run <name> --no-push       (commit as usual, skip the push)
# Examples: /runbook-run implement-ecc-import
#           /runbook-run implement-ecc-import --from 12
#           /runbook-run implement-ecc-import --only 4 --model sonnet

GOAL
Take a runbook and execute it. For each step, in order: spawn one subagent
with a fresh context and the assembled prompt, wait for its result, relay any
question it asks to the user and the answer back to it, then record what it
did and commit.

> **Install path assumption:** this skill assumes installation at
> `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/`, where
> `chosko-llm add skill:runbook-run` writes it. The two reference files this
> body reads are
> `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`
> and
> `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/subagent-contract.md`.
> Never a hardcoded home path — the `CLAUDE_HOME` override has to keep
> working.

---

## WHAT THIS SKILL READS AND WRITES

**It reads three files.** The project's `CLAUDE.md`, the runbook
(`.claude/runbooks/<name>.md`), and the index (`.claude/RUNBOOKS.md`) — plus
the two reference files above, which are part of this skill. It does **not**
open `.claude/context/`, `.claude/domain/`, or any source file. It touches no
source, so orienting in the codebase would be wasted tokens; orienting is each
step's subagent's job, and the spawned prompt tells it to.

**It writes two files.** The runbook and the index. Nothing else. Every other
change in the tree is made by a subagent. This is a hard contract: an
orchestrator that starts patching things is one that has lost track of what it
delegated.

**It does not review.** It reads three markers — `QUESTIONS FOR USER`,
`SPAWN REQUEST` and `DONE` — and classifies on them. It does not re-test, re-read a subagent's
diff, or second-guess its commit. Review is `/task-review`'s job and is
invoked, when it is wanted, from inside a step's own prompt.

---

## ARGUMENTS

| Argument | Effect |
| --- | --- |
| `<name>` \| `<id>` | The runbook to run. Required. A kebab-case name, or the numeric id the index assigns it — a bare all-digits argument is an id, anything else a name, per `runbook-schema.md` § *The store*. |
| `--from N` | Begin selection at step N — steps before N are not considered. |
| `--only N` | Run exactly step N, then stop. |
| `--model <model>` | Override the runbook header's `Model:` for **this whole run**. There is no per-step model. |
| `--relay-spawns` | Force the spawn relay for the whole run, for an environment already known to be flat. Without it the relay still works — the step's own subagent triggers it when it finds it cannot spawn. See THE SPAWN RELAY. |
| `--no-commit` | Do the work and write the bookkeeping, but commit nothing. Implies `--no-push`. |
| `--no-push` | Commit each step as usual, skip the push. |

`--from` and `--only` **do not weaken dependencies.** A step selected by
either whose `Depends on:` are not all `[x]` stops the run, naming the unmet
dependency. The remedy is not a flag: the user marks that step `[x]` by hand,
which is a visible, committed act rather than a silent override.

`--from` and `--only` together are an error — name both and stop.

---

## THE ARTIFACT

The store, the body schema, the four step markers and the `Done:` line, the
four-status vocabulary, and the index block are all specified in
`${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`.
Read it before parsing or writing either file. Nothing about the artifact is
restated here — a second copy is the copy that drifts.

---

## THE EXECUTION LOOP

### 1. Resolve

Resolve the argument to a runbook per `runbook-schema.md` § *The store* — a
bare all-digits argument is an id, anything else a name — then read that
runbook's block in `.claude/RUNBOOKS.md` and the body at
`.claude/runbooks/<name>.md`. The name resolved from an id is what the rest of
the run uses: reports, relay blocks and the spawned prompt all name the
runbook, never its id.

If the index predates ids, backfill it per `runbook-schema.md`
§ *Backfilling an index written before ids* before resolving. This skill writes
the index every step, so it is one of the three commands that performs the
backfill rather than working around it.

- **Unknown name or id** — report the available runbooks (from the index) and
  stop. Never guess at a near match, and never fall back from an id that
  matched nothing to a name that looks similar.
- **`[DONE]` runbook, with no `--only` / `--from`** — say so and stop. Doing
  nothing quietly is indistinguishable from a bug.
- **`[RUNNING]` runbook** — see ONE RUN PER RUNBOOK below. Usually this stops
  the run.
- **`[FAILED]` runbook** — proceed. The failed step is re-runnable and its
  failure is already recorded in its `Context:`.

Then run the pull-at-start half of the commit-and-push protocol (see COMMIT
CADENCE) unless `--no-commit` or `--no-push` was passed.

### 2. Re-read the body

**At the start of every step, not once per run.** Re-open
`.claude/runbooks/<name>.md` from disk and re-parse it.

This is deliberate and does two jobs. It reconciles a body edited by hand
between steps — the index is a summary and the body is the source of truth, so
re-reading *is* the reconciliation. And it is what makes steps appended
mid-run by `/runbook-create --append` visible to the run already in progress.
There is no separate reconciliation mechanism because this one is free.

### 3. Select

The first step whose marker is `[ ]`, `[~]` or `[!]`, and whose every
`Depends on:` step is `[x]`. Under `--from N`, skip steps numbered below N.
Under `--only N`, consider only step N.

- A **`[~]`** step is one a previous run was interrupted in. Report it as such
  and re-run it.
- A **`[!]`** step is re-run with its failure already recorded in `Context:`
  by the run that failed. Do not re-record it.
- If steps remain but **none is selectable**, that is a dependency deadlock:
  report the blocked steps and, for each, the dependencies that are not `[x]`,
  and stop. Do not pick one anyway.
- If **no steps remain** — every step is `[x]` — go to step 8's completion
  branch.

### 4. Mark

Set the selected step's marker to `[~]` in the body, and the index `Status:`
to `[RUNNING]`. Write both to disk now, before spawning.

The `[~]` marker is **never committed** — it is in-run working state, and it
is the resume signal (see ONE RUN PER RUNBOOK).

### 5. Spawn

Spawn **one** subagent with fresh context, the assembled prompt (see THE
SPAWNED PROMPT), and the model from the runbook header — or from `--model`,
which overrides it for the whole run.

One at a time. Never two. Steps are sequential always, even where the runbook
declares them independent: the user gets one question stream rather than
interleaved clarifications from three agents, and two agents writing `Done:`
lines into the same runbook race on the same file.

**Refuse a nested runbook.** If the step's prompt block invokes
`/runbook-run`, do not spawn it. Mark the step `[!]`, write a `Done:` line
opening with the reason, set the index to `[FAILED]` with `Failed at:`, and
stop. The reason to give: the orchestrator occupies one nesting level and the
step's agent a second, so a nested orchestrator would leave nothing for the
work. `/runbook-create` rejects such a step at authoring time; this check is
what stops a hand-written runbook smuggling one in.

### 6. Wait

**This is the single most dangerous point in the whole feature.**

A spawn returns **asynchronously**: the call yields an id, and the agent's
result arrives later as a separate notification. The return value of the spawn
call is *not* the result. A body that treats it as the result ticks a step
that never ran and commits the lie.

Nothing happens until the result actually arrives. Do not mark, do not write a
`Done:` line, do not commit, do not select the next step. **No step is ticked
before its subagent's result has actually arrived.**

### 7. Handle the result

Four cases, and only four — see THE FOUR RESULT CASES below.

### 8. Commit and loop

Commit the runbook and the index per COMMIT CADENCE, then loop back to step 2
and re-read the body.

When no `[ ]` steps remain — every step is `[x]` — set the index `Status:` to
`[DONE]`, commit, and report: the runbook name, the number of steps, and a
one-line-per-step summary of what each `Done:` line records. Under `--only`,
stop after that single step instead of looping, and set the index back to
`[PENDING]` unless every step is now `[x]`.

---

## THE SPAWNED PROMPT

Assembled in this fixed order, so the operating rules are the last thing the
agent reads:

1. **Preamble.** Orient in a fresh session: tell the agent to read the
   project's `CLAUDE.md` and follow its navigation instructions **as written**
   — the index of each navigation layer, then only the files relevant to this
   step, never a whole layer. Name the runbook and the step number this agent
   is executing; that is what lets a step's subagent call
   `/runbook-create --append` with no name argument.
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
   `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/subagent-contract.md`,
   with only its two placeholders filled in. It is fixed text and goes last.

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

### On `DONE`

Write the `Done:` line from the agent's report: the commit sha, the decisions
taken while executing, and any premise in the step that proved wrong. Then set
the marker to `[x]`, update the index's `Steps:` count (`[x]` only), and
propagate facts (below).

### On failure

Do not retry the step, do not attempt the work yourself, and do not continue
to the next step. Report to the user: which step failed, the reason, what the
agent said, and which steps were never started.

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

---

## THE SPAWN RELAY

**The orchestrator forwards; it does not read.**

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
   model where it says `same`), and a prompt that says: read the file at
   `<prompt path>`, do exactly what it asks, and write your report to
   `<result path>`. Add the OPERATING RULES block, as for any spawn — a child
   is a subagent like any other and is bound by the same contract.
2. **Wait for the child's result**, exactly as for a step's own agent. The
   spawn call returns an id, not the result.
3. **Reply to the same caller subagent** — the one that is suspended awaiting
   this — with one line: the child is finished, and its report is at
   `<result path>`. The caller reads the file and continues.

**Open neither file.** Not the prompt, not the result, not "just to check".
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

### The cap

**Eight relay rounds per step.** A round is one `SPAWN REQUEST` served. On the
ninth, stop: mark the step `[!]`, write a `Done:` line saying the relay cap was
reached and naming how many children ran, set the index to `[FAILED]` with
`Failed at:`, and halt. A step that wants a ninth child is looping, and the
alternative to a cap is an unbounded run nobody is watching.

### The files

Relay files live under the OS temp directory, **never inside the repository**.
The subagent chooses the paths and names them per runbook, step and round; the
orchestrator takes them as given and does not relocate them. Nothing about them
is committed — the staging rule under COMMIT CADENCE is unchanged and exact:
the runbook and the index, by explicit path, and nothing else. They are
transient message-passing, not state, and they are gone with the session.

### `--relay-spawns`

Passing it forces the relay for the whole run: the spawned prompt tells every
step's agent not to spawn at all and to route every child through the relay.
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

---

## COMMIT CADENCE

**One commit per completed step**, staging **exactly** the runbook and the
index — `.claude/runbooks/<name>.md` and `.claude/RUNBOOKS.md`, by explicit
path. Never a catch-all (`git add -A` / `git add .` / `git add -u`). A
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

---

## DO NOT

- Treat a spawn call's return value as the step's result — or a relayed
  child's. It is an id. Wait for the notification.
- Tick a step before its subagent's result has arrived.
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
- Edit the header, `Sequencing:`, `Companion:`, a step title, a
  `Depends on:` or a `Needs:` line — those are `/runbook-create`'s, by line.
- Do a step's work yourself, patch a file a subagent should have patched, or
  fix up a subagent's commit.
- Review, re-test or second-guess a subagent's work. Review is
  `/task-review`'s job, invoked from inside a step's prompt.
- Answer a subagent's question on the user's behalf, or ask the user to
  re-state something an earlier step already settled.
- Compress a draft at an approval gate.
- Classify an ambiguous report as success.
- Spawn a step whose prompt invokes `/runbook-run`.
- Weaken a `Depends on:` because `--from` or `--only` was passed.
- Stage anything but the runbook and the index.
- Open `.claude/context/`, `.claude/domain/`, or a source file.
