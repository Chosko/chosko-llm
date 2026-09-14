# The inline contract

Fixed text. Under `/runbook-run --inline`, the session executing a step
follows the rule set below **in place of** the subagent contract's OPERATING
RULES (`subagent-contract.md`). It is read once per run, in loop step 1, and
**only when `--inline` is passed** — a default run never loads this file.

It is a reference file rather than prose the session composes for the same
reason the subagent contract is one: a rule set re-worded per step is a rule
set the session can talk itself out of, and under `--inline` the session is
both the one bound by the rules and the one tempted to relax them.

Two placeholders, as in the subagent contract, stand for the runbook's name
(`<RUNBOOK>`) and the step being executed (`<N>`).

---

## INLINE RULES

```
INLINE RULES

- You are executing step <N> of runbook <RUNBOOK>, in this session, under
  --inline. This is the execution phase: it ends when you write out your
  outcome, and not before.
- Assemble the same brief a spawned step prompt carries — the preamble, the
  Companion: background, ## Do not re-propose, the step's Context:, and the
  step's prompt block verbatim — and work through it in that order.
- The brief is the authority. What you remember of an earlier step is not an
  instruction.
- Records win. Where your memory of an earlier step disagrees with that step's
  Done: line or a Context: bullet, the record is right.
- Facts are still written down. When this step changes a fact a later step
  relies on, it is propagated into that later step's Context: in the
  bookkeeping phase, exactly as in spawned mode, even though you already know
  it.
- At any clarifying question or approval gate: if you are a top-level session,
  ask the user directly in the fixed block
  `Step <N> of <total> — <title> — asking (round <r>)`, with any gate draft
  verbatim and unabridged. Never answer your own question, and never skip a
  gate because you "already know" the answer. If you are yourself a subagent,
  end your turn under `QUESTIONS FOR USER` instead, as in the default mode.
- Follow the invoked skill's default commit behaviour. Add no flag the user did
  not type.
- If the work wants a child subagent, spawn it directly, one level down. If you
  cannot spawn, follow your own parent's contract (for example SPAWN REQUEST).
  Failing that, the step fails [!] with a Done: line naming the child that could
  not be spawned and saying that re-running the step without --inline is the
  fix. Never do a child's work in your own context.
- During the execution phase, never edit .claude/runbooks/<RUNBOOK>.md or
  .claude/RUNBOOKS.md.
- End the execution phase by writing out your outcome as a separate act, before
  any bookkeeping: the literal line `DONE` followed by the commit sha(s), the
  decisions taken and any premise that proved wrong — or, if the work failed or
  could not be completed, a plain statement of failure. If you cannot state the
  outcome confidently, it is a failure.
- The Stop-hook reply is unchanged.
```

## Rules end

---

## Why each rule is in there

Not part of the rule set — this section is for whoever maintains the contract.

- **The phase boundary.** In the default mode a second agent separates the one
  who does the work from the one who records it. Under `--inline` the only
  separation left is the boundary between the two phases, so the rule names
  where the execution phase ends: at a written outcome.
- **The same brief, in order.** A runbook must stay executable by either mode
  without re-authoring. Assembling the spawned brief keeps the step's inputs
  identical, so only *who executes* changes.
- **The brief is the authority / records win.** A fresh subagent cannot carry a
  half-decision from step 1 into step 4; an inline session can. These two
  rules replace that structural guarantee: memory is never an instruction, and
  where it disagrees with the written record, the record is right.
- **Facts are still written down.** The session already knows what it learned,
  but a resumed or spawned run of the same runbook does not, and "records win"
  only works if the record exists.
- **Asking directly.** There is no relay hop, because the asker and the user's
  interlocutor are the same agent. The prohibition carries anyway: a session
  that answers its own question, or skips a gate it thinks it can predict, has
  made a decision the user never made. The fixed block tells the user which
  step is asking.
- **Children one level down, never inline.** The default mode's step agent sat
  one level below the orchestrator; under `--inline` that level is free, so a
  wanted child goes there. Doing a child's work in the session destroys the
  fresh context that was the reason for a child (an implementer reviewing its
  own diff is not a review). When no level is reachable, failing the step and
  naming the default mode as the fix is honest; improvising is not.
- **Never edit the runbook or the index during execution.** The bookkeeping
  phase writes exactly those two files; the execution phase writes everything
  else. Mixing them is how a `Done:` line gets written for work that did not
  finish.
- **The written outcome.** It is the inline analogue of waiting for a spawn's
  result. Classifying on a written statement — never on a re-inspection of the
  session's own diff — keeps the orchestrator from reviewing, and an outcome
  the session cannot state confidently is a failure for the same reason an
  ambiguous subagent report is.
