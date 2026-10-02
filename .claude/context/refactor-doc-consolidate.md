# Features: refactor commands and doc-consolidate

## Overview

Covers the behaviour-preserving rewrite tools: the two refactor commands and
the `doc-consolidate` skill. Feature kinds: [features.md](./features.md); the
frontmatter contract every one of them follows:
[feature-contract.md](./feature-contract.md).

- `commands/refactor-codebase.md` — behaviour-preserving, plan-first,
  test-gated refactor: extract constants/enums, dedupe, split oversized
  files, clean imports, rename. `scope=` / `focus=` limit work; `--commit`
  commits result (default leaves uncommitted).
- `commands/refactor-tests.md` — splits oversized test files into focused ones,
  runs suite before/after each split to keep it green. `threshold=`
  sets line cutoff; `--commit` commits splits (default uncommitted).
- `skills/doc-consolidate/` — rewrites a rules document (or every `.md`
  under a folder) under `claude-md:editing-discipline`, meaning-preserving:
  classifies each normative statement kept / superseded / historical /
  duplicate / restated / merged — every section of every file up front —
  writes the per-section ledgers of drops and merges only to one scratchpad
  file whose path it prints, then gates once per run on the judgement calls
  alone (entries the rules can't settle) as a numbered list plus a count line
  per file: `all` approves, numbers overrule, `ledger` prints them; no
  judgement calls means no gate. Rewrites, then spawns
  the fresh-context verifier in `verifier.md` (old + new text, no ledger)
  whose LOST list must be restored or accepted before the run ends; on a
  folder resolves cross-file duplicates with `rule-overlap`'s collection
  method, one owner cited from the rest. Preserves frontmatter, the `#`
  header, context six sections, feature-doc sections. Line counts reported
  as observation, never a target. Uncommitted by default; `--commit`.

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
