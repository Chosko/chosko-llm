---
name: architect
version: 0.6.0
type: skill
description: Turn one or more high-level features into low-level feature documents under .claude/domain/features/, indexed in .claude/FEATURES.md — the bridge between /product-design and /task-add. Grounds the architecture in the project's recorded technical-direction.md or existing code, or proposes a tech stack when there is neither. Runs from a product-design section, named features, or a bare prompt with no design documents at all. On a project whose .claude/domain/product-roadmap.md slices the target section, it switches per target into slice mode: it architects one milestone's scope slice rather than the whole section, turns the slice's exclusions into the document's non-goals, and records the milestone as a parenthetical on the FEATURES.md Source: line; pass --no-slices to force traditional resolution. Re-architecting a feature that already has tasks triggers an iterate guard: refuses outright while any task is [IN PROGRESS], otherwise asks, then flips surviving tasks to [STALE] and the feature to [ITERATED]. Requires /domain-setup. At a genuine design fork it offers to convene claude-council when that skill is installed, and is silent when it is not. Nothing committed by default; pass --commit to commit and push exactly the written paths (--commit --no-push to skip the push).
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
#        /architect <feature name> <milestone-slug>  (pick the slice up front on a roadmapped project)
#        /architect <args> --no-slices     (ignore the roadmap; resolve every target traditionally)
#        /architect <args> --commit        (commit and push exactly what this run wrote)
#        /architect <args> --commit --no-push  (commit locally, skip the push)

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
| `./sectioned-input.md` | PHASE 0, for each target resolving in **traditional mode** — no roadmap, or `--no-slices`, or a roadmap that does not slice this target's section. Matching against `product-design.md`'s sections and existing `FEATURES.md` slugs, and the `Source:` value that produces. |
| `./sliced-input.md` | PHASE 0, for each target resolving in **slice mode** — `.claude/domain/product-roadmap.md` carries at least one milestone with a `Covers:` line, a slice matches this target, and `--no-slices` was not passed. Slice resolution, disambiguation, exclusions into non-goals, and the extended `Source:`. |
| `./iterating.md` | PHASE 0 finds the target feature already has a `FEATURES.md` entry. Read before PHASE 0b. |
| `./tech-stack-selection.md` | The project has NO existing tech stack AND no `technical-direction.md` (greenfield). Read at the start of PHASE 2. |
| `./feature-doc-template.md` | PHASE 3, always — the feature-document schema and the `FEATURES.md` entry format. |
| `./council-gate.md` | PHASE 2 reaches a genuine design fork — a real trade-off with nameable stakes, expensive to reverse once tasks exist. Not on a fork settled by an existing stack, and not when the blocker is a missing fact (that is a PHASE 1 clarification). |

Do not read a supporting file speculatively — in particular, the two
input-resolution files are read per target, only once the PHASE 0 dispatch
has decided which mode that target takes, and never both for the same
target. The common path — a brownfield project with no roadmap, a feature
architected for the first time — reads only `./sectioned-input.md` and
`./feature-doc-template.md`.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for the optional `--commit` flag. If present, set
COMMIT = true and strip it. `--commit` and `--no-commit` are mutually
exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`

Also scan for the optional `--no-push` flag and strip it. NO_PUSH only
matters when COMMIT is true: it skips the pull-at-start / re-sync / push
steps of the commit-and-push protocol (docs/authoring-guide.md) while
still committing as always.

Also scan for the optional `--no-slices` flag and strip it. If present, set
NO_SLICES = true: PHASE 0 skips the roadmap probe entirely and every target
resolves in traditional mode. On a project with no roadmap it is a silent
no-op — never warn about it.

What remains is the input, resolved in PHASE 0. Its forms — empty, one or
more feature names, or a free-form description — and the rules that match
them are carried by the input-resolution file PHASE 0 dispatches to.

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

If COMMIT is true and the project's CLAUDE.md does not carry a `## VCS`
override (non-git), pull at start per the commit-and-push protocol: run
`git pull` on the current branch. A conflict stops the run here — report
the conflict output and tell the user to resolve manually and re-run.

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

**Probe for a roadmap.** Unless NO_SLICES is true, Glob for
`.claude/domain/product-roadmap.md`. If it exists, read it and note every
milestone carrying a `Covers:` line and the slices under it. The presence of
that document with at least one `Covers:` line is the whole of slice mode's
activation — there is no flag file, no settings key and no frontmatter
switch. If the document is absent, carries no `Covers:` line, or NO_SLICES
is true, there are no slices and the probe says nothing: a project with no
roadmap is the normal case, not a warning.

**Resolve the target feature(s) — dispatching per target, not per run.** One
invocation may architect several targets, and a roadmap that slices
`§ Authentication` may say nothing about `§ Config export`. For each target
independently:

- A slice matches this target → read `./sliced-input.md` and follow it for
  this target.
- No slice matches → read `./sectioned-input.md` and follow it for this
  target. When the probe did find a roadmap, say in one line that this
  target's section is unsliced and is taking the traditional path.

Read each of the two files at most once per run, and never read a mode's
file for a target that did not dispatch to it.

**Detect whether a stack exists.** A present `technical-direction.md` counts
as a stack that exists, exactly like an established codebase stack — note
this and move on. Otherwise, note from what you read whether this project
already has a technology stack (language, framework, storage, delivery).
Either way, this decides whether PHASE 2 reads `./tech-stack-selection.md`:
it does not, whenever a stack already exists in either form.

**Check for existing entries.** For each target feature, look for a
`FEATURES.md` entry. If any target already has one, read `./iterating.md`
and continue to PHASE 0b. If none do, skip PHASE 0b entirely.

**Check for an interrupted session.** For each target, derive a
`<target-slug>` — the kebab-case of the resolved feature name, or, for a
free-form prompt with no named feature, a short kebab-case label drawn from
the prompt's first few words. Glob for
`.claude/domain/features/<target-slug>.architect-progress.md`. If it
exists:

- Read it and summarize, in a few lines, what the last session covered and
  where it stopped — the same report-don't-guess spirit as
  `skills/product-design/resuming.md`, at this skill's smaller scale.
- Ask whether to resume (continue PHASE 2 treating the summarized ground as
  already covered) or start fresh (delete the marker, begin PHASE 2 from the
  top for this target). Wait for an explicit answer; do not guess.

This check is independent of the `FEATURES.md`-entry check above: the
marker tracks this skill's own conversational progress, not the feature's
write state, so a target can have a marker whether or not it already has a
`FEATURES.md` entry (e.g. an iteration interrupted mid-PHASE-2 has both).

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
   than presenting one design as inevitable. When that choice is a genuine
   fork — defensible options, nameable stakes, expensive to reverse once
   tasks exist — read `./council-gate.md` and follow it before you
   recommend.
2. Descend into the parts that carry risk: data and state, the interfaces
   between components, what happens at the boundaries with existing code.
3. Ask about the decisions you cannot make from the code — anything where
   the right answer depends on intent rather than structure.
4. Identify the seams: where does this feature end and the next begin? A
   high-level feature that will not fit in one document is where the
   low-level split comes from. Propose the split and let the user confirm
   it. Where the split could defensibly fall in more than one place and the
   choice would shape every task generated from it, `./council-gate.md`
   applies here too.
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

**Progress marker.** This phase is the one exception to "nothing is written
before PHASE 3": at each checkpoint above where real ground has been
covered (stack chosen, shape proposed, data/interfaces/seams discussed,
dependencies and open questions named) and whenever the conversation might
end, write or rewrite `.claude/domain/features/<target-slug>.architect-progress.md`
with a short recap — which of the steps above are covered, the decisions
made so far as a few bullets, any open questions raised so far, and any
council verdict already obtained (see `./council-gate.md` step 8 — recording
it is what stops a resumed session from paying for the same run twice). Keep it
short: this is a resume aid, not a second copy of the feature document, and
it carries none of `FEATURES.md`'s or `TASKS.md`'s status vocabulary
(no `[NEW]`/`[PLANNED]`/`[IN PROGRESS]`/etc.), so it can never be confused
with either.

The user confirms the architecture before PHASE 3 writes the feature
document(s) themselves.

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

5. **Clear the progress marker.** For each target just written, delete its
   `.claude/domain/features/<target-slug>.architect-progress.md` if it
   exists — a normally-completed PHASE 3 means there is nothing left to
   resume, and a feature that finished writing must never still look
   interrupted. If `--commit` was passed and the marker had previously been
   committed (an earlier, separately-committed interrupted run), add its
   path to `WRITTEN` so the deletion is staged and committed like any other
   change; if it only ever existed uncommitted within this same run,
   deleting the file is enough.

**Closing report.** State:

- Each feature written, its slug, its document path, and its status
  transition (`— → [NEW]`, `[PLANNED] → [ITERATED]`, `[NEW] → [NEW]`).
- Every task flipped to `[STALE]` by PHASE 0b, with its ID and title.
- The reconciliation command for each affected feature:
  `/task-add feature=<slug>`.
- Every open question recorded in the documents.
- Whether an interrupted-session marker was found at PHASE 0 and how it was
  resolved (resumed or started fresh), and that each written feature's
  marker was cleared in PHASE 3.
- If the council was convened: the question, the run SHA, the verdict, and
  the paths of the report and transcript it wrote, so the user can keep or
  delete them. Say nothing at all when it was not convened.
- When `WRITTEN` is non-empty and `--commit` was not passed: an explicit
  reminder that nothing was committed.

---

COMMIT AND PUSH (only when `--commit` was passed)

If COMMIT is false (the default), run no git/VCS command at all.

If COMMIT is true (the pull-at-start from PHASE 0 already ran):

1. If `WRITTEN` is empty, make no commit (and no push). Say so and stop.
2. Stage EXACTLY the paths in `WRITTEN` — the feature documents,
   `.claude/FEATURES.md`, `.claude/domain/INDEX.md`,
   `.claude/domain/product-design.md` if updated,
   `.claude/TASKS.md` when PHASE 0b flipped statuses, and a
   `.architect-progress.md` marker if PHASE 3 deleted a previously-committed
   one — and commit once:

   ```
   git add -- <path1> <path2> ...
   git commit -m "Architect <feature slug(s)>"
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
- Write any file before PHASE 3, with exactly two exceptions: the PHASE 2
  progress marker (`.claude/domain/features/<target-slug>.architect-progress.md`),
  and the report and transcript claude-council writes for itself when the
  PHASE 2 council gate is convened (`council-report-*.html`,
  `council-transcript-*.md` — see `./council-gate.md`). The second carve-out
  is narrow: it permits those two files and nothing else, and neither ever
  enters `WRITTEN` or a `--commit` staging list.
  Everything else — feature documents, `FEATURES.md`, `INDEX.md`,
  `product-design.md` — is PHASE 3's job, not PHASE 2's.
- Write implementation-level detail: real code, class-by-class breakdowns,
  file-by-file plans, or lists of files to edit. `/task-add` produces those
  against the codebase as it then stands; freezing them here makes them
  stale before anyone reads them.
- Create tasks, or touch `.claude/TASKS.md` for any reason other than
  flipping a `Status:` line to `[STALE]` under PHASE 0b. Never create,
  delete, or reorder task entries.
- Leave a target's progress marker in place once PHASE 3 has completed
  normally for it. A written feature must never still look interrupted.
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
- Advance past PHASE 2 without the user confirming the architecture — a
  council verdict is an input to that confirmation, never a substitute for
  it, however confident it came back.
- Run any git/VCS command unless `--commit` was passed; and with it, stage
  only the explicit `WRITTEN` paths, never a catch-all, push per the
  commit-and-push protocol unless `--no-push` was passed, and never
  force-push, retry a failed push, branch, tag, or use hook-skipping flags
  (`--no-verify`, `--no-gpg-sign`, `--amend`).
- Create the domain layer yourself when PHASE 0's gate fails. Point at
  `/domain-setup` and stop.
