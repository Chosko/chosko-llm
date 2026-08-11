#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_scope "$@"
set -- ${SCOPE_ARGS[@]+"${SCOPE_ARGS[@]}"}

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<EOF
Usage: chosko-llm add <feature> [<feature> ...] [--local | --global] | --all [--local | --global]

  <feature>     Install a feature: <name>, command:<name>, skill:<name>,
                claude-md:<name>, statusline:<name>, or hook:<name>. Multiple
                names may be given in one call; each is installed
                independently and a failure on one (already installed,
                unknown name, wrong scope for the kind) does not stop the rest.
  --all         Install every feature not yet installed. Cannot be combined
                with explicit feature names.
  --local       Install into <cwd>/.claude instead of \$CLAUDE_HOME. Requires
                <cwd>/CLAUDE.md to exist. statusline is global-only: a
                single-feature statusline request fails; --all skips it.
  --global      Install into \$CLAUDE_HOME (default). hook is local-only, the
                mirror rule: a single-feature hook request fails; --all skips
                it.
EOF
    exit 0
  fi
  die "Usage: chosko-llm add <feature> [<feature> ...] | --all"
fi

for a in "$@"; do
  if [ "$a" = "--all" ] && [ $# -gt 1 ]; then
    die "--all cannot be combined with explicit feature names."
  fi
done

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
      log_success "Installed command '$base' v$version -> $dst (scope: $CHOSKO_LLM_SCOPE)"
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
      log_success "Installed skill '$base' v$version -> $dst_dir (scope: $CHOSKO_LLM_SCOPE)"
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
      log_success "Installed claude-md '$base' v$version -> $(claudemd_target_path) (scope: $CHOSKO_LLM_SCOPE)"
      any=1
    done
  fi
  if scope_is_local; then
    log_info "Skipping statusline features — global-only, not supported with --local."
  elif [ -d "$CHOSKO_LLM_HOME/statusline" ]; then
    for f in "$CHOSKO_LLM_HOME"/statusline/*.sh; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .sh)"
      dst="$(inst_statusline_path "$base")"
      if [ -e "$dst" ]; then
        log_info "Already installed: statusline '$base' — skipping"
        continue
      fi
      version="$(read_frontmatter_field "$f" version || true)"
      if [ -z "$version" ]; then
        log_warn "Skipping statusline '$base': missing version in frontmatter"
        continue
      fi
      mkdir -p "$(dirname "$dst")"
      cp "$f" "$dst"
      chmod +x "$dst"
      log_success "Installed statusline '$base' v$version -> $dst (scope: $CHOSKO_LLM_SCOPE)"
      print_statusline_prompt "$base" "$dst"
      any=1
    done
  fi
  if ! scope_is_local; then
    log_info "Skipping hook features — local-only, not supported with --global."
  elif [ -d "$CHOSKO_LLM_HOME/hooks" ]; then
    for f in "$CHOSKO_LLM_HOME"/hooks/*.sh; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .sh)"
      dst="$(inst_hook_path "$base")"
      if [ -e "$dst" ]; then
        log_info "Already installed: hook '$base' — skipping"
        continue
      fi
      version="$(read_frontmatter_field "$f" version || true)"
      if [ -z "$version" ]; then
        log_warn "Skipping hook '$base': missing version in frontmatter"
        continue
      fi
      if [ -z "$(read_frontmatter_field "$f" event || true)" ]; then
        log_warn "Skipping hook '$base': missing event in frontmatter"
        continue
      fi
      mkdir -p "$(dirname "$dst")"
      cp "$f" "$dst"
      chmod +x "$dst"
      log_success "Installed hook '$base' v$version -> $dst (scope: $CHOSKO_LLM_SCOPE)"
      print_hook_prompt "$base" "$f"
      any=1
    done
  fi
  [ $any -eq 1 ] || log_info "Nothing to install — all features already installed."
  exit 0
fi

# add_one <spec>
# Installs a single feature spec. Runs in a subshell so an internal `die`
# (unknown/ambiguous spec, already installed, missing version) only aborts
# this one name — the caller's loop keeps going. die() already logs via
# log_error before exiting, so no extra message is needed here.
add_one() {
  local spec="$1"
  (
    mapfile -t resolved < <(resolve_feature "$spec")
    kind="${resolved[0]:-}"
    name="${resolved[1]:-}"
    [ -n "$kind" ] && [ -n "$name" ] || exit 1

    if ! scope_supports_kind "$kind"; then
      die "$(scope_violation_message "$kind")"
    fi

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
        log_success "Installed command '$name' v$version -> $dst (scope: $CHOSKO_LLM_SCOPE)"
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
        log_success "Installed skill '$name' v$version -> $dst_dir (scope: $CHOSKO_LLM_SCOPE)"
        ;;
      claude-md)
        src="$(src_claudemd_path "$name")"
        require_versioned_source "$src"
        if claudemd_is_installed "$name"; then
          die "claude-md '$name' is already installed. Use 'chosko-llm update claude-md:$name' to refresh."
        fi
        version="$(read_frontmatter_field "$src" version)"
        inject_section "$name" "$version" "$src"
        log_success "Installed claude-md '$name' v$version -> $(claudemd_target_path) (scope: $CHOSKO_LLM_SCOPE)"
        ;;
      statusline)
        src="$(src_statusline_path "$name")"
        dst="$(inst_statusline_path "$name")"
        require_versioned_source "$src"
        if [ -e "$dst" ]; then
          die "statusline '$name' is already installed at $dst. Use 'chosko-llm update $name' to refresh."
        fi
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        chmod +x "$dst"
        version="$(read_frontmatter_field "$src" version)"
        log_success "Installed statusline '$name' v$version -> $dst (scope: $CHOSKO_LLM_SCOPE)"
        print_statusline_prompt "$name" "$dst"
        ;;
      hook)
        src="$(src_hook_path "$name")"
        dst="$(inst_hook_path "$name")"
        require_versioned_source "$src"
        require_hook_source "$src"
        if [ -e "$dst" ]; then
          die "hook '$name' is already installed at $dst. Use 'chosko-llm update $name --local' to refresh."
        fi
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        chmod +x "$dst"
        version="$(read_frontmatter_field "$src" version)"
        log_success "Installed hook '$name' v$version -> $dst (scope: $CHOSKO_LLM_SCOPE)"
        print_hook_prompt "$name" "$src"
        ;;
    esac

    apply_replaces "$kind" "$name"
  )
}

failed=0
for spec in "$@"; do
  add_one "$spec" || failed=1
done
exit $failed
