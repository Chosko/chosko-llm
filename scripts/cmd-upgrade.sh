#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

BIN_DIR="${BIN_DIR:-$HOME/bin}"

# Toggle-only auto-upgrade preference flags. These set the preference and exit;
# they do NOT perform an upgrade.
enable_auto=0 disable_auto=0
for arg in "$@"; do
  case "$arg" in
    --enable-auto)  enable_auto=1 ;;
    --disable-auto) disable_auto=1 ;;
  esac
done
if [ "$enable_auto" -eq 1 ] && [ "$disable_auto" -eq 1 ]; then
  die "--enable-auto and --disable-auto cannot be combined. Pick one."
fi
if [ "$enable_auto" -eq 1 ]; then
  auto_upgrade_set enabled true
  log_success "Daily auto-upgrade enabled."
  exit 0
fi
if [ "$disable_auto" -eq 1 ]; then
  auto_upgrade_set enabled false
  log_success "Daily auto-upgrade disabled."
  exit 0
fi

[ -d "$CHOSKO_LLM_HOME/.git" ] || die "Managed clone $CHOSKO_LLM_HOME is not a git repo. Re-run install.sh."

before="$(git -C "$CHOSKO_LLM_HOME" rev-parse HEAD)"

log_info "Pulling latest in $CHOSKO_LLM_HOME"
git -C "$CHOSKO_LLM_HOME" pull --ff-only

after="$(git -C "$CHOSKO_LLM_HOME" rev-parse HEAD)"

if [ "$before" = "$after" ]; then
  log_success "Already up to date."
else
  log_info "Pulled changes:"
  git -C "$CHOSKO_LLM_HOME" log --oneline "$before..$after" >&2 || true
fi

# Refresh the proxy from the managed clone.
if [ -f "$CHOSKO_LLM_HOME/bin/chosko-llm" ]; then
  if [ -e "$BIN_DIR/chosko-llm" ]; then
    cp "$CHOSKO_LLM_HOME/bin/chosko-llm" "$BIN_DIR/chosko-llm"
    chmod +x "$BIN_DIR/chosko-llm"
    log_info "Refreshed proxy at $BIN_DIR/chosko-llm"
  else
    log_warn "Proxy not found at $BIN_DIR/chosko-llm — run install.sh to (re)create it."
  fi
fi

# Make sure scripts in the managed clone are executable.
chmod +x "$CHOSKO_LLM_HOME"/scripts/*.sh "$CHOSKO_LLM_HOME/bin/chosko-llm" 2>/dev/null || true

log_info "Run 'chosko-llm ls --available' to see new or upgradable features."
log_info "Run 'chosko-llm update --all' to refresh installed features."

# If the user has opted out of daily auto-upgrade, suggest opting back in.
if [ -t 2 ] && ! auto_upgrade_enabled; then
  log_info "Tip: enable daily auto-upgrade with: chosko-llm upgrade --enable-auto"
fi
