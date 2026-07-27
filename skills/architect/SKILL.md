---
name: architect
version: 0.2.0
type: skill
description: Turn one or more high-level features into low-level feature documents under .claude/domain/features/, indexed in .claude/FEATURES.md — the bridge between /product-design and /task-add. Grounds the architecture in the project's recorded technical-direction.md or existing code, or proposes a tech stack when there is neither. Runs from a product-design section, named features, or a bare prompt with no design documents at all. Re-architecting a feature that already has tasks triggers an iterate guard: refuses outright while any task is [IN PROGRESS], otherwise asks, then flips surviving tasks to [STALE] and the feature to [ITERATED]. Requires /domain-setup. Nothing committed by default; pass --commit to commit exactly the written paths.
---

# /architect
# Global skill: design the implementation architecture of one or more
# features and write it down as low-level feature documentation under
# `.claude/domain/features/`, indexed in `.claude/FEATURES.md`. Stage 2 of
# the product pipeline: consumes a high-level feature (or a bare prompt) and
# produces the document `/task-add feature=<slug>` turns into tasks.
# Usage: /architect                        (read product-design.md, ask which feature)
#        /architect <feature name> [...]   (architect the named feature(s))
#        /architect <free-form description of what to build>
#        /architect <args> --commit        (commit exactly what this run wrote)

GOAL
Take what a feature must do and decide how it will be built, grounded in the
code that already exists — or, on a greenfield project, in a tech stack
chosen with the user. Write the result as technical documentation of
**low-level features**: one document per separately designable unit.

One high-level feature may produce several low-level ones. That is normal,
not a sign of over-decomposition: "accounts" as a product feature routinely
becomes authentication, session handling, and profile management as
architecture.

The output level is **mid-to-high technical**: components and their
responsibilities, data and state, interfaces and contracts, dependencies.
No real code and no file-by-file plans — those are `/task-add`'s output,
produced at planning time against the codebase as it then stands.

Read [`.claude/domain/product-workflow.md`](../../.claude/domain/product-workflow.md)
in the target project if it has one; this skill is its main implementation.

$ARGUMENTS

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `./iterating.md` | PHASE 0 finds the target feature already has a `FEATURES.md` entry. Read before PHASE 0b. |
| `./tech-stack-selection.md` | The project has NO existing tech stack AND no `technical-direction.md` (greenfield). Read at the start of PHASE 2. |
| `./feature-doc-template.md` | PHASE 3, always — the feature-document schema and the `FEATURES.md` entry format. |

Do not read a supporting file speculatively. The common path — a brownfield
project, a feature architected for the first time — reads only
`./feature-doc-template.md`.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--commit` flag. If present, set
COMMIT = true and strip it. `--commit` and `--no-commit` are mutually
exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`

What remains is the input, resolved in PHASE 0. It is one of:

- **Empty** — read `product-design.md` and ask which feature(s) to
  architect.
- **One or more feature names** — matched against `product-design.md`'s
  high-level features and against existing `FEATURES.md` slugs.
- **A free-form description** — architect that, with no design documents
  required. This is the path on a project that has code but has never run
  `/product-design`.

Maintain a `WRITTEN` list of every path this invocation wrote. It drives the
final report and the optional commit.

---

PHASE 0 — GATE + INPUT

**Gate.** The domain layer must exist. Probe `.claude/domain/` (Glob) and
`.claude/domain/INDEX.md` (Read). If either is missing, stop:

> The domain knowledge layer hasn't been initialized in this project. Run
> `/domain-setup` first — it creates `.claude/domain/`, the domain
> `INDEX.md`, and `.claude/FEATURES.md`. Then re-run `/architect`.

Do not proceed and do not create the layer yourself. No exceptions.

**Read the inputs**, in this order, stopping when you have what you need:

1. `.claude/domain/INDEX.md` — what domain knowledge exists.
2. `.claude/domain/product-design.md`, if present — the high-level features
   and the decisions above them. Absent is fine: architect from the prompt.
3. `.claude/domain/technical-direction.md`, if present — the product's
   recorded technical foundations: stack, topology, data, hosting,
   protocols. Absent is fine: fall back to reading the stack off the code,
   or to `./tech-stack-selection.md` on a genuinely greenfield project.
4. `.claude/FEATURES.md` — existing features, their statuses, their `Tasks:`
   lines.
5. `.claude/context/INDEX.md` and the context files relevant to the area
   under design, if a context layer exists. This is the cheapest route to
   the existing architecture — prefer it to reading source.
6. Source files, only where the context layer is thin or absent and the
   design genuinely depends on how something currently works.

**Resolve the target feature(s).** With no argument, list
`product-design.md`'s high-level features and ask which to architect. With
names, match them; when a name matches nothing, say so and ask rather than
guessing. Confirm the resolved list back to the user in one line before
continuing.

**Detect whether a stack exists.** A present `technical-direction.md` counts
as a stack that exists, exactly like an established codebase stack — note
this and move on. Otherwise, note from what you read whether this project
already has a technology stack (language, framework, storage, delivery).
Either way, this decides whether PHASE 2 reads `./tech-stack-selection.md`:
it does not, whenever a stack already exists in either form.

**Check for existing entries.** For each target feature, look for a
`FEATURES.md` entry. If any target already has one, read `./iterating.md`
and continue to PHASE 0b. If none do, skip PHASE 0b entirely.

---

PHASE 0b — ITERATE GUARD (only when a target feature already has an entry)

Follow `./iterating.md`, which carries the full protocol. In summary, per
existing target feature:

1. Read the entry's `Tasks:` IDs; look each up in `.claude/TASKS.md`.
2. **Any `[IN PROGRESS]` task → REFUSE.** Report the task ID and title and
   stop the run. There is no override and no flag: an implementation is
   underway against the current design, and changing it underneath corrupts
   both the task and the feature.
3. **Any other non-`[DONE]` task → ask.** List them with statuses and
   titles, state that re-architecting may invalidate them, and offer stop or
   proceed.
4. **On proceed** — flip every non-`[DONE]` task to `[STALE]` in
   `.claude/TASKS.md` and set the feature `[PLANNED]` → `[ITERATED]`.
5. **No tasks at all** (`Tasks: none`, or a `[NEW]` feature) → skip the
   guard; the status stays as it is. A feature already `[ITERATED]` stays
   `[ITERATED]`.
6. **IDs that resolve to no task** are ignored, not an error — a
   hand-edited backlog must not break the run.

`[DONE]` tasks are never touched, whatever the design does afterwards.

This is the only circumstance in which this skill writes to
`.claude/TASKS.md`, and it writes nothing but `Status:` lines.

---

PHASE 1 — CLARIFY (skipped when everything is clear)

Ask only what you cannot resolve from the design documents and the codebase.
Cap it at a handful of focused questions, each with the answer you'd pick and
why, so the user can confirm in a word.

If there are no open questions, say so in one line — "The feature is
unambiguous as described; no questions." — and go straight to PHASE 2. Do
not manufacture questions to fill the phase.

When the feature came from `product-design.md` and an answer changes what
that document says, write the answer back into `product-design.md` in
PHASE 3. Clarifications belong upstream too; otherwise the next reader asks
the same question.

---

PHASE 2 — ARCHITECT (conversational)

**2a. Tech stack — only when the project has no existing stack.** Read
`./tech-stack-selection.md` and follow it: propose candidate stacks with
their trade-offs, tie each back to the product design, recommend one, and
let the user choose. Skip this step entirely whenever a stack already
exists — a recorded `technical-direction.md`, or an established codebase
stack — and adopt what is there. Say in one line that you are doing so.

**2b. Architecture.** Work top-down, conversationally. When
`technical-direction.md` exists, design within it and say so in one line,
naming the document ("Designing within the recorded technical direction —
see technical-direction.md"). Treat it exactly as an existing codebase
stack: adopted, not re-argued. If the feature genuinely doesn't fit what it
records, flag the mismatch once as a concern, then design around it anyway
— never silently override the direction and never edit
`technical-direction.md` to resolve the mismatch; the remedy is telling the
user to re-run `/product-design`.

Then:

1. Propose the shape — the components this feature needs, what each is
   responsible for, and how they talk. Where there is a real choice, present
   two or three options with their trade-offs and a recommendation, rather
   than presenting one design as inevitable.
2. Descend into the parts that carry risk: data and state, the interfaces
   between components, what happens at the boundaries with existing code.
3. Ask about the decisions you cannot make from the code — anything where
   the right answer depends on intent rather than structure.
4. Identify the seams: where does this feature end and the next begin? A
   high-level feature that will not fit in one document is where the
   low-level split comes from. Propose the split and let the user confirm
   it.
5. Name the dependencies on other features, and the open questions you could
   not close. Open questions go into the document rather than being
   resolved by guesswork.

**Stop at mid-to-high level.** Concretely: component names and
responsibilities yes; class-by-class breakdowns no. Interface contracts in
prose or signatures yes; implementations no. "State is persisted per user"
yes; a migration script no. If you find yourself writing code or listing
file paths to edit, you have gone one level too far — that is `/task-add`'s
work, and doing it here freezes decisions that should be made against the
codebase at planning time.

The user confirms the architecture before PHASE 3 writes anything.

---

PHASE 3 — WRITE

Read `./feature-doc-template.md` for both schemas below.

1. **One document per low-level feature**, at
   `.claude/domain/features/<slug>.md`. Slugs are kebab-case and **stable**:
   a re-architected feature keeps its slug forever, exactly like a task ID.
   Re-architecting updates the document in place.

2. **One `FEATURES.md` entry per feature**, appended for a new feature or
   updated in place for an existing one. This skill writes exactly four
   fields:

   - `Status:` — `[NEW]` for a first write; `[ITERATED]` when PHASE 0b
     transitioned it; unchanged otherwise.
   - `Doc:` — the document path.
   - `Source:` — `product-design.md § <section>`, or the literal `prompt`
     when architected directly with no design documents.
   - `Tasks:` — written as `none` **only** when creating a brand-new entry.
     On an existing entry, leave the `Tasks:` line exactly as it is. It
     belongs to `/task-add`; overwriting it destroys the link that makes
     reconciliation possible.

   `[PLANNED]` is never written here — that is `/task-add`'s transition. And
   `[PLANNED]` → `[NEW]` is illegal: tasks were generated from that feature,
   which cannot be un-happened.

3. **Register new documents in `.claude/domain/INDEX.md`** — one
   `| File | Covers |` row each. Leave existing rows alone.

4. **Update `product-design.md`** where the architecture changed a
   high-level decision, or where PHASE 1 produced a clarification that
   belongs upstream. Keep it high-level: the technical detail stays in the
   feature document.

**Closing report.** State:

- Each feature written, its slug, its document path, and its status
  transition (`— → [NEW]`, `[PLANNED] → [ITERATED]`, `[NEW] → [NEW]`).
- Every task flipped to `[STALE]` by PHASE 0b, with its ID and title.
- The reconciliation command for each affected feature:
  `/task-add feature=<slug>`.
- Every open question recorded in the documents.
- When `WRITTEN` is non-empty and `--commit` was not passed: an explicit
  reminder that nothing was committed.

---

COMMIT (only when `--commit` was passed)

If COMMIT is false (the default), run no git/VCS command at all.

If COMMIT is true:

1. If `WRITTEN` is empty, make no commit. Say so and stop.
2. Stage EXACTLY the paths in `WRITTEN` — the feature documents,
   `.claude/FEATURES.md`, `.claude/domain/INDEX.md`,
   `.claude/domain/product-design.md` if updated, and
   `.claude/TASKS.md` when PHASE 0b flipped statuses — and commit once:

   ```
   git add -- <path1> <path2> ...
   git commit -m "Architect <feature slug(s)>"
   ```

   Never use `git add -A`, `git add .`, or `git add -u`. On a non-git VCS,
   use the project's `## VCS` mapping in CLAUDE.md (git→`cm`).
3. On success, report the commit hash (`git rev-parse --short HEAD`).
4. On failure (e.g. a pre-commit hook rejects the commit): surface the exact
   output. Do NOT retry, amend, or use `--no-verify` / `--no-gpg-sign`.
   Files remain staged but uncommitted; tell the user.

---

DO NOT:
- Write implementation-level detail: real code, class-by-class breakdowns,
  file-by-file plans, or lists of files to edit. `/task-add` produces those
  against the codebase as it then stands; freezing them here makes them
  stale before anyone reads them.
- Create tasks, or touch `.claude/TASKS.md` for any reason other than
  flipping a `Status:` line to `[STALE]` under PHASE 0b. Never create,
  delete, or reorder task entries.
- Write or overwrite the `Tasks:` line of an existing `FEATURES.md` entry.
  It is `/task-add`'s field; this skill owns `Status:`, `Doc:`, and
  `Source:` only.
- Write `[PLANNED]`, or move a `[PLANNED]` feature back to `[NEW]`.
- Edit source code. This skill designs and documents; it implements nothing.
- Write or edit `technical-direction.md`. It is `/product-design`'s
  document; this skill reads and adopts it, and a genuine mismatch is a
  flagged concern designed around, never a reason to change it. The remedy
  is re-running `/product-design`.
- Rename a slug, or reuse one for a different feature. Slugs are stable
  identifiers, like task IDs.
- Override the `[IN PROGRESS]` refusal in PHASE 0b — not on the user's
  insistence, not with a flag. Tell them to finish or reset that task
  first.
- Advance past PHASE 2 without the user confirming the architecture.
- Run any git/VCS command unless `--commit` was passed; and with it, stage
  only the explicit `WRITTEN` paths, never a catch-all, and never push,
  branch, tag, or use hook-skipping flags (`--no-verify`, `--no-gpg-sign`,
  `--amend`).
- Create the domain layer yourself when PHASE 0's gate fails. Point at
  `/domain-setup` and stop.
