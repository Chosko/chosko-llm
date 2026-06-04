#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<EOF
Usage: chosko-llm show <feature> [--installed | --latest | --diff] [--content]

  Inspect a single feature: name, kind, installed/latest version, status,
  description, and path.

  (no flag)     Show the installed copy if installed, otherwise the latest.
  --installed   Show the installed copy (notes if it is not installed).
  --latest      Show the latest copy from the managed clone.
  --diff        Compare latest vs installed (summary; add --content for a line diff).
  --content     Also print the body of the selected copy (or the diff).

  <feature> may be a bare name or 'command:<name>', 'skill:<name>', or
  'claude-md:<name>' to disambiguate.
EOF
}

feature=""
view="default"
show_content=0
sel_count=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)   usage; exit 0 ;;
    --installed) view="installed"; sel_count=$((sel_count + 1)) ;;
    --latest)    view="latest";    sel_count=$((sel_count + 1)) ;;
    --diff)      view="diff";      sel_count=$((sel_count + 1)) ;;
    --content)   show_content=1 ;;
    -*)          die "Unknown flag for show: $1" ;;
    *)
      [ -z "$feature" ] || die "show takes a single feature; unexpected argument: $1"
      feature="$1"
      ;;
  esac
  shift
done

[ -n "$feature" ] || die "Usage: chosko-llm show <feature> [--installed | --latest | --diff] [--content]"
[ "$sel_count" -le 1 ] || die "Choose only one of --installed, --latest, --diff."

# resolve_show_feature <spec> -> prints "kind\nname".
# Unlike lib.sh::resolve_feature, this also matches features that are installed
# but absent from the managed clone (local-only), so `show` can inspect them.
resolve_show_feature() {
  local spec="$1"
  local prefix="" name="$spec"
  case "$spec" in
    command:*)   prefix=command;   name="${spec#command:}" ;;
    skill:*)     prefix=skill;     name="${spec#skill:}" ;;
    claude-md:*) prefix=claude-md; name="${spec#claude-md:}" ;;
  esac

  local has_cmd=0 has_skill=0 has_cm=0
  if [ -f "$(src_command_path "$name")" ] || [ -f "$(inst_command_path "$name")" ]; then has_cmd=1; fi
  if [ -f "$(src_skill_path "$name")" ]   || [ -f "$(inst_skill_path "$name")" ];   then has_skill=1; fi
  if [ -f "$(src_claudemd_path "$name")" ] || claudemd_is_installed "$name";         then has_cm=1; fi

  if [ -n "$prefix" ]; then
    case "$prefix" in
      command)   [ "$has_cmd" -eq 1 ]   || die "No command named '$name' (installed or available)." ;;
      skill)     [ "$has_skill" -eq 1 ] || die "No skill named '$name' (installed or available)." ;;
      claude-md) [ "$has_cm" -eq 1 ]    || die "No claude-md named '$name' (installed or available)." ;;
    esac
    printf '%s\n%s\n' "$prefix" "$name"
    return 0
  fi

  local total=$((has_cmd + has_skill + has_cm))
  if   [ "$total" -gt 1 ];    then die "Feature name '$name' is ambiguous. Disambiguate with 'command:$name', 'skill:$name', or 'claude-md:$name'."
  elif [ "$has_cmd" -eq 1 ];  then printf 'command\n%s\n'   "$name"
  elif [ "$has_skill" -eq 1 ]; then printf 'skill\n%s\n'    "$name"
  elif [ "$has_cm" -eq 1 ];   then printf 'claude-md\n%s\n' "$name"
  else die "No feature named '$name' found (installed or in the managed clone)."
  fi
}

if ! resolved_out="$(resolve_show_feature "$feature")"; then
  exit 1
fi
mapfile -t resolved <<< "$resolved_out"
kind="${resolved[0]}"
name="${resolved[1]}"

# Resolve source/installed file paths and existence per kind.
src_exists=0
inst_exists=0
case "$kind" in
  command)
    src_file="$(src_command_path "$name")"
    inst_file="$(inst_command_path "$name")"
    [ -f "$src_file" ]  && src_exists=1  || true
    [ -f "$inst_file" ] && inst_exists=1 || true
    ;;
  skill)
    src_file="$(src_skill_path "$name")"
    inst_file="$(inst_skill_path "$name")"
    [ -f "$src_file" ]  && src_exists=1  || true
    [ -f "$inst_file" ] && inst_exists=1 || true
    ;;
  claude-md)
    src_file="$(src_claudemd_path "$name")"
    inst_file="$CLAUDE_HOME/CLAUDE.md"
    [ -f "$src_file" ] && src_exists=1 || true
    claudemd_is_installed "$name" && inst_exists=1 || true
    ;;
esac

# Versions.
src_ver=""
inst_ver=""
if [ "$src_exists" -eq 1 ]; then src_ver="$(read_frontmatter_field "$src_file" version || true)"; fi
if [ "$inst_exists" -eq 1 ]; then
  if [ "$kind" = "claude-md" ]; then
    inst_ver="$(claudemd_installed_version "$name" || true)"
  else
    inst_ver="$(read_frontmatter_field "$inst_file" version || true)"
  fi
fi

# Columns + status (same vocabulary as cmd-ls).
if [ "$inst_exists" -eq 1 ]; then inst_col="${inst_ver:-unversioned}"; else inst_col="—"; fi
if [ "$src_exists" -eq 1 ] && [ -n "$src_ver" ]; then latest_col="$src_ver"; else latest_col="—"; fi

if   [ "$inst_col" = "—" ];           then status="not installed"
elif [ "$latest_col" = "—" ];         then status="local only"
elif [ "$inst_col" = "$latest_col" ]; then status="up-to-date"
else                                       status="updatable"
fi

# Descriptions (claude-md installed sections carry no frontmatter).
src_desc=""
inst_desc=""
if [ "$src_exists" -eq 1 ]; then src_desc="$(read_frontmatter_field "$src_file" description || true)"; fi
if [ "$kind" != "claude-md" ] && [ "$inst_exists" -eq 1 ]; then
  inst_desc="$(read_frontmatter_field "$inst_file" description || true)"
fi

# Resolve the default view to a concrete one.
effective_view="$view"
if [ "$view" = "default" ]; then
  if [ "$inst_exists" -eq 1 ]; then effective_view="installed"; else effective_view="latest"; fi
fi

case "$effective_view" in
  installed) header="Showing installed copy"; desc="${inst_desc:-$src_desc}" ;;
  latest)    header="Showing latest copy (managed clone)"; desc="${src_desc:-$inst_desc}" ;;
  diff)      header="Showing diff: latest vs installed"; desc="${src_desc:-$inst_desc}" ;;
esac

# Path display.
case "$kind" in
  command)   loc="$inst_file" ;;
  skill)     loc="$(inst_skill_dir "$name")" ;;
  claude-md) loc="$CLAUDE_HOME/CLAUDE.md (section: chosko-llm:$name)" ;;
esac
if [ "$inst_exists" -eq 1 ]; then path_display="$loc"; else path_display="$loc (not yet installed)"; fi

# Body extractors.
print_installed_body() {
  case "$kind" in
    command|skill) cat "$inst_file" ;;
    claude-md)
      awk -v b="<!-- chosko-llm:${name}:begin" -v e="<!-- chosko-llm:${name}:end -->" '
        index($0, b) { grab = 1; next }
        grab && index($0, e) { grab = 0; next }
        grab { print }
      ' "$CLAUDE_HOME/CLAUDE.md"
      ;;
  esac
}
print_latest_body() {
  case "$kind" in
    command|skill) cat "$src_file" ;;
    claude-md)
      awk 'BEGIN { seen = 0; past = 0 }
        /^---[[:space:]]*$/ { if (!seen) { seen = 1; next } else if (!past) { past = 1; next } }
        past { print }
      ' "$src_file"
      ;;
  esac
}

# ---------- metadata block ----------
printf '%s of %s "%s"\n\n' "$header" "$kind" "$name"
printf '  Name:        %s\n' "$name"
printf '  Kind:        %s\n' "$kind"
printf '  Installed:   %s\n' "$inst_col"
printf '  Latest:      %s\n' "$latest_col"
printf '  Status:      %s\n' "$status"
printf '  Description: %s\n' "${desc:-—}"
printf '  Path:        %s\n' "$path_display"

# ---------- view-specific output ----------
echo
case "$effective_view" in
  installed)
    if [ "$inst_exists" -ne 1 ]; then
      printf 'This feature is not installed — nothing to show for --installed.\n'
    elif [ "$show_content" -eq 1 ]; then
      printf -- '--- installed content ---\n'
      print_installed_body
    fi
    ;;
  latest)
    if [ "$src_exists" -ne 1 ]; then
      printf 'No managed/latest copy exists (local only).\n'
    elif [ "$show_content" -eq 1 ]; then
      printf -- '--- latest content ---\n'
      print_latest_body
    fi
    ;;
  diff)
    if [ "$inst_exists" -ne 1 ]; then
      printf 'Cannot diff: feature is not installed.\n'
    elif [ "$src_exists" -ne 1 ]; then
      printf 'Cannot diff: no managed/latest copy (local only).\n'
    else
      printf 'installed %s  vs  latest %s  (%s)\n' "$inst_col" "$latest_col" "$status"
      if [ "$show_content" -eq 1 ]; then
        lt="$(mktemp)"
        it="$(mktemp)"
        print_installed_body > "$it"
        print_latest_body > "$lt"
        printf '\n'
        diff -u -L "installed: $name" -L "latest: $name" "$it" "$lt" || true
        rm -f "$lt" "$it"
      fi
    fi
    ;;
esac

# ---------- footer suggestions ----------
echo
case "$status" in
  "not installed")
    printf 'Tip: run `chosko-llm add %s` to install this feature.\n' "$name"
    ;;
  "updatable")
    printf 'Tip: run `chosko-llm update %s` to update (installed %s -> %s).\n' "$name" "$inst_col" "$latest_col"
    printf '     run `chosko-llm show %s --diff --content` to preview the changes.\n' "$name"
    ;;
  "up-to-date")
    printf 'This feature is up to date.\n'
    ;;
  "local only")
    printf 'This feature is installed but not in the managed clone; `chosko-llm upgrade` will not change it.\n'
    ;;
esac

if [ "$show_content" -ne 1 ]; then
  if [ "$effective_view" = "diff" ]; then
    printf 'Pass --content to see the line-by-line diff.\n'
  else
    printf 'Pass --content to also print the feature body.\n'
  fi
fi
