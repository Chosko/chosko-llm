---
name: product-design
version: 0.9.1
type: skill
description: Design a product from the ground up with the user, writing the product design, the technical direction and an optional business model under .claude/domain/, resumable across sessions. Use it on a greenfield or brownfield product before anything is architected; stage 1 of the pipeline: turns a product idea into design documents; its output is /architect's input.
requires: skill:interaction-engine
---

# /product-design
# Global skill: design a product with the user, top-down, and write the
# result into the project's domain layer as high-level design
# documentation — a product design doc from the user-experience angle, a
# technical direction (stack, topology, data, hosting) that `/architect`
# adopts, plus an optional business model. Spans multiple sessions — the
# state is `.claude/domain/design-process.md`, so a later run resumes from
# what the document says, not from what anyone remembers; every phase
# transition rewrites its stage marker before the phase ends, the file
# shrinks rather than grows, and once the process is complete a re-run
# offers an amend path that edits a decision without re-running phases.
# Works greenfield or brownfield (detected by reading the repo). Requires
# `/domain-setup`. At a genuine greenfield technical fork offers to convene
# claude-council when that skill is installed, and is silent when it is not.
# Commits and pushes exactly the documents the run wrote by default.
# Usage: /product-design                    (commit and push the documents this run wrote)
#        /product-design --no-commit        (write the documents, run no git command)
#        /product-design --no-push          (commit the documents, skip the push)
#        /product-design <free-form context about the product>
#        /product-design amend "<change>"   (one pinned change to a finished design's documents, no phases)
#        /product-design <args> --attended | --unattended

GOAL
Produce the high-level design of a product — what it is, who it is for, how
it is experienced, the big decisions behind it, its high-level features —
and optionally a business model, as documentation in the project's domain
layer:

```
.claude/domain/
  design-process.md          the state of this process — method, phases, stage marker
  product-design.md          the product design itself
  technical-direction.md     the product's technical foundations
  business-model.md          the business model (only when requested)
```

- This is stage 1 of the product pipeline. `/architect` consumes
  `product-design.md` and turns one high-level feature into a low-level
  feature document; `/task-add feature=<slug>` turns that into tasks.
- Read [`.claude/domain/product-workflow.md`](../../.claude/domain/product-workflow.md)
  in the target project if it has one — it is the contract for the whole
  pipeline.
- Keep the design **high-level and user-facing**. Technical architecture,
  component breakdowns and file-level plans are `/architect`'s and
  `/task-add`'s output.

$ARGUMENTS

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `../interaction-engine/references/policy.md` | Every run, at ARGUMENT PARSING, to resolve the interaction policy. |
| `../interaction-engine/references/messages.md` | Every run, before the first question, gate or closing report — every one of them follows it. |
| `../interaction-engine/references/gates.md` | The policy resolved to `unattended`. |
| `./document-templates.md` | PHASE 1, 3, 5, and 7, when stubbing or filling the documents. |
| `./business-model.md` | The user opted into business modelling — read before the business-model questions in PHASE 2 and before writing `business-model.md` in PHASE 3. |
| `./technical-direction.md` | Start of PHASE 6, and again before PHASE 7 writes `technical-direction.md`. |
| `./resuming.md` | PHASE 0 found an existing `.claude/domain/design-process.md`. |
| `./amend.md` | ARGUMENT PARSING recognised `amend "<change>"`, or `./resuming.md`'s menu chose its amend arm. It carries the whole amend path and replaces every phase for the run. |
| `./council-gate.md` | PHASE 6 reaches a genuine technical fork on the GREENFIELD branch — a real trade-off with nameable stakes, expensive to reverse once features are architected against it. Never on the brownfield branch, and never when the blocker is a missing fact. |

Do not read a supporting file speculatively. A greenfield first run with no
business modelling never touches `./business-model.md` or `./resuming.md`.

---

ARGUMENT PARSING

1. **`--no-commit`** — if present, set COMMIT = false and strip it;
   otherwise COMMIT = true (the default: commit and push what the run
   wrote). `--no-commit` implies NO_PUSH. `--commit` is accepted, stripped,
   and a silent no-op. If both appear, stop with:
   `--commit and --no-commit cannot be combined. Pick one.`
2. **`--no-push`** — strip it and set NO_PUSH. It matters only when COMMIT
   is true: skip the pull at start, the pre-push re-sync and the push, and
   still commit.
3. **`--attended` / `--unattended`** — strip whichever appear. Resolve the
   run's interaction policy from them, a policy handed down by a parent run
   and the project's `CLAUDE.md`, per
   `../interaction-engine/references/policy.md`, which holds their argument
   errors. Each gate carries its class tag
   (`../interaction-engine/references/gates.md`). This skill cannot park:
   when the run stops on what waits, rewrite the stage marker first, so the
   next session resumes there.
4. **`amend "<change>"`** — if the remaining text opens with the literal
   token `amend` followed by a quoted change, set AMEND = true; the change is
   the quoted string. A missing change stops the run with
   `amend needs the change to make, e.g. /product-design amend "Authentication: drop the SSO provider".`
   Once PHASE 0's gate has passed and the pull-at-start has run, read
   `./amend.md` and follow it for the rest of the run — skip PHASE 0's
   resume probe and every phase — and end with COMMIT AND PUSH as any other
   run does.
5. Fold any remaining text into PHASE 1's orientation as free-form context
   about the product.

There is no `resume` argument: `design-process.md` is the anchor.

Throughout the run, maintain a `WRITTEN` list of every path this invocation
wrote. It drives the final report and the commit.

---

PHASE 0 — GATE + RESUME

1. **Gate.** Glob `.claude/domain/` and Read `.claude/domain/INDEX.md`. If
   either is missing, stop — no exceptions, and do not create the layer
   yourself:

   > The domain knowledge layer hasn't been initialized in this project. Run
   > `/domain-setup` first — it creates `.claude/domain/`, the domain
   > `INDEX.md`, and `.claude/FEATURES.md`. Then re-run `/product-design`.

2. **Pull.** If COMMIT is true and the project's CLAUDE.md carries no
   `## VCS` override (non-git), run `git pull` on the current branch per the
   commit-and-push protocol. On a conflict, stop: report the conflict output
   and tell the user to resolve manually and re-run.
3. **Resume.** Probe `.claude/domain/design-process.md` with the Read tool.
   - Not present → first run; continue to PHASE 1.
   - Present → read `./resuming.md` and follow it: it reads the recorded
     stage, summarizes where the last session stopped, and asks whether to
     resume there or start fresh. Never guess the stage
     from the other documents' contents; the marker is the state.

---

PHASE 1 — ORIENT + STUB

1. **Detect greenfield vs. brownfield.** Read, in this order, stopping as
   soon as the picture is clear:
   - `CLAUDE.md` and `README.md`.
   - `.claude/context/INDEX.md` and the context files it lists, if a
     context layer exists — the cheapest route to what already exists.
   - Existing documents under `.claude/domain/`.
   - The source tree (Glob for the primary source directories), only if the
     above left the picture unclear.

   Brownfield means a product exists here already, in code or in docs;
   greenfield means it does not. It is a spectrum — say which end you landed
   on and why, in one or two sentences, and let the user correct you.

2. **Ask about business modelling** — once, here:

   > Should this design include a business model (revenue, costs, segments,
   > pricing, go-to-market, unit economics, risks)? [y/N]

   Default no.

3. **Write the documents' initial state.** Read `./document-templates.md`
   and use the Write tool to create:
   - `.claude/domain/design-process.md` — the method, the phase list, and
     the stage marker, set to PHASE 1.
   - `.claude/domain/product-design.md` — stubbed sections, no invented
     content.
   - `.claude/domain/technical-direction.md` — stubbed sections, no invented
     content. Always: PHASE 6 always runs.
   - `.claude/domain/business-model.md` — ONLY if the answer in step 2 was
     yes.

   Overwriting an existing document needs explicit confirmation — gate
   class `design` (the run-wide rule is in DO NOT). If
   `product-design.md` already exists on a first run (hand-written, no
   `design-process.md` beside it), say you'll build on it and extend it in
   place.

4. **Register every created document in `.claude/domain/INDEX.md`** — one
   `| File | Covers |` row each, matching the table's existing shape. Leave
   every other row alone.

5. Rewrite the stage marker to record PHASE 1 complete, report what you
   wrote, and move on.

---

PHASE 2 — INTERVIEW

Hold a conversation, not a form. Cover:

- **The product.** What it is, in one paragraph the user would recognize.
- **Target users.** Who they are and what they are doing when they reach
  for this.
- **User experience and key flows.** The two or three journeys that matter
  most, walked end to end.
- **The big design decisions.** The choices that shape everything
  downstream, and what was rejected.
- **The business model** — only when opted in. Read `./business-model.md`
  first and work through its question bank.

Rules:

- **Contribute, don't just ask.** Confirm what sounds right, suggest what
  seems missing, warn about what looks contradictory or expensive, and offer
  alternatives with a recommendation.
- **On brownfield, start from what exists.** Frame it as "here's what I see
  you've built — is this still the intent?", not "what do you want to
  build?". Name the features you found and ask what has drifted.
- Ask questions a few at a time and follow the thread the user pulls on.
- The **user decides when this phase is done** (gate class `design`) — ask,
  and keep going until they say so. Never advance on your own.
- Rewrite the stage marker before leaving the phase.

---

PHASE 3 — WRITE-BACK

1. Fill `product-design.md` — and `business-model.md`, when it exists — from
   PHASE 2. Read `./document-templates.md` for the section-by-section shape.
   - **Register: documentational.** State WHAT the product is and, to a
     degree, HOW it works. Do not argue WHY: rationale lives in the
     conversation and, where it must be durable, in `design-process.md`.
     Write for a reader who joins in six months and needs the current
     truth, not the debate.
   - Do not write the high-level feature set yet — that is PHASE 4 and 5.
   - The DO NOT rules below on technical detail, `.claude/FEATURES.md`,
     `.claude/domain/features/` and `.claude/TASKS.md` apply.
2. **Sweep for uncaptured detail.** Before rewriting the stage marker,
   re-read the documents you just wrote against the PHASE 2 conversation and
   find anything the interview surfaced that no section covers: decisions,
   constraints, user or flow detail, rejected alternatives, and terminology
   the user used. Integrate it directly — no new question round, no new
   approval gate:
   - WHAT/HOW detail (product behavior, user experience, flows, decisions
     already in scope for `product-design.md`) → the matching section of
     `product-design.md`.
   - Business material → `business-model.md`, only when it exists.
   - WHY, rationale, and rejected alternatives → `design-process.md`'s
     "Decisions worth keeping" section (see `./document-templates.md`).

   The step-1 guards apply. Add every path the sweep writes to `WRITTEN` —
   `design-process.md` included, if it adds rationale there. If nothing is
   missing, say so and write nothing — do not restate the documents or
   manufacture content.
3. Rewrite the stage marker, then report the sections the write-back wrote
   AND what the sweep integrated (or that nothing was missing), and stop for
   the user.

---

PHASE 4 — HIGH-LEVEL FEATURES

Run a second conversational round to identify the product's high-level
features. For each one, capture:

- A name the user would use.
- What it does, from the user-experience angle, at medium-high detail —
  enough that `/architect` can start from it, and enough that the user can
  tell it apart from a neighbouring feature.
- Which user and which flow from PHASE 2 it serves.

Rules:

- **Stay out of technical territory.** No components, no data models, no
  libraries, no file names, no APIs. If the user volunteers technical
  detail, capture it as a constraint in one line and move the conversation
  back to experience — premature architecture here gets copied forward as
  though it had been decided.
- Aim for separable features — each one designable and buildable without
  waiting on the others' internals. When two candidates cannot be described
  independently, say so and propose either merging them or naming the seam
  between them.
- The user confirms when the set is complete. Ask; do not decide. Gate
  class: `design`.
- Rewrite the stage marker before the phase ends.

---

PHASE 5 — FEATURE WRITE-BACK

1. Record the confirmed feature set in `product-design.md`'s
   high-level-feature section, per `./document-templates.md`.
2. Write **nothing else** — in particular no `.claude/FEATURES.md` entries
   and nothing under `.claude/domain/features/`; both are `/architect`'s
   output, produced when a feature is actually architected.
3. Rewrite the stage marker, report the sections written, and move on to
   PHASE 6 — the process is not complete until the technical foundations
   are decided.

---

PHASE 6 — TECHNICAL DIRECTION

Run a third conversational round, in the same register as PHASE 4:
contribute, don't just extract answers. This phase always runs — it is the
one place the pipeline decides technical foundations for the whole product
rather than feature-by-feature.

1. Read back the feature set PHASE 4/5 produced. Name, in one or two
   sentences, which features force which technical choices — a realtime
   flow forces a transport decision, a document-heavy flow forces a storage
   decision, and so on.
2. Read `./technical-direction.md` for the question bank / decision axes:
   stack, topology (monolith vs. services), data and storage,
   async/queueing, hosting and deployment, inter-component protocols, and
   cross-cutting concerns.
3. **Branch on greenfield vs. brownfield**, using PHASE 1's judgement:
   - **Brownfield** — start from what exists: "Here's what I see you're
     built on — is this still the intent?" Decide only what is genuinely
     open; confirm-and-record rather than re-litigate what is settled.
     Never offer the council gate here.
   - **Greenfield** — propose candidates with trade-offs and a
     recommendation, the same discipline
     `skills/architect/tech-stack-selection.md` uses for a feature-level
     stack choice, scoped to the whole product. On an axis that is a genuine
     fork — defensible candidates, nameable stakes, expensive to reverse
     once features are architected against it — read `./council-gate.md`
     and follow it before you recommend. It is silent and costs nothing when
     claude-council isn't installed. Write nothing to the `design-process.md`
     stage marker when convening it.
4. The **user decides when this phase is done** — ask, and keep going until
   they say so. Never advance on your own. A council verdict is an input to
   that decision, never a substitute for it, however confident it came back.
5. Rewrite the stage marker before the phase ends.

---

PHASE 7 — TECHNICAL WRITE-BACK

1. Fill `technical-direction.md` from PHASE 6. Read
   `./document-templates.md` for the section-by-section shape, and
   `./technical-direction.md` again before writing if the conversation
   ranged widely.
   - **Register: documentational**, as in PHASE 3: state the decided
     direction, not the debate.
   - Create nothing new (PHASE 1 stubbed the document), and write no
     `FEATURES.md` entries, nothing under `.claude/domain/features/`, no
     tasks.
2. **Compress `design-process.md`** — immediately before writing the
   process-complete marker, not after. Re-read the file and delete
   everything that does not clear the "worth remembering" bar, per
   `./document-templates.md`'s "This file shrinks; it does not grow":
   - **Current stage** → one or two sentences plus short per-document
     one-liners and a next step.
   - **Decisions worth keeping** → a flat, undated bullet list of terse
     one-line entries; delete any superseded entry rather than marking it.
   - No dated sub-headers, no `[SUPERSEDED]` blocks, no closing-record
     essay, no mid-round working notes.
   - Delete; do not summarize into a ledger — the decisions are recorded in
     the other documents, and git history holds the cut text.
3. Rewrite the stage marker to record the process complete, then give the
   final report:
   - Every document written or updated across the whole run, with its path.
   - That `design-process.md` was compressed, and in one line what was cut.
   - The confirmed high-level feature set, one line each.
   - The technical direction, in summary — stack, topology, and any
     explicitly open decisions.
   - The next step: `/architect <feature>` to turn one of them into a
     low-level feature document, and `/task-add feature=<slug>` after that.
   - If the council was convened in PHASE 6: the question, the run SHA, the
     verdict, and the paths of the report and transcript it wrote, so the
     user can keep or delete them. Say nothing at all when it was not
     convened.
   - If `WRITTEN` is non-empty and `--no-commit` was passed, an explicit
     reminder that nothing was committed.

---

THE STAGE MARKER

`design-process.md` carries a current-stage marker. Every resume reads it
and nothing else to decide where to pick up.

- Rewrite it at **every** phase transition, **before** the phase ends — not
  after the next one starts. A phase that ends without rewriting it
  silently misleads every later resume: the documents look finished while
  the marker points at the wrong place.
- When the user stops mid-phase, leave the marker pointing at that phase;
  `./resuming.md` handles a partially completed phase.

---

COMMIT AND PUSH (unless `--no-commit` was passed)

If COMMIT is false (`--no-commit` was passed), run no git/VCS command at
all; leave the documents uncommitted for the user to review.

If COMMIT is true (the default), after the run's last phase completes (the
pull-at-start from PHASE 0 already ran):

1. If `WRITTEN` is empty, make no commit (and no push). Say so and stop.
2. Stage EXACTLY the paths in `WRITTEN` — the documents written plus the
   `.claude/domain/INDEX.md` rows — and commit once:

   ```
   git add -- <path1> <path2> ...
   git commit -m "Add product design documentation"
   ```

   - Never add the report and transcript claude-council writes for itself
     (`council-report-*.html`, `council-transcript-*.md`) to `WRITTEN`, or
     stage them at all — they are the council's output; leave them in the
     working tree.
   - On a non-git VCS, use the project's `## VCS` mapping in CLAUDE.md
     (git→`cm`).
3. On commit success, report the commit hash (`git rev-parse --short
   HEAD`). Then, unless NO_PUSH is true or the non-git VCS exemption
   applies, re-sync with `git pull` immediately before pushing — other
   commits may have landed upstream during the run — then `git push`.
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
  `/task-add`'s (tasks). Capture a hard technical constraint the user states
  there in one line; do not design against it in those two documents.
  `technical-direction.md` is the one document where stack, topology, and
  infrastructure detail belongs.
- Create tasks or touch `.claude/TASKS.md` in any way.
- Write entries in `.claude/FEATURES.md` or documents under
  `.claude/domain/features/`. Both belong to `/architect`.
- Overwrite an existing domain document without explicit confirmation,
  anywhere in the run. Hand-written docs are canonical brownfield input —
  read them, build on them, never clobber them.
- Stage anything but the explicit `WRITTEN` paths — never a catch-all
  (`git add -A`, `git add .`, `git add -u`).
- Force-push, retry a failed push, branch, tag, or use `--no-verify`,
  `--no-gpg-sign` or `--amend`.
