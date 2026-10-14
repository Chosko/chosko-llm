# Export skips installed features and pipeline wiring

## Goal
`chosko-llm export` packages a repository's own Claude config. Installed
commands, skills and agents, runbooks, the external-LLM wiring, the runbook
index and the shared `settings.json` are not that config, so neither export
shape carries them.

## Acceptance criteria
- `select_export_files` in `scripts/cmd-export.sh` prunes `.claude/commands`,
  `.claude/skills`, `.claude/agents`, `.claude/runbooks` and `.claude/external`
  from traversal, beside the existing `projects`, `history`, `todos`, `tasks`.
- `.claude/RUNBOOKS.md` and `.claude/settings.json` are excluded; a
  `settings.json` in a subdirectory of `.claude/` is still selected.
- The Markdown export's manifest and the `--archive` zip both omit every
  excluded path.
- The script's header comment states why `*.sh` is selected without citing
  `settings.json` or `.claude/external/`.
- Root `VERSION` is 1.100.1 with a matching `CHANGELOG.md` section.

## Decisions
- Exclusion is unconditional, with no flag to restore it: the user asked to
  prevent exporting these.
- Only the top-level `.claude/settings.json` is excluded, matching the
  existing top-level-only `TASKS.md` exclusion.
- "RUNBOOK.md" in the request read as `.claude/RUNBOOKS.md`, the runbook
  index.

## Hints
- `scripts/cmd-export.sh` (`select_export_files`, header comment)
- `VERSION`, `CHANGELOG.md`

## Drift
- `.claude/domain/features/repo-local-audits.md` § Interfaces and contracts — diverges:
  says `chosko-llm export` deliberately carries this repo's `.claude/skills/`;
  the change excludes every `.claude/skills/` entry.
- `.claude/context/cmd-export.md` § Public API (Selection) and the header
  comment rationale under it — diverges: lists the old include/exclude set and
  cites hooks and `external/run-*-tests.sh` as the `*.sh` rationale.
- `docs/reference.md` § Exporting a repo's Claude config — diverges: says the
  shell subset covers the task-setup test runners.
- `docs/cli-help.txt` § export — settles: says "curated .claude/*.md|json|toml|sh"
  without naming exclusions; the change decides the curated set.
- `.claude/domain/product-design.md` § Config export — settles: describes the
  purpose only; the change decides what counts as configuration.
