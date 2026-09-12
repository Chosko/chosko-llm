---
name: pipeline-revise
version: 0.1.0
type: skill
description: Revise work that is already planned — change, insert into, remove from or reorder a feature document, a task or a runbook step — through the owners of every artifact the change reaches. Probes, resolves an anchor (feature=<slug>, task=<N> or runbook=<name|id> step=<n>, or one the description names), classifies the request into exactly one branch — amend, insert, delete or reorder — and reads only that branch's file, then runs the impact walk in both directions over the pipeline's index graph, opening bodies only within the anchor's scope. /pipeline-check scoped to the anchor runs before the proposal and again after actuation, and the report shows the difference. The proposal names its tier — editorial, local or structural — the artifacts touched, the owner steps in order and the lint findings it will create or clear, behind a single gate that asks every time whether the change is editorial; nothing is written before it. Three or fewer owner steps run in the session, one at a time, each through its owner's amend arm or command with that owner's own gate intact; at four or more steps the gate also offers to hand the plan to /runbook-create and stop, when that command is installed. Removal is [SKIP] or a struck step, never physical deletion. Writes no line any owner owns and has no commit of its own — --commit / --no-push are forwarded to each owner step. For a change one owner's amend arm covers, /pipeline-patch is the cheaper tool.
requires: skill:pipeline-engine, skill:architect, skill:task-engine, skill:runbook-run
---

# /pipeline-revise
# Global skill: carry one described change to already-planned work through
# every artifact it reaches — feature documents, tasks, plan edges, runbook
# steps — by walking the impact, proposing a tiered plan behind one gate, and
# running each owner's own amend arm or command in order. Writes nothing itself.
# Usage: /pipeline-revise [<anchor>] "<change>" [--commit] [--no-push]
#        anchor: feature=<slug> | task=<N> | runbook=<name|id> step=<n>
# Examples: /pipeline-revise feature=password-auth "Data and state: sessions expire after 30 days"
#           /pipeline-revise task=42 "insert a task after 42 that migrates the config format"
#           /pipeline-revise runbook=implement-auth step=4 "strike it — task 44 was dropped"
#           /pipeline-revise "remove feature legacy-import"   (anchor named by the change)

GOAL
A design decision or a planned task changes after planning. Without this
skill every affected artifact needs its own command run and its own gate, and
the user carries the sequence — and the risk of the forgotten step. This skill
carries it instead: it finds what the change reaches, orders the owners that
must write it, shows the whole plan once, and then runs it one owner at a time.

The heavy half is analysis. The writing is always the owners'. A change that
one owner's amend arm covers pays less through `/pipeline-patch`; a user who
chose this skill for such a change still gets it run here, at this cost.

$ARGUMENTS

---

THE ENGINE AND THE OWNERS

What this skill knows about the pipeline as a whole is `pipeline-engine`'s,
read by path:

- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/probes.md`
  — the probe, its verdict line and the reuse rule;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/graph.md`
  — the edges between the indexes, and **the impact walk's only traversal
  input**;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/routing.md`
  — which owner each line belongs to, and, in its Amend column, the entry a
  revision routes through;
- `${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/lint.md`
  — the findings the verification bracket compares.

Every write goes through an owner: the amend arm `routing.md`'s Amend column
names, executed by path, or the owner's own command. The branch files name
each by path at the step that uses it.

This skill restates no probe, no edge, no finding and no arm's rule. What
follows is only what it does that none of them does.

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `./amend.md` | CLASSIFY found that something which already exists changes and nothing is added, removed or moved — a `Preconditions:` change that moves no entry included. |
| `./insert.md` | CLASSIFY found that a new task or a new runbook step is to exist at a position in its sequence — with the scope its feature document must newly promise, when it must. |
| `./delete.md` | CLASSIFY found that a live task, a pending runbook step or a whole feature is to stop being work. |
| `./reorder.md` | CLASSIFY found that an existing task or runbook step is to run at a different position. |

Do not read a supporting file speculatively. Exactly one of the four is read
per run, once CLASSIFY has chosen it, and never a second: a request of two
kinds is two runs. All four share one schema — the same seven sections in the
same order: *Applies when*, *Impact walk*, *Owner sequence*, *Tier*,
*Verification*, *Outcomes*, *Never* — so this file refers to a section of
"the branch file" without caring which one was read.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--commit` flag (COMMIT = true) and the
optional `--no-push` flag (NO_PUSH = true), and strip both. NO_PUSH only
matters when COMMIT is true. Neither is acted on by this skill itself — see
COMMITTING.

Then scan for an anchor in exactly one of three forms, and strip it:

- `feature=<slug>`
- `task=<N>`
- `runbook=<name|id> step=<n>`

What remains is the change, as one quoted string. An empty change stops with:
`/pipeline-revise needs the change to make, e.g. /pipeline-revise task=42 "Hints: point at the new loader".`

No anchor is legal: step 2 looks for one in the change.

---

WORKFLOW

**1. Probe.** Run the probe from `probes.md`, or reuse a verdict line already
in the conversation where that file's reuse rule allows. The verdict line is
also where step 6 reads which owners are installed.

**2. Resolve the anchor.** Given an anchor:

- `feature=<slug>` — an entry in `.claude/FEATURES.md`. None, or no feature
  index at all, stops: `No feature <slug> in .claude/FEATURES.md. Available: <slug>, <slug>.`
  (or that the project has no feature index).
- `task=<N>` — a summary block `## <N>.` in `.claude/TASKS.md`. An id at or
  below `Last task number:` with no block is archived and terminal, per
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
  § *The archive*; one above it was never assigned. Either way there is no live
  task to revise: stop, say which, and list the live tasks, id and title.
- `runbook=<name|id> step=<n>` — the runbook resolved by
  `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/runbook-schema.md`
  § *The store*'s one rule; an unknown one stops listing the runbooks in
  `.claude/RUNBOOKS.md`. The step by id in its body — the anchor's target
  artifact, read here; an unknown id stops listing the runbook's steps, id,
  marker and title, in list order.

With no anchor, look in the change for exactly one of: a slug on
`.claude/FEATURES.md`, a task id that has a summary block, or a runbook name
or id together with a step id. One → that is the anchor, stated in one line
(`Anchor: task=42 — named in the change.`) and resolved as above. None, or
more than one → stop, naming the three anchor forms and listing what was
found — or, when nothing was, the features, the live tasks and the runbooks
that exist. Never pick between two.

**3. Classify.** Put the request into exactly one branch. Test in this order;
the first that matches wins:

1. **reorder** — an existing task or runbook step is to run at a different
   position;
2. **delete** — a live task, a pending runbook step or a whole feature is to
   stop being work;
3. **insert** — a new task or runbook step is to exist;
4. **amend** — anything else that changes what exists, including a
   `Preconditions:` change that moves no entry.

A request of two kinds — "reword task 42 and add a task after it" — is two
revisions: classify its first, say in one line that the rest is a separate
`/pipeline-revise` run, and carry on with the first. Say `Branch: <name>.` and
read that branch's file.

**4. Walk the impact.** From the anchor, along `graph.md`'s edges and no
other traversal, in the directions the branch file's *Impact walk* gives.
Index lines come first: every entry the walk reaches is named from an index
line. Bodies are opened within one scope, stated here and never widened:

- **the target artifact** — the anchored feature's `Doc:` document (with the
  `product-design.md` section its `Source:` names, when the change lands in a
  design decision), the anchored task's `.claude/tasks/<N>.md`, or the
  anchored runbook's body;
- **the tasks whose `Preconditions:` name it or whose `Files:` overlap** — for
  a task anchor, the tasks naming `<N>` and those sharing a path with its
  `Files:`; for a feature anchor, the same for each of its live task ids;
- **the runbook steps that name it** — each open runbook `graph.md` E7 names as
  a candidate, opened through E6 only to find the steps naming the anchor's
  slug or one of its task ids.

A body in that scope is opened only when an index line cannot answer what the
branch asks of it. When an arm runs, it reads what its own inputs name; that
read is the arm's, made after the gate, and is not this skill's.

**5. Lint — before.** Run `/pipeline-check` scoped to the anchor, before the
proposal is built, so the plan starts from the true state:

- `feature=<slug>` → `/pipeline-check feature=<slug>`;
- `task=<N>` → `/pipeline-check feature=<slug>` with the slug on the task's
  `Feature:` line when it resolves in `.claude/FEATURES.md`, otherwise
  `/pipeline-check` unscoped;
- `runbook=<name|id> step=<n>` → `/pipeline-check` unscoped — no index line
  ties a runbook to a slug, so the command has no runbook scope.

When `/pipeline-check` is not installed, evaluate
`${CLAUDE_HOME:-$HOME/.claude}/skills/pipeline-engine/references/lint.md`
directly over the indexes and keep the findings whose identifier is the anchor
or an entry the walk reached, rendered from their templates unchanged. Keep
the findings: step 9 compares against them.

**6. Propose.** Build the plan from the branch file: its owner sequence, the
tier its *Tier* section judges, and the sequence each gate answer leaves.
Before rendering it, every owner a step needs must be installed — read off the
verdict line's `installed` field, which names a missing pipeline feature under
`missing:`. A step whose owner is missing stops the run here, before the gate
and before any write:

> Can't revise: step <i> needs `<owner>`, which is not installed. Install it
> with `chosko-llm add`, then re-run.

**7. The gate.** This skill's one gate: one message, carrying —

1. the verdict line;
2. the anchor, the branch and the tier the branch judged —
   `Revise task=42 — insert, structural.`;
3. the touched artifacts — each entry the walk reached, with the edge or the
   body read that reached it — and, one line each, the entries examined and
   judged untouched, so a call can be overruled;
4. the owner steps, numbered, in order — each with its owner, the exact
   invocation or arm path, and what it will write — rendered as the sequence
   answer A leaves and the sequence answer B runs;
5. the lint — the findings step 5 reported in scope, and for each step which
   finding it is expected to clear or create;
6. the question:

> Is this change editorial — wording only, with nothing downstream changing
> meaning?
>
> A. **Editorial** — run <the steps A leaves>.
> B. **Not editorial, here** — run steps 1–<k> in this session, one at a time.
> C. **Not editorial, as a runbook** — hand steps 1–<k> to `/runbook-create`
>    and stop.
> D. **Stop** — write nothing.

The question is asked on every run, whatever the tier — never inferred,
classified or skipped. The tier decides how long the sequence is; it never
decides whether the question is asked.

Arm C is rendered only when B's sequence has **four or more** owner steps and
`/runbook-create` is installed — detected at run time from the verdict line's
`installed` field. When it is absent the arm is omitted silently, the same
optional delegation `/architect`'s council gate applies to an uninstalled
council: no mention, no install suggestion. Letter the arms in the order
rendered.

The user may overrule a touched/untouched call or the tier in the same answer;
re-render and ask again — the same gate, not a second one. Wait for an
explicit answer. Silence, an unclear reply or EOF is Stop.

**Exactly one gate is this skill's, and nothing is written before it** — by
this skill, or by any arm it drives, since no arm has run yet. The gates the
owners ask during actuation are theirs, kept intact; they are not gates of
this skill.

**8. Actuate.**

*In the session (A or B).* Run the steps one at a time, in order — never in
parallel, never in a subagent. Before each, one line:
`Step <i>/<k> — <owner>: <invocation>`. Each runs through its entry: an arm
executed from its file by path, or a command invoked as the user would invoke
it, with the flags COMMITTING forwards. The owner's own gate is asked exactly
as the owner asks it. After each, its closing line, as the owner writes it.

A later step that an earlier step's outcome made moot — an `/architect amend`
answered editorial leaves no stale task for a later step to amend — is
dropped with one line saying why. A step is never added after the gate; the
one alternative a branch file has the gate show beside a step is not an
addition.

*As a runbook (C).* Invoke `/runbook-create` with the owner steps as its
follow-up list, in order — each step's prompt self-contained: the invocation
or arm path, the anchor, the change and the decisions taken at this gate —
followed by one last step that runs step 9 of this workflow. Pass it the
flags COMMITTING forwards. `/runbook-create`'s own gate decides what is
written; this skill writes no line of the runbook. Then stop, reporting step
5's findings and the runbook `/runbook-create` created. Step 9 runs in that
runbook's last step, not here.

**9. Lint — after, and verify.** Run step 5's scoped `/pipeline-check` again
— also when the sequence stopped part-way, so the report shows the state it
left. Report the difference: findings cleared, findings created, findings
unchanged.

Where an insertion or a deletion changed a precondition, read the successor
tasks' bodies afterwards — the tasks whose `Preconditions:` gained or lost an
id — and confirm the sequence still reads as a sequence. The branch file's
*Verification* says when this applies. A successor that no longer reads as
one is reported with what does not follow; it is never fixed here — that is a
new revision.

**10. Report.**

```
Revised <anchor> — <branch>, <tier>, <A | B>: <run>/<k> owner steps run.
```

then each step's closing line, the lint difference
(`Lint: cleared <n> (<L-ids>), created <n> (<L-ids>), unchanged <n>.`), the
sequence check's result, and every follow-up an owner named —
`Reconcile with /task-add feature=<slug>.` among them. When anything was
written and `--commit` was not passed, end with an explicit reminder that
nothing was committed.

---

COMMITTING

`--commit` and `--no-push` are forwarded to each owner step and acted on by
that step, and nowhere else: this skill has no commit phase of its own and
never stages a path no owner step wrote.

| Owner step | Without `--commit` (the default) | With `--commit` |
| --- | --- | --- |
| An arm executed by path — `architect`'s `amend.md`, `task-engine`'s `references/amend.md`, `runbook-run`'s `references/step-amend.md` — each of which leaves its commit to whoever executes it | nothing is committed | the arm's closed write set, staged by explicit path and committed as that step's one unit of work, the arm's closing report line as the subject, per `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/commit.md` and its push protocol — pull-at-start included, the push skipped under `--no-push` |
| A command that commits nothing by default — `/product-design`, `/runbook-create --append`, `/production-plan` | no flag | `--commit`, plus `--no-push` when given |
| `/task-add`, which commits by default | `--no-commit` | no flag, plus `--no-push` when given |

---

WRITE SET

Closed, and empty: this skill writes no line any owner owns, and no file of
its own — no index line, no body, no runbook, no report on disk. Every write
in a run is an owner step's, through an arm or an owner command, after the
gate.

---

FAILURE CONTRACT

- **An anchor that resolves to nothing** stops by listing what exists (step 2).
  Nothing is written.
- **A step whose owner is not installed** stops before the gate (step 6).
  Nothing is written.
- **An owner that refuses** — a touched `[IN PROGRESS]` task, a `[DONE]` task,
  a position on a `[RUNNING]` runbook its arm will not take — or a user who
  answers stop at an owner's own gate, **stops the sequence at that step.**
  Earlier steps' writes stay intact and are reported, **never rolled back**;
  the steps not run are listed; step 9 still runs.
- **`/runbook-create` absent** removes arm C and says nothing.

---

DO NOT:
- Write anything yourself — not an index line, a body, a status, a
  `Context:` fact, a runbook or a report on disk. Every write goes through an
  arm or an owner command.
- Write, or let an arm write, anything before the gate. Ask a second gate of
  your own, or infer, classify, pre-answer or skip the editorial question.
- Read the backlog in bulk: open a body outside step 4's scope, open every
  task body, or open anything under `.claude/tasks/archive/`.
- Read a branch file before CLASSIFY has chosen it, or read a second one.
- Traverse the pipeline by anything but `graph.md`'s edges, or restate a
  probe, an edge, a finding or an arm's rule.
- Run owner steps in parallel or in subagents, reorder them, or add one after
  the gate.
- Write a runbook yourself, or hand the plan to `/runbook-create` unless the
  user chose C.
- Roll back an earlier step's writes when a later step fails.
- Delete, remove or renumber a task, a step or a feature entry; reopen or
  re-status `[DONE]` work.
- Commit anything but an owner step's own write set, or make a commit of your
  own.
- Introduce a status value or a change ledger. The outcomes are the owners'
  existing vocabularies.
