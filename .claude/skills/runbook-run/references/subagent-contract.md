# The subagent contract

Fixed text. `OPERATING RULES` is pasted **verbatim** as the last section of
every spawned step prompt, `RELAY CHILD RULES` **verbatim** ahead of it into a
relay child's prompt only (THE SPAWN RELAY protocol step 1). Both are reference
text rather than prose the orchestrator composes because each must be identical
in every step of every runbook: a contract that is re-worded per spawn is a
contract the agent can be talked out of.

Five placeholders, and nothing else, are substituted:

- `<RUNBOOK>` — the runbook's name, e.g. `implement-ecc-import`.
- `<N>` — the step number being executed.
- `<FILE>` — the runbook body's path, exactly as its index block's `File:` line
  holds it, e.g. `.claude/runbooks/3-implement-ecc-import.md`.
- `<PROMPT>`, `<RESULT>` — the `prompt:` and `result:` paths the `SPAWN REQUEST`
  named. `RELAY CHILD RULES` only.

The relay rule below names no directory of its own: the subagent chooses one
under the OS temp directory and reports it, and the file names are built from
`<RUNBOOK>` and `<N>`. That is deliberate — a relay-path placeholder would be a
path the orchestrator has to invent before it knows whether the relay will be
used at all.

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
  If the work failed or could not be completed, say so plainly instead of
  `DONE`.
```

## Paste ends

---

## RELAY CHILD RULES — paste from here, verbatim

```
RELAY CHILD RULES

- Read the file at <PROMPT>; do exactly what it asks.
- Write your full report to <RESULT>.
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
- **The dirty-tree prompt answers itself.** The orchestrator writes `[~]` and
  `[RUNNING]` before it spawns, uncommitted by design, so the step's
  `/task-implement` meets exactly those two dirty paths at pre-flight and would
  otherwise end every step under `QUESTIONS FOR USER` on a question whose
  answer is already known. The rule holds in every spawned step, under either
  execution policy, because the prompt fires under both and its answer is the
  same under both. `proceed`, never `include`, because folding the markers into
  the task's commit would commit the in-flight state COMMIT CADENCE forbids;
  anything else dirty is not this case and still reaches the user. The same
  rule, word for word, is in `inline-contract.md` for the session that
  executes a step itself.
- **The two unattended rules, conditional on the preamble.** Under the
  `unattended` policy the orchestrator does not relay a question: it parks the
  step (`[P]`, the question in `Context:`) and the agent is never resumed —
  the step re-runs from the start, in a fresh subagent, once the answer is
  written. The condition is the preamble's one sentence and nothing else,
  because the block is fixed text and the policy is per run; an attended
  step's agent is non-interactive too, and that must not trigger them.
  *Clean tree before asking* because the run goes on: the next step's agent
  meets a dirty-tree prompt listing whatever this one left, on changes it
  cannot know, and the re-run has no use for them either — the only
  work-in-progress worth keeping is what a skill already put on
  `park/task-<N>`, which is that task's, not this agent's. Saying so in the
  block is what lets the orchestrator go on without looking, since it never
  reviews. *Answer from `Context:`* because the step re-runs whole and the
  invoked skill will ask its question again — `/task-implement`'s pre-ask on
  a `[PARKED]` task, a gate, a prompt — and an agent that relayed it back
  would park the step a second time on a question already answered, forever.
- **Default commit behaviour, no invented flags.** A step's prompt is often a
  bare slash-command invocation whose commit behaviour the user already chose
  when they authored it. An agent that helpfully adds `--no-commit` (or drops
  it) changes what the runbook does.
- **Never edit the runbook or the index.** The orchestrator writes exactly two
  files and a subagent writes everything else. Two writers on the runbook is
  how a `Done:` line gets lost. The body is named by `<FILE>` rather than built
  from `<RUNBOOK>` because a body's file name is not derivable from its name —
  it may be `<id>-<name>.md` or a legacy `<name>.md`, and only `File:` says
  which. **`<FILE>` is an acceptable placeholder where a relay path was not**:
  the orchestrator already holds `File:` from its *Resolve* step before it
  spawns anything, so filling it invents nothing, whereas a relay path is one
  it would have to make up before knowing whether the relay is used at all.
  `<PROMPT>` and `<RESULT>` pass the same test: the `SPAWN REQUEST` names both.
- **No feature-flip question.** Relayed as `QUESTIONS FOR USER` it would block
  the run mid-step; the orchestrator's closing report asks once, after the run.
- **Naming the runbook and step.** It orients the agent, it makes its report
  attributable, and it is what lets a step's subagent call
  `/runbook-create --append` with no name argument.
- **`SPAWN REQUEST`.** In some environments — cloud sessions among them — a
  subagent cannot spawn a subagent, so a step whose prompt invokes something
  that wants a child agent (`/task-implement --review --rounds 2`) has nowhere
  to put it. The two things an agent does instead are both bad: doing the
  child's work inline destroys the fresh context that was the entire reason for
  a child (an implementer reviewing its own diff is not a review), and dropping
  it silently produces a `DONE` report for work that did not happen. So the
  rule names a third option and makes it the required one. **Detection lives
  here rather than in the orchestrator** because only the agent that needs the
  tool can tell whether it has it; an orchestrator-side probe measures the
  orchestrator's environment and costs a spawn per run to do it. The paths go
  under `$TMPDIR` so no scratch file can ever land in a commit, and "one child
  at a time" keeps the relay sequential, exactly like the question relay it is
  modelled on. **The file names are dictated rather than left to the agent**
  because two runs of different runbooks share one `$TMPDIR`, and two agents
  each reaching for the obvious name would hand one runbook's child the other's
  prompt — a collision the orchestrator cannot detect, since it never opens
  either file. `<RUNBOOK>` and `<N>` are already substituted here, so naming
  them costs no further placeholder.
- **`DONE` plus the terse report.** `DONE` is the literal marker the
  orchestrator classifies on. The sha and the diffstat are exactly what the
  default `Done:` line records, and asking the agent for the diffstat is what
  lets the orchestrator write that line without running git — a cheap
  orchestrator is the thing being protected. Decisions and wrong premises are
  conditional, as on the `Done:` line itself, and feed fact propagation into
  later steps. The exclusion list names what agents were observed dumping into
  the line — review tallies, touched files, restated prompts, resumption
  narrative — until runbook bodies grew unreadable. "Say so plainly instead of `DONE`" exists because an agent that
  fails and still writes `DONE` out of politeness produces a runbook that lies.
- **`RELAY CHILD RULES`.** The child's obligations were orchestrator-composed
  prose until 2026-09-20, when step 83 of `m3-tasks-implementation` returned its
  report in its turn and wrote no result file, suspending its caller on a file
  that did not exist.
- **The self-check and the bare `DONE`.** Step 85 of the same run wrote the file
  but ended `Result file written: <path>`, which THE FOUR RESULT CASES reads as
  failure.
