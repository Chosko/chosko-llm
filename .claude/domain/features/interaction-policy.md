# Interaction policy

One shared, opt-in policy for how every interactive chosko-llm feature
behaves toward the person running it: which approval gates wait for them,
how gate summaries and closing reports are written, and how questions are
asked. A project chooses `attended` (the default) or `unattended` with one
line in its `CLAUDE.md`; any run can override it with `--attended` or
`--unattended`. The rules live once, in a new non-invocable
`interaction-engine` skill, and every interactive feature cites them by path
instead of restating them.

## Purpose

Two run-level skills already know an `unattended` mode
([unattended-parking](./unattended-parking.md)): a question nobody can answer
parks the task or the step instead of halting. Every other feature still
stops at every gate, however little the gate asks — "Approve and write?" on
a task the user has just described, a context-layer STOP on a scope report
nobody disputes — so a session left to run alone halts at the first
confirmation. And where a person is present, gates and reports print whole
drafts, before → after diffs, owner-step tables and reply grammars, and
questions lead with task numbers, slugs and section anchors the reader does
not have in context.

This feature gives every interactive feature one switch for the gates, one
shape for what it prints at a gate or at the end, and one shape for a
question. It restates no part of unattended-parking's parking and unparking
protocol; it widens where the policy comes from and what it governs, and
names the contracts that change.

## Scope and non-goals

In scope: the policy line, the per-run flags and the precedence that
resolves them; the three gate classes and what each does under `unattended`;
the output rules for gate summaries and closing reports; the question rules;
the `interaction-engine` skill that holds all of it; the adoption by every
interactive feature; and this repo's own `CLAUDE.md`, context layer and
domain layer describing the policy.

Deliberately out:

- **Unattended by default.** The policy is opt-in: an absent line is
  `attended`, and a project that never adds it keeps each feature's own gate
  behaviour.
- **Picking an option for the user.** No gate class and no "trivial
  question" exception changes the *Real decisions* rule below.
- **A new parking mechanism.** Parking stays what each feature already owns
  — task parking in `task-engine`, step parking in `runbook-run`, and
  objective runs in `objective-run`. A feature with no mechanism stops
  instead of parking.
- **The testing policy.** `Testing policy for /task-implement: …`, including
  `skip-tests-unattended`, stays an independent marker with its own meaning;
  the interaction policy neither reads nor sets it.
- **The `-y` flags.** The `-y` of `/context-update`, `/context-convert` and
  `/task-implement` stays as it is: a narrower switch that passes that
  feature's own confirmations for one run, with no parking or output effect.
- **Hard line limits.** The length rules are soft: about 8 lines for a gate
  summary, about 10 for a closing report, broken only when the content
  really needs it.
- **Read-only listings.** `/task-list`, `/runbook-list`, `/runbook-describe`,
  `/production-status`, `/follow-ups` and `/session-resume` print what they
  print; the output rules cover gate summaries and closing reports only.
  `/pipeline-check` takes only the plain-language rule, for its finding
  lines.
- **Setting the policy up.** Offering the `Interaction policy` line in
  `/project-setup` belongs to setup-sync, not here.
- **User-facing documentation.** `README.md`, `docs/reference.md` and the
  other user docs are rewritten when the experiment ships, not by this
  feature.

## Architecture

Built on the repo's existing shape per `technical-direction.md`: shipped
markdown skills whose runtime is Claude Code. It adds one skill, changes the
bodies of the interactive features, and adds no CLI surface and no script.

### The `interaction-engine` skill

A reference library shaped like `task-engine` and `pipeline-engine` (see
`.claude/context/task-engine.md` and `.claude/context/pipeline.md`):
`disable-model-invocation: true`, a body that says it is read by path and
never invoked, and the content in `references/`. It is its own skill rather
than a section of `pipeline-engine`, because `pipeline-engine` and
`task-engine` each cover only part of the features that need these rules.
Every interactive feature declares `requires: skill:interaction-engine` and
cites the files by a path relative to itself, per the home-path guard.

Three references, each opened only when it can apply:

- **`policy.md`** — the policy line, the flags, the precedence, how a parent
  run hands its policy down, the argument errors. Read by every interactive
  feature at argument parsing.
- **`gates.md`** — the three gate classes, the auto-pass summary, and the
  park-else-stop rule for real decisions. Read only when the policy resolves
  to `unattended`; under `attended` every gate waits and the file
  is never opened.
- **`messages.md`** — the output rules and the question rules. Read by every
  interactive feature before its first gate, question or closing report.

Later features extend the engine rather than restating it: the
"is orchestrate mode on?" check that orchestrate-mode adds lives here too.

### The policy and its resolution

One value per run, `attended` or `unattended`, resolved in this order, first
match wins:

1. `--attended` or `--unattended` passed to this run, or a policy handed down
   by the parent run (below);
2. the runbook's own `Execution policy:` header — `/runbook-run` only;
3. the project's `CLAUDE.md` line `Interaction policy: attended|unattended`;
4. `attended`.

This one rule absorbs `/task-implement`'s `--unattended` and `/runbook-run`'s
`--attended` / `--unattended`: their flags keep working as instances of
the shared flags, and their own resolution passages are replaced by a
citation. `/task-implement` gains `--attended`; `--skip-parked` stays a flag
of the two parking features, with its existing refusals.

**A parent hands its policy down.** A step agent, a delegated agent or any
subagent a run spawns resolves the policy its parent resolved, not the
`CLAUDE.md` line, which may say otherwise. `/runbook-run`'s step preamble
therefore states the resolved policy under **both** values — *This run is
attended* as well as *This run is unattended* — and a delegated agent's
fixed-size prompt keeps carrying it in its resolved-flag list. The declared
policy ranks with a typed flag. The wording rule stands: the sentence says
attended or unattended, never *non-interactive*.

`--attended` beside `--unattended` is an argument error in every feature. A
`CLAUDE.md` value outside the two words is an argument error naming it.
Every interactive feature accepts both flags, including those whose gates
are all class 2 or 3, so that a parent never needs to know which of its
children the flag would change.

### Gate classes under `unattended`

Every gate of every feature is in exactly one class. Membership is declared
at the gate, in the feature that owns it, as a one-word tag citing
`gates.md`; the engine holds the rule for each class, never a catalogue of
gates.

1. **Confirmation-only — passes on its own.** The gate asks nothing a
   prior instruction has not already settled. Under `unattended` it does not
   wait: the feature proceeds, and prints a short summary of what was
   written, naming the commit. Each auto-passed write is its own commit, and
   `git revert` of that commit is the undo. Class 1 is: `/task-add`'s
   "Approve and write?"; `/runbook-create`'s gate; every amend gate —
   `/architect`, `/product-design`, `/product-roadmap`, `/production-plan`,
   the `task-engine` amend arm; `/pipeline-revise`'s gate when the plan has
   no open questions; `/production-plan`'s main gate only when
   reconciliation found nothing; `/task-implement`'s feature `[DONE]`-flip
   proposal and its skip-tests "Proceed?"; the STOPs of `/context-build`,
   `/context-update` and `/context-convert`; the plan gates of
   `/refactor-codebase` and `/refactor-tests`, except for HIGH-risk items;
   `/project-setup`'s final "Approve and run?"; `/session-save`'s pointer
   prompt.
2. **Design-heavy — waits.** The gate is where the user's judgement is the
   product: `/product-design` and `/architect` confirming a conversational
   round. Every gate not listed in class 1 or class 3 is class 2 — among
   them `/product-roadmap`'s main gate, `/production-plan`'s main gate when
   reconciliation found something, the HIGH-risk items of a refactor plan,
   `/doc-consolidate`'s judgement gate and `/follow-ups-resolve`'s list
   approval. A new gate is class 2 until its owner tags it otherwise.
3. **Destructive — waits under every policy.** The gate guards something
   `git revert` cannot cleanly undo or that deletes the user's record:
   `/task-clean` and its backfill, `/runbook-prune`, `/runbook-clean`,
   `/product-design`'s discard, `/task-setup`'s overwrite, and any remote
   branch deletion. No flag and no policy passes it.

"Waits" under `unattended` means what a question means there: the item is
parked where the feature has a parking mechanism (tasks, runbook steps,
objective runs), and otherwise the run stops and ends its message with the
gate's summary and question. A parked gate stays the `approval gate` case of
unattended-parking — never pre-answerable, answered seen.

**`/runbook-run`'s gate rule gives way.** Its rule that a step never skips a
gate its skill defines because it "already knows" the answer — in the skill
body and in the inline contract — holds under `attended` and for class 2
and 3 under `unattended`. A class 1 gate passing on its own under
`unattended` is not a skipped gate; it is the gate's own behaviour under that
policy.

**A run that does not commit.** Under `--no-commit`, in a feature that
leaves its work uncommitted by default, or on a project whose `CLAUDE.md`
maps git to another VCS, `unattended` still applies. A class 1 gate passes
on its own and its summary names the uncommitted change instead of a
commit; discarding that change is the undo. Parking needs commits and a
branch, so a question there stops the run. `/task-implement`'s refusals of
`--unattended` beside `--no-commit` and on a non-git VCS apply to the typed
flag only; a policy from the `CLAUDE.md` line never makes `--no-commit`
unusable.

**Real decisions.** A question about the work — not a confirmation — is
parked whenever the feature can park, and otherwise ends the run with the
question. The agent never picks an option for the user. Questions are asked
together when the run stops, per *Questions* below.

### Output

These rules cover gate summaries and closing reports, under both
policies: only the gate classes depend on the policy.

- **No verbatim artifact previews at a gate.** No full drafts and no
  before → after diffs. A gate shows a concise plain-language summary: what
  changes, why, and what it affects. The user can reply `show` to see the
  full draft, and the feature then prints it and asks again. This replaces
  the "full draft, verbatim and unabridged" rules — `/runbook-run`'s question
  relay, the subagent and inline contracts, `/task-implement`'s delegated
  relay — and covers `/pipeline-revise`, every amend gate and `/task-add`'s
  manual-interventions block.
- **Soft length.** About 8 lines for a gate summary and about 10 for a
  closing report, exceeded only when the content needs it. Commit SHAs,
  diffstats and file paths are left out unless they matter to the reader's
  next decision — an auto-passed gate's commit always matters.
- **`/pipeline-revise`'s gate** is one verdict line, one plain sentence per
  change, then the questions. The owner-step table and the headless / GATED
  tokens stay internal and leave the chat; the lint bracket prints failures
  only; after an edit, only the changed line is re-shown.
- **Reply shortcuts** — `all but N`, `P1: Q1a` and the rest — keep working
  but are not printed each time; at most a one-line hint.

### Questions

These rules hold under both policies.

- **A message that asks ends with its questions.** Nothing follows them: no
  draft, no legend, no grammar list. Context goes above.
- **Plain language first, identifiers last in parentheses.** Say exactly
  what was not done and why; spend words on meaning, not on task numbers,
  slugs or section anchors the reader does not have in context. Bad: "task
  42's acceptance criterion not met, update password-auth § Session to
  match?". Good: "The login task was supposed to log users out after 30 idle
  minutes, but the code only ends sessions when the browser closes, because
  the session library has no idle timer. Should I change the design to
  accept that, or keep the 30-minute rule and add a task for it? (task 42,
  password-auth)".
- **One ask per stop.** A run collects its questions and asks them together
  when it stops.

The templates rewritten to these rules: `/task-implement`'s
feature-completion proposal; the `task-engine` stale-task prompt; the
parked-question lines of both parking mechanisms; `/pipeline-check`'s
finding lines, message first — its rule against rewording a `lint.md`
template points at the rewritten templates; `/architect`'s amend
evidence lines; and the one-line "Amended …" reports.

### Adoption

The interactive features — those with a gate, a question or a closing
report — declare the dependency and cite the engine: `/architect`,
`/product-design`, `/product-roadmap`, `/production-plan`,
`/pipeline-revise`, `/domain-setup`, `/project-setup`, `/task-setup`,
`/task-add`, `/task-implement`, `/task-iterate`, `/task-clean`,
`/runbook-create`, `/runbook-run`, `/runbook-clean`, `/runbook-prune`,
`/context-build`, `/context-update`, `/context-convert`,
`/refactor-codebase`, `/refactor-tests`, `/doc-consolidate`,
`/session-save`, `/follow-ups-resolve`, and `/pipeline-check` for the
plain-language rule only. `/unity-mcp-setup` is left alone: unity-mcp-removal
deletes it. The engines, the two suggesters, the claude-md artifacts, the
hook, the statusline and the read-only listings are not interactive and
take no dependency. Each adopting feature's change is a frontmatter line, a
row in its supporting-files table, a class tag on each gate, the two flags,
and the deletion of every passage the engine states.

Two passages of [unattended-parking](./unattended-parking.md) are
superseded and are rewritten with the domain layer: *the policy and its
carriers* (task-implement had no `CLAUDE.md` marker; the step preamble
carried the policy only when unattended) and *prompts with a default* (the
feature-flip proposal defaulted to *none*; under this policy it is class 1
and passes). This repo's own `CLAUDE.md`, `.claude/context/` and
`.claude/domain/` describe the policy in the same change.

## Data and state

- **`Interaction policy: attended|unattended`** — one line in a project's
  `CLAUDE.md`, absent by default, meaning `attended`. Read by every
  interactive feature; written by a human, or later by `/project-setup`.
- **`Execution policy:`** — the existing runbook header line, unchanged,
  ranking between the flag and the `CLAUDE.md` line for `/runbook-run`.
- **Gate class tags** — one per gate, in the body of the feature that owns
  the gate. No index of them exists anywhere.
- **In memory only:** the run's resolved policy, and the questions collected
  for the stop.

No new file in the project, no lockfile, no state file: the filesystem and
`CLAUDE.md` are the state.

## Interfaces and contracts

```
/<interactive feature> <args> --unattended   class 1 gates pass; real decisions park, else stop
/<interactive feature> <args> --attended     every gate waits, whatever CLAUDE.md says
/<interactive feature> <args> --attended --unattended   error
Interaction policy: unattended               (CLAUDE.md) the project's default for every run
```

| Contract today | Under this feature |
|---|---|
| `/task-implement --unattended`, `/runbook-run --attended/--unattended` with their own resolution | One precedence in `policy.md`; the flags become instances of it |
| Step preamble names the policy only when unattended | Names it under both values; a handed-down policy ranks with a flag |
| Every gate waits | Under `unattended`, class 1 passes with a summary naming its commit; classes 2 and 3 wait (park, else stop) |
| "Never skip a gate because you already know" | Holds except for class 1 under `unattended` |
| Approval gate shows the full draft verbatim | Shows a plain summary; `show` prints the draft |
| `/pipeline-revise` gate: owner-step table, headless/GATED, before → after | Verdict, one sentence per change, questions |
| Questions lead with ids, followed by drafts and grammars | Plain language first, ids last, questions last |
| Feature-flip proposal defaults to *none* when unattended | Class 1: passes, flipping the feature |

Failure contract: `--attended` beside `--unattended` is an argument error; a
`CLAUDE.md` policy value outside the two words is an argument error naming
it; an auto-passed gate whose commit fails stops the run exactly as that
feature's own commit failure does; a
missing `interaction-engine` install is caught by `requires:` at
`chosko-llm add` time.

## Dependencies

- [unattended-parking](./unattended-parking.md) — the parking mechanisms
  "waits" resolves to under `unattended`; its policy carriers are absorbed
  and two of its passages superseded.
- [shared-phase-engine](./shared-phase-engine.md) — the `requires:` field
  and the reference-library pattern the new engine follows.
- [runbook-suite](./runbook-suite.md) and [runbook-inline](./runbook-inline.md)
  — the relay block, the subagent and inline contracts whose verbatim-draft
  and never-skip-a-gate rules change.
- [task-implement-launcher](./task-implement-launcher.md) — the delegated
  prompt that hands the policy down and the relay whose draft rule changes.
- [pipeline-revision](./pipeline-revision.md) and
  [pipeline-engine](./pipeline-engine.md) — the gate rewritten to the
  output rules; `lint.md`'s finding templates rewritten to the question
  rules.
- [owner-amend-arms](./owner-amend-arms.md) — every amend gate is class 1,
  and the amend evidence and "Amended …" lines are rewritten.
- `scripts/check-home-paths.sh` — every citation of the engine is relative.

## Open questions

None outstanding. The scope of the output and question rules, runs that do
not commit, the `-y` flags and where a gate's class is recorded are recorded
above as decisions.
