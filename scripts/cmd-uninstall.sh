#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Thin wrapper so `chosko-llm uninstall` routes through the proxy's uniform
# cmd-<sub>.sh dispatch. The teardown logic lives in the repo-root
# uninstall.sh (single source of truth); this just execs it. Unlike the other
# cmd-*.sh scripts it does NOT source lib.sh — uninstall.sh is self-contained
# and must run even when the managed clone is being torn down.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
exec "$REPO_ROOT/uninstall.sh" "$@"
