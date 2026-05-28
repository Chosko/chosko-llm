#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<EOF
Usage:
  chosko-llm update <feature>     Re-copy a feature from the managed clone (installs if missing).
  chosko-llm update --all         Update every currently installed feature.
EOF
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

# Update a single feature given (kind, name). kind is command|skill.
update_one() {
  local kind="$1" name="$2"
  case "$kind" in
    command)
      local src dst
      src="$(src_command_path "$name")"
      dst="$(inst_command_path "$name")"
      [ -f "$src" ] || die "No source for command '$name' at $src"
      require_versioned_source "$src"
      mkdir -p "$(dirname "$dst")"
      [ -f "$dst" ] && rm -f "$dst"
      cp "$src" "$dst"
      log_info "Updated command '$name' -> v$(read_frontmatter_field "$src" version)"
      ;;
    skill)
      local src_dir src_skill dst_dir
      src_dir="$(src_skill_dir "$name")"
      src_skill="$(src_skill_path "$name")"
      dst_dir="$(inst_skill_dir "$name")"
      [ -f "$src_skill" ] || die "No source for skill '$name' at $src_skill"
      require_versioned_source "$src_skill"
      mkdir -p "$(dirname "$dst_dir")"
      [ -d "$dst_dir" ] && rm -rf "$dst_dir"
      cp -R "$src_dir" "$dst_dir"
      log_info "Updated skill '$name' -> v$(read_frontmatter_field "$src_skill" version)"
      ;;
    claude-md)
      local src
      src="$(src_claudemd_path "$name")"
      [ -f "$src" ] || die "No source for claude-md '$name' at $src"
      require_versioned_source "$src"
      local version
      version="$(read_frontmatter_field "$src" version)"
      inject_section "$name" "$version" "$src"
      log_info "Updated claude-md '$name' -> v$version"
      ;;
    *) die "Unknown kind: $kind" ;;
  esac
}

# version_cmp <a> <b>
# Prints -1, 0, or 1 — the ordering of semver strings a vs b.
# Returns non-zero exit code if either string is empty or non-semver.
version_cmp() {
  local a="$1" b="$2"
  [ -n "$a" ] && [ -n "$b" ] || return 1
  awk -v a="$a" -v b="$b" 'BEGIN {
    n = split(a, av, "."); m = split(b, bv, ".")
    if (n != 3 || m != 3) exit 2
    for (i = 1; i <= 3; i++) {
      if (av[i]+0 > bv[i]+0) { print  1; exit 0 }
      if (av[i]+0 < bv[i]+0) { print -1; exit 0 }
    }
    print 0; exit 0
  }'
}

if [ "$1" = "--all" ]; then
  any=0
  if [ -d "$CLAUDE_HOME/commands" ]; then
    for f in "$CLAUDE_HOME"/commands/*.md; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .md)"
      # Only update if a source exists in the managed clone.
      if [ -f "$(src_command_path "$base")" ]; then
        inst_ver="$(read_frontmatter_field "$f" version || true)"
        src_ver="$(read_frontmatter_field "$(src_command_path "$base")" version || true)"
        cmp="$(version_cmp "$inst_ver" "$src_ver" 2>/dev/null || echo "?")"
        case "$cmp" in
          0)  log_info "Already up-to-date: command '$base' (v$inst_ver)"; continue ;;
          1)  log_info "Local version ahead: command '$base' (local v$inst_ver, latest v$src_ver) — skipping"; continue ;;
          -1) ;; # fall through to update_one
          *)  log_warn "Skipping command '$base': version unreadable — update manually"; continue ;;
        esac
        update_one command "$base"
        any=1
      else
        log_warn "Skipping command '$base': no source in managed clone."
      fi
    done
  fi
  if [ -d "$CLAUDE_HOME/skills" ]; then
    for d in "$CLAUDE_HOME"/skills/*/; do
      [ -e "$d" ] || continue
      base="$(basename "$d")"
      if [ -f "$(src_skill_path "$base")" ]; then
        inst_skill="$(inst_skill_path "$base")"
        src_skill="$(src_skill_path "$base")"
        inst_ver="$(read_frontmatter_field "$inst_skill" version || true)"
        src_ver="$(read_frontmatter_field "$src_skill" version || true)"
        cmp="$(version_cmp "$inst_ver" "$src_ver" 2>/dev/null || echo "?")"
        case "$cmp" in
          0)  log_info "Already up-to-date: skill '$base' (v$inst_ver)"; continue ;;
          1)  log_info "Local version ahead: skill '$base' (local v$inst_ver, latest v$src_ver) — skipping"; continue ;;
          -1) ;; # fall through to update_one
          *)  log_warn "Skipping skill '$base': version unreadable — update manually"; continue ;;
        esac
        update_one skill "$base"
        any=1
      else
        log_warn "Skipping skill '$base': no source in managed clone."
      fi
    done
  fi
  if [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
    while IFS= read -r line; do
      local name inst_ver src_ver cmp
      name="$(printf '%s' "$line" | sed 's/<!-- chosko-llm:\([^:]*\):begin.*/\1/')"
      inst_ver="$(printf '%s' "$line" | sed 's/.*:begin v\([^ ]*\) -->.*/\1/')"
      [ -n "$name" ] || continue
      if [ -f "$(src_claudemd_path "$name")" ]; then
        src_ver="$(read_frontmatter_field "$(src_claudemd_path "$name")" version || true)"
        cmp="$(version_cmp "$inst_ver" "$src_ver" 2>/dev/null || echo "?")"
        case "$cmp" in
          0)  log_info "Already up-to-date: claude-md '$name' (v$inst_ver)"; continue ;;
          1)  log_info "Local version ahead: claude-md '$name' (local v$inst_ver, latest v$src_ver) — skipping"; continue ;;
          -1) ;; # fall through to update_one
          *)  log_warn "Skipping claude-md '$name': version unreadable — update manually"; continue ;;
        esac
        update_one claude-md "$name"
        any=1
      else
        log_warn "Skipping claude-md '$name': no source in managed clone."
      fi
    done < <(grep '<!-- chosko-llm:.*:begin' "$CLAUDE_HOME/CLAUDE.md" 2>/dev/null || true)
  fi
  [ $any -eq 1 ] || log_info "Nothing to update."
  exit 0
fi

# Single feature path. Resolve against managed clone — `update` installs if
# missing, per spec.
spec="$1"
mapfile -t resolved < <(resolve_feature "$spec")
update_one "${resolved[0]}" "${resolved[1]}"
