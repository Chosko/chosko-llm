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
  [shared-lib-scope.md](./shared-lib-scope.md). Both halves (script + settings.json) must
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
- [setup-commands.md](./setup-commands.md) — `commands/project-setup.md`,
  `commands/domain-setup.md`.
- [context-skills.md](./context-skills.md) — `skills/context-build/`,
  `skills/context-update/`, `skills/context-convert/`.
- [session-handoff.md](./session-handoff.md) — `commands/session-save.md`,
  `commands/session-resume.md`, `commands/session-list.md`,
  `commands/session-describe.md`.
- [refactor-doc-consolidate.md](./refactor-doc-consolidate.md) —
  `commands/refactor-codebase.md`, `commands/refactor-tests.md`, `skills/doc-consolidate/`.
- [claude-md-hook-statusline.md](./claude-md-hook-statusline.md) —
  `claude-md/tool-usage-policy.md`, `claude-md/editing-discipline.md`,
  `claude-md/git-commit-style.md`, `hooks/remote-session-protocol.sh`,
  `statusline/session-statusline.sh`.
- [quick-implement.md](./quick-implement.md) — `skills/quick-implement/`,
  one change from conversation to commit with no backlog entry, reading
  `task-engine`'s shared checks.
- [orchestrate-mode.md](./orchestrate-mode.md) — `skills/orchestrate-mode/`,
  a conversation-scoped mode turning every change request into per-area
  subagents with disjoint file ownership.
- [interaction-engine.md](./interaction-engine.md) — `skills/interaction-engine/`,
  the non-invocable reference library for the interaction policy. Every
  interactive feature, in every family, declares
  `requires: skill:interaction-engine`, accepts `--attended` /
  `--unattended`, and tags each of its gates `confirmation`, `design` or
  `destructive`.

The frontmatter block, the `description` contract, the optional keys and the
authoring patterns every feature follows: [feature-contract.md](./feature-contract.md).

## Public API

- [feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- `../../docs/authoring-guide.md` — frontmatter schema, naming rules,
  semver bump table. Canonical.
- `../../CLAUDE.md` — hard rules: every feature has frontmatter; filesystem
  is source of truth; copy-not-symlink; `cmd-add` / `cmd-update` reject
  files missing `version`.

## Cross-references

- [shared-lib-frontmatter.md](./shared-lib-frontmatter.md),
  [shared-lib-scope.md](./shared-lib-scope.md) — `parse_frontmatter`,
  `require_versioned_source`, path helpers that locate features.
- [cmd-add.md](./cmd-add.md), [cmd-update.md](./cmd-update.md),
  [cmd-rm.md](./cmd-rm.md), [cmd-ls.md](./cmd-ls.md) — verbs that
  operate on these artifacts.
- [task-suite.md](./task-suite.md), [runbook-suite.md](./runbook-suite.md),
  [pipeline.md](./pipeline.md) — the three feature families with a
  file of their own.
- [feature-contract.md](./feature-contract.md), [setup-commands.md](./setup-commands.md),
  [context-skills.md](./context-skills.md), [session-handoff.md](./session-handoff.md),
  [quick-implement.md](./quick-implement.md),
  [orchestrate-mode.md](./orchestrate-mode.md),
  [refactor-doc-consolidate.md](./refactor-doc-consolidate.md),
  [claude-md-hook-statusline.md](./claude-md-hook-statusline.md) — the
  contract and the rest of the shipped inventory.

## When to read the source

- Authoring or modifying specific feature → relevant
  `commands/<name>.md` or `skills/<name>/SKILL.md`. Body content
  outside scope of this navigation layer; it's prompt material for
  Claude Code, not project source.
- Adding/removing frontmatter field → `../../docs/authoring-guide.md` plus
  `parse_frontmatter` in `scripts/lib.sh` (see
  [shared-lib-frontmatter.md](./shared-lib-frontmatter.md)).
