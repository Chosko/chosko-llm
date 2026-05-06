#!/usr/bin/env bash
# Shared helpers for chosko-llm scripts. Source this file; do not exec it.
# shellcheck shell=bash

# Default paths — every script must respect these env overrides.
: "${CHOSKO_LLM_HOME:=$HOME/.chosko-llm}"
: "${CLAUDE_HOME:=$HOME/.claude}"

# ---------- logging ----------

_use_color() {
  [ -z "${NO_COLOR:-}" ] && [ -t 2 ]
}

log_info()  { if _use_color; then printf '\033[1;34m[info]\033[0m %s\n'  "$*" >&2; else printf '[info] %s\n'  "$*" >&2; fi; }
log_warn()  { if _use_color; then printf '\033[1;33m[warn]\033[0m %s\n'  "$*" >&2; else printf '[warn] %s\n'  "$*" >&2; fi; }
log_error() { if _use_color; then printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; else printf '[error] %s\n' "$*" >&2; fi; }

die() { log_error "$*"; exit 1; }

# ---------- frontmatter ----------

# parse_frontmatter <file>
# Emits key=value lines for: name, version, type, description.
# Reads only the first YAML frontmatter block delimited by --- ... ---.
# Quietly ignores keys it doesn't care about.
parse_frontmatter() {
  local file="$1"
  [ -f "$file" ] || return 1
  awk '
    BEGIN { in_fm = 0; seen_open = 0 }
    /^---[[:space:]]*$/ {
      if (!seen_open) { in_fm = 1; seen_open = 1; next }
      else if (in_fm)  { exit }
    }
    in_fm {
      line = $0
      # split on first colon
      idx = index(line, ":")
      if (idx == 0) next
      key = substr(line, 1, idx - 1)
      val = substr(line, idx + 1)
      # trim
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      # strip optional surrounding quotes
      if (val ~ /^".*"$/ || val ~ /^'\''.*'\''$/) {
        val = substr(val, 2, length(val) - 2)
      }
      if (key == "name" || key == "version" || key == "type" || key == "description") {
        print key "=" val
      }
    }
  ' "$file"
}

# read_frontmatter_field <file> <field>
# Convenience: prints just the value of one field, or empty if absent.
read_frontmatter_field() {
  local file="$1" field="$2"
  parse_frontmatter "$file" | awk -F= -v k="$field" '$1 == k { sub(/^[^=]*=/, ""); print; exit }'
}

# ---------- feature resolution ----------

# Source paths in the managed clone.
src_command_path() { printf '%s/commands/%s.md' "$CHOSKO_LLM_HOME" "$1"; }
src_skill_path()   { printf '%s/skills/%s/SKILL.md' "$CHOSKO_LLM_HOME" "$1"; }
src_skill_dir()    { printf '%s/skills/%s' "$CHOSKO_LLM_HOME" "$1"; }

# Installed paths under CLAUDE_HOME.
inst_command_path() { printf '%s/commands/%s.md' "$CLAUDE_HOME" "$1"; }
inst_skill_path()   { printf '%s/skills/%s/SKILL.md' "$CLAUDE_HOME" "$1"; }
inst_skill_dir()    { printf '%s/skills/%s' "$CLAUDE_HOME" "$1"; }

# feature_kind <name> -> command | skill | both | none
# Looks at the managed clone (the source of truth for what's authorable).
feature_kind() {
  local name="$1"
  local has_cmd=0 has_skill=0
  [ -f "$(src_command_path "$name")" ] && has_cmd=1
  [ -f "$(src_skill_path   "$name")" ] && has_skill=1
  if [ $has_cmd -eq 1 ] && [ $has_skill -eq 1 ]; then echo both
  elif [ $has_cmd -eq 1 ];                       then echo command
  elif [ $has_skill -eq 1 ];                     then echo skill
  else                                                 echo none
  fi
}

# installed_kind <name> -> command | skill | both | none
installed_kind() {
  local name="$1"
  local has_cmd=0 has_skill=0
  [ -f "$(inst_command_path "$name")" ] && has_cmd=1
  [ -f "$(inst_skill_path   "$name")" ] && has_skill=1
  if [ $has_cmd -eq 1 ] && [ $has_skill -eq 1 ]; then echo both
  elif [ $has_cmd -eq 1 ];                       then echo command
  elif [ $has_skill -eq 1 ];                     then echo skill
  else                                                 echo none
  fi
}

# resolve_feature <spec>
# Accepts: "<name>", "command:<name>", "skill:<name>".
# Prints two lines on stdout: kind\nname  (kind = command|skill).
# Errors out if ambiguous or not found in the managed clone.
resolve_feature() {
  local spec="$1"
  local prefix="" name="$spec"
  case "$spec" in
    command:*) prefix=command; name="${spec#command:}" ;;
    skill:*)   prefix=skill;   name="${spec#skill:}"   ;;
  esac

  if [ -n "$prefix" ]; then
    case "$prefix" in
      command) [ -f "$(src_command_path "$name")" ] || die "No such command in managed clone: $name" ;;
      skill)   [ -f "$(src_skill_path   "$name")" ] || die "No such skill in managed clone: $name"   ;;
    esac
    printf '%s\n%s\n' "$prefix" "$name"
    return 0
  fi

  local kind
  kind="$(feature_kind "$name")"
  case "$kind" in
    command|skill) printf '%s\n%s\n' "$kind" "$name" ;;
    both) die "Feature name '$name' matches both a command and a skill. Disambiguate with 'command:$name' or 'skill:$name'." ;;
    none) die "No feature named '$name' found in $CHOSKO_LLM_HOME (commands/ or skills/)." ;;
  esac
}

# ---------- semver ----------

# semver_cmp <a> <b>  -> prints "<", "=", or ">"
# Falls back to string equality if either side doesn't look like dotted numbers.
semver_cmp() {
  local a="$1" b="$2"
  if [ "$a" = "$b" ]; then echo "="; return 0; fi
  if ! [[ "$a" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || ! [[ "$b" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]]; then
    # Non-semver — fall back to string comparison.
    if [ "$a" \< "$b" ]; then echo "<"; else echo ">"; fi
    return 0
  fi
  IFS=. read -r a1 a2 a3 <<<"$a"
  IFS=. read -r b1 b2 b3 <<<"$b"
  a1="${a1:-0}"; a2="${a2:-0}"; a3="${a3:-0}"
  b1="${b1:-0}"; b2="${b2:-0}"; b3="${b3:-0}"
  for pair in "$a1 $b1" "$a2 $b2" "$a3 $b3"; do
    # shellcheck disable=SC2086
    set -- $pair
    if   [ "$1" -lt "$2" ]; then echo "<"; return 0
    elif [ "$1" -gt "$2" ]; then echo ">"; return 0
    fi
  done
  echo "="
}

# ---------- validation ----------

# require_versioned_source <file>
# Errors out if the file is missing a non-empty `version` frontmatter field.
require_versioned_source() {
  local file="$1"
  [ -f "$file" ] || die "Source file does not exist: $file"
  local version
  version="$(read_frontmatter_field "$file" version || true)"
  [ -n "$version" ] || die "Refusing to install: $file is missing a 'version' field in its frontmatter."
  local fname
  fname="$(read_frontmatter_field "$file" name || true)"
  [ -n "$fname" ] || die "Refusing to install: $file is missing a 'name' field in its frontmatter."
}
