---
name: context-build
version: 0.2.0
type: command
description: Build a navigation context layer to reduce token cost in future Claude Code sessions. Pass --commit to commit the context layer; default leaves it uncommitted.
---

# /context-build
# Global command: introduces a navigation layer of context files to reduce token cost
# in future Claude Code sessions on any project.
# Usage: /context-build
# Usage with hint: /context-build "source code lives under lib/ not src/"
# Usage with commit: /context-build --commit   (commit the context layer when done)

GOAL
Reduce token cost in future Claude Code sessions on this repo by introducing a
navigation layer of context files. The current cost driver is that Claude Code reads
multiple full source files upfront to answer questions or plan changes. The navigation
layer should let future Claude Code sessions decide which source files to read on
demand, based on cheap summaries.

$ARGUMENTS

ARGUMENT NOTE — before Phase 1, scan $ARGUMENTS for the optional `--commit`
flag. If present, set COMMIT = true and strip it (the remaining text, if
any, is a structure hint). `--commit` and `--no-commit` are mutually
exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.`
When COMMIT is false (the default), the run leaves all output uncommitted,
exactly as before.

CONSTRAINTS
- Do not refactor any source code.
- Do not modify CLAUDE.md until Phase 3 — that comes at the end as the entry-point update.
- The new context files describe CODEBASE STRUCTURE only — not the project's business
  domain or rules.
- If domain knowledge files already exist (e.g. a .claude/ folder with .md files,
  a docs/ folder, or similar), leave them untouched. Treat them as canonical and
  cross-reference them from context files where relevant, but do not modify them.
- If a CLAUDE.md or equivalent entry-point file does not exist, create a minimal one
  as part of Phase 3.

YOUR TASK — three phases. Stop at the end of each phase and report before continuing.

---

PHASE 1 — Analysis (no files written yet)

1.1 Discover the project layout:
    - Identify the language(s) and primary source directories.
    - Identify any existing documentation, context, or knowledge folders
      (e.g. .claude/, docs/, context/, CLAUDE.md, README.md).
    - Identify the test layout and config files.
    - If $ARGUMENTS provides hints about the project structure, apply them.

1.2 Read the entry-point file (CLAUDE.md or equivalent) if it exists, plus any
    existing context or domain files. Do not read full source files yet.

1.3 Identify the natural seams in the codebase — modules, layers, or feature areas
    that are cohesive internally but have clear interfaces to the rest of the system.
    Infer seams from filenames, directory structure, and import relationships where
    possible before opening full source files.

1.4 For each seam, decide whether it warrants its own context file. The criterion:
    would a future Claude Code session, asked to modify only that area, benefit from
    reading a focused summary instead of opening every source file in the project?

1.5 Decide on a folder layout. The default is .claude/context/<area>.md. Propose a
    different structure only if the project's existing conventions make the default
    a poor fit — and justify the alternative in one paragraph.

1.6 Decide a cross-reference convention. Each context file should link to related
    context files and relevant domain files by relative path, so Claude Code can
    chain reads without loading everything.

1.7 Decide on a top-level index file (default: .claude/context/INDEX.md) that lists
    every context file with a one-line description. This is the cheapest possible
    entry point for future sessions.

Report:
- Summary of discovered project layout (languages, source dirs, existing context files).
- Proposed folder layout with rationale.
- List of context files you intend to create, each with a one-line description.
- Cross-reference convention you will use.
- Estimated total size of the context layer in lines.

STOP and wait for user approval before Phase 2.

---

PHASE 2 — Author the context files

2.1 Create the context folder and the INDEX file first. INDEX must list every planned
    context file even before they exist, so it can be used as a checklist.

2.2 Create each context file. Every file must contain:

    a) OVERVIEW — what this area covers and which source files implement it.
       List files by relative path.

    b) PUBLIC API — the functions, classes, or interfaces that other areas of the
       codebase call into this one. For each: name, inputs, outputs, and side effects.
       Reference by fully-qualified name (e.g. src/sheet.py::append_row).
       Do not include implementation detail — only the contract.

    c) INTERNAL PATTERNS — non-obvious conventions, invariants, or constraints that
       anyone modifying this area must know. Examples: "all writes go through X to
       enforce the tab-lock rule," "URL normalization happens here and nowhere else."

    d) DOMAIN DEPENDENCIES — links to domain knowledge files (e.g. .claude/*.md,
       docs/) that define rules this area enforces. State which rule and which file.

    e) CROSS-REFERENCES — links to other context files this area interacts with,
       with a one-line description of the interaction.

    f) WHEN TO READ THE SOURCE — a concrete list of tasks that would require opening
       the actual source files, rather than stopping at this context file. Be specific:
       "modifying the dedup normalization logic in is_duplicate()" rather than
       "changing filters."

2.3 Each context file must be under 150 lines. If a file would exceed that, split it
    into two focused files and update INDEX accordingly.

2.4 Do not include code snippets longer than 10 lines. Reference source by path and
    function name rather than reproducing implementation.

2.5 Update INDEX to mark each file as complete as you go.

Report:
- Files created with line counts.
- Any area where the codebase resisted summarization (a signal for future refactoring,
  but do not refactor now — flag only).

STOP and wait for user approval before Phase 3.

---

PHASE 3 — Wire the entry point

3.1 Update CLAUDE.md (or the project's equivalent entry-point file) to add a
    navigation instruction at the top. The instruction must be explicit:

    "For any task involving the codebase, start by reading .claude/context/INDEX.md
    (or the equivalent index path for this project). Then read only the context files
    relevant to your task. Open source files only when the relevant context file's
    'When to read the source' section indicates it is necessary."

    If CLAUDE.md does not exist, create a minimal one containing only this instruction
    plus the index path.

3.2 Verify that every source file in the project is referenced from at least one
    context file. If any source file is orphaned (not mentioned anywhere in the
    context layer), flag it by name and suggest which context file should cover it.
    Do not create new context files to cover orphans — flag only.

3.3 Verify that INDEX.md is complete and accurate: every context file exists, every
    one-line description matches the file's actual content.

Report:
- The exact changes made to CLAUDE.md (show as a diff or before/after).
- Any orphaned source files and suggested home context file for each.
- A validation checklist the user can run manually to confirm the navigation layer
  works as intended. Example items:
    * "Ask Claude Code 'how does [feature X] work?' — it should read INDEX, then
      the relevant context file, and open source only if the task requires it."
    * "Ask Claude Code to modify [function Y] — confirm it reads the correct context
      file before opening src/."

---

PHASE 4 — Commit (only when `--commit` was passed)

If COMMIT is false (the default), do nothing here — the context layer is
left uncommitted for the user to review. This is the default behavior and
is unchanged.

If COMMIT is true, after Phase 3 completes:

1. If the run wrote nothing (e.g. it was aborted before Phase 2), make no
   commit. Say so and stop.
2. Stage EXACTLY the files this run wrote — `.claude/context/INDEX.md`,
   every context file created in Phase 2, and CLAUDE.md (the Phase 3
   entry-point edit, or a newly created CLAUDE.md). Build the path list
   explicitly; never use a catch-all (`git add -A` / `git add .` /
   `git add -u`).
3. Commit once: `git commit -m "Add navigation context layer"`.
4. On success, report the commit hash (`git rev-parse --short HEAD`).
5. On failure (e.g. a pre-commit hook rejects the commit): surface the
   exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.

NON-GIT VCS: if the project's CLAUDE.md carries a `## VCS` mapping section
(e.g. git→`cm` for Plastic SCM), substitute the mapped commands, staging
and checking in only the explicit paths this run wrote.

END
