#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [ $# -lt 1 ]; then
  die "Usage: chosko-llm add <feature> | --all"
fi

if [ "$1" = "--all" ]; then
  any=0
  if [ -d "$CHOSKO_LLM_HOME/commands" ]; then
    for f in "$CHOSKO_LLM_HOME"/commands/*.md; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .md)"
      dst="$(inst_command_path "$base")"
      if [ -e "$dst" ]; then
        log_info "Already installed: command '$base' — skipping"
        continue
      fi
      version="$(read_frontmatter_field "$f" version || true)"
      if [ -z "$version" ]; then
        log_warn "Skipping command '$base': missing version in frontmatter"
        continue
      fi
      mkdir -p "$(dirname "$dst")"
      cp "$f" "$dst"
      log_success "Installed command '$base' v$version -> $dst"
      any=1
    done
  fi
  if [ -d "$CHOSKO_LLM_HOME/skills" ]; then
    for d in "$CHOSKO_LLM_HOME"/skills/*/; do
      [ -e "$d" ] || continue
      base="$(basename "$d")"
      src_skill="$(src_skill_path "$base")"
      dst_dir="$(inst_skill_dir "$base")"
      if [ -e "$dst_dir" ]; then
        log_info "Already installed: skill '$base' — skipping"
        continue
      fi
      if [ ! -f "$src_skill" ]; then
        log_warn "Skipping skill '$base': no SKILL.md found"
        continue
      fi
      version="$(read_frontmatter_field "$src_skill" version || true)"
      if [ -z "$version" ]; then
        log_warn "Skipping skill '$base': missing version in frontmatter"
        continue
      fi
      mkdir -p "$(dirname "$dst_dir")"
      cp -R "$d" "$dst_dir"
      log_success "Installed skill '$base' v$version -> $dst_dir"
      any=1
    done
  fi
  if [ -d "$CHOSKO_LLM_HOME/claude-md" ]; then
    for f in "$CHOSKO_LLM_HOME"/claude-md/*.md; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .md)"
      if claudemd_is_installed "$base"; then
        log_info "Already installed: claude-md '$base' — skipping"
        continue
      fi
      version="$(read_frontmatter_field "$f" version || true)"
      if [ -z "$version" ]; then
        log_warn "Skipping claude-md '$base': missing version in frontmatter"
        continue
      fi
      inject_section "$base" "$version" "$f"
      log_success "Installed claude-md '$base' v$version -> $CLAUDE_HOME/CLAUDE.md"
      any=1
    done
  fi
  [ $any -eq 1 ] || log_info "Nothing to install — all features already installed."
  exit 0
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
    log_success "Installed command '$name' v$version -> $dst"
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
    log_success "Installed skill '$name' v$version -> $dst_dir"
    ;;
  claude-md)
    src="$(src_claudemd_path "$name")"
    require_versioned_source "$src"
    if claudemd_is_installed "$name"; then
      die "claude-md '$name' is already installed. Use 'chosko-llm update claude-md:$name' to refresh."
    fi
    version="$(read_frontmatter_field "$src" version)"
    inject_section "$name" "$version" "$src"
    log_success "Installed claude-md '$name' v$version -> $CLAUDE_HOME/CLAUDE.md"
    ;;
esac
