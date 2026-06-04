#!/usr/bin/env bash
set -euo pipefail

CHOSKO_LLM_HOME="${CHOSKO_LLM_HOME:-$HOME/.chosko-llm}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# 4. Determine version.
VERSION="unknown"
if [ -f "$CHOSKO_LLM_HOME/VERSION" ]; then
  VERSION="$(tr -d '[:space:]' < "$CHOSKO_LLM_HOME/VERSION")"
fi
if command -v git >/dev/null 2>&1; then
  GITDESC="$(git -C "$CHOSKO_LLM_HOME" describe --tags --always 2>/dev/null || true)"
  [ -n "$GITDESC" ] && VERSION="$VERSION ($GITDESC)"
fi

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

log "Next: run 'chosko-llm ls --available' to see installable features."
