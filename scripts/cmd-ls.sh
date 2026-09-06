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

  (no flag)     List all known features with installed and latest versions,
                status, and the 'requires:' specs each one declares.
  --installed   Show only features that are currently installed.
  --available   Show only features that exist in the managed clone.
  --local       List <cwd>/.claude instead of \$CLAUDE_HOME. Requires
                <cwd>/CLAUDE.md to exist. Omits statusline scripts, which
                are global-only.
  --global      List \$CLAUDE_HOME (default). Omits hooks, which are
                local-only.
EOF
    exit 0
    ;;
  *) die "Unknown flag for ls: $1" ;;
esac

# STATUS is padded to 18 — one wider than the longest value, "migration
# pending" — so REQUIRES can be the final, unpadded column: a long list of
# specs then runs off the right edge instead of shifting anything, and never
# needs truncating.
STATUS_WIDTH=18

print_header() {
  printf '%s%-30s %-8s %-14s %-16s %-*s %s%s\n' \
    "$C_BOLD" "NAME" "KIND" "INSTALLED" "LATEST" "$STATUS_WIDTH" "STATUS" "REQUIRES" "$C_RESET"
}

# ---------- the fork budget ----------
# This listing renders one row per feature, and on Git Bash for Windows — the
# CLI's primary platform — a fork costs ~12 ms and a fork plus exec ~20 ms. A
# helper invoked as `$(...)` or read through `< <(...)` is therefore not free at
# this scale: at ~34 features, the per-row command substitutions and one awk per
# frontmatter file were the whole of a five-second `ls`.
#
# So everything below that runs per row appends to a variable instead of
# printing into a command substitution, and every frontmatter file the listing
# needs is parsed by ONE awk (`read_frontmatter_table`) before rendering starts.
# Keep it that way: a `$(...)` added inside one of these loops costs a
# measurable fraction of the whole command.

# ROW is the row currently being assembled. _colored_cell and _requires_cell
# append to it; list_all clears it before each row and pushes it when done.
ROW=""

# Append a colored, right-padded cell to ROW. ANSI codes don't count toward
# field width, so we pad manually using the visible (plain-text) length of the
# value.
# Usage: _colored_cell COLOR TEXT RESET WIDTH SEPARATOR
_colored_cell() {
  local color="$1" text="$2" reset="$3" width="$4" sep="${5:- }"
  local pad=$(( width - ${#text} ))
  [ $pad -lt 0 ] && pad=0
  printf -v ROW '%s%s%s%s%*s%s' "$ROW" "$color" "$text" "$reset" "$pad" "" "$sep"
}

# _requires_cell <requires-value>
# Appends the final, unpadded REQUIRES cell to ROW: the feature's kind-prefixed
# specs exactly as declared, comma-separated, or a dimmed em dash when it
# declares none.
#
# It takes the raw `requires:` value, not a path, because the render loop has
# already parsed that file's frontmatter for its version column and can hand the
# second field over for free — reading the file again in here parsed it twice
# per row on a listing that runs one row per feature.
#
# Which file the value came from is the caller's choice, and every row makes the
# same one as the LATEST column: the source file's value when that file exists,
# the installed file's otherwise. So the cell answers what the feature will
# require after an `update`, and still gives a not-installed row its
# dependencies before `add`. A source file that exists but declares nothing
# renders the em dash rather than falling back — the source is the answer, and
# it said "none". A claude-md row has only a source value to offer:
# `inject_section` strips frontmatter, so an installed claude-md section carries
# no `requires:` to fall back to.
#
# An entry with no kind prefix is printed raw and dimmed rather than aborting
# the listing — hence `requires_specs_from_value_into` and not `requires_specs`.
# `ls` is a read-only lister; `add` and `rm` are where a malformed entry stays
# fatal.
_requires_cell() {
  local raw="$1" spec state entry out=""
  if [ -n "$raw" ]; then
    requires_specs_from_value_into "$raw"
    for spec in ${REQUIRES_SPECS[@]+"${REQUIRES_SPECS[@]}"}; do
      state="${spec%%$'\t'*}"
      entry="${spec#*$'\t'}"
      [ -n "$out" ] && out+=", "
      if [ "$state" = ok ]; then
        out+="$entry"
      else
        out+="$C_DIM$entry$C_RESET"
      fi
    done
  fi
  if [ -n "$out" ]; then
    ROW+="$out"
  else
    # Braces required: bash 3.2 folds the multibyte em dash into the name.
    ROW+="${C_DIM}—${C_RESET}"
  fi
}

# Kind rank — the tie-break when two rows share a feature name, so a
# superseded / migration pending pair stays adjacent and in the order the
# migration reads (the artifact being replaced first, its replacement next).
KIND_RANK_COMMAND=1
KIND_RANK_SKILL=2
KIND_RANK_CLAUDEMD=3
KIND_RANK_STATUSLINE=4
KIND_RANK_HOOK=5

# ---------- the managed CLAUDE.md, read once ----------
# claude-md artifacts do not live in a directory of their own on the installed
# side: they are sections of one CLAUDE.md. `claudemd_is_installed` and
# `claudemd_installed_version` each answer for one name with a grep (and a grep
# plus a sed plus a head), and this listing needs both answers for every
# claude-md feature as well as the list of sections already present. So it reads
# that file once, in bash, and answers all three questions from what it found.
CLAUDEMD_BODY=""
CLAUDEMD_NAMES=()
CLAUDEMD_VERSIONS=() # same index as CLAUDEMD_NAMES — macOS bash 3.2 has no associative arrays

# claudemd_version_var <outvar> <name>
# The section version the scan recorded for <name>; empty <outvar> and return 1
# when the scan never saw that name. printf -v keeps the per-row path fork-free.
claudemd_version_var() {
  local i
  printf -v "$1" '%s' ''
  for ((i = 0; i < ${#CLAUDEMD_NAMES[@]}; i++)); do
    if [ "${CLAUDEMD_NAMES[i]}" = "$2" ]; then
      printf -v "$1" '%s' "${CLAUDEMD_VERSIONS[i]}"
      return 0
    fi
  done
  return 1
}

# fm_vars <ver-outvar> <req-outvar> <path>
# The version/requires pair pass 2 recorded for <path>; both outvars empty and
# return 1 when the scan never saw it. Reads the caller's FM_FILES / FM_VERS /
# FM_REQS parallel arrays through bash's dynamic scoping.
fm_vars() {
  local i
  printf -v "$1" '%s' ''
  printf -v "$2" '%s' ''
  for ((i = 0; i < ${#FM_FILES[@]}; i++)); do
    if [ "${FM_FILES[i]}" = "$3" ]; then
      printf -v "$1" '%s' "${FM_VERS[i]}"
      printf -v "$2" '%s' "${FM_REQS[i]}"
      return 0
    fi
  done
  return 1
}

scan_claudemd() {
  local target line prefix rest name after remainder ver seen
  claudemd_target_path_var target
  CLAUDEMD_BODY=""
  CLAUDEMD_NAMES=()
  CLAUDEMD_VERSIONS=()
  [ -f "$target" ] || return 0
  CLAUDEMD_BODY="$(<"$target")"

  while IFS= read -r line; do
    case "$line" in
      *"<!-- chosko-llm:"*":begin"*) ;;
      *) continue ;;
    esac

    # Both parses below mirror one `sed` script each, for the shape
    # `inject_section` writes: ONE marker per line. They are not full `sed`
    # equivalents — where a single line carries two markers and the first is
    # malformed, `sed` re-anchors on the second and these do not. Both old and
    # new output are meaningless on that input, so the divergence is recorded
    # rather than chased.
    #
    # The name, mirroring `sed 's/<!-- chosko-llm:\([^:]*\):begin.*/\1/'`: any
    # text before the marker is kept, the name is what follows it up to
    # `:begin`, and a line the pattern cannot match passes through whole.
    prefix="${line%%<!-- chosko-llm:*}"
    rest="${line#*<!-- chosko-llm:}"
    name="${rest%%:begin*}"
    if [ "$name" = "$rest" ] || [ "${name%%:*}" != "$name" ]; then
      name="$line"
    else
      name="$prefix$name"
    fi

    # The version, mirroring `sed 's/.*:begin v\([^ ]*\) -->.*/\1/'` — greedy,
    # so the LAST `:begin v` on the line — piped through `head -1`, hence
    # first-occurrence-wins below.
    ver="$line"
    after="${line##*:begin v}"
    if [ "$after" != "$line" ]; then
      remainder="${after#"${after%% *}"}"
      case "$remainder" in " -->"*) ver="${after%% *}" ;; esac
    fi

    if ! claudemd_version_var seen "$name"; then
      CLAUDEMD_NAMES+=("$name")
      CLAUDEMD_VERSIONS+=("$ver")
    fi
  done <<< "$CLAUDEMD_BODY"
}

# claudemd_scan_is_installed <name>
# The scanned form of claudemd_is_installed, matching its fixed-string test
# against the body already in memory.
claudemd_scan_is_installed() {
  case "$CLAUDEMD_BODY" in
    *"<!-- chosko-llm:$1:begin"*) return 0 ;;
  esac
  return 1
}

# collect_names <kind>
# Fills the global array NAMES with the deduplicated feature names of that kind
# visible in either home. Deduplication is a pure-bash membership scan rather
# than `sort -u` (macOS bash 3.2 has no associative arrays), and the basenames
# are parameter expansion rather than `basename`: the final emit sorts every
# row by name and kind rank, so this function's order never reaches the output,
# and staying in-process was worth ~64 processes per listing.
NAMES=()
collect_names() {
  local kind="$1"
  local dir f d n
  NAMES=()
  _add() {
    local __n
    for __n in ${NAMES[@]+"${NAMES[@]}"}; do
      [ "$__n" = "$1" ] && return 0
    done
    NAMES+=("$1")
  }
  case "$kind" in
    command)
      for dir in "$CHOSKO_LLM_HOME/commands" "$CLAUDE_HOME/commands"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.md; do
          [ -e "$f" ] || continue
          n="${f##*/}"; _add "${n%.md}"
        done
      done
      ;;
    skill)
      for dir in "$CHOSKO_LLM_HOME/skills" "$CLAUDE_HOME/skills"; do
        [ -d "$dir" ] || continue
        for d in "$dir"/*/; do
          [ -e "$d" ] || continue
          n="${d%/}"; _add "${n##*/}"
        done
      done
      ;;
    claude-md)
      if [ -d "$CHOSKO_LLM_HOME/claude-md" ]; then
        for f in "$CHOSKO_LLM_HOME"/claude-md/*.md; do
          [ -e "$f" ] || continue
          n="${f##*/}"; _add "${n%.md}"
        done
      fi
      for n in ${CLAUDEMD_NAMES[@]+"${CLAUDEMD_NAMES[@]}"}; do
        _add "$n"
      done
      ;;
    statusline)
      for dir in "$CHOSKO_LLM_HOME/statusline" "$CLAUDE_HOME/statusline"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.sh; do
          [ -e "$f" ] || continue
          n="${f##*/}"; _add "${n%.sh}"
        done
      done
      ;;
    hook)
      for dir in "$CHOSKO_LLM_HOME/hooks" "$CLAUDE_HOME/hooks"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.sh; do
          [ -e "$f" ] || continue
          n="${f##*/}"; _add "${n%.sh}"
        done
      done
      ;;
  esac
  unset -f _add
}

# compute_status <kind> <name> <inst_col> <latest_col>
# Sets STATUS_COL and STATUS_COLOR. Extends the base four-value vocabulary (not
# installed / local only / up-to-date / updatable) with two migration-aware
# statuses when a replaces: declaration ties this row to its counterpart:
# "superseded" (installed, no source, but a clone feature claims to replace it)
# and "migration pending" (in the clone, not installed, but its own replaces:
# names an installed artifact). The find_replacement / check_migration_pending
# probes only run on rows that are already local-only / not-installed — never on
# every row — and both read the one `replaces:` index lib.sh builds on first use.
STATUS_COL=""
STATUS_COLOR=""
compute_status() {
  local kind="$1" name="$2" inst_col="$3" latest_col="$4"
  if [ "$inst_col" = "—" ]; then
    STATUS_COL="not installed"
  elif [ "$latest_col" = "—" ]; then
    STATUS_COL="local only"
  elif [ "$inst_col" = "$latest_col" ]; then
    STATUS_COL="up-to-date"
  else
    STATUS_COL="updatable"
  fi

  if [ "$STATUS_COL" = "local only" ] && find_replacement "$kind" "$name" >/dev/null; then
    STATUS_COL="superseded"
  elif [ "$STATUS_COL" = "not installed" ] && check_migration_pending "$kind" "$name" >/dev/null; then
    STATUS_COL="migration pending"
  fi

  case "$STATUS_COL" in
    "up-to-date")        STATUS_COLOR="$C_GREEN"  ;;
    "updatable")         STATUS_COLOR="$C_YELLOW" ;;
    "not installed")     STATUS_COLOR="$C_DIM"    ;;
    "local only")        STATUS_COLOR="$C_CYAN"   ;;
    "superseded")         STATUS_COLOR="$C_MAGENTA" ;;
    "migration pending")  STATUS_COLOR="$C_BLUE"    ;;
    *)                    STATUS_COLOR=""          ;;
  esac
}

list_all() {
  local filter="$1"
  printf '%sHome: %s%s\n\n' "$C_DIM" "$(scope_label)" "$C_RESET"
  print_header
  local found=0
  local installable=() updatable=() migrating=()
  # Every row is buffered here instead of printed; one name-ordered emit at the
  # end replaces the old kind-grouped output.
  local rows=()

  scan_claudemd

  # The kinds this scope lists, in the order the passes used to run. statusline
  # is global-only — a status bar belongs to a terminal, not a repo. hook is its
  # mirror image, local-only, since a hook only fires if it is committed to the
  # repository it governs.
  local kinds=(command skill claude-md)
  if scope_is_local; then
    kinds+=(hook)
  else
    kinds+=(statusline)
  fi

  # Pass 1 — enumerate the rows, and with them every frontmatter file the
  # listing will need to read.
  local r_kind=() r_name=() r_inst=() r_src=() files=()
  local kind name inst_file src_file
  for kind in "${kinds[@]}"; do
    collect_names "$kind"
    for name in ${NAMES[@]+"${NAMES[@]}"}; do
      [ -n "$name" ] || continue
      # `-f` decides whether the file counts — an existing file with no
      # `version` still renders `unversioned`, not `—`. `-r` separately decides
      # whether it is handed to awk, which aborts the whole batch on a file it
      # cannot open and would take every later row's values with it. An existing
      # but unreadable file therefore degrades exactly its own row, which is
      # what one awk per file did.
      inst_file=""
      # A claude-md artifact has no installed file: it is a section of the
      # CLAUDE.md scan_claudemd already read.
      if [ "$kind" != claude-md ]; then
        feature_path_var inst_file "$CLAUDE_HOME" "$kind" "$name"
        if [ -f "$inst_file" ]; then
          if [ -r "$inst_file" ]; then files+=("$inst_file"); fi
        else
          inst_file=""
        fi
      fi
      feature_path_var src_file "$CHOSKO_LLM_HOME" "$kind" "$name"
      if [ -f "$src_file" ]; then
        if [ -r "$src_file" ]; then files+=("$src_file"); fi
      else
        src_file=""
      fi
      r_kind+=("$kind"); r_name+=("$name")
      r_inst+=("$inst_file"); r_src+=("$src_file")
    done
  done

  # Pass 2 — one awk for all of them. Parallel arrays probed by fm_vars —
  # macOS bash 3.2 has no associative arrays.
  local FM_FILES=() FM_VERS=() FM_REQS=()
  if [ ${#files[@]} -gt 0 ]; then
    local line path rest
    while IFS= read -r line; do
      path="${line%%$'\t'*}"
      rest="${line#*$'\t'}"
      FM_FILES+=("$path")
      FM_VERS+=("${rest%%$'\t'*}")
      FM_REQS+=("${rest#*$'\t'}")
    done < <(read_frontmatter_table "version requires" "${files[@]}")
  fi

  # Pass 3 — render.
  local i inst_ver src_ver inst_req src_req req_raw inst_col latest_col
  local inst_color latest_color rank klabel kcolor
  for ((i = 0; i < ${#r_kind[@]}; i++)); do
    kind="${r_kind[i]}"; name="${r_name[i]}"
    inst_file="${r_inst[i]}"; src_file="${r_src[i]}"

    inst_req=""
    if [ "$kind" = claude-md ]; then
      if claudemd_scan_is_installed "$name"; then
        claudemd_version_var inst_ver "$name" || true
        inst_col="${inst_ver:-unversioned}"
      else
        inst_col="—"
      fi
    elif [ -n "$inst_file" ]; then
      fm_vars inst_ver inst_req "$inst_file" || true
      inst_col="${inst_ver:-unversioned}"
    else
      inst_col="—"
    fi

    req_raw=""
    if [ -n "$src_file" ]; then
      fm_vars src_ver src_req "$src_file" || true
      [ -n "$src_ver" ] && latest_col="$src_ver" || latest_col="—"
      req_raw="$src_req"
    else
      latest_col="—"
      # No installed-side fallback for claude-md: inject_section strips
      # frontmatter, so an installed section carries no `requires:` to read.
      [ "$kind" = claude-md ] || req_raw="$inst_req"
    fi

    if [ "$filter" = installed ] && [ "$inst_col" = "—" ]; then continue; fi
    if [ "$filter" = available ] && [ "$latest_col" = "—" ]; then continue; fi

    compute_status "$kind" "$name" "$inst_col" "$latest_col"

    case "$STATUS_COL" in
      "not installed")                  installable+=("$name") ;;
      "updatable")                      updatable+=("$name") ;;
      "superseded"|"migration pending") migrating+=("$name") ;;
    esac

    [ "$inst_col" = "—" ]    && inst_color="$C_DIM"   || inst_color=""
    [ "$latest_col" = "—" ]  && latest_color="$C_DIM" || latest_color=""

    case "$kind" in
      command)    rank=$KIND_RANK_COMMAND    ; klabel="command"    ; kcolor="$C_BLUE"    ;;
      skill)      rank=$KIND_RANK_SKILL      ; klabel="skill"      ; kcolor="$C_MAGENTA" ;;
      claude-md)  rank=$KIND_RANK_CLAUDEMD   ; klabel="claude-md"  ; kcolor="$C_CYAN"    ;;
      statusline) rank=$KIND_RANK_STATUSLINE ; klabel="statusline" ; kcolor="$C_GREEN"   ;;
      hook)       rank=$KIND_RANK_HOOK       ; klabel="hook"       ; kcolor="$C_YELLOW"  ;;
    esac

    ROW=""
    _colored_cell ""              "$name"        ""         30
    _colored_cell "$kcolor"       "$klabel"      "$C_RESET" 8
    _colored_cell "$inst_color"   "$inst_col"    "$C_RESET" 14
    _colored_cell "$latest_color" "$latest_col"  "$C_RESET" 16
    _colored_cell "$STATUS_COLOR" "$STATUS_COL"  "$C_RESET" "$STATUS_WIDTH"
    _requires_cell "$req_raw"
    rows+=("$name"$'\t'"$rank"$'\t'"$ROW")
    found=1
  done

  # Single name-ordered emit. Field 1 is the feature name, field 2 the kind
  # rank that breaks a tie between two rows sharing one; LC_ALL=C keeps the
  # order byte-deterministic whatever collation the caller's locale would use.
  if [ $found -eq 1 ]; then
    printf '%s\n' "${rows[@]}" \
      | LC_ALL=C sort -t $'\t' -k1,1 -k2,2n \
      | cut -f3-
  else
    log_info "No features found."
  fi

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
