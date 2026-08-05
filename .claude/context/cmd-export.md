# cmd-export

## Overview

`scripts/cmd-export.sh` packages repo Claude config — `CLAUDE.md`,
`AGENTS.md`, `README.md`, curated Markdown/JSON/TOML subset of
`.claude/` — into single hand-off artifact. Default shape: one
concatenated Markdown file, fit for Claude Project's knowledge base
(ingested all at once). `--archive` writes zip instead, fit for Claude
chat, where assistant reads members selectively. Both shapes built
from `select_export_files`, one function deciding what's included, so
two artifacts never disagree on what repo's config is.

## Public API

CLI:
- `chosko-llm export [<repo>]` — writes
  `$CHOSKO_LLM_EXPORT_DIR/<repo-name>-claude-config.md`. `<repo>` defaults to
  `$PWD`.
- `chosko-llm export [<repo>] --archive` — writes
  `$CHOSKO_LLM_EXPORT_DIR/<repo-name>-claude-config.zip` instead: selected
  files under top-level `<repo-name>/` directory plus root `MANIFEST.md`
  (repo name, version, commit/changeset, created date, generation date).
- Both forms print resulting absolute path on **stdout** on success — only
  stdout output; every progress/log line goes through `log_*` (stderr).
- After artifact written (either shape) and before open-folder
  prompt, `log_success` line reports file count and total line count
  of selection (`Exported N file(s), M line(s) total.`), computed from
  `$files`/`wc -l` on original repo-relative sources — not by parsing
  generated `.md`/`.zip`.

Selection (`select_export_files <repo_dir>`, repo-relative paths on stdout):
- Includes: `CLAUDE.md`, `AGENTS.md`, `README.md` at repo root, plus files
  under `.claude/` matching `*.md`, `*.json`, `*.toml` (recursively).
- Excludes: `.claude/projects/`, `.claude/history/`, `.claude/todos/`,
  `.claude/tasks/` (all pruned, not just filtered — kept off `find`
  traversal entirely so large `projects/` history or task backlog don't
  slow scan), `.claude/TASKS.md`, and any `settings.local.json` anywhere
  under `.claude/`. Task backlog is working-repo planning metadata, not
  part of repo's Claude config, so never ships in export.
- Missing optional root files skipped silently. Empty selection hard
  error via `die` — nothing to export.

Exit codes:
- 0 on success, or on "no" answer to non-git-repo prompt (nothing
  written).
- 1 (via `die`) when: `<repo>` doesn't resolve to directory; selection
  empty; no zip tool available (`--archive` only); or `<repo>` not
  git repo (or `git` unavailable) and stdin not TTY, so prompt
  can't be answered.

## Internal patterns

- **One selection function, two consumers.** Both Markdown writer and
  zip stager iterate same `select_export_files` output — adding
  include/exclude rule means editing exactly one place.
- **Three-way VCS detection: git / Plastic SCM / neither** (same probe
  `/project-setup` PHASE 1a uses: `.plastic/` present, or `cm` binary
  resolves and `cm status` succeeds from `<repo>`). Drives both `Commit:`
  and `Created:`:
  - git: `Commit:` via `git -C <repo> rev-parse --short HEAD`, `-dirty`
    appended when `git status --porcelain` non-empty. `Created:` is
    earliest commit reachable from `HEAD` (`git log --reverse --format=%ct`,
    first line, converted to `YYYY-MM-DD` via `date -u -d "@<ts>"`).
  - Plastic: `Commit:` via `cm log --limit=1 --format='{changesetid}'`
    (falls back to `unknown changeset` if `cm` errors). `Created:` via
    `cm find revision "where date <= 'now'" --order-ascending
    --format="{date}" --limit=1`, truncated to first 10 characters.
  - Neither: unchanged legacy behavior — warn, prompt to continue with
    `sha=not a git repository`, `Created:` omitted; "no" answer exits 0
    without writing anything; non-TTY stdin can't be prompted, so hard
    `die`.
- **`Version:` read from `<repo>/VERSION`** (trimmed contents) when file
  exists; omitted entirely (not blank/"none") when it doesn't, matching
  how missing optional root files already handled. Placed right after
  `Repo:`; `Created:` placed right after `Commit:` — same relative order
  in both manifest shapes.
- **Zip via `zip -r`, falling back to `powershell.exe -Command
  Compress-Archive`** when `zip` not on `PATH` (Git Bash on Windows ships
  `zipinfo`/`zipgrep` but no `zip`). Paths handed to `powershell.exe`
  converted with `cygpath -w` first — MSYS mangles bare `/c/...` path
  embedded inside `-Command` string (becomes `\c\...`, not `C:\...`),
  which silently breaks `Compress-Archive`'s `-DestinationPath`. If neither
  tool exists, `die` names both.
- **Staged in `mktemp -d`, cleaned via `trap ... EXIT`.** Zip shape
  builds `<stage>/<repo-name>/...` plus `<stage>/MANIFEST.md`, then
  `zip -rq` or `Compress-Archive`s whole staging dir.
- **Existing output files overwritten** without prompting — filename
  deterministic per repo, export is regenerable artifact.
- **Output directory resolution single-sourced** in `lib.sh`'s
  `export_dir_path` (see [shared-lib.md](./shared-lib.md)); `cmd-export.sh`
  never concatenates `$CHOSKO_LLM_EXPORT_DIR` inline.

## Domain dependencies

- `../../CLAUDE.md` — env-var overrides resolved via `lib.sh` helpers; no new
  runtime dependency beyond bash/awk/sed/grep/find plus conditional
  zip/PowerShell branch.

## Cross-references

- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for `die`, `log_*`, and
  `export_dir_path`.
- [cli-entry.md](./cli-entry.md) — proxy dispatches `export` →
  `cmd-export.sh`; not on `auto-upgrade.sh`'s skip list (unlike
  `upgrade`/`channel`/`uninstall`), so daily auto-upgrade can still fire
  before `export` run like any other subcommand.

## When to read the source

- Changing what's included/excluded from export → `select_export_files`
  in `scripts/cmd-export.sh` (only place selection rules live).
- Changing either output shape's layout (Markdown header/manifest format,
  fixed-width `===`/`FILE: <path>`/`===` banner between concatenated files, or
  zip's staging/`MANIFEST.md` content) → two branches at bottom
  of `scripts/cmd-export.sh`.
- Changing non-git-repo prompt or SHA resolution → `git -C "$repo"`
  block in `scripts/cmd-export.sh`.
- Changing export output location → `export_dir_path` in `scripts/lib.sh`.