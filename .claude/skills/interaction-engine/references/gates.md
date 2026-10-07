# Gate classes

Authority for: the three gate classes, what each does under `unattended`,
the auto-pass summary and its commit, runs that do not commit, and the rule
for real decisions.

Read only when the policy resolves to `unattended` (`./policy.md`). Under
`attended` every gate waits and this file is never opened.

---

## Membership is declared at the gate

Every gate of every feature is in exactly one class. The feature that owns
the gate declares it at the gate, with a one-word tag citing this file —
`confirmation`, `design` or `destructive`. This file holds the rule for each
class and no catalogue of gates. A gate that carries no tag is class 2.

## Class 1 — confirmation-only: passes on its own

The gate asks nothing a prior instruction has not already settled. Under
`unattended` it does not wait:

- the feature proceeds as if the gate had been approved, and prints a short
  summary of what was written, per `./messages.md`, naming the commit;
- each auto-passed write is its own commit, so `git revert` of that commit
  is the undo;
- an auto-passed gate whose commit fails stops the run exactly as that
  feature's own commit failure does.

## Class 2 — design-heavy: waits

The gate is where the user's judgement is the product. Under `unattended` it
waits: the item is parked where the feature has a parking mechanism, and
otherwise the run stops and ends its message with the gate's summary and
question. A new gate is class 2 until its owner tags it otherwise.

## Class 3 — destructive: waits under every policy

The gate guards something `git revert` cannot cleanly undo, or that deletes
the user's record. It waits under every policy, exactly as class 2 does under
`unattended`; no flag and no policy passes it.

## A parked gate

A gate that waits by parking is the `approval gate` case of the feature's
parking mechanism: never pre-answerable, answered with its draft seen. The
mechanism's own rules govern it; this file adds nothing to them.

## A run that does not commit

Under `--no-commit`, in a feature that leaves its work uncommitted by
default, or on a project whose `CLAUDE.md` maps git to another VCS,
`unattended` still applies:

- a class 1 gate passes on its own, and its summary names the uncommitted
  change instead of a commit; discarding that change is the undo;
- parking needs commits and a branch, so anything that would park stops the
  run instead.

## Real decisions

A question about the work — not a confirmation — is parked whenever the
feature can park, and otherwise ends the run with the question. The agent
never picks an option for the user, however small the decision looks or
however clear the recommendation: no class and no "trivial question"
exception changes this. A run that stops asks every question it collected
together, per `./messages.md`.
