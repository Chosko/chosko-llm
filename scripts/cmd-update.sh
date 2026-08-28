#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_scope "$@"
set -- ${SCOPE_ARGS[@]+"${SCOPE_ARGS[@]}"}

usage() {
  cat <<EOF
Usage:
  chosko-llm update <feature> [<feature> ...] [--local | --global]   Re-copy features from the
                                                                      managed clone (installs any
                                                                      that are missing).
  chosko-llm update --all [--local | --global]        Update every currently installed feature.

  <feature> Multiple names may be given in one call; each is updated independently and a
            failure on one (unknown name, wrong scope for the kind) does not stop the rest.
  --local   Operate on <cwd>/.claude instead of \$CLAUDE_HOME. Requires <cwd>/CLAUDE.md
            to exist. statusline is global-only: a single-feature statusline request
            fails; --all skips it.
  --global  Operate on \$CLAUDE_HOME (default). hook is local-only, the mirror rule:
            a single-feature hook request fails; --all skips it.
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

for a in "$@"; do
  if [ "$a" = "--all" ] && [ $# -gt 1 ]; then
    die "--all cannot be combined with explicit feature names."
  fi
done

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
      log_success "Updated command '$name' -> v$(read_frontmatter_field "$src" version) (scope: $CHOSKO_LLM_SCOPE)"
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
      log_success "Updated skill '$name' -> v$(read_frontmatter_field "$src_skill" version) (scope: $CHOSKO_LLM_SCOPE)"
      ;;
    claude-md)
      local src
      src="$(src_claudemd_path "$name")"
      [ -f "$src" ] || die "No source for claude-md '$name' at $src"
      require_versioned_source "$src"
      local version
      version="$(read_frontmatter_field "$src" version)"
      inject_section "$name" "$version" "$src"
      log_success "Updated claude-md '$name' -> v$version (scope: $CHOSKO_LLM_SCOPE)"
      ;;
    statusline)
      local src dst
      src="$(src_statusline_path "$name")"
      dst="$(inst_statusline_path "$name")"
      [ -f "$src" ] || die "No source for statusline '$name' at $src"
      require_versioned_source "$src"
      mkdir -p "$(dirname "$dst")"
      [ -f "$dst" ] && rm -f "$dst"
      cp "$src" "$dst"
      chmod +x "$dst"
      log_success "Updated statusline '$name' -> v$(read_frontmatter_field "$src" version) (scope: $CHOSKO_LLM_SCOPE)"
      ;;
    hook)
      local src dst
      src="$(src_hook_path "$name")"
      dst="$(inst_hook_path "$name")"
      [ -f "$src" ] || die "No source for hook '$name' at $src"
      require_versioned_source "$src"
      require_hook_source "$src"
      # Read the wiring the INSTALLED copy declares BEFORE overwriting it. That
      # copy is the only record of what was actually merged into settings.json,
      # which carries no version of its own.
      local was_installed=0 old_event="" old_matcher=""
      if [ -f "$dst" ]; then
        was_installed=1
        old_event="$(read_frontmatter_field "$dst" event || true)"
        old_matcher="$(read_frontmatter_field "$dst" matcher || true)"
      fi
      mkdir -p "$(dirname "$dst")"
      [ -f "$dst" ] && rm -f "$dst"
      cp "$src" "$dst"
      chmod +x "$dst"
      log_success "Updated hook '$name' -> v$(read_frontmatter_field "$src" version) (scope: $CHOSKO_LLM_SCOPE)"
      # Re-copying a script cannot re-wire settings.json. A body-only change
      # leaves the existing wiring valid and stays quiet; a changed event or
      # matcher invalidates it, and the stale entry would leave the hook firing
      # on the wrong tool or not at all — so name the old slot and re-prompt.
      if [ $was_installed -eq 0 ]; then
        print_hook_prompt "$name" "$src"
      else
        local new_event new_matcher
        new_event="$(read_frontmatter_field "$src" event || true)"
        new_matcher="$(read_frontmatter_field "$src" matcher || true)"
        if [ "$old_event" != "$new_event" ] || [ "$old_matcher" != "$new_matcher" ]; then
          log_warn "hook '$name' moved its wiring: $(hook_wiring_label "$old_event" "$old_matcher") -> $(hook_wiring_label "$new_event" "$new_matcher"). Remove the old entry from $(hook_settings_path), then apply the prompt below."
          print_hook_prompt "$name" "$src"
        fi
      fi
      ;;
    *) die "Unknown kind: $kind" ;;
  esac
}

# migrate_stale <installed-kind> <name>
# An installed artifact has no source in the managed clone. If some feature in
# the clone declares `replaces: <kind>:<name>`, install that replacement and let
# apply_replaces drop the stale artifact. Returns 0 when a migration happened,
# 1 when nothing in the clone claims this artifact.
migrate_stale() {
  local old_kind="$1" old_name="$2" found new_kind new_name
  found="$(find_replacement "$old_kind" "$old_name" || true)"
  [ -n "$found" ] || return 1
  new_kind="$(printf '%s\n' "$found" | sed -n 1p)"
  new_name="$(printf '%s\n' "$found" | sed -n 2p)"
  update_one "$new_kind" "$new_name"
  apply_replaces "$new_kind" "$new_name"
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
          1)  log_warn "Local version ahead: command '$base' (local v$inst_ver, latest v$src_ver) — skipping"; continue ;;
          -1) ;; # fall through to update_one
          *)  log_warn "Skipping command '$base': version unreadable — update manually"; continue ;;
        esac
        update_one command "$base"
        any=1
      elif migrate_stale command "$base"; then
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
          1)  log_warn "Local version ahead: skill '$base' (local v$inst_ver, latest v$src_ver) — skipping"; continue ;;
          -1) ;; # fall through to update_one
          *)  log_warn "Skipping skill '$base': version unreadable — update manually"; continue ;;
        esac
        update_one skill "$base"
        any=1
      elif migrate_stale skill "$base"; then
        any=1
      else
        log_warn "Skipping skill '$base': no source in managed clone."
      fi
    done
  fi
  claudemd_target="$(claudemd_target_path)"
  if [ -f "$claudemd_target" ]; then
    while IFS= read -r line; do
      name= inst_ver= src_ver= cmp=
      name="$(printf '%s' "$line" | sed 's/<!-- chosko-llm:\([^:]*\):begin.*/\1/')"
      inst_ver="$(printf '%s' "$line" | sed 's/.*:begin v\([^ ]*\) -->.*/\1/')"
      [ -n "$name" ] || continue
      if [ -f "$(src_claudemd_path "$name")" ]; then
        src_ver="$(read_frontmatter_field "$(src_claudemd_path "$name")" version || true)"
        cmp="$(version_cmp "$inst_ver" "$src_ver" 2>/dev/null || echo "?")"
        case "$cmp" in
          0)  log_info "Already up-to-date: claude-md '$name' (v$inst_ver)"; continue ;;
          1)  log_warn "Local version ahead: claude-md '$name' (local v$inst_ver, latest v$src_ver) — skipping"; continue ;;
          -1) ;; # fall through to update_one
          *)  log_warn "Skipping claude-md '$name': version unreadable — update manually"; continue ;;
        esac
        update_one claude-md "$name"
        any=1
      elif migrate_stale claude-md "$name"; then
        any=1
      else
        log_warn "Skipping claude-md '$name': no source in managed clone."
      fi
    done < <(grep '<!-- chosko-llm:.*:begin' "$claudemd_target" 2>/dev/null || true)
  fi
  if scope_is_local; then
    log_info "Skipping statusline features — global-only, not supported with --local."
  elif [ -d "$CLAUDE_HOME/statusline" ]; then
    for f in "$CLAUDE_HOME"/statusline/*.sh; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .sh)"
      if [ -f "$(src_statusline_path "$base")" ]; then
        inst_ver="$(read_frontmatter_field "$f" version || true)"
        src_ver="$(read_frontmatter_field "$(src_statusline_path "$base")" version || true)"
        cmp="$(version_cmp "$inst_ver" "$src_ver" 2>/dev/null || echo "?")"
        case "$cmp" in
          0)  log_info "Already up-to-date: statusline '$base' (v$inst_ver)"; continue ;;
          1)  log_warn "Local version ahead: statusline '$base' (local v$inst_ver, latest v$src_ver) — skipping"; continue ;;
          -1) ;; # fall through to update_one
          *)  log_warn "Skipping statusline '$base': version unreadable — update manually"; continue ;;
        esac
        update_one statusline "$base"
        any=1
      elif migrate_stale statusline "$base"; then
        any=1
      else
        log_warn "Skipping statusline '$base': no source in managed clone."
      fi
    done
  fi
  if ! scope_is_local; then
    log_info "Skipping hook features — local-only, not supported with --global."
  elif [ -d "$CLAUDE_HOME/hooks" ]; then
    for f in "$CLAUDE_HOME"/hooks/*.sh; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .sh)"
      if [ -f "$(src_hook_path "$base")" ]; then
        inst_ver="$(read_frontmatter_field "$f" version || true)"
        src_ver="$(read_frontmatter_field "$(src_hook_path "$base")" version || true)"
        cmp="$(version_cmp "$inst_ver" "$src_ver" 2>/dev/null || echo "?")"
        case "$cmp" in
          0)  log_info "Already up-to-date: hook '$base' (v$inst_ver)"; continue ;;
          1)  log_warn "Local version ahead: hook '$base' (local v$inst_ver, latest v$src_ver) — skipping" ; continue ;;
          -1) ;; # fall through to update_one
          *)  log_warn "Skipping hook '$base': version unreadable — update manually"; continue ;;
        esac
        update_one hook "$base"
        any=1
      elif migrate_stale hook "$base"; then
        any=1
      else
        log_warn "Skipping hook '$base': no source in managed clone."
      fi
    done
  fi
  [ $any -eq 1 ] || log_info "Nothing to update."
  exit 0
fi

# update_one_spec <spec>
# Resolves and updates a single feature spec against the managed clone —
# `update` installs if missing, per spec. Runs in a subshell so an internal
# `die` (unknown/ambiguous spec, statusline + --local) only aborts this one
# name — the caller's loop keeps going. die() already logs via log_error
# before exiting, so no extra message is needed here.
update_one_spec() {
  local spec="$1"
  (
    resolved=()
    while IFS= read -r line; do resolved+=("$line"); done < <(resolve_feature "$spec")
    kind="${resolved[0]:-}"
    name="${resolved[1]:-}"
    [ -n "$kind" ] && [ -n "$name" ] || exit 1

    if ! scope_supports_kind "$kind"; then
      die "$(scope_violation_message "$kind")"
    fi
    update_one "$kind" "$name"
    apply_replaces "$kind" "$name"
  )
}

failed=0
for spec in "$@"; do
  update_one_spec "$spec" || failed=1
done
exit $failed
