---
name: context-update
version: 1.4.0
type: skill
description: Update an existing navigation context layer after code changes, then auto-commit and push the context files it updated. Works on both flat and nested layers; on a nested layer pass unit=<names> to scope the run to specific units. Pass --no-commit to leave them uncommitted, or --no-push to commit without pushing.
replaces: command:context-update
---

# /context-update
# Global skill: updates an existing navigation context layer after code changes.
# Requires /context-build to have been run first to create the initial context layer.
#
# Usage — smart update (default, no arguments):
#   /context-update
#   Detects commits since the "Last updated" date in INDEX.md and updates only
#   the context files affected by those commits. If no commits are found since
#   that date, reports "context is up to date" and exits.
#
# Usage — full update (all context files, regardless of git history):
#   /context-update full
#
# Usage — update only specific context files:
#   /context-update files=cli,sheet
#
# Usage — update only context files affected by uncommitted changes:
#   /context-update git=uncommitted
#
# Usage — update only context files affected by a specific commit or range:
#   /context-update git=HEAD
#   /context-update git=a1b2c3d
#   /context-update git=my-feature-branch
#   /context-update git=HEAD~3..HEAD
#
# Parameters can be combined (files= and git= take the UNION of both target sets):
#   /context-update git=uncommitted files=filters,scorer
#
# Usage — skip all confirmation prompts (non-interactive / automated runs):
#   /context-update -y
#   /context-update --yes
#   Works with any other parameter combination:
#   /context-update full --yes
#   /context-update git=uncommitted -y
#
# Usage — update the context files but skip the auto-commit (and push):
#   /context-update --no-commit
#   Combinable with any mode: /context-update full --no-commit
#
# Usage — commit as usual but skip the push:
#   /context-update --no-push
#   Combinable with any mode: /context-update full --no-push
#
# Usage — nested layers only: update only specific units (leaves):
#   /context-update unit=api,worker
#   Also disambiguates a files= name that exists in more than one unit:
#   /context-update unit=api files=client

$ARGUMENTS

SUPPORTING FILES (read on demand — not up front)

This skill's common path is the whole of SKILL.md: a flat context layer,
one `INDEX.md` with every context file beside it. The nested path lives in
a sibling file, so a flat run never pays for it.

| Read this file | Exactly when |
| -------------- | ------------ |
| `./nested.md`  | PREPARATION step P.2a read `Layout: nested` from the index. |

Do not read `./nested.md` speculatively. On a flat run the file is never
opened.

---

PREPARATION — run before anything else

P.1 Locate the context layer:
    - Look for .claude/context/INDEX.md (default location).
    - If not found, search for any INDEX.md under a .claude/ or context/ folder.
    - If still not found, abort and tell the user to run /context-build first
      to create the initial context layer.

P.2 Read INDEX.md and resolve the layout marker (P.2a) FIRST, before taking
    anything else from the file. Once the layout is known to be flat, take
    from INDEX.md:
    - The full list of context files and their one-line descriptions.
    - The "Last updated" timestamp (format: YYYY-MM-DD).
    Do not read any context files or source files yet.

    On a nested layer the index is a router: it lists units, not context
    files, and it carries no "Last updated" at all. Do not read a date from
    it, and do not treat its absence as the missing-date fallback — that
    fallback is a flat-layout rule. `./nested.md` states how the file list
    and the dates are resolved instead.

P.2a Detect the layout from the marker, and only from the marker:
    - `Layout: flat` → LAYOUT = flat.
    - No `Layout:` line at all → LAYOUT = flat, and set BACKFILL_MARKER = true.
      This layer predates the marker; step 2.4 will add it.
    - `Layout: nested` → LAYOUT = nested.
    Never infer the layout from folder counts, subdirectories, or file
    contents. The marker line is the only source of truth.

    If LAYOUT is nested, read `./nested.md` now and follow it for the rest
    of the run. It replaces P.2's file list, P.3's mode resolution, P.4's
    scope report, Phase 2 step 2.4 and Phase 3's staging list; everything
    else in this file still applies. Do not carry on down the flat path — a
    half-handled nested run would stamp dates and stage files wrongly.
    BACKFILL_MARKER is never true on a nested layer: the marker was read, so
    there is nothing to backfill.

    If LAYOUT is flat, do not open `./nested.md` at all. This is the common
    path and the rest of this file is written for it.

P.3 Parse $ARGUMENTS. First, check for the confirmation flag:

    -y / --yes flag (optional, combinable with any mode):
    If "-y" or "--yes" is present in $ARGUMENTS, set AUTO_CONFIRM = true.
    When AUTO_CONFIRM is true:
    - Skip all "STOP and wait for user confirmation" gates.
    - Proceed automatically through PREPARATION → PHASE 1 → PHASE 2 without pausing.
    - Still produce all reports (scope report, Phase 1 diff summary, Phase 2 final
      report) — just do not wait for a response before continuing.
    - Exception: if Mode A detects no changes and would normally exit, still exit
      cleanly without asking. AUTO_CONFIRM does not force an update when there is
      nothing to update.
    Strip the flag from $ARGUMENTS before parsing the rest.

    --no-commit flag (optional, combinable with any mode):
    If "--no-commit" is present in $ARGUMENTS, set NO_COMMIT = true and strip
    it before parsing the rest. When NO_COMMIT is true, PHASE 3 skips the
    auto-commit (and the push — nothing was committed) and leaves the
    updated context files uncommitted. `--commit` and `--no-commit` are
    mutually exclusive — if both appear, stop with:
    `--commit and --no-commit cannot be combined. Pick one.`

    --no-push flag (optional, combinable with any mode):
    If "--no-push" is present in $ARGUMENTS, set NO_PUSH = true and strip it
    before parsing the rest. NO_PUSH only matters when NO_COMMIT is false:
    it skips the pull-at-start / re-sync / push steps of PHASE 3's
    commit-and-push protocol while still committing as always.

    Unless NO_COMMIT is true or the project's CLAUDE.md carries a `## VCS`
    override (non-git), pull at start here, before determining the update
    scope: run `git pull` on the current branch. A conflict stops the run
    immediately — report the conflict output and tell the user to resolve
    manually and re-run. This also keeps Mode A's `git log` scan reading
    from an up-to-date branch.

    Then determine the update scope. Four modes are possible:

    MODE A — Smart update (DEFAULT — no arguments provided):
    Use the "Last updated" date from INDEX.md to find all commits since that date:
      git log --after="YYYY-MM-DD" --name-only --pretty=format: | sort -u
    This returns the list of source files touched by any commit since the last
    context update. Map those source files to context files (via the OVERVIEW
    section of each context file, which lists source files by path).
    Update only the mapped context files plus INDEX.
    If no commits are found since the last-updated date:
      - Check for uncommitted changes: git diff --name-only HEAD
      - If uncommitted changes exist, report them and ask the user whether to
        include them in this update run.
      - If no uncommitted changes either, report "Context is up to date". If
        BACKFILL_MARKER is true, still run the marker backfill (see 2.4) —
        INDEX.md alone is written, staged and committed — then exit. Otherwise
        exit without writing anything.
    If the "Last updated" field is missing from INDEX.md, fall back to MODE B (full).

    MODE B — Full update (argument "full" provided):
    Update all context files in the context layer, regardless of git history.

    MODE C — Targeted update (files=<names> and/or git=<ref> provided):
    files=<names>: comma-separated context filenames without path or extension
      (e.g. "sheet" matches .claude/context/sheet.md). Update only the listed
      files plus INDEX. If a name does not match any existing context file, report
      it as unrecognized and skip it — do not create new files.
    git=<ref>: determine which source files changed according to the git reference:
      - "uncommitted" → run: git diff --name-only HEAD
        (includes staged and unstaged changes)
      - A commit SHA, branch name, or HEAD notation → run:
        git diff --name-only <ref>^ <ref>   for a single commit
        git diff --name-only <range>        for a range (e.g. HEAD~3..HEAD)
      Map the changed source files to context files via their OVERVIEW sections.
    If both files= and git= are provided, take the UNION of both target sets.
    If a changed source file is not covered by any context file, flag it as
    orphaned — do not create new context files, flag only.

P.4 Report the parsed scope before doing any work:
    - The detected layout (`flat`), read from the `Layout:` marker — or that
      the marker was absent and will be backfilled as `Layout: flat`.
    - Which mode was selected and why.
    - The "Last updated" date read from INDEX.md (all modes).
    - Which git command was run and which source files it returned (Modes A and C).
    - Which context files are in scope for this update run.
    - Any unrecognized file= names or orphaned source files detected.
    - If Mode A found no changes: state this clearly, note whether a marker
      backfill will still be written, and exit without proceeding further.

If AUTO_CONFIRM is false: STOP and wait for user confirmation before proceeding.
If AUTO_CONFIRM is true: proceed immediately to Phase 1.
If the scope looks wrong and AUTO_CONFIRM is false, the user can correct the
arguments before any files are touched.

---

PHASE 1 — Assess what has changed

For each context file in scope:

1.1 Read the context file.

1.2 Read the source files listed in its OVERVIEW section.
    In Modes A and C (git-driven), prioritise reading the changed source files first;
    read others only if needed to verify cross-references or invariants.

1.3 For each section of the context file (OVERVIEW, PUBLIC API, INTERNAL PATTERNS,
    DOMAIN DEPENDENCIES, CROSS-REFERENCES, WHEN TO READ THE SOURCE), determine:
    - Is the content still accurate?
    - Is anything missing (new functions, new invariants, new dependencies)?
    - Is anything stale (removed functions, changed signatures, deleted files)?

1.4 Produce a per-file diff summary — not a git diff, but a plain-language list:
    "OVERVIEW: still accurate"
    "PUBLIC API: append_row() gained a new parameter dry_run:bool"
    "INTERNAL PATTERNS: new invariant — all writes now go through transaction wrapper"
    "CROSS-REFERENCES: new dependency on notifier.py not yet mentioned"
    etc.

Report:
- Per-file diff summary for every file in scope.
- Files where nothing changed (will be skipped in Phase 2).
- Any cross-reference breakage detected (a context file references another that
  no longer covers what it claims).

If AUTO_CONFIRM is false: STOP and wait for user confirmation before Phase 2.
If AUTO_CONFIRM is true: proceed immediately to Phase 2.

---

PHASE 2 — Update the context files

2.1 For each context file that has changes (from Phase 1):

    a) Update each stale section in place. Preserve the existing structure and
       section headings — do not rewrite sections that are still accurate.

    b) When updating PUBLIC API entries: preserve the existing format exactly.
       Add new entries, update changed ones, remove deleted ones.

    c) When updating INTERNAL PATTERNS: add new invariants, remove invalidated ones.
       Do not rephrase existing accurate entries — only touch what changed.

    d) When updating CROSS-REFERENCES: add links to any new dependencies found in
       Phase 1. Remove links to files or functions that no longer exist.

    e) When updating WHEN TO READ THE SOURCE: add new tasks that are now relevant,
       remove tasks that are no longer meaningful given the code changes.

    f) If a context file has grown beyond 150 lines after updates, flag it for
       splitting — do not split it now, flag only with a suggestion for how to
       divide it.

2.2 Do not touch context files where Phase 1 found no changes.

2.3 Do not modify any domain knowledge files (e.g. .claude/*.md outside the context
    folder, docs/, CLAUDE.md). If a code change implies a domain rule has changed,
    flag it explicitly: "This change may require updating .claude/system-design.md —
    review manually."

2.4 Update INDEX.md last:
    - Backfill the layout marker: if BACKFILL_MARKER is true (INDEX.md carried
      no `Layout:` line), insert `Layout: flat` on its own line directly under
      the title. This fires on EVERY mode, including a Mode A run that found
      nothing else to update — in that case INDEX.md is the only file written,
      and it is staged and committed on its own by Phase 3. Every layer built
      before the marker existed migrates itself this way; there is no separate
      migration command.
    - Update one-line descriptions for any files whose purpose has shifted.
    - Add entries for any new context files (there should be none in an update run —
      if you feel a new file is needed, flag it and ask the user).
    - Remove entries for any context files that were deleted (there should be none —
      flag if deletion seems warranted).
    - Update the "Last updated" timestamp to today's date in the format: YYYY-MM-DD
      This is critical — it is the anchor for the next Mode A smart update run.

Report:
- List of files updated with a summary of what changed in each.
- Whether the `Layout: flat` marker was backfilled into INDEX.md.
- List of files skipped (no changes found).
- Any files flagged for splitting.
- Any domain knowledge files that may need manual review.
- Any new context files suggested (but not created).
- Confirm the new "Last updated" date written to INDEX.md.

---

PHASE 3 — Commit and push the updated context files

/context-update auto-commits (and pushes) its work, matching /task-add
and /task-clean. This phase runs after Phase 2's report, with no
confirmation prompt of its own (it is unaffected by AUTO_CONFIRM —
committing is the default behavior). The pull-at-start already ran in
PREPARATION, before the scope was even determined.

3.0 If NO_COMMIT is true, skip committing (and pushing) entirely: the
    context files Phase 2 updated (plus the INDEX.md "Last updated" bump
    and any marker backfill) are left uncommitted in the working tree.
    Report what was updated and remind the user that nothing was committed
    — they should commit when ready. Do not run any git command. Then stop.

3.1 If Phase 2 modified NO files at all (e.g. Mode A found nothing to
    update AND no marker backfill was needed), make no commit (and no
    push). Do not create an empty commit. Report "Context already up to
    date — nothing committed." and stop. A marker-backfill-only run is NOT
    a no-op: INDEX.md changed, so it is staged and committed as usual.

3.2 Otherwise, stage EXACTLY the context-layer files this run wrote —
    the updated context files plus INDEX.md (whose "Last updated" line
    Phase 2 bumped, and possibly its backfilled `Layout: flat` marker).
    Build the path list explicitly from the Phase 2 "files updated" report;
    never use a catch-all (`git add -A`, `git add .`, `git add -u`). Files
    Phase 2 skipped are NOT staged.

3.3 Commit the staged paths with a single descriptive message:

    ```
    git add -- <path1> <path2> ... <.../INDEX.md>
    git commit -m "Update context layer"
    ```

    Use a headline that names the subject (e.g.
    "Update context layer: cli, sheet" when a small, nameable set
    changed). For a backfill-only run, name that instead (e.g.
    "Add Layout marker to context index"). Keep to the repo's existing
    commit style.

3.4 On commit success, report the commit hash (`git rev-parse --short
    HEAD`). Then, unless NO_PUSH is true or this project's CLAUDE.md
    carries a `## VCS` override, re-sync (`git pull`) and `git push`.

3.5 On commit failure (e.g. a pre-commit hook rejects the commit): surface
    the exact output. Do NOT retry, amend, or use `--no-verify` /
    `--no-gpg-sign` or any hook-skipping flag. The files remain staged
    but uncommitted; tell the user.

3.6 On push failure (rejected, no upstream, no remote) or a pre-push
    conflict: surface the exact output. Never retry, never force-push. The
    commit exists locally; tell the user it needs a manual sync + push.

This phase stages ONLY the context-layer files this run modified. It
must not pull in unrelated dirty files, and it must not run
`git add -A` / `git add .` / `git add -u`.

END
