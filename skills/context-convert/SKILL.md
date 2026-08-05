---
name: context-convert
version: 0.1.0
type: skill
description: Convert an existing navigation context layer between the flat layout (one INDEX.md with every context file beside it) and the nested layout (a router INDEX plus per-unit leaves). Direction is inferred from the layer's Layout marker and can be forced with to=nested / to=flat; pass nested=<unit1>,<unit2> to name the units. Plan-first — reports the full move plan and stops for approval unless -y is passed. Pass --commit to commit and push the conversion (--commit --no-push to skip the push); default leaves it uncommitted.
---

# /context-convert
# Global skill: restructures an existing navigation context layer in place,
# from flat to nested or from nested back to flat, preserving the authored
# content of every context file.
#
# Requires /context-build to have been run first. This skill never authors a
# context layer from scratch and never rewrites what a context file says.
#
# Usage — convert in the direction implied by the current layout:
#   /context-convert
#   A flat layer becomes nested; a nested layer becomes flat.
#
# Usage — force the direction explicitly:
#   /context-convert to=nested
#   /context-convert to=flat
#   Converting to the layout already in place reports "already <layout>"
#   and exits without writing anything.
#
# Usage — name the units when converting to nested:
#   /context-convert nested=api,worker,shared
#   Same semantics as /context-build's nested=<units>: the user names the
#   units, the skill still proposes which context file lands in which unit.
#
# Usage — skip the plan-approval gate (non-interactive / automated runs):
#   /context-convert -y
#   /context-convert --yes
#   Combinable with any other argument: /context-convert to=flat --yes
#
# Usage — commit (and push) the conversion:
#   /context-convert --commit
#   /context-convert --commit --no-push   (commit locally, skip the push)
#   Default: everything is left uncommitted for review.

$ARGUMENTS

GOAL
A project that outgrows a flat context layer — or shrinks back into one —
should not have to rebuild it from source. This skill restructures the layer
it already has: it moves context files, re-authors the index files, and
repairs the cross-references that the depth change would otherwise break.
The authored body of every context file survives the conversion unchanged.

CONSTRAINTS
- `.claude/context/` is the only writable surface. Domain files, source
  code, README.md and CLAUDE.md are out of scope — flag, never edit.
- Never rewrite a context file's content. The six-section schema, the prose,
  the source-file lists, the 150-line cap: all of it is carried across
  untouched. The single exception is a cross-reference link whose relative
  path would no longer resolve at the file's new depth (Phase 2.3).
- Never author a new context file, never delete one, never merge two. This
  skill moves what exists; if the unit breakdown suggests a file should be
  split, flag it and let `/context-update` or the user handle it.
- Never write anything before the Phase 1 plan has been reported (and
  approved, unless AUTO_CONFIRM is true). Every stop condition in this file
  is a stop *before* any write — a half-converted layer is worse than an
  unconverted one.
- CLAUDE.md's navigation instruction points at `.claude/context/INDEX.md`,
  which is the entry point in **both** layouts. It therefore needs no edit,
  in either direction. Say so in the Phase 3 report rather than touching it.

---

PREPARATION — run before anything else

P.1 Locate the context layer:
    - Look for `.claude/context/INDEX.md` (default location).
    - If not found, search for any `INDEX.md` under a `.claude/` or
      `context/` folder.
    - If still not found, abort and tell the user to run `/context-build`
      first. There is nothing to convert.

P.2 Read that index and resolve the layout marker, and only the marker:
    - `Layout: flat` → LAYOUT = flat.
    - No `Layout:` line at all → LAYOUT = flat. The layer predates the
      marker; the conversion will write a correct marker either way.
    - `Layout: nested` → LAYOUT = nested.
    Never infer the layout from folder counts, subdirectories, or file
    contents. The marker line is the only source of truth.

P.3 Parse $ARGUMENTS:

    `-y` / `--yes` (optional): set AUTO_CONFIRM = true and strip it. The
    Phase 1 approval gate is skipped and the run proceeds straight into
    Phase 2. All reports are still produced. AUTO_CONFIRM does NOT resolve
    any of the stop conditions in this file — a stop is a stop under
    `--yes` too, because every one of them is a case where guessing writes
    the wrong thing invisibly.

    `--commit` (optional): set COMMIT = true and strip it. When COMMIT is
    false (the default) the conversion is left uncommitted for review.

    `--no-push` (optional): set NO_PUSH = true and strip it. Only matters
    when COMMIT is true — it skips the pull-at-start, the pre-push re-sync
    and the push, while still committing.

    `--no-commit` is not a flag of this skill (uncommitted is already the
    default). If both `--commit` and `--no-commit` appear, stop with:
    `--commit and --no-commit cannot be combined. Pick one.`

    `to=nested` / `to=flat` (optional): set TARGET explicitly and strip it.
    Any other value is an error — stop and say which values are accepted.

    `nested=<unit1>,<unit2>,…` (optional): set NESTED_UNITS to that
    comma-separated list and strip it. It also implies `to=nested`. If it
    is combined with `to=flat`, stop — the two contradict each other.

    Anything left over after stripping is not a hint this skill accepts:
    report it as ignored rather than guessing at its meaning.

P.4 Resolve the direction:
    - TARGET unset → TARGET is the opposite of LAYOUT (flat → nested,
      nested → flat).
    - TARGET equals LAYOUT → report `Context layer is already <layout> —
      nothing to convert.` and exit **without writing anything**. This is a
      clean exit, not an error, and it fires under `--yes` too.

    Then, when COMMIT is true and the project's CLAUDE.md carries no
    `## VCS` override (non-git), pull at start: run `git pull` on the
    current branch, before Phase 1 begins. A conflict stops the run here —
    report the conflict output and tell the user to resolve manually and
    re-run. (No pull happens when COMMIT is false: this run will commit and
    push nothing.)

---

PHASE 1 — Analyse and plan (NO FILES WRITTEN)

This phase reads and reports. It writes nothing, moves nothing, deletes
nothing.

1.1 Inventory the current layer.

    **From a flat layer** (`LAYOUT = flat`):
    - Read `.claude/context/INDEX.md`: its `Last updated` date (or that it
      is missing), and its list of context files with descriptions.
    - List the actual `.md` files sitting beside it. Reconcile the two: a
      file on disk that the index does not list, and an index entry with no
      file, are both reported. Carry the union of what exists on disk — the
      conversion moves files, so disk is what matters.
    - Report, do not fix, any file found in a subdirectory of a layer that
      declares itself flat.

    **From a nested layer** (`LAYOUT = nested`):
    - Read the router's Units table to get the unit names and their leaf
      index paths (`./<unit>/INDEX.md`).
    - Read every leaf index: its unit name, its own `Last updated` (or that
      it is missing), and the context files it owns.
    - The universe is the union of the leaf Files tables, reconciled
      against what is on disk.
    - If a context file sits loose beside the router, or appears in two
      leaves' Files tables, that is a layout violation: report it with the
      paths and STOP. Nothing is written. The ownership rule is what makes
      the date and staging arithmetic correct, and a violated layer cannot
      be converted correctly without a human decision.

1.2 Read each context file's CROSS-REFERENCES section (and scan the rest of
    the body for inline relative links). You need them to plan the link
    rewrites in 1.5; you are not assessing their content.

1.3 Plan the new structure.

    **flat → nested:**
    - If NESTED_UNITS was given, those are the units, in that order and
      under those names. Do not add or drop units. A unit name matching
      nothing you can find in the repo is reported, not silently
      reinterpreted.
    - Otherwise propose the units yourself, from the seams visible in the
      existing context files: their OVERVIEW source-file lists, their
      directory clustering in the repo, and which files cross-reference
      each other most densely. Prefer few, obvious units over many thin
      ones — a unit owning a single context file is a sign the seam belongs
      inside another unit.
    - Assign every context file to **exactly one** unit. This step runs in
      both forms: `nested=` pre-seeds the unit list, never the file
      assignment. State the reasoning for any file whose home is not
      obvious.
    - The layout is capped at **two levels**: router plus one rank of
      leaves. If a breakdown you would naturally propose needs a third
      level, flatten it — promote the sub-units to top-level units, or keep
      the parent as one unit — and say in the report which unit needed it
      and how you flattened it.
    - Unit folder names are kebab-case and must not collide with a context
      filename.
    - Planned paths: router at `.claude/context/INDEX.md`, leaf at
      `.claude/context/<unit>/INDEX.md`, each context file at
      `.claude/context/<unit>/<area>.md`.

    **nested → flat:**
    - Every context file returns to `.claude/context/<area>.md`, keeping
      its basename.
    - Every leaf index (`.claude/context/<unit>/INDEX.md`) is deleted, and
      each unit folder is removed once empty.
    - **Collision check.** If two units own context files with the same
      basename, the flat layer cannot hold both. STOP: list every colliding
      basename with the full `.claude/context/<unit>/<file>.md` paths that
      claim it, and tell the user to rename one and re-run. Write nothing.
      Do not invent a disambiguating name — a generated name would break
      every cross-reference pointing at the old one, and the user is better
      placed to pick the surviving name. AUTO_CONFIRM does not resolve this.

1.4 Plan the dates. This is the part that is easy to get wrong, so state
    the resulting date for every index file in the report.

    **flat → nested:** every leaf inherits the flat index's single
    `Last updated` date, verbatim. No unit may be given today's date or any
    other value — none of them has actually been re-checked by this run, and
    a fresher date would make `/context-update`'s next Mode A scan skip real
    changes in that unit. If the flat index carried no `Last updated` at
    all, write no `Last updated` into the leaves either: a dateless leaf
    degrades to a full update of that leaf, which is the safe direction.
    The router carries **no `Last updated` at all** — see 2.1.

    **nested → flat:** the flat index's `Last updated` is the **minimum**
    across all the leaf dates — a floor, so the next Mode A run re-checks
    units rather than skipping them. If **any** leaf carries no date, write
    no `Last updated` into the flat index at all: the missing field makes
    `/context-update` fall back to a full update, which is again the safe
    direction. Never take the maximum, never take today's date, and never
    average.

1.5 Plan the cross-reference rewrites. Only relative links **inside the
    layer or climbing out of it** change; nothing else in any file is
    touched.

    Source-file references are repo-root-relative in both layouts and are
    **never** rewritten. Absolute URLs are never rewritten.

    **flat → nested**, for a file moving into unit `U`:
    | Old link | New link |
    | --- | --- |
    | `./other.md`, `other.md` in the same unit `U` | unchanged |
    | `./other.md`, `other.md` in another unit `V` | `../V/other.md` |
    | `./INDEX.md` | `./INDEX.md` — now the unit's leaf index |
    | `../../CLAUDE.md` and other paths climbing out of the layer | one extra `../` (`../../../CLAUDE.md`) |

    **nested → flat**, for a file moving out of unit `U`:
    | Old link | New link |
    | --- | --- |
    | `./other.md` (same unit) | `./other.md` |
    | `../V/other.md` (another unit) | `./other.md` |
    | `../INDEX.md` (the router) | `./INDEX.md` |
    | `./INDEX.md` (its own leaf) | `./INDEX.md` |
    | `../../../CLAUDE.md` and other paths climbing out of the layer | one fewer `../` (`../../CLAUDE.md`) |

    Check the depth by **counting** from the file's new folder, not by
    pattern-matching a template. Getting a `../` wrong turns a working link
    into a dangling one that nothing will flag later.

Report — this is the plan gate, so it must be complete enough to approve or
reject without reading anything else:
- The detected layout, and that it was read from the `Layout:` marker (or
  that no marker was present and flat was assumed).
- The direction: `flat → nested` or `nested → flat`, and whether it was
  inferred or forced with `to=`.
- **Every file's old path and new path**, one line each.
- The unit breakdown (flat → nested): each unit, a one-line description,
  and the context files it will own. Say whether the unit list came from
  `nested=<units>` or was proposed by you. Name any third-level breakdown
  you flattened and how.
- The units being dissolved (nested → flat), and the leaf indexes that will
  be deleted.
- **What happens to each `Last updated`**: the source date(s), the date
  each new index file will carry, and the rule that produced it
  (inheritance or minimum). Name explicitly any missing date and the
  fallback it triggered.
- Every cross-reference that will be rewritten, as `file: old → new`.
- Anything flagged and not acted on: index/disk mismatches, files that look
  too large, orphan entries.

If AUTO_CONFIRM is false: STOP and wait for user approval before Phase 2.
If AUTO_CONFIRM is true: proceed immediately to Phase 2.

---

PHASE 2 — Perform the conversion

Order matters: move the files first, then author the index files, then
delete what the old layout leaves behind. Nothing is deleted before its
replacement exists.

2.1 Move the context files to their planned paths.

    On a git project, move with `git mv <old> <new>` — it preserves the
    bytes exactly and records the move as a rename, which keeps the diff
    readable and the staging list honest. Create the unit folders first
    when converting to nested. On a non-git VCS, use the move command from
    the project CLAUDE.md's `## VCS` mapping; failing that, a plain
    filesystem move.

    This is the only step in this skill that shells out for anything other
    than the Phase 4 commit.

    Do not open a context file to rewrite it during the move. The body is
    carried across as-is; 2.3 edits only the links.

2.2 Author the index files for the new layout.

    **flat → nested.** Rewrite `.claude/context/INDEX.md` as the router:

    ```
    # Context index

    Layout: nested

    <the flat index's one-line purpose sentence, carried across>

    <the flat index's canonical-docs block, with each path given one extra
    ../ — it is now read from the same depth as before, but state the
    convention as it applies to the unit folders>

    ## Units

    | Unit | Covers |
    | --- | --- |
    | [<unit>](./<unit>/INDEX.md) | <one line> |

    ## Conventions

    <the cross-reference convention: same unit ./other.md; another unit
    ../<other-unit>/other.md; own leaf ./INDEX.md; router ../INDEX.md;
    canonical docs and domain files climb out of the unit folder with one
    extra ../; source-file references stay repo-root-relative>
    ```

    Write `Layout: nested` verbatim, directly under the title. It is what
    `/context-update` and future `/context-build` runs read to decide how to
    treat this layer; never omit it and never leave it to inference.

    The router carries **no `Last updated:` field at all**. That absence is
    the design, not an oversight — the leaves are the sole date authority.
    Do not add one and do not derive one from the leaves. If the flat index
    had a `Last updated`, it does not survive on the router; it survives on
    every leaf.

    Then write each leaf at `.claude/context/<unit>/INDEX.md`:

    ```
    # <Unit name>

    Last updated: YYYY-MM-DD

    <one-line description of what the unit covers>

    ## Files

    | File | Covers |
    | --- | --- |
    | [<area>.md](./<area>.md) | <one line> |
    ```

    Each file's one-line description is carried over from the flat index
    verbatim where one existed. Write a description only for a file the old
    index never listed, and say so in the report.

    **nested → flat.** Rewrite `.claude/context/INDEX.md` as a flat index:

    ```
    # Context index

    Layout: flat
    Last updated: YYYY-MM-DD

    <the router's one-line purpose sentence, carried across>

    <the router's canonical-docs block, with one fewer ../ on each path>

    ## Files

    | File | Covers |
    | --- | --- |
    | [<area>.md](./<area>.md) | <one line> |

    ## Conventions

    <the flat convention: sibling context files ./other.md; canonical docs
    and domain files with ../../-prefixed paths; source-file references
    repo-root-relative>
    ```

    Write `Layout: flat` verbatim, directly under the title, and the
    `Last updated` computed in 1.4 (the minimum across the leaves) — or omit
    the field entirely if 1.4 said to. The Files table is the union of every
    leaf's Files table, with each file's one-line description carried over
    from its leaf verbatim. Unit names do not survive into a flat layer;
    they appear nowhere in the new index.

2.3 Rewrite the cross-references planned in 1.5, and nothing else.

    Edit each moved context file in place, changing only the link paths
    identified in 1.5. Do not reword the surrounding sentence, do not
    reorder the CROSS-REFERENCES section, do not update anything the code
    has since changed — that is `/context-update`'s job, not this skill's.
    A conversion diff on a context file should show link paths and nothing
    more.

2.4 Delete what the old layout leaves behind.

    **flat → nested:** nothing to delete — the flat index was rewritten in
    place as the router.

    **nested → flat:** delete every leaf index
    `.claude/context/<unit>/INDEX.md`, then remove each now-empty unit
    folder. On git, `git rm` the leaf indexes so the deletion is staged with
    the rest of the conversion. Verify each folder is empty before removing
    it — a file left inside means something was missed in 1.1, and it must
    be reported rather than deleted.

Report:
- Every file moved, as `old path → new path`.
- The index files written, and for each one the `Last updated` it carries
  (or, for the router, an explicit confirmation that it carries none).
- Every leaf index deleted and every unit folder removed (nested → flat).
- Every cross-reference rewritten, as `file: old → new`.
- Confirmation that no context file body was otherwise modified.

---

PHASE 3 — Verify the converted layer

Structural checks only. This phase reads; it does not write. Any failure is
reported loudly — the layer is already converted at this point, so a failure
here is something the user must fix, not something to silently repair.

3.1 **Nested result:** the router carries `Layout: nested` directly under
    its title and **no** `Last updated`; every unit in the Units table has a
    leaf index that exists; every leaf carries its own `Last updated` (or
    the documented dateless fallback) and a Files table; every file listed
    by a leaf exists in that leaf's folder; every moved context file is
    listed by exactly one leaf; no context file sits loose beside the
    router.

    **Flat result:** the index carries `Layout: flat` directly under its
    title and the computed `Last updated` (or the documented omission);
    every file in its Files table exists beside it; no subdirectory remains
    under `.claude/context/`; no leaf index survives.

3.2 Resolve every cross-reference link in every context file and in the
    index files, as an actual relative path from the file's own folder.
    Report any that does not resolve. This is where a miscounted `../`
    shows up, and it is much cheaper to catch here than in a future
    session.

3.3 Confirm the file count is conserved: the number of context files after
    equals the number before. This skill never creates or removes a context
    file, so any difference is a bug in the run and must be reported.

Report:
- The result of each check in 3.1–3.3.
- That CLAUDE.md was **not** modified, and why it did not need to be: its
  navigation instruction points at `.claude/context/INDEX.md`, which is the
  entry point in both layouts. On a nested result, mention that the user may
  optionally extend that instruction to say "follow its Units table to the
  unit that owns your task" — a readability nicety, not a requirement, and
  out of this skill's scope.
- The recommended live confirmation: run `/context-update` on the converted
  layer and check that it detects the new layout and reports a sane scope
  (per-leaf dates on a nested result, a single date on a flat one). Do not
  run it as part of this skill — it rewrites content and dates, which is
  not this run's business.

---

PHASE 4 — Commit and push (only when `--commit` was passed)

If COMMIT is false (the default), do nothing here — the conversion is left
uncommitted for the user to review. Say so, and stop.

If COMMIT is true (the pull-at-start from P.4 already ran):

4.1 If the run wrote nothing (an early exit, or a stop condition fired),
    make no commit and no push. Say so and stop. Never create an empty
    commit.

4.2 Stage EXACTLY the paths this conversion touched, and **cover the
    deletions** — a move that stages only the new path leaves the old one
    still tracked, and the commit describes a copy rather than a move.
    Stage:
    - every context file at its new path;
    - every index file written (`.claude/context/INDEX.md`, and each
      `.claude/context/<unit>/INDEX.md` on a nested result);
    - every removed path — each old context-file location, and each deleted
      leaf index. `git add -- <removed path>` records the deletion; paths
      moved with `git mv` and leaf indexes removed with `git rm` are already
      staged.

    Build the path list explicitly, one path at a time, from the Phase 2
    report. Never a catch-all (`git add -A` / `git add .` / `git add -u`)
    and never a directory shorthand such as `git add .claude/context/`,
    which would sweep in whatever else is dirty there. The whole conversion
    is ONE commit — a layer split across two commits is broken at the
    commit in between.

4.3 Commit once, with a message naming the direction, e.g.
    `Convert context layer to nested layout` or
    `Convert context layer to flat layout`. Keep to the repo's existing
    commit style.

4.4 On commit success, report the commit hash (`git rev-parse --short
    HEAD`). Then, unless NO_PUSH is true or this project's CLAUDE.md
    carries a `## VCS` override, re-sync (`git pull`) and `git push`.

4.5 On commit failure (e.g. a pre-commit hook rejects the commit): surface
    the exact output. Do NOT retry, amend, or use `--no-verify` /
    `--no-gpg-sign` or any hook-skipping flag. The files remain staged but
    uncommitted; tell the user.

4.6 On push failure (rejected, no upstream, no remote) or a pre-push
    conflict: abort the merge, leave the local commit intact, do not push,
    and surface the exact output. Never retry, never force-push. The commit
    exists locally; tell the user it needs a manual sync + push.

END
