# Features: context skills

## Overview

Covers the three skills that build, refresh and restructure the navigation
context layer. Feature kinds: [features.md](./features.md); the frontmatter
contract every one of them follows: [feature-contract.md](./feature-contract.md).

- `skills/context-build/` — introduces navigation context layer. Three
  phases: analysis (no writes, stops for approval), author, wire CLAUDE.md
  entry-point. Flat by default, stamping `Layout: flat` into the INDEX it
  authors; `nested` / `nested=<unit1>,<unit2>` builds router + per-unit
  leaves instead. One supporting file, `nested.md`, read ON DEMAND — only
  when the run is nested — so flat runs (the common path) never pay its
  tokens. Refuses to convert an existing layer, pointing at
  `/context-convert`. Leaves output uncommitted by default; `--commit`
  commits layer (INDEX, context files, CLAUDE.md edit) with explicit paths
  only. Carries `replaces: command:context-build`.
- `skills/context-update/` — refreshes existing context layer. Four modes
  (smart / `full` / `files=`+`git=` targeted / `-y`), backfills
  `Layout: flat` into any INDEX lacking the marker, then auto-commits
  context files it updated (explicit paths only; no commit when nothing
  changed) — its commit group is `../../docs/authoring-guide.md`
  § Commit-and-push convention. `--no-commit` leaves updates uncommitted. A test context file
  (`<unit>-tests.md`) holds only placement-and-running content and
  tripwire tests (rule 2.1 g) — never a catalogue of what each test
  asserts. One supporting
  file, `nested.md`, read ON DEMAND when the layer's marker says
  `Layout: nested` — covers per-leaf `Last updated` (each leaf its own
  date authority, router has none), one-leaf-per-file ownership, and
  `unit=<name>` scoping/disambiguation.
- `skills/context-convert/` — restructures an existing layer between the
  two layouts in place, either direction; `/context-build` refuses that
  operation and points here. Direction inferred from the `Layout:` marker,
  forceable with `to=nested` / `to=flat`; `nested=` pre-seeds unit names
  only, never file placement. Plan-first: Phase 1 reports every path move,
  date decision and link rewrite, then stops (`-y` skips the gate).
  Content is MOVED, never rewritten — the only in-file edit is a relative
  link whose depth changed. Dates fail safe both ways (flat→nested: every
  leaf inherits the flat date verbatim; nested→flat: the MINIMUM leaf
  date, never max, never today). No `nested.md` split — every run of this
  skill concerns the nested layout, so there is no cheap flat path to
  keep. Authoring-command commit family: `--commit` to commit and push.
  No `replaces:`.

## Public API

- None beyond [feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- None beyond [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- None beyond [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds and the rest of the shipped
  inventory; [feature-contract.md](./feature-contract.md) — the frontmatter
  contract these features follow.

## When to read the source

- None beyond [features.md](./features.md) § When to read the source.
