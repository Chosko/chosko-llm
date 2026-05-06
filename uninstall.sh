#!/usr/bin/env bash
set -euo pipefail

CHOSKO_LLM_HOME="${CHOSKO_LLM_HOME:-$HOME/.chosko-llm}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"

log()  { printf '\033[1;34m[uninstall]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[uninstall]\033[0m %s\n' "$*" >&2; }

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " reply || return 1
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *)           return 1 ;;
  esac
}

# 1. Remove the proxy.
if [ -e "$BIN_DIR/chosko-llm" ]; then
  log "Removing proxy: $BIN_DIR/chosko-llm"
  rm -f "$BIN_DIR/chosko-llm"
else
  log "No proxy at $BIN_DIR/chosko-llm — skipping."
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
