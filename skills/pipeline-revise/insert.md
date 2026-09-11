# Branch: insert — a new entry takes its place

Read this when `./SKILL.md`'s CLASSIFY chose insert. Together with
`./SKILL.md` it is the whole branch: a consumer that has read both can execute
an insert end to end. It writes nothing itself — every step below names the
primitive or arm it delegates to, by command name or by path.

This is the feature's motivating case: attach the task, place it, write back
the feature document, insert the runbook step, and confirm the lint is clean,
in one run.

---

## Applies when

A new task or a new runbook step is to exist at a position in its sequence —
together with the scope its feature document must newly promise, when it
must. Moving an entry that already exists is `./reorder.md`'s, and changing
one is `./amend.md`'s.

## Impact walk

Over `graph.md`'s edges, named by id.

- **Forward** — to the successor tasks whose `Preconditions:` must gain the
  new id (E4): the task the new one is placed before, and any task that must
  now wait on it. From those successors, on to the open runbooks whose steps
  run them (E7), where a step for the new task has to be inserted ahead of
  theirs.
- **Upward** — to the feature document that must promise the new scope (E3b,
  then E2). A task that belongs to no feature has no upward walk.

## Owner sequence

The composition, by primitive:

| Primitive | Does |
| --- | --- |
| `/task-add feature=<slug> --single` | attaches exactly one task to a `[PLANNED]` feature, with no reconciliation over its other tasks |
| `--before <N>` / `--after <N>` | places it — immediately above or below task N's block — and writes the edge together with the position |
| the orphan-task prompt | a free-form `/task-add` on a project with `.claude/FEATURES.md` asks whether the task belongs to a feature; `none` keeps a task that belongs to no feature free-form |
| `/runbook-create --append <name\|id> --before <n>` / `--after <n>` | inserts a step at that position under the next unused step id |

For the worked example — a task inserted after task N on a planned feature,
which a runbook runs — in order:

1. **The scope** — `/architect amend feature=<slug> "<the new scope>"`,
   executed from `${CLAUDE_HOME:-$HOME/.claude}/skills/architect/amend.md` by
   path, so the document promises the task before the task exists. Omitted
   when the document already promises it.
2. **The task** — `/task-add feature=<slug> --single --after <N> "<the task>"`,
   attaching and placing it under the id `Last task number:` + 1, which the
   gate shows.
3. **Each successor's `Preconditions:`** — through
   `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/amend.md`,
   one step per successor that must now wait on the new task. Under
   `--before <N>` task N needs no step: `/task-add` writes that edge with the
   placement.
4. **The runbook step** — `/runbook-create --append <name|id> --after <n>`
   (or `--before <n>`), the insert
   `${CLAUDE_HOME:-$HOME/.claude}/skills/runbook-run/references/step-amend.md`
   § *Insert* names, placed so the step running the new task sits ahead of the
   steps running its successors. A `[RUNNING]` runbook accepts inserts after
   the current step and nothing before it — `step-amend.md`'s rule, which this
   branch follows and does not own; a position it refuses stops the sequence
   here, per `./SKILL.md`'s failure contract.
5. **The scoped lint** — `./SKILL.md` step 9, which closes every run and is
   not an owner step.

A task that belongs to no feature has no step 1, and step 2 is a free-form
`/task-add --after <N> "<the task>"`, whose orphan prompt is answered `none`
at `/task-add`'s own gate. A runbook-only insert is step 4 alone.

**When step 1 leaves the feature `[ITERATED]`.** `--single` refuses an
`[ITERATED]` feature — `/task-add`'s FEATURE RESOLUTION step 5, its rule and
not this file's. So the gate shows step 2 in both forms: `--single` when
step 1 leaves the feature `[PLANNED]`, and `/task-add feature=<slug> --after
<N>` when step 1 leaves it `[ITERATED]` — the reconciliation run, the one
path back to `[PLANNED]`, with the drafts and the documentation task it adds
named. Step 1's outcome selects the form at actuation; the user saw both at
the gate.

## Tier

- **Structural** — the insert adds scope no existing task covers. Step 1
  runs, and flips the feature `[ITERATED]` through `/architect amend` — that
  arm's own scope call.
- **Local** — the insert is something the feature document already promises.
  No step 1; the feature's status is left alone, and step 2 is `--single`.

Under the gate's A, the sequence keeps only the step that writes the new entry
— step 2 with the edge its placement flag writes, or step 4 on a runbook-only
insert — and drops every step that changes another entry's meaning.

## Verification

A task insert always changes a precondition, so `./SKILL.md` step 9's
successor read always applies: after actuation, read the bodies of the new
task and of each successor whose `Preconditions:` gained its id, and confirm
the sequence still reads as a sequence — nothing a successor's body assumes is
missing from what the new task delivers, and the new task's body assumes
nothing a successor builds.

## Outcomes

No new status value. The new task arrives `[MISSING]` by `/task-add`'s rule
and the new step pending by `/runbook-create`'s; a feature step 1 moves goes
`[ITERATED]`, and a reconciliation run returns it to `[PLANNED]` — each the
owner's own write.

## Never

- Write anything itself, or write a successor's `Preconditions:` other than
  through step 3's arm or `/task-add`'s placement.
- Run `/task-add feature=<slug>` without `--single`, save the `[ITERATED]`
  form the gate showed beside it.
- Draft the task before `/architect amend` has written the scope it builds.
- Renumber an id, or move an existing task or step.
