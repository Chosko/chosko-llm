# Context workflow — navigation layer for future sessions

This project ships two commands, `/context-build` and `/context-update`,
that together maintain a **navigation context layer** under
`.claude/context/`. Read this doc when touching either command, when
changing the per-context-file schema, or when reasoning about how the
context layer relates to domain docs and to `CLAUDE.md`.

## Why this exists

Without a navigation layer, Claude Code answers questions about a repo
by reading multiple full source files upfront — expensive in tokens and
slow. The navigation layer is a set of small, structured `.md` summaries
that let a future session decide which source files to actually open,
based on cheap descriptions instead of full reads.

The layer is built once with `/context-build` and kept fresh with
`/context-update` after code changes. `CLAUDE.md` gets a navigation
pointer at the top so every session enters through `INDEX.md` first.

## Scope: structure, not domain

The two layers are deliberately separate:

- **Context layer** (`.claude/context/*.md`) — describes **codebase
  structure**: what files implement which area, public APIs, internal
  patterns, where to read source. Owned and rewritten by
  `/context-build` and `/context-update`.
- **Domain layer** (e.g. `.claude/domain/*.md`, `docs/`, `CLAUDE.md`) —
  describes **business rules, workflows, design decisions, hard rules**.
  Owned by humans (or by purpose-built commands like `/task-setup`).
  The context commands cross-reference domain files but **never modify
  them**. If a code change implies a domain rule shifted, `/context-update`
  flags it for manual review rather than rewriting it.

This file itself is a domain file — it describes the context-workflow
process. It is not part of the navigation layer.

## Per-context-file schema

Every file under `.claude/context/` (except `INDEX.md`) follows the same
six sections, authored by `/context-build` and preserved by
`/context-update`:

1. **OVERVIEW** — what this area covers; lists the source files that
   implement it by relative path. This list is the anchor
   `/context-update` uses to map changed source files back to the
   context files that need updating.
2. **PUBLIC API** — functions/classes/interfaces other areas call into,
   referenced as `path::name` with inputs, outputs, side effects. No
   implementation detail.
3. **INTERNAL PATTERNS** — non-obvious invariants and conventions a
   modifier of this area must respect.
4. **DOMAIN DEPENDENCIES** — links to domain files this area enforces
   rules from, naming the rule and the file.
5. **CROSS-REFERENCES** — links to sibling context files with a one-line
   description of the interaction.
6. **WHEN TO READ THE SOURCE** — concrete tasks that require opening
   actual source rather than stopping at this context file.

Hard limits enforced by the commands:

- 150 lines per context file (split if exceeded).
- No code snippets longer than 10 lines — reference by path and name.

## INDEX.md — the entry point

`.claude/context/INDEX.md` is the cheapest possible entry. It:

- Lists every context file with a one-line description.
- Records a **`Last updated: YYYY-MM-DD`** date — the anchor for
  `/context-update`'s default smart-update mode (it diffs commits
  `--after` that date).
- Is the file `CLAUDE.md`'s navigation instruction points at.

`/context-update` rewrites the `Last updated` date on every successful
run. If the field is missing, smart-update falls back to a full update.

## `/context-build` — three-phase initial build

1. **Phase 1 — Analysis (no writes).** Discover layout, identify
   existing docs/domain files (leave untouched), find natural seams,
   propose folder layout and file list. Stops for user approval.
2. **Phase 2 — Author.** Write `INDEX.md` first as a checklist, then
   each context file using the six-section schema.
3. **Phase 3 — Wire entry-point.** Add the navigation instruction at
   the top of `CLAUDE.md` (create a minimal one if absent). Verify
   every source file is referenced from at least one context file;
   flag orphans without auto-creating files for them.

The command refuses to refactor source code and refuses to modify
existing domain files.

## `/context-update` — four modes

Run after code changes. Modes are mutually inclusive where noted:

- **MODE A — Smart (default, no args).** `git log --after=<Last updated>`
  to find changed source files, map them to context files via OVERVIEW
  sections, update only those plus INDEX. If no commits since the date,
  checks for uncommitted changes and asks; otherwise reports
  "up to date" and exits.
- **MODE B — Full (`full`).** Rewrites every context file regardless of
  git history. Also the fallback when `Last updated` is missing.
- **MODE C — Targeted (`files=<names>` and/or `git=<ref>`).**
  `files=` takes comma-separated context filenames (no path/extension).
  `git=` takes `uncommitted`, a SHA, branch, or range like `HEAD~3..HEAD`.
  When both are given, the union of target sets is updated.
- **`-y` / `--yes`** — non-interactive; skips all confirmation gates
  while still producing the same reports. Combinable with any mode.
  Mode A's "nothing to update" exit still fires under `--yes`.

Phase 1 produces a per-file plain-language diff summary
("PUBLIC API: append_row gained dry_run:bool"); Phase 2 edits sections
in place — preserving accurate sections verbatim, updating only what
changed, and refreshing `Last updated` in INDEX last. Files that grow
past 150 lines are flagged for splitting, not split automatically.

Phase 3 then **auto-commits** the run, putting `/context-update` in the
committing group alongside `/task-add` and `/task-clean` (`/context-build`
stays uncommitted-by-default). It stages exactly the context files Phase 2
wrote plus `INDEX.md` — explicit paths only, never a catch-all — and makes
one commit. If Phase 2 changed nothing it makes no commit (no empty commit).
On a non-git VCS the commit honours the `CLAUDE.md` `## VCS` mapping
(git→`cm`). Hook-skipping flags (`--no-verify`, `--amend`, `--no-gpg-sign`)
are never used; a hook failure is surfaced and the files left staged.

## Authoring discipline for these commands

- Treat `.claude/context/` as the only writable surface. Domain files
  and source code are out of scope — flag, don't edit.
- Preserve existing structure on update. The schema is part of the
  contract: future sessions rely on section names being predictable.
- The `Last updated` date is load-bearing — every `/context-update`
  run must rewrite it on success, or smart-update degrades.
- Source-file references use relative paths; sibling context refs use
  `./other.md`; canonical-doc refs use `../../`-prefixed paths (see
  `.claude/context/INDEX.md` Conventions section).

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — navigation instruction lives
  at the top; hard rules below.
- [`../context/INDEX.md`](../context/INDEX.md) — live navigation index
  for this repo, with the `Last updated` anchor.
- `commands/context-build.md`, `commands/context-update.md` — the
  command implementations.
- `tests/smoke/context-build.md`, `tests/smoke/context-update.md` —
  smoke-test checklists.
