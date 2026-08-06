# Council gate

**Kept in step with `skills/product-design/council-gate.md`.** The two files
are near-identical by necessity: skills install as self-contained folders, so
there is no shared-file mechanism between them. Edit one, edit the other. The
only intended differences are the fold-back target and the PHASE 3 write
barrier, both flagged inline below.

Read this ONLY when PHASE 2 has reached a genuine design fork and the triage
below passes. It is never read speculatively, and never on a run that reaches
no fork.

## What this is

[claude-council](https://github.com/TorpedoD/claude-council) is a separately
installed skill that runs a decision through five thinking lenses — Red Team
(pre-mortem), First Principles (assumption reframing), Expansionist (option
generation), Outsider (cross-domain method), and Executor (feasibility) —
then anonymises them, peer-reviews, forces an adversarial debate when
consensus looks artificially clean, and synthesises a verdict that preserves
minority dissent.

`/architect` delegates to it; it does not reimplement it and does not require
it. When it is absent, everything below is skipped and the run proceeds
exactly as it would have.

## Step 1 — Detection

Probe for the skill:

```
${CLAUDE_HOME:-$HOME/.claude}/skills/claude-council/SKILL.md
```

Honor `CLAUDE_HOME` when it is set — never hardcode `~/.claude`; this repo's
scripts resolve paths that way and a shipped body must not disagree with them.

**If the file does not exist, stop here and say nothing.** Proceed with the
inline propose-and-recommend flow unchanged. Do not mention claude-council,
do not suggest installing it, do not note its absence in the closing report.
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
- The decision is expensive to reverse once tasks are generated from it.

**Never offer when:**

- The blocker is a **missing fact**, not a judgment. That is a PHASE 1
  clarification — ask the user directly.
  `./tech-stack-selection.md` already says this about the stack, and it
  generalises: the council reasons about trade-offs, it cannot supply facts
  about the product that only the user holds.
- An existing stack, or a present `technical-direction.md`, already settles
  the question. Adopting what exists is not a fork.
- One option is obviously right and the alternatives exist only for
  symmetry.
- The choice is cheap to reverse — a naming decision, an internal module
  boundary that can move later without touching a contract.

When triage fails, proceed inline without comment. Do not announce that the
council was considered and rejected.

## Step 3 — Frame the question

A vague question wastes all five lenses. Frame it as a decision, not a topic,
and give it enough context to be judged without the conversation:

```
DECISION: <the choice, as a question with named options>
CONTEXT:  <what the feature must do; the constraints already fixed>
STAKES:   <what the wrong answer costs, concretely>
OPTIONS:  <each option, one line, with its main cost>
PRIOR:    <what you would recommend absent the council, and why>
```

Include `PRIOR`. A council that has to reconstruct your reasoning spends
lenses on rediscovery; one that can attack a stated position spends them on
the actual decision.

Keep it to what the council needs. Do not paste the feature document.

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
`/architect`'s existing rule stands unchanged: PHASE 2 does not end until the
user confirms the architecture. Never present a verdict as settled, and never
skip the confirmation because the council was confident.

- **The verdict and its reasoning** feed the recommendation you present. Say
  plainly that it came from the council, so the user can weigh it as one
  input rather than as your unaided judgement.
- **The minority dissent ledger** goes into the feature document's **Open
  questions** section in PHASE 3. Dissent that survived synthesis is exactly
  what that section exists to hold — a live concern someone should revisit,
  not a resolved one. Do not flatten it into the verdict.
  *(In `skills/product-design/council-gate.md` this fold-back targets
  `product-design.md`'s design-decisions section instead.)*
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
user's repository is a side effect `/architect` has no mandate for, and
`--commit` stages explicit paths only.

*(`/architect` only — this paragraph has no counterpart in the
`/product-design` copy.)* Writing them also collides with the DO NOT rule
that nothing is written before PHASE 3. That rule carries an explicit
carve-out for these artifacts, alongside the PHASE 2 progress marker's. The
carve-out is narrow: it permits claude-council to write its own two files,
and permits nothing else.

Name both paths in the closing report so the user can keep or delete them.
Do not delete them yourself — the user may want the transcript.

## Step 8 — Record it

Write the outcome into the PHASE 2 progress marker
(`.claude/domain/features/<target-slug>.architect-progress.md`) as soon as the
council returns, in the marker's existing bullet register:

```
- Council convened on <the decision, in a half-sentence> → <verdict>.
  Dissent: <one line, or "none recorded">. Run SHA <sha>.
```

Without this, a session interrupted after the council and resumed later would
re-convene it — paying another full run for an answer already bought.

The closing report states, in one line: that the council was convened, the
question, the run SHA, the verdict, and where the two artifacts landed.
