#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [ $# -lt 1 ]; then
  die "Usage: chosko-llm add <feature>"
fi

spec="$1"
mapfile -t resolved < <(resolve_feature "$spec")
kind="${resolved[0]}"
name="${resolved[1]}"

case "$kind" in
  command)
    src="$(src_command_path "$name")"
    dst="$(inst_command_path "$name")"
    require_versioned_source "$src"
    if [ -e "$dst" ]; then
      die "Command '$name' is already installed at $dst. Use 'chosko-llm update $name' to refresh."
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    version="$(read_frontmatter_field "$src" version)"
    log_info "Installed command '$name' v$version -> $dst"
    ;;
  skill)
    src_dir="$(src_skill_dir "$name")"
    src_skill="$(src_skill_path "$name")"
    dst_dir="$(inst_skill_dir "$name")"
    require_versioned_source "$src_skill"
    if [ -e "$dst_dir" ]; then
      die "Skill '$name' is already installed at $dst_dir. Use 'chosko-llm update $name' to refresh."
    fi
    mkdir -p "$(dirname "$dst_dir")"
    cp -R "$src_dir" "$dst_dir"
    version="$(read_frontmatter_field "$src_skill" version)"
    log_info "Installed skill '$name' v$version -> $dst_dir"
    ;;
  claude-md)
    src="$(src_claudemd_path "$name")"
    require_versioned_source "$src"
    if claudemd_is_installed "$name"; then
      die "claude-md '$name' is already installed. Use 'chosko-llm update claude-md:$name' to refresh."
    fi
    version="$(read_frontmatter_field "$src" version)"
    inject_section "$name" "$version" "$src"
    log_info "Installed claude-md '$name' v$version -> $CLAUDE_HOME/CLAUDE.md"
    ;;
esac
