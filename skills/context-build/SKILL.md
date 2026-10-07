---
name: context-build
version: 0.6.1
type: skill
description: Build a navigation context layer under .claude/context/ — an INDEX.md plus one context file per area of the codebase — so future sessions read a map instead of the source. Use it once on a project with no layer yet; flat by default, nested on request. Restructuring a layer is /context-convert's job.
replaces: command:context-build
requires: skill:interaction-engine
---

# /context-build
# Global skill: introduces a navigation layer of context files to reduce token cost
# in future Claude Code sessions on any project. Flat by default; `nested`
# builds a router + per-unit leaf layout instead. Refuses to convert an
# existing layer — that is /context-convert. Authoring skill — leaves the
# layer uncommitted unless `--commit` is passed.
# Usage: /context-build
# Usage with hint: /context-build "source code lives under lib/ not src/"
# Usage nested: /context-build nested                   (router + per-unit leaves; the skill proposes the units)
# Usage nested, named: /context-build nested=api,worker (the user names the units)
# Usage with commit: /context-build --commit            (commit and push the context layer when done)
# Usage without push: /context-build --commit --no-push (commit locally, skip the push)

GOAL
Reduce token cost in future Claude Code sessions on this repo. Instead of
reading multiple full source files upfront to answer questions or plan changes,
future sessions use a navigation layer of context files — cheap summaries — to
decide which source files to read on demand.

$ARGUMENTS

ARGUMENT NOTE — before Phase 1, scan $ARGUMENTS and strip each flag and
argument below. Whatever text remains afterwards is the structure hint.

- `--commit` → COMMIT = true. Default COMMIT = false: the run leaves all
  output uncommitted for review.
- `--no-push` → NO_PUSH = true. It matters only when COMMIT is true: it skips
  the pull-at-start / re-sync / push steps of the commit-and-push protocol;
  the commit still happens.
- `--attended` / `--unattended` → strip whichever appear.
  - Resolve the run's interaction policy from them, a policy handed down by a
    parent run and the project's `CLAUDE.md`, per
    `../interaction-engine/references/policy.md`, which holds their argument
    errors.
  - Under `unattended`, read `../interaction-engine/references/gates.md`.
  - Read `../interaction-engine/references/messages.md` before the first
    gate, question or report — each of them follows it.
  - A gate that passes on its own has the closing report name the Phase 4
    commit or, without `--commit`, the uncommitted files.
- Nested-layout argument (optional):
  - `nested` → NESTED = true, NESTED_UNITS = unset. The skill proposes the
    unit seams itself.
  - `nested=<unit1>,<unit2>,…` → NESTED = true, NESTED_UNITS = that
    comma-separated list. The user has named the units; the skill still
    proposes which context file lands in which unit.
  - Neither present → NESTED = false.
  - Both forms compose freely with the structure hint, `--commit`, and
    `--no-push`.

Pull at start: when COMMIT is true (and NO_PUSH is not set) and the project's
CLAUDE.md does not carry a `## VCS` override (non-git), run `git pull` on the
current branch before Phase 1 begins. On a conflict, stop the run here: report
the conflict output and tell the user to resolve manually and re-run. When
COMMIT is false, do not pull — there is nothing this run will commit or push.

SUPPORTING FILES (read on demand — not up front)

SKILL.md alone covers the common path: a flat context layer, one `INDEX.md`
with every context file beside it. The nested path lives in a sibling file.

| Read this file | Exactly when |
| -------------- | ------------ |
| `../interaction-engine/references/policy.md` | Every run, at ARGUMENT NOTE. |
| `../interaction-engine/references/messages.md` | Every run, before the first gate, question or report. |
| `../interaction-engine/references/gates.md` | The policy resolved to `unattended`. |
| `./nested.md`  | NESTED is true (the `nested` / `nested=` argument was passed), OR Phase 1 step 1.0 read `Layout: nested` from an existing index. |

Do not read `./nested.md` speculatively; a flat run never opens it.

CONSTRAINTS
- Do not refactor any source code.
- Do not modify CLAUDE.md until Phase 3, the entry-point update at the end.
- Context files describe CODEBASE STRUCTURE only — not the project's business
  domain or rules.
- Leave existing domain knowledge files (e.g. a .claude/ folder with .md
  files, a docs/ folder, or similar) untouched. Treat them as canonical and
  cross-reference them from context files where relevant.

YOUR TASK — three phases. Stop at the end of each phase and report before continuing.

---

PHASE 1 — Analysis (no files written yet)

1.0 Detect the layout of any pre-existing context layer. The `Layout:` line
    directly under the title of `.claude/context/INDEX.md` (or the project's
    equivalent index) is the only source of truth — never infer the layout
    from folder counts, subdirectories, or file contents.
    - No index at all → fresh build, LAYOUT = flat.
    - `Layout: flat`, or no `Layout:` line → LAYOUT = flat.
    - `Layout: nested` → LAYOUT = nested.

    Then resolve the layout this run will produce:
    - LAYOUT nested → read `./nested.md` now and follow it for the rest of
      the run, whether or not the `nested` argument was passed.
    - LAYOUT flat, NESTED true → read `./nested.md` now and follow it; it
      states how to handle a pre-existing flat layer.
    - LAYOUT flat, NESTED false → continue with this file (the common path);
      do not open `./nested.md`.

1.1 Discover the project layout:
    - Identify the language(s) and primary source directories.
    - Identify any existing documentation, context, or knowledge folders
      (e.g. .claude/, docs/, context/, CLAUDE.md, README.md).
    - Identify the test layout and config files.
    - Apply any project-structure hints from $ARGUMENTS.

1.2 Read the entry-point file (CLAUDE.md or equivalent) if it exists, plus any
    existing context or domain files. Do not read full source files yet.

1.3 Identify the natural seams — modules, layers, or feature areas cohesive
    internally with clear interfaces to the rest of the system. Infer them
    from filenames, directory structure, and import relationships where
    possible before opening full source files.

1.4 For each seam, decide whether it warrants its own context file. Criterion:
    would a future Claude Code session, asked to modify only that area,
    benefit from reading a focused summary instead of opening every source
    file in the project?

1.5 Decide the folder layout. Default: .claude/context/<area>.md. Propose a
    different structure only if the project's existing conventions make the
    default a poor fit — and justify it in one paragraph.

1.6 Decide a cross-reference convention: each context file links to related
    context files and relevant domain files by relative path, so Claude Code
    can chain reads without loading everything.

1.7 Decide the top-level index file (default: .claude/context/INDEX.md),
    listing every context file with a one-line description — the cheapest
    possible entry point for future sessions.

Report:
- The detected layout (`flat`) and where the marker was read from (or that no
  index existed yet, so this is a fresh flat build).
- The discovered project layout (languages, source dirs, existing context files).
- The proposed folder layout with rationale.
- The context files you intend to create, each with a one-line description.
- The cross-reference convention.
- Estimated total size of the context layer in lines.
- OPTIONAL — a nesting suggestion, only when the codebase has obvious unit
  seams (several self-contained subsystems, packages, or services) that
  would each own a group of context files. Phrase it as a suggestion the
  user can act on by re-running with `nested`, e.g. "this repo splits
  cleanly into api / worker / shared — re-run with `nested` if you want a
  router + per-unit layout." Never switch layout on your own, and never
  turn this into a question that gates the flat run: the flat proposal
  stands as-is and the approval gate below covers the flat plan.

STOP and wait for user approval before Phase 2. Gate class: `confirmation`.

---

PHASE 2 — Author the context files

2.1 Create the context folder and the INDEX file first. INDEX lists every
    planned context file even before it exists, so it works as a checklist.
    Put the layout marker on its own line directly under the title:

    ```
    # Context index

    Layout: flat
    Last updated: YYYY-MM-DD
    ```

    Write `Layout: flat` verbatim — /context-update and future runs read it to
    decide how to treat this layer; never omit it and never infer it.

2.2 Create each context file. Every file must contain:

    a) OVERVIEW — what this area covers and which source files implement it,
       listed by relative path.

    b) PUBLIC API — the functions, classes, or interfaces other areas of the
       codebase call into this one. For each: name, inputs, outputs, and side
       effects. Reference by fully-qualified name (e.g.
       src/sheet.py::append_row). Only the contract — no implementation
       detail.

    c) INTERNAL PATTERNS — non-obvious conventions, invariants, or constraints
       anyone modifying this area must know. Examples: "all writes go through X to
       enforce the tab-lock rule," "URL normalization happens here and nowhere else."

    d) DOMAIN DEPENDENCIES — links to domain knowledge files (e.g. .claude/*.md,
       docs/) defining rules this area enforces. State which rule and which file.

    e) CROSS-REFERENCES — links to other context files this area interacts
       with, each with a one-line description of the interaction.

    f) WHEN TO READ THE SOURCE — a concrete list of tasks that require opening
       the actual source files rather than stopping at this context file. Be
       specific: "modifying the dedup normalization logic in is_duplicate()"
       rather than "changing filters."

2.3 Keep each context file under 150 lines. Split a file that would exceed it
    into two focused files and update INDEX accordingly.

2.4 Include no code snippet longer than 10 lines. Reference source by path and
    function name rather than reproducing implementation.

2.5 Mark each file complete in INDEX as you go.

Report:
- Files created with line counts.
- Confirmation that INDEX.md carries the `Layout: flat` marker.
- Any area where the codebase resisted summarization (flag only — a signal
  for future refactoring; do not refactor now).

STOP and wait for user approval before Phase 3. Gate class: `confirmation`.

---

PHASE 3 — Wire the entry point

3.1 Add an explicit navigation instruction at the top of CLAUDE.md (or the
    project's equivalent entry-point file):

    "For any task involving the codebase, start by reading .claude/context/INDEX.md
    (or the equivalent index path for this project). Then read only the context files
    relevant to your task. Open source files only when the relevant context file's
    'When to read the source' section indicates it is necessary."

    If no CLAUDE.md or equivalent entry-point file exists, create a minimal
    one containing only this instruction plus the index path.

3.2 Verify every source file in the project is referenced from at least one
    context file. Flag each orphan (mentioned nowhere in the context layer) by
    name and suggest which context file should cover it. Flag only — do not
    create new context files for orphans.

3.3 Verify INDEX.md is complete and accurate: every context file exists, every
    one-line description matches the file's actual content, and the
    `Layout: flat` marker sits directly under the title.

Report:
- What changed in CLAUDE.md, in plain words; the diff only on `show`.
- Any orphaned source files and suggested home context file for each.
- A validation checklist the user can run manually to confirm the navigation layer
  works as intended. Example items:
    * "Ask Claude Code 'how does [feature X] work?' — it should read INDEX, then
      the relevant context file, and open source only if the task requires it."
    * "Ask Claude Code to modify [function Y] — confirm it reads the correct context
      file before opening src/."

---

PHASE 4 — Commit and push (only when `--commit` was passed)

COMMIT false (the default) → do nothing; the context layer stays uncommitted
for review.

COMMIT true → after Phase 3 completes (pull at start already ran, per the
ARGUMENT NOTE):

1. If the run wrote nothing (e.g. it was aborted before Phase 2), make no
   commit and no push. Say so and stop.
2. Stage EXACTLY the files this run wrote — `.claude/context/INDEX.md`,
   every context file created in Phase 2, and CLAUDE.md (the Phase 3
   entry-point edit, or a newly created CLAUDE.md). Build the path list
   explicitly; never use a catch-all (`git add -A` / `git add .` /
   `git add -u`).
3. Commit once: `git commit -m "Add navigation context layer"`.
4. On commit success, report the commit hash (`git rev-parse --short HEAD`).
   Then, unless NO_PUSH is true or this project's CLAUDE.md carries a
   `## VCS` override, re-sync (`git pull`) and `git push`.
5. On commit failure (e.g. a pre-commit hook rejects the commit): surface
   the exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.
6. On push failure (rejected, no upstream, no remote) or a pre-push
   conflict: surface the exact output. Never retry, never force-push. The
   commit exists locally; tell the user it needs a manual sync + push.

END
