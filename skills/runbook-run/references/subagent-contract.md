# The subagent contract

Fixed text. The block below is pasted **verbatim** as the last section of every
spawned step prompt, with only its two placeholders filled in. It is a
reference file rather than prose the orchestrator composes because it must be
identical in every step of every runbook: a contract that is re-worded per
spawn is a contract the agent can be talked out of.

Two placeholders, and nothing else, is substituted:

- `<RUNBOOK>` — the runbook's name, e.g. `implement-ecc-import`.
- `<N>` — the step number being executed.

It goes **last** in the assembled prompt, after the step's own fenced prompt
block, so the operating rules are the final thing the agent reads.

---

## OPERATING RULES — paste from here, verbatim

```
OPERATING RULES

- You cannot talk to the user. Nobody is watching your turn in real time.
- At any clarifying question or approval gate, stop and end your turn with the
  literal line `QUESTIONS FOR USER`, followed by the questions, the options for
  each, and a recommendation for each. At an approval gate, include the full
  draft, unabridged, so it can be approved as-is. The user's answer will be
  sent back to you in this same conversation; then continue.
- Follow the invoked skill's default commit behaviour. Add no flag the user did
  not type.
- Never edit .claude/runbooks/<RUNBOOK>.md or .claude/RUNBOOKS.md.
- You are executing step <N> of runbook <RUNBOOK>.
- When finished, end your turn with the literal line `DONE` followed by a
  concise report naming the commit sha(s), the decisions taken, and any premise
  in the prompt or task body that proved wrong. If the work failed or could not
  be completed, say so plainly instead of `DONE`.
```

## Paste ends

---

## Why each rule is in there

Not part of the pasted block — this section is for whoever maintains the
contract, and is never sent to a subagent.

- **"You cannot talk to the user."** A spawned agent has no interactive
  channel. Without this line it asks a question into the void and either stalls
  or, worse, answers the question itself and proceeds on its own invention.
- **`QUESTIONS FOR USER`.** The literal marker is what the orchestrator
  classifies on. Options and a recommendation are required because the relay
  compresses but never answers — the user must be able to decide from the block
  alone. The full unabridged draft at an approval gate is the one thing the
  orchestrator must not compress: a summarized draft cannot be approved.
- **Default commit behaviour, no invented flags.** A step's prompt is often a
  bare slash-command invocation whose commit behaviour the user already chose
  when they authored it. An agent that helpfully adds `--no-commit` (or drops
  it) changes what the runbook does.
- **Never edit the runbook or the index.** The orchestrator writes exactly two
  files and a subagent writes everything else. Two writers on the runbook is
  how a `Done:` line gets lost.
- **Naming the runbook and step.** It orients the agent, it makes its report
  attributable, and it is what lets a step's subagent call
  `/runbook-create --append` with no name argument.
- **`DONE` plus the three-part report.** `DONE` is the literal marker the
  orchestrator classifies on; the sha, the decisions and the wrong premises are
  exactly what the `Done:` line records and what fact propagation feeds into
  later steps. "Say so plainly instead of `DONE`" exists because an agent that
  fails and still writes `DONE` out of politeness produces a runbook that lies.
