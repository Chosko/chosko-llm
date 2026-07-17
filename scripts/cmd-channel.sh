#!/usr/bin/env bash
# Point the managed clone at a branch ("channel") so a user can try features
# before they land on master, then switch back with `channel master`. The
# checked-out branch is the whole persistence mechanism — auto-upgrade's
# `git pull --ff-only` already follows it, so there is no state file.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

BIN_DIR="${BIN_DIR:-$HOME/bin}"

[ -d "$CHOSKO_LLM_HOME/.git" ] || die "Managed clone $CHOSKO_LLM_HOME is not a git repo. Re-run install.sh."

current_branch() {
  git -C "$CHOSKO_LLM_HOME" rev-parse --abbrev-ref HEAD
}

# Refresh the proxy from the managed clone and re-mark scripts executable.
# Same logic as cmd-upgrade.sh's post-pull refresh.
refresh_proxy() {
  if [ -f "$CHOSKO_LLM_HOME/bin/chosko-llm" ]; then
    if [ -e "$BIN_DIR/chosko-llm" ]; then
      cp "$CHOSKO_LLM_HOME/bin/chosko-llm" "$BIN_DIR/chosko-llm"
      chmod +x "$BIN_DIR/chosko-llm"
      log_info "Refreshed proxy at $BIN_DIR/chosko-llm"
    else
      log_warn "Proxy not found at $BIN_DIR/chosko-llm — run install.sh to (re)create it."
    fi
  fi
  chmod +x "$CHOSKO_LLM_HOME"/scripts/*.sh "$CHOSKO_LLM_HOME/bin/chosko-llm" 2>/dev/null || true
}

arg="${1:-}"

case "$arg" in
  "")
    # No arg: report the channel the clone is currently on.
    echo "$(current_branch)"
    exit 0
    ;;
  -l|--list)
    # List the channels available on origin, marking the current one.
    log_info "Fetching origin…"
    git -C "$CHOSKO_LLM_HOME" fetch --prune origin
    cur="$(current_branch)"
    git -C "$CHOSKO_LLM_HOME" for-each-ref --format='%(refname:short)' refs/remotes/origin \
      | sed 's#^origin/##' \
      | grep -vx 'HEAD' \
      | sort -u \
      | while IFS= read -r b; do
          if [ "$b" = "$cur" ]; then
            printf '* %s (current)\n' "$b"
          else
            printf '  %s\n' "$b"
          fi
        done
    exit 0
    ;;
  *)
    # Switch to <branch>: fetch, checkout, fast-forward, refresh the proxy.
    branch="$arg"
    log_info "Fetching origin…"
    git -C "$CHOSKO_LLM_HOME" fetch --prune origin
    git -C "$CHOSKO_LLM_HOME" checkout "$branch" \
      || die "Cannot switch to channel '$branch' — no such branch. The clone is unchanged; 'chosko-llm channel --list' shows available channels."
    git -C "$CHOSKO_LLM_HOME" pull --ff-only
    refresh_proxy
    log_success "Now on channel '$branch'."
    log_info "Run 'chosko-llm update --all' to deploy this channel's features."
    exit 0
    ;;
esac
