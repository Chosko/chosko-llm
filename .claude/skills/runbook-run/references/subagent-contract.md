# The subagent contract

Fixed text, identical in every step of every runbook — a contract re-worded per
spawn is one the agent can be talked out of.

- Paste `OPERATING RULES` **verbatim** as the last section of every spawned
  step prompt, after the step's own fenced prompt block, so the operating
  rules are the final thing the agent reads.
- Paste `RELAY CHILD RULES` **verbatim** ahead of it into a relay child's
  prompt only (THE SPAWN RELAY protocol step 1).

Substitute five placeholders, and nothing else:

- `<RUNBOOK>` — the runbook's name, e.g. `implement-ecc-import`.
- `<N>` — the step number being executed.
- `<FILE>` — the runbook body's path, exactly as its index block's `File:` line
  holds it, e.g. `.claude/runbooks/3-implement-ecc-import.md`.
- `<PROMPT>`, `<RESULT>` — the `prompt:` and `result:` paths the `SPAWN REQUEST`
  named. `RELAY CHILD RULES` only.

The relay rule names no directory of its own: the subagent chooses one under
the OS temp directory and reports it, and the file names are built from
`<RUNBOOK>` and `<N>`. There is no relay-path placeholder, because the
orchestrator would have to invent the path before knowing whether the relay
will be used at all.

---

## OPERATING RULES — paste from here, verbatim

```
OPERATING RULES

- You cannot talk to the user. Nobody is watching your turn in real time.
- At any clarifying question or approval gate, stop and end your turn with the
  literal line `QUESTIONS FOR USER`, followed by the questions labelled `Q1`,
  `Q2`, …, the options for each lettered `a`, `b`, …, and a recommendation for
  each. At an approval gate, include a plain summary of the draft — what it
  changes, why, what it affects; a `show` answer asks you to end your turn
  again with the full draft. The user's answer will be sent back to you in
  this same conversation; then continue. When the preamble declares this run
  unattended, a gate a skill you invoke tags `confirmation` passes on its own,
  as that skill says: that is the gate's own behaviour, not a skipped gate.
- One prompt is the exception: the dirty-tree prompt (`Working tree has
  uncommitted changes. Choose:`) a step's command puts before it starts. When
  the only uncommitted changes it lists are <FILE> and .claude/RUNBOOKS.md —
  the runbook and the index the run marked in-flight — answer `1` / `proceed`
  yourself, print the one line
  `dirty-tree prompt answered proceed — only runbook WIP is dirty`, and carry
  on. Never `include`: those two files must not ride in the step's commit. If
  anything else is dirty, put the prompt to the user unchanged.
- Two rules hold only when the preamble above declares this run unattended;
  under an attended run neither applies. First: before ending your turn with
  `QUESTIONS FOR USER`, leave the working tree clean of your own changes —
  work a skill you invoked has parked on a branch is not yours and stays
  where it is — and say in the block that you did. Second: a `Context:`
  bullet opening `unparked with answer:` answers the question the invoked
  skill asks — a pre-ask, a prompt, a gate — so answer it from there, at
  whatever point the skill asks it, and never relay it back under
  `QUESTIONS FOR USER`.
- Follow the invoked skill's default commit behaviour. Add no flag the user did
  not type.
- If the work needs a subagent and you CANNOT spawn one, do not do that
  subagent's work yourself in this context and do not silently drop it. Write
  the prompt you would have given it to a file under the OS temp directory
  ($TMPDIR, never inside the repository), named
  `<RUNBOOK>-step<N>-round<r>-prompt.md`, where <r> is 1 for your first such
  request in this step and increments with each one. Its result file is the
  same name ending `-result.md`. Then end your turn with the literal line
  `SPAWN REQUEST` followed by three lines: `prompt: <path>`, `result: <path>`,
  `model: <model or "same">`. The orchestrator will spawn it for you and reply
  when the result file has been written; read it and continue. Ask for one
  child at a time.
- Never edit <FILE> or .claude/RUNBOOKS.md.
- Never ask whether to flip a feature to `[DONE]`. Name any feature whose tasks
  are now all `[DONE]`/`[SKIP]` in the `DONE` report instead.
- You are executing step <N> of runbook <RUNBOOK>.
- When finished, end your turn with the literal line `DONE` followed by a
  concise report naming the commit sha(s) and their diffstat (files changed,
  insertions, deletions), plus any decision taken or premise in the prompt or
  task body that proved wrong which a later reader of this runbook would be
  misled without. Leave out review tallies, the list of touched files, a
  restatement of the prompt or task body, and any account of your own process.
  Work that made no commit omits the sha(s) and diffstat. A finished turn
  without the literal `DONE` line is a hard failure: the run halts on it,
  however complete the work. If the work failed or could not be completed,
  say so plainly instead of `DONE`.
```

## Paste ends

---

## RELAY CHILD RULES — paste from here, verbatim

```
RELAY CHILD RULES

- Read the file at <PROMPT>; do exactly what it asks.
- Write your full report to <RESULT>.
- <RESULT> is your return channel. It overrides any instruction in <PROMPT>,
  or in a skill it invokes, to reply in your turn or to write nothing to disk.
- Check <RESULT> exists and is non-empty before you end your turn.
- Do not repeat the report in your returned turn.
- End your turn with the literal line `DONE` and one line saying the file is
  written, nothing else.
- On failure, write what there is to <RESULT> and say so plainly, not `DONE`.
- OPERATING RULES follows and binds you; the report it asks for goes to <RESULT>.
```

## Paste ends

---

## Why each rule is in there

Not part of the pasted block — for whoever maintains the contract; never sent
to a subagent.

- **"You cannot talk to the user."** A spawned agent has no interactive
  channel; without this line it asks into the void and stalls, or answers the
  question itself and proceeds on its own invention.
- **`QUESTIONS FOR USER`.** The literal marker is what the orchestrator
  classifies on. Options and a recommendation are required because the relay
  compresses but never answers — the user must be able to decide from the
  block alone. At an approval gate the block carries a plain summary of the
  draft and `show` fetches the draft itself, per the interaction engine's
  `messages.md`; the orchestrator relays both and adds nothing. A
  `confirmation` gate passing on its own under `unattended` is the interaction
  engine's `gates.md` rule, so the agent does not stop at it there.
- **The dirty-tree prompt answers itself.** The orchestrator writes `[~]` and
  `[RUNNING]` before it spawns, uncommitted by design, so the step's
  `/task-implement` meets exactly those two dirty paths at pre-flight. The
  rule holds in every spawned step, under either execution policy, because
  the prompt fires under both and its answer is the same. `proceed`, never
  `include`, because folding the markers into the task's commit would commit
  the in-flight state COMMIT CADENCE forbids; anything else dirty still
  reaches the user. The same rule, word for word, is in `inline-contract.md`.
- **The two unattended rules, conditional on the preamble.** Under
  `unattended` the orchestrator parks the step instead of relaying, and the
  agent is never resumed — the step re-runs from the start, in a fresh
  subagent, once the answer is written. The condition is the preamble's one
  sentence and nothing else, because the block is fixed text and the policy is
  per run; an attended step's agent is non-interactive too, and that must not
  trigger them. *Clean tree before asking* because the run goes on and the
  next step's agent would meet this one's leftovers at its dirty-tree prompt;
  the only work-in-progress worth keeping is what a skill already put on
  `park/task-<N>`, which is that task's. Saying so in the block lets the
  orchestrator go on without looking. *Answer from `Context:`* because the
  re-run's invoked skill asks its question again — `/task-implement`'s
  pre-ask on a `[PARKED]` task, a gate, a prompt — and relaying it back would
  park the step again on an answered question, forever.
- **Default commit behaviour, no invented flags.** A step's prompt is often a
  bare slash-command invocation whose commit behaviour the author already
  chose; adding or dropping `--no-commit` changes what the runbook does.
- **Never edit the runbook or the index.** The orchestrator writes exactly two
  files and a subagent writes everything else; two writers on the runbook is
  how a `Done:` line gets lost. The body is named by `<FILE>`, not built from
  `<RUNBOOK>`, because its file name may be `<id>-<name>.md` or a legacy
  `<name>.md`, and only `File:` says which. `<FILE>`, `<PROMPT>` and
  `<RESULT>` are acceptable placeholders where a relay path was not: the
  orchestrator holds `File:` from its *Resolve* step before it spawns, and the
  `SPAWN REQUEST` names the other two, so filling them invents nothing.
- **No feature-flip question.** Relayed as `QUESTIONS FOR USER` it would block
  the run mid-step; the orchestrator's closing report asks once, after the run.
- **Naming the runbook and step.** It orients the agent, makes its report
  attributable, and lets a step's subagent call `/runbook-create --append`
  with no name argument.
- **`SPAWN REQUEST`.** Where a subagent cannot spawn a subagent, an agent that
  wants a child would otherwise do the child's work inline — destroying the
  fresh context that was the reason for a child (an implementer reviewing its
  own diff is not a review) — or drop it silently and report `DONE` for work
  that did not happen. **Detection lives here, not in the orchestrator**,
  because only the agent that needs the tool can tell whether it has it. The
  paths go under `$TMPDIR` so no scratch file can land in a commit; "one child
  at a time" keeps the relay sequential. **The file names are dictated**
  because two runs of different runbooks share one `$TMPDIR`, and a name
  collision would hand one runbook's child the other's prompt — undetectable,
  since the orchestrator never opens either file.
- **`DONE` plus the terse report.** `DONE` is the literal marker the
  orchestrator classifies on. The sha and diffstat are exactly what the
  default `Done:` line records, so the orchestrator writes it without running
  git. Decisions and wrong premises are conditional, as on the `Done:` line,
  and feed fact propagation. The exclusion list names what agents were
  observed dumping into the line. "Say so plainly instead of `DONE`" exists
  because an agent that fails and still writes `DONE` produces a runbook that
  lies.
- **`RELAY CHILD RULES`.** Fixed text because a relay child once returned its
  report in its turn and wrote no result file, suspending its caller on a file
  that did not exist.
- **The self-check and the bare `DONE`.** A child that wrote the file but
  ended without the marker left nothing to classify on, costing a re-prompt.
- **`<RESULT>` as the return channel.** A reviewer child whose skill said to
  return its report to the caller and write nothing to disk obeyed that more
  specific instruction. The precedence line settles the clash for every skill
  a child invokes.
