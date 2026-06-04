#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

if [ $# -lt 1 ]; then
  die "Usage: chosko-llm rm <feature>"
fi

spec="$1"
prefix="" name="$spec"
case "$spec" in
  command:*)   prefix=command;   name="${spec#command:}"   ;;
  skill:*)     prefix=skill;     name="${spec#skill:}"     ;;
  claude-md:*) prefix=claude-md; name="${spec#claude-md:}" ;;
esac

# For rm we look at what's actually installed, not the source.
resolve_installed() {
  if [ -n "$prefix" ]; then
    echo "$prefix"; return
  fi
  local has_cmd=0 has_skill=0 has_cm=0
  [ -f "$(inst_command_path "$name")" ] && has_cmd=1
  [ -f "$(inst_skill_path   "$name")" ] && has_skill=1
  claudemd_is_installed "$name" && has_cm=1 || true
  local total=$(( has_cmd + has_skill + has_cm ))
  if   [ $total -gt 1 ];    then die "Multiple installed features named '$name'. Disambiguate with 'command:$name', 'skill:$name', or 'claude-md:$name'."
  elif [ $has_cmd -eq 1 ];  then echo command
  elif [ $has_skill -eq 1 ]; then echo skill
  elif [ $has_cm -eq 1 ];   then echo claude-md
  else die "No feature named '$name' is installed under $CLAUDE_HOME."
  fi
}

kind="$(resolve_installed)"

case "$kind" in
  command)
    target="$(inst_command_path "$name")"
    [ -f "$target" ] || die "Command '$name' is not installed."
    rm -f "$target"
    log_success "Removed command '$name' ($target)"
    ;;
  skill)
    target="$(inst_skill_dir "$name")"
    [ -d "$target" ] || die "Skill '$name' is not installed."
    rm -rf "$target"
    log_success "Removed skill '$name' ($target)"
    ;;
  claude-md)
    remove_section "$name"
    log_success "Removed claude-md '$name' from $CLAUDE_HOME/CLAUDE.md"
    ;;
esac
