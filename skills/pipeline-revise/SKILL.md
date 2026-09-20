---
name: pipeline-revise
version: 0.6.2
type: skill
description: Revise already-planned work — change, insert into, remove from or reorder a feature document, a task or a runbook step — through the owners of every artifact the change reaches, behind one gate. Use it for a change that crosses owners or restructures the plan; for one owner's amend arm, /pipeline-patch is cheaper.
requires: skill:pipeline-engine, skill:architect, skill:task-engine, skill:runbook-run
---

# /pipeline-revise
# Global skill: carry one described change to already-planned work through
# every artifact it reaches — feature documents, tasks, plan edges, runbook
# steps — by walking the impact, proposing a tiered plan behind one gate, and
# running each owner's own amend arm or command in order. Writes nothing itself.
# Probes, resolves the anchor (or one the change names), classifies the
# request into exactly one branch — amend, insert, delete or reorder — and
# reads only that branch's file; walks the impact both ways over the index
# graph, opening bodies only within the anchor's scope; runs /pipeline-check
# on the anchor before the proposal and after actuation. The proposal names
# its tier — editorial, local or structural — the artifacts, the owner steps
# and the lint findings it creates or clears, with one Classified: evidence
# line; insert, delete and reorder are never editorial. The gate asks only
# when something is open: a borderline editorial call, or the here-versus-
# runbook choice. Three or fewer owner steps run in the session, one at a
# time, each with its owner's gate intact; at four or more the gate also
# offers to hand the plan to /runbook-create when installed. Removal is
# [SKIP] or a struck step, never physical deletion. Commits and pushes by
# default — every owner step runs uncommitted and one commit at the end holds
# the whole revision; a sequence that stops part-way commits nothing.
# Usage: /pipeline-revise [<anchor>] "<change>" [--no-commit] [--no-push]
#        anchor: feature=<slug> | task=<N> | runbook=<id|name|id-name> step=<n>
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

- `../pipeline-engine/references/probes.md`
  — the probe, its verdict line and the reuse rule;
- `../pipeline-engine/references/graph.md`
  — the edges between the indexes, and **the impact walk's only traversal
  input**;
- `../pipeline-engine/references/routing.md`
  — which owner each line belongs to, and, in its Amend column, the entry a
  revision routes through;
- `../pipeline-engine/references/lint.md`
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

Scan `$ARGUMENTS` for the optional `--no-commit` flag (COMMIT = false), the
optional `--no-push` flag (NO_PUSH = true) and the optional `--commit` flag,
and strip all three. COMMIT is true unless `--no-commit` is passed;
`--no-commit` implies NO_PUSH. `--commit` is accepted and changes nothing —
COMMIT is already true. `--commit` and `--no-commit` together stop the run
with: `--commit and --no-commit cannot be combined. Pick one.` What each flag
does is COMMITTING.

Then scan for an anchor in exactly one of three forms, and strip it:

- `feature=<slug>`
- `task=<N>`
- `runbook=<id|name|id-name> step=<n>`

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
  `../task-engine/references/resolution.md`
  § *The archive*; one above it was never assigned. Either way there is no live
  task to revise: stop, say which, and list the live tasks, id and title.
- `runbook=<id|name|id-name> step=<n>` — the runbook resolved by
  `../runbook-run/references/runbook-schema.md`
  § *Resolving a runbook argument* — id, name or `<id>-<name>`; one that does
  not resolve stops listing the runbooks in `.claude/RUNBOOKS.md`. The step by id in its body — the anchor's target
  artifact, read here; an unknown id stops listing the runbook's steps, id,
  marker and title, in list order.

With no anchor, look in the change for exactly one of: a slug on
`.claude/FEATURES.md`, a task id that has a summary block, or a runbook name
or id together with a step id. One → that is the anchor, stated in one line
(`Anchor: task=42 — named in the change.`) and resolved as above. None, or
more than one → stop, naming the three anchor forms and listing what was
found — or, when nothing was, the features, the live tasks and the runbooks
that exist. Never pick between two.

Given an anchor, a change that also names artifacts under a different anchor —
a task of another feature, say — is scoped to the resolved anchor: say in one
line that the rest is a separate `/pipeline-revise` run, the same shape as
step 3's two-kinds rule, and carry on with the anchor.

**Pull at start.** Once the anchor resolves, and before the walk, pull once
for the whole run per COMMITTING — skipped under `--no-commit` or
`--no-push`.

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
- `runbook=<id|name|id-name> step=<n>` → `/pipeline-check` unscoped — no index line
  ties a runbook to a slug, so the command has no runbook scope.

When `/pipeline-check` is not installed, evaluate
`../pipeline-engine/references/lint.md`
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
6. the classification — a `Classified:` line, or the question — and, when
   still open, the reply the gate waits for, by the rules below.

**Classified, or asked.** Whether the change is editorial is settled without
a reply whenever a mechanical signal decides it, and asked only when none
does:

- **insert, delete, reorder** — never editorial, for the reason the branch
  file's *Tier* gives, and never asked:
  `Classified: not editorial — <branch>: <the new, removed or moved entry>`.
- **amend**, over the findings `./amend.md` § *Tier* judges:
  - a `Preconditions:` edge added or dropped, a `Files:` change or a scope
    change → `Classified: not editorial — <the edge, the Files: line or the scope item>`;
  - all three of that section's editorial conditions hold →
    `Classified: editorial — only <anchored artifact> is touched`;
  - anything else — a borderline wording-versus-meaning amend — is asked.

A `Classified:` line cites only what item 3 lists, never an adjective. The
tier decides how long the sequence is; the classification decides which
sequence runs — editorial the one step that writes the anchored artifact, not
editorial the judged tier's.

**The gate waits for a reply only when something is still open**: the
editorial question, on an ambiguous amend; or the here-versus-runbook choice,
when arm C is rendered. With neither open, it renders items 1–5 and the
`Classified:` line and goes straight to step 8 — the user's description of the
change is authorisation enough when the evidence settles the tier.

The question, when the editorial call is open:

> Is this change editorial — wording only, with nothing downstream changing
> meaning?
>
> <evidence line>
>
> A. **Editorial** — run <the steps A leaves>.
> B. **Not editorial, here** — run steps 1–<k> in this session, one at a time.
> C. **Not editorial, as a runbook** — hand steps 1–<k> to `/runbook-create`
>    and stop.
> D. **Stop** — write nothing.

The choice, when the change is classified not editorial and arm C is
rendered:

> Classified: not editorial — <evidence>
>
> A. **Here** — run steps 1–<k> in this session, one at a time.
> B. **As a runbook** — hand steps 1–<k> to `/runbook-create` and stop.
> C. **Stop** — write nothing.

Throughout this skill, "arm C" names the runbook answer, whichever letter it
carries. A change classified editorial never reaches the choice: its sequence
is one step, below arm C's threshold.

**The judged tier is the recommendation.** When the question is asked, the
gate marks one letter, taken from the tier item 2 already renders, and adds no
concept of its own:

- tier **editorial** → mark **A**;
- tier **local** or **structural** → mark **B**.

The evidence line above the letters cites only what item 3 already lists — the
touched artifacts, by id, and the edge or reason that made the tier — never an
adjective:

- A marked: `Recommended: A — editorial: only <anchored artifact> is touched;
  A and B run the identical sequence here.` A judged editorial tier makes A's
  and B's sequences identical, so the line says so; both letters are still
  offered, so the tier can be overruled.
- B marked: `Recommended: B — <local | structural>: <touched artifacts, or the
  reason the branch file gives>`.

The marked letter is a recommendation, not an answer: the reply still has to
name a letter, and nothing is written on it alone. An overruled tier or
touched/untouched call re-applies the rules above when the gate re-renders:
a change that is now classified, with arm C not rendered, goes to step 8
without another prompt; otherwise the marked letter is re-derived and the gate
asks again.

Arm C is rendered only when B's sequence has **four or more** owner steps and
`/runbook-create` is installed — detected at run time from the verdict line's
`installed` field. When it is absent the arm is omitted silently, the same
optional delegation `/architect`'s council gate applies to an uninstalled
council: no mention, no install suggestion. Letter the arms in the order
rendered.

Whenever the gate asks, the user may overrule a touched/untouched call or the
tier in the same answer; re-render per the paragraph above — the same gate,
not a second one. Wait for an explicit answer. Silence, an unclear reply or
EOF is Stop, whichever letter is marked.

**Exactly one gate is this skill's, and nothing is written before it** — by
this skill, or by any arm it drives, since no arm has run yet. The gates the
owners ask during actuation are theirs, kept intact; they are not gates of
this skill.

**8. Actuate.**

*In the session (editorial, or not editorial here).* Run the steps one at a time, in order — never in
parallel, never in a subagent. Before each, one line:
`Step <i>/<k> — <owner>: <invocation>`. Each runs through its entry: an arm
executed from its file by path, or a command invoked as the user would invoke
it, without committing, per COMMITTING. The owner's own gate is asked exactly
as the owner asks it. After each, its closing line, as the owner writes it.

An `/architect amend` step — in whichever branch runs one — receives the
editorial classification step 7 settled: the user's reply when the question
was asked (A as *editorial*, B, or arm C, as *not editorial*), the automatic
classification otherwise — never the letter the gate marked. The arm applies
it with no prompt when its own findings agree, and asks in its confirmation
form, needing an explicit reply, when they disagree (`architect/amend.md`
§ 4). No other owner receives it.

A later step that an earlier step's outcome made moot — an `/architect amend`
answered editorial leaves no stale task for a later step to amend — is
dropped with one line saying why. A step is never added after the gate; the
one alternative a branch file has the gate show beside a step is not an
addition.

*As a runbook (arm C).* Invoke `/runbook-create` with the owner steps as its
follow-up list, in order — each step's prompt self-contained: the invocation
or arm path, the anchor, the change and the decisions taken at this gate —
followed by one last step that runs step 9 of this workflow. Pass it
`--no-commit`, per COMMITTING. `/runbook-create`'s own gate decides what is
written; this skill writes no line of the runbook. Then make the revision's
one commit — the runbook body and `.claude/RUNBOOKS.md` — and stop, reporting
step 5's findings and the runbook `/runbook-create` created. Step 9 runs in
that runbook's last step, not here.

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

**10. Commit.** When the sequence completed — a step dropped as moot under
step 8 still counts as completed — and at least one step wrote, make the
revision's one commit and push, per COMMITTING, the report line below as the
subject. A sequence that stopped part-way, a run that wrote nothing, or
`--no-commit` makes no commit.

**11. Report.**

```
Revised <anchor> — <branch>, <tier>, <editorial | not editorial>: <run>/<k> owner steps run.
```

then each step's closing line, the lint difference
(`Lint: cleared <n> (<L-ids>), created <n> (<L-ids>), unchanged <n>.`), the
sequence check's result, and every follow-up an owner named —
`Reconcile with /task-add feature=<slug>.` among them, save for a feature
whose `/task-add feature=<slug>` reconciliation ran as a step of this
sequence; when the sequence stopped before that step, the follow-up still
appears. Then the commit hash. When anything was written and no commit was
made — `--no-commit`, or a sequence that stopped part-way — list every path
written so far and end with an explicit reminder that nothing was committed.

---

COMMITTING

This skill owns the run's commit. A revision is one unit of work, so it lands
as exactly one commit, made at the end — never one per owner step. Commit and
push gating is
`../task-engine/references/commit.md`.

- **Pull at start** — once per run, after the anchor resolves and before the
  walk (WORKFLOW step 2), unless `--no-commit` or `--no-push`. A conflict
  stops the run there, nothing written.
- **Every owner step runs uncommitted.** A command owner — `/task-add`,
  `/product-design`, `/production-plan`, `/runbook-create` (`--append`
  included), `/architect` — always receives `--no-commit`, whatever its own
  default. An arm executed by path — `architect`'s `amend.md`, `task-engine`'s
  `references/amend.md`, `runbook-run`'s `references/step-amend.md` — is
  executed with no commit. No owner step pulls or pushes.
- **One commit.** After the last step and the closing check (step 9), stage
  exactly the union of the paths the owner steps reported writing, by
  explicit path, and commit once, the `Revised <anchor> — <branch>, <tier>`
  report line as the subject. Then re-sync and push per `commit.md`'s push
  protocol, the push skipped under `--no-push`. Report the hash.
- **Arm C follows the same rule.** `/runbook-create` runs with `--no-commit`,
  and the runbook body and `.claude/RUNBOOKS.md` it wrote are the revision's
  one commit.
- **No commit** on a stop before the gate, gate answer D, a sequence that
  stops part-way (an owner refuses, or its gate is answered stop), a run that
  wrote nothing, or `--no-commit`. A partial sequence is left uncommitted on
  purpose: every commit holds a complete revision, and step 9 already reports
  the state the stopped sequence left. Under `--no-commit` nothing touches
  git; otherwise only the pull at start does on those paths.

---

WRITE SET

Closed, and empty: this skill writes no line any owner owns, and no file of
its own — no index line, no body, no runbook, no report on disk. Every write
in a run is an owner step's, through an arm or an owner command, after the
gate. Its commit stages only those writes, and never stages a path no owner
step wrote.

---

FAILURE CONTRACT

- **An anchor that resolves to nothing** stops by listing what exists (step 2).
  Nothing is written.
- **A step whose owner is not installed** stops before the gate (step 6).
  Nothing is written.
- **An owner that refuses** — a touched `[IN PROGRESS]` task, a `[DONE]` task,
  a position on a `[RUNNING]` runbook its arm will not take — or a user who
  answers stop at an owner's own gate, **stops the sequence at that step.**
  Earlier steps' writes stay intact, uncommitted, and are reported path by
  path, **never rolled back**; the steps not run are listed; step 9 still
  runs; nothing is committed.
- **`/runbook-create` absent** removes arm C and says nothing.

---

DO NOT:
- Write anything yourself — not an index line, a body, a status, a
  `Context:` fact, a runbook or a report on disk. Every write goes through an
  arm or an owner command.
- Write, or let an arm write, anything before the gate. Ask a second gate of
  your own; ask the editorial question when step 7's rules classify the
  change, or classify it without asking when they leave it open; wait for a
  reply when nothing is open; or treat the letter the gate marks as the
  answer — the recommendation is shown for an explicit reply, and nothing is
  written on it alone. Carrying the settled classification — the user's reply,
  or step 7's automatic one — into an `/architect amend` step (step 8) is not
  pre-answering; carrying the recommendation is.
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
- Stage a path no owner step wrote; let an owner step commit, pull or push;
  make more than one commit; or commit a sequence that stopped part-way, or
  anything under `--no-commit`.
- Introduce a status value or a change ledger. The outcomes are the owners'
  existing vocabularies.
