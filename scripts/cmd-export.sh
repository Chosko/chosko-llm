#!/usr/bin/env bash
# Package a repo's Claude config (CLAUDE.md, AGENTS.md, README.md, and the
# curated subset of .claude/) into a single hand-off artifact: a concatenated
# Markdown file by default, or a zip with --archive. Both shapes draw from
# select_export_files so they can never disagree about what gets included.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

archive=false
repo=""
for arg in "$@"; do
  case "$arg" in
    --archive) archive=true ;;
    *)
      [ -z "$repo" ] || die "Unexpected argument: $arg"
      repo="$arg"
      ;;
  esac
done
repo="${repo:-$PWD}"
[ -d "$repo" ] || die "No such directory: $repo"
repo="$(cd "$repo" && pwd)"
repo_name="$(basename "$repo")"

# select_export_files <repo_dir>
# Emits repo-relative paths on stdout. The only place selection rules live.
select_export_files() {
  local repo_dir="$1" f
  for f in CLAUDE.md AGENTS.md README.md; do
    [ -f "$repo_dir/$f" ] && printf '%s\n' "$f"
  done
  if [ -d "$repo_dir/.claude" ]; then
    ( cd "$repo_dir" && find .claude \
        \( -path '.claude/projects' -o -path '.claude/history' -o -path '.claude/todos' -o -path '.claude/tasks' \) -prune -o \
        -type f \( -name '*.md' -o -name '*.json' -o -name '*.toml' \) ! -name 'settings.local.json' ! -path '.claude/TASKS.md' -print \
      | sort )
  fi
  return 0
}

files="$(select_export_files "$repo")"
[ -n "$files" ] || die "Nothing to export — no CLAUDE.md, AGENTS.md, README.md, or .claude/*.{md,json,toml} found in $repo."

# VCS detection: git / Plastic SCM / neither — same three-way check
# /project-setup PHASE 1a uses. Drives both Commit: and Created:.
created=""
if command -v git >/dev/null 2>&1 && git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
  sha="$(git -C "$repo" rev-parse --short HEAD)"
  [ -n "$(git -C "$repo" status --porcelain)" ] && sha="${sha}-dirty"
  earliest_ts="$(git -C "$repo" log --reverse --format=%ct | head -1)"
  [ -n "$earliest_ts" ] && created="$(date -u -d "@$earliest_ts" '+%Y-%m-%d')"
elif [ -d "$repo/.plastic" ] || { command -v cm >/dev/null 2>&1 && (cd "$repo" && cm status >/dev/null 2>&1); }; then
  sha="$(cd "$repo" && cm log --limit=1 --format='{changesetid}' 2>/dev/null || true)"
  [ -n "$sha" ] || sha="unknown changeset"
  earliest_date="$(cd "$repo" && cm find revision "where date <= 'now'" --order-ascending --format="{date}" --limit=1 2>/dev/null || true)"
  [ -n "$earliest_date" ] && created="${earliest_date:0:10}"
else
  log_warn "$repo is not a git repository (or git is unavailable) — no commit SHA to record."
  if [ ! -t 0 ]; then
    die "Cannot prompt to continue: stdin is not a TTY. Re-run interactively, or from a git repository."
  fi
  printf 'Proceed without commit info? [y/N] ' >&2
  read -r reply
  case "$reply" in
    y|Y|yes|Yes) sha="not a git repository" ;;
    *) exit 0 ;;
  esac
fi

version=""
[ -f "$repo/VERSION" ] && version="$(tr -d '[:space:]' < "$repo/VERSION")"

generated="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

export_dir="$(export_dir_path)"
mkdir -p "$export_dir"

if [ "$archive" = true ]; then
  out="$export_dir/${repo_name}-claude-config.zip"
  stage="$(mktemp -d)"
  trap 'rm -rf "$stage"' EXIT

  stage_root="$stage/$repo_name"
  mkdir -p "$stage_root"
  while IFS= read -r f; do
    mkdir -p "$stage_root/$(dirname "$f")"
    cp "$repo/$f" "$stage_root/$f"
  done <<< "$files"

  {
    printf '# MANIFEST\n\n'
    printf 'Repo: %s\n' "$repo_name"
    [ -n "$version" ] && printf 'Version: %s\n' "$version"
    printf 'Commit: %s\n' "$sha"
    [ -n "$created" ] && printf 'Created: %s\n' "$created"
    printf 'Generated: %s\n' "$generated"
  } > "$stage/MANIFEST.md"

  rm -f "$out"
  if command -v zip >/dev/null 2>&1; then
    ( cd "$stage" && zip -rq "$out" . )
  elif command -v powershell.exe >/dev/null 2>&1; then
    win_stage="$stage" win_out="$out"
    if command -v cygpath >/dev/null 2>&1; then
      win_stage="$(cygpath -w "$stage")"
      win_out="$(cygpath -w "$out")"
    fi
    powershell.exe -NoProfile -Command "Compress-Archive -Path '$win_stage\\*' -DestinationPath '$win_out' -Force" \
      || die "Compress-Archive failed."
  else
    die "No zip tool available: need 'zip' or 'powershell.exe' (Compress-Archive) on PATH."
  fi
  log_success "Wrote $out"
else
  out="$export_dir/${repo_name}-claude-config.md"
  {
    printf '# Claude config export: %s\n\n' "$repo_name"
    printf 'Repo: %s\n' "$repo_name"
    [ -n "$version" ] && printf 'Version: %s\n' "$version"
    printf 'Commit: %s\n' "$sha"
    [ -n "$created" ] && printf 'Created: %s\n' "$created"
    printf 'Generated: %s\n\n' "$generated"
    printf '## Manifest\n\n'
    while IFS= read -r f; do
      printf -- '- %s\n' "$f"
    done <<< "$files"
    banner="$(printf '=%.0s' $(seq 1 41))"
    while IFS= read -r f; do
      printf '\n%s\nFILE: %s\n%s\n\n' "$banner" "$f" "$banner"
      cat "$repo/$f"
    done <<< "$files"
  } > "$out"
  log_success "Wrote $out"
fi

file_count=0
line_count=0
while IFS= read -r f; do
  file_count=$((file_count + 1))
  line_count=$((line_count + $(wc -l < "$repo/$f")))
done <<< "$files"
log_success "Exported $file_count file(s), $line_count line(s) total."

if [ -t 0 ]; then
  printf 'Open the export folder? [y/N] ' >&2
  read -r reply
  case "$reply" in
    y|Y|yes|Yes) open_in_file_manager "$export_dir" ;;
  esac
fi

printf '%s\n' "$out"
