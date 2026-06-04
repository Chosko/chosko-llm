#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

_bold_usage_headings() {
  sed "s/^Usage:/${C_BOLD}Usage:${C_RESET}/"
}

if [ -f "$CHOSKO_LLM_HOME/docs/cli-help.txt" ]; then
  _bold_usage_headings < "$CHOSKO_LLM_HOME/docs/cli-help.txt"
else
  cat <<EOF | _bold_usage_headings
chosko-llm — manage global Claude Code commands and skills.

Usage:
  chosko-llm ls [--installed|--available]
  chosko-llm add <feature>
  chosko-llm rm  <feature>
  chosko-llm update <feature>
  chosko-llm update --all
  chosko-llm upgrade
  chosko-llm task-impl [OPTIONS] <N> [<N>…]   (run chosko-llm task-impl --help for options)
  chosko-llm help
EOF
fi
