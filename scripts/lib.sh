#!/usr/bin/env bash
# Shared helpers for chosko-llm scripts. Source this file; do not exec it.
# shellcheck shell=bash

# Default paths — every script must respect these env overrides.
: "${CHOSKO_LLM_HOME:=$HOME/.chosko-llm}"
: "${CLAUDE_HOME:=$HOME/.claude}"

# Install scope — set by resolve_scope; defaults to global until called.
: "${CHOSKO_LLM_SCOPE:=global}"
SCOPE_ARGS=()

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

# ---------- version ----------

# resolve_version
# Prints the repo-level version string for the managed clone: the trimmed
# contents of $CHOSKO_LLM_HOME/VERSION, plus " (<git describe>)" when git and a
# describe value are available. Prints "unknown" if VERSION is missing. This is
# the single source of the version format — install.sh and cmd-version.sh both
# use it so they never drift.
resolve_version() {
  local version="unknown" gitdesc
  if [ -f "$CHOSKO_LLM_HOME/VERSION" ]; then
    version="$(tr -d '[:space:]' < "$CHOSKO_LLM_HOME/VERSION")"
  fi
  if command -v git >/dev/null 2>&1; then
    gitdesc="$(git -C "$CHOSKO_LLM_HOME" describe --tags --always 2>/dev/null || true)"
    [ -n "$gitdesc" ] && version="$version ($gitdesc)"
  fi
  printf '%s\n' "$version"
}

# ---------- stdout colors ----------
# C_* variables are set at source time based on whether stdout is a TTY.
# Scripts that write to stdout should use these variables, never raw \033[ escapes.
if _use_color_stdout; then
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'
  C_BLUE=$'\033[34m'
  C_MAGENTA=$'\033[35m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  C_RESET=$'\033[0m'
else
  C_GREEN='' C_YELLOW='' C_CYAN='' C_BLUE='' C_MAGENTA='' C_DIM='' C_BOLD='' C_RESET=''
fi

# ---------- scope resolution ----------

# resolve_scope "$@"
# Scans every argument for --local / --global. Dies if both appear. Sets
# global CHOSKO_LLM_SCOPE ("local" or "global", default "global") and global
# array SCOPE_ARGS to the arguments with the scope flag removed, order and
# embedded whitespace preserved. In local scope, requires $PWD/CLAUDE.md to
# exist and repoints CLAUDE_HOME to "$PWD/.claude" (overriding any inherited
# CLAUDE_HOME). In global scope, CLAUDE_HOME is left untouched.
resolve_scope() {
  local args=() arg saw_local=0 saw_global=0
  for arg in "$@"; do
    case "$arg" in
      --local)  saw_local=1 ;;
      --global) saw_global=1 ;;
      *) args+=("$arg") ;;
    esac
  done

  if [ $saw_local -eq 1 ] && [ $saw_global -eq 1 ]; then
    die "--local and --global cannot be combined. Pick one."
  fi

  if [ $saw_local -eq 1 ]; then
    CHOSKO_LLM_SCOPE=local
    if [ ! -f "$PWD/CLAUDE.md" ]; then
      die "--local requires $PWD/CLAUDE.md to exist. Run --local from the project root; if this is an empty directory, run /project-setup first."
    fi
    CLAUDE_HOME="$PWD/.claude"
  else
    CHOSKO_LLM_SCOPE=global
  fi

  SCOPE_ARGS=(${args[@]+"${args[@]}"})
}

# scope_is_local — returns 0 in local scope, 1 otherwise.
scope_is_local() {
  [ "$CHOSKO_LLM_SCOPE" = local ]
}

# scope_label — prints a human-readable scope for log lines, including the
# resolved CLAUDE_HOME path, e.g. "local (/path/to/repo/.claude)".
scope_label() {
  if scope_is_local; then
    printf 'local (%s)' "$CLAUDE_HOME"
  else
    printf 'global (%s)' "$CLAUDE_HOME"
  fi
}

# scope_supports_kind <kind>
# Returns 1 for kind "statusline" in local scope (per-project statusline
# scripts are out of scope); 0 for every other kind/scope combination.
scope_supports_kind() {
  local kind="$1"
  if scope_is_local && [ "$kind" = statusline ]; then
    return 1
  fi
  return 0
}

# ---------- frontmatter ----------

# parse_frontmatter <file>
# Emits key=value lines for: name, version, type, description, replaces.
# `replaces` is optional — see the kind-migration section below.
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
      if (key == "name" || key == "version" || key == "type" || key == "description" || key == "replaces") {
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
src_statusline_path() { printf '%s/statusline/%s.sh' "$CHOSKO_LLM_HOME" "$1"; }

# Installed paths under CLAUDE_HOME.
inst_command_path() { printf '%s/commands/%s.md' "$CLAUDE_HOME" "$1"; }
inst_skill_path()   { printf '%s/skills/%s/SKILL.md' "$CLAUDE_HOME" "$1"; }
inst_skill_dir()    { printf '%s/skills/%s' "$CLAUDE_HOME" "$1"; }
inst_statusline_path() { printf '%s/statusline/%s.sh' "$CLAUDE_HOME" "$1"; }

# export_dir_path
# Prints the directory `chosko-llm export` writes into: $CHOSKO_LLM_EXPORT_DIR
# if set, else $HOME/claude-exports. The only place that path is assembled.
export_dir_path() { printf '%s' "${CHOSKO_LLM_EXPORT_DIR:-$HOME/claude-exports}"; }

# open_in_file_manager <dir>
# Opens <dir> in the OS file manager. Tries, in order: explorer.exe (Windows,
# incl. Git Bash/WSL), open (macOS), xdg-open (Linux). Silently does nothing
# if none are available.
open_in_file_manager() {
  local dir="$1"
  local win_dir="$dir"
  if command -v explorer.exe >/dev/null 2>&1; then
    command -v cygpath >/dev/null 2>&1 && win_dir="$(cygpath -w "$dir")"
    explorer.exe "$win_dir" >/dev/null 2>&1 || true
  elif command -v open >/dev/null 2>&1; then
    open "$dir"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$dir" >/dev/null 2>&1 &
  else
    log_warn "No file manager launcher found (explorer.exe / open / xdg-open) — open $dir manually."
  fi
}

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

# print_statusline_prompt <name> <installed_path>
# Prints a copy-pasteable prompt for a Claude Code session to safely merge
# the statusLine key into $CLAUDE_HOME/settings.json. No jq/automated JSON
# editing here — settings.json's shape isn't ours to own.
print_statusline_prompt() {
  local name="$1" installed_path="$2"
  cat <<EOF

To activate '$name', open a Claude Code session and paste this prompt:

  Update $CLAUDE_HOME/settings.json: set (or add) the top-level "statusLine"
  key to {"type":"command","command":"$installed_path","padding":1},
  preserving every other key in the file.
EOF
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
    command:*)    prefix=command;    name="${spec#command:}"    ;;
    skill:*)      prefix=skill;      name="${spec#skill:}"      ;;
    claude-md:*)  prefix=claude-md;  name="${spec#claude-md:}"  ;;
    statusline:*) prefix=statusline; name="${spec#statusline:}" ;;
  esac

  if [ -n "$prefix" ]; then
    case "$prefix" in
      command)    [ -f "$(src_command_path    "$name")" ] || die "No such command in managed clone: $name" ;;
      skill)      [ -f "$(src_skill_path      "$name")" ] || die "No such skill in managed clone: $name"   ;;
      claude-md)  [ -f "$(src_claudemd_path   "$name")" ] || die "No such claude-md in managed clone: $name" ;;
      statusline) [ -f "$(src_statusline_path "$name")" ] || die "No such statusline in managed clone: $name" ;;
    esac
    printf '%s\n%s\n' "$prefix" "$name"
    return 0
  fi

  local has_cmd=0 has_skill=0 has_cm=0 has_sl=0
  [ -f "$(src_command_path    "$name")" ] && has_cmd=1
  [ -f "$(src_skill_path      "$name")" ] && has_skill=1
  [ -f "$(src_claudemd_path   "$name")" ] && has_cm=1
  [ -f "$(src_statusline_path "$name")" ] && has_sl=1
  local total=$(( has_cmd + has_skill + has_cm + has_sl ))
  if   [ $total -gt 1 ];    then die "Feature name '$name' is ambiguous. Disambiguate with 'command:$name', 'skill:$name', 'claude-md:$name', or 'statusline:$name'."
  elif [ $has_cmd -eq 1 ];  then printf 'command\n%s\n'   "$name"
  elif [ $has_skill -eq 1 ]; then printf 'skill\n%s\n'    "$name"
  elif [ $has_cm -eq 1 ];   then printf 'claude-md\n%s\n' "$name"
  elif [ $has_sl -eq 1 ];   then printf 'statusline\n%s\n' "$name"
  else die "No feature named '$name' found in $CHOSKO_LLM_HOME (commands/, skills/, claude-md/, or statusline/)."
  fi
}

# ---------- kind migration (replaces:) ----------
# Install is copy-based and never prunes, so a feature that changes kind
# (commands/<n>.md becomes skills/<n>/SKILL.md) would leave the stale installed
# artifact sitting next to the new one under the same /<n> name. The superseding
# feature declares `replaces: <kind>:<name>` in its frontmatter; the helpers
# below act on that declaration. No state file — the fact travels in the same
# git pull that ships the rename.

# src_path_for_kind <kind> <name>
# The managed-clone source file for a feature of that kind. Returns non-zero
# for an unknown kind.
src_path_for_kind() {
  case "$1" in
    command)    src_command_path    "$2" ;;
    skill)      src_skill_path      "$2" ;;
    claude-md)  src_claudemd_path   "$2" ;;
    statusline) src_statusline_path "$2" ;;
    *) return 1 ;;
  esac
}

# parse_replaces_spec <spec>
# Splits a kind-prefixed spec ("command:foo") into two lines: kind\nname.
# Returns non-zero if the spec carries no recognized kind prefix.
parse_replaces_spec() {
  case "$1" in
    command:*)    printf 'command\n%s\n'    "${1#command:}"    ;;
    skill:*)      printf 'skill\n%s\n'      "${1#skill:}"      ;;
    claude-md:*)  printf 'claude-md\n%s\n'  "${1#claude-md:}"  ;;
    statusline:*) printf 'statusline\n%s\n' "${1#statusline:}" ;;
    *) return 1 ;;
  esac
}

# artifact_is_installed <kind> <name>
# Returns 0 if an artifact of that kind/name exists under $CLAUDE_HOME.
artifact_is_installed() {
  case "$1" in
    command)    [ -f "$(inst_command_path    "$2")" ] ;;
    skill)      [ -d "$(inst_skill_dir       "$2")" ] ;;
    claude-md)  claudemd_is_installed "$2" ;;
    statusline) [ -f "$(inst_statusline_path "$2")" ] ;;
    *) return 1 ;;
  esac
}

# remove_installed_artifact <kind> <name>
# Deletes an installed artifact using the same semantics as `cmd-rm` for its
# kind. Assumes artifact_is_installed already said yes.
remove_installed_artifact() {
  case "$1" in
    command)    rm -f  "$(inst_command_path    "$2")" ;;
    skill)      rm -rf "$(inst_skill_dir       "$2")" ;;
    claude-md)  remove_section "$2" ;;
    statusline) rm -f  "$(inst_statusline_path "$2")" ;;
    *) die "Unknown kind: $1" ;;
  esac
}

# apply_replaces <kind> <name>
# Post-install hook: honour the just-installed feature's `replaces:` key. If it
# names an artifact that is still installed, remove it and log one migration
# line. Silent when the key is absent or the named artifact is not installed.
apply_replaces() {
  local new_kind="$1" new_name="$2" src spec parsed old_kind old_name
  src="$(src_path_for_kind "$new_kind" "$new_name")" || return 0
  spec="$(read_frontmatter_field "$src" replaces || true)"
  [ -n "$spec" ] || return 0

  parsed="$(parse_replaces_spec "$spec" || true)"
  old_kind="$(printf '%s\n' "$parsed" | sed -n 1p)"
  old_name="$(printf '%s\n' "$parsed" | sed -n 2p)"
  if [ -z "$old_kind" ] || [ -z "$old_name" ]; then
    log_warn "Ignoring malformed 'replaces: $spec' in $src — expected <kind>:<name>."
    return 0
  fi
  if [ "$old_kind" = "$new_kind" ] && [ "$old_name" = "$new_name" ]; then
    log_warn "Ignoring 'replaces: $spec' in $src — a feature cannot replace itself."
    return 0
  fi

  artifact_is_installed "$old_kind" "$old_name" || return 0
  remove_installed_artifact "$old_kind" "$old_name"
  log_success "Migrated $old_kind '$old_name' -> $new_kind '$new_name'"
}

# find_replacement <old-kind> <old-name>
# Scans the managed clone for the feature declaring `replaces:
# <old-kind>:<old-name>`. Prints "<kind>\n<name>" on the first hit; prints
# nothing and returns 1 when no feature claims it.
find_replacement() {
  local want="$1:$2" f
  for f in "$CHOSKO_LLM_HOME"/commands/*.md; do
    [ -f "$f" ] || continue
    [ "$(read_frontmatter_field "$f" replaces || true)" = "$want" ] || continue
    printf 'command\n%s\n' "$(basename "$f" .md)"; return 0
  done
  for f in "$CHOSKO_LLM_HOME"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    [ "$(read_frontmatter_field "$f" replaces || true)" = "$want" ] || continue
    printf 'skill\n%s\n' "$(basename "$(dirname "$f")")"; return 0
  done
  for f in "$CHOSKO_LLM_HOME"/claude-md/*.md; do
    [ -f "$f" ] || continue
    [ "$(read_frontmatter_field "$f" replaces || true)" = "$want" ] || continue
    printf 'claude-md\n%s\n' "$(basename "$f" .md)"; return 0
  done
  for f in "$CHOSKO_LLM_HOME"/statusline/*.sh; do
    [ -f "$f" ] || continue
    [ "$(read_frontmatter_field "$f" replaces || true)" = "$want" ] || continue
    printf 'statusline\n%s\n' "$(basename "$f" .sh)"; return 0
  done
  return 1
}

# ---------- auto-upgrade state ----------
# A tiny key=value state file in the managed clone tracks the daily
# auto-upgrade preference and when it last ran. It is gitignored so the
# `git pull --ff-only` in `upgrade` is never blocked by it.
# Keys: enabled (true|false), last_run (YYYY-MM-DD).

auto_upgrade_state_file() { printf '%s/.auto-upgrade-state' "$CHOSKO_LLM_HOME"; }

# auto_upgrade_get <key> — print the value for <key>, or nothing if absent.
auto_upgrade_get() {
  local key="$1" file
  file="$(auto_upgrade_state_file)"
  [ -f "$file" ] || return 0
  awk -F= -v k="$key" '$1 == k { sub(/^[^=]*=/, ""); print; exit }' "$file"
}

# auto_upgrade_set <key> <value> — create or update <key> in the state file.
auto_upgrade_set() {
  local key="$1" value="$2" file tmp
  file="$(auto_upgrade_state_file)"
  if [ -f "$file" ] && grep -q "^${key}=" "$file"; then
    tmp="$(mktemp)"
    awk -F= -v k="$key" -v v="$value" '
      $1 == k { print k "=" v; next }
      { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

# auto_upgrade_enabled — succeeds unless the preference is explicitly "false".
# A missing file or missing key is treated as enabled (opt-in by default).
auto_upgrade_enabled() {
  [ "$(auto_upgrade_get enabled)" != "false" ]
}

# auto_upgrade_due — succeeds when the last run was not today (calendar day).
auto_upgrade_due() {
  [ "$(auto_upgrade_get last_run)" != "$(date +%Y-%m-%d)" ]
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
