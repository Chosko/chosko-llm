# Council gate

**Kept in step with `skills/architect/council-gate.md`.** The two files are
near-identical by necessity: skills install as self-contained folders, so
there is no shared-file mechanism between them. Edit one, edit the other. The
only intended differences are the fold-back target and the absence of a
PHASE 3 write barrier, both flagged inline below.

Read this ONLY when PHASE 6 has reached a genuine technical fork on the
**greenfield** branch and the triage below passes. It is never read
speculatively, and never on the brownfield branch.

## What this is

[claude-council](https://github.com/TorpedoD/claude-council) is a skill
chosko-llm ships (vendored under `skills/claude-council/`) and installs only
on request — `chosko-llm add skill:claude-council`. It stays opt-in, and this
gate still detects it rather than assuming it. It runs a decision through
five thinking lenses — Red Team
(pre-mortem), First Principles (assumption reframing), Expansionist (option
generation), Outsider (cross-domain method), and Executor (feasibility) —
then anonymises them, peer-reviews, forces an adversarial debate when
consensus looks artificially clean, and synthesises a verdict that preserves
minority dissent.

`/product-design` delegates to it; it does not reimplement it and does not
require it. When it is absent, everything below is skipped and the run
proceeds exactly as it would have.

PHASE 6 is the highest-leverage place in the whole pipeline to get a decision
wrong. `technical-direction.md` becomes a standing constraint that
`/architect` adopts rather than re-argues, so an unexamined choice here
propagates into every feature document downstream.

## Step 1 — Detection

Probe for the skill:

```
${CLAUDE_HOME:-$HOME/.claude}/skills/claude-council/SKILL.md
```

Honor `CLAUDE_HOME` when it is set — never hardcode `~/.claude`; this repo's
scripts resolve paths that way and a shipped body must not disagree with them.

**If the file does not exist, stop here and say nothing.** Proceed with the
inline propose-and-recommend flow unchanged. Do not mention claude-council,
do not suggest installing it, do not note its absence in the final report.
An authoring run must not advertise an uninstalled optional dependency
mid-flight — a user who wants to discover it will find it in the README.

## Step 2 — Triage

claude-council rejects unsuitable questions itself, but a rejected run still
costs a round trip and interrupts the design conversation. Filter first.

**Offer the council only when all of these hold:**

- The fork is a genuine trade-off — two or more defensible options whose
  costs land in different places.
- The stakes are nameable. You can say what going the wrong way costs, in
  rework, in doors closed, or in constraints inherited downstream.
- The decision is expensive to reverse once `technical-direction.md` is
  written and features are architected against it.

**Never offer when:**

- **The branch is brownfield.** PHASE 6's brownfield path is
  confirm-and-record over a stack that already exists; there is no trade-off
  to pressure-test, and convening a council there re-litigates what the
  codebase settled long ago. This gate belongs to the greenfield branch only.
- The blocker is a **missing fact**, not a judgment. Ask the user directly —
  the council reasons about trade-offs, it cannot supply facts about the
  product that only the user holds.
- One option is obviously right and the alternatives exist only for
  symmetry.
- The choice is cheap to reverse later without touching a contract.

When triage fails, proceed inline without comment. Do not announce that the
council was considered and rejected.

## Step 3 — Frame the question

A vague question wastes all five lenses. Frame it as a decision, not a topic,
and give it enough context to be judged without the conversation:

```
DECISION: <the choice, as a question with named options>
CONTEXT:  <which PHASE 4/5 features force this axis; the constraints already fixed>
STAKES:   <what the wrong answer costs, concretely>
OPTIONS:  <each option, one line, with its main cost>
PRIOR:    <what you would recommend absent the council, and why>
```

Include `PRIOR`. A council that has to reconstruct your reasoning spends
lenses on rediscovery; one that can attack a stated position spends them on
the actual decision.

Name the features that force the axis — PHASE 6 opens by reading those back
for exactly this reason, and a council question that omits them gets a
generic stack pitch in return.

## Step 4 — Offer

Ask once, in one line, and wait:

> This is a real fork — <the decision in a half-sentence>. Convene the
> council on it? It runs five analytical lenses with peer review and returns
> a verdict plus any minority dissent (~90s).

Silence is not approval. On no, proceed inline exactly as today and do not
ask again for this same fork. On yes, continue.

## Step 5 — Invoke

```
/claude-council "<the framed question from Step 3>"
```

**Pass no mode argument.** claude-council's own triage picks Quick, Standard,
or Deep from the stakes, and Standard auto-escalates to Deep when advisor
confidence comes back low. Naming a mode here overrides judgement that is
better informed than this gate's, and would need re-checking whenever
upstream changes its mode thresholds.

## Step 6 — Fold the result back

The council informs the recommendation; **it does not make the decision.**
`/product-design`'s existing rule stands unchanged: the user decides when
PHASE 6 is done, and phases never advance on their own. Never present a
verdict as settled, and never treat a confident council as the user's
go-ahead.

- **The verdict and its reasoning** feed the recommendation you present. Say
  plainly that it came from the council, so the user can weigh it as one
  input rather than as your unaided judgement.
- **The minority dissent ledger** goes into `product-design.md`'s
  design-decisions section in PHASE 7's write-back, as a recorded reservation
  against the direction taken. Surviving dissent is a live concern someone
  should revisit, not a resolved one — do not flatten it into the verdict.
  If the axis is one `technical-direction.md` records as explicitly open,
  the dissent belongs in that document's own open-decisions section instead.
  *(In `skills/architect/council-gate.md` this fold-back targets the feature
  document's Open questions section instead.)*
- **A verdict that contradicts your prior** is a result, not a problem.
  Report the contradiction rather than quietly re-deriving your way back to
  the original position.

## Step 7 — Artifacts

claude-council writes two files into the working directory:

```
council-report-<ts>-q<sha>.html
council-transcript-<ts>-q<sha>.md
```

**These are never added to `WRITTEN`, and never staged by `--commit`.** They
are the council's output, not this skill's. Committing generated HTML into a
user's repository is a side effect `/product-design` has no mandate for, and
the DO NOT rule that `--commit` stages only explicit `WRITTEN` paths — never
a catch-all — already forbids sweeping them in.

*(`/product-design` has no "write nothing before PHASE N" prohibition to
carve out — it stubs documents in PHASE 1 and writes in PHASE 3, 5, and 7 —
so unlike the `/architect` copy, no exception clause is needed here.)*

Name both paths in the final report so the user can keep or delete them. Do
not delete them yourself — the user may want the transcript.

## Step 8 — Record it

**Do not touch the `design-process.md` stage marker.** It records phase
transitions, and a consultation inside PHASE 6 is not one; writing to it here
would make a resumed run look like it stopped somewhere it didn't.

PHASE 7's final report states, in one line: that the council was convened,
the question, the run SHA, the verdict, and where the two artifacts landed.
