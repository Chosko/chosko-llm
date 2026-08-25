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

# raw_version
# Prints the trimmed contents of $CHOSKO_LLM_HOME/VERSION, or nothing at all
# when the file is absent. Deliberately bare: no " (<git describe>)" suffix, so
# two reads taken either side of a pull are comparable. The only place the
# VERSION path and its trim are written.
raw_version() {
  [ -f "$CHOSKO_LLM_HOME/VERSION" ] || return 0
  tr -d '[:space:]' < "$CHOSKO_LLM_HOME/VERSION"
  printf '\n'
}

# resolve_version
# Prints the repo-level version string for the managed clone: raw_version, plus
# " (<git describe>)" when git and a describe value are available. Prints
# "unknown" if VERSION is missing. This is the single source of the version
# format — install.sh and cmd-version.sh both use it so they never drift.
resolve_version() {
  local version gitdesc
  version="$(raw_version)"
  [ -n "$version" ] || version="unknown"
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
# Returns 1 for the two kinds that only make sense in one scope; 0 for every
# other kind/scope combination. The two rules are mirror images:
#   statusline is GLOBAL-only — a status bar belongs to a terminal, not a repo.
#   hook is LOCAL-only — a hook has to reach the agent it governs, and a cloud
#     container clones the repository and nothing else, so a hook wired into a
#     global settings.json can never fire there. Only a project's own committed
#     .claude/ travels.
scope_supports_kind() {
  local kind="$1"
  if scope_is_local && [ "$kind" = statusline ]; then
    return 1
  fi
  if ! scope_is_local && [ "$kind" = hook ]; then
    return 1
  fi
  return 0
}

# scope_violation_message <kind>
# The die message for a kind scope_supports_kind just rejected. Lives here so
# add / rm / update word the two mirrored rules identically.
scope_violation_message() {
  case "$1" in
    statusline) printf 'statusline scripts are global-only. Re-run without --local.' ;;
    hook)       printf 'hooks are local-only — a hook only fires if it is committed to the repository it governs. Re-run with --local from the project root.' ;;
    *)          printf '%s is not supported in %s scope.' "$1" "$CHOSKO_LLM_SCOPE" ;;
  esac
}

# ---------- frontmatter ----------

# _FM_AWK
# The frontmatter scanner, written once and shared by parse_frontmatter (one
# file, every key it finds) and read_frontmatter_table (many files, a fixed
# field list each). Two `mode=` values, one parser: the two entry points differ
# only in what they do with a key, so a second copy of this program would be a
# copy that drifts.
#
# It scans every file to the end rather than exiting at the frontmatter's
# closing `---`, because a multi-file run cannot afford to `exit` on the first
# file. `in_fm` is cleared there instead, so a later `---` block is still
# ignored and the output is unchanged; the cost is reading the rest of a small
# markdown file.
#
# Recognised keys: name, version, type, description, replaces, requires, event,
# matcher.
# `replaces` is optional — see the kind-migration section below.
# `requires` is optional and valid on every kind — see the dependency section
# below. The value is a comma-separated list of kind-prefixed specs, and the
# split below is on the FIRST colon only, so `skill:task-engine` survives it
# intact.
# `event` and `matcher` are read for the hook kind only: `event` names the
# Claude Code hook event to wire the script into (PreToolUse, SessionStart, …)
# and `matcher` optionally narrows it to one tool. Both are ignored on every
# other kind.
_FM_AWK='
  function _flush(   i, out) {
    if (curfile == "") return
    if (mode == "table") {
      out = curfile
      for (i = 1; i <= nf; i++) out = out "\t" ((want[i] in val) ? val[want[i]] : "")
      print out
    }
    curfile = ""
    delete val
  }
  BEGIN { nf = split(fields, want, " ") }
  FNR == 1 { _flush(); curfile = FILENAME; in_fm = 0; seen_open = 0 }
  /^---[[:space:]]*$/ {
    if (!seen_open) { in_fm = 1; seen_open = 1; next }
    else if (in_fm) { in_fm = 0; next }
  }
  in_fm {
    line = $0
    # split on first colon
    idx = index(line, ":")
    if (idx == 0) next
    key = substr(line, 1, idx - 1)
    v = substr(line, idx + 1)
    # trim
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
    # strip optional surrounding quotes
    if (v ~ /^".*"$/ || v ~ /^'\''.*'\''$/) {
      v = substr(v, 2, length(v) - 2)
    }
    if (key == "name" || key == "version" || key == "type" || key == "description" || key == "replaces" || key == "requires" || key == "event" || key == "matcher") {
      if (mode == "print") { print key "=" v }
      else if (!(key in val)) { val[key] = v }
    }
  }
  END { _flush() }
'

# parse_frontmatter <file>
# Emits key=value lines, in file order, for every recognised key the file's
# first frontmatter block declares. Quietly ignores keys it doesn't care about.
parse_frontmatter() {
  local file="$1"
  [ -f "$file" ] || return 1
  awk -v mode=print -v fields="" "$_FM_AWK" "$file"
}

# read_frontmatter_table <field-list> <file>...
# The batch counterpart to read_frontmatter_fields: ONE awk process reads every
# file given and prints one TAB-separated line per file —
#
#   <file> TAB <value-of-field-1> TAB <value-of-field-2> ...
#
# — with an empty value where the key is absent and the first occurrence
# winning where it repeats. <field-list> is a single space-separated string.
#
# It exists because `ls` reads two fields off ~2 files per row, and one awk
# process per file is the dominant cost of the listing on Git Bash for Windows,
# where a fork plus exec runs ~20 ms. Sixty-odd of those are one here.
#
# A file with no lines at all produces no line, so read the output by path
# rather than by position, and default a missing path to empty values.
#
# Every path handed in must exist AND be readable: awk aborts the whole run on
# one that is not, taking every file after it in the list with it, so the
# caller's own `-f` / `-r` guards are what decide whether a file counts. That is
# the price of the batch — one awk per file lost only its own row.
#
# TAB is the field separator, so no requested field's value may contain one:
# a TAB in a non-final value shifts every field after it. (The keys this parses
# are versions and kind-prefixed specs, so this is a documented limit, not a
# live case.) Split the result with parameter expansion, not `read -a`: TAB is
# also IFS whitespace, so `read -a` would collapse two adjacent empty fields
# into one.
read_frontmatter_table() {
  local fields="$1"; shift
  [ $# -gt 0 ] || return 0
  awk -v mode=table -v fields="$fields" "$_FM_AWK" "$@"
}

# read_frontmatter_field <file> <field>
# Convenience: prints just the value of one field, or empty if absent.
read_frontmatter_field() {
  local file="$1" field="$2"
  parse_frontmatter "$file" | awk -F= -v k="$field" '$1 == k { sub(/^[^=]*=/, ""); print; exit }'
}

# read_frontmatter_fields <file> <field>...
# The parse-once counterpart to read_frontmatter_field, for a caller that needs
# two or more fields out of the same frontmatter block. Parses <file> once and
# prints one line per requested field, in the order given: the field's value, or
# an empty line when the key is absent.
#
# It is read_frontmatter_table narrowed to one file, so the two cannot disagree
# about what a field's value is. A caller wanting exactly one field should keep
# using read_frontmatter_field; a caller with a whole list of files should use
# the table directly and pay one awk for all of them.
#
# Read the result with one `read -r` per field, in the same order:
#
#   { IFS= read -r ver; IFS= read -r req; } \
#     < <(read_frontmatter_fields "$f" version requires)
#
# The line count always matches the field count: no frontmatter value can
# contain a newline. A missing file yields empty values rather than an error, so
# the caller's own -f guard stays the thing that decides whether the file counts.
read_frontmatter_fields() {
  local file="$1"; shift
  local row="" rest i
  [ -f "$file" ] && row="$(read_frontmatter_table "$*" "$file")"
  # Drop the leading path field; an empty row leaves every value empty.
  rest="${row#*$'\t'}"
  [ "$rest" = "$row" ] && rest=""
  for ((i = 1; i <= $#; i++)); do
    if [ "$i" -lt "$#" ]; then
      printf '%s\n' "${rest%%$'\t'*}"
      rest="${rest#*$'\t'}"
    else
      printf '%s\n' "$rest"
    fi
  done
}

# ---------- feature resolution ----------

# feature_path_var <outvar> <root> <kind> <name>
# Assembles a feature's file path under <root> and assigns it to the variable
# named <outvar>. Returns non-zero, assigning nothing, for an unknown kind.
# `skill-dir` is the pseudo-kind for a skill's directory rather than its
# SKILL.md.
#
# This is the ONE place a feature's path shape is written; every named helper
# below is a printing wrapper over it. The wrappers are the readable form and
# stay the default. This one exists for callers in a loop: a wrapper has to be
# invoked as `$(...)`, and a command substitution is a fork — ~12 ms on Git Bash
# for Windows, paid twice per row by `ls`.
feature_path_var() {
  case "$3" in
    command)    printf -v "$1" '%s/commands/%s.md'     "$2" "$4" ;;
    skill)      printf -v "$1" '%s/skills/%s/SKILL.md' "$2" "$4" ;;
    skill-dir)  printf -v "$1" '%s/skills/%s'          "$2" "$4" ;;
    claude-md)  printf -v "$1" '%s/claude-md/%s.md'    "$2" "$4" ;;
    statusline) printf -v "$1" '%s/statusline/%s.sh'   "$2" "$4" ;;
    hook)       printf -v "$1" '%s/hooks/%s.sh'        "$2" "$4" ;;
    *) return 1 ;;
  esac
}

# Source paths in the managed clone.
src_command_path()  { local p; feature_path_var p "$CHOSKO_LLM_HOME" command   "$1"; printf '%s' "$p"; }
src_skill_path()    { local p; feature_path_var p "$CHOSKO_LLM_HOME" skill     "$1"; printf '%s' "$p"; }
src_skill_dir()     { local p; feature_path_var p "$CHOSKO_LLM_HOME" skill-dir "$1"; printf '%s' "$p"; }
src_claudemd_path() { local p; feature_path_var p "$CHOSKO_LLM_HOME" claude-md "$1"; printf '%s' "$p"; }
src_statusline_path() { local p; feature_path_var p "$CHOSKO_LLM_HOME" statusline "$1"; printf '%s' "$p"; }
src_hook_path()       { local p; feature_path_var p "$CHOSKO_LLM_HOME" hook       "$1"; printf '%s' "$p"; }

# The repo-level changelog in the managed clone. Not a feature: never copied
# into $CLAUDE_HOME, only read from the clone by `chosko-llm upgrade`.
src_changelog_path() { printf '%s/CHANGELOG.md' "$CHOSKO_LLM_HOME"; }

# Installed paths under CLAUDE_HOME.
inst_command_path() { local p; feature_path_var p "$CLAUDE_HOME" command   "$1"; printf '%s' "$p"; }
inst_skill_path()   { local p; feature_path_var p "$CLAUDE_HOME" skill     "$1"; printf '%s' "$p"; }
inst_skill_dir()    { local p; feature_path_var p "$CLAUDE_HOME" skill-dir "$1"; printf '%s' "$p"; }
inst_statusline_path() { local p; feature_path_var p "$CLAUDE_HOME" statusline "$1"; printf '%s' "$p"; }
inst_hook_path()       { local p; feature_path_var p "$CLAUDE_HOME" hook       "$1"; printf '%s' "$p"; }

# hook_settings_path
# The settings.json a hook's wiring belongs in. Hooks are local-only, so this
# is always <cwd>/.claude/settings.json — the file that travels with the repo.
hook_settings_path() { printf '%s/settings.json' "$CLAUDE_HOME"; }

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

# claudemd_target_path
# Prints the CLAUDE.md file that claude-md artifacts read/write. In global
# scope this is $CLAUDE_HOME/CLAUDE.md (Claude Code's global instructions
# file). In local scope, $CLAUDE_HOME is <cwd>/.claude (where commands and
# skills go), but a project's CLAUDE.md lives at the project root, one
# directory up — so claude-md sections target <cwd>/CLAUDE.md instead.
claudemd_target_path() { local p; claudemd_target_path_var p; printf '%s' "$p"; }

# claudemd_target_path_var <outvar>
# claudemd_target_path assigned to a named variable instead of printed — the
# same fork-free form, and for the same reason, as feature_path_var above. The
# local-scope parent directory is taken with parameter expansion rather than
# `dirname`, which would put an exec back in.
claudemd_target_path_var() {
  if scope_is_local; then
    printf -v "$1" '%s/CLAUDE.md' "${CLAUDE_HOME%/*}"
  else
    printf -v "$1" '%s/CLAUDE.md' "$CLAUDE_HOME"
  fi
}

# claudemd_is_installed <name>
# Returns 0 if a managed section for <name> exists in claudemd_target_path.
claudemd_is_installed() {
  local name="$1" target
  claudemd_target_path_var target
  [ -f "$target" ] && grep -qF "<!-- chosko-llm:${name}:begin" "$target"
}

# claudemd_installed_version <name>
# Prints the version recorded in the begin tag, or empty if not installed.
claudemd_installed_version() {
  local name="$1" target
  target="$(claudemd_target_path)"
  [ -f "$target" ] || return 0
  grep "<!-- chosko-llm:${name}:begin" "$target" 2>/dev/null \
    | sed 's/.*:begin v\([^ ]*\) -->.*/\1/' | head -1
}

# inject_section <name> <version> <src_file>
# Inserts or replaces the named managed section in claudemd_target_path.
# Body is the content of <src_file> after its frontmatter closing ---.
inject_section() {
  local name="$1" version="$2" src_file="$3"
  local target
  target="$(claudemd_target_path)"
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
# Removes a managed section from claudemd_target_path.
remove_section() {
  local name="$1" target
  target="$(claudemd_target_path)"
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

# hook_wiring_label <event> <matcher>
# Human-readable name for the settings.json slot a hook occupies, e.g.
# "hooks.PreToolUse[matcher=AskUserQuestion]" or "hooks.SessionStart" when the
# feature declares no matcher. Used to name the OLD slot when an update moves
# a hook, since that entry has to be removed by hand.
hook_wiring_label() {
  local event="$1" matcher="$2"
  if [ -n "$matcher" ]; then
    printf 'hooks.%s[matcher=%s]' "$event" "$matcher"
  else
    printf 'hooks.%s' "$event"
  fi
}

# print_hook_prompt <name> <src_file>
# Prints a copy-pasteable prompt for a Claude Code session to safely merge this
# hook into the project's settings.json. Same reasoning as the statusline
# prompt: settings.json's shape isn't ours to own, and merging into a nested
# array of existing hooks is exactly the job we refuse to do in awk.
#
# The wired command deliberately uses $CLAUDE_PROJECT_DIR rather than the
# absolute install path — settings.json is committed and travels to other
# machines and to cloud containers, where an absolute local path would be wrong.
print_hook_prompt() {
  local name="$1" src_file="$2" event matcher settings entry
  event="$(read_frontmatter_field "$src_file" event || true)"
  matcher="$(read_frontmatter_field "$src_file" matcher || true)"
  settings="$(hook_settings_path)"

  if [ -n "$matcher" ]; then
    entry="the {\"matcher\":\"$matcher\"} entry of the hooks.$event array"
  else
    entry="a matcher-less entry of the hooks.$event array"
  fi

  cat <<EOF

To activate '$name', open a Claude Code session in this project and paste this prompt:

  Update $settings: add
  {"type":"command","command":"\$CLAUDE_PROJECT_DIR/.claude/hooks/$name.sh"}
  to $entry, creating "hooks", the "$event" array, or that entry if any of them
  are absent. Preserve every other key in the file and every hook already wired.

Then commit both $settings and the script: hooks are read from the
repository, so an uncommitted hook never reaches a cloud session. Claude Code
snapshots hook config at session start — restart the session to pick it up.
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
# Accepts: "<name>", "command:<name>", "skill:<name>", "claude-md:<name>",
# "statusline:<name>", "hook:<name>".
# Prints two lines on stdout: kind\nname.
# Errors out if ambiguous or not found in the managed clone.
resolve_feature() {
  local spec="$1"
  local prefix="" name="$spec"
  case "$spec" in
    command:*)    prefix=command;    name="${spec#command:}"    ;;
    skill:*)      prefix=skill;      name="${spec#skill:}"      ;;
    claude-md:*)  prefix=claude-md;  name="${spec#claude-md:}"  ;;
    statusline:*) prefix=statusline; name="${spec#statusline:}" ;;
    hook:*)       prefix=hook;       name="${spec#hook:}"       ;;
  esac

  if [ -n "$prefix" ]; then
    case "$prefix" in
      command)    [ -f "$(src_command_path    "$name")" ] || die "No such command in managed clone: $name" ;;
      skill)      [ -f "$(src_skill_path      "$name")" ] || die "No such skill in managed clone: $name"   ;;
      claude-md)  [ -f "$(src_claudemd_path   "$name")" ] || die "No such claude-md in managed clone: $name" ;;
      statusline) [ -f "$(src_statusline_path "$name")" ] || die "No such statusline in managed clone: $name" ;;
      hook)       [ -f "$(src_hook_path       "$name")" ] || die "No such hook in managed clone: $name" ;;
    esac
    printf '%s\n%s\n' "$prefix" "$name"
    return 0
  fi

  local has_cmd=0 has_skill=0 has_cm=0 has_sl=0 has_hook=0
  [ -f "$(src_command_path    "$name")" ] && has_cmd=1
  [ -f "$(src_skill_path      "$name")" ] && has_skill=1
  [ -f "$(src_claudemd_path   "$name")" ] && has_cm=1
  [ -f "$(src_statusline_path "$name")" ] && has_sl=1
  [ -f "$(src_hook_path       "$name")" ] && has_hook=1
  local total=$(( has_cmd + has_skill + has_cm + has_sl + has_hook ))
  if   [ $total -gt 1 ];    then die "Feature name '$name' is ambiguous. Disambiguate with 'command:$name', 'skill:$name', 'claude-md:$name', 'statusline:$name', or 'hook:$name'."
  elif [ $has_cmd -eq 1 ];  then printf 'command\n%s\n'   "$name"
  elif [ $has_skill -eq 1 ]; then printf 'skill\n%s\n'    "$name"
  elif [ $has_cm -eq 1 ];   then printf 'claude-md\n%s\n' "$name"
  elif [ $has_sl -eq 1 ];   then printf 'statusline\n%s\n' "$name"
  elif [ $has_hook -eq 1 ]; then printf 'hook\n%s\n'      "$name"
  else die "No feature named '$name' found in $CHOSKO_LLM_HOME (commands/, skills/, claude-md/, statusline/, or hooks/)."
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
    hook)       src_hook_path       "$2" ;;
    *) return 1 ;;
  esac
}

# split_kind_spec <kind-outvar> <name-outvar> <spec>
# Splits a kind-prefixed spec ("command:foo") into the two named variables.
# Returns non-zero, assigning nothing, if the spec carries no recognized kind
# prefix. The fork-free form of parse_replaces_spec, which is a printing wrapper
# over it — same relationship, and same reason, as feature_path_var above.
split_kind_spec() {
  case "$3" in
    command:*)    printf -v "$1" 'command'    ; printf -v "$2" '%s' "${3#command:}"    ;;
    skill:*)      printf -v "$1" 'skill'      ; printf -v "$2" '%s' "${3#skill:}"      ;;
    claude-md:*)  printf -v "$1" 'claude-md'  ; printf -v "$2" '%s' "${3#claude-md:}"  ;;
    statusline:*) printf -v "$1" 'statusline' ; printf -v "$2" '%s' "${3#statusline:}" ;;
    hook:*)       printf -v "$1" 'hook'       ; printf -v "$2" '%s' "${3#hook:}"       ;;
    *) return 1 ;;
  esac
}

# parse_replaces_spec <spec>
# Splits a kind-prefixed spec ("command:foo") into two lines: kind\nname.
# Returns non-zero if the spec carries no recognized kind prefix.
parse_replaces_spec() {
  local k n
  split_kind_spec k n "$1" || return 1
  printf '%s\n%s\n' "$k" "$n"
}

# artifact_is_installed <kind> <name>
# Returns 0 if an artifact of that kind/name exists under $CLAUDE_HOME.
artifact_is_installed() {
  local p
  case "$1" in
    command)    feature_path_var p "$CLAUDE_HOME" command    "$2" && [ -f "$p" ] ;;
    skill)      feature_path_var p "$CLAUDE_HOME" skill-dir  "$2" && [ -d "$p" ] ;;
    claude-md)  claudemd_is_installed "$2" ;;
    statusline) feature_path_var p "$CLAUDE_HOME" statusline "$2" && [ -f "$p" ] ;;
    hook)       feature_path_var p "$CLAUDE_HOME" hook       "$2" && [ -f "$p" ] ;;
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
    hook)       rm -f  "$(inst_hook_path       "$2")" ;;
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

# The `replaces:` index — built at most once per process, on first use, and read
# by both migration probes below.
#
# It exists because the probes' old shape rescanned the whole clone per call:
# every source file, two awk processes each, for a declaration only a couple of
# features ever carry. `ls` runs a probe on every local-only and every
# not-installed row, so a clone of N features cost O(N) processes per row and
# O(N²) for the listing. One awk pass now answers both probes for every row.
#
# No state file, per this repo's rules: the index lives in the process and dies
# with it. It maps only the managed clone, which no command mutates while it
# runs. The installed side — which add / rm / update do mutate — is deliberately
# NOT cached; artifact_is_installed still asks the filesystem every time.
_REPLACES_INDEX_BUILT=0
declare -A _REPLACES_BY_FILE=()    # clone source path -> its `replaces:` value
declare -A _REPLACES_CLAIMED_BY=() # "<old-kind>:<old-name>" -> "<kind>:<name>"

_build_replaces_index() {
  [ "$_REPLACES_INDEX_BUILT" -eq 1 ] && return 0
  _REPLACES_INDEX_BUILT=1

  # Kind order below matches find_replacement's original scan order, and within
  # a kind the glob is lexical, so "the first feature to claim it wins" resolves
  # to exactly the same feature it always did. The `-r` beside each `-f` is what
  # keeps one unreadable file from aborting the single awk and emptying the
  # whole index — it is skipped instead, which is what the old per-file read did
  # with it anyway.
  local files=() owners=() f n d
  for f in "$CHOSKO_LLM_HOME"/commands/*.md; do
    [ -f "$f" ] && [ -r "$f" ] || continue
    n="${f##*/}"; files+=("$f"); owners+=("command:${n%.md}")
  done
  for f in "$CHOSKO_LLM_HOME"/skills/*/SKILL.md; do
    [ -f "$f" ] && [ -r "$f" ] || continue
    d="${f%/SKILL.md}"; files+=("$f"); owners+=("skill:${d##*/}")
  done
  for f in "$CHOSKO_LLM_HOME"/claude-md/*.md; do
    [ -f "$f" ] && [ -r "$f" ] || continue
    n="${f##*/}"; files+=("$f"); owners+=("claude-md:${n%.md}")
  done
  for f in "$CHOSKO_LLM_HOME"/statusline/*.sh; do
    [ -f "$f" ] && [ -r "$f" ] || continue
    n="${f##*/}"; files+=("$f"); owners+=("statusline:${n%.sh}")
  done
  for f in "$CHOSKO_LLM_HOME"/hooks/*.sh; do
    [ -f "$f" ] && [ -r "$f" ] || continue
    n="${f##*/}"; files+=("$f"); owners+=("hook:${n%.sh}")
  done
  [ ${#files[@]} -gt 0 ] || return 0

  local line path spec i
  while IFS= read -r line; do
    path="${line%%$'\t'*}"
    spec="${line#*$'\t'}"
    [ "$spec" = "$line" ] && spec=""
    _REPLACES_BY_FILE["$path"]="$spec"
  done < <(read_frontmatter_table replaces "${files[@]}")

  for ((i = 0; i < ${#files[@]}; i++)); do
    spec="${_REPLACES_BY_FILE[${files[i]}]:-}"
    [ -n "$spec" ] || continue
    [ -n "${_REPLACES_CLAIMED_BY[$spec]:-}" ] || _REPLACES_CLAIMED_BY["$spec"]="${owners[i]}"
  done
}

# find_replacement <old-kind> <old-name>
# Answers which feature in the managed clone declares `replaces:
# <old-kind>:<old-name>`. Prints "<kind>\n<name>" on the first claimant; prints
# nothing and returns 1 when no feature claims it.
find_replacement() {
  _build_replaces_index
  local hit="${_REPLACES_CLAIMED_BY["$1:$2"]:-}"
  [ -n "$hit" ] || return 1
  printf '%s\n%s\n' "${hit%%:*}" "${hit#*:}"
}

# check_migration_pending <kind> <name>
# For a clone feature not yet installed, checks whether its own `replaces:`
# declaration names an artifact that is currently installed — meaning a
# plain `add` would leave two artifacts side by side instead of completing
# a kind migration. Prints "<old-kind>\n<old-name>" and returns 0 on a hit;
# returns 1 with no output otherwise. Companion to `find_replacement`, which
# answers the same question from the other side (an installed, source-less
# artifact asking "am I superseded?").
check_migration_pending() {
  local kind="$1" name="$2" src spec old_kind old_name
  feature_path_var src "$CHOSKO_LLM_HOME" "$kind" "$name" || return 1
  _build_replaces_index
  spec="${_REPLACES_BY_FILE[$src]:-}"
  [ -n "$spec" ] || return 1
  split_kind_spec old_kind old_name "$spec" || return 1
  [ -n "$old_kind" ] && [ -n "$old_name" ] || return 1
  artifact_is_installed "$old_kind" "$old_name" || return 1
  printf '%s\n%s\n' "$old_kind" "$old_name"
}

# ---------- dependencies (`requires:`) ----------
# A feature whose body reads a file inside another installed feature declares
# that feature in its frontmatter:
#
#   requires: skill:task-engine
#   requires: skill:task-engine, command:task-add
#
# `cmd-add` installs what a feature names before installing the feature;
# `cmd-rm` refuses to remove a feature something installed still requires.
# Resolution is one level deep, unversioned and non-transitive — a flat
# declaration, never a dependency graph. See docs/authoring-guide.md.

# requires_specs <file>
# Prints one kind-prefixed spec per line, one per comma-separated entry of
# <file>'s optional `requires:` value; whitespace around the commas and around
# the kind colon is tolerated and empty entries are dropped. Each entry is
# validated with `parse_replaces_spec` — deliberately the same kind-prefix
# parser `replaces:` uses, not a second one; the whitespace is squeezed out
# first so that parser never has to learn about it, and so a stray space cannot
# turn into a requirement name nothing can resolve. Prints nothing and returns
# 0 when the key is absent or empty.
#
# An entry with no recognised kind prefix is a hard error, not a silent skip:
# the whole point of the key is to catch a dangling reference at install time
# rather than mid-run, and a typo that parses to nothing would defeat that. It
# therefore `die`s — so call it through a command substitution
# (`specs="$(requires_specs "$f")" || exit 1`), never a process substitution,
# where the `die` would only kill the subshell and leave the caller running.
# The raw value is re-read only on the die path, so the happy path parses the
# frontmatter exactly once — inside the lenient sibling — rather than twice.
requires_specs() {
  local file="$1" state entry
  while IFS=$'\t' read -r state entry; do
    [ "$state" = ok ] \
      || die "Malformed 'requires: $(read_frontmatter_field "$file" requires)' in $file — entry '$entry' has no kind prefix (expected command:, skill:, claude-md:, statusline: or hook:)."
    printf '%s\n' "$entry"
  done < <(requires_specs_lenient "$file")
}

# requires_specs_lenient <file>
# The non-fatal sibling of requires_specs — requires_specs is a strict filter
# over this. Reads <file>'s `requires:` value and hands it to
# requires_specs_from_value, so it prints one TAB-separated line per non-empty
# entry: "ok<TAB><spec>" for an entry carrying a recognised kind prefix,
# "bad<TAB><entry>" for one that does not. Prints nothing and returns 0 when the
# key is absent or empty.
#
# It exists for read-only consumers — `ls` renders a REQUIRES column and must
# not be taken down by one typo in one unrelated feature. Install- and
# removal-time callers (`cmd-add`, `cmd-rm`) keep using requires_specs and keep
# dying on a malformed entry: that is where a dangling reference has to be
# caught. Never route those through this function.
requires_specs_lenient() {
  local file="$1" raw
  raw="$(read_frontmatter_field "$file" requires || true)"
  requires_specs_from_value "$raw"
}

# requires_specs_from_value <value>
# The one place a raw `requires:` value is split and trimmed: whitespace around
# the commas and around the kind colon is tolerated and empty entries are
# dropped. Output is requires_specs_lenient's, described above; this is that
# function with the frontmatter read lifted out.
#
# It takes the value rather than a path so a caller that has already parsed the
# file's frontmatter for another field can classify the specs without parsing it
# a second time — which is what `ls` does, once per row.
#
# The split and both trims are parameter expansion, not an awk: this runs once
# per listed feature, and a process per row is the kind of cost that is
# invisible in a unit test and plainly visible in `ls` on Git Bash for Windows,
# where a fork plus exec runs ~20 ms. The three steps are the awk substitutions
# that preceded them, in the same order — leading space, trailing space, then
# the FIRST colon's surroundings, which is why the last one splits on `%%`/`#`
# rather than touching every colon.
requires_specs_from_value() {
  requires_specs_from_value_into "${1:-}"
  [ ${#REQUIRES_SPECS[@]} -gt 0 ] || return 0
  printf '%s\n' "${REQUIRES_SPECS[@]}"
}

# requires_specs_from_value_into <value>
# requires_specs_from_value delivered in the global array REQUIRES_SPECS — one
# "<state><TAB><spec>" element per non-empty entry — instead of on stdout. This
# is the authority; the printing sibling above formats what it leaves behind.
#
# A global array rather than a pipe for the same reason as feature_path_var: a
# caller reading lines out of this in a loop would need a process substitution,
# and `ls` calls it once per row. `resolve_scope`/`SCOPE_ARGS` set the
# precedent for returning an array this way.
REQUIRES_SPECS=()
requires_specs_from_value_into() {
  local raw="${1:-}" rest entry k v __k __n
  REQUIRES_SPECS=()
  [ -n "$raw" ] || return 0
  rest="$raw"
  while [ -n "$rest" ]; do
    case "$rest" in
      *,*) entry="${rest%%,*}"; rest="${rest#*,}" ;;
      *)   entry="$rest"; rest="" ;;
    esac
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    [ -n "$entry" ] || continue
    case "$entry" in
      *:*)
        k="${entry%%:*}"; v="${entry#*:}"
        k="${k%"${k##*[![:space:]]}"}"
        v="${v#"${v%%[![:space:]]*}"}"
        entry="$k:$v"
        ;;
    esac
    if split_kind_spec __k __n "$entry"; then
      REQUIRES_SPECS+=($'ok\t'"$entry")
    else
      REQUIRES_SPECS+=($'bad\t'"$entry")
    fi
  done
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

# ---------- changelog ----------

# _render_bullet_markup <text> <bold> <code> <reset>
# Rewrites the two inline markups a CHANGELOG bullet uses — **bold** and
# `code` — to <bold>...<reset> and <code>...<reset>, leaving the rest alone and
# putting the result in _BULLET_MARKUP_OUT. With the colours empty the markers
# are stripped, so a no-colour stream never prints a literal "**" or backtick
# that the markup itself put there.
#
# The scan is a single left-to-right pass over both delimiters rather than one
# pass each, which is what keeps a marker quoted inside the other markup intact:
# in "strips the `**` markers" the backtick opens first, so the "**" it wraps is
# span text and never reads as a bold delimiter. An unpaired marker of either
# kind is left exactly as the source wrote it, and a genuinely nested span is
# not a case the changelog has: whichever marker opens first owns the span, and
# the inner markers stay literal.
#
# The result comes back in a variable rather than on stdout because a command
# substitution forks a subshell per bullet, and this runs once per bullet of
# every section a range readout prints.
_render_bullet_markup() {
  local text="$1" bold="$2" code="$3" reset="$4" out='' head span bi ci
  while :; do
    bi=-1; ci=-1
    [ "${text#*\*\*}" != "$text" ] && { head="${text%%\*\**}"; bi=${#head}; }
    [ "${text#*\`}"   != "$text" ] && { head="${text%%\`*}";   ci=${#head}; }
    if [ "$bi" -ge 0 ] && { [ "$ci" -lt 0 ] || [ "$bi" -lt "$ci" ]; }; then
      head="${text:0:bi}"
      text="${text:bi+2}"
      if [ "${text#*\*\*}" = "$text" ]; then
        out="$out$head**$text"
        text=''
        break
      fi
      span="${text%%\*\**}"
      text="${text#*\*\*}"
      out="$out$head$bold$span$reset"
    elif [ "$ci" -ge 0 ]; then
      head="${text:0:ci}"
      text="${text:ci+1}"
      if [ "${text#*\`}" = "$text" ]; then
        out="$out$head\`$text"
        text=''
        break
      fi
      span="${text%%\`*}"
      text="${text#*\`}"
      out="$out$head$code$span$reset"
    else
      break
    fi
  done
  _BULLET_MARKUP_OUT="$out$text"
}

# _render_changelog_sections <body> <fd> <color-predicate>
# The single formatter for CHANGELOG.md sections. Writes <body> — raw section
# text, headers and bullets — to file descriptor <fd> in the shared layout:
# two-space version indent, four-space bullet indent, a blank line between
# sections and one after the block.
#
# The palette follows the one `ls` and `show` already use, so a version number
# reads the same colour wherever it appears: the version bright green, its
# " — <date>" dim, the bullet's leading ASCII "- " marker dim, the bullet's
# **Subject** bright cyan, any `code` span yellow and the prose between them
# default. The marker is deliberately the quietest thing on the line — it
# repeats on every bullet, so colour spent on it is colour that stops the
# subject from standing out. An unrecognised line inside a section is passed
# through indented and uncoloured rather than dropped.
#
# <color-predicate> is the NAME of a function returning 0 when colour applies to
# the stream this block is going to: `_use_color` for stderr, a caller-captured
# stdout predicate for stdout. It is a parameter and not read off <fd> on
# purpose — `changelog --since` may hand its output to a pager, at which point
# fd 1 is a pipe, and gating on that would silently strip every escape.
#
# Both callers — print_changelog_range below (stderr, from `upgrade`) and
# cmd-changelog.sh (stdout, from `changelog --since`) — go through here, so the
# two presentations cannot drift apart. Only the gate differs.
_render_changelog_sections() {
  local body="$1" fd="$2" color_fn="$3"
  local line rest version remainder first=1 _BULLET_MARKUP_OUT=''
  local ver='' dim='' subject='' code='' reset=''

  if "$color_fn"; then
    ver=$'\033[1;32m'; dim=$'\033[2m'; subject=$'\033[1;36m'
    code=$'\033[33m'; reset=$'\033[0m'
  fi

  while IFS= read -r line; do
    case "$line" in
      '## '*)
        rest="${line#\#\# }"
        version="${rest%%[[:space:]]*}"
        remainder="${rest#"$version"}"
        [ "$first" -eq 1 ] || printf '\n' >&"$fd"
        first=0
        printf '  %s%s%s%s%s%s\n' "$ver" "$version" "$reset" "$dim" "$remainder" "$reset" >&"$fd"
        ;;
      # The marker stays ASCII: colour the two characters the source bullet
      # already begins with rather than substituting a glyph that can mangle in
      # a legacy codepage console.
      '- '*)
        _render_bullet_markup "${line#- }" "$subject" "$code" "$reset"
        printf '    %s- %s%s\n' "$dim" "$reset" "$_BULLET_MARKUP_OUT" >&"$fd"
        ;;
      '')
        ;;
      *)
        printf '    %s\n' "$line" >&"$fd"
        ;;
    esac
  done <<< "$body"

  printf '\n' >&"$fd"
}

# changelog_since_kind <value>
# Classifies a `changelog --since` value into one of three disjoint forms and
# prints it: "version" (1.10.0), "date" (2026-08-01), or "duration" (30d / 2w /
# 6mo / 1y). Returns 1, printing nothing, when the value is none of them. The
# shapes cannot collide, which is why --since auto-detects instead of carrying
# one flag per form.
changelog_since_kind() {
  local value="${1:-}"
  if printf '%s' "$value" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    printf 'version\n'
  elif printf '%s' "$value" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    printf 'date\n'
  elif printf '%s' "$value" | grep -Eq '^[0-9]+(d|w|mo|y)$'; then
    printf 'duration\n'
  else
    return 1
  fi
}

# changelog_duration_to_date <duration>
# Resolves 30d / 2w / 6mo / 1y to the YYYY-MM-DD that many units before today.
# GNU `date -d` first, BSD `date -v` second, and a pure-awk civil-calendar
# conversion last, so a shell with neither still answers — no new dependency for
# date maths. The awk fallback approximates a month as 30 days and a year as
# 365; the two `date` paths do real calendar arithmetic. Returns 1 when even
# `date +%Y-%m-%d` is unavailable.
changelog_duration_to_date() {
  local duration="${1:-}" n unit word days out today
  n="${duration%%[!0-9]*}"
  unit="${duration#"$n"}"
  case "$unit" in
    d)  word=days   ; days=$((n))      ;;
    w)  word=weeks  ; days=$((n * 7))  ;;
    mo) word=months ; days=$((n * 30)) ;;
    y)  word=years  ; days=$((n * 365));;
    *)  return 1 ;;
  esac

  if out="$(date -d "-$n $word" +%Y-%m-%d 2>/dev/null)" && [ -n "$out" ]; then
    printf '%s\n' "$out"
    return 0
  fi
  case "$unit" in
    d)  out="-${n}d" ;;
    w)  out="-${n}w" ;;
    mo) out="-${n}m" ;;
    y)  out="-${n}y" ;;
  esac
  if out="$(date -v"$out" +%Y-%m-%d 2>/dev/null)" && [ -n "$out" ]; then
    printf '%s\n' "$out"
    return 0
  fi

  today="$(date +%Y-%m-%d 2>/dev/null || true)"
  [ -n "$today" ] || return 1
  awk -v today="$today" -v back="$days" '
    function days_from_civil(y, m, d,   era, yoe, doy, doe) {
      if (m <= 2) y -= 1
      era = int((y >= 0 ? y : y - 399) / 400)
      yoe = y - era * 400
      doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
      doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
      return era * 146097 + doe - 719468
    }
    function civil_from_days(z,   era, doe, yoe, y, doy, mp, d, m) {
      z += 719468
      era = int((z >= 0 ? z : z - 146096) / 146097)
      doe = z - era * 146097
      yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
      y = yoe + era * 400
      doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
      mp = int((5 * doy + 2) / 153)
      d = doy - int((153 * mp + 2) / 5) + 1
      m = mp + (mp < 10 ? 3 : -9)
      if (m <= 2) y += 1
      return sprintf("%04d-%02d-%02d", y, m, d)
    }
    BEGIN {
      split(today, t, "-")
      print civil_from_days(days_from_civil(t[1] + 0, t[2] + 0, t[3] + 0) - back)
    }
  '
}

# select_changelog_sections <kind> <value>
# Prints the CHANGELOG.md sections a `changelog --since` selection covers,
# verbatim, on stdout — headers and bodies, never the preamble above the first
# `## `. <kind> is either:
#   version — every section from the newest down to and INCLUDING the one whose
#             header token is <value>. Inclusive on purpose, unlike
#             print_changelog_range's exclusive old bound: "since 1.10.0" reads
#             as "1.10.0 and everything after", whereas an upgrading user
#             already had the version they came from.
#   date    — every section whose header carries a date on or after <value>.
#             Plain string comparison of YYYY-MM-DD is enough, and the whole
#             file is scanned rather than a prefix: the file is ordered by
#             descending semver, which the merge in this repo's history makes
#             non-chronological in one place.
# Returns 1, printing nothing, when the file is missing or nothing matched. A
# selection that matches nothing is not an error — the caller says so and exits
# 0.
select_changelog_sections() {
  local kind="${1:-}" value="${2:-}" file
  file="$(src_changelog_path)"
  [ -f "$file" ] || return 1

  case "$kind" in
    version)
      awk -v v="$value" '
        /^## / {
          if (stop) halted = 1
          started = 1
          if (!halted && $2 == v) { found = 1; stop = 1 }
        }
        started && !halted { buf[++n] = $0 }
        END {
          if (!found) exit 1
          for (i = 1; i <= n; i++) print buf[i]
        }
      ' "$file" 2>/dev/null
      ;;
    date)
      awk -v since="$value" '
        /^## / {
          keep = 0
          if (match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) &&
              substr($0, RSTART, RLENGTH) >= since) { keep = 1; found = 1 }
        }
        keep { buf[++n] = $0 }
        END {
          if (!found) exit 1
          for (i = 1; i <= n; i++) print buf[i]
        }
      ' "$file" 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

# terminal_height
# Prints the terminal's line count: $LINES, else `tput lines`, else 24. Used to
# decide whether a rendered block fits one screen. Falls back to a constant
# rather than taking a dependency — `tput` is absent often enough on the bare
# git-bash this CLI's primary platform ships.
terminal_height() {
  local h="${LINES:-}"
  if [ -z "$h" ] && command -v tput >/dev/null 2>&1; then
    h="$(tput lines 2>/dev/null || true)"
  fi
  case "$h" in
    ''|*[!0-9]*) h=24 ;;
  esac
  printf '%s\n' "$h"
}

# print_changelog_range <old-version> <new-version>
# Writes the CHANGELOG.md sections for the versions between two VERSION values
# to stderr: from <new-version>'s header inclusive, down to but excluding
# <old-version>'s. The file is descending semver, so that is a single forward
# scan. Returns 0 when at least one section was printed, 1 otherwise — the
# caller uses that to decide whether to fall back to a raw commit list.
#
# Degrades, never fails: a missing, malformed or unreadable CHANGELOG.md costs
# the reader their release notes and nothing else. A line inside a section that
# is neither a header nor a bullet is passed through indented and uncoloured
# rather than dropped.
#
# Colour is gated on _use_color (stderr), not the C_* variables (stdout).
print_changelog_range() {
  local old_version="${1:-}" new_version="${2:-}"
  local file body rc=0

  file="$(src_changelog_path)"
  # A clone predating this feature has no changelog. Say nothing.
  [ -f "$file" ] || return 1

  if [ -z "$new_version" ]; then
    log_info "Could not read VERSION in $CHOSKO_LLM_HOME — skipping the changelog readout."
    return 1
  fi
  # Nothing moved: the caller's commit list is the whole story.
  if [ "$old_version" = "$new_version" ]; then
    return 1
  fi

  # Single forward scan. Buffered so the END block can tell "old header found"
  # (print the whole range) from "old header missing" (print only the newest
  # section, so an unknown prior version cannot dump the entire file).
  # Exit codes: 10 = no header for the new version, 11 = none for the old,
  # 12 = empty range (old sits at or above new — a downgrade or channel switch).
  body="$(awk -v old="$old_version" -v new="$new_version" '
    /^## / {
      if ($2 == new)      { found_new = 1; if (!seen_old) { keep = 1; nsec++ } }
      else if ($2 == old) { found_old = 1; seen_old = 1; keep = 0 }
      else if (keep)      { nsec++ }
    }
    keep { buf[++n] = $0; sect[n] = nsec }
    END {
      if (!found_new) exit 10
      if (n == 0) exit 12
      for (i = 1; i <= n; i++) {
        if (!found_old && sect[i] > 1) break
        print buf[i]
      }
      if (!found_old) exit 11
    }
  ' "$file" 2>/dev/null)" || rc=$?

  case "$rc" in
    0|11) ;;
    10) log_info "CHANGELOG.md has no section for $new_version."; return 1 ;;
    *) return 1 ;;
  esac

  if [ -n "$old_version" ]; then
    log_info "What changed since $old_version → $new_version"
  else
    log_info "What changed in $new_version"
  fi
  printf '\n' >&2

  # Layout and colour both live in the shared renderer. This caller writes to
  # stderr, so it gates on _use_color — the C_* variables are gated on stdout
  # being a TTY and would be the wrong tool here.
  _render_changelog_sections "$body" 2 _use_color

  if [ "$rc" -eq 11 ]; then
    log_info "CHANGELOG.md has no section for ${old_version:-the previous version} — showing only $new_version."
  fi
  return 0
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

# require_hook_source <file>
# Extra validation for the hook kind on top of require_versioned_source: the
# wiring prompt can only name an event it was told about, so a hook without
# `event` is unwireable and refused rather than half-installed.
require_hook_source() {
  local file="$1" event
  event="$(read_frontmatter_field "$file" event || true)"
  [ -n "$event" ] || die "Refusing to install: $file is missing an 'event' field in its frontmatter (e.g. 'event: PreToolUse')."
}
