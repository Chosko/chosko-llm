Compressed version below.

# Refactor workflow — behaviour-preserving, plan-first, phase-gated

Doc explain philosophy + invariants behind
`/refactor-codebase`. Read when touch that command, extend
phase model, or wire related quality-improvement command.

## Prime directive: behaviour preservation

`/refactor-codebase` = **pure refactoring** command. Observable
behaviour — every public function signature, every CLI surface, every
external integration — identical before + after run. Test suite = contract:

- Suite must be **green at start**. Baseline red or absent → command stop, report. Not "fix tests then
  refactor" — conflate two kinds change.
- Suite must be **green between phases**. Each phase end with
  full run; red suite block next phase.
- "Split" = pure relocation. Signatures, return types, control
  flow don't change inside Phase 3.

Makes command safe run on working codebase: worst case = no-op, not regression.

## Plan-first, then approval gate

Phase 0 (PREPARATION) end with written plan + hard stop. Model
not write code until user approve. Plan format deliberate:

- **Grouped by concern**, ordered for execution.
- Every item carry **risk grade** (LOW/MEDIUM/HIGH). HIGH-risk items
  — touch control flow, external API calls, shared state
  — flagged separately, need explicit approval. Can defer
  without blocking rest of run.
- **Preconditions** explicit so dependent items can't run out of
  order.

Separates *deciding* what refactor from *doing* it. Model
propose, user dispose.

## Five focus concerns

`focus=` scope run to one+ concerns. Default all five:

1. `constants` — extract hardcoded vocabulary (status strings, magic
   numbers, lookup tables) into Enums / dataclasses / module constants.
   Goal: invalid states unrepresentable.
2. `duplication` — extract repeated logic into shared functions, placed
   in module most aligned w/ concern (not generic dumping
   ground).
3. `splitting` — break files over ~300 lines along natural
   responsibility boundaries. One split, one test run.
4. `imports` — remove unused imports, enforce stdlib → third-party →
   local ordering, replace star imports.
5. `naming` — rename ambiguous/misleading identifiers. Renames must be
   in approved plan; no opportunistic renames mid-phase.

Phases run order 1 → 2 → 3 → 4. Phase 5 update context layer
+ stale CLAUDE.md paths. Focus subset skip phases it don't touch.

## `scope=` semantics

`scope=foo,bar` match by basename w/o path or extension —
`main` match `src/main.py`. Files outside scope read only when shared
dependency force it. Keep narrow refactors narrow.

## Commit and push

`/refactor-codebase` + `/refactor-tests` = authoring commands:
uncommitted by default, `--commit` opts in. When `--commit` passed, both
follow commit-and-push protocol in
[docs/authoring-guide.md](../../docs/authoring-guide.md) — pull at start,
commit, re-sync, push — not plain `git commit`. `--no-push`
(only meaningful w/ `--commit`) skip sync/push cycle,
commit locally only. Algorithm not re-derived here; see that doc.

## Integration with context layer

If `.claude/context/INDEX.md` exists, model read only INDEX during
preparation to learn module map — not pre-fetch every
context file. Phase 5 then update context files whose covered source
moved, split, or got renamed, apply same rules as
`/context-update`. Domain knowledge files (this file, others under
`.claude/domain/`) not touched.

## What this command is NOT

- **Not feature command.** Not add or change behaviour.
- **Not test-fixing command.** Red baseline → stop.
- **Not style-only pass.** Formatting/lint belong to project's
  formatter; this command target structural improvements.
- **Not opportunistic.** Every change in approved plan. Spotted
  technical debt outside plan reported in FINAL REPORT, not
  silently fixed.

## Minimal preconditions for safe use

- Runnable test suite w/ non-trivial coverage of affected code.
- Clean working tree (diff purely refactor).
- Optional, recommended: navigation context layer under
  `.claude/context/` so planning step map codebase cheap.