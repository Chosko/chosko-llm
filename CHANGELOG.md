# Changelog

What changed for a user of the `chosko-llm` CLI or of the features it ships,
one section per root `VERSION` value, newest first.

Two rules keep this file honest, and they are converses of each other:

- **A `VERSION` bump without a matching section here is an incomplete change.**
- **A change that does not bump `VERSION` gets no entry here.** Repo-local
  artifacts that never reach a user — anything under `.claude/` that is not
  shipped — never bump `VERSION`, so they never appear.

`scripts/check-changelog.sh` guards the first rule and this file's structure;
run it after every bump.

Sections are ordered by **descending semver, not by date**. The repo's history
is a DAG: a side branch ran its own bumps while master ran others, and the two
merged. Descending semver is the only order in which "everything above the
version you had" is the right answer.

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
