# Features: runbook-run — execution loop

## Overview

Covers `skills/runbook-run/`'s execution policy, parked-question handles,
runbook ids, the step loop and its result cases, the end branch, the spawn
relay and resolve. The rest of the bullet:
[runbook-run.md](./runbook-run.md) and
[runbook-run-contracts.md](./runbook-run-contracts.md).

- `skills/runbook-run/`, continued from [runbook-run.md](./runbook-run.md) § Overview:
  **The execution policy** is the interaction policy, one value per run,
  resolved per [interaction-engine.md](./interaction-engine.md) `policy.md`:
  flag or a parent's policy, then the header `Execution policy:`, then the
  `CLAUDE.md` `Interaction policy:` line, then `attended`; resolved last in
  step 1, never written back. Under `unattended` a step that asks is parked
  and the run goes on; at launch, unless `--skip-parked` (requires the
  policy to resolve to `unattended`), the same **pre-ask** as
  `/task-implement`'s, over every `[P]` step in range, each answer
  unparking its step at once in one bookkeeping commit. All three flags
  compose with `--inline`. The spawned preamble states the policy under
  both values — *This run is attended* / *This run is unattended*, never
  *non-interactive* — the handed-down policy a skill the step invokes
  resolves; the unattended sentence turns on the contract's two conditional
  rules. **Handles**: every parked
  question printed carries a `P<n>` handle, its questions `Q1`, `Q2`, … and
  options `a`, `b`, … (`Unpark P1: Q1a, Q2b`, an example, not a grammar),
  one sequence per run (pre-ask from `P1`, later parks the next unused); a
  reply by handle, step id or title mid-run
  (read at step 8, after the commit) or after the report unparks the step —
  `unparked with answer:` bullet, `[ ]`, `Parked:` rewritten, one bookkeeping
  commit — and it is the next step selected, stated as a rule; rejected with
  one line and nothing recorded: a number never printed, a second answer, an
  answer to an approval-gate item. **Ids**: every runbook carries one beside its kebab-case name,
  and every command taking a runbook accepts `<id>`, `<name>` or
  `<id>-<name>`, resolved in order: all digits → id; exact name → that block;
  `<digits>-<rest>` → that block only when block `<digits>` is named `<rest>`,
  else an error naming the id's real runbook (never a fallback to either
  half); anything else unknown, listing what exists. A legacy name matching
  two blocks is reported as an ambiguity. The id is an alias, never the
  identity: it appears in the body's file name, but the body carries no id,
  messages name the runbook, and **every command opens the body at `File:`,
  never a path built from the name** (a legacy `<name>.md` value stays
  correct). `Last runbook number:` only ever increases; survivors are never
  renumbered and a pruned id is never reused (`TASKS.md`'s rule, same reason —
  `max()` would hand a deleted runbook's id to the next one). An index written
  before ids is backfilled in place by the first command that **writes** it
  (`/runbook-create`, `/runbook-clean`, `/runbook-run`); a read-only command
  never does. **A step's number is a stable id, not its position**: order is
  list position, and `runbook-schema.md` declares a body carrying ids out of
  numeric order (after a `/runbook-create --append --before`/`--after`
  insert) legal — never infer order from numbering, never renumber. Loop:
  re-read body at start of EVERY step (this is the whole
  reconciliation mechanism, and what makes mid-run `--append` steps picked up),
  select the first step **in list order** whose marker is `[ ]`/`[~]`/`[!]`
  and whose `Depends on:` are all `[x]` (a `[P]` step is never selected as it
  stands: under `attended`, reached as the step this rule would pick, its
  question is asked in the relay's fixed block headed `parked <date>,
  asking:` and, answered, it is `[ ]` and selected now — an `approval gate`
  bullet unparks without a question and the agent relays the gate with its
  draft; under `unattended` it is passed over and its dependents are
  unselectable, untouched, not parked), mark
  `[~]`, spawn ONE subagent, **wait for the result notification** (the single
  most dangerous point — the spawn's return value is not the result), classify,
  commit. **Four** result cases: `QUESTIONS FOR USER` → relay to user, answer back
  to the SAME subagent, repeat; `SPAWN REQUEST` → the spawn relay, below; `DONE` + report → `[x]`, write `Done:` (terse default
  `Done: <date>, commit <sha> (<N> files, +X/-Y)` from the report's sha +
  diffstat; decisions / wrong premises only if a re-reader would be misled),
  propagate facts as dated `Context:` bullets,
  update `Steps:`, commit; **anything else, incl. ambiguous → `[!]`**, index
  `[FAILED]` + `Failed at:`, halt. Under `unattended` a **fifth row replaces
  the first**, the policy's only change to the table: `QUESTIONS FOR USER`
  (from the step's agent, a relay child, or the inline session's own written
  outcome) → `[P]` replacing `[~]`, `- <date> parked: <question>` into
  `Context:` (question, options, recommendation verbatim; an approval gate
  recorded as the words `approval gate`, draft left out), printed in chat
  under the next handle in a fixed `Parked (P<n>) — Step …` block, `Parked:`
  line written, `Status:` still `[RUNNING]`, `Steps:` unmoved, committed at
  step 8 like `[x]`/`[!]`, loop; no `Done:` line, the agent never resumed —
  the step re-runs whole in a fresh subagent once answered. Selection with
  steps remaining, none selectable and one `[P]` is the **end branch**, not a
  deadlock: index back to `[PENDING]` (`Parked:` stays), commit, closing
  report naming each `[P]` step's question and the steps waiting on it;
  applies inside a bounded run too. **Spawn relay** (`--relay-spawns` forces it;
  otherwise the step's own agent triggers it): where a subagent cannot spawn a
  subagent — cloud sessions — the step's agent writes the child's prompt to a
  `$TMPDIR` file, **never inside the repo**, and ends its turn with
  `SPAWN REQUEST` naming a prompt path, a result path and a model. The
  orchestrator spawns that child **at its own nesting level** — sideways, not
  down, which is the whole mechanism — waits, then tells the same suspended
  caller the result file is ready. It **opens neither file**: forwards, does not
  read, the same discipline as *compresses, does not answer*, and what keeps the
  child's output out of its context. The child is bound by the verbatim RELAY
  CHILD RULES block, and the one exception is an existence check on the result
  path. A **miss** — a `DONE` child whose result file is absent or empty, or a
  turn carrying no marker that does not plainly declare its own failure — buys
  that child one re-prompt (not a relay round), since it still holds its
  report in context; a second miss fails the step, and a declared failure
  fails it at once. The unmarked-turn re-prompt is the one departure from the
  four result cases and is the relay child's alone: a step's own agent's
  unmarked turn still fails the step. Detection is the SUBAGENT's, not
  the orchestrator's — only the agent needing the tool can tell if it has it,
  and a probe would measure the wrong environment. The caller stays suspended
  throughout, so one agent works at a time — the one stated exception to *never
  two subagents*; a child's own `SPAWN REQUEST` is served identically, so
  fan-out stays flat; cap of **8 relay rounds per step**, the ninth is a `[!]`
  failure. A child that fails **fails the step** — never reported to its caller
  as finished, which would buy a `Done:` line for work that never happened.
  Classification runs on the child's returned marker, never on the result file,
  which is what squares it with *opens neither file*. File names are **dictated
  by the contract** (`<runbook>-step<n>-round<r>-prompt.md` / `-result.md`), not
  left to the agent: two runs share one `$TMPDIR` and the orchestrator, never
  opening either file, could not detect a collision. Relay files are never
  staged. Question-relay block is fixed text: question, lettered
  options with costs, a recommendation; at an approval gate the agent's
  plain summary of the draft, a `show` reply relayed to the same agent
  fetching the draft whole. A gate the step's skill tags `confirmation`
  passing on its own under `unattended` is not a skipped gate. In the subagent
  position (depth 3, a batch parent driving the runbook) it emits the same block
  as its own final turn under `QUESTIONS FOR USER`, for its parent to carry.
  **Resolve** reads the body at `File:` (a missing file stops) and, before
  marking `[RUNNING]`, runs the migration check — a hit reads
  `body-migration.md` and the run uses the new path for its whole life; a
  resume of an already-`[RUNNING]` runbook never migrates.

## Public API

- [runbook-suite.md](./runbook-suite.md) § Public API.

## Internal patterns

- [runbook-suite.md](./runbook-suite.md) § Internal patterns.

## Domain dependencies

- [runbook-suite.md](./runbook-suite.md) § Domain dependencies.

## Cross-references

- [runbook-suite.md](./runbook-suite.md) — the runbook suite's hub, and its
  family-wide cross-references.
- [runbook-run.md](./runbook-run.md) — store, reference files and
  dependencies.
- [runbook-run-contracts.md](./runbook-run-contracts.md) — chat contract,
  closing report, commit convention, Stop-hook reply and hard contracts.

## When to read the source

- [runbook-suite.md](./runbook-suite.md) § When to read the source.
