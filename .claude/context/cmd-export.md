# cmd-export

## Overview

`scripts/cmd-export.sh` packages a repo's Claude config — `CLAUDE.md`,
`AGENTS.md`, `README.md`, and the curated Markdown/JSON/TOML subset of
`.claude/` — into a single hand-off artifact. The default shape is one
concatenated Markdown file, suited to a Claude Project's knowledge base
(ingested all at once). `--archive` writes a zip instead, suited to a Claude
chat, where the assistant reads members selectively. Both shapes are built
from `select_export_files`, the one function that decides what's included, so
the two artifacts can never disagree about what a repo's config is.

## Public API

CLI:
- `chosko-llm export [<repo>]` — writes
  `$CHOSKO_LLM_EXPORT_DIR/<repo-name>-claude-config.md`. `<repo>` defaults to
  `$PWD`.
- `chosko-llm export [<repo>] --archive` — writes
  `$CHOSKO_LLM_EXPORT_DIR/<repo-name>-claude-config.zip` instead: the selected
  files under a top-level `<repo-name>/` directory plus a root `MANIFEST.md`
  (repo name, commit SHA, generation date).
- Both forms print the resulting absolute path on **stdout** on success — the
  only stdout output; every progress/log line goes through `log_*` (stderr).

Selection (`select_export_files <repo_dir>`, repo-relative paths on stdout):
- Includes: `CLAUDE.md`, `AGENTS.md`, `README.md` at the repo root, plus files
  under `.claude/` matching `*.md`, `*.json`, `*.toml` (recursively).
- Excludes: `.claude/projects/`, `.claude/history/`, `.claude/todos/`,
  `.claude/tasks/` (all pruned, not just filtered — kept off the `find`
  traversal entirely so a large `projects/` history or task backlog doesn't
  slow the scan), `.claude/TASKS.md`, and any `settings.local.json` anywhere
  under `.claude/`. The task backlog is working-repo planning metadata, not
  part of a repo's Claude config, so it never ships in an export.
- Missing optional root files are skipped silently. An empty selection is a
  hard error via `die` — nothing to export.

Exit codes:
- 0 on success, or on a "no" answer to the non-git-repo prompt (nothing
  written).
- 1 (via `die`) when: `<repo>` doesn't resolve to a directory; the selection
  is empty; no zip tool is available (`--archive` only); or `<repo>` is not a
  git repo (or `git` is unavailable) and stdin is not a TTY, so the prompt
  can't be answered.

## Internal patterns

- **One selection function, two consumers.** Both the Markdown writer and the
  zip stager iterate the same `select_export_files` output — adding an
  include/exclude rule means editing exactly one place.
- **Commit SHA via `git -C <repo> rev-parse --short HEAD`**, with `-dirty`
  appended when `git status --porcelain` is non-empty. Non-git repos (or a
  missing `git`) warn and prompt to continue with
  `sha=not a git repository`; a "no" answer exits 0 without writing anything;
  a non-TTY stdin can't be prompted, so it's a hard `die`.
- **Zip via `zip -r`, falling back to `powershell.exe -Command
  Compress-Archive`** when `zip` isn't on `PATH` (Git Bash on Windows ships
  `zipinfo`/`zipgrep` but no `zip`). Paths handed to `powershell.exe` are
  converted with `cygpath -w` first — MSYS mangles a bare `/c/...` path
  embedded inside a `-Command` string (it becomes `\c\...`, not `C:\...`),
  which silently breaks `Compress-Archive`'s `-DestinationPath`. If neither
  tool exists, `die` names both.
- **Staged in a `mktemp -d`, cleaned via `trap ... EXIT`.** The zip shape
  builds `<stage>/<repo-name>/...` plus `<stage>/MANIFEST.md`, then
  `zip -rq` or `Compress-Archive`s the whole staging dir.
- **Existing output files are overwritten** without prompting — the filename
  is deterministic per repo, and an export is a regenerable artifact.
- **Output directory resolution is single-sourced** in `lib.sh`'s
  `export_dir_path` (see [shared-lib.md](./shared-lib.md)); `cmd-export.sh`
  never concatenates `$CHOSKO_LLM_EXPORT_DIR` inline.

## Domain dependencies

- `../../CLAUDE.md` — env-var overrides resolved via `lib.sh` helpers; no new
  runtime dependency beyond bash/awk/sed/grep/find plus the conditional
  zip/PowerShell branch.

## Cross-references

- [shared-lib.md](./shared-lib.md) — sources `lib.sh` for `die`, `log_*`, and
  `export_dir_path`.
- [cli-entry.md](./cli-entry.md) — the proxy dispatches `export` →
  `cmd-export.sh`; not on `auto-upgrade.sh`'s skip list (unlike
  `upgrade`/`channel`/`uninstall`), so a daily auto-upgrade can still fire
  before an `export` run like any other subcommand.

## When to read the source

- Changing what's included or excluded from an export → `select_export_files`
  in `scripts/cmd-export.sh` (the only place selection rules live).
- Changing either output shape's layout (Markdown header/manifest format, the
  fixed-width `===`/`FILE: <path>`/`===` banner between concatenated files, or
  the zip's staging/`MANIFEST.md` content) → the two branches at the bottom
  of `scripts/cmd-export.sh`.
- Changing the non-git-repo prompt or SHA resolution → the `git -C "$repo"`
  block in `scripts/cmd-export.sh`.
- Changing the export output location → `export_dir_path` in `scripts/lib.sh`.
