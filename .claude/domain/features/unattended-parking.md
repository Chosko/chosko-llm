# Unattended parking

An execution policy for `/runbook-run` and `/task-implement` under which a
question nobody is present to answer no longer halts the whole run. Under the
`unattended` policy the step or task that asked is **parked** — its question
recorded verbatim, its work-in-progress kept on a branch where a task made
one — and the run moves on to whatever does not depend on it. The question is
answered later: at the next launch, in chat while the run is still going, or
after the closing report, and the parked item is then **unparked** and
resumed. Under the default `attended` policy nothing changes: a question is
relayed to the user and the run waits, exactly as today.

## Purpose

A runbook launched to work overnight, or a batch `/task-implement all`, is
only as unattended as its most curious step. Today a single clarifying
question — a wording choice in a test, an ambiguous acceptance criterion —
ends its turn under `QUESTIONS FOR USER`, the orchestrator relays it, and the
run waits until morning with every later step untouched. The question was
often small; the cost was the whole night.

The feature keeps the question and drops the wait. It gives the two run-level
skills of the [Task backlog](../product-design.md#task-backlog) one policy
switch, one way to set a question aside without losing the work behind it,
and one way to bring it back. It restates no part of
[runbook-suite](./runbook-suite.md) or
[task-implement-launcher](./task-implement-launcher.md); it names the
contracts of those features that gain a branch under the new policy, and
what that branch does.

## Scope and non-goals

In scope: the policy and how it reaches every agent a run spawns; parking and
unparking a task, with its work-in-progress preserved on a branch; parking
and unparking a runbook step; how an answer gets in — before a run, during
it, after it; the closing report's single follow-up list; and the ripple into
the read-only and lint commands that must recognise a parked item.

Deliberately out:

- **Asking fewer questions.** The subagent contract's *never answer on the
  user's behalf* stands. Parking changes what happens after a question is
  asked, not whether it is asked.
- **Pre-reading tasks to predict questions.** Ambiguity is found by doing the
  work, and an orchestrator that pre-read every body to look for it would
  spend the context its thinness exists to protect.
- **Parking as a general escape hatch.** Parking is the outcome of exactly one
  event: **a question the agent asked** — `QUESTIONS FOR USER` from a step
  agent, or a skill's own blocking question inside a task. Every other gate
  keeps the outcome it has today: an unmet precondition skips, a dependency
  that is not `[x]` makes a step unselectable, a failure is `[!]` or
  `[IN PROGRESS]`, and a prompt that already resolves on silence takes that
  value (see *Prompts with a default*). None of those deserve a handoff and
  none get one.
- **Work-in-progress for runbook steps.** A task parks its uncommitted edits
  on a branch; a generic runbook step does not. A step agent that must ask
  under `unattended` leaves the tree clean of its own changes first — work a
  skill has already parked on a branch is not "its own changes".
- **Parking under `attended`.** Never. An attended run halts on a question as
  it does today; parking exists only where no answer can come.
- **Notification.** How the user learns a run is waiting (push, mail, hook)
  is a separate concern and not part of this feature.
- **Storing an approval-gate draft in the handoff.** The draft is the
  work-in-progress and is on the parking branch already; a copy in the body
  would be the duplication the handoff rules forbid.
- **Non-git projects.** `--unattended` is refused where the project's
  `CLAUDE.md` maps git to another VCS: a parking branch is the mechanism, and
  there is no equivalent to invent there.

## Architecture

Built on the repo's existing shape per `technical-direction.md`: shipped
markdown skills whose runtime is Claude Code. The change lands in
`skills/task-implement/`, `skills/task-engine/references/` and
`skills/runbook-run/` (see `.claude/context/features.md`), plus the small
ripple named at the end. It adds no CLI surface and no script.

### Load discipline

The protocol is read only when it can apply. Each half lives in a reference
file beside the rules it extends — `parking.md` under
`task-engine/references/` for tasks, `parking.md` under
`runbook-run/references/` for runbooks — and each is opened on exactly two
triggers: the run's policy resolved to `unattended`, or the run is about to
touch an item that is already parked (`[PARKED]` in the resolved task list,
`[P]` selected or blocking selection). A run under `attended` that never meets
a parked item never loads either file. What the always-read bodies gain is
one line each: the status vocabulary's ninth tag, the schema's fifth marker,
the flag row, the pointer to the reference.

### The policy and its carriers

One signal, `attended` or `unattended`, with `attended` the default
everywhere.

- **Runbook.** A header line `Execution policy: attended|unattended`, authored
  by `/runbook-create` and owned by it like the other header lines; absent
  means `attended`. `/runbook-run --attended` and `--unattended` override it
  for one run; both together is an argument error.
- **`/task-implement`.** A `--unattended` flag and nothing else — no
  `CLAUDE.md` marker, no header. `--unattended` beside `--no-commit` is an
  argument error: parking is made of commits.
- **Into a step agent.** The runbook prompt block is verbatim and the
  subagent contract forbids adding a flag the user did not type, so the
  policy cannot be typed into a step's `/task-implement` line. It travels the
  way `--relay-spawns` does: one sentence in the spawned prompt's preamble,
  present only under `unattended`. `/task-implement` resolves UNATTENDED as
  *the flag was passed, or the conversation declares this run unattended*. The
  sentence says **unattended**, not *non-interactive*: an attended runbook's
  step agent is also non-interactive — it relays — and must not park.
- **Into a delegated agent.** `./delegated-runs.md`'s fixed-size prompt
  carries UNATTENDED in its resolved-flag list, which is already O(1) in the
  batch.

Under `attended`, delegated runs gain the question relay they lack today: a
delegated agent's question returns to the launcher as its own result case,
the launcher relays it to the user in the runbook's fixed block and sends the
answer back to the same agent. Stop-and-report on a human decision was a
choice of `delegated-runs.md`, not a limit of the Agent tool — `/runbook-run`
relays over the same tool — and keeping it would leave attended batches
halting where attended runbooks wait. Under `unattended` the agent parks
instead and returns `[PARKED]` as its terminal status; the launcher records
it and spawns the next.

### Prompts with a default

`--unattended` must survive every prompt a run can raise, and only a question
about the work can park. The rule for the rest costs no list: **a prompt
whose silence already resolves to a value takes that value** — the delegation
question to *no*, the `[PARTIAL]` surfacing to writing `[PARTIAL]`, the
feature-flip proposal to *none*, `Proceed?` to *yes*, the dirty-tree prompt at
pre-flight to *abort*, an explicitly named `[STALE]` task to *skip with one
line*. The one prompt with no default today, an ambiguous test runner, aborts
the run. Each taken default is a *For the record* line. Pre-flight prompts
can never park — there is no current task yet — which is why they need this
rule and nothing more.

### Task parking

**`[PARKED]`** joins the status vocabulary in `task-engine`'s `status.md`:
non-terminal, never in a default prune set, written and cleared only by
`/task-implement`. A task waiting on a parked task is blocked by the ordinary
precondition rule, since `[PARKED]` is neither `[DONE]` nor `[SKIP]`, and
appears in the ordinary blocked report; nothing new is needed there.

Parking happens inside the per-task workflow, at the moment the question is
asked, and produces:

- **The handoff**, a trailing `## Parking handoff` section in the task body —
  the one section of a body `/task-implement` writes, and it removes it at
  unpark. Its fields, in order: `Parked:` (date, the step reached, one reason
  clause, and the word `approval gate` when the question is one),
  `Parking Branch:` (`park/task-<N>` or `[none]` when nothing had been
  edited), and `Question:` — the question **verbatim and multi-line**,
  options included, never compressed. Nothing else: the body, the referenced
  files and the branch are re-read at unpark, so the handoff never restates
  them.
- **The parking branch**, `park/task-<N>`, holding **one commit** of the
  task's uncommitted work — tracked edits and the untracked files it created,
  **excluding** `.claude/TASKS.md` and the task body — branched from the
  current head and pushed. A branch of that name already existing is an
  inconsistent state and fails the park; it is never overwritten.
- **The bookkeeping commit** on the base branch: the `Status:` flip to
  `[PARKED]` and the handoff section, and only those. It follows the branch
  commit and the checkout back, so the base tree is clean when the run
  continues.

Under `--no-push` the branch exists locally only; an unpark on another
machine then fails as *branch not found*, which is reported, not worked
around.

### Task unparking

Unparking is a **transaction**: nothing destructive happens until the last
step, and any failure rolls back to the parked state exactly as it was.

1. **Ask first** — the handoff's question, to whoever can answer (see *Answer
   intake*). Asking before touching the tree is what lets a `skip` cost
   nothing and what matches the pre-ask, which can only ask first. The one
   exception is an `approval gate`: its draft is the work-in-progress and
   cannot be approved unseen, so a gate cherry-picks first and asks with the
   draft in the tree. A gate is therefore never pre-answerable; the pre-ask
   lists it as skip-only.
2. **Cherry-pick the parking commit without committing** onto the current
   head. A conflict aborts the pick and restores the tree.
3. **Delete the branch**, local and remote.
4. **Resume the task** at the step the handoff names: the `Status:` flip to
   `[IN PROGRESS]` and the handoff's removal ride in the task's own commit,
   as Step 1's flip does today. Step 7 commits as always.

On failure at step 2: under `unattended`, the task stays `[PARKED]`, the
answer already given is recorded in the handoff (an `Answer:` line and a
`Parked:` reason now naming the merge failure), that update is committed as
bookkeeping so the next task does not meet a dirty tree, the task is skipped
and the closing report names it as needing an attended unpark. Under
`attended`, the run halts and asks how to merge.

**Unpark is attempted whenever an answerer exists**: an attended session when
the task is reached, or an unattended run holding an answer from the pre-ask
or from chat. An unattended run holding no answer skips the task with one line
— never re-parks it, so no branch is touched and no commit is made. `all` and
`next` treat `[PARKED]` as implementable under that condition; a `[PARKED]`
task named by number is unparked under either policy.

### Runbook parking

**`[P]`** joins the step markers as the fifth: *parked — a `Context:` bullet
carries the question*. It counts as not done in `Steps:`, is committed like
`[x]` and `[!]` (unlike `[~]`), and the index gains a `Parked: steps <ids>`
line present only while at least one step is `[P]` — the `Failed at:` rule
applied again, so `/runbook-list` shows a parked runbook without opening its
body.

The orchestrator's result table gains a fifth row, active only under
`unattended`: `QUESTIONS FOR USER` → mark `[P]`, append
`- <date> parked: <question verbatim>` to the step's `Context:`, print the
question in chat with a number handle, commit, continue. The orchestrator
still compresses and never answers; it stores the block's question and
options, not an approval-gate draft. Attended runs keep the relay row and
never reach this one.

A parked step is a step whose dependents are not `[x]`, so those become
unselectable — untouched, not parked. Selection gains one branch: steps remain,
none is selectable, and at least one is `[P]` → this is not a deadlock and
not a failure; the run ends with the index at `[PENDING]` and the closing
report naming the parked steps and the steps waiting on them. A runbook that
is a linear chain therefore stops after its first parked step; the value of
continuing is proportional to how honestly `Depends on:` was authored, and the
report says exactly what to answer either way.

Three lines join the subagent contract as fixed text, conditional on the
preamble's policy sentence: under `unattended`, leave the tree clean of your
own changes before ending with a question, and say so in the block; an answer
recorded in your `Context:` answers the invoked skill's question — do not
relay it back; and the dirty-tree prompt that lists only the runbook and the
index is answered `proceed` — the inline contract's rule, ported, closing the
gap that makes a spawned step's `/task-implement` ask on every step. Under
`--inline` the session follows the same three under its own contract.

Unparking a step is bookkeeping only: append
`- <date> unparked with answer: <text>` to `Context:` and set the marker to
`[ ]`. The step is above the current one in list order, so the ordinary
top-down selection picks it next — stated as a rule anyway, so the behaviour
is a promise and not a coincidence. When the step's prompt is a
`/task-implement` on a task that is itself `[PARKED]`, the answer is recorded
on the step only; the task unparks when the step executes, the step's agent
answering its skill's question from `Context:`. Runbook steps never park work
on a branch; the task's branch is the task's.

### Answer intake

Three moments, one handle:

- **Pre-ask, at launch, `unattended` only.** The user typing the command is
  present at that instant. Before the run starts, one block lists every
  `[P]` step in range (runbook) or `[PARKED]` task in the resolved list
  (task-implement), each with its question verbatim, numbered; the user
  answers by number or replies `skip`, per item or for all. Runbook answers go
  into `Context:` at once; task answers are held in run memory and fed at
  unpark. An attended run has no pre-ask: it asks when it reaches the item,
  after the user has seen the earlier steps' outcomes. `--skip-parked`
  suppresses the pre-ask for a launch no human sees — a routine, a scheduler,
  an orchestrator that is itself a subagent, which implies it.
- **Mid-run, in chat.** A parked question is printed with a number when it is
  parked. A reply by that number, or naming the step or task, is its answer:
  it is recorded (runbook `Context:` and `[ ]`; task memory) and the item is
  unparked after the current step or task finishes, before the next —
  `[P]`→`[ ]` above the current step is selected next by list order; an
  answered task moves to the front of the remaining list. Any other message
  is ordinary conversation and the run continues. An answer to a question this
  run never printed is rejected and records nothing; a second answer to an
  already-answered question is rejected too — the first wins, and changing it
  is a hand edit of `Context:`.
- **After the closing report.** Parked items are listed there with their
  question verbatim and a number; replying by number is the same act as
  mid-run, and unparks on the next run.

### The closing report

Both skills' closing reports become two groups in this order: **For the
record**, then **Follow-ups** — last, nearest the prompt, since its numbers
are the reply handle. The `Needs you` group and the separate `/follow-ups`
call after the report are replaced by one list: the run's own items (the
flip question, a failed step, a `[~]` step, steps or tasks left outside the
range, every parked item with its verbatim question) and the items
`/follow-ups`' rules yield when applied to the run's reading — the command's
body read and applied, never invoked, the pattern delegated agents already
use — de-duplicated by action, the command form kept where two items name the
same one, under one numbering. Neither old list was a superset of the other:
`Needs you` carried on-disk pointers `/follow-ups` excludes by rule, and
`/follow-ups` carried unrecorded conversation facts `Needs you` never held. The
standalone `/follow-ups` command is unchanged and already prints under the
same `Follow-ups` heading. `requires: command:follow-ups` stays; where the
command is absent the list is the run's own items only, silently.

### Ripple

Kept to a line each: `/task-list` shows `⚠ parked` in its existing marker
column; `/task-clean` adds `[PARKED]` to its why-pruning-is-unusual list;
`/pipeline-check` gains two probes — a `[PARKED]` task without a handoff
section, a `[P]` step without its `Parked:` index line — and no branch
probe, since git across machines makes it noise; `/task-add feature=<slug>`
reconciliation treats a parked task as it treats `[MISSING]` and deletes the
parking branch on skip-and-replace; `/architect` leaves `[PARKED]` alone.
`/runbook-create` writes the header line when asked and never by default.
The pipeline-engine routing rows for both skills list the new flags.

## Data and state

- **`Status: [PARKED]`** in `.claude/TASKS.md` — ninth tag, non-terminal,
  written and cleared by `/task-implement` only.
- **`## Parking handoff`** in `.claude/tasks/<N>.md` — `Parked:`,
  `Parking Branch:`, `Question:` (multi-line verbatim), plus `Answer:` only
  after an unpark whose merge failed. Present exactly while the task is
  `[PARKED]`; removed in the unpark commit. The body is otherwise never
  written by this feature.
- **`park/task-<N>`** — one commit, the task's work-in-progress minus the two
  backlog files, pushed unless `--no-push`. Exists exactly while the task is
  `[PARKED]` with a non-`[none]` branch; deleted as the last step of a
  successful unpark, or by reconciliation's skip-and-replace.
- **`[P]`** on a step heading, committed; **`Context:`** bullets
  `parked: …` and `unparked with answer: …`; **`Parked: steps …`** in the
  index while any step is `[P]`; **`Execution policy:`** in the header,
  absent by default.
- **In memory only:** pre-ask and chat answers for tasks, until unpark; the
  run's resolved policy; the number handles printed this run.

The source of truth is the filesystem throughout: a `[PARKED]` task without a
branch is `[none]` or an error the unpark reports; nothing is derived from a
lock, a timestamp or a cache.

## Interfaces and contracts

```
/runbook-run <runbook> --unattended            park on a question; pre-ask parked steps in range first
/runbook-run <runbook> --attended              override a header `Execution policy: unattended`
/runbook-run <runbook> --unattended --skip-parked   no pre-ask; parked steps stay parked
/runbook-run <runbook> --attended --unattended  error
/task-implement <sel> --unattended             park on a question; pre-ask parked tasks in the list first
/task-implement <sel> --unattended --skip-parked
/task-implement <sel> --unattended --no-commit  error
/task-implement <sel> --unattended             error on a non-git VCS
```

| Contract today | Under `unattended` |
|---|---|
| `QUESTIONS FOR USER` → relay and wait | → park `[P]`, print with handle, continue |
| Delegated agent: stop-and-report on a human decision | attended: relay; unattended: park, return `[PARKED]` |
| Subagent contract: never answer on the user's behalf | Unchanged; plus clean tree before a question, Context answer answers the skill, runbook-WIP dirty-tree prompt self-answered |
| Selection: none selectable → deadlock | → not a deadlock when a `[P]` step exists; run ends `[PENDING]` |
| `all` / `next` skip non-implementable statuses | `[PARKED]` implementable when an answerer exists, else skipped with one line |
| Closing report: Needs you, For the record, then `/follow-ups` | For the record, then one Follow-ups list |

Failure contract: a park that cannot make its branch (name taken, push
refused) fails the task as any Step 7 failure does, `[IN PROGRESS]`, tree
intact; an unpark that cannot cherry-pick rolls back and leaves `[PARKED]`;
an answer that matches no printed question is rejected with one line; a
header policy value outside the two words is an argument error.

## Dependencies

- [runbook-suite](./runbook-suite.md) — the markers, index, result table,
  subagent contract and relay this feature extends.
- [runbook-inline](./runbook-inline.md) — the inline contract's dirty-tree
  self-answer, ported to the spawned contract; the inline session honours the
  three new lines under its own rule set.
- [task-implement-launcher](./task-implement-launcher.md) — the fixed-size
  agent prompt carries UNATTENDED; the six-field return gains `[PARKED]`;
  the launcher gains the attended relay.
- [task-peer-review](./task-peer-review.md) — the review loop's approval
  gates are the `approval gate` case of the handoff.
- [shared-phase-engine](./shared-phase-engine.md) — `parking.md` is a
  `task-engine` reference; `status.md` and `resolution.md` gain their lines.
- [pipeline-engine](./pipeline-engine.md) — two probes; routing rows for the
  new flags, guarded by `check-routing.sh`.
- `/follow-ups` (command) — its rules are applied by the closing report; the
  command itself is unchanged.

## Open questions

None outstanding. The policy, its carriers, the parking and unparking
sequences, the answer intake and the report merge are recorded above as
decisions.
