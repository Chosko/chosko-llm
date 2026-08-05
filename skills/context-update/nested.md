# Nested layout — updating a router + leaves layer

Read this file only when SKILL.md's PREPARATION step P.2a read
`Layout: nested` from the index. On a flat run this file is never opened.

It replaces five things in SKILL.md: the P.2 file list, the P.3 mode
resolution, the P.4 scope report, Phase 2 step 2.4, and Phase 3's staging
list. Everything SKILL.md says that this file does not restate still
applies — in particular the P.1 locate step, the `-y` / `--yes`,
`--no-commit` and `--no-push` flags, the pull-at-start, all of Phase 1, the
Phase 2 rules 2.1–2.3 (in-place section edits, the 150-line split flag, the
hands-off rule for domain files), and the commit-and-push protocol of
Phase 3.

`BACKFILL_MARKER` is never true here: the layer's marker was read as
`nested`, so there is nothing to backfill.

## The shape

- **Router** — `.claude/context/INDEX.md`. Lists the units in a Units
  table. Owns no context files, and carries **no `Last updated` field at
  all**. Never read a date from the router, never write one to it, and
  never treat its missing date as the "fall back to full update" trigger.
- **Leaf** — `.claude/context/<unit>/INDEX.md`. Carries its own
  `Last updated` and a Files table listing the context files it owns, which
  live in the same folder.

Every context file belongs to **exactly one** leaf. Leaf dates drift apart
by design: a unit-scoped run refreshes only the leaves it touched, and each
leaf stays correctly scannable from its own last run.

Cross-references inside the layer follow the layout's convention: a context
file in the same unit is `./other.md`, one in another unit is
`../<other-unit>/other.md`. Preserve that convention when editing
cross-reference sections; do not rewrite same-unit links as cross-unit ones
or vice versa.

## N.1 — Discover the leaves (replaces P.2's file list)

1. Read the router's Units table to get the unit names and their leaf
   index paths (`./<unit>/INDEX.md`).
2. Read every leaf index. From each, record:
   - the unit name,
   - the leaf's `Last updated` date (or that it is missing),
   - the context files that leaf owns, with their one-line descriptions.
3. The in-scope universe for this run is the **union of the leaf Files
   tables**. For every context file, record its owning leaf. That leaf owns
   that file for the rest of the run — it is the leaf whose date scopes the
   file's git scan and the only leaf that gets bumped when the file is
   written.

Do not read any context files or source files yet.

If a leaf listed by the router does not exist, or a file listed by a leaf
does not exist, report it and continue with what does exist — do not create
anything. If a context file sits beside the router or appears in two leaves'
Files tables, report it as a layout violation and stop; the ownership rule
is what makes the dates and the staging list correct.

## N.2 — Determine the update scope (replaces P.3's mode block)

Flag parsing (`-y` / `--yes`, `--no-commit`, `--no-push`) and the
pull-at-start are unchanged — do them exactly as SKILL.md's P.3 says. Then
resolve the mode:

### MODE A — Smart update (default, no mode arguments)

Run **one git scan per leaf**, each anchored to that leaf's own date:

```
git log --after="<that leaf's Last updated>" --name-only --pretty=format: | sort -u
```

There is no global date and no global scan. Do not scope the run by the
newest, oldest, or any derived date: leaf dates drift apart by design, and
one date for all leaves silently skips real changes in the older ones.

Map each leaf's changed source files to context files **owned by that
leaf**, via those files' OVERVIEW sections. A source file that maps only to
a context file in another unit is not this leaf's business — that unit's
own scan covers it from its own date.

A leaf whose `Last updated` is missing degrades to a **full update of that
leaf only**: every context file that leaf owns is in scope, with no git
scan. It never triggers a full-layer rebuild, and the degrade is named
explicitly in the scope report ("unit `worker` has no Last updated — full
update of that unit").

"No commits found" is evaluated across the **union of all the leaves'
scans**, not per leaf. Only when every leaf's scan came back empty (and no
leaf degraded to a full update):

- Check for uncommitted changes: `git diff --name-only HEAD`.
- If uncommitted changes exist, report them and ask the user whether to
  include them in this run.
- If there are none either, report "Context is up to date" and exit
  without writing anything. There is no marker backfill on a nested layer.

A leaf whose own scan was empty while another leaf's was not is simply not
in scope: it is not read, not written, not bumped, not staged.

### MODE B — Full update (argument `full`)

Every context file in every leaf is in scope, regardless of git history and
regardless of the leaf dates. Every leaf is bumped at the end.

### MODE C — Targeted update (`unit=`, `files=` and/or `git=`)

`unit=<names>`: comma-separated unit names, matched against the router's
Units table. The run is scoped to those leaves — their files, their dates,
their index bumps. Leaves outside the list are not read, not written and
not staged. An unrecognized unit name is reported as unrecognized and
skipped; if no name matches at all, stop rather than silently updating
nothing.

`files=<names>`: comma-separated context filenames without path or
extension, resolved inside the leaves:

- With `unit=` also given, a name resolves **only** within those units, and
  no disambiguation question is asked.
- Without `unit=`, a name that matches a context file in exactly one unit
  resolves there. A name that matches in **more than one** unit is
  ambiguous: STOP and ask the user to disambiguate, listing the matching
  `<unit>/<file>.md` paths and telling them to re-run with `unit=<name>`.
  Do not guess, do not apply any tie-break rule, and do not silently pick
  one — updating the wrong unit's file is invisible once done. This stop is
  not a confirmation gate, so `-y` / `--yes` does not resolve it: under
  AUTO_CONFIRM, stop with the same message.
- A name that matches nothing is reported as unrecognized and skipped — do
  not create new files.

`git=<ref>`: exactly as in SKILL.md's flat Mode C (`uncommitted`, a SHA, a
branch, or a range). Map the changed source files to context files across
the whole layer via their OVERVIEW sections — or, when `unit=` was given,
across those units only. Each matched file is scoped to its owning leaf as
usual.

When more than one of `unit=`, `files=` and `git=` is given, take the
**UNION** of the resulting target sets, with `unit=` acting as the filter
on the other two rather than as an extra set of its own when it is combined
with them.

A changed source file covered by no context file in any unit is flagged as
orphaned, naming the unit that should probably cover it. Do not create
context files for orphans — flag only.

## N.3 — Scope report (replaces P.4)

Report before doing any work:

- The detected layout: `nested`, read from the `Layout:` marker in the
  router.
- Which mode was selected and why.
- **Every unit, with its own `Last updated` date** — including units that
  are out of scope, so the drift is visible. Name any leaf whose date is
  missing and the leaf-only full-update degrade that followed.
- Which git command was run per leaf and which source files each returned
  (Modes A and C).
- Which leaves are in scope, and which context files under each.
- Which leaves are deliberately left alone this run.
- Any unrecognized `unit=` / `files=` names, any ambiguous `files=` name,
  any orphaned source files, any layout violations.
- If Mode A found no changes anywhere: state it clearly and exit without
  proceeding further.

If AUTO_CONFIRM is false: STOP and wait for user confirmation.
If AUTO_CONFIRM is true: proceed immediately to Phase 1.

## PHASE 1 — Assess what has changed

Unchanged from SKILL.md, applied to the in-scope context files resolved
above. When reading a context file's OVERVIEW to find its source files,
remember its path is `.claude/context/<unit>/<area>.md` — source-file
references are still repo-root-relative in both layouts, so no path
adjustment is needed for them.

## PHASE 2 — Update the context files

Steps 2.1–2.3 are unchanged. Step 2.4 is replaced by:

**2.4 (nested) — Update the leaf indexes last, and only the ones this run
actually wrote to.**

For each leaf that owns at least one context file Phase 2 wrote:

- Update the one-line descriptions in that leaf's Files table for any of
  its files whose purpose has shifted.
- Update that leaf's `Last updated` to today's date, format `YYYY-MM-DD`.
  This is the anchor for that unit's next Mode A scan.

A leaf whose files were all skipped (Phase 1 found no changes) is **not
written at all** — not its descriptions, not its date. Leaving an old date
on an untouched leaf is correct: it keeps that unit's next scan reaching
back far enough.

The router is not a date holder. No code path in this run writes a
`Last updated` onto `.claude/context/INDEX.md`, and none derives one from
the leaves.

Adding or removing a context file edits its owning leaf's Files table only
— never the router. (As in the flat path, an update run should not be
adding or removing files: flag it and ask the user instead.) The router is
edited only when a whole unit is added or retired, which likewise is a
flag-and-ask in an update run, not something this skill decides on its own.

Report, in addition to SKILL.md's Phase 2 report items:

- The layout (`nested`).
- Each leaf's date before and after, and the resulting list of leaves
  bumped versus leaves deliberately left alone.
- Confirmation that the router was not given a date.

## PHASE 3 — Commit and push

SKILL.md's Phase 3 applies unchanged (3.0 NO_COMMIT, 3.1 nothing-written,
3.4 push, 3.5 commit failure, 3.6 push failure), with the staging list of
3.2 replaced by:

Stage EXACTLY:

- every context file Phase 2 wrote, at its `.claude/context/<unit>/<area>.md`
  path;
- every leaf index Phase 2 bumped, at `.claude/context/<unit>/INDEX.md`;
- the router `.claude/context/INDEX.md` **only** if a whole unit was added
  or retired in this run. Otherwise the router is untouched and must not be
  staged.

Leaves that were not bumped, and files Phase 2 skipped, are NOT staged.
Build the path list explicitly from the Phase 2 report, one path at a time
— never a catch-all (`git add -A` / `git add .` / `git add -u`) and never a
directory shorthand such as `git add .claude/context/`, which would sweep
in leaves this run deliberately left alone.

For 3.3's commit message, name the units that changed, e.g.
`Update context layer: api, worker`. Keep to the repo's existing commit
style.
