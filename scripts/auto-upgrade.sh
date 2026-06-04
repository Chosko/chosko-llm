#!/usr/bin/env bash
# Daily auto-upgrade hook. Invoked by the proxy before it dispatches a
# subcommand. Runs `chosko-llm upgrade` at most once per calendar day when the
# user is opted in. It must never abort the user's actual command, so the
# proxy calls it with `|| true` and every exit here is non-fatal.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

subcommand="${1:-}"

# Escape hatch (CI / non-interactive use).
[ -n "${CHOSKO_LLM_NO_AUTO_UPGRADE:-}" ] && exit 0

# Never auto-upgrade for these — and never recurse into `upgrade`.
case "$subcommand" in
  ""|upgrade|help|-h|--help) exit 0 ;;
esac

auto_upgrade_enabled || exit 0
auto_upgrade_due     || exit 0

# Stamp today's date BEFORE upgrading, so a failed/again-offline upgrade does
# not retry on every command for the rest of the day.
auto_upgrade_set last_run "$(date +%Y-%m-%d)"

log_info "Auto-upgrading chosko-llm (first run today)…"
if ! "$SCRIPT_DIR/cmd-upgrade.sh"; then
  log_warn "Auto-upgrade failed; continuing with your command."
fi

# Suggestion is shown only on an interactive terminal (mirrors cmd-ls).
if [ -t 2 ]; then
  log_info "Auto-upgrade ran. Disable it with: chosko-llm upgrade --disable-auto"
fi

echo
exit 0
