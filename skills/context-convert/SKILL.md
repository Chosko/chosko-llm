---
name: context-convert
version: 0.2.2
type: skill
description: Convert an existing navigation context layer between the flat layout (one INDEX.md with every context file beside it) and the nested layout (a router INDEX plus per-unit leaves), moving content, never rewriting it. Use it when a layer has outgrown one layout or shrunk out of the other.
requires: skill:interaction-engine
project-policy: vcs:mv, vcs:rm
---

# /context-convert
# Global skill: restructure an existing navigation context layer in place,
# flat to nested or nested back to flat, preserving the authored content of
# every context file. Requires /context-build to have been run first; never
# authors a layer from scratch, never rewrites what a context file says.
#
# Usage: /context-convert                    (direction implied by the current layout: flat becomes nested, nested becomes flat)
#        /context-convert to=nested | to=flat (force the direction; converting to the layout already in place reports "already <layout>" and exits without writing anything)
#        /context-convert nested=api,worker,shared
#          (name the units when converting to nested; same semantics as /context-build's nested=<units>:
#          the user names the units, the skill still proposes which context file lands in which unit)
#        /context-convert -y | --yes          (skip the plan-approval gate, for non-interactive / automated runs;
#          combinable with any other argument: /context-convert to=flat --yes)
#        /context-convert --commit            (commit and push the conversion)
#        /context-convert --commit --no-push  (commit locally, skip the push)
# Default: everything is left uncommitted for review.

$ARGUMENTS

GOAL
Restructure the layer the project already has instead of rebuilding it from
source: move context files, re-author the index files, and repair the
cross-references the depth change would otherwise break. The authored body of
every context file survives the conversion unchanged.

CONSTRAINTS
- Write only under `.claude/context/`. Domain files, source code, README.md
  and CLAUDE.md are out of scope — flag, never edit.
- Never rewrite a context file's content: carry the six-section schema, the
  prose, the source-file lists and the 150-line cap across untouched. The
  single exception is a cross-reference link whose relative path would no
  longer resolve at the file's new depth (Phase 2.3).
- Never author a new context file, delete one or merge two — move what
  exists. If the unit breakdown suggests a file should be split, flag it and
  let `/context-update` or the user handle it.
- Write nothing before the Phase 1 plan has been reported (and approved,
  unless AUTO_CONFIRM is true or the gate passed on its own under
  `unattended`). Every stop condition in this file is a stop *before* any
  write.
- Leave CLAUDE.md alone: its navigation instruction points at
  `.claude/context/INDEX.md`, the entry point in **both** layouts, so it
  needs no edit in either direction. Say so in the Phase 3 report.

---

PREPARATION — run before anything else

P.1 Locate the context layer:
    1. Look for `.claude/context/INDEX.md` (default location).
    2. Not found: search for any `INDEX.md` under a `.claude/` or `context/`
       folder.
    3. Still not found: abort and tell the user to run `/context-build`
       first. There is nothing to convert.

P.2 Read that index and resolve the layout from the marker line alone —
    never from folder counts, subdirectories or file contents:
    - `Layout: flat` → LAYOUT = flat.
    - No `Layout:` line at all → LAYOUT = flat. The layer predates the
      marker; the conversion writes a correct marker either way.
    - `Layout: nested` → LAYOUT = nested.

P.3 Parse $ARGUMENTS, stripping each argument below that appears (all
    optional):
    - `-y` / `--yes`: set AUTO_CONFIRM = true. Skip the Phase 1 approval
      gate and proceed straight into Phase 2; still produce every report.
      AUTO_CONFIRM resolves none of the stop conditions in this file — a
      stop is a stop under `--yes` too.
    - `--commit`: set COMMIT = true. When COMMIT is false (the default),
      leave the conversion uncommitted for review.
    - `--no-push`: set NO_PUSH = true. Matters only when COMMIT is true —
      it skips the pull-at-start, the pre-push re-sync and the push, while
      still committing.
    - `--no-commit` is not a flag of this skill (uncommitted is already the
      default). If both `--commit` and `--no-commit` appear, stop with:
      `--commit and --no-commit cannot be combined. Pick one.`
    - --attended / --unattended: strip whichever appears. Resolve the run's
      interaction policy from them, a policy handed down by a parent run and
      the project's `CLAUDE.md`, per
      `../interaction-engine/references/policy.md`, which holds their
      argument errors; under `unattended`, read
      `../interaction-engine/references/gates.md`. Read
      `../interaction-engine/references/messages.md` before the first gate,
      question or report — each of them follows it. A gate that passes on
      its own has the closing report name the Phase 4 commit or, without
      `--commit`, the uncommitted conversion. `-y` keeps its own meaning. A
      stop condition is not a gate and stops under every policy.
    - `to=nested` / `to=flat`: set TARGET explicitly. Any other value is an
      error — stop and say which values are accepted.
    - `nested=<unit1>,<unit2>,…`: set NESTED_UNITS to that comma-separated
      list; it implies `to=nested`. Combined with `to=flat`, stop — the two
      contradict each other.
    - Anything left over is not a hint this skill accepts: report it as
      ignored rather than guessing at its meaning.

P.4 Resolve the direction:
    - TARGET unset → TARGET is the opposite of LAYOUT (flat → nested,
      nested → flat).
    - TARGET equals LAYOUT → report `Context layer is already <layout> —
      nothing to convert.` and exit **without writing anything**. This is a
      clean exit, not an error, and it fires under `--yes` too.

    Then, when COMMIT is true and the project's CLAUDE.md carries no
    `## VCS` override (non-git), pull at start: run `git pull` on the
    current branch, before Phase 1 begins. On a conflict, stop the run here:
    report the conflict output and tell the user to resolve manually and
    re-run. When COMMIT is false, do not pull — this run commits and pushes
    nothing.

---

PHASE 1 — Analyse and plan (NO FILES WRITTEN)

Read and report only: write, move and delete nothing.

1.1 Inventory the current layer.

    **From a flat layer** (`LAYOUT = flat`):
    - Read `.claude/context/INDEX.md`: its `Last updated` date (or that it
      is missing), and its list of context files with descriptions.
    - List the actual `.md` files beside it and reconcile the two: report
      both a file on disk the index does not list and an index entry with
      no file. Carry the union of what exists on disk — the conversion
      moves files, so disk is what matters.
    - Report, do not fix, any file found in a subdirectory of a layer that
      declares itself flat.

    **From a nested layer** (`LAYOUT = nested`):
    - Read the router's Units table for the unit names and their leaf index
      paths (`./<unit>/INDEX.md`).
    - Read every leaf index: its unit name, its own `Last updated` (or that
      it is missing), and the context files it owns.
    - Take as the universe the union of the leaf Files tables, reconciled
      against what is on disk.
    - A context file sitting loose beside the router, or appearing in two
      leaves' Files tables, is a layout violation: report it with the paths
      and STOP, writing nothing — converting it needs a human decision.

1.2 Read each context file's CROSS-REFERENCES section and scan the rest of
    the body for inline relative links — only to plan the link rewrites in
    1.5, not to assess their content.

1.3 Plan the new structure.

    **flat → nested:**
    - NESTED_UNITS given: those are the units, in that order and under those
      names; add or drop none. Report a unit name matching nothing you can
      find in the repo — never silently reinterpret it.
    - Otherwise propose the units yourself, from the seams visible in the
      existing context files: their OVERVIEW source-file lists, their
      directory clustering in the repo, and which files cross-reference
      each other most densely. Prefer few, obvious units over many thin
      ones — a unit owning a single context file is a sign the seam belongs
      inside another unit.
    - Assign every context file to **exactly one** unit. Do this in both
      forms: `nested=` pre-seeds the unit list, never the file assignment.
      State the reasoning for any file whose home is not obvious.
    - Cap the layout at **two levels**: router plus one rank of leaves. If a
      breakdown you would naturally propose needs a third level, flatten
      it — promote the sub-units to top-level units, or keep the parent as
      one unit — and say in the report which unit needed it and how you
      flattened it.
    - Name unit folders in kebab-case; they must not collide with a context
      filename.
    - Planned paths: router at `.claude/context/INDEX.md`, leaf at
      `.claude/context/<unit>/INDEX.md`, each context file at
      `.claude/context/<unit>/<area>.md`.

    **nested → flat:**
    - Return every context file to `.claude/context/<area>.md`, keeping its
      basename.
    - Delete every leaf index (`.claude/context/<unit>/INDEX.md`) and remove
      each unit folder once empty.
    - **Collision check.** If two units own context files with the same
      basename, the flat layer cannot hold both. STOP: list every colliding
      basename with the full `.claude/context/<unit>/<file>.md` paths that
      claim it, tell the user to rename one and re-run, and write nothing.
      Do not invent a disambiguating name. AUTO_CONFIRM does not resolve
      this.

1.4 Plan the dates, and state the resulting date for every index file in the
    report.

    **flat → nested:** every leaf inherits the flat index's single
    `Last updated` date, verbatim. Never give a unit today's date or any
    other value — a fresher date would make `/context-update`'s next Mode A
    scan skip real changes in that unit. If the flat index carried no
    `Last updated` at all, write no `Last updated` into the leaves either
    (a dateless leaf degrades to a full update of that leaf).
    The router carries **no `Last updated` at all** — see 2.1.

    **nested → flat:** the flat index's `Last updated` is the **minimum**
    across all the leaf dates — a floor, so the next Mode A run re-checks
    units rather than skipping them. If **any** leaf carries no date, write
    no `Last updated` into the flat index at all (`/context-update` then
    falls back to a full update).
    Never take the maximum, never take today's date, and never average.

1.5 Plan the cross-reference rewrites. Change only relative links **inside
    the layer or climbing out of it**; touch nothing else in any file. Never
    rewrite source-file references (repo-root-relative in both layouts) or
    absolute URLs.

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
    pattern-matching a template.

Report — the plan gate; make it complete enough to approve or reject without
reading anything else:
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

If AUTO_CONFIRM is false: STOP and wait for user approval before Phase 2
(gate class: `confirmation`).
If AUTO_CONFIRM is true: proceed immediately to Phase 2.

---

PHASE 2 — Perform the conversion

Work in this order: move the files, then author the index files, then delete
what the old layout leaves behind. Delete nothing before its replacement
exists.

2.1 Move the context files to their planned paths.
    - When converting to nested, create the unit folders first.
    - On a git project, move with `git mv <old> <new>` — it preserves the
      bytes exactly and records the move as a rename. On a non-git VCS, use the move
      command from the project CLAUDE.md's `## VCS` mapping; failing that, a
      plain filesystem move.
    - This is the only step in this skill that shells out for anything
      other than the Phase 4 commit.
    - Do not open a context file to rewrite it during the move: carry the
      body across as-is; 2.3 edits only the links.

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

    - Write `Layout: nested` verbatim, directly under the title; never omit
      it and never leave it to inference.
    - Give the router **no `Last updated:` field at all** — by design, the
      leaves are the sole date authority. Do not add one and do not derive
      one from the leaves. A flat index's `Last updated` does not survive on
      the router; it survives on every leaf.

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

    - Carry each file's one-line description over from the flat index
      verbatim where one existed. Write a description only for a file the
      old index never listed, and say so in the report.

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

    - Write `Layout: flat` verbatim, directly under the title, and the
      `Last updated` computed in 1.4 (the minimum across the leaves) — or
      omit the field entirely if 1.4 said to.
    - Make the Files table the union of every leaf's Files table, carrying
      each file's one-line description over from its leaf verbatim.
    - Unit names do not survive into a flat layer: they appear nowhere in
      the new index.

2.3 Rewrite the cross-references planned in 1.5, and nothing else. Edit each
    moved context file in place, changing only the link paths identified in
    1.5. Do not reword the surrounding sentence, reorder the
    CROSS-REFERENCES section, or update anything the code has since
    changed — that is `/context-update`'s job. A conversion diff on a
    context file shows link paths and nothing more.

2.4 Delete what the old layout leaves behind.
    - **flat → nested:** nothing to delete — the flat index was rewritten in
      place as the router.
    - **nested → flat:** delete every leaf index
      `.claude/context/<unit>/INDEX.md`, then remove each now-empty unit
      folder. On git, `git rm` the leaf indexes so the deletion is staged
      with the rest of the conversion. Verify each folder is empty before
      removing it — a file left inside means something was missed in 1.1;
      report it, never delete it.

Report:
- Every file moved, as `old path → new path`.
- The index files written, and for each one the `Last updated` it carries
  (or, for the router, an explicit confirmation that it carries none).
- Every leaf index deleted and every unit folder removed (nested → flat).
- Every cross-reference rewritten, as `file: old → new`.
- Confirmation that no context file body was otherwise modified.

---

PHASE 3 — Verify the converted layer

Run structural checks only; read, never write. Report any failure loudly
for the user to fix — never silently repair it.

3.1 **Nested result:**
    - the router carries `Layout: nested` directly under its title and
      **no** `Last updated`;
    - every unit in the Units table has a leaf index that exists;
    - every leaf carries its own `Last updated` (or the documented dateless
      fallback) and a Files table;
    - every file listed by a leaf exists in that leaf's folder;
    - every moved context file is listed by exactly one leaf;
    - no context file sits loose beside the router.

    **Flat result:**
    - the index carries `Layout: flat` directly under its title and the
      computed `Last updated` (or the documented omission);
    - every file in its Files table exists beside it;
    - no subdirectory remains under `.claude/context/`;
    - no leaf index survives.

3.2 Resolve every cross-reference link in every context file and in the
    index files, as an actual relative path from the file's own folder.
    Report any that does not resolve — this is where a miscounted `../`
    shows up.

3.3 Confirm the file count is conserved: the number of context files after
    equals the number before. This skill never creates or removes a context
    file, so report any difference as a bug in the run.

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

If COMMIT is false (the default), do nothing here — leave the conversion
uncommitted for the user to review, say so, and stop.

If COMMIT is true (the pull-at-start from P.4 already ran):

4.1 If the run wrote nothing (an early exit, or a stop condition fired),
    make no commit and no push; say so and stop. Never create an empty
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
    report. Never use a catch-all (`git add -A` / `git add .` /
    `git add -u`) or a directory shorthand such as
    `git add .claude/context/`, which would sweep in whatever else is dirty
    there. Make the whole conversion ONE commit.

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
