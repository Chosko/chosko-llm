# Context workflow — navigation layer for future sessions

Project ship two commands, `/context-build` and `/context-update`, together maintain **navigation context layer** under `.claude/context/`. Read doc when touching either command, changing per-context-file schema, or reasoning how context layer relate to domain docs and `CLAUDE.md`.

## Why this exists

Without navigation layer, Claude Code answer questions about repo by reading multiple full source files upfront — expensive tokens, slow. Navigation layer: set of small, structured `.md` summaries let future session decide which source files actually open, based on cheap descriptions instead of full reads.

Layer built once with `/context-build`, kept fresh with `/context-update` after code changes. `CLAUDE.md` get navigation pointer at top so every session enter through `INDEX.md` first.

## Scope: structure, not domain

Two layers deliberately separate:

- **Context layer** (`.claude/context/*.md`) — describes **codebase structure**: what files implement which area, public APIs, internal patterns, where read source. Owned, rewritten by `/context-build` and `/context-update`.
- **Domain layer** (e.g. `.claude/domain/*.md`, `docs/`, `CLAUDE.md`) — describes **business rules, workflows, design decisions, hard rules**. Owned by humans (or purpose-built commands like `/task-setup`). Context commands cross-reference domain files but **never modify them**. Code change imply domain rule shifted → `/context-update` flags for manual review, no rewrite.

This file itself domain file — describes context-workflow process. Not part of navigation layer.

## Per-context-file schema

Every file under `.claude/context/` (except `INDEX.md`) follow same six sections, authored by `/context-build`, preserved by `/context-update`:

1. **OVERVIEW** — what area covers; lists source files implementing it by relative path. List = anchor `/context-update` use to map changed source files back to context files needing update.
2. **PUBLIC API** — functions/classes/interfaces other areas call into, referenced as `path::name` with inputs, outputs, side effects. No implementation detail.
3. **INTERNAL PATTERNS** — non-obvious invariants, conventions modifier of this area must respect.
4. **DOMAIN DEPENDENCIES** — links to domain files this area enforces rules from, naming rule and file.
5. **CROSS-REFERENCES** — links to sibling context files, one-line description of interaction.
6. **WHEN TO READ THE SOURCE** — concrete tasks requiring opening actual source rather than stopping at context file.

Hard limits enforced by commands:

- 150 lines per context file (split if exceeded).
- No code snippets longer than 10 lines — reference by path and name.

## INDEX.md — the entry point

`.claude/context/INDEX.md` cheapest possible entry. It:

- Lists every context file with one-line description.
- Records **`Last updated: YYYY-MM-DD`** date — anchor for `/context-update`'s default smart-update mode (diffs commits `--after` that date).
- File `CLAUDE.md`'s navigation instruction points at.

`/context-update` rewrites `Last updated` date on every successful run. Field missing → smart-update falls back to full update.

Description above is **flat layout**: one `INDEX.md`, all context files beside it. Flat stays default and unchanged. Larger repos may use **nested layout** instead — specified below.

## `Layout:` policy marker

Layer declare own shape. `.claude/context/INDEX.md` header carry single line directly under title:

```
Layout: flat
```

or

```
Layout: nested
```

Rules:

- Detection = **read that line**. Never infer layout from file contents, folder count, or presence of subdirectories. Inference guesses; marker states.
- Marker missing → layout is **flat**. Every pre-existing layer therefore keeps working untouched, no migration needed.
- Marker lives in `.claude/context/INDEX.md`, not `CLAUDE.md`. Detection costs zero extra reads (commands already open `INDEX.md` first), marker travels with layer it describes, and conversion flips exactly one source of truth.

## Nested layout — router + leaves

Nested layer split context files into **units** (natural seams: subsystem, package, service). Each unit own folder under `.claude/context/` with own `INDEX.md`.

- **Router** = `.claude/context/INDEX.md`. Points at units, owns no context files.
- **Leaf** = `.claude/context/<unit>/INDEX.md`. Owns unit's context files.

### Router INDEX schema

1. Title.
2. `Layout: nested` line directly under title.
3. Canonical-docs block — same purpose as flat: links to `CLAUDE.md`, `README.md`, authoring docs living outside layer.
4. **Units table** — one row per unit, mapping unit name to `./<unit>/INDEX.md` plus one-line description of what unit covers.
5. Conventions block — path/link conventions, same as flat.

Router carry **no `Last updated` field at all**. Stated explicitly because absence is the design, not omission: leaves are sole date authority, so router has no derived value to compute, stage, or mistake for scan anchor. Alternative (router date = minimum across leaves) is correct but needs re-derivation logic, non-obvious documented semantic, extra staging rules; having no date removes failure mode instead of managing it.

### Leaf INDEX schema

1. Title (unit name).
2. Own **`Last updated: YYYY-MM-DD`** — same anchor semantics as flat `INDEX.md`: `/context-update` smart mode diffs commits `--after` that date, rewrites it on every successful run touching that unit, falls back to full update when missing.
3. **Files table** — context files that unit owns, with one-line description each.

Leaf dates **drift apart by design**. Updating one unit refresh only that leaf's date; other units keep older dates and stay correctly scannable from their own last run.

### Ownership

Every context file belong to **exactly one leaf**. No file shared between units, no file sitting loose beside router.

- Adding or removing context file → edits that leaf's `INDEX.md` only.
- Router changes **only** when whole unit added or retired.

Keeps router stable and makes staging obvious: unit-scoped run touches one leaf plus its files.

### Depth cap

Nested layout capped at **two levels**: root router + one rank of leaves. Leaf never point at further router.

Cap is deliberate current limit, not oversight. Deeper nesting wanted eventually but multiply work in every consumer (detection, addressing, staging, date resolution). Recorded here so later task can lift it knowingly rather than discover it accidentally.

### `unit=<name>` addressing

`unit=<name>` scope operation to single leaf — its `INDEX.md` and files it owns. Two uses:

- **Scoping** — restrict build/update to one unit, leaving other leaves and their dates untouched.
- **Disambiguation** — when same context filename exist in two units, `files=` alone ambiguous; `unit=` pins which leaf's copy meant.

Flat layout has no units, so `unit=` not applicable there.

### What nesting does not change

Per-context-file six-section schema, 150-line cap per context file, 10-line snippet cap all apply **identically in both layouts**. Nesting change only where index files live and which index owns which file.

## `/context-build` — three-phase initial build

1. **Phase 1 — Analysis (no writes).** Discover layout, identify existing docs/domain files (leave untouched), find natural seams, propose folder layout and file list. Stops for user approval.
2. **Phase 2 — Author.** Write `INDEX.md` first as checklist, then each context file using six-section schema.
3. **Phase 3 — Wire entry-point.** Add navigation instruction at top of `CLAUDE.md` (create minimal one if absent). Verify every source file referenced from at least one context file; flag orphans, no auto-create files for them.

Command refuses refactor source code, refuses modify existing domain files.

## `/context-update` — four modes

Run after code changes. Modes mutually inclusive where noted:

- **MODE A — Smart (default, no args).** `git log --after=<Last updated>` find changed source files, map to context files via OVERVIEW sections, update only those plus INDEX. No commits since date → checks uncommitted changes, asks; else reports "up to date", exits.
- **MODE B — Full (`full`).** Rewrites every context file regardless of git history. Also fallback when `Last updated` missing.
- **MODE C — Targeted (`files=<names>` and/or `git=<ref>`).** `files=` takes comma-separated context filenames (no path/extension). `git=` takes `uncommitted`, SHA, branch, or range like `HEAD~3..HEAD`. Both given → union of target sets updated.
- **`-y` / `--yes`** — non-interactive; skips all confirmation gates, still produces same reports. Combinable with any mode. Mode A's "nothing to update" exit still fires under `--yes`.

Phase 1 produces per-file plain-language diff summary ("PUBLIC API: append_row gained dry_run:bool"); Phase 2 edits sections in place — preserving accurate sections verbatim, updating only what changed, refreshing `Last updated` in INDEX last. Files growing past 150 lines flagged for splitting, not split automatically.

Phase 3 then **auto-commits and pushes** run, putting `/context-update` in committing group alongside `/task-add` and `/task-clean` (`/context-build` stays uncommitted-by-default, pushing only under `--commit`). Stages exactly context files Phase 2 wrote plus `INDEX.md` — explicit paths only, never catch-all — makes one commit. Phase 2 changed nothing → no commit (no empty commit). Non-git VCS → commit honours `CLAUDE.md` `## VCS` mapping (git→`cm`), push step skipped entirely. Hook-skipping flags (`--no-verify`, `--amend`, `--no-gpg-sign`) never used; hook failure surfaced, files left staged. Both commands follow commit-and-push protocol in [docs/authoring-guide.md](../../docs/authoring-guide.md) — pull at start, commit, re-sync, push — skippable via `--no-push` (implied by `--no-commit` for `/context-update`); see doc for algorithm.

## Authoring discipline for these commands

- Treat `.claude/context/` as only writable surface. Domain files, source code out of scope — flag, don't edit.
- Preserve existing structure on update. Schema part of contract: future sessions rely on section names predictable.
- `Last updated` date load-bearing — every `/context-update` run must rewrite it on success, or smart-update degrades.
- Source-file references use relative paths; sibling context refs use `./other.md`; canonical-doc refs use `../../`-prefixed paths (see `.claude/context/INDEX.md` Conventions section).

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — navigation instruction lives at top; hard rules below.
- [`../context/INDEX.md`](../context/INDEX.md) — live navigation index for this repo, with `Last updated` anchor.
- `commands/context-build.md`, `commands/context-update.md` — command implementations.