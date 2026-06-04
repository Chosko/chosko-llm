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

_use_color_stdout() {
  [ -z "${NO_COLOR:-}" ] && [ -t 1 ]
}

log_info()    { if _use_color; then printf '\033[1;34m[info]\033[0m %s\n'  "$*" >&2; else printf '[info] %s\n'  "$*" >&2; fi; }
log_warn()    { if _use_color; then printf '\033[1;33m[warn]\033[0m %s\n'  "$*" >&2; else printf '[warn] %s\n'  "$*" >&2; fi; }
log_error()   { if _use_color; then printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; else printf '[error] %s\n' "$*" >&2; fi; }
log_success() { if _use_color; then printf '\033[1;32m[ok]\033[0m %s\n'    "$*" >&2; else printf '[ok] %s\n'    "$*" >&2; fi; }

die() { log_error "$*"; exit 1; }

# ---------- stdout colors ----------
# C_* variables are set at source time based on whether stdout is a TTY.
# Scripts that write to stdout should use these variables, never raw \033[ escapes.
if _use_color_stdout; then
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  C_RESET=$'\033[0m'
else
  C_GREEN='' C_YELLOW='' C_CYAN='' C_DIM='' C_BOLD='' C_RESET=''
fi

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
src_command_path()  { printf '%s/commands/%s.md' "$CHOSKO_LLM_HOME" "$1"; }
src_skill_path()    { printf '%s/skills/%s/SKILL.md' "$CHOSKO_LLM_HOME" "$1"; }
src_skill_dir()     { printf '%s/skills/%s' "$CHOSKO_LLM_HOME" "$1"; }
src_claudemd_path() { printf '%s/claude-md/%s.md' "$CHOSKO_LLM_HOME" "$1"; }

# Installed paths under CLAUDE_HOME.
inst_command_path() { printf '%s/commands/%s.md' "$CLAUDE_HOME" "$1"; }
inst_skill_path()   { printf '%s/skills/%s/SKILL.md' "$CLAUDE_HOME" "$1"; }
inst_skill_dir()    { printf '%s/skills/%s' "$CLAUDE_HOME" "$1"; }

# claudemd_is_installed <name>
# Returns 0 if a managed section for <name> exists in $CLAUDE_HOME/CLAUDE.md.
claudemd_is_installed() {
  local name="$1" target="$CLAUDE_HOME/CLAUDE.md"
  [ -f "$target" ] && grep -qF "<!-- chosko-llm:${name}:begin" "$target"
}

# claudemd_installed_version <name>
# Prints the version recorded in the begin tag, or empty if not installed.
claudemd_installed_version() {
  local name="$1" target="$CLAUDE_HOME/CLAUDE.md"
  [ -f "$target" ] || return 0
  grep "<!-- chosko-llm:${name}:begin" "$target" 2>/dev/null \
    | sed 's/.*:begin v\([^ ]*\) -->.*/\1/' | head -1
}

# inject_section <name> <version> <src_file>
# Inserts or replaces the named managed section in $CLAUDE_HOME/CLAUDE.md.
# Body is the content of <src_file> after its frontmatter closing ---.
inject_section() {
  local name="$1" version="$2" src_file="$3"
  local target="$CLAUDE_HOME/CLAUDE.md"
  local begin_tag="<!-- chosko-llm:${name}:begin v${version} -->"
  local end_tag="<!-- chosko-llm:${name}:end -->"
  local begin_marker="<!-- chosko-llm:${name}:begin"

  local body_file
  body_file="$(mktemp)"
  awk 'BEGIN{seen_open=0;past_fm=0}
    /^---[[:space:]]*$/ {
      if (!seen_open) { seen_open=1; next }
      else if (!past_fm) { past_fm=1; next }
    }
    past_fm { print }
  ' "$src_file" > "$body_file"

  if [ ! -f "$target" ]; then
    { printf '%s\n' "$begin_tag"; cat "$body_file"; printf '%s\n' "$end_tag"; } > "$target"
    rm -f "$body_file"; return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  if grep -qF "$begin_marker" "$target"; then
    awk -v begin_marker="$begin_marker" \
        -v begin_tag="$begin_tag" \
        -v end_marker="$end_tag" \
        -v body_file="$body_file" '
      index($0, begin_marker) {
        print begin_tag
        while ((getline line < body_file) > 0) print line
        close(body_file)
        skip=1; next
      }
      skip && index($0, end_marker) { print end_marker; skip=0; next }
      skip { next }
      { print }
    ' "$target" > "$tmp_file" && mv "$tmp_file" "$target"
  else
    cp "$target" "$tmp_file"
    { printf '\n%s\n' "$begin_tag"; cat "$body_file"; printf '%s\n' "$end_tag"; } >> "$tmp_file"
    mv "$tmp_file" "$target"
  fi
  rm -f "$body_file"
}

# remove_section <name>
# Removes a managed section from $CLAUDE_HOME/CLAUDE.md.
remove_section() {
  local name="$1" target="$CLAUDE_HOME/CLAUDE.md"
  [ -f "$target" ] || die "CLAUDE.md not found at $target"
  grep -qF "<!-- chosko-llm:${name}:begin" "$target" \
    || die "claude-md '$name' is not installed in $target"
  local tmp_file
  tmp_file="$(mktemp)"
  awk -v begin_marker="<!-- chosko-llm:${name}:begin" \
      -v end_marker="<!-- chosko-llm:${name}:end -->" '
    index($0, begin_marker) { skip=1; next }
    skip && index($0, end_marker) { skip=0; next }
    skip { next }
    { print }
  ' "$target" > "$tmp_file" && mv "$tmp_file" "$target"
}

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
# Accepts: "<name>", "command:<name>", "skill:<name>", "claude-md:<name>".
# Prints two lines on stdout: kind\nname  (kind = command|skill|claude-md).
# Errors out if ambiguous or not found in the managed clone.
resolve_feature() {
  local spec="$1"
  local prefix="" name="$spec"
  case "$spec" in
    command:*)   prefix=command;   name="${spec#command:}"   ;;
    skill:*)     prefix=skill;     name="${spec#skill:}"     ;;
    claude-md:*) prefix=claude-md; name="${spec#claude-md:}" ;;
  esac

  if [ -n "$prefix" ]; then
    case "$prefix" in
      command)   [ -f "$(src_command_path  "$name")" ] || die "No such command in managed clone: $name" ;;
      skill)     [ -f "$(src_skill_path    "$name")" ] || die "No such skill in managed clone: $name"   ;;
      claude-md) [ -f "$(src_claudemd_path "$name")" ] || die "No such claude-md in managed clone: $name" ;;
    esac
    printf '%s\n%s\n' "$prefix" "$name"
    return 0
  fi

  local has_cmd=0 has_skill=0 has_cm=0
  [ -f "$(src_command_path  "$name")" ] && has_cmd=1
  [ -f "$(src_skill_path    "$name")" ] && has_skill=1
  [ -f "$(src_claudemd_path "$name")" ] && has_cm=1
  local total=$(( has_cmd + has_skill + has_cm ))
  if   [ $total -gt 1 ];    then die "Feature name '$name' is ambiguous. Disambiguate with 'command:$name', 'skill:$name', or 'claude-md:$name'."
  elif [ $has_cmd -eq 1 ];  then printf 'command\n%s\n'   "$name"
  elif [ $has_skill -eq 1 ]; then printf 'skill\n%s\n'    "$name"
  elif [ $has_cm -eq 1 ];   then printf 'claude-md\n%s\n' "$name"
  else die "No feature named '$name' found in $CHOSKO_LLM_HOME (commands/, skills/, or claude-md/)."
  fi
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
