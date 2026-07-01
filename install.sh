#!/usr/bin/env bash
set -euo pipefail

CHOSKO_LLM_HOME="${CHOSKO_LLM_HOME:-$HOME/.chosko-llm}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"

# When run via `curl | bash`, there is no script file, so BASH_SOURCE is unset.
# Guard against that (with set -u active) and leave SCRIPT_DIR empty so the
# curl-pipe branch below clones REPO_URL instead of a local working copy.
_src="${BASH_SOURCE[0]:-}"
if [ -n "$_src" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$_src")" && pwd)"
else
  SCRIPT_DIR=""
fi

# Detect platform once; used in steps 3 and 5.
_uname="$(uname -s 2>/dev/null || true)"

# Default repo used when not running from a git checkout (i.e. curl | bash).
REPO_URL="${REPO_URL:-https://github.com/Chosko/chosko-llm.git}"

log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[install]\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Clone or update the managed clone.
if [ -d "$CHOSKO_LLM_HOME/.git" ]; then
  log "Found existing managed clone at $CHOSKO_LLM_HOME — pulling latest."
  git -C "$CHOSKO_LLM_HOME" pull --ff-only
elif [ -d "$SCRIPT_DIR/.git" ]; then
  # Running from a developer working copy — derive the origin URL from it.
  ORIGIN_URL="$(git -C "$SCRIPT_DIR" remote get-url origin 2>/dev/null || true)"
  if [ -z "$ORIGIN_URL" ]; then
    die "Could not determine origin URL from $SCRIPT_DIR.
Add a remote with: git remote add origin <url>"
  fi
  log "Cloning $ORIGIN_URL into $CHOSKO_LLM_HOME"
  git clone "$ORIGIN_URL" "$CHOSKO_LLM_HOME"
else
  # Running via curl | bash — no working copy available.
  log "Cloning $REPO_URL into $CHOSKO_LLM_HOME"
  git clone "$REPO_URL" "$CHOSKO_LLM_HOME"
fi

# 2. Ensure scripts are executable in the managed clone.
chmod +x "$CHOSKO_LLM_HOME/bin/chosko-llm" \
         "$CHOSKO_LLM_HOME"/scripts/*.sh \
         "$CHOSKO_LLM_HOME/install.sh" \
         "$CHOSKO_LLM_HOME/uninstall.sh" 2>/dev/null || true

# 3. Set up bin dir + proxy.
mkdir -p "$BIN_DIR"

if [ -e "$BIN_DIR/chosko-llm" ]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  log "Existing $BIN_DIR/chosko-llm found — backing up to chosko-llm.bak.$TS"
  mv "$BIN_DIR/chosko-llm" "$BIN_DIR/chosko-llm.bak.$TS"
fi

cp "$CHOSKO_LLM_HOME/bin/chosko-llm" "$BIN_DIR/chosko-llm"
chmod +x "$BIN_DIR/chosko-llm"

# 3a. On Windows (MINGW/MSYS/Cygwin), also install the .cmd shim.
case "$_uname" in
  MINGW*|MSYS*|CYGWIN*)
    if [ -e "$BIN_DIR/chosko-llm.cmd" ]; then
      TS="$(date +%Y%m%d-%H%M%S)"
      log "Existing $BIN_DIR/chosko-llm.cmd found — backing up to chosko-llm.cmd.bak.$TS"
      mv "$BIN_DIR/chosko-llm.cmd" "$BIN_DIR/chosko-llm.cmd.bak.$TS"
    fi
    cp "$CHOSKO_LLM_HOME/bin/chosko-llm.cmd" "$BIN_DIR/chosko-llm.cmd"
    log "Installed chosko-llm.cmd (Windows cmd/PowerShell shim)"
    ;;
esac

# 3b. Initialize auto-upgrade state (opt-in by default). Don't clobber an
#     existing preference on re-install.
STATE_FILE="$CHOSKO_LLM_HOME/.auto-upgrade-state"
if [ ! -f "$STATE_FILE" ]; then
  printf 'enabled=true\nlast_run=%s\n' "$(date +%Y-%m-%d)" > "$STATE_FILE"
  log "Enabled daily auto-upgrade (disable with 'chosko-llm upgrade --disable-auto')."
fi

# 4. Determine version. Reuse resolve_version from the (now-present) managed
#    clone's lib.sh so the format stays in sync with `chosko-llm --version`.
#    Sourced in a subshell so lib.sh's own log_*/die definitions don't clobber
#    this script's [install]-prefixed logging.
VERSION="$(source "$CHOSKO_LLM_HOME/scripts/lib.sh" 2>/dev/null && resolve_version || echo unknown)"

# 5. Summary + PATH check.
log "Installed chosko-llm $VERSION"
log "  Managed clone : $CHOSKO_LLM_HOME"
log "  Proxy script  : $BIN_DIR/chosko-llm"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    log "PATH already contains $BIN_DIR — you can run 'chosko-llm' now."
    ;;
  *)
    warn "$BIN_DIR is not in your PATH."
    warn "Add it by appending this to your shell rc (e.g. ~/.bashrc, ~/.zshrc):"
    warn "    export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

# 5a. Windows users: the shim must be on the *Windows* PATH, not just the MSYS PATH.
case "$_uname" in
  MINGW*|MSYS*|CYGWIN*)
    _win_bin=""
    if command -v cygpath >/dev/null 2>&1; then
      _win_bin="$(cygpath -w "$BIN_DIR" 2>/dev/null || true)"
    fi
    warn "Windows users: to use 'chosko-llm' from cmd.exe or PowerShell, add"
    warn "the following directory to your *Windows* PATH (not just the MSYS PATH):"
    if [ -n "$_win_bin" ]; then
      warn "    $_win_bin"
    else
      warn "    $BIN_DIR"
    fi
    warn "System Properties -> Advanced -> Environment Variables -> Path -> Edit -> New"
    warn "WSL users: run from inside WSL (where ~/.chosko-llm is your WSL home)."
    ;;
esac

log "Next: run 'chosko-llm ls --available' to see installable features."
