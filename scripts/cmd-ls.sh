#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

resolve_scope "$@"
set -- ${SCOPE_ARGS[@]+"${SCOPE_ARGS[@]}"}

filter="all"
case "${1:-}" in
  ""|--all)    filter="all" ;;
  --installed) filter="installed" ;;
  --available) filter="available" ;;
  -h|--help)
    cat <<EOF
Usage: chosko-llm ls [--installed | --available] [--local | --global]

  (no flag)     List all known features with installed and latest versions.
  --installed   Show only features that are currently installed.
  --available   Show only features that exist in the managed clone.
  --local       List <cwd>/.claude instead of \$CLAUDE_HOME. Requires
                <cwd>/CLAUDE.md to exist. Omits statusline scripts, which
                are global-only.
  --global      List \$CLAUDE_HOME (default).
EOF
    exit 0
    ;;
  *) die "Unknown flag for ls: $1" ;;
esac

print_header() {
  printf '%s%-30s %-8s %-14s %-16s %s%s\n' \
    "$C_BOLD" "NAME" "KIND" "INSTALLED" "LATEST" "STATUS" "$C_RESET"
}

# Print a colored, right-padded cell. ANSI codes don't count toward field width,
# so we pad manually using the visible (plain-text) length of the value.
# Usage: _colored_cell COLOR TEXT RESET WIDTH SEPARATOR
_colored_cell() {
  local color="$1" text="$2" reset="$3" width="$4" sep="${5:- }"
  local pad=$(( width - ${#text} ))
  [ $pad -lt 0 ] && pad=0
  printf '%s%s%s%*s%s' "$color" "$text" "$reset" "$pad" "" "$sep"
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
        local claudemd_target
        claudemd_target="$(claudemd_target_path)"
        if [ -f "$claudemd_target" ]; then
          grep '<!-- chosko-llm:.*:begin' "$claudemd_target" 2>/dev/null \
            | sed 's/<!-- chosko-llm:\([^:]*\):begin.*/\1/' || true
        fi
      } | sort -u
      ;;
    statusline)
      for dir in "$CHOSKO_LLM_HOME/statusline" "$CLAUDE_HOME/statusline"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.sh; do
          [ -e "$f" ] || continue
          basename "$f" .sh
        done
      done | sort -u
      ;;
  esac
}

# compute_status <kind> <name> <inst_col> <latest_col>
# Prints "<status_col>\n<status_color>". Extends the base four-value
# vocabulary (not installed / local only / up-to-date / updatable) with two
# migration-aware statuses when a replaces: declaration ties this row to its
# counterpart: "superseded" (installed, no source, but a clone feature
# claims to replace it) and "migration pending" (in the clone, not
# installed, but its own replaces: names an installed artifact). The
# find_replacement / check_migration_pending probes only run on rows that
# are already local-only / not-installed — never on every row.
compute_status() {
  local kind="$1" name="$2" inst_col="$3" latest_col="$4"
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

  if [ "$status_col" = "local only" ] && find_replacement "$kind" "$name" >/dev/null; then
    status_col="superseded"
  elif [ "$status_col" = "not installed" ] && check_migration_pending "$kind" "$name" >/dev/null; then
    status_col="migration pending"
  fi

  local status_color
  case "$status_col" in
    "up-to-date")        status_color="$C_GREEN"  ;;
    "updatable")         status_color="$C_YELLOW" ;;
    "not installed")     status_color="$C_DIM"    ;;
    "local only")        status_color="$C_CYAN"   ;;
    "superseded")         status_color="$C_MAGENTA" ;;
    "migration pending")  status_color="$C_BLUE"    ;;
    *)                    status_color=""          ;;
  esac
  printf '%s\n%s\n' "$status_col" "$status_color"
}

list_all() {
  local filter="$1"
  printf '%sHome: %s%s\n\n' "$C_DIM" "$(scope_label)" "$C_RESET"
  print_header
  local found=0
  local installable=() updatable=() migrating=()

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

    local status_col status_color
    { read -r status_col; read -r status_color; } < <(compute_status command "$name" "$inst_col" "$latest_col")

    case "$status_col" in
      "not installed")                  installable+=("$name") ;;
      "updatable")                      updatable+=("$name") ;;
      "superseded"|"migration pending") migrating+=("$name") ;;
    esac

    local inst_color latest_color
    [ "$inst_col" = "—" ]    && inst_color="$C_DIM"   || inst_color=""
    [ "$latest_col" = "—" ]  && latest_color="$C_DIM" || latest_color=""
    _colored_cell ""              "$name"       ""        30
    _colored_cell "$C_BLUE"       "command"     "$C_RESET" 8
    _colored_cell "$inst_color"   "$inst_col"   "$C_RESET" 14
    _colored_cell "$latest_color" "$latest_col" "$C_RESET" 16
    printf '%s%s%s\n' "$status_color" "$status_col" "$C_RESET"
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

    local status_col status_color
    { read -r status_col; read -r status_color; } < <(compute_status skill "$name" "$inst_col" "$latest_col")

    case "$status_col" in
      "not installed")                  installable+=("$name") ;;
      "updatable")                      updatable+=("$name") ;;
      "superseded"|"migration pending") migrating+=("$name") ;;
    esac

    local inst_color latest_color
    [ "$inst_col" = "—" ]    && inst_color="$C_DIM"   || inst_color=""
    [ "$latest_col" = "—" ]  && latest_color="$C_DIM" || latest_color=""
    _colored_cell ""              "$name"       ""        30
    _colored_cell "$C_MAGENTA"    "skill"       "$C_RESET" 8
    _colored_cell "$inst_color"   "$inst_col"   "$C_RESET" 14
    _colored_cell "$latest_color" "$latest_col" "$C_RESET" 16
    printf '%s%s%s\n' "$status_color" "$status_col" "$C_RESET"
    found=1
  done < <(collect_names skill)

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    local src_file inst_ver src_ver inst_col latest_col
    src_file="$(src_claudemd_path "$name")"

    if claudemd_is_installed "$name"; then
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

    local status_col status_color
    { read -r status_col; read -r status_color; } < <(compute_status claude-md "$name" "$inst_col" "$latest_col")

    case "$status_col" in
      "not installed")                  installable+=("$name") ;;
      "updatable")                      updatable+=("$name") ;;
      "superseded"|"migration pending") migrating+=("$name") ;;
    esac

    local inst_color latest_color
    [ "$inst_col" = "—" ]    && inst_color="$C_DIM"   || inst_color=""
    [ "$latest_col" = "—" ]  && latest_color="$C_DIM" || latest_color=""
    _colored_cell ""              "$name"       ""        30
    _colored_cell "$C_CYAN"       "claude-md"   "$C_RESET" 8
    _colored_cell "$inst_color"   "$inst_col"   "$C_RESET" 14
    _colored_cell "$latest_color" "$latest_col" "$C_RESET" 16
    printf '%s%s%s\n' "$status_color" "$status_col" "$C_RESET"
    found=1
  done < <(collect_names claude-md)

  if ! scope_is_local; then
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    local inst_file src_file inst_ver src_ver inst_col latest_col
    inst_file="$(inst_statusline_path "$name")"
    src_file="$(src_statusline_path "$name")"

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

    local status_col status_color
    { read -r status_col; read -r status_color; } < <(compute_status statusline "$name" "$inst_col" "$latest_col")

    case "$status_col" in
      "not installed")                  installable+=("$name") ;;
      "updatable")                      updatable+=("$name") ;;
      "superseded"|"migration pending") migrating+=("$name") ;;
    esac

    local inst_color latest_color
    [ "$inst_col" = "—" ]    && inst_color="$C_DIM"   || inst_color=""
    [ "$latest_col" = "—" ]  && latest_color="$C_DIM" || latest_color=""
    _colored_cell ""              "$name"       ""        30
    _colored_cell "$C_GREEN"      "statusline"  "$C_RESET" 8
    _colored_cell "$inst_color"   "$inst_col"   "$C_RESET" 14
    _colored_cell "$latest_color" "$latest_col" "$C_RESET" 16
    printf '%s%s%s\n' "$status_color" "$status_col" "$C_RESET"
    found=1
  done < <(collect_names statusline)
  fi

  [ $found -eq 1 ] || log_info "No features found."

  # Actionable suggestions, gated to an interactive stdout so piped/redirected
  # output stays a clean table. Counts reflect the filtered, displayed rows.
  if [ "$found" -eq 1 ] && [ -t 1 ]; then
    local n_inst="${#installable[@]}" n_upd="${#updatable[@]}" n_mig="${#migrating[@]}"
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
    if [ "$n_mig" -ge 1 ]; then
      printf "Run 'chosko-llm update --all' to migrate %d feature(s) that changed kind.\n" "$n_mig"; suggested=1
    fi
    [ "$suggested" -eq 1 ] || printf 'Everything is up to date.\n'
    printf "Run 'chosko-llm show <feature>' to inspect a feature.\n"
  fi
}

list_all "$filter"
