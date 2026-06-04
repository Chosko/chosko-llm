---
name: context-update
version: 1.0.0
type: command
description: Update an existing navigation context layer after code changes, then auto-commit the context files it updated.
---

# /context-update
# Global command: updates an existing navigation context layer after code changes.
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

$ARGUMENTS

---

PREPARATION — run before anything else

P.1 Locate the context layer:
    - Look for .claude/context/INDEX.md (default location).
    - If not found, search for any INDEX.md under a .claude/ or context/ folder.
    - If still not found, abort and tell the user to run /context-build first
      to create the initial context layer.

P.2 Read INDEX.md to get:
    - The full list of context files and their one-line descriptions.
    - The "Last updated" timestamp (format: YYYY-MM-DD).
    Do not read any context files or source files yet.

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
      - If no uncommitted changes either, report "Context is up to date" and exit.
    If the "Last updated" field is missing from INDEX.md, fall back to MODE D (full).

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
    - Which mode was selected and why.
    - The "Last updated" date read from INDEX.md (all modes).
    - Which git command was run and which source files it returned (Modes A and C).
    - Which context files are in scope for this update run.
    - Any unrecognized file= names or orphaned source files detected.
    - If Mode A found no changes: state this clearly and exit without proceeding.

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
    - Update one-line descriptions for any files whose purpose has shifted.
    - Add entries for any new context files (there should be none in an update run —
      if you feel a new file is needed, flag it and ask the user).
    - Remove entries for any context files that were deleted (there should be none —
      flag if deletion seems warranted).
    - Update the "Last updated" timestamp to today's date in the format: YYYY-MM-DD
      This is critical — it is the anchor for the next Mode A smart update run.

Report:
- List of files updated with a summary of what changed in each.
- List of files skipped (no changes found).
- Any files flagged for splitting.
- Any domain knowledge files that may need manual review.
- Any new context files suggested (but not created).
- Confirm the new "Last updated" date written to INDEX.md.

---

PHASE 3 — Commit the updated context files

`/context-update` auto-commits its work, matching `/task-add` and
`/task-clean`. This phase runs after Phase 2's report, with no
confirmation prompt of its own (it is unaffected by AUTO_CONFIRM —
committing is the default behavior).

3.1 If Phase 2 modified NO files (e.g. Mode A found nothing to update, or
    every in-scope file was skipped), make no commit. Do not create an
    empty commit. Report "Context already up to date — nothing committed."
    and stop.

3.2 Otherwise, stage EXACTLY the context-layer files this run wrote —
    the updated context files plus INDEX.md (whose "Last updated" line
    Phase 2 bumped). Build the path list explicitly from the Phase 2
    "files updated" report; never use a catch-all (`git add -A`,
    `git add .`, `git add -u`). Files Phase 2 skipped are NOT staged.

3.3 Commit the staged paths with a single descriptive message:

    ```
    git add -- <path1> <path2> ... <.../INDEX.md>
    git commit -m "Update context layer"
    ```

    Use a headline that names the subject (e.g.
    "Update context layer: cli, sheet" when a small, nameable set
    changed). Keep to the repo's existing commit style.

3.4 On success, report the commit hash (`git rev-parse --short HEAD`).

3.5 On failure (e.g. a pre-commit hook rejects the commit): surface the
    exact output. Do NOT retry, amend, or use `--no-verify` /
    `--no-gpg-sign` or any hook-skipping flag. The files remain staged
    but uncommitted; tell the user.

NON-GIT VCS: if the project's CLAUDE.md carries a `## VCS` mapping
section (e.g. git→`cm` for Plastic SCM), substitute the mapped commands
for the git commands above — stage and check in only the explicit paths
this run wrote, never a catch-all.

This phase stages ONLY the context-layer files this run modified. It
must not pull in unrelated dirty files, and it must not run
`git add -A` / `git add .` / `git add -u`.

END
