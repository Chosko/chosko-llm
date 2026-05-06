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
    *) die "Unknown kind: $kind" ;;
  esac
}

if [ "$1" = "--all" ]; then
  any=0
  if [ -d "$CLAUDE_HOME/commands" ]; then
    for f in "$CLAUDE_HOME"/commands/*.md; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .md)"
      # Only update if a source exists in the managed clone.
      if [ -f "$(src_command_path "$base")" ]; then
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
        update_one skill "$base"
        any=1
      else
        log_warn "Skipping skill '$base': no source in managed clone."
      fi
    done
  fi
  [ $any -eq 1 ] || log_info "Nothing to update."
  exit 0
fi

# Single feature path. Resolve against managed clone — `update` installs if
# missing, per spec.
spec="$1"
mapfile -t resolved < <(resolve_feature "$spec")
update_one "${resolved[0]}" "${resolved[1]}"
