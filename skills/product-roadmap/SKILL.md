---
name: product-roadmap
version: 0.5.1
type: skill
description: Write the product's roadmap into .claude/domain/product-roadmap.md — ordered milestones, each with a goal, exit criteria, rationale and the scope slices it takes from each high-level feature. Use it once the design exists, or from a bare description, and re-run it to revise; stage 2 of the pipeline: turns the design into ordered milestones; its output is /architect's input.
requires: skill:interaction-engine
---

# /product-roadmap
# Global skill: decide, with the user, the order in which the product gets
# built, and write it down as `.claude/domain/product-roadmap.md` —
# milestones with goals and exit criteria, and the scope slices that say
# which share of each high-level feature a milestone takes on. Stage 2 of
# the pipeline: orders what `/product-design` described, ahead of
# `/architect`. Asks whether you already have an ordering in mind before
# drafting one, so a strategy you arrived with steers the roadmap instead of
# arguing with a draft, and records that premise in the document. Usable
# from a bare description when `product-design.md` doesn't exist yet, and
# re-runnable: the document is its own resume state. Reads
# `.claude/FEATURES.md` and never writes it, and carries no milestone status
# — that belongs to the plan. Requires `/domain-setup`. Commits and pushes
# exactly what the run wrote by default.
# Usage: /product-roadmap                        (read the design, draft or revise the roadmap)
#        /product-roadmap <free-form context>    (what the next release is about, constraints, deadlines)
#        /product-roadmap amend "<change>"       (one pinned change to named milestone lines, no conversation)
#        /product-roadmap --no-commit            (write the roadmap, run no git command)
#        /product-roadmap --no-push              (commit the roadmap, skip the push)
#        /product-roadmap <args> --attended | --unattended

GOAL
Produce an **ordered list of milestones**. Each one states the outcome it
delivers, what makes it shippable, why it comes where it does, and — the
load-bearing part — the *share* of each high-level feature it takes on.

- That share is a **scope slice**. A high-level feature is a design unit, not
  a scheduling unit: business strategy — MVP scoping, cost, timing — splits
  it across releases, not architecture. So `§ Authentication` may appear
  under an early milestone as "email and password only" and under a much
  later one as "third-party OAuth providers".
- Keep the register **product-level, not technical**: outcomes, criteria and
  scope, never components, data models, interfaces, libraries, file paths or
  code. Those belong to `/architect` and `/task-add`. If the user states a
  hard technical constraint, capture it in one line; designing against it is
  `/architect`'s job.
- Read [`.claude/domain/product-workflow.md`](../../.claude/domain/product-workflow.md)
  in the target project if it has one; this skill is a stage of the pipeline
  that document describes.

$ARGUMENTS

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `../interaction-engine/references/policy.md` | Every run, at ARGUMENT PARSING, to resolve the interaction policy. |
| `../interaction-engine/references/messages.md` | Every run, before the first question, gate or closing report — every one of them follows it. |
| `../interaction-engine/references/gates.md` | The policy resolved to `unattended`. |
| `./amend.md` | ARGUMENT PARSING recognised `amend "<change>"`. Read once the gate has passed; it carries the whole amend path and replaces every phase for the run. |

A full run reads nothing but `SKILL.md`; every full run needs the whole of it.

---

ARGUMENT PARSING

1. **`--no-commit`.** If present, set COMMIT = false and strip it; otherwise
   COMMIT = true — by default this skill commits and pushes what it wrote.
   `--no-commit` implies NO_PUSH: nothing is committed, so nothing is there
   to push.
   - `--commit` is still accepted and stripped; it is a silent no-op naming
     the default.
   - If both `--commit` and `--no-commit` appear, stop with:
     `--commit and --no-commit cannot be combined. Pick one.`
2. **`--no-push`.** Strip it if present. NO_PUSH matters only when COMMIT is
   true: skip the pull at start, the pre-push re-sync and the push, and still
   commit as always.
3. **`--attended` / `--unattended`.** Strip whichever appear. Resolve the
   run's interaction policy from them, a policy handed down by a parent run
   and the project's `CLAUDE.md`, per
   `../interaction-engine/references/policy.md`, which holds their argument
   errors.
   - Each gate carries its class tag
     (`../interaction-engine/references/gates.md`).
   - This skill cannot park: a run that stops on what waits — the steer
     question included — writes nothing.
4. **`amend`.** If what remains opens with the literal token `amend`
   followed by a quoted change, set AMEND = true; the change is the quoted
   string.
   - A missing change stops the run with
     `amend needs the change to make, e.g. /product-roadmap amend "m2-teams Exit criteria: drop the SSO bullet".`
   - Once the gate has passed and the pull-at-start has run, read
     `./amend.md` and follow it for the rest of the run. No phase runs; the
     run ends with COMMIT AND PUSH as any other does.
5. **Free-form context.** Otherwise, treat whatever remains as context about
   the release being planned — what the next milestone is meant to achieve,
   a constraint, a deadline, a feature the user wants pulled forward or
   pushed back. Fold it into PHASE 1; do not treat it as a command.
   - If it carries an **ordering** — a first release, a sequence, a "before"
     or "after", something explicitly deferred — the user's strategy has
     arrived up front. Set `STEER = given`, treat it as the seed PHASE 1
     drafts *from* (not as commentary on a draft you write anyway), and
     acknowledge it in the PHASE 0 summary before anything is drafted.
   - Otherwise leave `STEER` unset; PHASE 0 settles it.
6. **`WRITTEN`.** Maintain a list of every path this invocation writes. It
   drives the final report and the optional commit.

---

PHASE 0 — GATE + READ

1. **Gate.** The domain layer must exist. Probe `.claude/domain/` (Glob) and
   `.claude/domain/INDEX.md` (Read). If either is missing, stop:

   > The domain knowledge layer hasn't been initialized in this project. Run
   > `/domain-setup` first — it creates `.claude/domain/`, the domain
   > `INDEX.md`, and `.claude/FEATURES.md`. Then re-run `/product-roadmap`.

   Do not proceed and do not create the layer yourself. No exceptions.
2. **Pull at start.** If COMMIT is true and the project's CLAUDE.md does not
   carry a `## VCS` override (non-git), pull per the commit-and-push
   protocol: run `git pull` on the current branch. On a conflict, stop here:
   report the conflict output and tell the user to resolve manually and
   re-run.
3. **Read the inputs**, in this order:
   1. `.claude/domain/INDEX.md` — what domain knowledge exists.
   2. `.claude/domain/product-design.md`, **if present** — its high-level
      feature set and its section headings are the vocabulary `Covers:`
      entries are written in. If absent, do not stop: a roadmap can be
      drafted from a bare description, exactly as `/architect` can. Say in
      one line that you are working without it, and take the section names
      from the conversation instead.
   3. `.claude/domain/product-roadmap.md`, if present — the existing roadmap
      and the run's resume state: a re-run proposes changes *against* it,
      never from a blank page. There is no separate marker or state file;
      never create one.
   4. `.claude/FEATURES.md` — which sections have already been architected,
      and into which feature slugs. Read-only, always: never write a byte to
      it.
4. **Summarise** in two or three lines what you found — first run or
   revision, how many milestones exist today, whether `product-design.md` is
   present.
5. **Settle who proposes the order**, in the same message. Sequencing is the
   one input the documents cannot contain: it is business intent, and it
   lives with the user. A draft written before they speak can be well-built
   and still the wrong strategy, and both sides then argue against the draft
   instead of thinking from a blank page. Unless `STEER` is already settled,
   ask one short question and stop for the answer:

   > Do you have an ordering in mind? If not, I'll propose one.

   - Ask it as written, in two sentences: the first is the question, the
     second states the default without becoming a second thing to answer. Do
     not compress them into one either/or — a disjunction hands the reply two
     arms to mirror into answer options, and arms with different subjects
     ("*you* have an ordering" against "should *I* propose one") mirror into
     labels whose "I" means the user in one and you in the other.
   - Map the reply straight onto `STEER`: yes → `given`, no → `propose`.
   - Skip the question — never ask it as ceremony — when the answer is
     already in hand:
     - **`$ARGUMENTS` carried an ordering.** `STEER` is already `given`. Say
       back what you took the strategy to be, in a line or two, and let the
       user correct it.
     - **A revision with an existing roadmap.** The document is the strategy:
       `STEER = given`, seeded from what is there, and PHASE 1 discusses the
       delta as always. Ask only when the user's context signals a rethink
       rather than an increment.
   - The steer question is a question, not an approval: PHASE 1's
     confirmation is the one gate guarding a write.

---

PHASE 1 — THE ROADMAP CONVERSATION

Draft nothing until `STEER` is settled.

Run one conversational round, not a form. How it opens depends on `STEER`;
what it has to cover does not.

- **`STEER = propose`.** Draft first. Propose an ordering with reasons, name
  what you would defer and why, and flag a milestone that looks too big to
  ship. The user reacts to something concrete.
- **`STEER = given`.** Take the skeleton first — the milestone list, its
  rough order, and what the first release holds — then draft the rest *from*
  it: goals, exit criteria, rationale, and above all the scope slices. Never
  write a draft that ignores the user's ordering and reconcile with it
  afterwards. Ask only what the skeleton leaves open, each question carrying
  the answer you would pick and why, so it can be confirmed in a word.
- **Contribute, don't just ask.** This binds hardest on the `given` branch,
  where the pull is to become a stenographer. Taking the user's ordering
  does not suspend your judgement: still flag the milestone too big to ship,
  still name what you would defer and why, still refuse a slice with no
  exclusions in it, still say when the order fights a dependency. The
  ordering is the user's call; argue where you disagree, and make the case
  against it before they commit to it.

Cover, in whatever order the conversation wants:

1. **The milestones, their order, and the premise behind it.** What is the
   first shippable outcome, and what does each one after it unlock? Order is
   the product of value, risk and dependency — say which drives each
   placement. Settle too the **strategic premise** the whole sequence rests
   on: the bet, constraint or priority that explains why this order rather
   than another. On the `given` branch it is the user's, stated back in your
   own words for confirmation; on `propose` it is the argument your draft
   rests on, which you owe them out loud rather than leaving implicit across
   separate rationales. It goes in the document preamble. On a revision,
   start from the existing list and premise and discuss the delta.
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
7. **The sequencing questions you could not close.** Put them into the
   document; do not resolve them by guesswork.

**Three warnings, all non-blocking.** Raise each where it arises, in one or
two lines, and carry on. The only refusal in this skill is PHASE 0's gate.

- **A `Covers:` entry naming a section that `product-design.md` does not
  have.** Say so and proceed — a roadmap may legitimately run ahead of the
  design document. If `product-design.md` is absent entirely, this check
  does not apply: do not warn once per entry for a document that was never
  there.
- **Editing a slice whose section already has features in `.claude/FEATURES.md`.**
  Name the affected feature slugs, say that the design already downstream
  of that slice may no longer match it, and that the remedy is re-running
  `/architect <slug>`. Then proceed on the user's say-so. Never flip a
  feature's `Status:` — `[ITERATED]` is `/architect`'s field, and writing it
  from this skill would put two writers on one line.
- **A revision whose deltas contradict the recorded premise.** Name the
  contradiction and ask which one moves: the milestones, or the premise. Do
  not quietly restate the premise so the document agrees with its new order.

**Milestone identity.** Give each milestone a stable kebab-case slug,
e.g. `m1-mvp`, chosen once — never renamed, never renumbered, never reused
for a different milestone — the same rule task IDs and feature slugs
follow, because other documents reference it. **Order is list position in
the document**, not the slug: never encode order in a slug, so a milestone
inserted between two others needs no renumbering, and the numeral inside a
slug is decoration, not an index.

**Slice identity is the `(milestone, section)` pair.** Slices get no
identifier of their own: `m1-mvp § Authentication` is already unique and
already addressable. Do not invent a fourth identifier vocabulary beside
task IDs, feature slugs and milestone slugs.

**Gate.** The user confirms the roadmap — the milestone list, their order,
and the slices — before PHASE 2 writes anything. This is the run's one
approval gate, gate class `design`. Do not advance past PHASE 1 without it.

---

PHASE 2 — WRITE

The only phase that writes; write nothing before it. It writes exactly two
paths:

1. **`.claude/domain/product-roadmap.md`**, to the schema below. On a
   re-run, update it in place: keep the slugs, the wording that did not
   change, and the `Not now` entries that are still deferred.
2. **A row for it in `.claude/domain/INDEX.md`** — one `| File | Covers |`
   row matching the table's existing shape, added only if it is not already
   there. Leave every other row alone.

Add both to `WRITTEN`.

Never write anything else — in particular never `.claude/FEATURES.md`,
`.claude/PLAN.md`, `.claude/TASKS.md`, task bodies, `product-design.md`,
`technical-direction.md`, or anything under `.claude/domain/features/`. A
roadmap change that invalidates a design is reported, never applied.

### The document schema

````markdown
# Product roadmap

<One short paragraph: what this roadmap covers and what it is for. No dates,
no estimates, no status.>

Strategy: <one short paragraph — the premise the whole order rests on. The
bet, constraint or priority that explains why the milestones run in this
sequence rather than another. The user's strategy where they had one, your
own value/risk/dependency argument where they did not.>

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
  belongs to the plan — the same separation that keeps feature statuses out
  of `product-design.md`. Do not smuggle it in as prose like "(current)" or
  "(shipped)" either.
- **No dates, no estimates, no sizing, no velocity**, in any field or as
  prose. Record a date the user wants as an open sequencing question rather
  than a field. This binds the `Strategy:` paragraph as hard as anywhere
  else: a deadline that surfaces inside the premise becomes an open
  sequencing question too.
- **The preamble's `Strategy:` paragraph is global; `Rationale:` is local.**
  The premise explains why the sequence as a whole runs this way;
  `Rationale:` stays comparative — why *this* milestone before the next.
  State the premise once, above, not in every milestone.
- **On a revision the recorded premise is input, not output.** Read it
  before proposing any delta. Where the delta contradicts it, raise it in
  PHASE 1 (third warning) and let the user say which one moves. Never edit
  the premise so the document agrees with an order decided later in the same
  run: a premise that always agrees with the milestones records no reason.
- **`Covers:` entries name `product-design.md` sections, never
  `FEATURES.md` slugs**, so the roadmap stays writable before anything has
  been architected. Where no `product-design.md` exists, use the section
  name the conversation settled on, in the same `product-design.md § <X>`
  form, so it lines up the day that document appears.
- **Every `Covers:` entry carries a scope statement.** There is no
  "all of it" shorthand — it would reintroduce a completeness claim this
  schema has no way to check.
- Milestones appear in execution order, top to bottom, separated by `---`.

### What `Covers:` means

`Covers:` is **a decomposition instruction for `/architect`, not a delivery
claim.** It constrains how a section gets decomposed when it is architected;
it does not promise what ships.

So **partial coverage of a section across several milestones is the normal
case, not a defect.** Never check that a milestone's slices add up to a
whole section, that every section is covered somewhere, or that the exit
criteria are met by the slices listed. Compute no coverage report and store
none.

**Closing report.** State:

- The strategic premise recorded, and whether this run changed it.
- Every milestone, in order, with its slug and one-line goal.
- Every slice added, changed or removed in this run.
- Every warning raised in PHASE 1 — sections missing from
  `product-design.md`, and slices whose section already has features, with
  the affected slugs and the `/architect <slug>` remedy.
- Every open sequencing question recorded.
- The paths written (`WRITTEN`).
- The next step: `/architect <feature>` to design a milestone's slices.
- When `WRITTEN` is non-empty and `--no-commit` was passed: an explicit
  reminder that nothing was committed.

---

COMMIT AND PUSH (unless `--no-commit` was passed)

If COMMIT is false (`--no-commit` was passed), run no git/VCS command at
all. Leave the document uncommitted for the user to review.

If COMMIT is true (the default; the pull-at-start from PHASE 0 already
ran):

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
   re-sync with `git pull` immediately before pushing — other commits may
   have landed upstream during the run — then `git push`.
4. On commit failure (e.g. a pre-commit hook rejects the commit): surface
   the exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.
5. On push failure (rejected, no upstream, no remote) or a pre-push
   conflict: surface the exact output. Never retry, never force-push. The
   commit exists locally; tell the user it needs a manual sync + push.

Never branch, tag, force-push, retry a failed push, or use `--no-verify`,
`--no-gpg-sign` or `--amend`.
