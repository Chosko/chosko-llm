#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# Print the installed CLI version. Format mirrors install.sh's banner.
printf 'chosko-llm %s\n' "$(resolve_version)"

# TTY-gated, and on stderr, so the line above stays the whole of stdout when a
# script captures it.
if [ -t 2 ]; then
  log_info "Tip: run 'chosko-llm changelog' to see what changed in this and earlier versions."
fi
