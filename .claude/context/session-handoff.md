# Features: session handoff

## Overview

Covers the session-handoff pair, `/session-save` and `/session-resume`.
Feature kinds: [features.md](./features.md); the frontmatter contract both
follow: [feature-contract.md](./feature-contract.md).

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
