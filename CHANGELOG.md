# Changelog

User-facing changes per root `VERSION`, highest version first. Rules and schema: `docs/authoring-guide.md` § Versioning.

## 1.22.1 — 2026-08-25

- Documentation catch-up for the review cost controls shipped in 1.21.0 and
  1.22.0. The README's `/task-implement` entry now names `--review-model` and
  `--review-effort`, their `auto` defaults, and the fact that `auto` gives a
  light diff a cheaper Sonnet reviewer on a `shallow` budget while reserving
  Opus and `deep` for a heavy one.
- The README's `/task-review` entry now describes the read budget it honours —
  navigation layer uncounted, only source and test files beyond the diff
  counted, a cap that binds reported — and states the new never-runs-a-test-
  command clause. It also records that `/task-review` joined the features
  declaring `requires: skill:task-engine`.
- No behaviour change: documentation only.

## 1.22.0 — 2026-08-25

- `/task-review` now honours the read budget `/task-implement --review` sends
  it. A spawned run carrying a budget block reads the tier's permissions from
  `task-engine`'s `references/review-budget.md` and obeys them; the navigation
  layer (`CLAUDE.md`, `.claude/context/`, the task body, the feature document)
  is read in full and never counted at any tier, and only distinct source and
  test files beyond the diff count against the cap. A cap that actually binds
  is now reported in one line so it can be retuned.
- Under `shallow`, the reviewer says plainly that it cannot read callers, which
  answers Pre-Report Gate question 3 with a "no" and lets the existing gate
  demote or drop the finding — a cheaper review is a more conservative one, and
  no second gate was added.
- A manual `/task-review`, and a spawn whose `--review-effort` resolved to
  `same`, carry no budget block and read unbounded exactly as before. The skill
  still has no cost-control flags of its own.
- New contract clause: **`/task-review` invokes no test command**, in any mode,
  under any budget, under any testing policy and on either invocation path. A
  green suite is an input its caller hands it. Where the caller reports
  skip-tests mode it says nothing ran and reports a criterion depending on
  runtime behaviour as `unverifiable`. Reading test *files* as source is
  unchanged.
- **Install change:** `task-review` now declares `requires: skill:task-engine`,
  so `chosko-llm add skill:task-review` installs `task-engine` first if it is
  not already present.

## 1.21.0 — 2026-08-25

- `/task-implement --review` gains two cost controls over the reviewer it
  spawns: `--review-model <name>|same|auto` and
  `--review-effort shallow|standard|deep|same|auto`, both defaulting to
  `auto` and both requiring `--review` (like `--rounds`). `auto` resolves
  deterministically per task from that task's own diff — lines, files,
  acceptance-criteria count, and whether anything outside `.md` changed —
  against the tier table in `task-engine`'s `references/review-budget.md`,
  and the resolved pair is reported once per task, e.g.
  `Review: sonnet / standard (auto — 210 lines, 4 files, code)`.
- **Behaviour change to an existing flag:** `--review` used to spawn a
  reviewer with no `model:`, so it inherited the implementer's — an Opus
  implementer spawned an Opus reviewer for every task in a batch. With
  `auto` as the new default, `--review` now spawns a **Sonnet** reviewer on
  an ordinary task and reserves Opus for a heavy diff. Pass
  `--review-model same` to restore the old inherit-the-implementer
  behaviour; `--review-effort same` likewise drops the read budget and lets
  the reviewer read unbounded as before.
- Model names are not validated locally — any name passes verbatim to the
  Agent tool, so a new model works the day it ships.
- In a batch run both flags ride the launcher's fixed-size hand-off as two
  strings; the parent measures nothing and still never opens a task body.
- A run without `--review` is unchanged in every respect.

## 1.20.0 — 2026-08-25

- `task-engine` gains a seventh reference file, `references/review-budget.md`,
  the single authority for the review cost controls that back
  `/task-implement --review`: the `--review-model` / `--review-effort` values
  and their `same` / `auto` reserved words, the deterministic `auto` tier table
  (heavy / light / standard, resolved per task from the round's own diff), the
  read budget behind the effort axis, the rule that the navigation layer is
  permitted in full and never counted at any tier, and the requirement that a
  cap which actually binds is reported in one line. No behaviour change on its
  own — the two consumers, `/task-implement` and `/task-review`, wire up next.

## 1.19.3 — 2026-08-25

- `/architect`'s iterate guard no longer leaves a cleaned feature stuck at
  `[DONE]`. It used to read `Tasks: none` as "this feature was never planned"
  and skip the guard outright — but `/task-clean` prunes finished task IDs and
  deliberately leaves `Status:` alone, so a completed feature looks exactly
  like a brand-new one. The status flip is now keyed on the feature's own
  `Status:`: `[PLANNED]` and `[DONE]` become `[ITERATED]` even with no tasks
  left, while `[NEW]` and `[ITERATED]` stay put. No prompt is added — with no
  tasks to invalidate there is nothing to warn about — and the flip is named
  in the closing report.

## 1.19.2 — 2026-08-25

- Documentation only: the domain layer described `/production-status` as it
  stood before 1.19.0. It now records the Next field as section 2's last
  field, section 4 echoing that value rather than deriving its own, and the
  zero-task rollup splitting on the feature's status. No behaviour change.

## 1.19.1 — 2026-08-25

- `chosko-llm ls` is fast again. Adding the REQUIRES column had left it about
  30% slower, because every row parsed its source file's frontmatter twice —
  once for the LATEST version, once for the `requires:` value. Each row now
  parses any given file at most once and takes both fields out of that one
  parse. Output is unchanged, byte for byte, under every flag.

## 1.19.0 — 2026-08-25

- `/production-status` no longer claims `no tasks yet` on a feature whose
  completed tasks `/task-clean` pruned. A `[DONE]` or `[PLANNED]` feature with
  zero tasks now renders `-`; `no tasks yet` is kept for `[NEW]` and
  `[ITERATED]`, where it is actually true. The same split applies under
  `--task-ids`, which no longer prints an empty ID list.
- Section 2's last column is now a **Next** column instead of a readiness one:
  it names the concrete action — `/task-add feature=<slug>`,
  `/task-implement <N>`, `flip to [DONE] in FEATURES.md`, `blocked by <slug>`,
  or `-` for a finished feature — rather than a fact about the dependency
  graph. Blockedness suppresses only `/task-implement`; planning ahead of a
  dependency and a bookkeeping flip are never blocked.
- The recommended-next-feature section now echoes that same Next value instead
  of working out its own next step from the task counts, so the recommendation
  can no longer disagree with the feature's own row — it used to suggest
  re-planning a feature whose tasks had merely been pruned.
- Readiness itself is unchanged — still derived on every read, never stored,
  and still what the ready set, the recommendation and the blocked list are
  built from. The command stays read-only and shell-free.

## 1.18.0 — 2026-08-25

- `chosko-llm ls` gained a sixth column, `REQUIRES`, so a feature's
  dependencies are readable straight from the listing instead of only from its
  frontmatter or from `rm`'s refusal. It shows the `requires:` specs exactly as
  declared (`skill:task-engine`), or a dimmed `—` when the feature declares
  none.
- The value is read from the managed clone when the feature is there and from
  the installed copy otherwise — the same bias as `LATEST` — so a
  not-installed row already shows what `add` will pull in with it.
- `STATUS` is now padded and `REQUIRES` is last and unpadded, so a long list of
  specs never shifts the other columns and is never truncated. Every column,
  colour, status, filter and footer hint is otherwise unchanged.
- A `requires:` entry missing its kind prefix no longer aborts `ls`: the row
  shows the offending entry dimmed and the listing continues. `add` and `rm`
  still refuse outright — that is where a dangling reference has to be caught.

## 1.17.0 — 2026-08-25

- `chosko-llm ls` now prints one table ordered by feature name instead of five
  kind-grouped blocks, so finding a feature no longer means knowing its kind
  first — the KIND column already says which kind a row is.
- Two rows sharing a name stay adjacent and in migration order (command,
  skill, claude-md, statusline, hook), so a `superseded` / `migration pending`
  pair still reads as a pair. The order is byte-deterministic whatever your
  locale is.
- Columns, colours, statuses, the `Home:` line, the `--installed` /
  `--available` / `--local` / `--global` filters and the footer hints are
  unchanged.

## 1.16.0 — 2026-08-25

- New `claude-md:git-commit-style` artifact. Install it with `chosko-llm add
  claude-md:git-commit-style` to inject a global commit-message shape policy
  into your `CLAUDE.md`: a short imperative subject line, an optional body of
  at most 2–3 lines used only when it says something the subject cannot, and
  no body at all on a trivial commit.
- The snippet puts `Co-Authored-By:` and `Claude-Session:` trailers behind a
  checkable size test — 5 or more files changed, or 200 or more changed lines
  (`git diff --cached --shortstat`). Below that both trailers are omitted, so
  small commits stop carrying them.
- It mandates no `feat:` / `fix:` prefix vocabulary, and yields to local
  style: a repo's own convention, a command's own prescribed message form, and
  a repo's own trailer habit all override it.
- `/task-implement`'s fallback commit template no longer asks for a
  one-paragraph summary — its body is now optional and capped at 2–3 lines.

## 1.15.0 — 2026-08-25

- New `chosko-llm changelog` subcommand. With no arguments it opens the managed
  clone's `CHANGELOG.md` in `$VISUAL`, else `$EDITOR`, else `git var
  GIT_EDITOR`, falling back to `less -R` and then to plain output — it never
  fails merely because no editor is configured.
- `chosko-llm changelog --since <value>` prints the sections from that point
  forward on stdout, where `<value>` is auto-detected as a version (`1.10.0` —
  that section and everything newer), a date (`2026-08-01`), or a duration
  (`30d`, `2w`, `6mo`, `1y`). A value matching no section says so and exits 0;
  an unreadable one names all three forms.
- `--since` output is paged only when it does not fit one screen and stdout is
  a terminal, so a pipe or a redirect always yields the same plain stream.
  `chosko-llm changelog --print` forces unpaged output and never spawns an
  editor or a pager.
- `chosko-llm --version` and `chosko-llm upgrade` each gained a TTY-gated
  stderr tip pointing at `chosko-llm changelog`. `--version`'s stdout is
  unchanged.
- `changelog` joins `version` and `help` in the set of read-only subcommands
  the daily auto-upgrade skips.
- `scripts/lib.sh` now owns one changelog renderer, parameterised by output
  stream and colour gate, shared by `upgrade`'s stderr readout and
  `changelog --since`'s stdout block, so the two presentations cannot drift.
  `upgrade`'s output is unchanged.

## 1.14.1 — 2026-08-25

- Documentation catch-up for the `runbook-suite` feature shipped in 1.10.0–1.14.0.
  No shipped feature's behaviour changes.
- `README.md` gains a `runbook-*` section under Claude Code Workflows: what a
  runbook is (an ordered list of self-contained prompts, each written for a
  fresh agent that has none of the conversation they came out of), the committed
  store at `.claude/runbooks/` plus `.claude/RUNBOOKS.md`, the five artifacts,
  the execution loop with its per-step re-read, the wait for the subagent's
  actual result and the one-commit-per-step cadence, the question relay and fact
  propagation, the nine prompt-quality rules, and each command's commit
  behaviour. It also draws the line against session handoffs and the backlog: a
  session file is a snapshot of work in flight, a runbook is a plan for work not
  yet done.
- `.claude/context/features.md` gains a "Currently shipped" entry for each of
  the five artifacts, each naming its kind and why, its `requires:` edge and the
  reason for it, its commit convention, and the hard contracts — the
  orchestrator writes exactly two files, steps are always sequential, no step is
  ticked before its subagent's result arrives, no step invokes `/runbook-run`,
  and no `chosko-llm` subcommand reads `.claude/runbooks/`.
- `docs/authoring-guide.md` § "State that outlives a session belongs in a
  project document" records the runbook store as another instance of that rule,
  with the body as source of truth and the index derived from it.
- `.claude/domain/features/runbook-suite.md` is reconciled with what shipped:
  `/runbook-suggest`'s suggestion is generic and names no runbook, the question
  relay is specified for an orchestrator that is itself a subagent, and the
  `VERSION` rule is per task rather than one bump for the feature.

## 1.14.0 — 2026-08-25

- New skill **`runbook-suggest`** (0.1.0) — the last artifact of the runbook
  suite, and the only one nobody invokes. It addresses the suite's one
  usability problem: the moment a runbook is worth writing is the moment
  nobody thinks of it. Declares `requires: command:runbook-create`, so
  installing it installs the command it proposes.
- **The description is the trigger.** Claude Code selects a skill from its
  `description`, so the frontmatter is the entire mechanism — no hook, no
  `Stop` handler, no event registration — and it carries the trigger
  conditions and the anti-triggers together, the way `claude-council`'s does.
- **The threshold**, stated in both the description and the body: suggest only
  when the follow-ups would be lost with the conversation — three or more
  actions, or two or more with an ordering constraint, or any action that
  depends on decisions recorded nowhere on disk. Never for a two-step list of
  simple prompts. Anti-triggers are named: a single next action, a list of
  things already done, a checklist this session is about to work through, an
  enumeration inside an explanation, and a task backlog, which is `/task-add`.
- **It asks nothing and reads nothing.** One or two lines pointing at
  `/runbook-create` — new runbook or append — then it stops. It names no
  runbook, does not open `.claude/RUNBOOKS.md` or any runbook body, writes
  nothing, and never invokes `/runbook-create` itself; the no-argument form of
  that command is what asks new-versus-append.
- Its fire rate is **tuned after observing real sessions** — the accepted
  method for this artifact rather than an open question. If it proves noisy,
  the fix is a narrower description, never a suppression flag.

## 1.13.0 — 2026-08-25

- New command **`runbook-clean`** (0.1.0) — the pruning side of the runbook
  suite. `/runbook-clean` deletes each finished runbook's body file under
  `.claude/runbooks/` and removes its `.claude/RUNBOOKS.md` index block,
  including the surrounding `---` rules. Declares `requires: skill:runbook-run`
  and cites that skill's `references/runbook-schema.md` for the status
  vocabulary and the index block shape rather than carrying a second copy of
  either.
- Removal is an **explicit act, never a consequence of completion** — reaching
  `[DONE]` deletes nothing on its own. The `Done:` lines are the record of what
  was decided while the work was being done, and that durability is the point;
  this command exists because the store is committed and grows without bound.
- Three stages, exactly `/task-clean`'s: **resolve** (no argument means every
  `[DONE]` runbook, names mean exactly those), **plan and confirm** (each
  runbook with its created date, steps done over total, and *both* paths — body
  file and index block — then "Apply?"), and **remove and commit** (staging
  exactly the deleted paths and the index by explicit path, never a catch-all).
- **Only `[DONE]` is eligible, and there is no `--force` and no status
  argument.** `[PENDING]` is unstarted work, `[RUNNING]` is a run someone is in
  the middle of, and `[FAILED]` is the record of a halt that still needs a
  decision — the status most likely to be misread as finished. A user who
  genuinely wants a `[FAILED]` runbook gone flips its status by hand first, one
  visible committed edit. Narrower than `/task-clean` on purpose: runbooks have
  no second terminal status.
- A **named runbook that is not `[DONE]` is refused by name with its actual
  status**, never silently skipped — a silent skip reads as a successful
  removal. An **unknown name aborts the whole run before anything is deleted**,
  rather than removing the names it did recognise. An **empty plan says so and
  stops** without asking anything.
- Commits and pushes by default, with `--no-commit` and `--no-push` to opt
  out — the cleanup convention rather than the authoring one: a deletion left
  uncommitted is the change most likely to be lost, and the confirmation gate
  has already served as the review pass.
- It touches no runbook it is not deleting, never edits a body file, and
  corrects no status, `Steps:` count or `Failed at:` line however wrong it
  looks — reconciliation belongs to `/runbook-run`, which already has the body
  open.

## 1.12.0 — 2026-08-25

- New command **`runbook-list`** (0.1.0) — the read side of the runbook suite.
  `/runbook-list` makes one pass over `.claude/RUNBOOKS.md` and prints every
  runbook as a single line: status, name, `<done>/<total>` steps, creation date
  and source. Declares `requires: skill:runbook-run` and cites that skill's
  `references/runbook-schema.md` for the status vocabulary and the index block
  shape rather than carrying a second copy of either.
- A `[FAILED]` runbook gets a `↳ failed at step <n> — <reason>` continuation
  line under it, so the one thing a reader of a halted runbook needs is in the
  listing rather than behind a file open. The listing closes with a summary
  counting the runbooks by status.
- **It never opens a file under `.claude/runbooks/`** — everything printed comes
  from the index, which is why the index carries derived fields at all. That is
  `/task-list`'s discipline of never opening a task body, and it keeps the cost
  flat in the number of runbooks rather than in their size.
- The optional status argument is matched without brackets and
  case-insensitively, as `/task-list`'s filter already is. An unknown status
  names the valid ones instead of printing nothing — a silent empty result is
  indistinguishable from having no matching runbooks. A missing or empty index
  is not an error either: one line saying no runbooks exist and naming
  `/runbook-create`.
- The listing writes nothing, runs no shell command, and corrects no status
  however wrong it looks. Reconciliation belongs to `/runbook-run`, which
  already has the body open.

## 1.11.0 — 2026-08-25

- New command **`runbook-create`** (0.1.0) — the authoring side of the runbook
  suite. `/runbook-create` harvests the material for a runbook while the
  conversation that produced it is still open, and writes
  `.claude/runbooks/<name>.md` plus its `.claude/RUNBOOKS.md` index block.
  Declares `requires: skill:runbook-run` and cites that skill's
  `references/runbook-schema.md` for the artifact rather than carrying a
  second copy of it.
- Two axes. Target: `/runbook-create <name>` for a new runbook (a single
  kebab-case token is a name, anything longer is a description),
  `--append <name>` to add steps to an existing one, `--append` with no name
  for the runbook the session is currently running, and no arguments at all,
  which asks new-versus-append and lists the runbooks with non-`[DONE]` ones
  first. Source: the conversation's **most recent** enumerated follow-up list
  by default, or a batched five-question interview when a free-form
  description is given.
- Nine prompt-quality rules are stated in the body in full and enforced
  against every step before the file is written — self-contained; names the
  document to read first or carries the evidence inline; carries every
  decision that exists nowhere on disk and nothing that already does (so the
  correct prompt for an authored task is the one-line `/task-implement <n>`);
  states its sequencing and why; states what must not be re-proposed; uses a
  real slash command in its real argument form; references no path missing at
  run time; produces one deliverable; and never invokes `/runbook-run`. A step
  failing a rule is fixed before the write and the fix is named in the
  confirmation report, never applied silently.
- The confirmation gate shows the proposed **shape** only — target, step
  titles, the sequencing line, dependencies and any rule-8 splits — never the
  full prompts. `Context:` is written as `none` at authoring time; corrections
  and learned facts are the run's field. Appends continue the numbering,
  extend the `Sequencing:` line rather than replacing it, never edit a line
  above the append point, flip a `[DONE]` runbook back to `[PENDING]`, leave a
  `[FAILED]` one `[FAILED]`, and are allowed on a `[RUNNING]` runbook only
  from the session running it.
- `.claude/runbooks/` and `.claude/RUNBOOKS.md` are created on first use,
  silently and idempotently — no setup step, and `/task-setup` and
  `/project-setup` are untouched. A colliding name is refused with a suggested
  alternative rather than disambiguated. Authoring-command convention: output
  is left uncommitted for one review pass by default; `--commit` opts in and
  `--commit --no-push` commits without pushing.

## 1.10.0 — 2026-08-25

- New skill **`runbook-run`** (0.1.0) — the first artifact of the runbook
  suite. A *runbook* is an ordered list of self-contained prompts under
  `.claude/runbooks/<name>.md`, each written to be executed by a fresh agent
  that has none of the conversation the prompts came out of.
  `/runbook-run <name>` walks one top to bottom: it spawns one subagent per
  step, waits for that subagent's result to actually arrive, relays any
  question it asks to the user and the answer back to the same subagent,
  records what the step did in a `Done:` line naming the commit sha, the
  decisions taken and any premise that proved wrong, and commits the runbook
  and its `.claude/RUNBOOKS.md` index after every step.
- Steps run one at a time, never in parallel. The orchestrator reads only
  `CLAUDE.md`, the runbook and the index, and writes only the runbook and the
  index — every other change in the tree is made by a subagent, and it never
  reviews or second-guesses one. It re-reads the body at the start of *every*
  step, which is what reconciles a hand-edited body and what makes steps
  appended mid-run visible to the run already in progress.
- Arguments: `--from N`, `--only N`, `--model <model>`, `--no-commit`,
  `--no-push`. `--from` and `--only` do not weaken `Depends on:` — a selected
  step with an unmet dependency stops the run and names it.
- The skill also ships the two reference files the rest of the suite reads by
  path. `references/runbook-schema.md` is the single authority for the asset
  kind — the store, the body schema, the four step markers `[ ] [~] [x] [!]`,
  the `Done:` line, the four-status vocabulary `[PENDING]` / `[RUNNING]` /
  `[FAILED]` / `[DONE]` (deliberately distinct from `TASKS.md`'s and
  `FEATURES.md`'s), and the index block — and records the two deliberate
  absences, no `[SKIP]` status and no per-step `Produces:` field, with their
  reasons. `references/subagent-contract.md` holds the OPERATING RULES block
  as fixed text, pasted verbatim as the last section of every spawned prompt.
- Nested runbooks are refused at spawn time, and the depth budget is stated
  plainly: the orchestrator is one level and the step's agent a second,
  leaving one confirmed level (depth 3 verified 2026-08-24) — a step whose own
  prompt spawns subagents would need depth 4, which is unprobed and warned
  about rather than blocked.
- Nothing under `scripts/` or `bin/` learns about runbooks: they are input to
  agents, never to tooling, and the filesystem-plus-frontmatter rule is
  unchanged. `/runbook-create`, `/runbook-list`, `/runbook-clean` and
  `/runbook-suggest` follow.

## 1.9.0 — 2026-08-25

- `/task-add` (2.2.0) replaces its ownership *notice* with an ownership
  **pre-authorisation gate**. Previously a drafted task could name a document
  owned by another pipeline command and the user was merely told; the
  implementer then met the one-writer-per-artifact rule holding no authority to
  proceed, and either stalled to ask or edited the document anyway. Now, at the
  PHASE 3 gate, the command enumerates the specific reconciliations that task
  needs to make to each owned document and asks for exactly two possible
  answers — grant pre-authorisation for those points, or drop the file and
  leave the document to its owner — then writes the grant (a dated,
  point-scoped `## Decisions` bullet plus the points in `## Acceptance
  criteria`) or the removal into the task body. Silence is not a grant, an
  "Approve and write?" that skipped the question is re-asked, and PHASE 4
  refuses to write a task whose owned document is neither granted nor removed.
- The gate covers **every task a run drafts** — the documentation task, a
  free-form task, each part of a split, and any body rewritten during
  reconciliation — not the documentation task alone.
- The owner list `/task-add` carries inline grows from four documents to seven,
  adding `product-roadmap.md` (`/product-roadmap`) and `.claude/PLAN.md`
  (`/production-plan`); `FEATURES.md` and `TASKS.md` stay excluded because they
  are split by line and `/task-add` is one of their writers.
- A grant does not make `/task-add` a writer: it authorises the *implementer*
  of the task being drafted, so one writer per artifact still holds for the
  pipeline commands.

## 1.8.5 — 2026-08-25

- Documentation catch-up for the `shared-phase-engine` work (1.7.0 – 1.8.4).
  `README.md` now describes what `add` does with `requires:` and what `rm`
  refuses without `--force`, lists `requires:` among the optional frontmatter
  keys, and says that installing any `task-*` feature installs
  `skill:task-engine` too.
- `docs/authoring-guide.md`'s "Keeping the two `council-gate.md` copies in
  step" rule is **qualified, not lifted**: a shared file is safe when it lives
  in its own installable skill that every dependent declares in `requires:`
  (`skills/task-engine/` is the worked example), and the council gate is still
  the exception because it must keep working when `claude-council` is
  *absent* — an optional dependency, which `requires:` cannot express. The
  "Authoring a skill" section now covers the non-invocable reference-library
  shape and the `description`-says-so convention that keeps it out of skill
  suggestions.
- `skills/task-engine` (0.1.1) — `references/targets.md` no longer describes
  `/task-list`'s dead `local` target mention as "awaiting its migration"; that
  migration landed in 1.8.1. Text only; no rule changed.
- This repo's own `.claude/context/` and `.claude/domain/` layers are brought
  in line with what shipped, and the `shared-phase-engine` feature document is
  reconciled with it — including the line-count targets the migration missed
  and why they were the wrong measure.

## 1.8.4 — 2026-08-25

- `/task-implement` (1.3.0) is the last of the four consumers to move onto
  `task-engine`, and the suite's duplication is now gone: its backlog
  resolution and selectors are a reference to
  `skills/task-engine/references/resolution.md`, its implementable- and
  terminal-status rules to `status.md`, its `Target:` handling and delegation
  guard to `targets.md`, its `STALE TASKS` protocol to `stale.md`, its
  dirty-tree check to `tree.md`, and `PRE-FLIGHT` step 5 plus `Step 7` to
  `commit.md`. It declares `requires: skill:task-engine`, so
  `chosko-llm add skill:task-implement` installs the engine first.
- The skill's own `dirty-tree.md` supporting file is deleted — `tree.md` was
  extracted from it and now holds the protocol once. `chosko-llm update`
  removes the stale copy from an existing install.
- Behaviour is unchanged — same usage header and examples, same flags
  (`--no-commit`, `--no-push`, `-y`, `--agents` / `--no-agents`, `--review`,
  `--rounds N`), same pre-flight order, same seven-step per-task workflow and
  review loop, same one commit and one push per task, same delegation
  contract, and the same end-of-run feature-completion proposal.

## 1.8.3 — 2026-08-25

- `/task-add` (2.1.0) now consumes `task-engine`, the largest migration in the
  suite: its `PHASE 0` setup check and `INDEX FILE FORMAT` are references to
  `skills/task-engine/references/resolution.md`, its `STATUS TAGS` block to
  `status.md`, `TARGET VALUES & MANUAL INTERVENTIONS` to `targets.md`, the
  `[STALE]` and reconciliation-classification rules to `stale.md`, and
  `PHASE 5` to `commit.md`. It declares `requires: skill:task-engine`, so
  `chosko-llm add command:task-add` installs the engine first.
- Behaviour is unchanged — same usage header and examples, same flags and
  mutual exclusions, same eight-phase flow and its single `Approve and write?`
  gate, same drafts, same written artifacts, same commit message forms, and the
  same two-field `.claude/FEATURES.md` write.

## 1.8.2 — 2026-08-25

- `/task-clean` (0.8.0) now consumes `task-engine` too, and is the first
  *writing* feature to do so: its `--no-commit` / `--no-push` gating and push
  protocol are a reference to `skills/task-engine/references/commit.md`, its
  backlog parsing a reference to `resolution.md`, its prune-set vocabulary to
  `status.md`, and its `[STALE]` warning to `stale.md`. It declares
  `requires: skill:task-engine`, so `chosko-llm add command:task-clean`
  installs the engine first.
- Behaviour is unchanged — same usage lines and examples, same plan-and-confirm
  gate and plan layout, same commit message, same `--no-commit` / `--no-push`
  semantics, and the same `.claude/FEATURES.md` `Tasks:` pruning that leaves
  feature statuses alone.

## 1.8.1 — 2026-08-25

- `/task-list` (0.6.0) is the first feature to consume `task-engine`: its
  backlog-resolution and status-vocabulary rules are now references to
  `skills/task-engine/references/resolution.md` and `status.md` instead of its
  own copies, and it declares `requires: skill:task-engine`, so
  `chosko-llm add command:task-list` installs the engine first.
- Its output is unchanged — same usage lines, same status filter, same flat and
  milestone-grouped rendering, and it still opens no file under `.claude/tasks/`.
- Dropped a dead mention of a `local` task target from its marker rules; that
  value was removed from the system when the dual-LLM lane was deleted.

## 1.8.0 — 2026-08-25

- New shipped skill `task-engine`: a reference library holding one authority per
  rule the `task-*` features share. Six files under
  `skills/task-engine/references/` cover backlog resolution and the `TASKS.md`
  schema (`resolution.md`), the status vocabulary and its transitions
  (`status.md`), `Target:` values and the delegation guard (`targets.md`),
  `[STALE]` handling (`stale.md`), the dirty-tree protocol (`tree.md`), and
  commit/push gating with `--no-commit` / `--no-push` (`commit.md`).
- It is **not a skill to invoke**: it takes no arguments, runs nothing, and says
  so in its `description` so it is not offered as a suggestion. Install it with
  `chosko-llm add skill:task-engine`; features reach it at
  `${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/<file>.md`.
- Every reference file was extracted verbatim from the current
  `/task-add`, `/task-list`, `/task-clean` and `/task-implement` bodies, and
  records where the copies diverged as per-consumer notes rather than merging
  them into a paraphrase.
- Nothing consumes it yet — no `task-*` feature changed, no `requires:` was
  declared, and no behaviour of any command or skill is different in this
  release.

## 1.7.0 — 2026-08-25

- New optional frontmatter key `requires:`, valid on every feature kind. It
  names the features a feature reads a file out of, as a comma-separated list
  of kind-prefixed specs (`requires: skill:task-engine, command:task-add`), so
  a cross-feature reference can no longer install into a dangling path.
- `chosko-llm add <feature>` installs what a source declares in `requires:`
  before installing the feature itself — after validation and before the first
  copy, so a requirement that cannot be resolved aborts that feature without
  half-installing it. A requirement already installed is skipped with one info
  line; a requirement absent from the managed clone, or invalid for the scope,
  aborts only that feature and the other names in the call still run.
- `chosko-llm rm <feature>` now refuses to remove a feature that an installed
  feature still declares in `requires:`, naming every dependent. New `--force`
  flag removes it anyway and warns which dependents it just broke. `--force`
  may appear anywhere in the argument list, like `--local` / `--global`.
- Resolution is deliberately one level deep, unversioned and non-transitive: a
  requirement's own `requires:` is not followed, there is no version range, no
  solver, no lockfile and no cycle detection.
- `add --all`, `update`, `ls` and `uninstall.sh` are unchanged. `--all`
  installs every feature, so every requirement is satisfied incidentally; a
  bulk uninstall deletes artifacts directly and is never blocked by the new
  `rm` guard.
- No shipped feature declares `requires:` yet — this release only adds the
  capability. `docs/authoring-guide.md` gains a `requires:` section beside the
  `replaces:` one, and `chosko-llm help` documents both sides.

## 1.6.1 — 2026-08-25

- Documentation catch-up for the `task-peer-review` feature shipped in 1.4.0–1.6.0.
  No shipped feature's behaviour changes.
- `README.md`'s `task-*` section now lists `/task-review` and `/task-iterate`,
  mentions `--review [--rounds N]` on `/task-implement`, and spells out the
  commit rule: `/task-iterate` commits and pushes standalone but commits nothing
  inside a `/task-implement --review` round, so a reviewed task still produces
  exactly one commit.
- `docs/authoring-guide.md`'s commit-and-push convention adds `/task-iterate` to
  the auto-committing group with that caller-dependent departure named, and
  records that `/task-review` belongs to neither group because it never commits
  anything.
- The navigation layers catch up too: `.claude/context/features.md` gains
  entries for `skills/task-review/` and `skills/task-iterate/` and describes
  `/task-implement`'s `--review` loop and its eighth supporting file, and
  `.claude/domain/task-workflow.md` gains a review-loop section covering the
  fresh-context reviewer, mandatory triage, sticky rejections, the severity gate
  and round bound, and the one-commit-per-task invariant.
- `.claude/domain/features/task-peer-review.md` is reconciled with what shipped:
  the branch-mode base and the `--rounds`-on-`/task-review` open questions are
  closed, the read-only contract is stated so it no longer conflicts with the
  opt-in `.claude/reviews/` report, and the loop is recorded as running before
  `/task-implement`'s status flip rather than after it.

## 1.6.0 — 2026-08-25

- `/task-implement` gains `--review` and `--rounds N` (`skills/task-implement`
  to `version: 1.2.0`), completing the peer-review loop: a task can now be
  implemented, reviewed by a context that did not write it, and corrected
  without leaving the run. Default off — a run without `--review` behaves
  exactly as before, reads no new file and asks nothing new.
- The loop runs after the full test suite and **before** the terminal status
  flip, on the uncommitted tree, so the review's fixes ride in the task's own
  single commit. A reviewed task still produces exactly one commit, and
  `/task-iterate` is told not to commit inside a round.
- Each round spawns `/task-review` as a subagent, because fresh context is the
  mechanism rather than a detail, and runs `/task-iterate` in the session so its
  edits land in the tree that gets committed. The new
  `skills/task-implement/review-rounds.md` holds the protocol and is read only
  when `--review` is passed.
- `--rounds N` (default 1) bounds the loop, which continues only while
  `BLOCKING` findings remain unresolved; `IMPORTANT` and `ADVISORY` findings are
  reported once and never re-raised, later rounds re-review only the hunks the
  last iterate changed, and a finding rejected in one round may not be
  re-raised in the next, only escalated on new evidence. `--rounds` without
  `--review` is an error.
- Unresolved `BLOCKING` findings after the last round stop the run: the findings
  are reported by id, the tree is left uncommitted and the task stays
  `[IN PROGRESS]`. `--review` on a run whose session lacks either the
  `task-review` or the `task-iterate` skill stops before the first task with the
  `chosko-llm add skill:task-review skill:task-iterate` remedy, rather than
  silently skipping the review.
- In a batch run the flags ride through the launcher's fixed-size hand-off
  prompt and each implementor spawns its own reviewer. A spawned reviewer
  returns asynchronously — the call yields an id and the report arrives later —
  so no implementor may commit before its reviewer's result has arrived, and no
  finding ever travels up to the parent.

## 1.5.0 — 2026-08-25

- New skill `task-iterate` (`/task-iterate`), at `version: 0.1.0`. It takes the
  findings `/task-review` produced, triages every one of them, applies what
  survives, and records why the rest did not — it never reviews the diff itself
  and never adds a finding of its own.
- Triage is mandatory and written down first: every finding gets exactly one of
  `fix`, `defer` or `reject`, a `defer` needs a follow-up task number (or a note
  that one should be authored), a `reject` needs a one-line reason, and the full
  verdict table is produced before the first edit. A `BLOCKING` finding naming an
  unmet acceptance criterion cannot be deferred.
- `/task-iterate` takes the same three input forms as `/task-review` — no
  argument for the uncommitted working tree, a branch name (with an optional
  `base=<ref>`), or a PR number or URL through `gh` — and `task=<n>` pins the
  task. In PR mode it replies on each thread it acted on and resolves those it
  addressed, leaving rejected threads open for the human.
- Committing depends on the caller, and the caller asserts it: run standalone it
  commits and pushes like every other auto-committing feature and accepts
  `--no-commit` / `--no-push`; run inside a `/task-implement --review` round it
  commits nothing, so a reviewed task still produces exactly one commit.
- The run returns a triage summary, a sticky rejection ledger the next round
  must treat as binding, and an explicit yes/no on whether any `BLOCKING`
  findings remain unresolved. It never opens a pull request, in any mode.

## 1.4.0 — 2026-08-25

- New skill `task-review` (`/task-review`), at `version: 0.1.0`. It audits a
  diff against the acceptance criteria of the task that produced it — the
  check Claude Code's built-in `/code-review` cannot make — and reports a
  verdict per criterion plus findings carrying a stable `R<round>-<n>` id, a
  severity, a `file:line`, the failure scenario and a suggested fix.
- `/task-review` takes three input forms: no argument reviews the uncommitted
  working tree, a branch name reviews that branch against the repository's
  default branch (or an explicit `base=<ref>`), and a PR number or URL reviews
  that pull request through `gh`. `task=<n>` pins the task when the branch name
  or PR title does not name it; without a resolvable task the run stops instead
  of degrading into a generic code review.
- The reviewer is gated rather than merely instructed: findings below 80%
  confidence are not reported, a four-question pre-report gate downgrades or
  drops anything that cannot cite a line and name a concrete failure mode, a
  BLOCKING finding must show the snippet, the scenario and why existing guards
  miss it, and a review with no findings is stated to be a valid result.
- `/task-review` is read-only. It edits no source, test, task or status file,
  runs no mutating `git` or `gh` command, and never opens a pull request; the
  only file it can write is the `.claude/reviews/<task>-R<round>.md` report a
  manual run explicitly opted into.
- `gh` is a dependency of PR mode only, and its absence there is a clear error
  naming it — never a silent fallback to reviewing the working tree.

## 1.3.1 — 2026-08-25

- Documentation only. This repo's own navigation layers now describe the
  `/task-implement` launcher shipped in 1.3.0: the context layer's
  `task-implement` entry and the domain layer's "Delegated runs" section both
  state that the parent evaluates the delegation guard from the `TASKS.md`
  summary blocks alone, opens no task body for a delegated task, hands every
  agent the same fixed-size prompt, and keeps only the four values each agent
  returns.
- The `task-implement-launcher` feature document is reconciled with what
  shipped on two points: the three guard fields come from the `TASKS.md`
  summary block rather than being greped out of the task body, and `[STALE]`
  needs no `FEATURES.md` join because it is a `TASKS.md` status.
- Nothing the CLI installs changed.

## 1.3.0 — 2026-08-25

- `/task-implement`'s batch parent is now a **launcher**. On a delegated run
  (`--agents`, or answering yes to the delegation question) the parent no longer
  reads the body of a task it is about to hand over — it evaluates the
  delegation guard from the `Target:`, `Status:` and `Feature:` lines already in
  the `TASKS.md` summary blocks, and hands every agent the same fixed-size
  prompt: the task number, the run's resolved flags, and the instruction to read
  the task body, `CLAUDE.md` and `.claude/context/` for itself.
- Each agent now returns exactly four things — task number, terminal status,
  commit hash (or that nothing was committed), and a one-line reason if it
  failed — and the parent keeps nothing else. A fifty-task run leaves the parent
  holding fifty short rows instead of fifty task bodies.
- Observable behaviour is unchanged: no new flag, no altered usage, the same
  sequential-never-parallel agents, the same tasks kept in the parent
  (`claude+human`, `human`, explicitly requested `[STALE]`), the same
  between-agent verification, the same end-of-run feature-completion proposal,
  and single-task runs untouched. What changed is the parent's token profile.

## 1.2.3 — 2026-08-25

- Documentation only. The README and the authoring guide now describe
  **repo-local skills** — skills under this repo's own `.claude/skills/` that
  are tooling for building the product rather than part of it: no `version:`,
  invisible to `ls` / `add` / `update` / `rm`, installed nowhere, and outside
  the root `VERSION` bump rule.
- The authoring guide gains a "Repo-local skills are not features" section
  beside "Vendored skills", including the rule that such a skill's name must
  never collide with a shipped feature name, and the note that
  `chosko-llm export` deliberately does carry them along — an export packages a
  repo's Claude config, and repo-local tooling is part of it.
- Nothing the CLI installs changed.

## 1.2.2 — 2026-08-25

- Repo governance only; nothing a user of the CLI receives changes. `CLAUDE.md`
  § Versioning now records one narrow exception to the bump-on-every-shipped-
  change rule: a change confined to this repo's own `.claude/skills/` —
  unversioned development tooling, installed nowhere — does not bump root
  `VERSION`, because bumping for a file no user receives corrupts the meaning of
  the version `install.sh` reports.
- The rest of `.claude/` — context layer, domain layer, backlog — is explicitly
  unaffected and bumps as before.

## 1.2.1 — 2026-08-25

- Documentation only. The README gains a section on `/session-save` and
  `/session-resume` — the per-project store, the full and pointer file forms,
  the `Work:` line, the fact that resuming briefs you and then stops, and how
  old handoffs get pruned.
- The authoring guide's "State that outlives a session belongs in a project
  document" section now notes that `/session-save`'s known-artifact table
  recognizes exactly the class of document it defines.

## 1.2.0 — 2026-08-25

- New `/session-resume` command, the read half of `/session-save`: it loads one
  handoff out of `.claude/sessions/` — the newest one, the newest from a date
  you name, or a path — and briefs the conversation from it. There is no
  task-number selector.
- Only files carrying a `Work:` line are candidates, so a companion document
  sitting in the same directory is never mistaken for a handoff; same-timestamp
  ties break on the full filename and the file picked is always named, so an
  explicit path can correct it.
- The briefing is fixed in shape — what was being built, what must not be
  retried, and the exact next step, verbatim. A handoff older than 14 days is
  flagged as stale, and paths it names that no longer exist are listed, both
  before the briefing rather than after.
- It then **stops and waits**: it starts no work, edits nothing, deletes
  nothing and runs no shell command. It closes by naming the file it resumed
  from and handing its deletion to the resumed session, which is what lets
  `/session-save` remove the superseded file later.

## 1.1.0 — 2026-08-25

- New `/session-save` command: writes a per-project handoff file to
  `.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md` capturing what a conversation
  knows and nothing else does — what was tried, what failed and why, what was
  deliberately not tried, which files are half-finished, and the exact next
  step. Nine sections, every one written (`N/A` where empty), each "what
  worked" claim carrying its evidence.
- It shrinks to a one-line pointer when the work already has its own resume
  artifact — a project-scoped state document carrying a resume marker, such as
  `/product-design`'s `.claude/domain/design-process.md`. The command detects;
  skills declare nothing.
- Every save writes a new file, never updates one in place. When the
  conversation itself resumed from a session file, that file is deleted once
  the new snapshot is written, so two snapshots of the same work never coexist.
- It does not commit, does not push, offers no `--commit`, and does not touch
  `.gitignore`; it prints the path it wrote and a one-line note that the file
  is untracked. No `chosko-llm` subcommand reads what it writes.

## 1.0.0 — 2026-08-25

**Breaking.** The local-model implementation lane is removed. It drove a local
LLM (aider + Ollama) through a project's task backlog and was never used in
274 task authorings across four repositories.

- `chosko-llm task-impl` is gone. The subcommand now exits 2 as an unknown
  subcommand, and it no longer appears in `chosko-llm help`.
- `/task-enrich` is no longer shipped, and `/task-add --enrich` is gone with
  it. `Target:` keeps its three live values — `claude`, `claude+human`,
  `human` — and the enriched body schema (`## Context bundle` /
  `## Implementation steps`, `Target: local`) no longer exists.
- `/task-implement` no longer warns about `Target: local` tasks. Everything
  else about it is unchanged, including the `claude+human` checkpoint flow,
  the `human` guided walkthrough and the Unity MCP path.
- `/task-setup` now creates `.claude/TASKS.md`, `.claude/tasks/` and the two
  test-dispatch wrappers (`run-affected-tests.sh`, `run-full-tests.sh`) — and
  nothing else. It no longer writes the two aider prompt templates. Existing
  `.claude/external/` directories in other projects are untouched and keep
  working; the wrappers, including the `# CHOSKO_TASK_IMPL_STUB` sentinel,
  behave exactly as before.
- `scripts/check-task-parity.sh` is deleted — with the shell orchestrator
  gone, the task status vocabulary has only one encoding to guard.

## 0.63.1 — 2026-08-25

- `README.md` documents the upgrade readout, the rule that a `VERSION` bump
  without a `CHANGELOG.md` section is incomplete, and the
  `scripts/check-changelog.sh` guard; `CHANGELOG.md` and that script are now
  listed in the repo-layout table.
- `chosko-llm help` notes that `upgrade` prints what changed for the versions
  just pulled.

## 0.63.0 — 2026-08-25

- `chosko-llm upgrade` now prints what changed: the `CHANGELOG.md` sections for
  exactly the versions just pulled, newest first, with the version bold and the
  bullets colour-marked. The raw `git log --oneline` dump is suppressed when
  those bullets print, and still appears when the version did not move or the
  clone has no `CHANGELOG.md`.
- The same readout appears during daily auto-upgrade.

## 0.62.4 — 2026-08-25

- `CHANGELOG.md` preamble reduced to one line; the rule, its converse and the ordering rationale live in `CLAUDE.md` and the authoring guide, not in the record.

## 0.62.3 — 2026-08-25

- New `scripts/check-changelog.sh`: an authoring-time guard that fails when the
  top `CHANGELOG.md` section does not match `VERSION`, when sections are out of
  descending-semver order or duplicated, or when the newest section has no
  bullets. Silent on success; not a `chosko-llm` subcommand.
- The authoring guide documents the guard and when to run it.

## 0.62.2 — 2026-08-25

- New `CHANGELOG.md` at the repo root: a curated, user-facing record of every
  version this repo has released, backfilled from `0.1.0` onward.
- `CLAUDE.md` and the authoring guide now require a `CHANGELOG.md` section
  with every `VERSION` bump, and state its converse.

## 0.62.1 — 2026-08-24

- `CLAUDE.md` records that this repo itself uses only `FEATURES.md` and
  `TASKS.md` — never a `PLAN.md`, roadmap or milestones.
- Five features architected from the ECC import assessment and planned into
  the backlog.

## 0.62.0 — 2026-08-24

- New shipped skill `claude-council` — pressure-test a decision with five
  thinking-lens advisors, anonymised peer review and a dual-chairman synthesis
  that preserves dissent.
- `/task-list`'s fenced-output instruction is trimmed to one reading.

## 0.61.1 — 2026-08-22

- Fix `/task-list`: its numbered output no longer gets renumbered by the
  markdown renderer.

## 0.61.0 — 2026-08-16

- `/product-design` replaces `design-process.md`'s content when a run ends
  instead of appending to it, so the file stops growing a run at a time.
- Fix `/production-status` treating a `[DONE]` feature as still ready to
  start.

## 0.60.0 — 2026-08-13

- `FEATURES.md` accepts `[DONE]` as a feature status, so a finished feature
  has somewhere to land.

## 0.59.0 — 2026-08-11

- New `hook` feature kind — a `.sh` Claude Code runs on a hook event,
  installed into the repo it governs. The `remote-session-protocol` claude-md
  artifact is replaced by a hook.
- `chosko-llm update` re-prompts for hook wiring when an update moves a hook's
  `event:` or `matcher:`.
- `chosko-llm export` includes the `.claude` shell scripts.
- The roadmap branch merges into master, bringing `0.52.1` through `0.58.2`
  with it.

## 0.58.2 — 2026-08-09

- The six repo scripts that are executed are tracked with the executable bit
  set.

## 0.58.1 — 2026-08-09

- Fix `/product-roadmap`'s steer question, whose two options could be read the
  same way.

## 0.58.0 — 2026-08-08

- `/product-roadmap` asks who proposes the milestone order and records the
  strategic premise behind the order it produces.

## 0.57.2 — 2026-08-08

- The product pipeline's stages are renumbered end to end now that
  `/product-roadmap` sits in it.

## 0.57.1 — 2026-08-08

- Documentation for `/production-status` and plan-aware `/task-list`.

## 0.57.0 — 2026-08-08

- `/task-list` groups tasks under their milestone in plan order, and flags a
  task whose feature is blocked.

## 0.56.0 — 2026-08-08

- New command `/production-status` — what to build next: the active milestone,
  the ready set, the blocked features and one recommendation.

## 0.55.1 — 2026-08-08

- Documentation for `/production-plan` and the `PLAN.md` index.

## 0.55.0 — 2026-08-08

- New skill `/production-plan` — writes `.claude/PLAN.md`: ordered features
  per milestone, the dependency graph, and cycle and ordering validation.

## 0.54.1 — 2026-08-08

- Documentation for slice-aware `/architect` across the doc layers.

## 0.54.0 — 2026-08-07

- `/architect` resolves a roadmap scope slice instead of a whole design
  section on projects that have a roadmap.

## 0.53.2 — 2026-08-07

- `/architect`'s input resolution moves into an on-demand reference file, so a
  project with no roadmap reads none of it.

## 0.53.1 — 2026-08-07

- Documentation for `/product-roadmap` and its stage in the product pipeline.

## 0.53.0 — 2026-08-07

- New skill `/product-roadmap` — milestones with goals, exit criteria and the
  scope slices that decide what each milestone takes.
- New claude-md artifact `remote-session-protocol`, installable into a repo's
  `CLAUDE.md`.

## 0.52.1 — 2026-08-07

- `/task-add`'s documentation-task ownership gate becomes a warning instead of
  a refusal.
- `/architect` and `/product-design` gain an optional `claude-council`
  decision gate.

## 0.52.0 — 2026-08-06

- `chosko-llm add` and `chosko-llm update` accept several feature names in one
  call.

## 0.51.1 — 2026-08-06

- `ls` and `show` give "superseded" and "migration pending" distinct status
  colours.

## 0.51.0 — 2026-08-06

- `ls` and `show` surface a feature whose kind changed and is waiting to be
  migrated.

## 0.50.0 — 2026-08-06

- `--local` / `--global` on `ls`, `add`, `rm`, `update` and `show` — install
  features into a single repo instead of `~/.claude/`.

## 0.49.2 — 2026-08-06

- Install-scope resolution lands in `lib.sh`, ahead of the subcommands that
  use it.

## 0.49.1 — 2026-08-05

- Documentation for the context skill family, and a refreshed navigation
  context layer.

## 0.49.0 — 2026-08-05

- New skill `/context-convert` — converts a navigation context layer between
  the flat and nested layouts, reporting the move plan before touching
  anything.

## 0.48.0 — 2026-08-05

- `/context-update` handles nested layers, and takes `unit=<names>` to scope a
  run to specific units.

## 0.47.0 — 2026-08-05

- `/context-build nested` builds a router index plus per-unit leaves instead
  of one flat index.

## 0.46.0 — 2026-08-05

- `/context-build` and `/context-update` become skills, and stamp a `Layout:`
  marker on the index so nothing has to infer the layer's shape.

## 0.45.1 — 2026-08-05

- The nested context-layer layout is specified in the domain layer.

## 0.45.0 — 2026-08-05

- The CLI handles a feature that changes kind (command to skill), so `update`
  migrates it instead of leaving two copies installed.

## 0.44.2 — 2026-08-05

- `CLAUDE.md` and the context and domain docs are compressed, cutting what
  every session reads before it starts.

## 0.44.1 — 2026-08-05

- The authoring guide states that `docs/` never ships to `~/.claude/`, so no
  shipped feature may read a `docs/` path at runtime.

## 0.44.0 — 2026-08-05

- `/architect` writes a resume marker, so an interrupted design session can be
  picked up where it stopped.

## 0.43.3 — 2026-08-05

- Oversized feature `description:` fields are trimmed to the length the
  authoring guide specifies.

## 0.43.2 — 2026-08-05

- Vestigial `--no-commit` checks removed from authoring commands that never
  committed anything anyway.

## 0.43.1 — 2026-08-05

- The task-parity guard also checks the `Target:` field gating.
- `chosko-llm task-impl` refuses a task with a missing `Target:`, not only one
  whose target is not `claude`.

## 0.43.0 — 2026-08-05

- `chosko-llm task-impl` hard-refuses any task whose `Target:` is not
  `claude` — an unattended run cannot pause for a human.

## 0.42.2 — 2026-08-05

- Dead reference links removed from the `unity-mcp-skill` skill.

## 0.42.1 — 2026-08-05

- Fix `/task-setup`'s external-LLM prompt templates, which still described the
  superseded task-body schema.

## 0.42.0 — 2026-08-05

- `/task-add --short` — a lightweight body for trivial tasks, skipping the
  deep investigation pass that would cost more than the task.

## 0.41.0 — 2026-08-05

- `/task-implement` skips the test phases on a task that touches nothing but
  documentation.

## 0.40.0 — 2026-08-05

- `/task-implement` offers one fresh subagent per task on a multi-task run, so
  later tasks do not inherit earlier ones' context. `--agents` /
  `--no-agents` pre-answer the question.

## 0.39.0 — 2026-07-28

- `/task-add feature=<slug>` appends a final documentation-update task to
  every feature it plans.

## 0.38.0 — 2026-07-28

- `/task-implement`'s strict-TDD sequence is simplified to the steps it
  actually runs.

## 0.37.0 — 2026-07-28

- `/product-design` sweeps the conversation at the end of a phase for design
  detail that never made it into the document.

## 0.36.0 — 2026-07-28

- `/task-implement` and `chosko-llm task-impl` push once per task, right after
  that task's own commit, instead of deferring to the end of the run.

## 0.35.0 — 2026-07-28

- `/unity-mcp-setup` pushes what it commits; `--no-push` skips the push.

## 0.34.0 — 2026-07-28

- `/project-setup` pushes what it commits; `--no-push` skips the push.

## 0.33.0 — 2026-07-28

- `/domain-setup`, `/product-design` and `/architect` push what they commit;
  `--no-push` skips the push.

## 0.32.0 — 2026-07-28

- `/refactor-codebase` and `/refactor-tests` push what they commit;
  `--no-push` skips the push.

## 0.31.0 — 2026-07-28

- `/context-build` and `/context-update` push what they commit; `--no-push`
  skips the push.

## 0.30.0 — 2026-07-28

- `/task-add`, `/task-clean`, `/task-setup` and `/task-enrich` push what they
  commit; `--no-push` skips the push.

## 0.29.0 — 2026-07-28

- The authoring guide gains one commit-and-push protocol — pull, commit,
  re-sync, push — that every committing feature follows instead of its own.

## 0.28.0 — 2026-07-28

- `chosko-llm export` records the exported repo's version and creation date in
  the manifest.

## 0.27.1 — 2026-07-28

- `chosko-llm export` prints a file-count and line-count report when it
  finishes.

## 0.27.0 — 2026-07-28

- New `statusline` feature kind, and the `session-statusline` status bar that
  ships through it.

## 0.26.0 — 2026-07-27

- `/task-implement -y` and the `skip-tests-unattended` testing-policy marker
  suppress the per-task confirmation on projects with no test suite.

## 0.25.0 — 2026-07-27

- `/architect` adopts `technical-direction.md` as the project's established
  stack instead of re-deciding it per feature.

## 0.24.0 — 2026-07-27

- `/product-design` gains a technical-direction phase and writes
  `technical-direction.md`.

## 0.23.2 — 2026-07-27

- `chosko-llm export` excludes the task backlog, and separates each file
  clearly in the Markdown output.

## 0.23.1 — 2026-07-27

- Fix an invalid `local` declaration in `lib.sh`'s open-in-file-manager
  helper.

## 0.23.0 — 2026-07-27

- `chosko-llm export` opens the output folder when it finishes.

## 0.22.0 — 2026-07-27

- New subcommand `chosko-llm export` — package a repo's Claude config as a
  Markdown file or a zip.

## 0.21.1 — 2026-07-27

- Documentation for the product pipeline end to end.

## 0.21.0 — 2026-07-27

- `/task-clean` prunes the task IDs it removes from `FEATURES.md` too, so the
  feature index stops pointing at tasks that are gone.

## 0.20.0 — 2026-07-27

- `/task-add feature=<slug>` plans tasks from a feature document, and
  reconciles the tasks it generated before when the design changes.

## 0.19.0 — 2026-07-27

- New skill `/architect` — turns a design section into a low-level feature
  document.

## 0.18.0 — 2026-07-27

- New skill `/product-design` — the guided design pass and the documents it
  produces.

## 0.17.0 — 2026-07-27

- `/project-setup` runs `/domain-setup` as part of first-time initialization.

## 0.16.0 — 2026-07-27

- New command `/domain-setup` — scaffolds the domain knowledge layer and the
  `FEATURES.md` index.

## 0.15.0 — 2026-07-27

- The backlog schema gains the `[STALE]` status and the `Feature:` origin
  link.

## 0.14.2 — 2026-07-27

- `refactor-workflow.md` is indexed in the context layer's domain table.

## 0.14.1 — 2026-07-27

- The `product-workflow` domain document describes the design to architecture
  to task pipeline.

## 0.14.0 — 2026-07-21

- New shipped skill `unity-mcp-skill` — drives the Unity Editor through MCP.

## 0.13.2 — 2026-07-21

- The Unity MCP checkpoint question offers explicit automatic and manual
  options instead of an ambiguous opt-out.

## 0.13.1 — 2026-07-17

- Fix `chosko-llm channel --list` listing a bogus `origin` entry.

## 0.13.0 — 2026-07-17

- New subcommand `chosko-llm channel` — point the managed clone at a branch to
  test unmerged work.

## 0.12.0 — 2026-07-17

- `/project-setup` offers to run `/unity-mcp-setup` on Unity projects.

## 0.11.0 — 2026-07-17

- `/task-implement` drives a task's manual checkpoints through Unity MCP when
  the project and the session both support it.

## 0.10.0 — 2026-07-17

- New command `/unity-mcp-setup` — makes a Unity project ready for
  MCP-assisted task implementation.

## 0.9.0 — 2026-07-10

- `/project-setup` injects a Tasks-implementation section into `CLAUDE.md` on
  Unity projects, covering editor dirty-tree noise and the testing policy.

## 0.8.2 — 2026-07-10

- `/task-implement` states that a checkpoint explanation ends the turn with no
  tool call, so the user actually sees it before being asked.

## 0.8.1 — 2026-07-10

- Polished the human-in-the-loop checkpoint wording in `/task-implement`.

## 0.8.0 — 2026-07-09

- The repo ships a Claude Code plugin manifest and marketplace entry.

## 0.7.3 — 2026-07-09

- The non-git VCS rule is stated once and referenced, instead of repeated in
  every command that commits.

## 0.7.2 — 2026-07-09

- Redundant TOOL DISCIPLINE blocks removed from the shipped commands.

## 0.7.1 — 2026-07-09

- New repo guard `check-task-parity.sh` keeps the `/task-implement` prompt and
  `cmd-task-impl.sh` in step.

## 0.7.0 — 2026-07-09

- `/task-implement` becomes a skill, so its supporting files load only when
  the branch that needs them applies.

## 0.6.4 — 2026-07-09

- The duplicated test-runner tables carry "mirrored copy" markers, so an edit
  to one is visibly an edit to both.

## 0.6.3 — 2026-07-09

- Fix `chosko-llm task-impl` running the affected tests twice per task.

## 0.6.2 — 2026-07-09

- The smoke-test suite is removed, and the docs that referenced it updated.

## 0.6.1 — 2026-07-08

- `/task-implement` explains a manual step before asking the human to confirm
  it.

## 0.6.0 — 2026-07-08

- A project can declare `Testing policy for /task-implement: skip-tests` in
  its `CLAUDE.md`, so a run stops asking about the missing suite every time.

## 0.5.1 — 2026-07-08

- The dirty-tree prompt splits "proceed" into committing the existing changes
  first or leaving them uncommitted.

## 0.5.0 — 2026-07-08

- Human-in-the-loop tasks: the `claude+human` and `human` targets, and the
  `Manual interventions` body section that pauses a run at each checkpoint.

## 0.4.1 — 2026-07-08

- The Plastic SCM `## VCS` snippet maps `git log`, so `/context-update`'s
  incremental mode works on a non-git project.

## 0.4.0 — 2026-07-01

- `/task-add` proposes splitting a description into several tasks when it
  bundles independent deliverables.

## 0.3.1 — 2026-07-01

- Fix the `curl | bash` install failing on an unset `BASH_SOURCE`.

## 0.3.0 — 2026-06-05

- `chosko-llm --version` prints the repo-level version.

## 0.2.0 — 2026-06-05

- New subcommand `chosko-llm show` — inspect one feature's versions, status,
  description and body.
- `chosko-llm ls` gains a STATUS column and prints actionable suggestions
  after the table.
- `chosko-llm add --all` installs every uninstalled feature; `update --all`
  skips features that are up to date or locally ahead.
- `chosko-llm uninstall` is reachable through the proxy.
- Semantic colour across the CLI, colour-coded feature kinds, and `NO_COLOR`
  honoured.
- One-liner `curl | bash` install, and a `chosko-llm.cmd` entry point for cmd
  and PowerShell.
- Daily auto-upgrade, toggled with `upgrade --enable-auto` /
  `--disable-auto`.
- The task backlog splits into a lightweight `TASKS.md` index plus per-task
  body files, with the thin body schema and the `Target:` field.
- New commands `/task-add`, `/task-list`, `/task-clean`, `/task-implement`,
  `/task-enrich`, `/refactor-codebase`, `/refactor-tests`, `/context-build`,
  `/context-update` and `/project-setup`.
- `chosko-llm task-impl` runs the external-LLM (aider + Ollama) task sequence,
  with `--model`, `--retries` and `--map-tokens`.
- Commit control across the suite: authoring commands leave their output
  uncommitted and take `--commit`; auto-committing commands take
  `--no-commit`.
- `/task-implement` prompts on a dirty working tree instead of aborting.

## 0.1.0 — 2026-05-06

- Initial release: the `chosko-llm` CLI with `ls`, `add`, `rm`, `update`,
  `upgrade` and `help`, `install.sh` / `uninstall.sh`, and copy-not-symlink
  installs of commands and skills into `~/.claude/`.
