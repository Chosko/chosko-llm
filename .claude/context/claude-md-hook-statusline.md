# Features: claude-md, hook and statusline artifacts

## Overview

Covers the shipped artifacts of the three non-command, non-skill kinds. The
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
