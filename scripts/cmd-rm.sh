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
  command:*) prefix=command; name="${spec#command:}" ;;
  skill:*)   prefix=skill;   name="${spec#skill:}"   ;;
esac

# For rm we look at what's actually installed, not the source.
resolve_installed() {
  if [ -n "$prefix" ]; then
    echo "$prefix"; return
  fi
  local k
  k="$(installed_kind "$name")"
  case "$k" in
    command|skill) echo "$k" ;;
    both) die "Both a command and a skill named '$name' are installed. Disambiguate with 'command:$name' or 'skill:$name'." ;;
    none) die "No feature named '$name' is installed under $CLAUDE_HOME." ;;
  esac
}

kind="$(resolve_installed)"

case "$kind" in
  command)
    target="$(inst_command_path "$name")"
    [ -f "$target" ] || die "Command '$name' is not installed."
    rm -f "$target"
    log_info "Removed command '$name' ($target)"
    ;;
  skill)
    target="$(inst_skill_dir "$name")"
    [ -d "$target" ] || die "Skill '$name' is not installed."
    rm -rf "$target"
    log_info "Removed skill '$name' ($target)"
    ;;
esac
