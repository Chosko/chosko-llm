---
name: domain-setup
version: 0.1.0
type: command
description: Initialize the project's domain knowledge layer — creates .claude/domain/, .claude/domain/features/, a .claude/domain/INDEX.md that indexes any pre-existing domain docs, the .claude/FEATURES.md feature index, and a CLAUDE.md pointer to the domain index. Idempotent and re-runnable on projects that already have hand-written domain docs. Authoring command — leaves everything uncommitted for review by default; pass --commit to commit the scaffolding.
---

# /domain-setup
# Global command: initialize the project's domain knowledge layer. Creates
# `.claude/domain/` and `.claude/domain/features/`, a
# `.claude/domain/INDEX.md` navigation index, the `.claude/FEATURES.md`
# feature index, and a CLAUDE.md pointer at the domain index. Idempotent: a
# re-run leaves existing artifacts untouched and only creates the missing
# ones. Safe on a project that already has hand-written domain docs — those
# get indexed rather than replaced.
# Usage: /domain-setup            (leaves the scaffolding uncommitted)
# Usage: /domain-setup --commit   (commit the scaffolding this run wrote)

GOAL
Make the domain layer structural. `.claude/domain/` holds the project's
product and rules knowledge — what the product is, how its features are
designed, why the architecture is what it is. It is read by `/task-add` and
`/task-enrich`, deliberately never written by `/context-build` or
`/context-update`, and until now created by nothing at all: every project
that has one grew it by hand, with no index and no entry-point pointer.
`/product-design` and `/architect` both write into it, so it must exist and
be navigable first.

Create the artifacts the rest of the product pipeline assumes:

1. `.claude/domain/` — the domain layer directory.
2. `.claude/domain/features/` — one document per low-level feature, written
   later by `/architect`.
3. `.claude/domain/INDEX.md` — the domain-layer navigation index: a
   `| File | Covers |` table matching the shape of
   `.claude/context/INDEX.md`. On a project that already has hand-written
   domain docs, they are indexed here.
4. `.claude/FEATURES.md` — the feature index, a sibling of `TASKS.md`. It
   indexes work items the way `TASKS.md` does, which is why it sits at the
   `.claude/` root rather than inside `domain/`; the feature *documents* it
   points at are knowledge, so those live under `.claude/domain/features/`.
5. A CLAUDE.md navigation pointer at `.claude/domain/INDEX.md`.

This command is the gate for `/product-design` and `/architect`. It creates
the layer and nothing in it: no feature entries, no design documents.

By default this is a pure authoring command: it writes the scaffolding and
leaves everything uncommitted in the working tree, matching `/task-setup`,
`/context-build`, and `/project-setup`. The user reviews and commits when
ready. Passing `--commit` opts in to committing exactly what this run wrote
(see PHASE — COMMIT below).

This command shells out for exactly two things: filesystem prep (`mkdir -p`
for `.claude/domain` and `.claude/domain/features`) and, ONLY when
`--commit` is passed, the commit step. Without `--commit`, it runs NO
git/VCS command.

$ARGUMENTS

---

WORKFLOW

Before anything else, parse $ARGUMENTS for the optional `--commit` flag.
If present, set COMMIT = true. `--commit` and `--no-commit` are mutually
exclusive — if both appear, stop with:
`--commit and --no-commit cannot be combined. Pick one.` When COMMIT is
false (the default), the run leaves its scaffolding uncommitted.

Each artifact is checked individually and created only if missing. Never
overwrite an existing artifact without explicit user confirmation —
re-running `/domain-setup` on a partially or fully initialized project must
be idempotent.

Throughout the run, maintain a `WRITTEN` list of paths actually written or
overwritten this invocation. Each successful Write / `mkdir -p` (when the
directory did not previously exist) appends to it; idempotent no-ops do
not. `WRITTEN` drives the final report in step 4 and the optional commit in
PHASE — COMMIT.

1. **Probe every artifact:**
   - `.claude/domain/` — use Glob `.claude/domain/*` or list it.
   - `.claude/domain/features/` — use Glob `.claude/domain/features/*`.
   - `.claude/domain/INDEX.md` — use the Read tool; "file not found" means
     it does not exist.
   - `.claude/FEATURES.md` — use the Read tool.
   - `CLAUDE.md` — use the Read tool. Note whether it exists and whether it
     already carries a pointer at `.claude/domain/INDEX.md`.

2. **Inventory any pre-existing domain docs.** Glob
   `.claude/domain/**/*.md` (excluding `INDEX.md` itself). The near-term
   users of this command are existing projects, so a non-empty result is
   the expected case, not an edge case. For each file found, read its
   heading and opening paragraph — enough for one "Covers" cell, no more.
   Do not read them in full and do not modify them.

3. **Create whichever artifacts are missing:**
   - If `.claude/domain/` is missing, create it
     (`mkdir -p .claude/domain`).
   - If `.claude/domain/features/` is missing, create it
     (`mkdir -p .claude/domain/features`).
   - If `.claude/domain/INDEX.md` is missing, use the Write tool to create
     it from the **DOMAIN INDEX TEMPLATE** below, with one table row per
     document inventoried in step 2. When step 2 found nothing, write the
     table header with no rows — never invent rows for documents that do
     not exist.
   - If `.claude/FEATURES.md` is missing, use the Write tool to create it
     with the exact stub in the **FEATURES.md STUB** below. No entries.
   - If CLAUDE.md carries no pointer at `.claude/domain/INDEX.md`, add one
     per **CLAUDE.md POINTER** below. If CLAUDE.md does not exist at all,
     create a minimal one containing just that pointer — the same fallback
     `/context-build` uses.

4. **Report to the user:**
   - For each artifact: created (with path) or already present.
   - If everything already existed and no pointer was needed, say "Domain
     layer already initialized." and write nothing.
   - When step 2 found pre-existing docs, list which ones were indexed.
   - If anything was created, hint at the usable next steps:
     `/product-design` to design the product top-down, or `/architect`
     to go straight to a feature document on a project whose direction is
     already settled.
   - If `WRITTEN` is non-empty and `--commit` was NOT passed, close with an
     explicit reminder that nothing was committed — the scaffolding is left
     in the working tree for the user to review and commit when ready.

5. **Continue to PHASE — COMMIT.**

---

DOMAIN INDEX TEMPLATE

Write `.claude/domain/INDEX.md` in this shape. The `| File | Covers |`
table matches `.claude/context/INDEX.md` so the two layers read the same
way:

```
# Domain index

Product and rules knowledge for <project name>. Read this first, then the
files relevant to your task.

This layer answers WHAT the product is and WHY it is built this way. For
CODEBASE STRUCTURE — which file implements what — see
[../context/INDEX.md](../context/INDEX.md) if the project has a context
layer.

## Files

| File | Covers |
| --- | --- |
| [<name>.md](./<name>.md) | <one line, from the document's heading and opening paragraph> |

## Features

Low-level feature documents live under [features/](./features/), one per
feature, written by `/architect`. The feature index — status and generated
task IDs per feature — is [../FEATURES.md](../FEATURES.md).
```

One row per document found in step 2, in alphabetical order. Write the
"Covers" cell from what the document actually says; if a file's subject
cannot be summarized from its heading and opening paragraph, say so in the
report rather than guessing in the table.

---

FEATURES.md STUB

Write `.claude/FEATURES.md` with exactly this content:

```
# Features
```

No entries. Entries are appended by `/architect`, one per feature, in this
shape (documented here for reference — this command never writes one):

```
---

## <slug> — <one-line title>

Status: [NEW]
Doc: .claude/domain/features/<slug>.md
Source: product-design.md § <section>
Tasks: none

---
```

`Status:` is one of `[NEW]` / `[ITERATED]` / `[PLANNED]`. There is no
`Last feature number` counter and no numeric IDs — slugs are the
identifiers, so there is nothing to count.

---

CLAUDE.md POINTER

The pointer must be explicit about when to read the layer:

> For product and domain knowledge — what this product is, how its
> features are designed, and why the architecture is what it is — read
> `.claude/domain/INDEX.md`, then only the domain files relevant to your
> task.

Compose it with what is already there; do not duplicate or overwrite:

- If CLAUDE.md already has a navigation instruction from `/context-build`
  (pointing at `.claude/context/INDEX.md`), add the domain pointer
  alongside it under the same navigation heading, and make the division of
  labour explicit — context = codebase structure, domain = product and
  rules.
- If CLAUDE.md exists with no navigation section, add the pointer near the
  top, before project-specific detail.
- If CLAUDE.md does not exist, create a minimal one containing only this
  pointer.
- If a pointer at `.claude/domain/INDEX.md` is already present in any
  form, leave CLAUDE.md alone entirely — this is the idempotent case.

---

PHASE — COMMIT (only when `--commit` was passed)

If COMMIT is false (the default), do nothing here — the scaffolding is left
uncommitted for the user to review.

If COMMIT is true:

1. If `WRITTEN` is empty (a fully idempotent re-run that wrote nothing),
   make no commit. Say so and stop — no empty commit.
2. Otherwise, stage EXACTLY the paths in `WRITTEN` and commit them:

   ```
   git add -- <path1> <path2> ...      # exactly the entries of WRITTEN
   git commit -m "Initialize domain knowledge layer"
   ```

   Stage ONLY the entries of `WRITTEN`. Never use `git add -A`,
   `git add .`, or `git add -u`. On a non-git VCS, use the project's
   `## VCS` mapping in CLAUDE.md (git→`cm`).
3. On success, report the commit hash (`git rev-parse --short HEAD`).
4. On failure (e.g. a pre-commit hook rejects the commit): surface the
   exact output. Do NOT retry, amend, or use `--no-verify` /
   `--no-gpg-sign`. Files remain staged but uncommitted; tell the user.

---

DO NOT:
- Create any feature entries in `.claude/FEATURES.md`. This command creates
  the empty index; entries are `/architect`'s to write.
- Create any design or feature documents — no `product-design.md`, no
  `business-model.md`, no `features/<slug>.md`. Those belong to
  `/product-design` and `/architect`. `/domain-setup` scaffolds the layer,
  never its contents.
- Overwrite or edit an existing domain document, an existing
  `.claude/domain/INDEX.md`, or an existing `.claude/FEATURES.md`. These
  are hand-written knowledge; treat them as canonical. Index them, never
  clobber them.
- Duplicate an existing CLAUDE.md navigation instruction, or replace the
  `/context-build` context-layer pointer with this one. The two layers are
  separate and both pointers coexist.
- Write anything into `.claude/context/`. The context layer is
  `/context-build`'s and `/context-update`'s; this command only
  cross-references it.
- Run any git/VCS command UNLESS `--commit` was passed. By default
  `/domain-setup` writes scaffolding and leaves everything uncommitted —
  committing is the user's job. With `--commit`, make exactly one commit of
  the `WRITTEN` paths; never push, branch, tag, or use hook-skipping flags
  (`--no-verify`, `--no-gpg-sign`, `--amend`), and never stage with a
  catch-all (`git add -A` / `git add .` / `git add -u`).
