# Refactor workflow — behaviour-preserving, plan-first, phase-gated

This doc explains the philosophy and invariants behind
`/refactor-codebase`. Read it when touching that command, when extending
its phase model, or when wiring a related quality-improvement command.

## Prime directive: behaviour preservation

`/refactor-codebase` is a **pure refactoring** command. Observable
behaviour — every public function signature, every CLI surface, every
external integration — must be identical before and after the run. The
test suite is the contract:

- The suite must be **green at the start**. If the baseline is red or
  absent, the command stops and reports. It does not "fix tests then
  refactor" — that conflates two kinds of change.
- The suite must be **green between phases**. Each phase ends with a
  full run; a red suite blocks the next phase.
- A "split" is a pure relocation. Signatures, return types, and control
  flow do not change inside Phase 3.

This is what makes the command safe to run on a working codebase: the
worst case is a no-op, not a regression.

## Plan-first, then approval gate

Phase 0 (PREPARATION) ends with a written plan and a hard stop. The
model does not write code until the user approves. The plan format is
deliberate:

- **Grouped by concern**, ordered for execution.
- Every item carries a **risk grade** (LOW/MEDIUM/HIGH). HIGH-risk items
  — those that touch control flow, external API calls, or shared state
  — are flagged separately for explicit approval. They can be deferred
  without blocking the rest of the run.
- **Preconditions** are explicit so dependent items can't run out of
  order.

This separates *deciding* what to refactor from *doing* it. The model
proposes, the user disposes.

## The five focus concerns

`focus=` scopes the run to one or more concerns. Default is all five:

1. `constants` — extract hardcoded vocabulary (status strings, magic
   numbers, lookup tables) into Enums / dataclasses / module constants.
   Goal: make invalid states unrepresentable.
2. `duplication` — extract repeated logic into shared functions, placed
   in the module most aligned with the concern (not a generic dumping
   ground).
3. `splitting` — break files over ~300 lines along natural
   responsibility boundaries. One split, one test run.
4. `imports` — remove unused imports, enforce stdlib → third-party →
   local ordering, replace star imports.
5. `naming` — rename ambiguous/misleading identifiers. Renames must be
   in the approved plan; no opportunistic renames mid-phase.

Phases run in order 1 → 2 → 3 → 4. Phase 5 updates the context layer
and stale CLAUDE.md paths. A focus subset skips the phases it doesn't
touch.

## `scope=` semantics

`scope=foo,bar` matches by basename without path or extension —
`main` matches `src/main.py`. Files outside scope are read only when a
shared dependency forces it. This keeps narrow refactors narrow.

## Integration with the context layer

If `.claude/context/INDEX.md` exists, the model reads only INDEX during
preparation to learn the module map — it does not pre-fetch every
context file. Phase 5 then updates context files whose covered source
moved, split, or got renamed, applying the same rules as
`/context-update`. Domain knowledge files (this file, others under
`.claude/domain/`) are not touched.

## What this command is NOT

- **Not a feature command.** It does not add or change behaviour.
- **Not a test-fixing command.** Red baseline → stop.
- **Not a style-only pass.** Formatting/lint belongs to the project's
  formatter; this command targets structural improvements.
- **Not opportunistic.** Every change is in the approved plan. Spotted
  technical debt outside the plan is reported in the FINAL REPORT, not
  silently fixed.

## Minimal preconditions for safe use

- A runnable test suite with non-trivial coverage of the affected code.
- A clean working tree (so the diff is purely the refactor).
- Optional but recommended: a navigation context layer under
  `.claude/context/` so the planning step can map the codebase cheaply.
