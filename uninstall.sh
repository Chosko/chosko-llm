#!/usr/bin/env bash
set -euo pipefail

CHOSKO_LLM_HOME="${CHOSKO_LLM_HOME:-$HOME/.chosko-llm}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"

# -y / --yes auto-confirms every prompt (non-interactive / CI use).
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help)
      printf 'Usage: uninstall.sh [-y|--yes]\n\n'
      printf 'Removes the chosko-llm proxy and, with confirmation, the installed\n'
      printf 'features and the managed clone. -y/--yes answers every prompt yes.\n'
      exit 0
      ;;
  esac
done

log()  { printf '\033[1;34m[uninstall]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[uninstall]\033[0m %s\n' "$*" >&2; }

confirm() {
  local prompt="$1"
  [ "$ASSUME_YES" -eq 1 ] && return 0
  read -r -p "$prompt [y/N] " reply || return 1
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *)           return 1 ;;
  esac
}

# Top-level gate: nothing is removed (not even the proxy) without an explicit
# yes. Exposing uninstall as a CLI verb makes accidental invocation easier than
# running the script by path, so confirm before any destructive step.
if ! confirm "This will uninstall chosko-llm (proxy, and optionally features + managed clone). Continue?"; then
  log "Aborted — nothing was changed."
  exit 0
fi

# 1. Remove the proxy (and the Windows .cmd shim if present).
if [ -e "$BIN_DIR/chosko-llm" ]; then
  log "Removing proxy: $BIN_DIR/chosko-llm"
  rm -f "$BIN_DIR/chosko-llm"
else
  log "No proxy at $BIN_DIR/chosko-llm — skipping."
fi

if [ -e "$BIN_DIR/chosko-llm.cmd" ]; then
  log "Removing Windows shim: $BIN_DIR/chosko-llm.cmd"
  rm -f "$BIN_DIR/chosko-llm.cmd"
fi

# 2. Optionally remove installed features (do this BEFORE removing the managed
#    clone, since we need the source list to know what we authored).
if [ -d "$CHOSKO_LLM_HOME" ] && [ -d "$CLAUDE_HOME" ]; then
  if confirm "Also remove all features installed by chosko-llm from $CLAUDE_HOME?"; then
    # Commands
    if [ -d "$CHOSKO_LLM_HOME/commands" ] && [ -d "$CLAUDE_HOME/commands" ]; then
      for src in "$CHOSKO_LLM_HOME"/commands/*.md; do
        [ -e "$src" ] || continue
        base="$(basename "$src")"
        target="$CLAUDE_HOME/commands/$base"
        if [ -e "$target" ]; then
          log "Removing command: $target"
          rm -f "$target"
        fi
      done
    fi
    # Skills
    if [ -d "$CHOSKO_LLM_HOME/skills" ] && [ -d "$CLAUDE_HOME/skills" ]; then
      for srcdir in "$CHOSKO_LLM_HOME"/skills/*/; do
        [ -e "$srcdir" ] || continue
        base="$(basename "$srcdir")"
        target="$CLAUDE_HOME/skills/$base"
        if [ -d "$target" ]; then
          log "Removing skill: $target"
          rm -rf "$target"
        fi
      done
    fi
    # claude-md sections
    if [ -d "$CHOSKO_LLM_HOME/claude-md" ] && [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
      for src in "$CHOSKO_LLM_HOME"/claude-md/*.md; do
        [ -e "$src" ] || continue
        base="$(basename "$src" .md)"
        if grep -qF "<!-- chosko-llm:${base}:begin" "$CLAUDE_HOME/CLAUDE.md" 2>/dev/null; then
          log "Removing claude-md section: $base"
          tmp="$(mktemp)"
          awk -v bm="<!-- chosko-llm:${base}:begin" \
              -v em="<!-- chosko-llm:${base}:end -->" '
            index($0, bm) { skip=1; next }
            skip && index($0, em) { skip=0; next }
            skip { next }
            { print }
          ' "$CLAUDE_HOME/CLAUDE.md" > "$tmp" && mv "$tmp" "$CLAUDE_HOME/CLAUDE.md"
        fi
      done
    fi
  else
    log "Leaving installed features alone."
  fi
fi

# 3. Remove the managed clone.
if [ -d "$CHOSKO_LLM_HOME" ]; then
  if confirm "Remove the managed clone at $CHOSKO_LLM_HOME?"; then
    log "Removing $CHOSKO_LLM_HOME"
    rm -rf "$CHOSKO_LLM_HOME"
  else
    log "Leaving $CHOSKO_LLM_HOME in place."
  fi
fi

log "Done."
