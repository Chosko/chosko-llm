---
name: product-design
version: 0.1.0
type: skill
description: Brainstorm and design a product from the ground up with the user, producing high-level design documentation under .claude/domain/ — a product design doc whose features are described from the user-experience angle, plus an optional business model. Resumable across sessions: the state lives in design-process.md, not in conversation history, and every phase transition rewrites the stage marker before the phase ends. Works greenfield or brownfield (detected by reading the repo). Its output is /architect's input. Requires /domain-setup to have run. Nothing is committed by default; pass --commit to commit exactly the documents written.
---

# /product-design
# Global skill: design a product with the user, top-down, and write the
# result into the project's domain layer as high-level design
# documentation. Spans multiple sessions — the state is
# `.claude/domain/design-process.md`, so a later run resumes from what the
# document says, not from what anyone remembers.
# Usage: /product-design                    (leaves the documents uncommitted)
#        /product-design --commit           (commit the documents this run wrote)
#        /product-design <free-form context about the product>

GOAL
Produce the high-level design of a product: what it is, who it is for, how
it is experienced, the big decisions behind it, and the set of high-level
features that make it up. Optionally, a business model alongside.

The output is documentation, in the project's domain layer:

```
.claude/domain/
  design-process.md      the state of this process — method, phases, stage marker
  product-design.md      the product design itself
  business-model.md      the business model (only when requested)
```

This is stage 1 of the product pipeline. `/architect` consumes
`product-design.md` and turns one high-level feature into a low-level
feature document; `/task-add feature=<slug>` turns that into tasks. Read
[`.claude/domain/product-workflow.md`](../../.claude/domain/product-workflow.md)
in the target project if it has one — it is the contract for the whole
pipeline.

The design here is **high-level and user-facing**. Technical architecture,
component breakdowns, and file-level plans are `/architect`'s and
`/task-add`'s output, not this skill's.

$ARGUMENTS

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `./document-templates.md` | PHASE 1, when stubbing the documents, and again in PHASE 3 / PHASE 5 when filling them. |
| `./business-model.md` | The user opted into business modelling — read before the business-model questions in PHASE 2 and before writing `business-model.md` in PHASE 3. |
| `./resuming.md` | PHASE 0 found an existing `.claude/domain/design-process.md`. |

Do not read a supporting file speculatively. A greenfield first run with no
business modelling never touches `./business-model.md` or `./resuming.md`.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--commit` flag. If present, set
COMMIT = true and strip it; any remaining text is free-form context about
the product, to be folded into PHASE 1's orientation. `--commit` and
`--no-commit` are mutually exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`

There is no `resume` argument. Weeks pass between sessions and a flag would
not be remembered; `design-process.md` already exists and is the anchor.

Throughout the run, maintain a `WRITTEN` list of every path this invocation
wrote. It drives the final report and the optional commit.

---

PHASE 0 — GATE + RESUME

**Gate.** The domain layer must exist. Probe:

1. `.claude/domain/` — Glob it.
2. `.claude/domain/INDEX.md` — Read it.

If either is missing, stop:

> The domain knowledge layer hasn't been initialized in this project. Run
> `/domain-setup` first — it creates `.claude/domain/`, the domain
> `INDEX.md`, and `.claude/FEATURES.md`. Then re-run `/product-design`.

Do not proceed, and do not create the layer yourself. This rule has no
exceptions.

**Resume.** Probe `.claude/domain/design-process.md` with the Read tool.

- Not present → this is a first run. Continue to PHASE 1.
- Present → read `./resuming.md` and follow it. It reads the recorded
  stage, summarizes where the last session stopped, and asks whether to
  resume there or start fresh. Do not guess the stage from the other
  documents' contents; the marker is the state.

---

PHASE 1 — ORIENT + STUB

1. **Detect greenfield vs. brownfield.** Read, in this order, stopping as
   soon as you have a clear picture:
   - `CLAUDE.md` and `README.md`.
   - `.claude/context/INDEX.md` and the context files it lists, if a
     context layer exists — this is the cheapest route to what already
     exists.
   - Existing documents under `.claude/domain/`.
   - The source tree itself (Glob for the primary source directories), only
     if the above left the picture unclear.

   Brownfield means there is a product here already, in code or in docs.
   Greenfield means there is not. It is a spectrum — say which end you
   landed on and why, in one or two sentences, and let the user correct you.

2. **Ask about business modelling** — once, here:

   > Should this design include a business model (revenue, costs, segments,
   > pricing, go-to-market, unit economics, risks)? [y/N]

   Default no: the pipeline stays usable for internal tools and side
   projects. `business-model.md` is not created unless the answer is yes.

3. **Write the documents' initial state.** Read
   `./document-templates.md` and use the Write tool to create:
   - `.claude/domain/design-process.md` — the method, the phase list, and
     the stage marker, set to PHASE 1.
   - `.claude/domain/product-design.md` — stubbed sections, no invented
     content.
   - `.claude/domain/business-model.md` — ONLY if business modelling was
     requested in step 2.

   Never overwrite an existing document without explicit confirmation. If
   `product-design.md` already exists on a first run (hand-written, no
   `design-process.md` beside it), treat it as canonical brownfield input:
   read it, say you'll build on it, and extend it in place rather than
   replacing it.

4. **Register every created document in `.claude/domain/INDEX.md`** — one
   `| File | Covers |` row each, matching the table's existing shape. Leave
   every other row alone.

5. Rewrite the stage marker to record that PHASE 1 is complete, then report
   what you wrote and move on.

---

PHASE 2 — INTERVIEW

A conversation, not a form. Cover:

- **The product.** What it is, in one paragraph the user would recognize.
- **Target users.** Who they are and what they are doing when they reach
  for this.
- **User experience and key flows.** The two or three journeys that matter
  most, walked end to end.
- **The big design decisions.** The choices that shape everything
  downstream, and what was rejected.
- **The business model** — only when opted in. Read `./business-model.md`
  first and work through its question bank.

Two rules make this phase worth doing:

**Contribute, don't just ask.** Confirm what sounds right, suggest what
seems missing, warn about what looks contradictory or expensive, and offer
alternatives with a recommendation. A phase that only extracts answers
produces a document the user could have written alone.

**On brownfield, start from what exists.** The framing is "here's what I see
you've built — is this still the intent?", not "what do you want to build?".
Name the features you found and ask what has drifted.

Ask questions a few at a time and follow the thread the user pulls on. The
**user decides when this phase is done** — ask, and keep going until they
say so. Never advance on your own.

Before leaving the phase, rewrite the stage marker.

---

PHASE 3 — WRITE-BACK

Fill `product-design.md` — and `business-model.md`, when it exists — from
PHASE 2. Read `./document-templates.md` for the section-by-section shape.

**Register: documentational.** These documents state WHAT the product is
and, to a degree, HOW it works. They do not argue WHY: rationale lives in
the conversation and, where it must be durable, in `design-process.md`.
Write for a reader who joins the project in six months and needs the
current truth, not the debate that produced it.

Do not write the high-level feature set yet — that is PHASE 4 and 5.

Rewrite the stage marker before the phase ends, then report the sections
written and stop for the user.

---

PHASE 4 — HIGH-LEVEL FEATURES

A second conversational round, identifying the product's high-level
features. For each one:

- A name the user would use.
- What it does, from the user-experience angle, at medium-high detail —
  enough that `/architect` can start from it, and enough that the user can
  tell it apart from a neighbouring feature.
- Which user and which flow from PHASE 2 it serves.

**Stay out of technical territory.** No components, no data models, no
libraries, no file names, no APIs. If the user volunteers technical detail,
capture it as a constraint in one line and move the conversation back to
experience — `/architect` is where it belongs, and premature architecture
here gets copied forward as though it had been decided.

Aim for features that are separable — each one could be designed and built
without waiting on the others' internals. When two candidates cannot be
described independently, say so and propose either merging them or naming
the seam between them.

The user confirms when the set is complete. Ask; do not decide.

Rewrite the stage marker before the phase ends.

---

PHASE 5 — FEATURE WRITE-BACK

Record the confirmed feature set in `product-design.md`, in its
high-level-feature section, per `./document-templates.md`.

This phase writes **nothing else**. In particular it does not write
`.claude/FEATURES.md` entries and does not create anything under
`.claude/domain/features/` — both are `/architect`'s output, produced when
a feature is actually architected. Writing them here would create feature
entries with no feature documents behind them.

Rewrite the stage marker to record that the process is complete, then give
the final report:

- Every document written or updated, with its path.
- The confirmed high-level feature set, one line each.
- The next step: `/architect <feature>` to turn one of them into a
  low-level feature document, and `/task-add feature=<slug>` after that.
- If `WRITTEN` is non-empty and `--commit` was NOT passed, an explicit
  reminder that nothing was committed.

---

THE STAGE MARKER

`design-process.md` carries a current-stage marker. It is load-bearing:
every resume reads it and nothing else to decide where to pick up.

- Rewrite it at **every** phase transition, **before** the phase ends —
  not after the next one starts.
- A phase that ends without rewriting it degrades every later resume, and
  silently: the documents look finished while the marker points at the
  wrong place.
- When the user stops mid-phase, the marker still points at that phase.
  That is correct — `./resuming.md` handles a partially completed phase.

---

COMMIT (only when `--commit` was passed)

If COMMIT is false (the default), run no git/VCS command at all. The
documents are left uncommitted for the user to review — matching
`/domain-setup`, `/task-setup`, and `/context-build`.

If COMMIT is true, after the run's last phase completes:

1. If `WRITTEN` is empty, make no commit. Say so and stop.
2. Stage EXACTLY the paths in `WRITTEN` — the documents written plus the
   `.claude/domain/INDEX.md` rows — and commit once:

   ```
   git add -- <path1> <path2> ...
   git commit -m "Add product design documentation"
   ```

   Never use `git add -A`, `git add .`, or `git add -u`. On a non-git VCS,
   use the project's `## VCS` mapping in CLAUDE.md (git→`cm`).
3. On success, report the commit hash (`git rev-parse --short HEAD`).
4. On failure (e.g. a pre-commit hook rejects the commit): surface the
   exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.

---

DO NOT:
- Write technical or implementation-level detail into any document —
  components, data models, interfaces, libraries, file paths, code. That is
  `/architect`'s output (feature documents) and `/task-add`'s (tasks).
  Capture a hard technical constraint in one line if the user states one;
  do not design against it here.
- Create tasks or touch `.claude/TASKS.md` in any way.
- Write entries in `.claude/FEATURES.md` or documents under
  `.claude/domain/features/`. Both belong to `/architect`.
- Advance a phase without the user's explicit go-ahead. PHASE 2 and PHASE 4
  end when the user says they end.
- Overwrite an existing domain document without explicit confirmation.
  Hand-written docs are canonical brownfield input — read them, build on
  them, never clobber them.
- End a phase without rewriting the stage marker.
- Create `business-model.md` unless the user opted into business modelling.
- Run any git/VCS command unless `--commit` was passed; and with it, stage
  only the explicit `WRITTEN` paths, never a catch-all, and never push,
  branch, tag, or use hook-skipping flags (`--no-verify`, `--no-gpg-sign`,
  `--amend`).
- Create the domain layer yourself when PHASE 0's gate fails. Point at
  `/domain-setup` and stop.
