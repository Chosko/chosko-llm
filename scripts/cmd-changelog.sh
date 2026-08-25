#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

USAGE="Usage: chosko-llm changelog [--since <version|YYYY-MM-DD|30d>] [--print]"

# The colour decision is captured HERE, from the command's original stdout,
# before anything can redirect it. The rendered block may end up going to a
# pager, at which point fd 1 is a pipe — deciding from the write fd would
# silently strip every escape from exactly the case that wants them.
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
  STDOUT_WAS_TTY=1
else
  STDOUT_WAS_TTY=0
fi
_changelog_use_color() { [ "$STDOUT_WAS_TTY" -eq 1 ]; }

since=""
# Tracked separately from the value: `--since=` with an empty value is a
# malformed request, not an absent one, and must not fall through to the
# whole-file view a bare `changelog` gets.
since_given=0
print_only=0
while [ $# -gt 0 ]; do
  case "$1" in
    --print)
      print_only=1
      shift
      ;;
    --since)
      shift
      [ $# -gt 0 ] || die "--since needs a value. $USAGE"
      since="$1"
      since_given=1
      shift
      ;;
    --since=*)
      since="${1#--since=}"
      since_given=1
      shift
      ;;
    -h|--help)
      printf '%s\n' "$USAGE"
      exit 0
      ;;
    *)
      die "Unknown argument: $1. $USAGE"
      ;;
  esac
done

file="$(src_changelog_path)"
[ -f "$file" ] || die "No CHANGELOG.md in $CHOSKO_LLM_HOME. Run 'chosko-llm upgrade' to refresh the managed clone."

# ---------- no --since: the whole file ----------

if [ "$since_given" -eq 0 ]; then
  # --print exists for scripts and pipelines: never an editor, never a pager.
  if [ "$print_only" -eq 1 ] || [ ! -t 1 ]; then
    cat "$file"
    exit 0
  fi

  # $VISUAL, then $EDITOR, then git's. `git var GIT_EDITOR` answers even when
  # nothing is configured, which is the point: a bare git-bash on Windows
  # commonly has neither variable set, and refusing there would make the first
  # run fail on this CLI's primary platform.
  editor="${VISUAL:-}"
  [ -n "$editor" ] || editor="${EDITOR:-}"
  if [ -z "$editor" ] && command -v git >/dev/null 2>&1; then
    editor="$(git var GIT_EDITOR 2>/dev/null || true)"
  fi
  if [ -n "$editor" ]; then
    # Through a shell, because that is git's own contract for these values: it
    # runs GIT_EDITOR via `sh -c`, so the configured string may carry flags
    # ("code -w") AND quoting ('"C:\Program Files\...\code" --wait'), which is
    # the form git writes on Windows. Plain word-splitting handles the first and
    # mangles the second into a nonexistent argv[0].
    exec sh -c "$editor \"\$1\"" "$editor" "$file"
  fi
  if command -v less >/dev/null 2>&1; then
    exec less -R "$file"
  fi
  exec cat "$file"
fi

# ---------- --since: a filtered, rendered block on stdout ----------

kind="$(changelog_since_kind "$since")" || die "Cannot read '--since $since'. Give a version (1.10.0), a date (2026-08-01), or a duration (30d, 2w, 6mo, 1y)."

value="$since"
if [ "$kind" = "duration" ]; then
  value="$(changelog_duration_to_date "$since")" || die "Could not resolve '--since $since' to a date on this system."
  kind="date"
fi

if ! body="$(select_changelog_sections "$kind" "$value")"; then
  # Matching nothing is a legitimate answer, not a failure.
  log_info "No CHANGELOG.md sections match --since $since."
  exit 0
fi

# Rendered up front so its height can be measured before choosing a stream. The
# command substitution strips the block's trailing blank line; put it back, so
# the block is byte-identical to the one `upgrade` prints.
rendered="$(_render_changelog_sections "$body" 1 _changelog_use_color)"$'\n'

# Page only when the block does not fit one screen, and only on a TTY without
# --print: a pipe or a redirect must stay a plain stream whatever its length, so
# `changelog --since 30d | grep …` behaves the same either way.
if [ "$print_only" -eq 0 ] && [ -t 1 ]; then
  line_count="$(printf '%s\n' "$rendered" | wc -l | tr -d '[:space:]')"
  if [ "$line_count" -gt "$(terminal_height)" ]; then
    pager="${PAGER:-}"
    if [ -z "$pager" ] && command -v less >/dev/null 2>&1; then
      # -R so the escapes the renderer just wrote survive the pager.
      pager="less -R"
    fi
    if [ -n "$pager" ]; then
      # Through a shell, for the same reason as the editor above: $PAGER carries
      # its own flags and may be quoted.
      set +e
      printf '%s\n' "$rendered" | sh -c "$pager"
      pager_status=$?
      set -e
      # 126/127 mean the pager could not be run at all — fall through and write
      # the block out plainly rather than swallowing what the user asked for.
      # Every other status means it ran, including the 141 that pipefail reports
      # when a reader quits early and SIGPIPEs the printf.
      case "$pager_status" in
        126|127) ;;
        *) exit 0 ;;
      esac
    fi
  fi
fi

printf '%s\n' "$rendered"
