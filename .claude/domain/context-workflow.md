# Context workflow — navigation layer for future sessions

Project ship three skills — `/context-build` (`skills/context-build/SKILL.md`), `/context-update` (`skills/context-update/SKILL.md`), `/context-convert` (`skills/context-convert/SKILL.md`) — together maintain **navigation context layer** under `.claude/context/`. Read doc when touching any of them, changing per-context-file schema, or reasoning how context layer relate to domain docs and `CLAUDE.md`.

`/context-build` and `/context-update` were `commands/*.md` until task 97 (v0.46.0). Converted to skills so nested-layout detail can live in read-on-demand sibling files (`nested.md`) — flat runs never pay tokens for nested path. Old command files deleted; each `SKILL.md` carry `replaces: command:<name>` so `chosko-llm update --all` migrate stale installs (see [docs/authoring-guide.md](../../docs/authoring-guide.md)). `/context-convert` new in task 100 (v0.49.0), never a command, so no `replaces:`.

Family at a glance:

| Skill | Owns | Supporting files | Commits |
| --- | --- | --- | --- |
| `/context-build` | Creating layer that not exist. Flat default; `nested` / `nested=<units>` for router+leaves. Refuse convert existing layer. | `nested.md` (read only on nested run) | Uncommitted by default; `--commit` |
| `/context-update` | Refreshing layer that exist. Four modes. Backfills `Layout:` marker. | `nested.md` (read only when marker say nested) | Auto-commits; `--no-commit` |
| `/context-convert` | Restructuring layer that exist, either direction. Move content, never rewrite. | none — every run is about nesting | Uncommitted by default; `--commit` |

## Why this exists

Without navigation layer, Claude Code answer questions about repo by reading multiple full source files upfront — expensive tokens, slow. Navigation layer: set of small, structured `.md` summaries let future session decide which source files actually open, based on cheap descriptions instead of full reads.

Layer built once with `/context-build`, kept fresh with `/context-update` after code changes, restructured with `/context-convert` when it outgrow its layout. `CLAUDE.md` get navigation pointer at top so every session enter through `INDEX.md` first — that pointer name `.claude/context/INDEX.md`, entry point in **both** layouts, so it never need editing when layout change.

## Scope: structure, not domain

Two layers deliberately separate:

- **Context layer** (`.claude/context/*.md`) — describes **codebase structure**: what files implement which area, public APIs, internal patterns, where read source. Owned, rewritten by `/context-build` and `/context-update`, moved (never rewritten) by `/context-convert`.
- **Domain layer** (e.g. `.claude/domain/*.md`, `docs/`, `CLAUDE.md`) — describes **business rules, workflows, design decisions, hard rules**. Owned by humans (or purpose-built commands like `/task-setup`). All three context skills cross-reference domain files but **never modify them**. Code change imply domain rule shifted → `/context-update` flags for manual review, no rewrite.

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
- `/context-build` **writes** `Layout: flat` into every `INDEX.md` it authors (Phase 2), directly under title.
- `/context-update` **backfills** it: layer whose `INDEX.md` lack `Layout:` line get `Layout: flat` inserted as part of step 2.4 index update. Fires on **every mode**, including Mode A run finding nothing else to update — then `INDEX.md` alone written, staged, committed. Self-migrating; no separate migration command.
- Marker reading happen in `/context-build` Phase 1 / `/context-update` PREPARATION / `/context-convert` PREPARATION, detected layout stated in scope report. `Layout: nested` routes the run into that skill's `nested.md` — never half-handled as flat. `/context-convert` has no `nested.md` split: every run of it concerns the nested layout, so there is no flat path to keep cheap.
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

Layout chosen by argument, not inference: no argument → flat (default, and what Phase 2 stamp as `Layout: flat`); `nested` → skill propose units in Phase 1; `nested=<unit1>,<unit2>` → user name units, skill still decide which file land in which. Nested run read `skills/context-build/nested.md`; flat run never open it.

Skill refuses refactor source code, refuses modify existing domain files, and refuses **convert** — nested build over layer that already exist stop and point at `/context-convert`. `/context-build` only ever author layer that not exist.

`/project-setup` always invoke `/context-build` with no layout argument (flat), and never offer nested: first-time setup has no basis for picking unit seams.

## `/context-update` — four modes

Run after code changes. Modes mutually inclusive where noted:

- **MODE A — Smart (default, no args).** `git log --after=<Last updated>` find changed source files, map to context files via OVERVIEW sections, update only those plus INDEX. No commits since date → checks uncommitted changes, asks; else reports "up to date", exits.
- **MODE B — Full (`full`).** Rewrites every context file regardless of git history. Also fallback when `Last updated` missing.
- **MODE C — Targeted (`files=<names>` and/or `git=<ref>`).** `files=` takes comma-separated context filenames (no path/extension). `git=` takes `uncommitted`, SHA, branch, or range like `HEAD~3..HEAD`. Both given → union of target sets updated.
- **`-y` / `--yes`** — non-interactive; skips all confirmation gates, still produces same reports. Combinable with any mode. Mode A's "nothing to update" exit still fires under `--yes`.
- **`unit=<name>[,<name>]`** — nested layers only; scope run to named leaves, leaving other leaves and their dates untouched. Also disambiguate `files=` when same context filename exist in two units. Not applicable on flat layer. Nested run read `skills/context-update/nested.md`; flat run never open it.

Phase 1 produces per-file plain-language diff summary ("PUBLIC API: append_row gained dry_run:bool"); Phase 2 edits sections in place — preserving accurate sections verbatim, updating only what changed, refreshing `Last updated` in INDEX last. Files growing past 150 lines flagged for splitting, not split automatically.

Phase 3 then **auto-commits and pushes** run, putting `/context-update` in committing group alongside `/task-add` and `/task-clean` (`/context-build` stays uncommitted-by-default, pushing only under `--commit`). Stages exactly context files Phase 2 wrote plus `INDEX.md` — explicit paths only, never catch-all — makes one commit. Phase 2 changed nothing → no commit (no empty commit). Non-git VCS → commit honours `CLAUDE.md` `## VCS` mapping (git→`cm`), push step skipped entirely. Hook-skipping flags (`--no-verify`, `--amend`, `--no-gpg-sign`) never used; hook failure surfaced, files left staged. Both skills follow commit-and-push protocol — pull at start, commit, re-sync, push — skippable via `--no-push` (implied by `--no-commit` for `/context-update`). Protocol stated inline in each `SKILL.md`, not by reference: `docs/` never installed to `~/.claude/`, so shipped body must never point runtime agent at a `docs/` path. Authoring-time algorithm reference: [docs/authoring-guide.md](../../docs/authoring-guide.md).

Marker-backfill-only run (Mode A found nothing, but `INDEX.md` lacked `Layout:`) is **not** a no-op: `INDEX.md` changed, so it stage and commit as usual.

## `/context-convert` — restructure an existing layer

`skills/context-convert/SKILL.md`. Converts a layer that already exists between the two layouts, in either direction, without rebuilding it from source. `/context-build` refuses to convert (a nested build over an existing flat layer stops and points here); this skill is that operation.

Direction inferred from the `Layout:` marker, forceable with `to=nested` / `to=flat`. Target equal to current layout reports "already `<layout>`" and exits without writing. `nested=<unit1>,<unit2>,…` pre-seeds the unit list exactly as in `/context-build` — it never pre-seeds which file lands in which unit. Plan-first: Phase 1 reports every file's old and new path, the unit breakdown, every date decision and every cross-reference rewrite, then stops for approval; `-y` / `--yes` skips that gate. Authoring-command commit family: uncommitted by default, `--commit` to commit and push, `--commit --no-push` to skip the push.

**Content is moved, never rewritten.** The only edit made inside a context file is to a relative link whose path would stop resolving at the new depth (`./other.md` ↔ `../<unit>/other.md`, and one `../` more or fewer on paths climbing out of the layer). Source-file references stay repo-root-relative in both layouts and are never touched. No context file is created, deleted, split or merged.

### Date rules — both directions fail safe

- **flat → nested:** every leaf inherits the flat index's single `Last updated` verbatim. No leaf gets today's date; none has actually been re-checked, and a fresher date would make that unit's next Mode A scan skip real changes. Router gets no date at all, per the router schema. Flat index had no date → leaves get none, and each degrades to a full update of itself.
- **nested → flat:** the flat index's `Last updated` is the **minimum** across the leaf dates — a floor, so the next Mode A run re-checks rather than skips. Any leaf missing a date → the flat index omits the field entirely, falling back to Mode B. Never the maximum, never today.

Worst case in both directions is re-checking a unit that had not changed; never skipping one that had.

### Stop conditions

Every stop happens **before any write**, and none is resolved by `-y`:

- Filename collision on nested → flat (same basename owned by two units). Colliding paths are listed; the user renames and re-runs. Auto-renaming is refused deliberately — a generated name breaks every cross-reference pointing at the old one, and the user picks better.
- Layout violation on a nested source layer (a context file loose beside the router, or listed by two leaves).
- Contradictory arguments (`nested=` with `to=flat`, `--commit` with `--no-commit`).

### Out of scope

Domain files, source code and `CLAUDE.md` are untouched, matching the rest of the family. `CLAUDE.md`'s navigation instruction already points at `.claude/context/INDEX.md`, the entry point in **both** layouts, so a conversion needs no edit there — the skill says so in its report instead of touching the file. Staging covers deletions (`git mv` / `git rm`, or `git add --` on removed paths) so the whole move is one coherent commit; a conversion split across two commits is broken at the commit in between.

## Authoring discipline for these skills

- Treat `.claude/context/` as only writable surface. Domain files, source code out of scope — flag, don't edit.
- Preserve existing structure on update. Schema part of contract: future sessions rely on section names predictable.
- `Last updated` date load-bearing — every `/context-update` run must rewrite it on success, or smart-update degrades. Nested: date live on leaf, one per unit, and run rewrite only leaves it touched. Router never carry date at all.
- Layout known by reading `Layout:` marker, never by inferring from folders. Missing marker mean flat.
- Depth capped at two levels (router + one rank of leaves). Lifting cap is deliberate future work, not a bug to fix in passing.
- Nesting change only where index files live and which index own which file. Six-section schema, 150-line file cap, 10-line snippet cap identical in both layouts.
- Source-file references use relative paths; sibling context refs use `./other.md`; canonical-doc refs use `../../`-prefixed paths (see `.claude/context/INDEX.md` Conventions section).

## Cross-references

- [`../../CLAUDE.md`](../../CLAUDE.md) — navigation instruction lives at top; hard rules below.
- [`../context/INDEX.md`](../context/INDEX.md) — live navigation index for this repo, with `Layout: flat` marker and `Last updated` anchor. Reference example of marker-bearing flat index; this repo stays flat deliberately (thirteen context files, no unit seams worth a router).
- `skills/context-build/SKILL.md` (+ `nested.md`), `skills/context-update/SKILL.md` (+ `nested.md`), `skills/context-convert/SKILL.md` — skill implementations.
- [`../context/features.md`](../context/features.md) — shipped-artifact inventory; per-skill entries for all three.
- [`../../README.md`](../../README.md) — user-facing account of the family and the two layouts.
- [`../../commands/project-setup.md`](../../commands/project-setup.md) — wizard that orchestrates `/context-build` (flat only).
- [`../../docs/authoring-guide.md`](../../docs/authoring-guide.md) — frontmatter schema incl. `replaces:` kind-migration key.