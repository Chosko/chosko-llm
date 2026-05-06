#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

mode="--installed"
case "${1:-}" in
  ""|--installed) mode="--installed" ;;
  --available)    mode="--available" ;;
  -h|--help)
    cat <<EOF
Usage: chosko-llm ls [--installed | --available]

  --installed   (default) list features in \$CLAUDE_HOME with version
  --available   list features in the managed clone that are not installed,
                or are installed at an older version
EOF
    exit 0
    ;;
  *) die "Unknown flag for ls: $1" ;;
esac

# Print a row: name, kind, version, [status]
# Use printf with column widths.
print_header() {
  printf '%-30s %-8s %-12s %s\n' "NAME" "KIND" "VERSION" "STATUS"
}

# ---------- --installed ----------

list_installed() {
  print_header
  local found=0

  if [ -d "$CLAUDE_HOME/commands" ]; then
    for f in "$CLAUDE_HOME"/commands/*.md; do
      [ -e "$f" ] || continue
      local name version
      name="$(read_frontmatter_field "$f" name || true)"
      version="$(read_frontmatter_field "$f" version || true)"
      [ -n "$name" ]    || name="$(basename "$f" .md)"
      [ -n "$version" ] || version="?"
      printf '%-30s %-8s %-12s\n' "$name" "command" "$version"
      found=1
    done
  fi

  if [ -d "$CLAUDE_HOME/skills" ]; then
    for d in "$CLAUDE_HOME"/skills/*/; do
      [ -e "$d" ] || continue
      local sf="$d/SKILL.md"
      [ -f "$sf" ] || continue
      local name version
      name="$(read_frontmatter_field "$sf" name || true)"
      version="$(read_frontmatter_field "$sf" version || true)"
      [ -n "$name" ]    || name="$(basename "$d")"
      [ -n "$version" ] || version="?"
      printf '%-30s %-8s %-12s\n' "$name" "skill" "$version"
      found=1
    done
  fi

  if [ $found -eq 0 ]; then
    log_info "No features installed under $CLAUDE_HOME."
  fi
}

# ---------- --available ----------

list_available() {
  print_header
  local any=0

  # Commands
  if [ -d "$CHOSKO_LLM_HOME/commands" ]; then
    for f in "$CHOSKO_LLM_HOME"/commands/*.md; do
      [ -e "$f" ] || continue
      local name src_ver
      name="$(read_frontmatter_field "$f" name || true)"
      src_ver="$(read_frontmatter_field "$f" version || true)"
      [ -n "$name" ]    || name="$(basename "$f" .md)"
      [ -n "$src_ver" ] || src_ver="?"
      local inst="$(inst_command_path "$name")"
      if [ -f "$inst" ]; then
        local inst_ver cmp
        inst_ver="$(read_frontmatter_field "$inst" version || true)"
        [ -n "$inst_ver" ] || inst_ver="?"
        cmp="$(semver_cmp "$inst_ver" "$src_ver")"
        if [ "$cmp" = "<" ]; then
          printf '%-30s %-8s %-12s %s\n' "$name" "command" "$src_ver" "[upgradable: $inst_ver -> $src_ver]"
          any=1
        fi
      else
        printf '%-30s %-8s %-12s %s\n' "$name" "command" "$src_ver" "[new]"
        any=1
      fi
    done
  fi

  # Skills
  if [ -d "$CHOSKO_LLM_HOME/skills" ]; then
    for d in "$CHOSKO_LLM_HOME"/skills/*/; do
      [ -e "$d" ] || continue
      local sf="$d/SKILL.md"
      [ -f "$sf" ] || continue
      local name src_ver
      name="$(read_frontmatter_field "$sf" name || true)"
      src_ver="$(read_frontmatter_field "$sf" version || true)"
      [ -n "$name" ]    || name="$(basename "$d")"
      [ -n "$src_ver" ] || src_ver="?"
      local inst="$(inst_skill_path "$name")"
      if [ -f "$inst" ]; then
        local inst_ver cmp
        inst_ver="$(read_frontmatter_field "$inst" version || true)"
        [ -n "$inst_ver" ] || inst_ver="?"
        cmp="$(semver_cmp "$inst_ver" "$src_ver")"
        if [ "$cmp" = "<" ]; then
          printf '%-30s %-8s %-12s %s\n' "$name" "skill" "$src_ver" "[upgradable: $inst_ver -> $src_ver]"
          any=1
        fi
      else
        printf '%-30s %-8s %-12s %s\n' "$name" "skill" "$src_ver" "[new]"
        any=1
      fi
    done
  fi

  if [ $any -eq 0 ]; then
    log_info "Nothing new or upgradable. All features in $CHOSKO_LLM_HOME are installed at the current version."
  fi
}

case "$mode" in
  --installed) list_installed ;;
  --available) list_available ;;
esac
