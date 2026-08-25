# Changelog

User-facing changes per root `VERSION`, highest version first. Rules and schema: `docs/authoring-guide.md` § Versioning.

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
