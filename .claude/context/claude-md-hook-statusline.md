# Features: claude-md, hook and statusline artifacts

## Overview

Covers the shipped artifacts of the three non-command, non-skill kinds, plus
`commands/pipeline-statusline.md`, the command that wires one of them. The
kinds themselves: [features.md](./features.md); the frontmatter contract:
[feature-contract.md](./feature-contract.md).

- `claude-md/tool-usage-policy.md` — claude-md artifact: global tool-usage
  guidance injected into `$CLAUDE_HOME/CLAUDE.md`.
- `claude-md/editing-discipline.md` — claude-md artifact: nine rules for
  editing a rules document (supersede, no history in body, rule not decision,
  cite not paraphrase, carry consequences). Installed `--local` into this
  repo's own `CLAUDE.md`; the authoring guide and the feature template cite
  it, `task-review` flags stratification against it.
- `claude-md/git-commit-style.md` — claude-md artifact: global commit-message
  shape — subject, optional body, ban on Claude attribution lines — injected
  into `$CLAUDE_HOME/CLAUDE.md`. Read the artifact for the policy itself; commit
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
- `statusline/pipeline-statusline.sh` — statusline artifact: the session
  line, then runbook + task progress and one line per task in scope that is
  `[IN PROGRESS]` or in flight in a `wt/task-<N>` worktree, read from the
  project's `.claude/` indexes and the git dir. Hard constraint: bash
  only `exec`s ONE `awk` under `LC_ALL=C` — no other fork (git, grep, sed,
  cygpath, date), since a late render is dropped by Claude Code and each fork
  costs ~0.5 s on Windows. awk parses the JSON, reads `.git/HEAD` (following a
  worktree's `gitdir:`, and leaving the common git dir — through its
  `commondir` file — in `GITDIR`), tests file existence by `getline`, takes
  the clock from `srand()`. THE IN-FLIGHT PROBE: `inflight(unit)` reads
  `$GITDIR/worktrees/<unit>/HEAD` and is true when it names
  `refs/heads/wt/<unit>` — git's registry entry for a linked worktree, named
  after the directory basename the protocol makes the unit name
  (`skills/task-engine/references/worktree.md` § *A worktree is a unit in
  flight*); every task in scope with a `task-<N>` entry is set `IN PROGRESS`
  before the counts, so the base tree's `TASKS.md`, which never sees the
  worktree's flip, still renders it. Task scope, first match: runbook title range → step-heading
  ids → steps' `Done:` lines (only when no heading names one) → `[ACTIVE]`
  milestone's features in `PLAN.md` → all of `TASKS.md`; archived ids in
  scope count done. Labels and both glyph sets (Nerd Font octal escapes,
  `--no-nerd-font` Unicode) sit in shell variables at the top, passed by `-v`.
  The awk program is single-quoted: an apostrophe anywhere in it, comments
  included, breaks the script.
- `commands/pipeline-statusline.md` — command, `requires:
  statusline:pipeline-statusline`: the agent edits only the `statusLine` key
  of the user `settings.json` (no jq), resolving the user scope as
  `${CLAUDE_HOME:-$HOME/.claude}` — the home-path guard's rule for state
  living in the user scope by design; backs up a replaced status line (value + script copy +
  `script-path`) to `statusline/pipeline-statusline.backup/`, never
  overwriting an existing backup; `uninstall` restores it; refresh goes
  through `chosko-llm update`; ends with a timed run of the renderer, in the project and in an empty
  directory, on the shape of `statusline-last-input.json` when present, else a
  fixture. Shares its name with the statusline, so CLI calls need the kind
  prefix.

## Public API

- None beyond [feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- None beyond [feature-contract.md](./feature-contract.md) § Internal patterns.

## Domain dependencies

- None beyond [features.md](./features.md) § Domain dependencies.

## Cross-references

- [features.md](./features.md) — feature kinds and the rest of the shipped
  inventory; [feature-contract.md](./feature-contract.md) — the frontmatter
  contract these features follow.

## When to read the source

- None beyond [features.md](./features.md) § When to read the source.
