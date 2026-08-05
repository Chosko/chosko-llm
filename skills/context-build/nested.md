# Nested layout — router + leaves

Read this file only when SKILL.md's Phase 1 step 1.0 sent you here: the
`nested` / `nested=<units>` argument was passed, or the existing index
declares `Layout: nested`. On a flat run this file is never opened.

It replaces Phases 1.5–4 of SKILL.md for a nested run. Everything SKILL.md
says that this file does not restate still applies — in particular the
CONSTRAINTS block, the six-section per-context-file schema (Phase 2.2), the
150-line cap per context file, the 10-line snippet cap, the Phase 3
entry-point wiring, and the commit-and-push rules.

## The shape

A nested layer splits its context files into **units** — natural seams such
as a subsystem, package, or service.

- **Router** — `.claude/context/INDEX.md`. Points at the units. Owns no
  context files of its own.
- **Leaf** — `.claude/context/<unit>/INDEX.md`. Owns that unit's context
  files, which live in the same folder.

Every context file belongs to **exactly one** leaf. No file is shared
between units, and no context file sits loose beside the router.

### Depth cap — two levels

The layout is capped at two levels: the root router plus one rank of
leaves. A leaf never points at a further router.

If the breakdown you would naturally propose needs a third level (a unit
that itself splits into sub-units), do not build it. Flatten it into two
levels — either promote the sub-units to top-level units, or keep the
parent as one unit and let its context files carry the distinction — and
say so explicitly in the Phase 1 report: which unit needed a third level,
and how you flattened it.

## Starting state

- **No context layer exists yet** — a fresh nested build. Proceed.
- **The existing index declares `Layout: nested`** — a rebuild. Proceed,
  and treat the existing units as the starting proposal: keep unit names
  stable unless you have a reason to change them, and say in the report
  which units are kept, added, or retired.
- **The existing index declares `Layout: flat` (or carries no marker) and
  `nested` was passed** — STOP. Report that the project already has a flat
  layer, that converting an existing layer between layouts is a separate
  operation rather than something a build silently performs, and that the
  user should either convert the layer or remove `.claude/context/` and
  re-run to build fresh. Write nothing.

## PHASE 1 — Analysis (no files written)

Do SKILL.md steps 1.1–1.4 unchanged, then instead of 1.5–1.7:

N.1 Determine the unit list.
    - `nested=<unit1>,<unit2>,…` was passed → those are the units, in that
      order and under those names. Do not add or drop units. If a unit
      name matches nothing you can find in the repo, say so in the report
      rather than silently reinterpreting it.
    - Plain `nested` was passed (or this is a rebuild) → propose the units
      yourself from the seams found in 1.3. Prefer few, obvious units over
      many thin ones: a unit that would own a single context file is a
      sign the seam belongs inside another unit.

N.2 Assign every planned context file to exactly one unit. This step runs
    in both forms — `nested=` pre-seeds the unit list but never the file
    assignment. State the reasoning for any file whose home is not
    obvious.

N.3 Plan the paths. Router at `.claude/context/INDEX.md`; leaf index at
    `.claude/context/<unit>/INDEX.md`; each context file at
    `.claude/context/<unit>/<area>.md`. Unit folder names are kebab-case
    and must not collide with a context filename.

N.4 Fix the cross-reference convention (it goes into the router's
    Conventions block verbatim in Phase 2):
    - Context file in the **same** unit → `./other.md`.
    - Context file in **another** unit → `../<other-unit>/other.md`.
    - The unit's own leaf index → `./INDEX.md`; the router →
      `../INDEX.md`.
    - Canonical docs and domain files outside the layer → repo-relative
      paths climbing out of the unit folder, i.e. one extra `../` compared
      with a flat layer (`../../../CLAUDE.md` from
      `.claude/context/<unit>/`). Check the depth by counting, not by
      copying a flat example.
    - Source-file references stay repo-root-relative in both layouts.

Report:
- The detected layout and where the marker was read from (or that no index
  existed yet, so this is a fresh nested build).
- Summary of the discovered project layout (as in the flat run).
- **The unit breakdown**: each unit, a one-line description, and the
  context files it will own. Say whether the unit list came from
  `nested=<units>` or was proposed by you.
- Any third-level breakdown you flattened, and how.
- The cross-reference convention from N.4.
- Estimated total size of the context layer in lines.

STOP and wait for user approval before Phase 2.

## PHASE 2 — Author the layer

2.1 Write the router first, at `.claude/context/INDEX.md`, in this shape:

    ```
    # Context index

    Layout: nested

    <one-line purpose sentence, as in a flat index>

    <canonical-docs block — links to CLAUDE.md, README.md, authoring docs
    that live outside the layer>

    ## Units

    | Unit | Covers |
    | --- | --- |
    | [<unit>](./<unit>/INDEX.md) | <one line> |

    ## Conventions

    <the convention block from N.4>
    ```

    Write `Layout: nested` verbatim, directly under the title. It is what
    /context-update and future runs read to decide how to treat this
    layer; never omit it and never leave it to inference.

    The router carries **no `Last updated:` field at all**. That absence is
    the design, not an oversight — the leaves are the sole date authority.
    Do not add one, and do not derive one from the leaves.

2.2 For each unit, write its leaf index at
    `.claude/context/<unit>/INDEX.md`:

    ```
    # <Unit name>

    Last updated: YYYY-MM-DD

    <one-line description of what the unit covers>

    ## Files

    | File | Covers |
    | --- | --- |
    | [<area>.md](./<area>.md) | <one line> |
    ```

    Each leaf owns its own `Last updated` date, with the same anchor
    semantics the flat `INDEX.md` has. Leaf dates drift apart by design —
    a later unit-scoped update refreshes only that leaf.

    Write the leaf index before the unit's context files, so it works as a
    checklist exactly as the flat INDEX does.

2.3 Write each context file into its owning unit folder, using SKILL.md's
    six-section schema (2.2 a–f) unchanged, the 150-line cap unchanged,
    and the 10-line snippet cap unchanged. Nesting changes where files
    live and which index owns them — nothing about the files themselves.

    Apply the N.4 convention to every cross-reference you write, and check
    each cross-unit link resolves as an actual relative path from the
    file's own folder (`../<other-unit>/<file>.md`).

    A file that must be split for the 150-line cap stays in the same unit;
    update that leaf's Files table, not the router.

2.4 Update each leaf's Files table as you go. The router changes only when
    a whole unit is added or retired — never when a single context file is
    added or removed.

Report:
- Files created, grouped by unit, with line counts.
- Confirmation that the router carries `Layout: nested` and no
  `Last updated`, and that every leaf carries its own `Last updated`.
- Any area that resisted summarization (flag only, do not refactor).

STOP and wait for user approval before Phase 3.

## PHASE 3 — Wire the entry point

Do SKILL.md's Phase 3 with one difference in 3.1: the navigation
instruction still points at `.claude/context/INDEX.md` — the router is the
entry point — and additionally tells the reader to follow its Units table
to the relevant unit's index. For example:

    "For any task involving the codebase, start by reading
    .claude/context/INDEX.md. Follow its Units table to the unit that owns
    your task, read that unit's INDEX.md, then read only the context files
    relevant to your task. Open source files only when the relevant context
    file's 'When to read the source' section indicates it is necessary."

3.3 becomes: verify the router lists every unit, every leaf lists every
context file it owns, every listed file exists, the router carries
`Layout: nested` directly under the title and no `Last updated`, and no
context file sits beside the router or is listed by two leaves.

Orphan checking (3.2) is unchanged: flag orphaned source files and name the
unit and context file that should cover each. Do not create files for them.

## PHASE 4 — Commit and push (only when `--commit` was passed)

Identical to SKILL.md's Phase 4, with the staging list widened: stage the
router `.claude/context/INDEX.md`, every leaf `.claude/context/<unit>/INDEX.md`,
every context file written under a unit folder, and CLAUDE.md. Build the
path list explicitly, one path at a time — never a catch-all
(`git add -A` / `git add .` / `git add -u`), and never a directory
shorthand that would sweep in files this run did not write.
