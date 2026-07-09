---
name: refactor-codebase
version: 0.2.1
type: command
description: Refactor a codebase by applying clean-code principles — extract constants/enums, eliminate duplication, split oversized files, clean imports, and rename ambiguous identifiers — without changing observable behaviour. Plan-first, phase-gated, test-suite-protected. Supports scope= and focus= arguments to limit the work, and --commit to commit the result (default leaves it uncommitted).
---

# /refactor-codebase
# Global command: refactors a codebase applying clean code principles.
# Splits oversized files, eliminates duplication, extracts constants/enums,
# and improves overall structure — without changing any observable behaviour.
#
# Usage — refactor everything:
#   /refactor-codebase
#
# Usage — refactor only specific files or areas:
#   /refactor-codebase scope=main,filters
#
# Usage — refactor only a specific concern:
#   /refactor-codebase focus=constants     # only extract hardcoded values
#   /refactor-codebase focus=splitting     # only split oversized files
#   /refactor-codebase focus=duplication   # only deduplicate repeated logic
#
# Parameters can be combined:
#   /refactor-codebase scope=main focus=splitting,constants
#
# Usage — commit the refactor when done (default leaves it uncommitted):
#   /refactor-codebase --commit

$ARGUMENTS

---

PRIME DIRECTIVE
This is a pure refactoring task. Observable behaviour must not change.
Every function, command, and integration must work exactly as before.
The test suite must pass before and after every phase.
If tests do not exist or do not pass before you start, stop and report — do not proceed.

---

PREPARATION — run before anything else

P.1 Run the test suite. Record the result (pass count, fail count, coverage if available).
    If any tests fail before refactoring begins, stop and report. Do not proceed until
    the baseline is green.

P.2 Parse $ARGUMENTS:

    scope=<names> — comma-separated list of file or module names to limit the refactor to.
    Names are matched without path or extension (e.g. "main" matches src/main.py).
    If scope= is not provided, all source files are in scope.

    focus=<concerns> — comma-separated list of refactoring concerns to apply.
    Valid values:
      constants    — extract hardcoded strings, magic numbers, status values, and
                     lookup tables into enums, dataclasses, or constants modules.
      splitting    — split files that exceed a reasonable size threshold (default: 300
                     lines) into focused, single-responsibility modules.
      duplication  — identify and extract repeated logic into shared functions or
                     utility modules.
      imports      — clean up unused imports, enforce consistent import ordering.
      naming       — rename identifiers that are ambiguous, misleading, or inconsistent
                     with the rest of the codebase conventions.
    If focus= is not provided, apply all five concerns.

    --commit (optional flag) — if present, set COMMIT = true; the refactor
    is committed at the end (see PHASE 6). `--commit` and `--no-commit` are
    mutually exclusive — if both appear, stop with:
    `--commit and --no-commit cannot be combined. Pick one.` When COMMIT is
    false (the default), the run leaves all changes uncommitted, as before.

P.3 Locate the context layer (e.g. .claude/context/INDEX.md) if it exists.
    Read INDEX.md to understand the current module map — do not read context files
    or source files yet.

P.4 Read only the source files that are in scope (per P.2). Do not read files outside
    scope unless needed to understand a shared dependency.

P.5 Produce a refactoring plan — no code changes yet. The plan must list every
    proposed change grouped by concern, in the order they will be executed. For each
    proposed change:

    - Title: short description (e.g. "Extract StatusValue enum from main.py")
    - Concern: which focus area this belongs to
    - Files affected: which files will be created, modified, or deleted
    - Rationale: why this change improves the code (one sentence)
    - Risk: LOW / MEDIUM / HIGH — likelihood of subtle behaviour change
      (HIGH = touches control flow, external API calls, or shared state)
    - Preconditions: other plan items that must be completed first

    Flag any proposed change rated HIGH risk separately at the end of the plan
    for explicit user approval.

P.6 Estimate the impact on file sizes: for each file being split, show current line
    count and projected line count of each resulting file.

Report the full plan. STOP and wait for user approval before writing any code.
If the user requests changes to the plan, revise and re-report before proceeding.

---

PHASE 1 — Extract constants, enums, and static data structures

Execute only if "constants" is in focus scope.

1.1 Identify all hardcoded values that should be symbolic:
    - String literals that represent domain vocabulary (status values, dropdown labels,
      column names, source names, command names, log prefixes, notification templates)
    - Magic numbers (column indices, size thresholds, timeout values, retry counts)
    - Repeated string patterns used in more than one place
    - Dictionary or list literals that encode domain rules (e.g. lists of valid statuses,
      sets of AI-writable vs human-only statuses)

1.2 For each group of related constants, choose the appropriate structure:
    - Use Enum (or StrEnum in Python 3.11+) for closed vocabularies where exhaustiveness
      matters and values are compared or iterated (e.g. ApplicationStatus, RemoteType)
    - Use a dataclass or NamedTuple for structured records with multiple fields
    - Use module-level constants (ALL_CAPS) for simple scalar values
    - Use a frozen dict or tuple for lookup tables that are read but never mutated
    Choose the simplest structure that makes invalid states unrepresentable.

1.3 Create a dedicated constants or enums module (e.g. src/constants.py or
    src/enums.py). If the project already has one, extend it rather than creating
    a new file. If the volume warrants it, split into src/enums.py (Enum types)
    and src/constants.py (scalar constants and lookup tables).

1.4 Replace all hardcoded occurrences throughout the codebase with references to
    the new symbols. Do not leave any unreplaced instances of the extracted values.

1.5 Update any isinstance checks, match statements, or string comparisons that
    now operate on Enum members to use the Enum correctly (e.g. status == StatusValue.EXPIRED
    rather than status == "6c - Expired").

1.6 Run the test suite. All tests must pass before proceeding to Phase 2.
    If any test fails, fix it before continuing — do not proceed with a red suite.

Report:
- New files created and their contents summary.
- Count of replaced occurrences per constant/enum.
- Test result after phase.

---

PHASE 2 — Eliminate duplication

Execute only if "duplication" is in focus scope.

2.1 Identify repeated logic: code blocks that appear in two or more places and
    perform the same operation (even if not identical character-for-character).
    Common patterns to look for:
    - Row eligibility checks repeated across commands
    - URL normalization applied in multiple places
    - Sheet read-then-filter patterns repeated per command
    - Notification construction duplicated across event types
    - Error handling boilerplate repeated in multiple functions
    - Logging setup duplicated across modules

2.2 For each duplication found:
    - Extract to a shared function in the most appropriate existing module.
    - If no existing module is the right home, create a src/utils.py or
      src/helpers.py for general-purpose utilities — but prefer placing extracted
      functions in the module most closely related to their concern.
    - Name extracted functions for what they do, not where they came from.

2.3 Replace all call sites with calls to the extracted function.

2.4 Run the test suite. All tests must pass before proceeding to Phase 3.

Report:
- Extractions performed: function name, source locations, destination.
- Test result after phase.

---

PHASE 3 — Split oversized files

Execute only if "splitting" is in focus scope.

3.1 List all files in scope that exceed 300 lines (or the threshold specified in the
    plan). For each, identify the natural split boundaries — groups of functions or
    classes that form a coherent sub-responsibility.

3.2 For each file to be split:

    a) Propose the new file names and what each will contain before splitting.
       Each new file must have a single clear responsibility expressible in one sentence.

    b) Split the file. Move functions/classes to their new homes. Do not copy — move.

    c) Update all import statements across the codebase to reference the new locations.
       Search for every import of the original module and update it.

    d) Keep the original filename as a thin re-export shim ONLY if it is part of a
       public API that external code depends on. If the file is purely internal,
       delete it after moving its contents and update all imports directly.

    e) Do not change function signatures, return types, or logic during a split.
       A split is purely a relocation — no behaviour changes.

3.3 Run the test suite after each file split. Do not batch multiple splits before
    testing — split one file, run tests, confirm green, then proceed to the next.

Report:
- Per-split: original file, new files created, line counts before and after.
- Test result after each split.

---

PHASE 4 — Clean up imports and naming

Execute only if "imports" or "naming" is in focus scope.

4.1 Imports (if in scope):
    - Remove unused imports in all in-scope files.
    - Enforce consistent ordering: standard library → third-party → local, each group
      alphabetically sorted.
    - Replace star imports (from x import *) with explicit imports.
    - Replace redundant aliasing (import numpy as numpy) with direct imports.

4.2 Naming (if in scope):
    - Identify identifiers that are ambiguous, misleading, abbreviated without
      reason, or inconsistent with naming conventions used elsewhere in the codebase.
    - Propose renames in the Phase 1 plan output. Only apply renames that were
      approved in the plan — do not rename opportunistically during this phase.
    - When renaming: update every reference across the codebase including tests,
      context files, and comments.

4.3 Run the test suite. All tests must pass.

Report:
- Imports cleaned per file.
- Renames applied with old name → new name and files updated.
- Test result after phase.

---

PHASE 5 — Update context layer and documentation

5.1 If a .claude/context/ layer exists, update every context file whose covered
    source files were modified, split, or renamed. Apply the same rules as
    /update-context: update in place, preserve accurate sections, do not touch
    domain knowledge files.

5.2 Update INDEX.md to reflect any new files created or old files removed.
    Add a last-updated timestamp.

5.3 If CLAUDE.md references specific file paths or module names that have changed,
    update those references. Do not rewrite CLAUDE.md — only fix stale paths.

5.4 Run the full test suite one final time. Report the final result.

---

FINAL REPORT

Produce a summary covering:
- Total files modified, created, and deleted.
- Before/after line counts for every file that changed size significantly (>20%).
- Constants/enums extracted: count and names.
- Duplications eliminated: count and extraction targets.
- Files split: original → resulting files.
- Test suite result: pass count before refactor vs pass count after.
- Any HIGH-risk changes that were deferred (not applied) and why.
- Any technical debt spotted but not addressed (flag only — do not fix unless
  it was in the approved plan).

---

PHASE 6 — Commit (only when `--commit` was passed)

If COMMIT is false (the default), do nothing here — the refactor is left
uncommitted for the user to review. This is the default behavior and is
unchanged.

If COMMIT is true, after the final green test suite (PHASE 5 / FINAL
REPORT):

1. If the run modified nothing (e.g. the plan was empty or every change
   was deferred), make no commit. Say so and stop.
2. Stage EXACTLY the paths this run created, modified, or deleted —
   the source files refactored, any new constants/enums/utils modules,
   the updated context-layer files and INDEX.md, and any CLAUDE.md path
   fixes from PHASE 5. Build the path list explicitly from the FINAL
   REPORT; use `git add -- <path>` (which records deletions too). Never
   use a catch-all (`git add -A` / `git add .` / `git add -u`).
3. Commit once with a message naming the refactor, e.g.
   `git commit -m "Refactor: extract constants, split oversized modules"`
   — tailor the subject to the concerns actually applied. Keep to the
   repo's existing commit style.
4. On success, report the commit hash (`git rev-parse --short HEAD`).
5. On failure (e.g. a pre-commit hook rejects the commit): surface the
   exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.

END
