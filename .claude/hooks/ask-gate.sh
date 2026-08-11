#!/usr/bin/env bash
# TEMPORARY probe — see the commit that added it. Reverted after the test.
#
# PreToolUse hook on AskUserQuestion. In a confirmed remote session it denies
# the call and hands the model the text protocol as the denial reason; anywhere
# else it emits nothing, which is "no decision", so the tool proceeds normally.
#
# Deliberately no `set -euo pipefail`: a hook that exits 2 BLOCKS the tool, so
# every path here ends in an explicit `exit 0` and no failure can escalate.

printf 'PROBE-ASKGATE %s remote=%s\n' \
  "$(date -u +%FT%TZ)" "${CLAUDE_CODE_REMOTE:-unset}" >> /tmp/hook-probe.log 2>/dev/null

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Single line, no double quotes and no backslashes, so it drops into the JSON
# string below without escaping. Keep it that way if you edit it.
reason='AskUserQuestion is unavailable in this session; do not retry it. Ask in plain text instead: put every open question in one message, numbered Q1 to Qn, with lettered options and a one-line recommendation each. Then end your turn and wait - no further tool calls, no polling. When the user replies, restate the numbered batch with their answers before acting. A subagent returns its questions to its parent instead of asking.'

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"

exit 0
