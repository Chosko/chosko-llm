# The interaction policy

Authority for: the two policy values, the `Interaction policy:` line, the
`--attended` / `--unattended` flags, the precedence that resolves them, how a
parent run hands its policy down, and the argument errors.

Read by every interactive feature at argument parsing.

---

## One value per run

A run has exactly one policy, `attended` or `unattended`, resolved once at
argument parsing and held in memory for the whole run. It never changes
mid-run.

- **`attended`** — every gate waits for the person running the feature, and
  a question is put to them and waited on. The default.
- **`unattended`** — the gate classes of `./gates.md` apply: confirmation-only
  gates pass on their own, every other gate and every question about the work
  parks where the feature can park and otherwise stops the run.

The output and question rules of `./messages.md` hold under both values.

## Precedence

First match wins:

1. `--attended` or `--unattended` passed to this run, or a policy handed down
   by the parent run (§ *A parent hands its policy down*) — the handed-down
   policy ranks with a typed flag;
2. the runbook's own `Execution policy:` header — `/runbook-run` only;
3. the project's `CLAUDE.md` line `Interaction policy: attended` or
   `Interaction policy: unattended`;
4. `attended`.

A project that carries no `Interaction policy:` line and passes no flag runs
`attended`: every gate waits, as each feature's own body describes it.

## A parent hands its policy down

A step agent, a delegated agent or any subagent a run spawns resolves the
policy its parent resolved, never the `CLAUDE.md` line, which may say
otherwise. The parent states it explicitly:

- a runbook step's preamble states it under **both** values — *This run is
  attended* as well as *This run is unattended*;
- a delegated agent's prompt carries it in its resolved-flag list, as the
  `--attended` or `--unattended` flag.

The sentence says *attended* or *unattended*, never *non-interactive*: a
non-interactive session is not a policy, and an attended step agent is
non-interactive too.

## Flags

Every interactive feature accepts both `--attended` and `--unattended`,
including one whose gates are all class 2 or 3 and so behaves the same under
either, so that a parent never needs to know which of its children a flag
would change. Each flag is stripped from the arguments before the feature
reads what is left.

## Argument errors

Each stops the run before any work, with its one line:

- `--attended` beside `--unattended` —
  `--attended and --unattended cannot be combined. Pick one.`
- a `CLAUDE.md` `Interaction policy:` value outside the two words —
  `CLAUDE.md's Interaction policy is "<value>" — it must be attended or unattended.`

## What the policy does not touch

- **The testing policy.** `Testing policy for /task-implement: …`, including
  `skip-tests-unattended`, is an independent marker with its own meaning; the
  interaction policy neither reads nor sets it.
- **The `-y` flags.** The `-y` of `/context-update`, `/context-convert` and
  `/task-implement` stays a narrower switch that passes that feature's own
  confirmations for one run, with no parking or output effect.
- **Parking.** Each parking mechanism stays the property of the feature that
  owns it; this file only says when a run is `unattended`.
