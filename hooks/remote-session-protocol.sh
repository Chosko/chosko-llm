#!/usr/bin/env bash
: <<'CHOSKO_FRONTMATTER'
---
name: remote-session-protocol
version: 0.1.0
type: hook
description: In remote cloud sessions, deny AskUserQuestion and have Claude ask in one numbered text batch instead.
event: PreToolUse
matcher: AskUserQuestion
---
CHOSKO_FRONTMATTER

# Why this exists: in a Claude Code cloud session, a question asked through the
# AskUserQuestion tool can be re-asked while nobody is at the keyboard, burning
# tokens and occasionally leaving two agents working the same task. Denying the
# tool and handing the model a text protocol in the denial reason removes the
# trigger: the model asks once, in writing, and ends its turn.
#
# Detection is POSITIVE-ONLY. The protocol engages when the session says it is
# remote and not otherwise, so a renamed variable silently restores ordinary
# local behaviour rather than blocking the tool everywhere. Retune this file if
# that day comes; do not widen the check to "when in doubt, assume remote".
# IS_SANDBOX is deliberately not consulted — it marks sandboxed execution,
# which local sessions also have.
#
# Deliberately no `set -euo pipefail`: a PreToolUse hook exiting 2 BLOCKS the
# tool call, so every path here ends in an explicit `exit 0` and no incidental
# failure can escalate into a block.

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && [ -z "${CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE:-}" ]; then
  exit 0
fi

# One line, no double quotes and no backslashes, so it drops into the JSON
# string below without escaping. Keep it that way if you edit it.
reason='AskUserQuestion is unavailable in this session; do not retry it. Ask in plain text instead: put every open question in one message, numbered Q1 to Qn, with lettered options and a one-line recommendation each. Then end your turn and wait - no further tool calls, no polling. When the user replies, restate the numbered batch with their answers before acting. A subagent returns its questions to its parent instead of asking.'

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"

exit 0
