# Features: runbook-suggest and follow-ups

## Overview

Covers `skills/runbook-suggest/`, `commands/follow-ups.md` and
`skills/follow-ups-resolve/`. The family hub:
[runbook-suite.md](./runbook-suite.md).

- `skills/runbook-suggest/` — the trigger, and one of the two artifacts nobody
  invokes (the other is `skills/pipeline-suggest/`, which copies its shape).
  `requires: command:runbook-create` — the one judgment call in the graph: it
  cites no shared file and needs no schema, but a proposal naming a command that
  is not installed is exactly what `requires:` exists to stop. It depends on the
  command alone, not the whole suite. Skill not command **because a command is
  invoked and this is selected**: Claude Code picks a skill from its
  `description`, so the frontmatter IS the mechanism — no hook, no `Stop`
  handler, no event registration. ~30 lines of body, small because it loads on a
  guess. Threshold, carried in both description and body: suggest only when the
  follow-ups would be **lost with the conversation** — 3+ actions, or 2+ with an
  ordering constraint, or any that depends on decisions recorded nowhere on
  disk; never a two-step list of simple prompts. Anti-triggers named explicitly
  (single next action, list of things already done, checklist this session will
  work through, enumeration inside an explanation, backlog tasks = `/task-add`),
  the way `claude-council`'s description does. **The emitted line is generic**:
  one or two lines pointing at `/runbook-create` — new or append — naming no
  runbook, listing none, and not saying whether one is running, because
  new-versus-append is asked entirely by `/runbook-create`'s no-argument gate.
  Asks nothing (no gate, no waiting — a question from an auto-fired skill is an
  interruption at the wrong moment), opens no file (not `RUNBOOKS.md`, not a
  body), **writes nothing**, and never invokes `/runbook-create` itself. Fire
  rate is tuned by narrowing the description after observing real sessions —
  the accepted method, not an open question, and never a suppression flag.
- `commands/follow-ups.md` — reads the current conversation and lists what it
  would lose if it ended now: actions proposed but never executed, outcomes
  never recorded on disk, decisions taken in conversation and written down
  nowhere. Output is exactly one of the single line `No follow-ups left` (a
  guarantee, not a shrug, and bare — no heading) or a numbered list under a
  `Follow-ups` heading, each item a slash command plus a short "to …" wherever
  one fits. **Command not skill** — the inverse of
  `skills/runbook-suggest/`, which fires from its description and is never
  invoked: this one is invoked by name and fires from nothing. The two are
  complementary and deliberately unwired — a `/follow-ups` list of 3+ ordered
  items is exactly what `runbook-suggest` already watches for. Exclusion rule
  carried in the body with both sides: work already tracked on disk is not a
  follow-up (`/runbook-run X to continue` isn't one — the runbook tracks it),
  while a task created in the conversation and not yet appended to the running
  runbook is, because nothing on disk connects it to the work in flight. The
  numbering is the handle: acting on a reply is `skills/follow-ups-resolve/`'s,
  not something the command implements; once a working list exists in the
  conversation, the output is that list in its two-section shape (Approved,
  then Awaiting approval, gaps added to the second) — invoked while a
  `/runbook-run` is in flight, the list collected so far in that shape. Takes no arguments, opens no project file,
  writes nothing, commits nothing, invokes nothing. Deliberately short — a
  reading rule, an exclusion rule, an output shape and a stop; `runbook-suggest`
  is the register it imitates. States in one sentence that a run-closing
  skill may apply its rules as the second group of its own closing report,
  under this same `Follow-ups` heading, its own items folded into the one
  numbering. No `requires:` of its own; `skills/runbook-run/` and
  `skills/task-implement/` require it. Carries a
  `routing.md` row (Consumes the conversation only, Produces the list, Owns
  `Nothing`, no preconditions, no arguments, Amend `—`) in the shape
  `runbook-suggest` and `pipeline-suggest` use; `check-routing.sh` does not
  demand one — it declares no engine — but consistency does.
- `skills/follow-ups-resolve/` — the general protocol for acting on a user
  reply to a numbered Follow-ups list, whatever produced it (`/follow-ups`, a
  `/runbook-run` or `/task-implement` closing report, any list of that shape).
  Auto-trigger skill — selected from its description, which is written to the
  150-word budget with a "Not for" list last (a `P<n>` reply to a parked
  question, an unrelated request, producing a list). **Skill not a section of
  `/follow-ups`** because the command is read-only by contract and only a skill
  auto-loads on a reply. `requires: command:follow-ups` — it cites that body's
  item form and § WHAT DOES NOT by name. Body is six rules over one **working
  list** (numbered from 1 each printing, the reply handle; split into
  Approved / Awaiting approval once anything is approved): resolve (feedback
  rewrites the list, re-presented until approved, nothing executes before);
  execute (orchestrator delegates items to subagents, independent ones in
  parallel, may do one-line fixes itself); gates (delegated prompts
  auto-confirm an approval-only gate, but the item's approval stands in only
  while the gate's draft stays inside the item; genuine questions are relayed
  verbatim, never answered by the orchestrator); new follow-ups go to the user
  then join the list; on a project with `.claude/RUNBOOKS.md` every task a
  follow-up creates brings a companion runbook-placement item; during a
  runbook run (resolution and approval allowed mid-run, execution deferred to
  the run's end; an arising follow-up printed once as one `Follow-up: <item>`
  line; the list on demand only, via `/follow-ups`; approvals merge into
  Approved; a `P<n>` reply is never an approval; after the closing report the
  approved items start at once, except one whose precondition is an item still
  awaiting approval). Writes nothing
  of its own. `runbook-suggest` and `pipeline-suggest` exclude a reply to a
  Follow-ups list in their descriptions; `runbook-run` and `task-implement`
  name the skill (never a path) where their closing reports say how a reply by
  number is handled — `runbook-run` also cites it in CHAT OUTPUT and CLOSING
  THE RUN; for `task-implement` it stays optional. Carries a `routing.md` row in the
  `runbook-suggest` shape.

## Public API

- [runbook-suite.md](./runbook-suite.md) § Public API.

## Internal patterns

- [runbook-suite.md](./runbook-suite.md) § Internal patterns.

## Domain dependencies

- [runbook-suite.md](./runbook-suite.md) § Domain dependencies.

## Cross-references

- [runbook-suite.md](./runbook-suite.md) — the runbook suite's hub, and its
  family-wide cross-references.
- [runbook-run-contracts.md](./runbook-run-contracts.md) — the closing report
  that applies `/follow-ups`' rules.
- [runbook-create.md](./runbook-create.md) — the command `runbook-suggest`
  points at.

## When to read the source

- [runbook-suite.md](./runbook-suite.md) § When to read the source.
