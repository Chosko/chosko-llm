---
name: product-design
version: 0.6.1
type: skill
description: Brainstorm and design a product from the ground up with the user, producing high-level design documentation under .claude/domain/ — a product design doc whose features are described from the user-experience angle, a technical direction (stack, topology, data, hosting) that /architect adopts, plus an optional business model. Resumable across sessions: the state lives in design-process.md, not in conversation history, and every phase transition rewrites the stage marker before the phase ends. That state file shrinks rather than grows — every round that ends, the first completion and each later amendment alike, compresses it by deleting; once the process is complete a re-run also offers an amend path that edits a decision directly without re-running phases. Works greenfield or brownfield (detected by reading the repo). Its output is /architect's input. Requires /domain-setup to have run. At a genuine greenfield technical fork it offers to convene claude-council when that skill is installed, and is silent when it is not. Nothing is committed by default; pass --commit to commit and push exactly the documents written (--commit --no-push to skip the push).
---

# /product-design
# Global skill: design a product with the user, top-down, and write the
# result into the project's domain layer as high-level design
# documentation. Spans multiple sessions — the state is
# `.claude/domain/design-process.md`, so a later run resumes from what the
# document says, not from what anyone remembers.
# Usage: /product-design                    (leaves the documents uncommitted)
#        /product-design --commit           (commit and push the documents this run wrote)
#        /product-design --commit --no-push (commit locally, skip the push)
#        /product-design <free-form context about the product>

GOAL
Produce the high-level design of a product: what it is, who it is for, how
it is experienced, the big decisions behind it, and the set of high-level
features that make it up. Optionally, a business model alongside.

The output is documentation, in the project's domain layer:

```
.claude/domain/
  design-process.md          the state of this process — method, phases, stage marker
  product-design.md          the product design itself
  technical-direction.md     the product's technical foundations
  business-model.md          the business model (only when requested)
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
| `./document-templates.md` | PHASE 1, 3, 5, and 7, when stubbing or filling the documents. |
| `./business-model.md` | The user opted into business modelling — read before the business-model questions in PHASE 2 and before writing `business-model.md` in PHASE 3. |
| `./technical-direction.md` | Start of PHASE 6, and again before PHASE 7 writes `technical-direction.md`. |
| `./resuming.md` | PHASE 0 found an existing `.claude/domain/design-process.md`. |
| `./council-gate.md` | PHASE 6 reaches a genuine technical fork on the GREENFIELD branch — a real trade-off with nameable stakes, expensive to reverse once features are architected against it. Never on the brownfield branch, and never when the blocker is a missing fact. |

Do not read a supporting file speculatively. A greenfield first run with no
business modelling never touches `./business-model.md` or `./resuming.md`.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--commit` flag. If present, set
COMMIT = true and strip it; any remaining text is free-form context about
the product, to be folded into PHASE 1's orientation. `--commit` and
`--no-commit` are mutually exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`

Also scan for the optional `--no-push` flag and strip it. NO_PUSH only
matters when COMMIT is true: it skips the pull-at-start / re-sync / push
steps of the commit-and-push protocol (docs/authoring-guide.md) while
still committing as always.

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

If COMMIT is true and the project's CLAUDE.md does not carry a `## VCS`
override (non-git), pull at start per the commit-and-push protocol: run
`git pull` on the current branch. A conflict stops the run here — report
the conflict output and tell the user to resolve manually and re-run.

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
   - `.claude/domain/technical-direction.md` — stubbed sections, no invented
     content. Unconditional: PHASE 6 always runs, unlike business modelling.
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

**Sweep for uncaptured detail.** After the write-back above, before
rewriting the stage marker, re-read the documents you just wrote against
the PHASE 2 conversation and look for anything the interview surfaced that
no section covers: decisions, constraints, user or flow detail, rejected
alternatives, and terminology the user used. This is automatic — no new
question round, no new approval gate — you integrate directly into the
relevant document:

- WHAT/HOW detail (product behavior, user experience, flows, decisions
  already in scope for `product-design.md`) → the matching section of
  `product-design.md`.
- Business material → `business-model.md`, only when it exists.
- WHY, rationale, and rejected alternatives → `design-process.md`'s
  "Decisions worth keeping" section — this is where that register already
  lives (see `./document-templates.md`).

The same guards from the write-back above apply here: no technical or
implementation-level detail (a hard technical constraint the user stated
gets one line, as elsewhere), no high-level feature set, and never touch
`.claude/FEATURES.md`, `.claude/domain/features/`, or `.claude/TASKS.md`.
Add every path this step writes to `WRITTEN` — `design-process.md`
included, if the sweep adds rationale there.

If nothing is missing, say so and write nothing — do not restate what the
documents already say or manufacture content to fill the step.

Rewrite the stage marker before the phase ends, then report the sections
written by the write-back AND what the sweep integrated (or that nothing
was missing), and stop for the user.

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

Rewrite the stage marker before the phase ends, then report the sections
written and move on to PHASE 6 — the process is not complete yet; the
product's technical foundations have not been decided.

---

PHASE 6 — TECHNICAL DIRECTION

A third conversational round, in the same register as PHASE 4: contribute,
don't just extract answers. This phase always runs — every product has
technical foundations, and this is the one place the pipeline decides them
as a whole rather than feature-by-feature.

Start by reading back the feature set PHASE 4/5 produced. Name, in one or
two sentences, which features force which technical choices — a realtime
flow forces a transport decision, a document-heavy flow forces a storage
decision, and so on. This is what keeps the conversation grounded instead
of a generic stack pitch.

Read `./technical-direction.md` for the question bank / decision axes to
work through: stack, topology (monolith vs. services), data and storage,
async/queueing, hosting and deployment, inter-component protocols, and
cross-cutting concerns.

**Branch on greenfield vs. brownfield**, using PHASE 1's judgement:

- **Brownfield** — start from what exists. "Here's what I see you're built
  on — is this still the intent?" Only decide what is genuinely open;
  confirm-and-record rather than re-litigate what is already settled.
- **Greenfield** — propose candidates with trade-offs and a recommendation,
  the same discipline `skills/architect/tech-stack-selection.md` uses for a
  feature-level stack choice, but scoped to the whole product. On an axis
  that is a genuine fork — defensible candidates, nameable stakes, expensive
  to reverse once features are architected against it — read
  `./council-gate.md` and follow it before you recommend. It is silent and
  costs nothing when claude-council isn't installed.

The **user decides when this phase is done** — ask, and keep going until
they say so. Never advance on your own.

Rewrite the stage marker before the phase ends.

---

PHASE 7 — TECHNICAL WRITE-BACK

Fill `technical-direction.md` from PHASE 6. Read `./document-templates.md`
for the section-by-section shape, and `./technical-direction.md` again
before writing if the conversation ranged widely. This phase creates
nothing new — the document was already stubbed in PHASE 1 — and it does
not write `FEATURES.md` entries, anything under `.claude/domain/features/`,
or tasks.

**Register: documentational**, same discipline as PHASE 3: state the
decided direction, not the debate that produced it.

**Then compress `design-process.md`** — immediately before writing the
process-complete marker, not after. The round is over, so the scaffolding
it needed goes away: re-read the file and delete everything that does not
clear the "worth remembering" bar, per `./document-templates.md`'s "This
file shrinks; it does not grow". Concretely: **Current stage** back to one
or two sentences plus short per-document one-liners and a next step;
**Decisions worth keeping** back to a flat, undated bullet list of terse
one-line entries, with any superseded entry deleted rather than marked; no
dated sub-headers, no `[SUPERSEDED]` blocks, no closing-record essay, no
mid-round working notes. Deletion, not summarization into a ledger — the
decisions are already recorded in the other documents, and git history
holds the text that was cut.

Rewrite the stage marker to record that the process is complete, then give
the final report:

- Every document written or updated across the whole run, with its path.
- That `design-process.md` was compressed, and in one line what was cut.
- The confirmed high-level feature set, one line each.
- The technical direction, in summary — stack, topology, and any explicitly
  open decisions.
- The next step: `/architect <feature>` to turn one of them into a
  low-level feature document, and `/task-add feature=<slug>` after that.
- If the council was convened in PHASE 6: the question, the run SHA, the
  verdict, and the paths of the report and transcript it wrote, so the user
  can keep or delete them. Say nothing at all when it was not convened.
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

COMMIT AND PUSH (only when `--commit` was passed)

If COMMIT is false (the default), run no git/VCS command at all. The
documents are left uncommitted for the user to review — matching
`/domain-setup`, `/task-setup`, and `/context-build`.

If COMMIT is true, after the run's last phase completes (the pull-at-start
from PHASE 0 already ran):

1. If `WRITTEN` is empty, make no commit (and no push). Say so and stop.
2. Stage EXACTLY the paths in `WRITTEN` — the documents written plus the
   `.claude/domain/INDEX.md` rows — and commit once:

   ```
   git add -- <path1> <path2> ...
   git commit -m "Add product design documentation"
   ```

   Never use `git add -A`, `git add .`, or `git add -u`. On a non-git VCS,
   use the project's `## VCS` mapping in CLAUDE.md (git→`cm`).
3. On commit success, report the commit hash (`git rev-parse --short
   HEAD`). Then, unless NO_PUSH is true or the non-git VCS exemption
   applies, re-sync (`git pull`) and push per docs/authoring-guide.md's
   commit-and-push protocol.
4. On commit failure (e.g. a pre-commit hook rejects the commit): surface
   the exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.
5. On push failure (rejected, no upstream, no remote) or a pre-push
   conflict: surface the exact output. Never retry, never force-push. The
   commit exists locally; tell the user it needs a manual sync + push.

---

DO NOT:
- Write technical or implementation-level detail into `product-design.md`
  or `business-model.md` — components, data models, interfaces, libraries,
  file paths, code. That is `/architect`'s output (feature documents) and
  `/task-add`'s (tasks). Capture a hard technical constraint in one line if
  the user states one there; do not design against it in those two
  documents. `technical-direction.md` is the one document where stack,
  topology, and infrastructure detail belongs — that is PHASE 6/7's whole
  purpose.
- Create tasks or touch `.claude/TASKS.md` in any way.
- Write entries in `.claude/FEATURES.md` or documents under
  `.claude/domain/features/`. Both belong to `/architect`.
- Advance a phase without the user's explicit go-ahead. PHASE 2, PHASE 4,
  and PHASE 6 end when the user says they end — a council verdict is an
  input to that, never a substitute for it, however confident it came back.
- Add the report and transcript claude-council writes for itself
  (`council-report-*.html`, `council-transcript-*.md`) to `WRITTEN`, or stage
  them under `--commit`. They are the council's output, not this skill's.
  Name their paths in the final report and leave them in the working tree
  for the user to keep or delete.
- Offer the council gate on PHASE 6's brownfield branch, or write anything
  to the `design-process.md` stage marker when convening it. See
  `./council-gate.md`.
- Overwrite an existing domain document without explicit confirmation.
  Hand-written docs are canonical brownfield input — read them, build on
  them, never clobber them.
- End a phase without rewriting the stage marker.
- Let `design-process.md` grow across rounds — no dated revision headers,
  no `[SUPERSEDED]`-tagged text kept verbatim, no closing-record essay, no
  "Current stage" that reads as a changelog. A round that ends compresses
  the file by deleting; the amend path in `./resuming.md` does the same.
- Create `business-model.md` unless the user opted into business modelling.
- Run any git/VCS command unless `--commit` was passed; and with it, stage
  only the explicit `WRITTEN` paths, never a catch-all, push per the
  commit-and-push protocol unless `--no-push` was passed, and never
  force-push, retry a failed push, branch, tag, or use hook-skipping flags
  (`--no-verify`, `--no-gpg-sign`, `--amend`).
- Create the domain layer yourself when PHASE 0's gate fails. Point at
  `/domain-setup` and stop.
