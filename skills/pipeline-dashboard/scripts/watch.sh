#!/usr/bin/env bash
# Watch .claude/TASKS.md and print one line per task status change, polled
# every 10 seconds, for the Monitor tool: each line is one dashboard event.
# Run from the project root; runs until killed.
# Usage: watch.sh
set -u
export LC_ALL=C

snap() {
  awk '/^## [0-9]+\. / { id = $2; sub(/\.$/, "", id) }
       /^Status: \[/ && id != "" { s = $0; sub(/^Status: \[/, "", s); sub(/\].*/, "", s); print id " " s; id = "" }' \
    .claude/TASKS.md 2>/dev/null
}

prev=$(snap)
while :; do
  sleep 10
  cur=$(snap)
  if [ "$cur" != "$prev" ]; then
    printf '%s\n--\n%s\n' "$prev" "$cur" | awk '
      !f && /^--$/ { f = 1; next }
      { id = $1; s = $0; sub(/^[^ ]+ /, "", s) }
      !f { P[id] = s; next }
      !(id in P) { print "task " id ": [" s "]"; fflush(); next }
      P[id] != s { print "task " id ": [" P[id] "] -> [" s "]"; fflush() }'
    prev=$cur
  fi
done
