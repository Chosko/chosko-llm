#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# Print the installed CLI version. Format mirrors install.sh's banner.
printf 'chosko-llm %s\n' "$(resolve_version)"
