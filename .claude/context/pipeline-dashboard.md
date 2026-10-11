# Features: pipeline-dashboard

## Overview

Covers `skills/pipeline-dashboard/`, the always-on progress dashboard. The
kinds: [features.md](./features.md); the design:
`../domain/features/pipeline-dashboard.md`.

- `skills/pipeline-dashboard/SKILL.md` — the protocol the **main session
  only** follows while a run is in progress or when the user asks how things
  stand (auto-triggered by its `description`; no `requires:`, and nothing
  requires it). Regenerate only after every status marker of the event is
  written; copy the state folder's page and data into
  `<scratchpad>/pipeline-dashboard/<slug>/` (the Artifact tool publishes only
  from working directories or the scratchpad) and publish that copy; with a
  stored `url`, `read` it then republish to it; without, `list` for the title
  `Pipeline <repo>` before creating one, then store the URL. Refresh triggers,
  the Monitor watcher re-armed every 30 minutes, `pending.json` written then
  cleared, one Italian chat line per republish, any failure one warning line.
- `skills/pipeline-dashboard/scripts/generate.sh` — one awk pass (plus one
  `date` and one `mkdir`): reads `PLAN.md` (first `[ACTIVE]`), `FEATURES.md`,
  `TASKS.md`, `RUNBOOKS.md` (first `[RUNNING]`, else last), the runbook body
  up to `## Do not re-propose`, the task archive, the git dir's worktree
  registry and `pending.json`; writes
  `data.js` (`window.DASH`) and `index.html` (the asset with `__PROJECT__`
  replaced, HTML-escaped) into
  `${CLAUDE_HOME:-$HOME/.claude}/pipeline-dashboard/<slug>/`. `gitdir()`
  resolves the common git dir once into `GITD` (root `.git`, or a worktree's
  `gitdir:` → `commondir` followed); `<slug>` from its `config`'s `origin`,
  else the folder name. THE IN-FLIGHT PROBE: `inflight(unit)` reads
  `$GITD/worktrees/<unit>/HEAD` and is true when it names
  `refs/heads/wt/<unit>` — no git call
  (`skills/task-engine/references/worktree.md` § *A worktree is a unit in
  flight*); a shown task with a `task-<id>` entry gets status `IN PROGRESS`
  whatever `TASKS.md` says, a step of the picked runbook with a
  `runbook-<id>-step-<n>` entry gets marker `~`, the runbook id read off the
  index heading into `RBI`. Scope: the milestone features' tasks, else every task;
  tasks a step names join the list with `scope: false`. A step's `tasks` from
  ids in its title, else the tasks of a feature slug named as a word in it.
  `unreadable` lists only a runbook body the index points at but that cannot
  be read — an empty index is not unreadable. `--text` prints the snapshot,
  `--print-state-dir` the folder. awk builtins `RS`/`RT` are why the runbook
  arrays are named `RB*`.
- `skills/pipeline-dashboard/scripts/watch.sh` — the Monitor's command:
  polls `TASKS.md` every 10 s, prints `task <id>: [OLD] -> [NEW]` per change
  (`fflush()` per line), runs until killed.
- `skills/pipeline-dashboard/assets/index.html` — the page: a body fragment
  (the Artifact skeleton wraps it), `<title>Pipeline __PROJECT__</title>`,
  tokens with both dark blocks, DOM built with `textContent` only, the
  pending banner and modal (once per `pending.id` via `localStorage` in
  try/catch, Esc/backdrop/button close, focus back to the opener).

## Public API

- None beyond [feature-contract.md](./feature-contract.md) § Public API (per-feature contract).

## Internal patterns

- The awk programs are single-quoted in bash: an apostrophe anywhere in
  them, comments included, breaks the script.

## Domain dependencies

- `../domain/features/pipeline-dashboard.md` — the design, the data model,
  the publish and pending contracts.

## Cross-references

- [runbook-run.md](./runbook-run.md), [task-implement.md](./task-implement.md)
  — the orchestrators that cite it.
- [claude-md-hook-statusline.md](./claude-md-hook-statusline.md) —
  `pipeline-statusline`, which parses the same indexes and probes the same
  worktree registry with its own code.
- [task-engine.md](./task-engine.md) — `references/worktree.md`, the rule
  behind the in-flight probe.

## When to read the source

- Changing the data model, the page's sections or the publish order: read
  the generator and the page together — the page reads every field the
  generator writes.
