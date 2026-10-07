---
name: pipeline-revise
version: 1.2.2
type: skill
description: Revise already-planned work — a set of changes to feature documents, tasks, plan edges and runbook steps — through the owners of every artifact they reach, as one numbered plan behind one gate. Use it for any change to work that is already planned, from one wording fix to a list of amendments, deletions, insertions and reorders.
requires: skill:pipeline-engine, skill:architect, skill:task-engine, skill:runbook-run, skill:product-design, skill:production-plan, skill:product-roadmap, skill:interaction-engine
---

# /pipeline-revise
# Global skill: carry a change set to already-planned work through the
# owners of every artifact it reaches, as one numbered plan behind one
# gate. --catch-up amends the documentation to match code that has
# already landed.
# Usage: /pipeline-revise "<change set>" [--no-commit] [--no-push] [--attended | --unattended]
#        /pipeline-revise <anchor> "<change>" [--no-commit] [--no-push] [--attended | --unattended]
#        /pipeline-revise --catch-up <spec-path | "<landed change>"> [--no-commit] [--no-push] [--attended | --unattended]
#        anchor: feature=<slug> | task=<N> | runbook=<id|name|id-name> step=<n>
# Examples: /pipeline-revise task=42 "Hints: point at the new loader"
#           /pipeline-revise "drop the contact URL from the user-agent (source-inventory, line 178); delete task 214; strike runbook 3 step 9"
#           /pipeline-revise "1. /architect amend feature=a,b: … 2. delete task 214 3. move exit criterion 160 to m3"
#           /pipeline-revise --catch-up .claude/specs/2026-10-07-export-button.md

GOAL
Take every change to already-planned work at once, find what each reaches,
order the owners that must write them, show the whole plan once, and run
it.

The heavy half is analysis. The writing is always the owners'.

$ARGUMENTS

---

THE ENGINE AND THE OWNERS

Take pipeline-wide knowledge from `pipeline-engine`, read by path:

- `../pipeline-engine/references/probes.md` — the probe, its verdict line
  and the reuse rule;
- `../pipeline-engine/references/graph.md` — the edges between the indexes,
  and **the impact walk's only traversal input**;
- `../pipeline-engine/references/routing.md` — which owner each line belongs
  to, and, in its Amend column, the arm a revision routes through;
- `../pipeline-engine/references/lint.md` — the findings the verification
  bracket compares.

- Route every write through an owner: the amend arm `routing.md`'s Amend
  column names, executed by path, or the owner's own command. The branch
  files name each by path at the step that uses it.
- Restate no probe, no edge, no finding and no arm's rule.

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `../interaction-engine/references/policy.md` | Every run, at ARGUMENT PARSING, to resolve the interaction policy. |
| `../interaction-engine/references/messages.md` | Every run, before the gate — the gate, the closing follow-up gate and the report follow it. |
| `../interaction-engine/references/gates.md` | The policy resolved to `unattended`. |
| `./amend.md` | WORKFLOW step 3 classifies an item as amend. |
| `./insert.md` | WORKFLOW step 3 classifies an item as insert. |
| `./delete.md` | WORKFLOW step 3 classifies an item as delete. |
| `./reorder.md` | WORKFLOW step 3 classifies an item as reorder. |
| `./catch-up.md` | The run was invoked with `--catch-up`. |

- Read the branch file of every kind the items classify into, each once;
  never read one no item needs.
- All five share one schema — the same seven sections in the same order:
  *Applies when*, *Impact walk*, *Owner sequence*, *Tier*, *Verification*,
  *Outcomes*, *Never*. "The branch file" below means whichever one is open.

---

ARGUMENT PARSING

1. **Commit flags.** Strip the optional `--no-commit` (COMMIT = false),
   `--no-push` (NO_PUSH = true) and `--commit` flags.
   - COMMIT is true unless `--no-commit` is passed; `--no-commit` implies
     NO_PUSH. `--commit` is accepted and changes nothing.
   - `--commit` with `--no-commit` stops the run with:
     `--commit and --no-commit cannot be combined. Pick one.`
   - What each flag does is COMMITTING.
2. **Policy flags.** Strip `--attended` and `--unattended`, whichever appear.
   - Resolve the run's interaction policy from them, a policy handed down by
     a parent run and the project's `CLAUDE.md`, per
     `../interaction-engine/references/policy.md`, which holds their argument
     errors.
   - Hand the policy down to every owner the run drives, as the flag.
   - This skill has no parking mechanism
     (`../interaction-engine/references/gates.md`); a stopped run writes
     nothing.
3. **Catch-up.** Strip `--catch-up`. CATCH_UP is true when present; what
   follows it is its input — a path to a spec file, or a quoted description
   of a change that has already landed.
   - An input that names a path — it ends in `.md` or sits under
     `.claude/specs/` — must exist; one that does not stops with
     `No spec file at <path>.`
   - An empty input stops with
     `/pipeline-revise --catch-up needs a spec path or the landed change, e.g. /pipeline-revise --catch-up .claude/specs/<file>.md.`
   - Under CATCH_UP there is no anchor and no change set: the items are the
     points `./catch-up.md` § *Applies when* derives, and that file replaces
     step 3's classification.
   - An anchor beside `--catch-up` stops with `--catch-up takes no anchor.`
4. **Anchor** (otherwise). Scan for an anchor in one of three forms, and
   strip it:
   - `feature=<slug>`
   - `task=<N>`
   - `runbook=<id|name|id-name> step=<n>`
5. **Change set.** What remains is the **change set**, as one quoted string.
   An empty change set stops with: `/pipeline-revise needs the change to make, e.g. /pipeline-revise task=42 "Hints: point at the new loader".`

**Items.** The change set is one or more items.

- A numbered list — the shape `/follow-ups` prints, one `<n>.` per line,
  each a command form or a sentence — is one item per number.
- Split free-form text at the changes it describes: each distinct thing to
  change, insert, delete or move is one item, and a sentence naming two is
  two.
- An anchor argument applies to every item that names no artifact of its
  own; an item that names one uses its own.
- The split is the user's to correct at the gate, where `show` prints it.

---

WORKFLOW

**1. Probe.** Run the probe from `probes.md`, or reuse a verdict line
already in the conversation where that file's reuse rule allows. Step 6
reads which owners are installed off this verdict line.

**2. Resolve each item's anchor.**

- Under CATCH_UP, a point's anchor is the document it lags in, resolved as
  below by the feature, task, runbook or milestone that document belongs
  to. A point in a document no anchor form reaches — `CLAUDE.md`,
  `README.md`, a context file — has the context-layer step or the report as
  its owner (`./catch-up.md`).
- Otherwise, per item, in order:
  - `feature=<slug>` — an entry in `.claude/FEATURES.md`. None, or no
    feature index at all, stops: `No feature <slug> in .claude/FEATURES.md. Available: <slug>, <slug>.`
  - `task=<N>` — a summary block `## <N>.` in `.claude/TASKS.md`. An id at
    or below `Last task number:` with no block is archived and terminal, per
    `../task-engine/references/resolution.md` § *The archive*; one above it
    was never assigned. Either way stop, say which, and list the live tasks,
    id and title.
  - `runbook=<id|name|id-name> step=<n>` — the runbook resolved by
    `../runbook-run/references/runbook-schema.md` § *Resolving a runbook
    argument*; one that does not resolve stops listing the runbooks in
    `.claude/RUNBOOKS.md`. Read the step by id in its body — the item's
    target artifact; an unknown id stops listing the runbook's steps.
  - **A milestone** — named in the item (`m3`, `m3-teams`, an exit
    criterion quoted from it) — resolves to a `##` block in
    `.claude/domain/product-roadmap.md`; none stops listing the milestones.
    This anchor has no argument form: only an item names it.
- An item with no anchor argument and none named in its text stops the
  whole run before the gate: name that item and the four anchor forms, and
  list what exists. Never pick between two. A stop here writes nothing.

**Pull at start**, once for the whole run, per COMMITTING.

**3. Classify each item.**

- Under CATCH_UP, every item is the catch-up branch's; a design break's
  answer brings in `./amend.md` or `./insert.md` when it is given.
- Otherwise put each item into exactly one branch, testing in this order;
  the first that matches wins:
  1. **reorder** — an existing task or runbook step is to run at a different
     position;
  2. **delete** — a live task, a pending runbook step or a whole feature is
     to stop being work;
  3. **insert** — a new task or runbook step is to exist;
  4. **amend** — anything else that changes what exists, a milestone line
     and a `Preconditions:` change that moves no entry included.
- Read each branch file the items need, once.
- Record `Item <i>: <branch> — <anchor>` for every item, for the plan `show`
  prints.

**4. Walk each item's impact.**

- Walk from its anchor along `graph.md`'s edges and no other traversal, in
  the directions its branch file's *Impact walk* gives.
- Index lines come first: name every entry the walk reaches from an index
  line.
- Open bodies only within one scope per item, stated here and never
  widened:
  - **the target artifact** — the anchored feature's `Doc:` document (with
    the `product-design.md` section its `Source:` names, when the change
    lands in a design decision), the anchored task's
    `.claude/tasks/<N>.md`, the anchored runbook's body, or the roadmap;
  - **the tasks whose `Preconditions:` name it or whose `Files:` overlap** —
    for a task anchor, the tasks naming `<N>` and those sharing a path with
    its `Files:`; for a feature anchor, the same for each of its live task
    ids;
  - **the runbook steps that name it** — each open runbook `graph.md` E7
    names as a candidate, opened through E6 only to find the steps naming
    the anchor's slug or one of its task ids;
  - **what a headless owner's arm reads to decide**, since step 6 makes
    each arm's decision from those reads: for `/architect amend`, the `.claude/TASKS.md` summary blocks of
    the feature's tasks and a task body only when its block cannot decide.
- Visit every node once across the whole change set: an artifact two items
  reach is one entry in the proposal.

**5. Lint — before.**

- Run `/pipeline-check` scoped to the union of the items' features — one
  `/pipeline-check feature=<slug>` per feature reached, or `/pipeline-check`
  unscoped when any item anchors on a runbook or a milestone, or names a
  task whose `Feature:` does not resolve.
- When `/pipeline-check` is not installed, evaluate `lint.md` directly over
  the indexes and keep the findings whose identifier is an anchor or an
  entry a walk reached, rendered from their templates unchanged.
- Keep the findings: step 9 compares against them.

**6. Propose.** Build the plan from the branch files, then merge, order and
decide.

*Merge.* Take the owner steps of every item as one set. Two items that
reach the same artifact become one step:

- several sections of one feature document → one `/architect amend
  feature=<slug>` naming them all;
- several feature documents → one `/architect amend feature=<a>,<b>` run;
- several edits to one task → one task amend;
- every roadmap edit → one `/product-roadmap amend`; every plan edit → one
  `/production-plan amend`; every design-decision edit → one
  `/product-design amend`;
- the runbook steps of one runbook → one `/runbook-create --append` when
  they insert, and one step each when they strike or add a `Context:` fact.

*Order.* Upstream first, as every branch file orders its own sequence, and
across items: design decision → the roadmap → feature documents → task
amends → removals (`[SKIP]`) → task insertions and `/task-add`
reconciliation → the plan → runbook strikes, facts and insertions.

- A step whose input is another step's output — a runbook step for a task
  an earlier step creates — comes after it, whatever the kinds say.
- The user moves steps at the gate; the plan states this order once.

*Decide.* Make here every decision an owner's arm makes by a closed rule
over its reads, from the reads step 4 put in scope, and show it on its
step:

- `/architect amend` — the editorial classification per feature, by
  `../architect/amend.md` § 4's clear-or-ambiguous rule over the touched set
  and the scope call; ask an ambiguous feature **at this gate**, in that
  arm's question form, and carry the answer in;
- a task amend — the drafted fields and body sections, per
  `../task-engine/references/amend.md`;
- a runbook strike, `Context:` fact or insert — the struck id and reason,
  the dated fact, or the step's prompt, per
  `../runbook-run/references/step-amend.md`;
- the design, roadmap and plan arms — the drafted edit, per
  `../product-design/amend.md`, `../product-roadmap/amend.md` and
  `../production-plan/amend.md`.

Tag the steps:

- **headless** — a step decided above: it runs with the decision carried in
  and asks nothing.
- **GATED**, with one `Will ask:` line naming what it will ask (approve the
  drafted bodies; the design-change question; the orphan question):
  - a `/task-add` create or reconcile step — the one owner whose work is
    drafting;
  - a task amend whose draft adds a point at which the task diverges from a
    document another command owns, since that design-change question is
    answered only at the arm's own gate.
- Sort gated steps last wherever the order above allows, so every headless
  write lands before the first stop.

- A reconciliation step is conditional and shows its evidence: `because step 1 stales 12, 14`,
  or `because step 1 adds scope no task covers`. When step 1's carried
  classification is editorial for every feature, render no reconciliation
  step.
- An id unknown until a step runs is a placeholder in every later step that
  needs it: `<id from step 5>`.
- Before rendering, check every owner a step needs is installed — read off
  the verdict line's `installed` field. A step whose owner is missing stops
  the run here, before the gate and before any write:

> Can't revise: step <i> needs `<owner>`, which is not installed. Install it
> with `chosko-llm add`, then re-run.

**7. The gate.** One message, written to
`../interaction-engine/references/messages.md`. It carries, in order:

1. **the verdict** — one line: how many changes the plan makes, how many
   ask something at their owner's own gate, and whether anything is open;
2. **one plain sentence per change**, numbered as the owner steps are, in
   order — what the step changes and why, in words, with the identifiers
   last in parentheses; a step that will ask at its owner's own gate says
   what it will ask, a conditional step says on what, and a step carrying a
   decision says the decision in words (*wording only, no task to re-plan*);
3. **step 5's findings in scope**, only when there are any;
4. **the questions** — any architect question still open, in
   `../architect/amend.md` § 4's ambiguous form, one per feature, and under
   CATCH_UP each design break's question, in `./catch-up.md`'s form — last,
   with at most a one-line hint of the reply shortcuts.

- Keep internal, not printed at the gate: the item split, the classification and tier per item, the touched and
  untouched entries, the owner-step table with its invocations, arm paths
  and headless / GATED tags, and the drafts.
- A `show` reply prints them — the full plan, drafts included — and asks
  again; a `show <n>` prints one step's.
- Gate class: `confirmation` when no question is open, `design` otherwise
  (`../interaction-engine/references/gates.md`).
- Under `unattended`, a plan with no open question passes on its own — the
  run proceeds as on `go`, and the report names the commit — and a plan with
  one stops the run here, nothing written. Otherwise wait for the reply.

The reply grammar:

- `go` — run the plan as rendered;
- `all but <n>[, <m>]` — drop those steps and run the rest;
- `<n> as runbook step` — defer step n: it is appended, as one
  self-contained step carrying its invocation, anchor, change and every
  decision taken here, to the runbook the reply names, or to the runbook
  this session is running, or, naming none, to a new runbook
  `/runbook-create` creates from the deferred steps; `all as runbook
  steps` defers the whole plan;
- `<n> after <m>` — move step n below step m;
- a letter for an open architect question (`a: A`) or a design break
  (`2: a`), or an overruled touched/untouched call or tier, as the arm's own
  reply rules allow;
- `stop` — write nothing.

- Any reply but `go` and `stop`: apply the edit, re-show only the lines it
  changed, at the same gate, and wait again.
- A step the reply drops that another step depends on drops that step too,
  named.
- Silence, an unclear reply or EOF is `stop`.
- Nothing is written before `go`, by this skill or by any arm it drives.

**8. Actuate.**

- Run the steps one at a time, in order — never in parallel, never in a
  subagent.
- Before each, print one line: `Step <i>/<k> — <owner>: <invocation>`.
- A headless step: execute its arm from its file by path, with the decision
  carried in:
  - `/architect amend` receives the classification per feature,
    `../architect/amend.md` § 4 *A classification carried from
    `/pipeline-revise`*;
  - the design, roadmap and plan arms receive the draft, and write without a
    gate when it matches theirs;
  - the task and runbook arms receive their drafted content.
- A gated step: run its owner's command as the user would invoke it, with
  the owner's own gate asked exactly as the owner asks it.
- Run every step without committing, per COMMITTING.
- After each, print its closing line, as the owner writes it.
- Drop, with one line saying why, a later step an earlier step's outcome
  made moot — a reconciliation whose `/architect amend` staled nothing after
  all.
- Never add a step after the gate; what execution surfaces goes to step 10.

*Deferred steps.* Once the in-session steps have run, invoke
`/runbook-create --append <runbook> --after <step>` (or `/runbook-create
<name>` for a new runbook) with the deferred steps as its follow-up list,
in plan order, each prompt self-contained, and `--no-commit`.
`/runbook-create`'s own gate decides what is written; this skill writes no
line of the runbook.

**9. Lint — after, and verify.**

- Run step 5's scoped `/pipeline-check` again — also when the sequence
  stopped part-way, so the report shows the state it left.
- Report failures only: findings created and findings left unchanged; a
  bracket with neither prints nothing.
- Where an insertion or a deletion changed a precondition, read the
  successor tasks' bodies afterwards — the tasks whose `Preconditions:`
  gained or lost an id — and confirm the sequence still reads as a
  sequence. The branch file's *Verification* says when this applies.

**10. The closing follow-up gate.** Collect what execution surfaced and the
plan did not hold:

- a task a `/task-add` step created that no open runbook running its
  feature has a step for;
- a successor that no longer reads as a sequence;
- a lint finding step 9 reports as created;
- a feature an owner's closing line names for reconciliation that no step
  ran.

When there is nothing, skip this step. Otherwise:

- Render the items as step 7 does — one plain sentence each, numbered,
  proposing its owner step, the question last — and wait, with step 7's
  reply grammar; gate class `design`: `go` runs them here, one at a time as
  step 8 does; `<n> as runbook step` defers; `all but`; `stop` leaves them
  to the report.
- Write nothing on this list without the reply.
- When anything ran here, run step 9's scoped check once more afterwards;
  the difference step 12 reports is measured from that run.

**11. Commit.** When the sequence completed — a step dropped as moot or by
the reply still counts as completed — and at least one step wrote, the
runbook `/runbook-create` wrote for deferred steps included, make the
revision's one commit and push, per COMMITTING, the report line below as
the subject. Otherwise make none (COMMITTING § **No commit**).

**12. Report.** Written to `../interaction-engine/references/messages.md`
§ *Output*.

```
Revised <items> items — <run>/<k> owner steps run, <d> deferred, <m> dropped.
```

Then, in order:

- each step's closing line;
- the lint failures when there are any
  (`Lint: created <n> (<L-ids>), unchanged <n> (<L-ids>).`);
- the sequence check's result when it failed;
- the follow-ups the closing gate left to the report;
- every follow-up an owner named that no step covered;
- the commit hash.

When anything was written and no commit was made — `--no-commit`, or a
sequence that stopped part-way — list every path written so far and end
with an explicit reminder that nothing was committed.

---

COMMITTING

This skill owns the run's commit: exactly one per revision, made at the
end — never one per owner step. Commit and push
gating is `../task-engine/references/commit.md`.

- **Pull at start** — once per run, after every item resolves and before
  the walks (WORKFLOW step 2), unless `--no-commit` or `--no-push`. A
  conflict stops the run there, nothing written.
- **Every owner step runs uncommitted.**
  - A command owner — `/task-add`, `/runbook-create` (`--append` included) —
    always receives `--no-commit`, whatever its own default.
  - An arm executed by path — `architect`'s `amend.md`, `product-design`'s,
    `product-roadmap`'s and `production-plan`'s `amend.md`, `task-engine`'s
    `references/amend.md`, `runbook-run`'s `references/step-amend.md` — is
    executed with no commit.
  - No owner step pulls or pushes.
- **One commit.** After the closing follow-up gate:
  - stage exactly the union of the paths the owner steps reported writing —
    a runbook `/runbook-create` wrote for deferred steps included, and under
    CATCH_UP the deletion of the spec it was given (`git rm -- <spec>`) — by
    explicit path;
  - commit once, the `Revised …` report line as the subject;
  - re-sync and push per `commit.md`'s push protocol, the push skipped under
    `--no-push`;
  - report the hash.
- **No commit** on a stop before the gate, `stop` at either gate, a
  sequence that stops part-way (an owner refuses, or its gate is answered
  stop), a run that wrote nothing, or `--no-commit`. Leave a partial
  sequence uncommitted on purpose: every commit holds a complete revision.

---

WRITE SET

Closed, and empty but for one deletion:

- Write no line any owner owns, and no file of your own — no index line, no
  body, no runbook, no report on disk.
- Every write in a run is an owner step's, through an arm or an owner
  command, after the gate.
- The one exception is CATCH_UP's: its commit deletes the spec file it was
  given, the deletion `/quick-implement`'s spec lifecycle assigns to it.
- The commit stages only those writes.

---

FAILURE CONTRACT

- **An item whose anchor resolves to nothing** (step 2) and **a step whose
  owner is not installed** (step 6) stop the run before the gate, nothing
  written.
- **An owner that refuses** — a touched `[IN PROGRESS]` task, a `[DONE]`
  task, a position on a `[RUNNING]` runbook its arm will not take — or a
  user who answers stop at a gated owner's own gate, **stops the sequence at
  that step.** Earlier steps' writes stay intact, uncommitted, and are
  reported path by path, **never rolled back**; the steps not run are
  listed; step 9 still runs; nothing is committed.
- **`/runbook-create` absent** makes `as runbook step` an error naming it,
  shown at the same gate, which waits again.
