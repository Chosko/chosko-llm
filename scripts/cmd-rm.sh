#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_scope "$@"
set -- ${SCOPE_ARGS[@]+"${SCOPE_ARGS[@]}"}

case "${1:-}" in
  -h|--help)
    cat <<EOF
Usage: chosko-llm rm <feature> [--local | --global]

  <feature>     Remove an installed feature: <name>, command:<name>,
                skill:<name>, claude-md:<name>, or statusline:<name>.
  --local       Remove from <cwd>/.claude instead of \$CLAUDE_HOME. Requires
                <cwd>/CLAUDE.md to exist. statusline is global-only and
                fails with --local.
  --global      Remove from \$CLAUDE_HOME (default).
EOF
    exit 0
    ;;
esac

if [ $# -lt 1 ]; then
  die "Usage: chosko-llm rm <feature>"
fi

spec="$1"
prefix="" name="$spec"
case "$spec" in
  command:*)    prefix=command;    name="${spec#command:}"    ;;
  skill:*)      prefix=skill;      name="${spec#skill:}"      ;;
  claude-md:*)  prefix=claude-md;  name="${spec#claude-md:}"  ;;
  statusline:*) prefix=statusline; name="${spec#statusline:}" ;;
esac

# For rm we look at what's actually installed, not the source.
resolve_installed() {
  if [ -n "$prefix" ]; then
    echo "$prefix"; return
  fi
  local has_cmd=0 has_skill=0 has_cm=0 has_sl=0
  [ -f "$(inst_command_path "$name")" ] && has_cmd=1
  [ -f "$(inst_skill_path   "$name")" ] && has_skill=1
  claudemd_is_installed "$name" && has_cm=1 || true
  [ -f "$(inst_statusline_path "$name")" ] && has_sl=1
  local total=$(( has_cmd + has_skill + has_cm + has_sl ))
  if   [ $total -gt 1 ];    then die "Multiple installed features named '$name'. Disambiguate with 'command:$name', 'skill:$name', 'claude-md:$name', or 'statusline:$name'."
  elif [ $has_cmd -eq 1 ];  then echo command
  elif [ $has_skill -eq 1 ]; then echo skill
  elif [ $has_cm -eq 1 ];   then echo claude-md
  elif [ $has_sl -eq 1 ];   then echo statusline
  else die "No feature named '$name' is installed under $CLAUDE_HOME."
  fi
}

kind="$(resolve_installed)"

if ! scope_supports_kind "$kind"; then
  die "statusline scripts are global-only. Re-run without --local."
fi

case "$kind" in
  command)
    target="$(inst_command_path "$name")"
    [ -f "$target" ] || die "Command '$name' is not installed."
    rm -f "$target"
    log_success "Removed command '$name' ($target) (scope: $CHOSKO_LLM_SCOPE)"
    ;;
  skill)
    target="$(inst_skill_dir "$name")"
    [ -d "$target" ] || die "Skill '$name' is not installed."
    rm -rf "$target"
    log_success "Removed skill '$name' ($target) (scope: $CHOSKO_LLM_SCOPE)"
    ;;
  claude-md)
    remove_section "$name"
    log_success "Removed claude-md '$name' from $(claudemd_target_path) (scope: $CHOSKO_LLM_SCOPE)"
    ;;
  statusline)
    target="$(inst_statusline_path "$name")"
    [ -f "$target" ] || die "statusline '$name' is not installed."
    rm -f "$target"
    log_success "Removed statusline '$name' ($target) (scope: $CHOSKO_LLM_SCOPE)"
    log_warn "If $CLAUDE_HOME/settings.json's \"statusLine\" key still points at $target, update or remove it."
    ;;
esac
