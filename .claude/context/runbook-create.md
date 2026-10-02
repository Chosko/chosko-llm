# Features: runbook-create

## Overview

Covers `commands/runbook-create.md`, the runbook author. The family hub:
[runbook-suite.md](./runbook-suite.md).

- `commands/runbook-create.md` — authors a runbook, or appends to one.
  `requires: skill:runbook-run` — it cites that skill's `runbook-schema.md` for
  the body/index shape rather than carrying a second copy. **The only assigner
  of ids**: a new runbook takes `Last runbook number: + 1` (never `max()`)
  BEFORE writing the body, writes it at `.claude/runbooks/<id>-<name>.md`, and
  advances the counter and appends the block (`File:` prefixed) in the same
  index write; an append assigns nothing. Refuses a new name that is taken OR
  whose first kebab segment is all digits (`2026-migration`), with one
  suggested alternative. `--append <id|name|id-name>` resolves by the schema's
  rule, then runs the migration check (reading `body-migration.md` on a hit)
  before gathering material — unless the target is `[RUNNING]`, which is
  appended to at its current `File:` path, never renamed; body always read and
  written at `File:`, staged by that path (both paths when it migrated). Also the
  only writer of a step's `Needs:` line (`agent` / `agent+human` / `human`,
  absent meaning `agent`) — a seventh from-scratch interview question, harvested
  in passing in conversation mode, and called out at the gate because whether
  the run can be left unattended is the one thing the titles cannot say. Also
  the only writer of the header `Execution policy:` line — written only when
  the user asks for an unattended runbook, never by default and never asked
  in either mode (absent means `attended`, as an absent `Needs:` means
  `agent`); the gate's `Policy:` line shows it only then. Never writes `[P]`
  or the two parking `Context:` bullets, which are the run's.
  Command not skill:
  one pass with a confirmation gate, no supporting files of its own. Two
  orthogonal axes — target (`<name>` new / `--append <id|name|id-name>` / bare `--append` =
  the runbook this session is running, which a step's subagent knows because the
  spawned prompt names it / no args = ask) and source (the conversation's MOST
  RECENT enumerated follow-up list, the default; or a free-form description via
  one batched interview). Append is a flag, not a `/runbook-append` command:
  interview, prompt rules and gate are identical, only the write target differs.
  Append rules: new steps take the next unused ids from the highest existing
  one; they go at the foot unless `--before <step>` / `--after <step>`
  (mutually exclusive, `--append` only, value a step **id** never a position;
  an unknown id is answered by listing the runbook's steps) writes them as one
  contiguous block at that position — id is not position, so the foot need
  not carry the highest id, and the gate's `Position:` line says where they
  land; existing steps NEVER edited, moved or renumbered, their `Depends on:`
  never rewritten, `Sequencing:` (optional, one line) never touched, `[DONE]` → back to `[PENDING]`, `[FAILED]` stays
  `[FAILED]`, `[RUNNING]` appendable **only from the running session itself**.
  Enforces ten prompt-quality rules before writing (self-contained; names the
  document to read first or carries evidence inline; carries every decision that
  exists nowhere on disk **and nothing that already does** — which is why
  `/task-implement 134` is a complete one-line prompt; states sequencing and
  why; states what must not be re-proposed; real slash commands in real argument
  form; **no path that will not exist at run time, in particular nothing under
  `docs/`**; one deliverable; never invokes `/runbook-run`; **rule 10** prefers
  two steps to one needing a nested spawn — a preference, not rule 9's
  rejection, because a skill that spawns internally cannot be split by an author
  who does not know it will, which is the case the spawn relay covers at run
  time), fixing failures and NAMING each fix in the report rather than silently. Gate shows the proposed
  shape only — never the full prompts, which are a wall of text and are in the
  file a moment later. `Context:` is authored as `none`: decisions belong INSIDE
  the fenced prompt, which keeps it pasteable into a fresh session by hand.
  **Commits and pushes by default** (`Add runbook <name>` / `Append <n> steps
  to runbook <name>`, staging exactly the written paths); flags per
  `../../docs/authoring-guide.md` § Commit-and-push convention.

## Public API

- [runbook-suite.md](./runbook-suite.md) § Public API.

## Internal patterns

- [runbook-suite.md](./runbook-suite.md) § Internal patterns.

## Domain dependencies

- [runbook-suite.md](./runbook-suite.md) § Domain dependencies.

## Cross-references

- [runbook-suite.md](./runbook-suite.md) — the runbook suite's hub, and its
  family-wide cross-references.
- [runbook-run.md](./runbook-run.md) — the schema this command cites.

## When to read the source

- [runbook-suite.md](./runbook-suite.md) § When to read the source.
