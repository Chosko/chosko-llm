# Features: session handoff

## Overview

Covers the four session commands: the handoff pair, `/session-save` and
`/session-resume`, and the two read-only readers, `/session-list` and
`/session-describe`. Feature kinds: [features.md](./features.md); the
frontmatter contract all four follow: [feature-contract.md](./feature-contract.md).

- `commands/session-save.md` — writes per-project handoff file so an in-flight
  conversation's state survive end of that conversation. Command not skill:
  single pass, no phases, no supporting files — same register `/task-list` and
  `/production-status` occupy. One file per save at
  `.claude/sessions/YYYY-MM-DD-HHMM-<slug>.md`; directory created by write, no
  separate `mkdir` for the session file. `<slug>` is two-or-three-word kebab-case summary of the
  work (how an old session is found — `/session-list` shows it,
  `/session-resume <slug>` resumes by it), or the single argument verbatim. NEVER updates file in place — second save is second
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
  not `TASKS.md`/`FEATURES.md`, not a feature or context file. HANDOFF MOVE,
  after the write and any supersession delete: orchestrate-mode area handoffs
  (`agent-*.md`, found by Glob) in `pending/` and in the previous save's or the
  resumed file's `<stem>/` folder are moved — `mkdir -p` the new stem folder,
  one `mv` each, content never read — into `<new-stem>/`, and each source
  folder left empty is `rmdir`ed; moves run under `--no-commit` too.
  **Commits and
  pushes by default** (flags per `../../docs/authoring-guide.md`
  § Commit-and-push convention): pull
  at start before writing, then ONE commit `Save session <slug>` staging the
  new file, the moved handoffs' new paths and old paths' removals, plus, when
  the superseded file was tracked, its deletion; shell use is a clock read,
  HANDOFF MOVE's `mkdir`/`mv`/`rmdir`, and the commit-and-push protocol's git
  commands, none of the git under `--no-commit`.
- `commands/session-resume.md` — reads one handoff and briefs current
  conversation from it. Command not skill, same single-pass shape. Holds THE
  RESOLUTION RULE — the one home of argument resolution, written
  self-contained so `/session-describe` applies it by name. Four forms, tried
  in order: a path (contains `/` or `\`, or ends `.md`) → read as given with
  NO candidacy check; `YYYY-MM-DD` → newest candidate from that date; a slug
  (anything else not purely numeric) → newest candidate whose filename slug
  part (after `YYYY-MM-DD-HHMM-`, before `.md`) equals it EXACTLY; nothing →
  newest candidate. Slug matching is on the file listing, never `ls`/`grep`.
  A slug with no exact match names up to five nearest slugs and STOPS — no
  substring/fuzzy fallback, no fall-through to newest; the one exception to the
  degradation contract, because guessing a file for a typed name loads the
  wrong session. **No task-number selector** — bare number unrecognized, said
  in one line, run continues with newest candidate. Other stops: missing
  directory / no candidate (date form names dates that have candidates) /
  missing explicit path. **Only a top-level file carrying a `Work:` line is a
  candidate** — companion documents, subfolders (orchestrate-mode area
  handoffs, `pending/`) and their contents skipped SILENTLY. Ties (shared
  prefix or shared slug) break deterministically on the FULL filename,
  descending; the picked file is named on the first output line, which is
  what makes a wrong pick correctable. Pointer form is followed: reads
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
  conversation. Before that close, when the resolved file has a `<stem>/`
  folder, lists each `agent-<area>.md` by area with its path, from the file
  listing alone — no handoff body read, orchestrate mode not turned on.
  Never names the pointed-at artifact for deletion; only the
  session file is superseded. Reads nothing under `.claude/tasks/`, nor
  `FEATURES.md`/`PLAN.md`, unless `Work:` points there. Writes nothing, deletes
  nothing, stages nothing; no `--prune`, no `--commit`. As with
  `/session-save`, no `chosko-llm` subcommand walks `.claude/sessions/` —
  session files are context for a human or agent, never input to tooling.
- `commands/session-list.md` — one line per session, newest first by full
  filename descending, in one fenced block plus a count:
  `<YYYY-MM-DD HH:MM>  <slug>  <Work: value>  — <first sentence of next step>`.
  Pointer-form file prints `→ <Resume from: path>` in place of the next step
  and ends `[pointer]`; a session with a `<session-file-stem>/` subfolder ends
  `[areas: <n>]`, n = `agent-*.md` filenames counted. No arguments, no filter
  (a session carries no status). Read budget: ONE Grep over the store for
  `Work:`, `Resume from:` and the *Exact next step* heading with the two lines
  after it (subfolder matches dropped), plus a file listing per subfolder —
  never a full read, no shell. Missing/empty store or no candidate → one line.
  `requires: command:session-save`.
- `commands/session-describe.md` — resolves one handoff by THE RESOLUTION
  RULE in `/session-resume` (cited, never restated; picked file named on first
  line as `Describing <path>`), prints about ten plain lines: about (preamble,
  else first sentence of *What we are building*, with `Work:`/`Running:`),
  stopped-at/next (*Exact next step*), still open (objectives *What we are
  building* sets that the next step shows unfinished — the save schema has no
  objectives section), blocked (*Blockers and open questions*), areas by name
  from the subfolder listing. Read budget: one Grep with line numbers for
  header lines and `##` headings, then line ranges of only those sections;
  *What worked*, *What did not work*, *What has not been tried yet*,
  *Decisions made*, the file table and environment notes NOT read; no area
  handoff body read. Pointer form: header plus the artifact's resume-marker
  line (one Grep) only. Malformed file described as found, never compensated
  by reading more. Does not brief, does not stop and wait. `requires:
  command:session-resume, command:session-save`.
- Both readers: write, delete, stage and commit nothing, correct no file
  however malformed, run no shell, and cite no interaction-policy reference
  (read-only listings sit outside that policy).

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
