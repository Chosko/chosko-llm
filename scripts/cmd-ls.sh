#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

filter="all"
case "${1:-}" in
  ""|--all)    filter="all" ;;
  --installed) filter="installed" ;;
  --available) filter="available" ;;
  -h|--help)
    cat <<EOF
Usage: chosko-llm ls [--installed | --available]

  (no flag)     List all known features with installed and latest versions.
  --installed   Show only features that are currently installed.
  --available   Show only features that exist in the managed clone.
EOF
    exit 0
    ;;
  *) die "Unknown flag for ls: $1" ;;
esac

print_header() {
  printf '%-30s %-8s %-14s %-16s %s\n' "NAME" "KIND" "INSTALLED" "LATEST" "STATUS"
}

# collect_names <kind>
# Emits a sorted, deduplicated list of feature names visible in either home.
collect_names() {
  local kind="$1"
  case "$kind" in
    command)
      for dir in "$CHOSKO_LLM_HOME/commands" "$CLAUDE_HOME/commands"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.md; do
          [ -e "$f" ] || continue
          basename "$f" .md
        done
      done | sort -u
      ;;
    skill)
      for dir in "$CHOSKO_LLM_HOME/skills" "$CLAUDE_HOME/skills"; do
        [ -d "$dir" ] || continue
        for d in "$dir"/*/; do
          [ -e "$d" ] || continue
          basename "$d"
        done
      done | sort -u
      ;;
    claude-md)
      {
        if [ -d "$CHOSKO_LLM_HOME/claude-md" ]; then
          for f in "$CHOSKO_LLM_HOME"/claude-md/*.md; do
            [ -e "$f" ] || continue
            basename "$f" .md
          done
        fi
        if [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
          grep '<!-- chosko-llm:.*:begin' "$CLAUDE_HOME/CLAUDE.md" 2>/dev/null \
            | sed 's/<!-- chosko-llm:\([^:]*\):begin.*/\1/' || true
        fi
      } | sort -u
      ;;
  esac
}

list_all() {
  local filter="$1"
  print_header
  local found=0
  local installable=() updatable=()

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    local inst_file src_file inst_ver src_ver inst_col latest_col
    inst_file="$(inst_command_path "$name")"
    src_file="$(src_command_path "$name")"

    if [ -f "$inst_file" ]; then
      inst_ver="$(read_frontmatter_field "$inst_file" version || true)"
      inst_col="${inst_ver:-unversioned}"
    else
      inst_col="—"
    fi

    if [ -f "$src_file" ]; then
      src_ver="$(read_frontmatter_field "$src_file" version || true)"
      [ -n "$src_ver" ] && latest_col="$src_ver" || latest_col="—"
    else
      latest_col="—"
    fi

    case "$filter" in
      installed) [ "$inst_col" = "—" ] && continue ;;
      available) [ "$latest_col" = "—" ] && continue ;;
    esac

    local status_col
    if [ "$inst_col" = "—" ]; then
      status_col="not installed"
    elif [ "$latest_col" = "—" ]; then
      status_col="local only"
    elif [ "$inst_col" = "$latest_col" ]; then
      status_col="up-to-date"
    else
      status_col="updatable"
    fi

    case "$status_col" in
      "not installed") installable+=("$name") ;;
      "updatable")     updatable+=("$name") ;;
    esac

    printf '%-30s %-8s %-14s %-16s %s\n' "$name" "command" "$inst_col" "$latest_col" "$status_col"
    found=1
  done < <(collect_names command)

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    local inst_file src_file inst_ver src_ver inst_col latest_col
    inst_file="$(inst_skill_path "$name")"
    src_file="$(src_skill_path "$name")"

    if [ -f "$inst_file" ]; then
      inst_ver="$(read_frontmatter_field "$inst_file" version || true)"
      inst_col="${inst_ver:-unversioned}"
    else
      inst_col="—"
    fi

    if [ -f "$src_file" ]; then
      src_ver="$(read_frontmatter_field "$src_file" version || true)"
      [ -n "$src_ver" ] && latest_col="$src_ver" || latest_col="—"
    else
      latest_col="—"
    fi

    case "$filter" in
      installed) [ "$inst_col" = "—" ] && continue ;;
      available) [ "$latest_col" = "—" ] && continue ;;
    esac

    local status_col
    if [ "$inst_col" = "—" ]; then
      status_col="not installed"
    elif [ "$latest_col" = "—" ]; then
      status_col="local only"
    elif [ "$inst_col" = "$latest_col" ]; then
      status_col="up-to-date"
    else
      status_col="updatable"
    fi

    case "$status_col" in
      "not installed") installable+=("$name") ;;
      "updatable")     updatable+=("$name") ;;
    esac

    printf '%-30s %-8s %-14s %-16s %s\n' "$name" "skill" "$inst_col" "$latest_col" "$status_col"
    found=1
  done < <(collect_names skill)

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    local src_file inst_ver src_ver inst_col latest_col
    src_file="$(src_claudemd_path "$name")"

    if [ -f "$CLAUDE_HOME/CLAUDE.md" ] && grep -qF "<!-- chosko-llm:${name}:begin" "$CLAUDE_HOME/CLAUDE.md" 2>/dev/null; then
      inst_ver="$(claudemd_installed_version "$name" || true)"
      inst_col="${inst_ver:-unversioned}"
    else
      inst_col="—"
    fi

    if [ -f "$src_file" ]; then
      src_ver="$(read_frontmatter_field "$src_file" version || true)"
      [ -n "$src_ver" ] && latest_col="$src_ver" || latest_col="—"
    else
      latest_col="—"
    fi

    case "$filter" in
      installed) [ "$inst_col" = "—" ] && continue ;;
      available) [ "$latest_col" = "—" ] && continue ;;
    esac

    local status_col
    if [ "$inst_col" = "—" ]; then
      status_col="not installed"
    elif [ "$latest_col" = "—" ]; then
      status_col="local only"
    elif [ "$inst_col" = "$latest_col" ]; then
      status_col="up-to-date"
    else
      status_col="updatable"
    fi

    case "$status_col" in
      "not installed") installable+=("$name") ;;
      "updatable")     updatable+=("$name") ;;
    esac

    printf '%-30s %-8s %-14s %-16s %s\n' "$name" "claude-md" "$inst_col" "$latest_col" "$status_col"
    found=1
  done < <(collect_names claude-md)

  [ $found -eq 1 ] || log_info "No features found."

  # Actionable suggestions, gated to an interactive stdout so piped/redirected
  # output stays a clean table. Counts reflect the filtered, displayed rows.
  if [ "$found" -eq 1 ] && [ -t 1 ]; then
    local n_inst="${#installable[@]}" n_upd="${#updatable[@]}"
    printf '\n'
    local suggested=0
    if [ "$n_inst" -eq 1 ]; then
      printf "Run 'chosko-llm add %s' to install it.\n" "${installable[0]}"; suggested=1
    elif [ "$n_inst" -ge 2 ]; then
      printf "Run 'chosko-llm add <feature>' to install one, or 'chosko-llm add --all' to install all %d.\n" "$n_inst"; suggested=1
    fi
    if [ "$n_upd" -eq 1 ]; then
      printf "Run 'chosko-llm update %s' to update it.\n" "${updatable[0]}"; suggested=1
    elif [ "$n_upd" -ge 2 ]; then
      printf "Run 'chosko-llm update --all' to update all %d updatable features.\n" "$n_upd"; suggested=1
    fi
    [ "$suggested" -eq 1 ] || printf 'Everything is up to date.\n'
  fi
}

list_all "$filter"
