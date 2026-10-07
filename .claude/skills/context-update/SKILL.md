---
name: context-update
version: 1.6.1
type: skill
description: Update an existing navigation context layer after code changes — by default only the context files the commits since INDEX.md's Last updated date touched — then commit and push what it updated. Use it after landing code a context file describes.
replaces: command:context-update
requires: skill:interaction-engine
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

SKILL.md alone covers the common path: a flat context layer, one `INDEX.md`
with every context file beside it. The nested path lives in a sibling file,
so a flat run never pays for it.

| Read this file | Exactly when |
| -------------- | ------------ |
| `../interaction-engine/references/policy.md` | Every run, at P.3. |
| `../interaction-engine/references/messages.md` | Every run, before the first gate, question or report. |
| `../interaction-engine/references/gates.md` | The policy resolved to `unattended`. |
| `./nested.md`  | PREPARATION step P.2a read `Layout: nested` from the index. |

---

PREPARATION — run before anything else

P.1 Locate the context layer:
    - Look for .claude/context/INDEX.md (default location).
    - If not found, search for any INDEX.md under a .claude/ or context/ folder.
    - If still not found, abort and tell the user to run /context-build first
      to create the initial context layer.

P.2 Read INDEX.md. Resolve the layout marker (P.2a) FIRST, before taking
    anything else from the file.
    - Flat layout: take from INDEX.md the full list of context files with
      their one-line descriptions, and the "Last updated" timestamp (format:
      YYYY-MM-DD).
    - Nested layout: the index is a router — it lists units, not context
      files, and carries no "Last updated". Do not read a date from it, and do
      not treat its absence as the missing-date fallback (that fallback is a
      flat-layout rule). `./nested.md` resolves the file list and the dates.
    - Do not read any context files or source files yet.

P.2a Detect the layout from the `Layout:` marker line only — never from
    folder counts, subdirectories or file contents:
    - `Layout: flat` → LAYOUT = flat.
    - No `Layout:` line at all → LAYOUT = flat, and set BACKFILL_MARKER = true
      (the layer predates the marker; step 2.4 adds it).
    - `Layout: nested` → LAYOUT = nested. BACKFILL_MARKER is never true here.

    If LAYOUT is nested:
    - Read `./nested.md` now and follow it for the rest of the run. It
      replaces P.2's file list, P.3's mode resolution, P.4's scope report,
      Phase 2 step 2.4 and Phase 3's staging list; everything else in this
      file still applies.
    - Do not carry on down the flat path — a half-handled nested run stamps
      dates and stages files wrongly.

    If LAYOUT is flat, never open `./nested.md` (not even speculatively);
    follow the rest of this file.

P.3 Parse $ARGUMENTS. Each flag below is optional; when present, act on it
    and strip it before parsing the rest. `-y` / `--yes`, `--no-commit` and
    `--no-push` combine with any mode.

    -y / --yes: set AUTO_CONFIRM = true.
    When AUTO_CONFIRM is true:
    - Skip all "STOP and wait for user confirmation" gates; proceed through
      PREPARATION → PHASE 1 → PHASE 2 without pausing.
    - Still produce every report (scope report, Phase 1 diff summary, Phase 2
      final report), without waiting for a response.
    - If Mode A detects no changes, still exit cleanly without asking:
      AUTO_CONFIRM never forces an update when there is nothing to update.

    --no-commit: set NO_COMMIT = true.
    PHASE 3 then skips the auto-commit (and the push — nothing was committed)
    and leaves the updated context files uncommitted.
    - Accept and strip a bare `--commit` as a silent no-op — committing is
      the default.
    - If both `--commit` and `--no-commit` appear, stop with:
      `--commit and --no-commit cannot be combined. Pick one.`

    --no-push: set NO_PUSH = true. It matters only when NO_COMMIT is false:
    skip the pull-at-start / re-sync / push steps of PHASE 3's
    commit-and-push protocol, still committing as always.

    --attended / --unattended:
    - Resolve the run's interaction policy from them, a policy handed down by
      a parent run and the project's `CLAUDE.md`, per
      `../interaction-engine/references/policy.md`, which holds their
      argument errors.
    - Under `unattended`, read `../interaction-engine/references/gates.md`.
    - Read `../interaction-engine/references/messages.md` before the first
      gate, question or report; each of them follows it.
    - A gate that passes on its own has the closing report name the PHASE 3
      commit or, under `--no-commit`, the uncommitted files.
    - `-y` keeps its own meaning: it passes this skill's confirmations for
      one run, whatever the policy.

    Pull at start, here, before determining the update scope — unless
    NO_COMMIT is true or the project's CLAUDE.md carries a `## VCS` override
    (non-git):
    - Run `git pull` on the current branch (this also keeps Mode A's
      `git log` scan current).
    - On a conflict, stop the run immediately: report the conflict output and
      tell the user to resolve manually and re-run.

    Then determine the update scope — one of four modes:

    MODE A — Smart update (DEFAULT — no arguments provided):
    1. List the source files touched by any commit since INDEX.md's
       "Last updated" date:
         git log --after="YYYY-MM-DD" --name-only --pretty=format: | sort -u
    2. Map those source files to context files via each context file's
       OVERVIEW section (it lists source files by path).
    3. Update only the mapped context files plus INDEX.
    If no commits are found since the last-updated date:
      - Check for uncommitted changes: git diff --name-only HEAD
      - If uncommitted changes exist, report them and ask the user whether to
        include them in this update run.
      - If none either, report "Context is up to date". If BACKFILL_MARKER is
        true, still run the marker backfill (see 2.4) — INDEX.md alone is
        written, staged and committed — then exit. Otherwise exit without
        writing anything.
    If the "Last updated" field is missing from INDEX.md, fall back to MODE B (full).

    MODE B — Full update (argument "full" provided):
    Update all context files in the context layer, regardless of git history.

    MODE C — Targeted update (files=<names> and/or git=<ref> provided):
    - files=<names>: comma-separated context filenames without path or
      extension (e.g. "sheet" matches .claude/context/sheet.md). Update only
      the listed files plus INDEX. Report a name matching no existing context
      file as unrecognized and skip it — do not create new files.
    - git=<ref>: find the changed source files:
      - "uncommitted" → git diff --name-only HEAD
        (includes staged and unstaged changes)
      - A commit SHA, branch name, or HEAD notation →
        git diff --name-only <ref>^ <ref>   for a single commit
        git diff --name-only <range>        for a range (e.g. HEAD~3..HEAD)
      Map the changed source files to context files via their OVERVIEW sections.
    - If both files= and git= are provided, take the UNION of both target sets.
    - Flag a changed source file covered by no context file as orphaned — do
      not create new context files, flag only.

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

    Then:
    - If AUTO_CONFIRM is false: STOP and wait for user confirmation before
      proceeding (gate class: `confirmation`). The user can correct the
      arguments here, before any files are touched.
    - If AUTO_CONFIRM is true: proceed immediately to Phase 1.

---

PHASE 1 — Assess what has changed

For each context file in scope:

1.1 Read the context file.

1.2 Read the source files listed in its OVERVIEW section. In Modes A and C
    (git-driven), read the changed source files first; read others only if
    needed to verify cross-references or invariants.

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

Then:
- If AUTO_CONFIRM is false: STOP and wait for user confirmation before Phase 2
  (gate class: `confirmation`).
- If AUTO_CONFIRM is true: proceed immediately to Phase 2.

---

PHASE 2 — Update the context files

2.1 For each context file that has changes (from Phase 1):

    a) Update each stale section in place. Preserve the existing structure and
       section headings; do not rewrite sections that are still accurate.

    b) PUBLIC API: preserve the existing format exactly. Add new entries,
       update changed ones, remove deleted ones.

    c) INTERNAL PATTERNS: add new invariants, remove invalidated ones. Do not
       rephrase existing accurate entries — touch only what changed.

    d) CROSS-REFERENCES: add links to any new dependencies found in Phase 1.
       Remove links to files or functions that no longer exist.

    e) WHEN TO READ THE SOURCE: add new tasks that are now relevant, remove
       tasks no longer meaningful given the code changes.

    f) If a context file has grown beyond 150 lines after updates, flag it for
       splitting with a suggestion for how to divide it — do not split it now.

    g) A test context file — one whose subject is a test tree rather than
       source code (`<unit>-tests.md`) — carries two kinds of content and no
       third, in its existing sections:
       - **Placement and running** (its layout section): where a test of each
         kind goes, the directory layout, the shared helpers and fixtures a new
         test should reuse, and how the suite runs.
       - **Tripwires** (WHEN TO READ THE SOURCE): a test that pins something
         an unrelated-looking change will break. One entry names the test file
         and says in a line what change trips it and why.
       - Never catalogue what each test asserts: the `describe`/`it` names
         answer that through grep, and are never stale.
       - Give a new or changed test an entry only when it is a tripwire or
         changes a placement rule, a shared helper or a fixture; a test that
         only adds coverage earns none.
       - Remove, rather than update, a catalogue line found in the file.
       - Describe the file's row in its index in the same terms, never as a
         list of the suites it covers.

2.2 Do not touch context files where Phase 1 found no changes.

2.3 Do not modify any domain knowledge files (e.g. .claude/*.md outside the
    context folder, docs/, CLAUDE.md). If a code change implies a domain rule
    has changed, flag it explicitly: "This change may require updating
    .claude/system-design.md — review manually."

2.4 Update INDEX.md last:
    - Backfill the layout marker: if BACKFILL_MARKER is true (INDEX.md carried
      no `Layout:` line), insert `Layout: flat` on its own line directly under
      the title. Do this on EVERY mode, including a Mode A run that found
      nothing else to update — then INDEX.md is the only file written, and
      Phase 3 stages and commits it on its own. There is no separate
      migration command.
    - Update one-line descriptions for any files whose purpose has shifted.
    - Add entries for any new context files (there should be none in an update
      run — if a new file seems needed, flag it and ask the user).
    - Remove entries for any context files that were deleted (there should be
      none — flag if deletion seems warranted).
    - Update the "Last updated" timestamp to today's date in the format:
      YYYY-MM-DD. This is critical — it is the anchor for the next Mode A
      smart update run.

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

Run this phase after Phase 2's report, with no confirmation prompt of its
own and unaffected by AUTO_CONFIRM — committing (and pushing) is the default.
The pull-at-start already ran in PREPARATION.

3.0 If NO_COMMIT is true, skip committing (and pushing) entirely:
    - Leave the context files Phase 2 updated (plus the INDEX.md "Last
      updated" bump and any marker backfill) uncommitted in the working tree.
    - Report what was updated and remind the user that nothing was committed
      — they should commit when ready.
    - Do not run any git command. Then stop.

3.1 If Phase 2 modified NO files at all (e.g. Mode A found nothing to update
    AND no marker backfill was needed), make no commit (and no push) — never
    an empty commit. Report "Context already up to date — nothing committed."
    and stop. A marker-backfill-only run is NOT a no-op: INDEX.md changed, so
    stage and commit it as usual.

3.2 Otherwise, stage EXACTLY the context-layer files this run wrote — the
    updated context files plus INDEX.md (its bumped "Last updated" line, and
    possibly its backfilled `Layout: flat` marker).
    - Build the path list explicitly from the Phase 2 "files updated" report.
    - Never use a catch-all (`git add -A`, `git add .`, `git add -u`); never
      pull in unrelated dirty files.
    - Do NOT stage files Phase 2 skipped.

3.3 Commit the staged paths with a single descriptive message:

    ```
    git add -- <path1> <path2> ... <.../INDEX.md>
    git commit -m "Update context layer"
    ```

    - Use a headline that names the subject (e.g.
      "Update context layer: cli, sheet" when a small, nameable set changed).
    - For a backfill-only run, name that instead (e.g.
      "Add Layout marker to context index").
    - Keep to the repo's existing commit style.

3.4 On commit success, report the commit hash (`git rev-parse --short
    HEAD`). Then, unless NO_PUSH is true or this project's CLAUDE.md
    carries a `## VCS` override, re-sync (`git pull`) and `git push`.

3.5 On commit failure (e.g. a pre-commit hook rejects the commit): surface
    the exact output. Do NOT retry, amend, or use `--no-verify` /
    `--no-gpg-sign` or any hook-skipping flag. Tell the user the files
    remain staged but uncommitted.

3.6 On push failure (rejected, no upstream, no remote) or a pre-push
    conflict: surface the exact output. Never retry, never force-push. Tell
    the user the commit exists locally and needs a manual sync + push.

END
