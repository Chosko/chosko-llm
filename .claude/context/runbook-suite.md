# Features: runbook suite

## Overview

Covers the runbook asset kind's shipped artifacts — the `runbook-*` commands
and skills — plus `follow-ups` and `follow-ups-resolve`. Feature kinds and the
frontmatter contract every one of them follows: [features.md](./features.md).

- `skills/runbook-run/` — orchestrator of the runbook asset kind
  (`.claude/runbooks/<id>-<name>.md` bodies at the path each index block's
  `File:` holds + `.claude/RUNBOOKS.md` index; body is
  source of truth, index's `Status:`/`Steps:` derived and rebuildable from it —
  the id and its counter are the one exception, assigned rather than derived).
  **Skill not command** because `cmd-add` copies a skill folder with `cp -R`
  while a command is one file carrying nothing: it hosts `references/
  runbook-schema.md` (store, body schema, the FIVE step markers
  `[ ]`/`[~]`/`[x]`/`[!]`/`[P]` — `[P]` parked: a `Context:` bullet
  `- <date> parked: <question>` carries the question verbatim, options
  included, never an approval-gate draft; not done in `Steps:`, committed
  like `[x]`/`[!]`, never beside `[~]`, not a skip, cleared to `[ ]` with
  `- <date> unparked with answer: <text>` — the four statuses
  `[PENDING]`/`[RUNNING]`/`[FAILED]`/`[DONE]` (a runbook waiting on a `[P]`
  step is `[PENDING]`), the optional header `Execution policy:
  attended|unattended` (absent = `attended`; any other value an argument
  error at run time), the index `Parked: steps <ids>` line present only while
  a step is `[P]` — `Failed at:`'s rule applied again — the optional
  per-step `Needs:` field, index block + its `Last runbook number:` counter and
  per-runbook **id**, plus two header fields of the body's own: the
  `Last step number:` step counter — highest id ever assigned, only ever
  increases, never `max()`, next unused id = value + 1 — and the optional
  `Archive:` id list `/runbook-prune` writes, whose ids **count as `[x]`**
  everywhere a marker is read, keeping a surviving `Depends on:` resolvable and
  the `Steps:` count unchanged by a prune; a body with no `Last step number:`
  line is backfilled in place — to the highest id present, counting steps about
  to be removed — by whichever of `/runbook-create --append` and
  `/runbook-prune` writes it first)
  and `references/subagent-contract.md` (two fenced blocks: OPERATING RULES,
  pasted verbatim into every spawned prompt, and RELAY CHILD RULES, pasted
  verbatim ahead of it into a relay child's prompt only — five placeholders,
  `<RUNBOOK>`, `<N>` and `<FILE>` (the body's `File:` path, for the never-edit
  rule; relay file names stay built from `<RUNBOOK>`/`<N>`), plus
  `<PROMPT>`/`<RESULT>` on the child block alone,
  and it carries the `SPAWN REQUEST` rule; OPERATING RULES make the literal
  `DONE` line mandatory — a finished turn without it is a hard failure however
  complete the work, and work that made no commit omits the sha and diffstat;
  RELAY CHILD RULES carry a precedence line: `<RESULT>` is the child's return
  channel, overriding any instruction in `<PROMPT>` or a skill it invokes to
  reply in the turn or write nothing to disk), both cited by the other three
  by a `./references/<f>.md` path relative to the citing body.
  `references/inline-contract.md` holds the fixed inline rule set that replaces the OPERATING RULES under
  `--inline`, read only when that flag is passed. Both contracts carry, as
  fixed text, one unconditional rule — a step command's dirty-tree prompt
  listing only the runbook and the index is answered `proceed` (never
  `include`) by the step's agent or the inline session, one line said — and
  two rules conditional on the preamble's `unattended` sentence: leave the
  tree clean of your own changes before ending with a question (work a skill
  parked on a branch is not yours) and say so; and a `Context:` bullet
  `unparked with answer:` answers the invoked skill's question, never relayed
  back. `references/parking.md`, read once per run on two triggers only
  (policy resolved to `unattended` in step 1; step 3 selecting or blocked by
  a `[P]` step), holds the fifth result row, the end branch, unparking, the
  pre-ask, mid-run answers, the rejections and the attended handling of a
  `[P]` step — bookkeeping in the two files only, never a task body, branch
  or diff. `references/step-amend.md` (amending one pending step: strike it as `[x]` with a `Done:` line opening
  `struck — <reason>` and no commit sha, never deleted or renumbered; insert
  through `/runbook-create --append --before`/`--after`; add dated `Context:`
  facts; the prompt block immutable, so a wrong prompt is struck and a
  corrected step inserted; a `[RUNNING]` runbook accepting changes only after
  its current step), is never read by this body — whatever amends a step
  (`pipeline-revise`) reads it by path, and reads and writes
  the body at `File:`. `references/body-migration.md` (the lazy rename
  of a legacy `<name>.md` body: plain `mv` to `<id>-<name>.md` then rewrite
  `File:`, nothing staged until the writing command's one commit, which names
  old path, new path and the index explicitly — never `git mv`, whose staged
  rename a step's own commit would carry off; never while
  `[RUNNING]`; a taken target path stops, never overwritten; non-git VCS
  mapping), is read ONLY by `/runbook-run` and `/runbook-create --append`, and
  only after the schema's one-sentence check finds a `File:` file name not
  beginning `<id>-`. No sweep, no migration script. It IS the dependency
  the rest of the runbook suite declares — and declares two itself,
  `requires: command:follow-ups, skill:follow-ups-resolve` (the second for
  the mid-run follow-up protocol and the post-report execution of approved
  items): its CLOSING THE RUN section applies the first
  command's rules — body read by name, never invoked — as the *Follow-ups*
  group of the closing report, once per run (completion, a `--to`/`--only`/
  `--steps` bound, the end branch, a user-requested stop after a step, or a
  failure halt), after the final commit, adding no commit; with the command
  absent the group holds the run's own items only, silently; in the default
  spawned mode that
  reading covers the step subagents' result reports — already in hand from
  step 7, so no file is opened and neither the "reads three files" contract
  nor the spawn relay's never-read-a-relay-file rule is touched.
  **The execution policy**, one value per run:
  `--attended` / `--unattended` when passed, else the header
  `Execution policy:`, else `attended`; resolved last in step 1, never
  written back. `--unattended`: a step that asks is parked and the run goes
  on; at launch, unless `--skip-parked` (requires `--unattended`), the same
  **pre-ask** as `/task-implement`'s, over every `[P]` step in range, each
  answer unparking its step at once in one bookkeeping commit. `--attended` overrides a header
  `unattended`; both together an error. All three compose with `--inline`.
  Under `unattended` the spawned preamble carries ONE sentence declaring the
  run unattended (never *non-interactive*, which an attended step's agent is
  too) — what turns on the contract's two conditional rules and what
  `/task-implement` reads as its own UNATTENDED. **Handles**: every parked
  question printed carries a `P<n>` handle, its questions `Q1`, `Q2`, … and
  options `a`, `b`, … (`Unpark P1: Q1a, Q2b`, an example, not a grammar),
  one sequence per run (pre-ask from `P1`, later parks the next unused); a
  reply by handle, step id or title mid-run
  (read at step 8, after the commit) or after the report unparks the step —
  `unparked with answer:` bullet, `[ ]`, `Parked:` rewritten, one bookkeeping
  commit — and it is the next step selected, stated as a rule; rejected with
  one line and nothing recorded: a number never printed, a second answer, an
  answer to an approval-gate item. **Ids**: every runbook carries one beside its kebab-case name,
  and every command taking a runbook accepts `<id>`, `<name>` or
  `<id>-<name>`, resolved in order: all digits → id; exact name → that block;
  `<digits>-<rest>` → that block only when block `<digits>` is named `<rest>`,
  else an error naming the id's real runbook (never a fallback to either
  half); anything else unknown, listing what exists. A legacy name matching
  two blocks is reported as an ambiguity. The id is an alias, never the
  identity: it appears in the body's file name, but the body carries no id,
  messages name the runbook, and **every command opens the body at `File:`,
  never a path built from the name** (a legacy `<name>.md` value stays
  correct). `Last runbook number:` only ever increases; survivors are never
  renumbered and a pruned id is never reused (`TASKS.md`'s rule, same reason —
  `max()` would hand a deleted runbook's id to the next one). An index written
  before ids is backfilled in place by the first command that **writes** it
  (`/runbook-create`, `/runbook-clean`, `/runbook-run`); a read-only command
  never does. **A step's number is a stable id, not its position**: order is
  list position, and `runbook-schema.md` declares a body carrying ids out of
  numeric order (after a `/runbook-create --append --before`/`--after`
  insert) legal — never infer order from numbering, never renumber. Loop:
  re-read body at start of EVERY step (this is the whole
  reconciliation mechanism, and what makes mid-run `--append` steps picked up),
  select the first step **in list order** whose marker is `[ ]`/`[~]`/`[!]`
  and whose `Depends on:` are all `[x]` (a `[P]` step is never selected as it
  stands: under `attended`, reached as the step this rule would pick, its
  question is asked in the relay's fixed block headed `parked <date>,
  asking:` and, answered, it is `[ ]` and selected now — an `approval gate`
  bullet unparks without a question and the agent relays the gate with its
  draft; under `unattended` it is passed over and its dependents are
  unselectable, untouched, not parked), mark
  `[~]`, spawn ONE subagent, **wait for the result notification** (the single
  most dangerous point — the spawn's return value is not the result), classify,
  commit. **Four** result cases: `QUESTIONS FOR USER` → relay to user, answer back
  to the SAME subagent, repeat; `SPAWN REQUEST` → the spawn relay, below; `DONE` + report → `[x]`, write `Done:` (terse default
  `Done: <date>, commit <sha> (<N> files, +X/-Y)` from the report's sha +
  diffstat; decisions / wrong premises only if a re-reader would be misled),
  propagate facts as dated `Context:` bullets,
  update `Steps:`, commit; **anything else, incl. ambiguous → `[!]`**, index
  `[FAILED]` + `Failed at:`, halt. Under `unattended` a **fifth row replaces
  the first**, the policy's only change to the table: `QUESTIONS FOR USER`
  (from the step's agent, a relay child, or the inline session's own written
  outcome) → `[P]` replacing `[~]`, `- <date> parked: <question>` into
  `Context:` (question, options, recommendation verbatim; an approval gate
  recorded as the words `approval gate`, draft left out), printed in chat
  under the next handle in a fixed `Parked (P<n>) — Step …` block, `Parked:`
  line written, `Status:` still `[RUNNING]`, `Steps:` unmoved, committed at
  step 8 like `[x]`/`[!]`, loop; no `Done:` line, the agent never resumed —
  the step re-runs whole in a fresh subagent once answered. Selection with
  steps remaining, none selectable and one `[P]` is the **end branch**, not a
  deadlock: index back to `[PENDING]` (`Parked:` stays), commit, closing
  report naming each `[P]` step's question and the steps waiting on it;
  applies inside a bounded run too. **Spawn relay** (`--relay-spawns` forces it;
  otherwise the step's own agent triggers it): where a subagent cannot spawn a
  subagent — cloud sessions — the step's agent writes the child's prompt to a
  `$TMPDIR` file, **never inside the repo**, and ends its turn with
  `SPAWN REQUEST` naming a prompt path, a result path and a model. The
  orchestrator spawns that child **at its own nesting level** — sideways, not
  down, which is the whole mechanism — waits, then tells the same suspended
  caller the result file is ready. It **opens neither file**: forwards, does not
  read, the same discipline as *compresses, does not answer*, and what keeps the
  child's output out of its context. The child is bound by the verbatim RELAY
  CHILD RULES block, and the one exception is an existence check on the result
  path. A **miss** — a `DONE` child whose result file is absent or empty, or a
  turn carrying no marker that does not plainly declare its own failure — buys
  that child one re-prompt (not a relay round), since it still holds its
  report in context; a second miss fails the step, and a declared failure
  fails it at once. The unmarked-turn re-prompt is the one departure from the
  four result cases and is the relay child's alone: a step's own agent's
  unmarked turn still fails the step. Detection is the SUBAGENT's, not
  the orchestrator's — only the agent needing the tool can tell if it has it,
  and a probe would measure the wrong environment. The caller stays suspended
  throughout, so one agent works at a time — the one stated exception to *never
  two subagents*; a child's own `SPAWN REQUEST` is served identically, so
  fan-out stays flat; cap of **8 relay rounds per step**, the ninth is a `[!]`
  failure. A child that fails **fails the step** — never reported to its caller
  as finished, which would buy a `Done:` line for work that never happened.
  Classification runs on the child's returned marker, never on the result file,
  which is what squares it with *opens neither file*. File names are **dictated
  by the contract** (`<runbook>-step<n>-round<r>-prompt.md` / `-result.md`), not
  left to the agent: two runs share one `$TMPDIR` and the orchestrator, never
  opening either file, could not detect a collision. Relay files are never
  staged. Question-relay block is fixed text: question, lettered
  options with costs, a recommendation; at an approval gate the full draft
  follows **unabridged** — the one place it must not compress. In the subagent
  position (depth 3, a batch parent driving the runbook) it emits the same block
  as its own final turn under `QUESTIONS FOR USER`, for its parent to carry.
  **Resolve** reads the body at `File:` (a missing file stops) and, before
  marking `[RUNNING]`, runs the migration check — a hit reads
  `body-migration.md` and the run uses the new path for its whole life; a
  resume of an already-`[RUNNING]` runbook never migrates.
  **Chat contract**: quiet between steps — a progress line at each step's
  spawn / execution-phase start (`Step <n> running. Current run progress
  (<k>/<m>). Total runbook progress (<x>/<y>).`; `k` = steps this run
  finished + the one starting, `m` = every selectable step in range capped by
  `--steps N`, fixed at launch, `x/y` = the index's `Steps:` counter at launch,
  `x` raised by this run's finished steps + the one starting; parked/failed
  steps add nothing; full definitions in CHAT OUTPUT) and one line at its end
  (`Step 4 done (abc1234). Starting step 5.`, or the failure line), no
  narration of spawn/wait/classify/`Done:`/commit, the progress line the only
  status line on a forced mid-step turn, relayed questions,
  spawn-relay lines and the one-line `Follow-up: <item>` printed when a
  follow-up arises mid-run (`follow-ups-resolve` § DURING A RUNBOOK RUN) never
  suppressed — with the **closing report as the record of
  the run**, printed the same at completion, at a bound, at the end branch
  and at a failure halt; a parked step's question under its handle is never
  suppressed, like a relayed block; nothing extra read for it; no opt-out
  flag. THE CLOSING
  REPORT: the same two groups `/task-implement` closes in. **For the record**:
  one line per executed step in list order,
  `<step n> — <outcome, commit sha and diffstat> — <what changed in one line;
  decision or wrong premise flagged; questions relayed and their answers>`,
  then any run-level deviation on one line; each drawn from the `Done:` line
  and the step report already in hand. **Follow-ups** (numbered `1.`/`2.`/…, any length — the reply handle,
  restarting at 1 per report, a number naming a parked step's question being
  its answer): the feature completion
  candidates the step reports named plus one flip question asked once after
  the run, a failed step with its reason, a step left `[~]` to resume, every
  step left `[P]` with its question verbatim and the steps waiting on it, the
  steps outside the range / `--steps` count / never started, and what
  `/follow-ups`' rules yield applied to the run's reading, de-duplicated by
  action with the command form kept. An empty group prints `none`. When the user
  resolved or approved follow-ups mid-run, the group is that working list in
  its two-section shape (Approved, then Awaiting approval, the run's own items
  folded into the second), and after the report the approved items execute
  under `follow-ups-resolve` — conversation after the run, so no commit and no
  status flip of the report's own; a `FEATURES.md` flip is a delegated item.
  **Commit convention: one commit per completed step**, staging exactly the
  runbook (its `File:` path; both old and new path on the step that migrated
  it) and the index, then push; `--no-commit`/`--no-push` usual meanings.
  `[~]` is deliberately NEVER committed — its presence in a tree is the resume
  signal and the same-tree exception to one-run-per-runbook (`[RUNNING]` in the
  index blocks a second run otherwise; no lock file, no timestamp, no staleness
  heuristic); by commit time a marker is `[x]`, `[!]` or `[P]`, a parked
  step's commit its one commit for the run, an unpark a bookkeeping commit of
  its own. **The Stop-hook reply** (under COMMIT CADENCE) is the cost of that
  choice, paid down: a cloud sandbox's Stop hook exits 2 on any dirty tree, and
  an in-flight step is dirty by design, so the block lands at every step start
  and every relayed question. It cannot be cleared from inside the run — the
  harness runs the script after the model stops — but the script's own
  `stop_hook_active` recursion guard makes it **one forced turn per fire, not a
  loop**, and that turn is model-produced and so reachable by instruction. The
  rule: when the only dirty files are the runbook and the index the orchestrator
  itself just wrote, reply with the literal `stop hook ignored on runbook WIP`, no tool call, no
  explanation, and end the turn. Condition is **the orchestrator's own writes,
  never a `git status`** — it set `[~]` one step ago, so it needs no inspection,
  the avoided tool call is the bigger saving, and anything else dirty falls
  through to normal handling, which preserves the real forgotten-commit check.
  Second case, spawned mode only: while a spawned step is in flight (spawned,
  result not yet arrived) reply `stop hook ignored on subagent WIP` whatever is
  dirty; `--inline` keeps the runbook-WIP case alone. `task-engine`'s
  `tree.md` itself knows nothing of runbooks.
  Lives in THIS body, not a global `claude-md`: `Stop` fires for the main
  session (a subagent's is `SubagentStop`), which is the orchestrator holding
  this skill, so it costs zero resident tokens in every non-runbook session.
  Hard contracts (the reads/writes,
  does-no-work and subagent-result ones are **default-mode contracts**; `--inline`
  is their one opt-in exception, executing every selected step in the session
  itself, refused beside `--relay-spawns` or `--model` — see
  `.claude/domain/features/runbook-inline.md`): steps are **always sequential** (never parallel,
  even when declared independent — one question stream, and two agents would
  race on `Done:` lines); it **writes exactly two files** and does none of the
  work itself; **no step is ticked before its subagent's result arrives**; it
  reads only `CLAUDE.md`, the runbook and the index — **never a step's task
  body or named document, not even to compose the prompt**, whose
  orchestrator-written parts 1–4 restate nothing the step will read itself
  (preamble = navigation instruction + runbook name + step number, plus the
  `--relay-spawns` sentence) — and **does not review** a
  step's diff or commit; **no step invokes `/runbook-run`** (nested runbooks
  refused at spawn time). `--from N`/`--to N`/`--only N` narrow selection but
  never weaken `Depends on:` — one model, not three (`--only N` **is**
  `--from N --to N`; naming `--only` beside either bound is an error, as is a
  `--to` naming a step listed above the `--from` step — nine argument errors
  in all, the last three `--attended` with `--unattended`, `--skip-parked`
  without `--unattended`, and a header `Execution policy:` value outside the
  two words). The bounds name steps
  **by id** and cut the list **at those steps' positions**, so a range is
  always the stretch of steps the run walks. Bounds are re-applied against the
  body re-read each step, so a step appended mid-run inside the range runs and
  a bound naming a step not yet in the body is not an error. Reaching a `--to` bound is **not** completion: the
  index goes back to `[PENDING]` unless the whole runbook is `[x]`.
  `--steps N` runs at most N steps **executed in this run** (a step counts once
  its result reached step 8 as `DONE`; `[x]` steps never count), composes with
  `--from` only (error beside `--to`/`--only`, or with a non-positive-integer
  value), never weakens `Depends on:`, and reaching the count stops the run
  exactly like a `--to` bound (back to `[PENDING]` unless all `[x]`). Depth
  budget stated plainly in the body: orchestrator +
  step agent leaves one confirmed level **where nesting works at all** (depth 3
  confirmed locally; a cloud subagent cannot spawn, and depth 4 was never
  probed anywhere) — with the spawn relay, a step wanting its own subagent
  needs no third level.
- `commands/runbook-create.md` — authors a runbook, or appends to one.
  `requires: skill:runbook-run` — it cites that skill's `runbook-schema.md` for
  the body/index shape rather than carrying a second copy. **The only assigner
  of ids**: a new runbook takes `Last runbook number: + 1` (never `max()`)
  BEFORE writing the body, writes it at `.claude/runbooks/<id>-<name>.md`, and
  advances the counter and appends the block (`File:` prefixed) in the same
  index write; an append assigns nothing. Refuses a new name that is taken OR
  whose first kebab segment is all digits (`2026-migration`), with one
  suggested alternative. `--append <id|name|id-name>` resolves by the schema's
  rule, then runs the migration check (reading `body-migration.md` on a hit)
  before gathering material — unless the target is `[RUNNING]`, which is
  appended to at its current `File:` path, never renamed; body always read and
  written at `File:`, staged by that path (both paths when it migrated). Also the
  only writer of a step's `Needs:` line (`agent` / `agent+human` / `human`,
  absent meaning `agent`) — a seventh from-scratch interview question, harvested
  in passing in conversation mode, and called out at the gate because whether
  the run can be left unattended is the one thing the titles cannot say. Also
  the only writer of the header `Execution policy:` line — written only when
  the user asks for an unattended runbook, never by default and never asked
  in either mode (absent means `attended`, as an absent `Needs:` means
  `agent`); the gate's `Policy:` line shows it only then. Never writes `[P]`
  or the two parking `Context:` bullets, which are the run's.
  Command not skill:
  one pass with a confirmation gate, no supporting files of its own. Two
  orthogonal axes — target (`<name>` new / `--append <id|name|id-name>` / bare `--append` =
  the runbook this session is running, which a step's subagent knows because the
  spawned prompt names it / no args = ask) and source (the conversation's MOST
  RECENT enumerated follow-up list, the default; or a free-form description via
  one batched interview). Append is a flag, not a `/runbook-append` command:
  interview, prompt rules and gate are identical, only the write target differs.
  Append rules: new steps take the next unused ids from the highest existing
  one; they go at the foot unless `--before <step>` / `--after <step>`
  (mutually exclusive, `--append` only, value a step **id** never a position;
  an unknown id is answered by listing the runbook's steps) writes them as one
  contiguous block at that position — id is not position, so the foot need
  not carry the highest id, and the gate's `Position:` line says where they
  land; existing steps NEVER edited, moved or renumbered, their `Depends on:`
  never rewritten, `Sequencing:` (optional, one line) never touched, `[DONE]` → back to `[PENDING]`, `[FAILED]` stays
  `[FAILED]`, `[RUNNING]` appendable **only from the running session itself**.
  Enforces ten prompt-quality rules before writing (self-contained; names the
  document to read first or carries evidence inline; carries every decision that
  exists nowhere on disk **and nothing that already does** — which is why
  `/task-implement 134` is a complete one-line prompt; states sequencing and
  why; states what must not be re-proposed; real slash commands in real argument
  form; **no path that will not exist at run time, in particular nothing under
  `docs/`**; one deliverable; never invokes `/runbook-run`; **rule 10** prefers
  two steps to one needing a nested spawn — a preference, not rule 9's
  rejection, because a skill that spawns internally cannot be split by an author
  who does not know it will, which is the case the spawn relay covers at run
  time), fixing failures and NAMING each fix in the report rather than silently. Gate shows the proposed
  shape only — never the full prompts, which are a wall of text and are in the
  file a moment later. `Context:` is authored as `none`: decisions belong INSIDE
  the fenced prompt, which keeps it pasteable into a fresh session by hand.
  **Commits and pushes by default** (`Add runbook <name>` / `Append <n> steps
  to runbook <name>`, staging exactly the written paths); flags per
  `../../docs/authoring-guide.md` § Commit-and-push convention.
- `commands/runbook-list.md` — read side. `requires: skill:runbook-run`, for
  vocabulary rather than parsing: the status set and index block shape are
  specified once in `runbook-schema.md`. One pass over `.claude/RUNBOOKS.md`,
  never opens a body under `.claude/runbooks/` — same discipline as
  `/task-list`'s never opening `.claude/tasks/`, and what keeps cost flat in the
  number of runbooks rather than their size (it is why the index carries
  `Steps:` at all). Prints `<id>. [STATUS] <name> <done>/<total> <created>
  <source> <title>` — the id leads so it can be typed at any other
  runbook command, the one-line title closes so the listing is answerable
  without opening anything; an id-less block prints `-` and is **left alone**,
  the backfill belonging to a command that writes the index. `Failed at:`
  printed as a continuation line under `[FAILED]` rows only; a block's
  `Parked:` line printed the same way, `↳ parked: steps <ids>`, whatever the
  status, after `Failed at:` when both are present — the reason the index
  carries `Parked:` at all. Optional status filter matched without brackets, case-insensitively
  (`/task-list`'s convention); unknown status names the four valid ones rather
  than printing nothing. Missing/empty index is not an error. **Writes nothing**,
  runs no shell, corrects no status, `Failed at:` or `Parked:` line however
  wrong it looks.
- `commands/runbook-describe.md` — the compact one-runbook summary, and the
  deliberate pair to `/runbook-list`. `requires: skill:runbook-run` for the
  schema. Takes one runbook as `<id|name|id-name>` (the schema's resolution
  rule), extracts from the body at its block's `File:` path (a `File:` that
  does not resolve is reported; never migrates), and renders a fixed shape: the
  index heading line (`Failed at:` continuation for `[FAILED]` only, and a
  `↳ parked: steps <ids>` continuation for a block carrying `Parked:`, after
  `Failed at:` when both), one header
  line (`Created:`/`Source:`/`Model:` — no `Sequencing:`, `Companion:`,
  `Last step number:` or
  re-propose count), an `Archived: <ids>   (pruned; counted as done)` line
  directly under it **only when the body carries an `Archive:` line** (absent
  renders nothing),
  one line per step (marker as the body carries it, `[P]` included — printed
  with nothing of its `Context:`, the question staying in the body; `deps:`
  only when non-empty and printed verbatim even when it names an archived id —
  never annotated or cross-referenced against `Archived:`, `needs:` only for an
  authored non-`agent` value), at most
  one `done:` line per step (sha(s) + short summary, wrong premises as a count,
  `[!]` opens `FAILED —`), no `Context:` text, then a by-marker count **that
  counts every archived id as done and as present** (schema § *An archived id
  counts as `[x]`*, so the count agrees with the heading line's progress
  figure; `[P]` named "parked"; a fully-pruned body renders heading + header +
  `Archived:` + count,
  not an error) and the
  "need a person present" line. **Read budget (THE READ BUDGET section):** the
  index plus Grep line extraction from exactly one body — header fields
  (`Created:`, `Source:`, `Model:`, `Archive:`), step
  headings, `Depends on:`, `Needs:`, first line of `Done:`, prompt fences only
  to discard matches inside them. Never a full Read of the body, never prompt
  text, never `.claude/tasks/` (archive included), `.claude/domain/`,
  `.claude/context/` or another body; task ids in `Done:` printed as written.
  Malformed body reported as found, never compensated by reading more. No
  `Needs:` inference. Writes nothing, runs no shell,
  corrects no status, count, marker, `Failed at:` or `Parked:` line however
  wrong the index looks — deriving the count from
  the body's steps *and* its `Archive:` line is derivation, not
  reconciliation; a disagreeing index `Steps:` is reported in prose only.
- `commands/runbook-clean.md` — pruning, `/task-clean`'s plan-and-confirm
  shape, except that it deletes: runbooks have no archive.
  `requires: skill:runbook-run` for the status vocabulary and block shape. Three
  stages: resolve (no arg = every `[DONE]`; `<id|name|id-name>` arguments,
  by the schema's rule = exactly those,
  and a named non-`[DONE]` runbook is refused BY NAME with its actual status,
  never silently skipped) → plan and confirm (name, created date, steps done/total, both paths;
  empty plan says so and stops) → remove and commit (delete each body at its
  block's `File:` path, printed verbatim in the plan, a legacy `<name>.md`
  included — never renames, never reads `body-migration.md`; remove
  index blocks incl. surrounding `---` rules, stage exactly those paths). An
  unknown name aborts the whole run **before anything is deleted**. Only
  `[DONE]` is eligible — narrower than `/task-clean`, which also takes `[SKIP]`;
  runbooks have no second terminal status. No `--force`, no status argument
  widening the set: a `[FAILED]` runbook is flipped by hand first, one visible
  committed edit. **Commit convention: cleanup** — commits and pushes by
  default (a deletion left uncommitted is the change most likely to be lost, and
  the confirm gate already served as the review pass); `--no-commit`/`--no-push`
  opt out.
- `commands/runbook-prune.md` — the other pruner, and the pair to
  `/runbook-clean`: **clean removes finished runbooks, prune removes finished
  steps from one live runbook**. `requires: skill:runbook-run` for the body
  schema, the markers and the two header fields, none of them restated in the
  body. Takes **exactly one** runbook as `<id|name|id-name>` (the schema's
  resolution rule); no step argument, no `--all`, no `--force` — the set is
  every `[x]` step in the named runbook, struck steps included, and `[ ]`, `[~]`
  and `[!]` are never touched. Refuses a `[RUNNING]` runbook and any body
  holding a `[~]` step (the body decides, not the index); `[PENDING]`,
  `[FAILED]` and `[DONE]` are all prunable, and `[FAILED]` is where it helps
  most. Nothing to prune says so and stops without a prompt. Writes exactly two
  files — the body at its block's `File:` path, verbatim, never migrated — and
  `.claude/RUNBOOKS.md`, where the one line it touches is `Steps:`. Removes each
  `[x]` step whole (heading through prompt fence) and records its id on the
  header's `Archive:` line, ascending, extended rather than replaced; a
  surviving `Depends on:` naming a pruned step is **left exactly as it is**,
  which is what `Archive:` is for. **Never touches `Last step number:`** on a
  body that has one — up or down — so pruning the highest-numbered step is
  legal.
  Both derived values (`Archive:`, `Steps:`) and the backfill are computed in
  STAGE 1 and printed in STAGE 2's plan with their previous values beside them,
  ending in **"Apply?"** — nothing is written before an explicit answer, and a
  step the user rescues re-renders the whole plan. A prune may legally empty a
  body of steps; the file and its index block stay (removal is
  `/runbook-clean`'s). **Commit convention: cleanup** — commits and pushes by
  default, `--no-commit`/`--no-push` opt out, the plan gate serving as the
  review pass.
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

Each feature's contract is its bullet in § Overview. Frontmatter,
`description` contract and loading-control keys:
[features.md](./features.md) § Public API.

## Internal patterns

- None of their own: [features.md](./features.md) § Internal patterns.

## Domain dependencies

- `../domain/features/runbook-suite.md` — the runbook asset kind and its
  artifacts.
- Frontmatter schema: [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds, frontmatter contract, the
  home-path guard.
- [task-suite.md](./task-suite.md) — `/task-implement`, the other runner of
  the execution policy.
- [pipeline.md](./pipeline.md) — `pipeline-engine`'s `RUNBOOKS.md` edges and
  `pipeline-revise`'s runbook steps.

## When to read the source

- [features.md](./features.md) § When to read the source.
