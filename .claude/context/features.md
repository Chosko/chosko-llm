# Features (commands, skills, claude-md, statusline & hooks)

Artifacts this repo *ships*. CLI installs and updates them.

## Overview

Feature kinds, keyed by feature name (kebab-case):

- `commands/<name>.md` — single markdown file, YAML frontmatter. Body = prompt Claude Code runs when user invoke `/<name>`.
- `skills/<name>/SKILL.md` — folder containing `SKILL.md` plus supporting files. Folder copied recursively on install.
- `claude-md/<name>.md` — managed section injected into
  `$CLAUDE_HOME/CLAUDE.md` (between `<!-- chosko-llm:<name>:begin … -->` /
  `:end` markers) rather than copied as standalone file — global CLAUDE.md
  guidance ships and updates like any other feature. `chosko-llm add/rm/update`
  treat as `claude-md:` kind; surrounding user content preserved.
- `statusline/<name>.sh` — directly executable status-bar shell script,
  installed verbatim to `$CLAUDE_HOME/statusline/<name>.sh`. Frontmatter
  lives in bash no-op heredoc (`: <<'CHOSKO_FRONTMATTER' ... CHOSKO_FRONTMATTER`)
  right after shebang, so `parse_frontmatter`'s first-`---`-pair scan still
  find it. `chosko-llm add` does not edit `settings.json`; it prints a merge
  prompt ([shared-lib-kinds.md](./shared-lib-kinds.md) § Public API › statusline
  scripts). `chosko-llm add/rm/update/ls/show` treat as `statusline:` kind.
- `hooks/<name>.sh` — executable script Claude Code runs on hook event.
  Frontmatter in same bash no-op heredoc as statusline, plus two hook-only
  keys: `event:` (required — `PreToolUse`, `SessionStart`, …; enforced per
  [shared-lib-kinds.md](./shared-lib-kinds.md) § Public API › hooks) and `matcher:`
  (optional, narrows event to one tool). Installed to
  `$CLAUDE_HOME/hooks/<name>.sh`; `add` prints a settings.json wiring prompt
  ([shared-lib-kinds.md](./shared-lib-kinds.md) § Public API › hooks). **Local-only kind** — exact
  mirror of statusline's global-only rule; see `scope_supports_kind` in
  [shared-lib.md](./shared-lib.md). Both halves (script + settings.json) must
  be committed, and Claude Code snapshots hook config at session start, so
  new wiring needs fresh session.

**Not a kind — `.claude/skills/`.** `skills/<name>/` is shipped: versioned,
walked by `cmd-ls --available`, installed by `cmd-add`. This repo's OWN
`.claude/skills/<name>/SKILL.md` is repo-local development tooling, invocable
only while working in this repo — what that means is `../../CLAUDE.md`
§ Versioning's `.claude/skills/` exception. Two exist (`context-budget`, `rule-overlap`). Deliberately absent from
"Currently shipped" below, which lists artifacts the CLI installs; the whole
point of the location is that these are not. See
`../domain/features/repo-local-audits.md` and
`../../docs/authoring-guide.md` § "Repo-local skills are not features".

Three feature families have a file of their own: the `task-*` suite and
`task-engine` — [task-suite.md](./task-suite.md); the runbook suite with
`follow-ups` and `follow-ups-resolve` — [runbook-suite.md](./runbook-suite.md);
the product pipeline, `pipeline-engine` and the features built on it, and
`claude-council` — [pipeline.md](./pipeline.md). Every other shipped feature
is listed here.

Currently shipped:
- `commands/project-setup.md` — interactive first-time project init
  wizard. Two phases: GATHER phase collects every choice upfront (VCS
  detection, CLAUDE.md seeding from pasted source, AGENTS.md, task backlog,
  domain layer, context layer), EXECUTE phase applies them in
  fixed order.
  **Authoring command — makes NO commits by default.** Writes own
  artifacts (CLAUDE.md project-info section synthesized from user-pasted
  material only, `## VCS` section mapping git→`cm` for non-git VCS like
  Plastic SCM, `## Tasks implementation` section on Unity projects
  covering editor dirty-tree noise and optional skip-tests
  testing-policy marker, and AGENTS.md), then runs heavy sub-commands last —
  `/task-setup` (leaves scaffolding uncommitted by default), then
  `/domain-setup` (Step 5b — deliberately BEFORE context layer, since
  `/context-build`'s DOMAIN DEPENDENCIES sections link to domain files; its
  GATHER step detects existing `.claude/domain/` and offers indexing docs
  already there), then
  `/context-build` (most context-hungry, gated step, and the wizard always
  invokes it in its default FLAT layout — never `nested`). On Unity
  projects also offers `/unity-mcp-setup`, invoked LAST (after
  `/context-build`, so freshly-built context layer exists for its
  `mcp-tools.md` doc) — wizard only offers and delegates, holds no MCP
  logic itself. By default everything, including
  sub-commands' output, left uncommitted for user review and commit
  in one pass — `../../docs/authoring-guide.md` § Commit-and-push
  convention. With `--commit` it
  commits own artifacts first, then runs sub-commands with `--commit`
  so each commits own output. VCS detection decides whether to inject
  VCS-mapping section (and, under `--commit`, which VCS commits target).
- `commands/unity-mcp-setup.md` — makes Unity project ready for
  MCP-assisted `/task-implement`. Idempotent, re-runnable. Refuses on
  non-Unity projects (probes `ProjectSettings/ProjectVersion.txt`). Two
  sides: VERSIONED project side — adds `com.coplaydev.unity-mcp` to
  `Packages/manifest.json` if missing, writes CLAUDE.md marker
  `Unity MCP for /task-implement: com.coplaydev.unity-mcp (UnityMCP, http)`
  (phrase `/task-implement` scans for), and, when project has
  context layer, creates `.claude/context/mcp-tools.md` + `INDEX.md`
  row — and MACHINE-LOCAL Claude side that registers/verifies
  `UnityMCP` server via `claude mcp add` / `claude mcp list` (written to
  `~/.claude.json` local scope, never committed). **Authoring command —
  leaves versioned artifacts uncommitted by default; `--commit` commits
  exactly those paths.** Handles "running session's tool index doesn't
  refresh after `claude mcp add`" gotcha by telling user to restart.
- `skills/context-build/` — introduces navigation context layer. Three
  phases: analysis (no writes, stops for approval), author, wire CLAUDE.md
  entry-point. Flat by default, stamping `Layout: flat` into the INDEX it
  authors; `nested` / `nested=<unit1>,<unit2>` builds router + per-unit
  leaves instead. One supporting file, `nested.md`, read ON DEMAND — only
  when the run is nested — so flat runs (the common path) never pay its
  tokens. Refuses to convert an existing layer, pointing at
  `/context-convert`. Leaves output uncommitted by default; `--commit`
  commits layer (INDEX, context files, CLAUDE.md edit) with explicit paths
  only. Carries `replaces: command:context-build`.
- `skills/context-update/` — refreshes existing context layer. Four modes
  (smart / `full` / `files=`+`git=` targeted / `-y`), backfills
  `Layout: flat` into any INDEX lacking the marker, then auto-commits
  context files it updated (explicit paths only; no commit when nothing
  changed) — its commit group is `../../docs/authoring-guide.md`
  § Commit-and-push convention. `--no-commit` leaves updates uncommitted. One supporting
  file, `nested.md`, read ON DEMAND when the layer's marker says
  `Layout: nested` — covers per-leaf `Last updated` (each leaf its own
  date authority, router has none), one-leaf-per-file ownership, and
  `unit=<name>` scoping/disambiguation.
- `skills/context-convert/` — restructures an existing layer between the
  two layouts in place, either direction; `/context-build` refuses that
  operation and points here. Direction inferred from the `Layout:` marker,
  forceable with `to=nested` / `to=flat`; `nested=` pre-seeds unit names
  only, never file placement. Plan-first: Phase 1 reports every path move,
  date decision and link rewrite, then stops (`-y` skips the gate).
  Content is MOVED, never rewritten — the only in-file edit is a relative
  link whose depth changed. Dates fail safe both ways (flat→nested: every
  leaf inherits the flat date verbatim; nested→flat: the MINIMUM leaf
  date, never max, never today). No `nested.md` split — every run of this
  skill concerns the nested layout, so there is no cheap flat path to
  keep. Authoring-command commit family: `--commit` to commit and push.
  No `replaces:`.
- `commands/domain-setup.md` — initializes domain knowledge layer, same
  way `/task-setup` initializes backlog: `.claude/domain/`,
  `.claude/domain/features/`, `.claude/domain/INDEX.md` whose
  `| File | Covers |` table matches context INDEX's shape,
  `.claude/FEATURES.md` stub (a `.claude/` root sibling of `TASKS.md`,
  since it indexes work items — feature *documents* live in
  domain layer), and CLAUDE.md pointer at domain index that composes
  with `/context-build`'s context-layer pointer instead of replacing it.
  Idempotent, probe-per-artifact; on project with hand-written domain
  docs indexes them (heading + opening paragraph → "Covers" cell)
  rather than writing empty index. Creates layer and nothing in it —
  design documents and feature entries belong to `/product-design` and
  `/architect`. **Authoring command — leaves scaffolding uncommitted
  by default; `--commit` stages exactly `WRITTEN` paths in one commit.**
- `skills/unity-mcp-skill/` — Unity-MCP operator guide vendored from
  upstream skill. `SKILL.md` carries resource-first workflow,
  core tool categories, best-practice patterns for driving Unity
  editor over MCP; two supporting files under `references/` hold
  detailed material — `tools-reference.md` (per-tool parameters and
  examples) and `workflows.md` (extended scene/script/UI/camera/test
  workflows). Frontmatter reconciled to repo rules on vendoring:
  `name: unity-mcp-skill` (upstream `name` was
  `unity-mcp-orchestrator`), plus required `version` and `type: skill`;
  body and description otherwise verbatim. Complements Unity story
  already in repo (`commands/unity-mcp-setup.md` and
  `skills/task-implement/unity-mcp-checkpoints.md` checkpoint flow) by
  giving Claude reusable reference when operating editor via
  `mcp__UnityMCP__*` tools.
- `commands/session-save.md` — writes per-project handoff file so an in-flight
  conversation's state survive end of that conversation. Command not skill:
  single pass, no phases, no supporting files — same register `/task-list` and
  `/production-status` occupy. One file per save at
  `.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md`; directory created by write, no
  separate `mkdir`. `<slug>` is two-or-three-word kebab-case summary of the
  work (directory listing is the only way an old session ever found), or the
  single argument verbatim. NEVER updates file in place — second save is second
  file with later timestamp. Two forms. **Pointer form**: header block +
  `Resume from:` + one sentence, nothing else. **Full form** (generic and
  common case): optional one-paragraph preamble, then nine `##` sections —
  building / worked-with-evidence / didn't-work-and-why / not-yet-tried / file
  table (`File | Status | Notes`, status exactly one of Complete, In progress,
  Broken, Not started) / decisions-with-reasons / blockers / exact next step /
  environment. Two full-form rules load-bearing: **write every section**, `N/A`
  or `nothing yet` where genuinely empty (skipped section indistinguishable
  from overlooked one), and **evidence or it's a guess**. Form picked by
  artifact detection, which is the COMMAND's job — skills declare nothing, so
  skill gaining/losing artifact needs no change here. Known-artifact table has
  exactly ONE row: `/product-design` → `.claude/domain/design-process.md`.
  Row qualifies only for **project-scoped state document carrying a resume
  marker** (current-stage/phase/next-step line, rewritten as work progresses) —
  static instruction file shipped inside installed skill folder never qualifies
  (holds no state, path relative to skill folder not project), so
  `/task-implement` deliberately has no row and its sessions take full form.
  See [../../docs/authoring-guide.md](../../docs/authoring-guide.md) § "State
  that outlives a session belongs in a project document". No row matches →
  recency check (file written THIS session carrying resume marker) → offer
  pointer form; decline or nothing found → full form. Header block both forms:
  `Work:` (`task <n>` | `feature <slug>` | `document <path>` | `none`; `none`
  first-class, may carry trailing `— <why>`; never two values, never a list,
  never a guessed task number) and `Running:` (skill/command in flight,
  INFERRED from conversation, never by reading state; ask user once when
  unclear). Pruning half: when THIS conversation itself resumed from a session
  file, write new snapshot FIRST then delete the resumed one as superseded —
  path taken from conversation (`/session-resume` states it), never guessed;
  deletes nothing when it can't tell, so an unresumed file is never
  auto-deleted. Writes nothing outside `.claude/sessions/` — not `.gitignore`,
  not `TASKS.md`/`FEATURES.md`, not a feature or context file. **Commits and
  pushes by default** (flags per `../../docs/authoring-guide.md`
  § Commit-and-push convention): pull
  at start before writing, then ONE commit `Save session <slug>` staging the
  new file plus, when the superseded file was tracked, its deletion; shell use
  is a clock read plus the commit-and-push protocol's git commands, none under
  `--no-commit`.
- `commands/session-resume.md` — reads one handoff and briefs current
  conversation from it. Command not skill, same single-pass shape. Resolution
  has exactly THREE forms: no argument → newest candidate; `YYYY-MM-DD` →
  newest candidate from that date; a path (contains `/` or `\`, or ends `.md`)
  → read as given with NO candidacy check. **No task-number selector** — bare
  number unrecognized, said in one line, run continues with newest candidate
  (whole failure contract is degradation, never refusal; only a missing
  directory / no candidate / missing explicit path stop it). **Only a file
  carrying a `Work:` line is a candidate** — the store may hold companion
  documents, and a non-candidate is skipped SILENTLY, not warned about. Ties on
  identical `YYYY-MM-DD-HHMM` prefix break deterministically on the FULL
  filename, descending; the picked file is named on the first output line,
  which is what makes a wrong pick correctable. Pointer form is followed: reads
  artifact named by `Resume from:` and briefs from THAT, using session file for
  its header block only; unresolved path named on its own line and briefing
  called thin. Staleness (>14 days) and paths that no longer resolve are both
  reported BEFORE the briefing, never after. Briefing fixed in shape: what was
  being built, what must not be retried (reasons kept attached), exact next
  step VERBATIM — then **stops and waits**, starting no work, not even the
  obvious one-line first step. Pruning half: closes by naming the resumed file
  and instructing the resumed session to delete it once its `Work:` is finished
  — an instruction, never an action, which is what keeps the command read-only
  and what lets `/session-save`'s supersession delete take the path from the
  conversation. Never names the pointed-at artifact for deletion; only the
  session file is superseded. Reads nothing under `.claude/tasks/`, nor
  `FEATURES.md`/`PLAN.md`, unless `Work:` points there. Writes nothing, deletes
  nothing, stages nothing; no `--prune`, no `--commit`. As with
  `/session-save`, no `chosko-llm` subcommand walks `.claude/sessions/` —
  session files are context for a human or agent, never input to tooling.
- `commands/refactor-codebase.md` — behaviour-preserving, plan-first,
  test-gated refactor: extract constants/enums, dedupe, split oversized
  files, clean imports, rename. `scope=` / `focus=` limit work; `--commit`
  commits result (default leaves uncommitted).
- `commands/refactor-tests.md` — splits oversized test files into focused ones,
  runs suite before/after each split to keep it green. `threshold=`
  sets line cutoff; `--commit` commits splits (default uncommitted).
- `skills/doc-consolidate/` — rewrites a rules document (or every `.md`
  under a folder) under `claude-md:editing-discipline`, meaning-preserving:
  classifies each normative statement kept / superseded / historical /
  duplicate / restated / merged — every section of every file up front —
  writes the per-section ledgers of drops and merges only to one scratchpad
  file whose path it prints, then gates once per run on the judgement calls
  alone (entries the rules can't settle) as a numbered list plus a count line
  per file: `all` approves, numbers overrule, `ledger` prints them; no
  judgement calls means no gate. Rewrites, then spawns
  the fresh-context verifier in `verifier.md` (old + new text, no ledger)
  whose LOST list must be restored or accepted before the run ends; on a
  folder resolves cross-file duplicates with `rule-overlap`'s collection
  method, one owner cited from the rest. Preserves frontmatter, the `#`
  header, context six sections, feature-doc sections. Line counts reported
  as observation, never a target. Uncommitted by default; `--commit`.
- `claude-md/tool-usage-policy.md` — claude-md artifact: global tool-usage
  guidance injected into `$CLAUDE_HOME/CLAUDE.md`.
- `claude-md/editing-discipline.md` — claude-md artifact: nine rules for
  editing a rules document (supersede, no history in body, rule not decision,
  cite not paraphrase, carry consequences). Installed `--local` into this
  repo's own `CLAUDE.md`; the authoring guide and the feature template cite
  it, `task-review` flags stratification against it.
- `claude-md/git-commit-style.md` — claude-md artifact: global commit-message
  shape — subject, optional body, trailer threshold — injected into
  `$CLAUDE_HOME/CLAUDE.md`. Read the artifact for the policy itself; commit
  hygiene (staging, atomicity, push) stays in
  `skills/task-engine/references/commit.md`. Never restate it in a feature
  body: `docs/authoring-guide.md` § *Global rules ship as `claude-md`*.
- `hooks/remote-session-protocol.sh` — hook artifact (`event: PreToolUse`,
  `matcher: AskUserQuestion`): in a confirmed remote cloud session it DENIES
  the tool and returns the text protocol as `permissionDecisionReason` — one
  numbered batch, lettered options, a recommendation each, then end of turn —
  so a slow reply can't drive a re-ask loop. Gate is **positive-only** and
  evaluated by the shell, not the model: `CLAUDE_CODE_REMOTE=true` or non-empty
  `CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE`; anything else prints nothing (= no
  permission decision) and the tool proceeds untouched. False negatives are the
  accepted failure direction (renamed variable ⇒ hook stops firing ⇒ retune
  it), deliberately not "when in doubt, assume remote". `IS_SANDBOX` is
  explicitly NOT a signal — local sessions are sandboxed too. Carries no
  `set -euo pipefail` by design: exit 2 from a `PreToolUse` hook blocks the
  call, so every path ends in explicit `exit 0`. Chosen over a `CLAUDE.md`
  section because a hook costs zero resident tokens in the sessions where it
  never fires, and denial is enforcement rather than guidance.
- `statusline/session-statusline.sh` — statusline artifact: model · cwd ·
  git branch · context% · cost · 5h/7d rate limits. Parses the session JSON with its own
  awk flattener (scalars to `dotted.path<TAB>value` lines, `null` dropped so
  missing and null read the same) — no `jq`, per the no-new-dependencies rule.

## Public API (per-feature contract)

Every feature file requires complete frontmatter block:
```yaml
---
name: <kebab-case>          # MUST match filename / folder name
version: <semver>           # required; install refuses without it
type: command | skill | claude-md | statusline | hook
description: <one line>
replaces: command:<name>     # OPTIONAL, only on a kind change; see below
requires: skill:<name>       # OPTIONAL, any kind; comma-separated; see below
event: PreToolUse            # hook kind ONLY; required there
matcher: AskUserQuestion     # hook kind ONLY; optional, narrows event to one tool
disable-model-invocation: true   # OPTIONAL loading-control key; see below
paths:                       # OPTIONAL, skills only; see below
  - "Assets/**"
---
```

**`description` is short by contract** — `../../docs/authoring-guide.md`
§ The `description` contract. Flags,
argument grammar, refusals, read-only contracts and commit/push defaults
live in the body's leading `#` header (`# /name`, summary, `# Usage:`,
`# Examples:`), which loads only on invocation and which `cmd-show` prints
under the description ([cmd-show.md](./cmd-show.md)). Every shipped body has
one; the two engines' is a two-line "read by path; not invoked" note.

**Loading-control keys** — three Claude Code frontmatter keys this repo may
use; `parse_frontmatter` ignores unknown keys, so they pass through
`add` / `update` untouched and are never a rejection path:
- `disable-model-invocation: true` (commands, skills) — description kept
  out of the model's context; only the user invokes it, by typing
  `/<name>`; stays listed and typeable. **Carried by eleven features:** the
  two reference libraries `skills/task-engine/`, `skills/pipeline-engine/`,
  the authoring skill `skills/doc-consolidate/`, and eight wizards /
  housekeeping commands never worth suggesting unprompted —
  `commands/project-setup.md`, `commands/task-setup.md`,
  `commands/domain-setup.md`, `commands/unity-mcp-setup.md`,
  `commands/refactor-codebase.md`, `commands/refactor-tests.md`,
  `commands/runbook-prune.md`, `commands/runbook-clean.md`. `task-review` /
  `task-iterate` deliberately NOT hidden — `/task-implement --review` spawns
  them by name.
- `user-invocable: false` (commands, skills) — hidden from the `/` menu;
  model-only. Carried by nothing.
- `paths:` (skills only) — loads only when files matching its globs are in
  play. **Carried by one:** `skills/unity-mcp-skill/` (`Assets/**`,
  `ProjectSettings/**`, `Packages/**`), so it loads only in a Unity project.

`replaces:` is an optional key from the kind-migration path: set it when
a feature changes kind (`commands/<n>.md` rewritten as `skills/<n>/SKILL.md`),
so the install verbs remove the superseded artifact instead of leaving two
definitions of one slash command — which verbs, and when:
[shared-lib-kinds.md](./shared-lib-kinds.md) § Public API › Kind migration. Live
examples: `skills/context-build/SKILL.md`, `skills/context-update/SKILL.md` and
`skills/task-clean/SKILL.md`.
Drop the key once the migration has propagated.

`requires:` is the other optional key, valid on every kind: a comma-separated
list of kind-prefixed specs naming features whose files this one reads at run
time. Install and removal semantics: [shared-lib-kinds.md](./shared-lib-kinds.md) §
Public API › Dependencies (`requires:`); the `--force` override:
[cmd-rm.md](./cmd-rm.md) § Public API. Live examples: `commands/task-add.md`,
`commands/task-list.md`, `skills/task-clean/SKILL.md` and
`skills/task-implement/SKILL.md`, all declaring `requires: skill:task-engine`;
and `commands/pipeline-check.md`, declaring `requires: skill:pipeline-engine`.
`skills/pipeline-revise/SKILL.md` declares seven at once.
Unlike `replaces:`, it is permanent — the dependency does not "propagate" and
the key is dropped only when the reference is.

See `../../docs/authoring-guide.md` for canonical spec, including
semver bump rules, commit-control convention, three places task
status vocabulary must agree, and rule that multi-session skill keeps
its state in versioned project document.

## Internal patterns

- **Filename = folder name = `name` field.** Every verb resolves by
  filename, never by `name` ([cmd-ls.md](./cmd-ls.md) § Internal patterns),
  so a mismatched `name` is silently ignored; the authoring guide flags this
  as a common mistake.
- **Skills are folders, not single files.** Bare `skills/foo.md` is
  ignored by every script. See `feature_kind` in
  [shared-lib-kinds.md](./shared-lib-kinds.md).
- **Supporting files are read on demand.** A skill folder's non-`SKILL.md`
  files exist so the common path stays cheap: `SKILL.md` names the branch
  and the file to read when it fires, and nothing else reads them.
  `skills/task-implement/` (seven), `skills/product-design/` (six),
  `skills/architect/` (seven), `skills/pipeline-revise/` (four, one per
  branch), `skills/task-review/remote-diffs.md`,
  `skills/context-build/nested.md` and
  `skills/context-update/nested.md` (one each) all follow this.
  `skills/task-iterate/` has none, and says so in its body so nobody goes
  looking for one. Whole
  folder is copied on install regardless — the saving is tokens per run,
  not bytes on disk.
- **`skills/task-engine/references/` and `skills/pipeline-engine/references/`
  are the other thing entirely.** Those files are read by OTHER features, not by their own `SKILL.md`, which is why
  the skill needs `requires:` and a plain supporting file does not. A skill's
  own supporting file is private to it and needs no declaration; a file
  another feature reads is a cross-feature dependency and must be declared, or
  it installs into a dangling path. See
  `../../docs/authoring-guide.md` § "Keeping the two `council-gate.md` copies
  in step" for the case where this does NOT apply (an optional dependency,
  which `requires:` cannot express).
- **A shipped body cites another shipped file by a path relative to
  itself**, never by an absolute install home — `../../CLAUDE.md`
  § Versioning and `../../docs/authoring-guide.md` § `requires:`.
- **`scripts/check-home-paths.sh` guards that** — its contract is
  `../../CLAUDE.md` § Versioning and `../../docs/authoring-guide.md` § The
  home-path guard. Two passes: `grep` one line at a time, then an awk two-line window that
  catches a citation wrapped across a line break (continuation line's
  blockquote marker and indentation stripped), reported against the line the
  literal starts on. The pattern reaches that awk through the environment
  (`ENVIRON`), never `-v`, whose escape processing strips the regex's
  backslashes and leaves `$` an end-of-line anchor. Asking whether an
  optional feature is installed goes by name, never by path —
  `../../docs/authoring-guide.md` § "Asking whether a feature is installed:
  name it"; for the one place a home is derived, see `probes.md` § *Which
  install home — both of them*.
  No CI and no pre-commit hook, so `CLAUDE.md` § Versioning plus each task's
  acceptance criteria are the whole enforcement mechanism.
- **No state file.** Versions live in frontmatter; what's installed is
  whatever exists under `$CLAUDE_HOME`. See `../../CLAUDE.md` hard rules.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter schema, naming rules,
  semver bump table. Canonical.
- `../../CLAUDE.md` — hard rules: every feature has frontmatter; filesystem
  is source of truth; copy-not-symlink; `cmd-add` / `cmd-update` reject
  files missing `version`.

## Cross-references

- [shared-lib.md](./shared-lib.md) — `parse_frontmatter`,
  `require_versioned_source`, path helpers that locate features.
- [cmd-add.md](./cmd-add.md), [cmd-update.md](./cmd-update.md),
  [cmd-rm.md](./cmd-rm.md), [cmd-ls.md](./cmd-ls.md) — verbs that
  operate on these artifacts.
- [task-suite.md](./task-suite.md), [runbook-suite.md](./runbook-suite.md),
  [pipeline.md](./pipeline.md) — the three feature families with a
  file of their own.

## When to read the source

- Authoring or modifying specific feature → relevant
  `commands/<name>.md` or `skills/<name>/SKILL.md`. Body content
  outside scope of this navigation layer; it's prompt material for
  Claude Code, not project source.
- Adding/removing frontmatter field → `../../docs/authoring-guide.md` plus
  `parse_frontmatter` in `scripts/lib.sh` (see
  [shared-lib.md](./shared-lib.md)).
