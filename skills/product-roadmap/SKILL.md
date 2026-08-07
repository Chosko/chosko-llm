---
name: product-roadmap
version: 0.1.0
type: skill
description: Write the product's roadmap into .claude/domain/product-roadmap.md — an ordered list of milestones, each with a goal, exit criteria, rationale, and the scope slices saying which share of a high-level feature it takes on. The product-level WHEN of the pipeline, sitting between /product-design and /architect. Usable from a bare description when product-design.md doesn't exist yet, and re-runnable: the document is its own resume state, so a later run proposes changes against what is already there. Reads .claude/FEATURES.md and never writes it, and carries no milestone status — that belongs to the plan, not the roadmap. Requires /domain-setup. Nothing committed by default; pass --commit to commit and push exactly what the run wrote (--commit --no-push to skip the push).
---

# /product-roadmap
# Global skill: decide, with the user, the order in which the product gets
# built, and write it down as `.claude/domain/product-roadmap.md` —
# milestones with goals and exit criteria, and the scope slices that say
# which share of each high-level feature a milestone takes on. Sits between
# `/product-design` (what to build) and `/architect` (how to build it), and
# supplies the WHEN neither of them covers.
# Usage: /product-roadmap                        (read the design, draft or revise the roadmap)
#        /product-roadmap <free-form context>    (what the next release is about, constraints, deadlines)
#        /product-roadmap --commit               (commit and push exactly what this run wrote)
#        /product-roadmap --commit --no-push     (commit locally, skip the push)

GOAL
Produce an **ordered list of milestones**. Each one states the outcome it
delivers, what makes it shippable, why it comes where it does, and — the
load-bearing part — the *share* of each high-level feature it takes on.

That share is a **scope slice**. A high-level feature is a design unit, not
a scheduling unit: the axis that splits it across releases is business
strategy — MVP scoping, cost, timing — not architecture. So
`§ Authentication` may appear under an early milestone as "email and
password only" and under a much later one as "third-party OAuth providers".

The register is **product-level, not technical**: outcomes, criteria and
scope, never components, data models or file paths. Those belong to
`/architect` and `/task-add`.

Read [`.claude/domain/product-workflow.md`](../../.claude/domain/product-workflow.md)
in the target project if it has one; this skill is a stage of the pipeline
that document describes.

$ARGUMENTS

---

SUPPORTING FILES

None. This skill ships `SKILL.md` and nothing else: it is one document with
one schema, and every run needs the whole of it, so there is no cheap path a
split would protect.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--commit` flag. If present, set
COMMIT = true and strip it. `--commit` and `--no-commit` are mutually
exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`

Also scan for the optional `--no-push` flag and strip it. NO_PUSH only
matters when COMMIT is true: it skips the pull-at-start / re-sync / push
steps of the commit-and-push protocol (docs/authoring-guide.md) while still
committing as always.

Whatever remains is free-form context about the release being planned —
what the next milestone is meant to achieve, a constraint, a deadline, a
feature the user wants pulled forward or pushed back. Fold it into PHASE 1
rather than treating it as a command.

Maintain a `WRITTEN` list of every path this invocation wrote. It drives the
final report and the optional commit.

---

PHASE 0 — GATE + READ

**Gate.** The domain layer must exist. Probe `.claude/domain/` (Glob) and
`.claude/domain/INDEX.md` (Read). If either is missing, stop:

> The domain knowledge layer hasn't been initialized in this project. Run
> `/domain-setup` first — it creates `.claude/domain/`, the domain
> `INDEX.md`, and `.claude/FEATURES.md`. Then re-run `/product-roadmap`.

Do not proceed and do not create the layer yourself. No exceptions.

If COMMIT is true and the project's CLAUDE.md does not carry a `## VCS`
override (non-git), pull at start per the commit-and-push protocol: run
`git pull` on the current branch. A conflict stops the run here — report the
conflict output and tell the user to resolve manually and re-run.

**Read the inputs**, in this order:

1. `.claude/domain/INDEX.md` — what domain knowledge exists.
2. `.claude/domain/product-design.md`, **if present** — its high-level
   feature set and its section headings are the vocabulary `Covers:` entries
   are written in. Absent is fine, and not a reason to stop: a roadmap can
   be drafted from a bare description, exactly as `/architect` can. Say in
   one line that you are working without it, and take the section names from
   the conversation instead.
3. `.claude/domain/product-roadmap.md`, if present — the existing roadmap.
   This is the run's resume state: a re-run proposes changes *against* it,
   never from a blank page. There is no separate marker or state file.
4. `.claude/FEATURES.md` — which sections have already been architected, and
   into which feature slugs. Read-only, always: this skill never writes a
   byte to it.

Say in two or three lines what you found — first run or revision, how many
milestones exist today, whether `product-design.md` is present — then
continue.

---

PHASE 1 — THE ROADMAP CONVERSATION

One conversational round, not a form. Contribute rather than only extract:
propose an ordering with reasons, name what you would defer and why, and
flag a milestone that looks too big to ship.

Cover, in whatever order the conversation wants:

1. **The milestones and their order.** What is the first shippable outcome,
   and what does each one after it unlock? Order is the product of value,
   risk and dependency — say which is driving each placement. On a revision,
   start from the existing list and discuss the delta.
2. **Per milestone: the goal**, stated as an *outcome* a user or the
   business gets, never as a feature list.
3. **Per milestone: exit criteria** — what has to be true for it to be
   shippable. Concrete enough to be judged by reading, since nothing
   validates them mechanically.
4. **Per milestone: rationale** — why this one before the next.
5. **Per milestone: the scope slices.** For each high-level feature the
   milestone takes a share of, write a prose scope statement whose real
   payload is its **exclusions**. "Email and password only. No third-party
   providers, no SSO, no reset-by-SMS" is a slice; "authentication" is not.
   Push back on a slice with no exclusions in it: either the milestone
   genuinely takes the whole section, in which case say what "the whole
   thing" means, or the scope has not been decided yet.
6. **What is deliberately not now**, each with the trigger that would pull
   it back in — a user count, a customer request, a cost threshold, a date.
   Deferral without a trigger is just an omission.
7. **The sequencing questions you could not close.** They go into the
   document rather than being resolved by guesswork.

**Two warnings, both non-blocking.** Raise them where they arise, in one or
two lines each, and carry on:

- **A `Covers:` entry naming a section that `product-design.md` does not
  have.** Say so and proceed. A roadmap may legitimately run ahead of the
  design document, and refusing here would make the skill unusable on a
  project that has no design document at all. If `product-design.md` is
  absent entirely, this check simply does not apply — do not warn once per
  entry for a document that was never there.
- **Editing a slice whose section already has features in `.claude/FEATURES.md`.**
  Name the affected feature slugs and say that the design already downstream
  of that slice may no longer match it, and that the remedy is re-running
  `/architect <slug>`. Then proceed on the user's say-so. Nothing here flips
  a feature's `Status:` — `[ITERATED]` is `/architect`'s field, and writing
  it from this skill would put two writers on one line.

**Milestone identity.** Each milestone gets a stable kebab-case slug,
e.g. `m1-mvp`, chosen once and never renamed and never renumbered — the same
rule task IDs and feature slugs follow, and for the same reason: other
documents reference it. **Order is list position in the document**, not the
slug, so a milestone inserted between two others needs no renumbering and
the numeral inside a slug is decoration, not an index.

**Slice identity is the `(milestone, section)` pair.** Slices get no
identifier of their own: `m1-mvp § Authentication` is already unique and
already addressable. Do not invent a fourth identifier vocabulary beside
task IDs, feature slugs and milestone slugs.

The user confirms the roadmap — the milestone list, their order, and the
slices — before PHASE 2 writes anything. This is the run's one approval
gate.

---

PHASE 2 — WRITE

The only phase that writes. It writes exactly two paths:

1. **`.claude/domain/product-roadmap.md`**, to the schema below. On a
   re-run, update it in place: keep the slugs, the wording that did not
   change, and the `Not now` entries that are still deferred.
2. **A row for it in `.claude/domain/INDEX.md`** — one `| File | Covers |`
   row matching the table's existing shape, added only if it is not already
   there. Leave every other row alone.

Add both to `WRITTEN`.

### The document schema

````markdown
# Product roadmap

<One short paragraph: what this roadmap covers and what it is for. No dates,
no estimates, no status.>

---

## m1-<slug> — <one-line milestone title>

Goal: <the outcome this milestone delivers, as an outcome and not a feature
list. One or two sentences.>

Exit criteria:
- <what has to be true for this to be shippable>
- <one per line>

Rationale: <why this milestone comes before the next one — the value, risk
or dependency argument that puts it here.>

Covers:
- product-design.md § <Section> — <prose scope statement. What is in, and,
  more importantly, what is deliberately out.>
- product-design.md § <Section> — <…>

---

## m2-<slug> — <one-line milestone title>

…

---

## Not now

- <deferred item> — <the trigger that would pull it back in.>
- <deferred item> — <…>

## Open sequencing questions

- <a sequencing question this roadmap could not close.>
````

Rules the schema is not free to bend:

- **No `Status:` line anywhere in the document**, on a milestone or
  otherwise. Which milestone is active and which have shipped is state, and
  it belongs to the plan rather than the roadmap — the same separation that
  keeps feature statuses out of `product-design.md`. Do not add the field,
  and do not smuggle it in as prose like "(current)" or "(shipped)".
- **No dates, no estimates, no sizing, no velocity.** If the user wants a
  date, record it as an open sequencing question rather than a field.
- **`Covers:` entries name `product-design.md` sections, never
  `FEATURES.md` slugs.** The roadmap must stay writable before anything has
  been architected. Where no `product-design.md` exists, use the section
  name the conversation settled on, in the same `product-design.md § <X>`
  form, so it lines up the day that document appears.
- **Every `Covers:` entry carries a scope statement.** There is no
  "all of it" shorthand — it would reintroduce a completeness claim this
  schema deliberately has no way to check.
- Milestones appear in execution order, top to bottom, separated by `---`.

### What `Covers:` means

`Covers:` is **a decomposition instruction for `/architect`, not a delivery
claim.** It constrains how a section gets decomposed when it is architected;
it does not promise what ships. That is what lets the roadmap be
load-bearing without being a claim anything has to validate against.

The consequence: **partial coverage of a section across several milestones
is the normal case, not a defect.** Nothing in this skill checks that a
milestone's slices add up to a whole section, that every section is covered
somewhere, or that the exit criteria are met by the slices listed. No
coverage report is computed and none is stored.

**Closing report.** State:

- Every milestone, in order, with its slug and one-line goal.
- Every slice added, changed or removed in this run.
- Every warning raised in PHASE 1 — sections missing from
  `product-design.md`, and slices whose section already has features, with
  the affected slugs and the `/architect <slug>` remedy.
- Every open sequencing question recorded.
- The paths written (`WRITTEN`).
- The next step: `/architect <feature>` to design a milestone's slices.
- When `WRITTEN` is non-empty and `--commit` was not passed: an explicit
  reminder that nothing was committed.

---

COMMIT AND PUSH (only when `--commit` was passed)

If COMMIT is false (the default), run no git/VCS command at all. The
document is left uncommitted for the user to review — matching
`/product-design`, `/architect`, and `/domain-setup`.

If COMMIT is true (the pull-at-start from PHASE 0 already ran):

1. If `WRITTEN` is empty — the conversation ended without an approved
   roadmap, or a re-run changed nothing — make no commit and no push. Say
   so and stop.
2. Stage EXACTLY the paths in `WRITTEN` — `.claude/domain/product-roadmap.md`
   and `.claude/domain/INDEX.md` — and commit once:

   ```
   git add -- <path1> <path2>
   git commit -m "Update the product roadmap"
   ```

   Never use `git add -A`, `git add .`, or `git add -u`. On a non-git VCS,
   use the project's `## VCS` mapping in CLAUDE.md (git→`cm`).
3. On commit success, report the commit hash (`git rev-parse --short HEAD`).
   Then, unless NO_PUSH is true or the non-git VCS exemption applies,
   re-sync (`git pull`) and push per docs/authoring-guide.md's
   commit-and-push protocol.
4. On commit failure (e.g. a pre-commit hook rejects the commit): surface
   the exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.
5. On push failure (rejected, no upstream, no remote) or a pre-push
   conflict: surface the exact output. Never retry, never force-push. The
   commit exists locally; tell the user it needs a manual sync + push.

---

DO NOT:
- Write anything before PHASE 2, or write anything in PHASE 2 other than
  `.claude/domain/product-roadmap.md` and its `.claude/domain/INDEX.md` row.
  In particular never write `.claude/FEATURES.md`, `.claude/PLAN.md`,
  `.claude/TASKS.md`, task bodies, `product-design.md`,
  `technical-direction.md`, or anything under `.claude/domain/features/`.
  A roadmap change that invalidates a design is reported, never applied.
- Write a `Status:` line, a date, an estimate, or a size anywhere in the
  roadmap — in any field or as prose. Milestone state belongs to the plan.
- Write a `Covers:` entry with no scope statement, or one naming a
  `FEATURES.md` slug instead of a `product-design.md` section.
- Refuse over a `Covers:` entry whose section is missing from
  `product-design.md`, or over a slice whose section already has features.
  Both are warnings. The only refusal in this skill is PHASE 0's gate.
- Rename or renumber a milestone slug, or reuse one for a different
  milestone. Slugs are stable identifiers, like task IDs and feature slugs.
- Encode order in the slugs. Order is list position; a milestone inserted
  between two others must never force a renumber.
- Invent an identifier for a slice. Its identity is the
  `(milestone, section)` pair.
- Create a separate marker or state file to resume from. The document is the
  state.
- Descend into technical territory — components, data models, interfaces,
  libraries, file paths, code. Capture a hard technical constraint in one
  line if the user states one; designing against it is `/architect`'s job.
- Advance past PHASE 1 without the user confirming the roadmap. There is
  exactly one approval gate and this is it.
- Run any git/VCS command unless `--commit` was passed; and with it, stage
  only the explicit `WRITTEN` paths, never a catch-all, push per the
  commit-and-push protocol unless `--no-push` was passed, and never
  force-push, retry a failed push, branch, tag, or use hook-skipping flags
  (`--no-verify`, `--no-gpg-sign`, `--amend`).
- Create the domain layer yourself when PHASE 0's gate fails. Point at
  `/domain-setup` and stop.
