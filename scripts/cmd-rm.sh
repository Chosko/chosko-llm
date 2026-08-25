#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_scope "$@"
set -- ${SCOPE_ARGS[@]+"${SCOPE_ARGS[@]}"}

# --force is stripped the same way resolve_scope strips --local / --global, so
# it may appear anywhere in the argument list and never reaches the spec.
force=0
rm_args=()
for a in "$@"; do
  if [ "$a" = "--force" ]; then force=1; else rm_args+=("$a"); fi
done
set -- ${rm_args[@]+"${rm_args[@]}"}

case "${1:-}" in
  -h|--help)
    cat <<EOF
Usage: chosko-llm rm <feature> [--force] [--local | --global]

  <feature>     Remove an installed feature: <name>, command:<name>,
                skill:<name>, claude-md:<name>, statusline:<name>, or
                hook:<name>.
  --force       Remove it even when an installed feature declares it in
                'requires:'. Without this, such a removal is refused and the
                dependents are named; with it, they are named as a warning and
                the removal proceeds.
  --local       Remove from <cwd>/.claude instead of \$CLAUDE_HOME. Requires
                <cwd>/CLAUDE.md to exist. statusline is global-only and
                fails with --local.
  --global      Remove from \$CLAUDE_HOME (default). hook is local-only and
                fails with --global.
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
  hook:*)       prefix=hook;       name="${spec#hook:}"       ;;
esac

# For rm we look at what's actually installed, not the source.
resolve_installed() {
  if [ -n "$prefix" ]; then
    echo "$prefix"; return
  fi
  local has_cmd=0 has_skill=0 has_cm=0 has_sl=0 has_hook=0
  [ -f "$(inst_command_path "$name")" ] && has_cmd=1
  [ -f "$(inst_skill_path   "$name")" ] && has_skill=1
  claudemd_is_installed "$name" && has_cm=1 || true
  [ -f "$(inst_statusline_path "$name")" ] && has_sl=1
  [ -f "$(inst_hook_path "$name")" ] && has_hook=1
  local total=$(( has_cmd + has_skill + has_cm + has_sl + has_hook ))
  if   [ $total -gt 1 ];    then die "Multiple installed features named '$name'. Disambiguate with 'command:$name', 'skill:$name', 'claude-md:$name', 'statusline:$name', or 'hook:$name'."
  elif [ $has_cmd -eq 1 ];  then echo command
  elif [ $has_skill -eq 1 ]; then echo skill
  elif [ $has_cm -eq 1 ];   then echo claude-md
  elif [ $has_sl -eq 1 ];   then echo statusline
  elif [ $has_hook -eq 1 ]; then echo hook
  else die "No feature named '$name' is installed under $CLAUDE_HOME."
  fi
}

kind="$(resolve_installed)"

if ! scope_supports_kind "$kind"; then
  die "$(scope_violation_message "$kind")"
fi

# ---------- dependents guard ----------
# Removing a feature that another installed feature reads a file out of leaves
# the survivor following a dangling path mid-run. Scan the installed set for
# anything declaring this one in `requires:` before deleting it.
#
# The scan reads INSTALLED frontmatter for command, skill, statusline and hook,
# but the MANAGED-CLONE source for claude-md. That asymmetry is not an
# oversight: `inject_section` strips frontmatter, so an installed claude-md
# section carries no `requires:` to read at all — the clone's copy of the same
# name is the only place the declaration survives.
want="$kind:$name"
dependents=""

record_if_dependent() {
  local file="$1" dep_spec="$2" specs
  [ -f "$file" ] || return 0
  # A feature naming itself is not its own dependent — it would otherwise block
  # its own removal forever.
  [ "$dep_spec" != "$want" ] || return 0
  # requires_specs `die`s on a malformed entry; the command substitution keeps
  # that exit status visible, and `exit 1` aborts rm rather than deleting on a
  # declaration nobody could read.
  specs="$(requires_specs "$file")" || exit 1
  printf '%s\n' "$specs" | grep -qxF -- "$want" || return 0
  dependents="$dependents $dep_spec"
}

for f in "$CLAUDE_HOME"/commands/*.md; do
  record_if_dependent "$f" "command:$(basename "$f" .md)"
done
for f in "$CLAUDE_HOME"/skills/*/SKILL.md; do
  record_if_dependent "$f" "skill:$(basename "$(dirname "$f")")"
done
for f in "$CLAUDE_HOME"/statusline/*.sh; do
  record_if_dependent "$f" "statusline:$(basename "$f" .sh)"
done
for f in "$CLAUDE_HOME"/hooks/*.sh; do
  record_if_dependent "$f" "hook:$(basename "$f" .sh)"
done
for f in "$CHOSKO_LLM_HOME"/claude-md/*.md; do
  [ -f "$f" ] || continue
  cm_name="$(basename "$f" .md)"
  claudemd_is_installed "$cm_name" || continue
  record_if_dependent "$f" "claude-md:$cm_name"
done

if [ -n "$dependents" ]; then
  if [ $force -eq 0 ]; then
    die "Cannot remove $kind '$name': still required by$dependents. Pass --force to remove it anyway."
  fi
  log_warn "Removing $kind '$name' with --force — these installed features declare it in 'requires:' and will break:$dependents"
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
  hook)
    target="$(inst_hook_path "$name")"
    [ -f "$target" ] || die "hook '$name' is not installed."
    rm -f "$target"
    log_success "Removed hook '$name' ($target) (scope: $CHOSKO_LLM_SCOPE)"
    log_warn "Remove this hook's entry from $(hook_settings_path) too — a wired hook pointing at a deleted script fails on every session."
    ;;
esac
