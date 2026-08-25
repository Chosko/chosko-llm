# Changelog

User-facing changes per root `VERSION`, highest version first. Rules and schema: `docs/authoring-guide.md` § Versioning.

## 1.23.0 — 2026-08-25

- **chosko-llm changelog** every entry is now one terse line opening with a bold subject naming what changed.
- **chosko-llm upgrade** renders that bold subject in colour, and strips the `**` markers when colour is off.
- **CHANGELOG.md** the whole history is rewritten in the new style; versions, dates and ordering are untouched.

## 1.22.5 — 2026-08-25

- **chosko-llm ls** about 27× faster — 5.4 s down to 0.2 s on ~34 features, from 217 processes to 3, with byte-identical output.
- **chosko-llm show / update** faster too: the `superseded` and `migration pending` probes read an index built once instead of rescanning the clone.

## 1.22.4 — 2026-08-25

- **/production-status** renders its feature section as a fixed five-column table instead of improvising a shape per run.

## 1.22.3 — 2026-08-25

- **/task-implement, /task-review** instruction fixes: the review-budget authority is listed where it is used, and the reviewer's reading list defers to the read budget.

## 1.22.2 — 2026-08-25

- **No user-facing change** in this release.

## 1.22.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.22.0 — 2026-08-25

- **/task-review** honours the read budget its caller sends, and reports a cap that actually binds.
- **/task-review** invokes no test command in any mode — a green suite is an input its caller hands it.
- **chosko-llm add skill:task-review** installs `task-engine` first, now that the skill declares it.

## 1.21.0 — 2026-08-25

- **/task-implement --review** gains `--review-model` and `--review-effort`, both defaulting to `auto` and resolved per task from that task's own diff.
- **/task-implement --review** now spawns a Sonnet reviewer on an ordinary task instead of inheriting the implementer's model; `--review-model same` restores the old behaviour.

## 1.20.0 — 2026-08-25

- **skill:task-engine** gains `references/review-budget.md`, the single authority for the review cost controls its consumers wire up next.

## 1.19.3 — 2026-08-25

- **/architect** no longer leaves a cleaned feature stuck at `[DONE]`: the iterate guard keys its status flip on the feature's status, not its task list.

## 1.19.2 — 2026-08-25

- **No user-facing change** in this release.

## 1.19.1 — 2026-08-25

- **chosko-llm ls** is fast again — each row parses any given file at most once, undoing the 30% the `REQUIRES` column cost.

## 1.19.0 — 2026-08-25

- **/production-status** replaces its readiness column with a **Next** column naming the concrete action each feature needs.
- **/production-status** stops claiming `no tasks yet` on a feature whose finished tasks were pruned.

## 1.18.0 — 2026-08-25

- **chosko-llm ls** gains a `REQUIRES` column, so a feature's dependencies read straight off the listing.

## 1.17.0 — 2026-08-25

- **chosko-llm ls** prints one table ordered by feature name instead of five kind-grouped blocks.

## 1.16.0 — 2026-08-25

- **claude-md:git-commit-style** new artifact — a global commit-message shape, with the trailers behind a checkable size test.
- **/task-implement** commit-message body is now optional and capped at 2–3 lines.

## 1.15.0 — 2026-08-25

- **chosko-llm changelog** new subcommand — opens `CHANGELOG.md`, or prints from a version, date or duration with `--since`.
- **chosko-llm upgrade / --version** point at it with a TTY-gated tip.

## 1.14.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.14.0 — 2026-08-25

- **skill:runbook-suggest** new skill — proposes capturing a conversation's follow-up actions as a runbook before the session closes.

## 1.13.0 — 2026-08-25

- **/runbook-clean** new command — deletes each `[DONE]` runbook's body and index block, behind a confirmation gate.

## 1.12.0 — 2026-08-25

- **/runbook-list** new command — one line per runbook: status, name, steps done over total, creation date and source.

## 1.11.0 — 2026-08-25

- **/runbook-create** new command — writes a runbook out of the conversation that produced it, new or `--append`.

## 1.10.0 — 2026-08-25

- **skill:runbook-run** new skill — walks a runbook top to bottom, one subagent per step, committing after each.

## 1.9.0 — 2026-08-25

- **/task-add** asks for pre-authorisation before drafting a task that must edit a document another command owns, instead of only warning.

## 1.8.5 — 2026-08-25

- **skill:task-engine** drops a stale note about a migration that had already landed; no rule changed.

## 1.8.4 — 2026-08-25

- **/task-implement** consumes `task-engine` for the rules the `task-*` suite shares, and declares `requires: skill:task-engine`; behaviour unchanged.

## 1.8.3 — 2026-08-25

- **/task-add** consumes `task-engine` and declares `requires: skill:task-engine`; behaviour unchanged.

## 1.8.2 — 2026-08-25

- **/task-clean** consumes `task-engine` and declares `requires: skill:task-engine`; behaviour unchanged.

## 1.8.1 — 2026-08-25

- **/task-list** is the first feature to consume `task-engine`; its output is unchanged.

## 1.8.0 — 2026-08-25

- **skill:task-engine** new skill — a reference library holding one authority per rule the `task-*` features share. Nothing consumes it yet.

## 1.7.0 — 2026-08-25

- **requires:** new optional frontmatter key naming the features a feature reads a file out of.
- **chosko-llm add** installs a feature's requirements first; **rm** refuses to break an installed dependent without `--force`.

## 1.6.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.6.0 — 2026-08-25

- **/task-implement** gains `--review` and `--rounds N` — a task is reviewed by a fresh context and corrected before its single commit.

## 1.5.0 — 2026-08-25

- **skill:task-iterate** new skill — triages `/task-review`'s findings, applies what survives and records why the rest did not.

## 1.4.0 — 2026-08-25

- **skill:task-review** new skill — audits a diff against the acceptance criteria of the task that produced it, and writes nothing.

## 1.3.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.3.0 — 2026-08-25

- **/task-implement** batch parent becomes a launcher: it hands each agent a fixed-size prompt and never opens a delegated task's body. Observable behaviour unchanged.

## 1.2.3 — 2026-08-25

- **No user-facing change** in this release.

## 1.2.2 — 2026-08-25

- **No user-facing change** in this release.

## 1.2.1 — 2026-08-25

- **No user-facing change** in this release.

## 1.2.0 — 2026-08-25

- **/session-resume** new command — loads one handoff out of `.claude/sessions/`, briefs the conversation, then stops.

## 1.1.0 — 2026-08-25

- **/session-save** new command — writes a per-project handoff capturing what a conversation knows and nothing else does.

## 1.0.0 — 2026-08-25

- **chosko-llm task-impl** removed (breaking) — the local-model lane (aider + Ollama) is gone and the subcommand now exits 2.
- **/task-enrich** is no longer shipped, and `/task-add --enrich` with it; `Target:` keeps `claude`, `claude+human` and `human`.
- **/task-setup** creates the backlog and the two test-dispatch wrappers only, no longer the aider prompt templates.

## 0.63.1 — 2026-08-25

- **chosko-llm help** notes that `upgrade` prints what changed for the versions just pulled.

## 0.63.0 — 2026-08-25

- **chosko-llm upgrade** prints the `CHANGELOG.md` sections for exactly the versions just pulled, instead of a raw commit list.

## 0.62.4 — 2026-08-25

- **No user-facing change** in this release.

## 0.62.3 — 2026-08-25

- **scripts/check-changelog.sh** new authoring-time guard — fails when the top `CHANGELOG.md` section does not match `VERSION`.

## 0.62.2 — 2026-08-25

- **CHANGELOG.md** added at the repo root, backfilled from `0.1.0` onward.

## 0.62.1 — 2026-08-24

- **No user-facing change** in this release.

## 0.62.0 — 2026-08-24

- **skill:claude-council** new skill — pressure-test a decision with five thinking-lens advisors and a dual-chairman synthesis.
- **/task-list** fenced-output instruction trimmed to one reading.

## 0.61.1 — 2026-08-22

- **/task-list** numbered output no longer gets renumbered by the markdown renderer.

## 0.61.0 — 2026-08-16

- **/product-design** replaces `design-process.md` when a run ends instead of appending, so the file stops growing a run at a time.
- **/production-status** no longer treats a `[DONE]` feature as still ready to start.

## 0.60.0 — 2026-08-13

- **FEATURES.md** accepts `[DONE]` as a feature status, so a finished feature has somewhere to land.

## 0.59.0 — 2026-08-11

- **hook** new feature kind — a `.sh` Claude Code runs on a hook event, installed into the repo it governs.
- **chosko-llm update** re-prompts for hook wiring when an update moves a hook's `event:` or `matcher:`.
- **chosko-llm export** includes the `.claude` shell scripts.

## 0.58.2 — 2026-08-09

- **repo scripts** the six that are executed are tracked with the executable bit set.

## 0.58.1 — 2026-08-09

- **/product-roadmap** fixes a steer question whose two options could be read the same way.

## 0.58.0 — 2026-08-08

- **/product-roadmap** asks who proposes the milestone order, and records the strategic premise behind the order it produces.

## 0.57.2 — 2026-08-08

- **/product-roadmap** the product pipeline's stages are renumbered end to end now that it sits in them.

## 0.57.1 — 2026-08-08

- **No user-facing change** in this release.

## 0.57.0 — 2026-08-08

- **/task-list** groups tasks under their milestone in plan order, and flags a task whose feature is blocked.

## 0.56.0 — 2026-08-08

- **/production-status** new command — the active milestone, the ready set, the blocked features and one recommendation.

## 0.55.1 — 2026-08-08

- **No user-facing change** in this release.

## 0.55.0 — 2026-08-08

- **/production-plan** new skill — writes `.claude/PLAN.md`: ordered features per milestone, plus cycle and ordering validation.

## 0.54.1 — 2026-08-08

- **No user-facing change** in this release.

## 0.54.0 — 2026-08-07

- **/architect** resolves a roadmap scope slice instead of a whole design section on projects that have a roadmap.

## 0.53.2 — 2026-08-07

- **/architect** moves its input resolution into an on-demand reference file, so a project with no roadmap reads none of it.

## 0.53.1 — 2026-08-07

- **No user-facing change** in this release.

## 0.53.0 — 2026-08-07

- **/product-roadmap** new skill — milestones with goals, exit criteria and the scope slices that decide what each takes.
- **claude-md:remote-session-protocol** new artifact, installable into a repo's `CLAUDE.md`.

## 0.52.1 — 2026-08-07

- **/task-add** documentation-task ownership gate becomes a warning instead of a refusal.
- **/architect, /product-design** gain an optional `claude-council` decision gate.

## 0.52.0 — 2026-08-06

- **chosko-llm add / update** accept several feature names in one call.

## 0.51.1 — 2026-08-06

- **chosko-llm ls / show** give `superseded` and `migration pending` distinct status colours.

## 0.51.0 — 2026-08-06

- **chosko-llm ls / show** surface a feature whose kind changed and is waiting to be migrated.

## 0.50.0 — 2026-08-06

- **--local / --global** on `ls`, `add`, `rm`, `update` and `show` — install features into a single repo instead of `~/.claude/`.

## 0.49.2 — 2026-08-06

- **scripts/lib.sh** owns install-scope resolution, ahead of the subcommands that use it.

## 0.49.1 — 2026-08-05

- **No user-facing change** in this release.

## 0.49.0 — 2026-08-05

- **/context-convert** new skill — converts a context layer between the flat and nested layouts, reporting the move plan first.

## 0.48.0 — 2026-08-05

- **/context-update** handles nested layers, and takes `unit=<names>` to scope a run to specific units.

## 0.47.0 — 2026-08-05

- **/context-build** `nested` builds a router index plus per-unit leaves instead of one flat index.

## 0.46.0 — 2026-08-05

- **/context-build, /context-update** become skills, and stamp a `Layout:` marker on the index.

## 0.45.1 — 2026-08-05

- **No user-facing change** in this release.

## 0.45.0 — 2026-08-05

- **chosko-llm update** migrates a feature that changed kind instead of leaving two copies installed.

## 0.44.2 — 2026-08-05

- **No user-facing change** in this release.

## 0.44.1 — 2026-08-05

- **No user-facing change** in this release.

## 0.44.0 — 2026-08-05

- **/architect** writes a resume marker, so an interrupted design session can be picked up where it stopped.

## 0.43.3 — 2026-08-05

- **shipped features** oversized `description:` fields trimmed to the length the authoring guide specifies.

## 0.43.2 — 2026-08-05

- **authoring commands** vestigial `--no-commit` checks removed from the ones that never committed anything anyway.

## 0.43.1 — 2026-08-05

- **chosko-llm task-impl** refuses a task with a missing `Target:`, not only one whose target is not `claude`.

## 0.43.0 — 2026-08-05

- **chosko-llm task-impl** hard-refuses any task whose `Target:` is not `claude` — an unattended run cannot pause for a human.

## 0.42.2 — 2026-08-05

- **skill:unity-mcp-skill** dead reference links removed.

## 0.42.1 — 2026-08-05

- **/task-setup** fixes the external-LLM prompt templates, which still described the superseded task-body schema.

## 0.42.0 — 2026-08-05

- **/task-add --short** a lightweight body for trivial tasks, skipping the deep investigation pass that would cost more than the task.

## 0.41.0 — 2026-08-05

- **/task-implement** skips the test phases on a task that touches nothing but documentation.

## 0.40.0 — 2026-08-05

- **/task-implement** offers one fresh subagent per task on a multi-task run; `--agents` / `--no-agents` pre-answer the question.

## 0.39.0 — 2026-07-28

- **/task-add feature=<slug>** appends a final documentation-update task to every feature it plans.

## 0.38.0 — 2026-07-28

- **/task-implement** strict-TDD sequence simplified to the steps it actually runs.

## 0.37.0 — 2026-07-28

- **/product-design** sweeps the conversation at the end of a phase for design detail that never made it into the document.

## 0.36.0 — 2026-07-28

- **/task-implement** pushes once per task, right after that task's own commit, instead of deferring to the end of the run.

## 0.35.0 — 2026-07-28

- **/unity-mcp-setup** pushes what it commits; `--no-push` skips the push.

## 0.34.0 — 2026-07-28

- **/project-setup** pushes what it commits; `--no-push` skips the push.

## 0.33.0 — 2026-07-28

- **/domain-setup, /product-design, /architect** push what they commit; `--no-push` skips the push.

## 0.32.0 — 2026-07-28

- **/refactor-codebase, /refactor-tests** push what they commit; `--no-push` skips the push.

## 0.31.0 — 2026-07-28

- **/context-build, /context-update** push what they commit; `--no-push` skips the push.

## 0.30.0 — 2026-07-28

- **/task-add, /task-clean, /task-setup, /task-enrich** push what they commit; `--no-push` skips the push.

## 0.29.0 — 2026-07-28

- **committing features** all follow one commit-and-push protocol — pull, commit, re-sync, push — instead of each carrying its own.

## 0.28.0 — 2026-07-28

- **chosko-llm export** records the exported repo's version and creation date in the manifest.

## 0.27.1 — 2026-07-28

- **chosko-llm export** prints a file-count and line-count report when it finishes.

## 0.27.0 — 2026-07-28

- **statusline** new feature kind, and the `session-statusline` status bar that ships through it.

## 0.26.0 — 2026-07-27

- **/task-implement -y** and the `skip-tests-unattended` policy marker suppress the per-task confirmation on projects with no test suite.

## 0.25.0 — 2026-07-27

- **/architect** adopts `technical-direction.md` as the project's established stack instead of re-deciding it per feature.

## 0.24.0 — 2026-07-27

- **/product-design** gains a technical-direction phase, and writes `technical-direction.md`.

## 0.23.2 — 2026-07-27

- **chosko-llm export** excludes the task backlog, and separates each file clearly in the Markdown output.

## 0.23.1 — 2026-07-27

- **chosko-llm export** fixes an invalid `local` declaration in the open-in-file-manager helper.

## 0.23.0 — 2026-07-27

- **chosko-llm export** opens the output folder when it finishes.

## 0.22.0 — 2026-07-27

- **chosko-llm export** new subcommand — package a repo's Claude config as a Markdown file or a zip.

## 0.21.1 — 2026-07-27

- **No user-facing change** in this release.

## 0.21.0 — 2026-07-27

- **/task-clean** prunes the task IDs it removes from `FEATURES.md` too, so the feature index stops pointing at tasks that are gone.

## 0.20.0 — 2026-07-27

- **/task-add feature=<slug>** plans tasks from a feature document, and reconciles them when the design changes.

## 0.19.0 — 2026-07-27

- **/architect** new skill — turns a design section into a low-level feature document.

## 0.18.0 — 2026-07-27

- **/product-design** new skill — the guided design pass and the documents it produces.

## 0.17.0 — 2026-07-27

- **/project-setup** runs `/domain-setup` as part of first-time initialization.

## 0.16.0 — 2026-07-27

- **/domain-setup** new command — scaffolds the domain knowledge layer and the `FEATURES.md` index.

## 0.15.0 — 2026-07-27

- **TASKS.md** the backlog schema gains the `[STALE]` status and the `Feature:` origin link.

## 0.14.2 — 2026-07-27

- **No user-facing change** in this release.

## 0.14.1 — 2026-07-27

- **No user-facing change** in this release.

## 0.14.0 — 2026-07-21

- **skill:unity-mcp-skill** new skill — drives the Unity Editor through MCP.

## 0.13.2 — 2026-07-21

- **/task-implement** Unity MCP checkpoint question offers explicit automatic and manual options instead of an ambiguous opt-out.

## 0.13.1 — 2026-07-17

- **chosko-llm channel** fixes `--list` showing a bogus `origin` entry.

## 0.13.0 — 2026-07-17

- **chosko-llm channel** new subcommand — point the managed clone at a branch to test unmerged work.

## 0.12.0 — 2026-07-17

- **/project-setup** offers to run `/unity-mcp-setup` on Unity projects.

## 0.11.0 — 2026-07-17

- **/task-implement** drives a task's manual checkpoints through Unity MCP when the project and the session both support it.

## 0.10.0 — 2026-07-17

- **/unity-mcp-setup** new command — makes a Unity project ready for MCP-assisted task implementation.

## 0.9.0 — 2026-07-10

- **/project-setup** injects a Tasks-implementation section into `CLAUDE.md` on Unity projects, covering dirty-tree noise and the testing policy.

## 0.8.2 — 2026-07-10

- **/task-implement** states that a checkpoint explanation ends the turn, so the user actually sees it before being asked.

## 0.8.1 — 2026-07-10

- **/task-implement** human-in-the-loop checkpoint wording polished.

## 0.8.0 — 2026-07-09

- **plugin manifest** the repo ships a Claude Code plugin manifest and marketplace entry.

## 0.7.3 — 2026-07-09

- **committing commands** the non-git VCS rule is stated once and referenced, instead of repeated in every one of them.

## 0.7.2 — 2026-07-09

- **shipped commands** redundant TOOL DISCIPLINE blocks removed.

## 0.7.1 — 2026-07-09

- **scripts/check-task-parity.sh** new repo guard keeping the `/task-implement` prompt and `cmd-task-impl.sh` in step.

## 0.7.0 — 2026-07-09

- **/task-implement** becomes a skill, so its supporting files load only when the branch that needs them applies.

## 0.6.4 — 2026-07-09

- **/task-implement** its duplicated test-runner tables carry "mirrored copy" markers, so an edit to one is visibly an edit to both.

## 0.6.3 — 2026-07-09

- **chosko-llm task-impl** fixes running the affected tests twice per task.

## 0.6.2 — 2026-07-09

- **smoke-test suite** removed, along with the docs that referenced it.

## 0.6.1 — 2026-07-08

- **/task-implement** explains a manual step before asking the human to confirm it.

## 0.6.0 — 2026-07-08

- **/task-implement** honours `Testing policy for /task-implement: skip-tests` in a project's `CLAUDE.md`, so a run stops asking about the missing suite.

## 0.5.1 — 2026-07-08

- **/task-implement** dirty-tree prompt splits "proceed" into committing the existing changes first or leaving them uncommitted.

## 0.5.0 — 2026-07-08

- **/task-implement** human-in-the-loop targets `claude+human` and `human`, with a `Manual interventions` body section that pauses the run at each checkpoint.

## 0.4.1 — 2026-07-08

- **/context-update** the Plastic SCM `## VCS` snippet maps `git log`, so incremental mode works on a non-git project.

## 0.4.0 — 2026-07-01

- **/task-add** proposes splitting a description into several tasks when it bundles independent deliverables.

## 0.3.1 — 2026-07-01

- **install.sh** fixes the `curl | bash` install failing on an unset `BASH_SOURCE`.

## 0.3.0 — 2026-06-05

- **chosko-llm --version** prints the repo-level version.

## 0.2.0 — 2026-06-05

- **chosko-llm show** new subcommand — inspect one feature's versions, status, description and body.
- **chosko-llm ls** gains a STATUS column, and prints actionable suggestions after the table.
- **chosko-llm add --all** installs every uninstalled feature; `update --all` skips what is up to date or locally ahead.
- **chosko-llm uninstall** is reachable through the proxy.
- **chosko-llm upgrade** gains daily auto-upgrade, toggled with `--enable-auto` / `--disable-auto`.
- **install.sh** one-liner `curl | bash` install, plus a `chosko-llm.cmd` entry point for cmd and PowerShell.
- **semantic colour** across the CLI, colour-coded feature kinds, and `NO_COLOR` honoured.
- **TASKS.md** the backlog splits into a lightweight index plus per-task body files, with the thin body schema and the `Target:` field.
- **/task-add, /task-list, /task-clean, /task-implement, /task-enrich** new task commands.
- **/refactor-codebase, /refactor-tests, /context-build, /context-update, /project-setup** new workflow commands.
- **chosko-llm task-impl** runs the external-LLM (aider + Ollama) task sequence, with `--model`, `--retries` and `--map-tokens`.
- **commit control** authoring commands leave their output uncommitted and take `--commit`; auto-committing commands take `--no-commit`.
- **/task-implement** prompts on a dirty working tree instead of aborting.

## 0.1.0 — 2026-05-06

- **chosko-llm** initial release — `ls`, `add`, `rm`, `update`, `upgrade` and `help`, `install.sh` / `uninstall.sh`, and copy-not-symlink installs into `~/.claude/`.
