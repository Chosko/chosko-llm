#!/usr/bin/env bash
: <<'CHOSKO_FRONTMATTER'
---
name: session-statusline
version: 0.1.1
type: statusline
description: Status line showing model, cwd, git branch, context usage, cost, and 5h/7d rate limits.
---
CHOSKO_FRONTMATTER
# Claude Code status line: model · cwd · git · context% · cost · 5h limit · 7d limit
set -euo pipefail

input=$(cat)

# --- Flatten the JSON to "dotted.path<TAB>value" lines (no jq) ---
# Scalars only; null is dropped so a missing and a null field read the same.
FIELDS=$(printf '%s' "$input" | awk '
  function emit(v,   p, k) {
    p = ""
    for (k = 1; k <= d; k++) p = p (k > 1 ? "." : "") key[k]
    print p "\t" v
  }
  { s = s $0 "\n" }
  END {
    n = length(s); d = 0; i = 1
    while (i <= n) {
      c = substr(s, i, 1)
      if (c == "{") { d++; typ[d] = "o"; key[d] = ""; expk = 1; i++; continue }
      if (c == "[") { d++; typ[d] = "a"; key[d] = 0;  expk = 0; i++; continue }
      if (c == "}" || c == "]") { d--; i++; continue }
      if (c == ":") { expk = 0; i++; continue }
      if (c == ",") { if (typ[d] == "o") expk = 1; else key[d]++; i++; continue }
      if (c ~ /[ \t\r\n]/) { i++; continue }
      if (c == "\"") {
        v = ""; i++
        while (i <= n) {
          c = substr(s, i, 1)
          if (c == "\\") {
            e = substr(s, i + 1, 1)
            if (e == "n" || e == "t" || e == "r") v = v " "
            else if (e == "u") { v = v "\\u" substr(s, i + 2, 4); i += 4 }
            else v = v e
            i += 2; continue
          }
          i++
          if (c == "\"") break
          v = v c
        }
        if (typ[d] == "o" && expk) key[d] = v; else emit(v)
        continue
      }
      j = i
      while (j <= n && substr(s, j, 1) !~ /[,}\] \t\r\n]/) j++
      v = substr(s, i, j - i); i = j
      if (v != "null") emit(v)
    }
  }')

field() {
  printf '%s\n' "$FIELDS" | awk -F'\t' -v k="$1" '$1 == k { sub(/^[^\t]*\t/, ""); print; exit }'
}

# --- Parse fields (all with null-safe fallbacks) ---
MODEL=$(field model.display_name);                    MODEL=${MODEL:-?}
DIR=$(field workspace.current_dir);                   DIR=${DIR:-?}
PCT=$(field context_window.used_percentage);          PCT=${PCT%%.*}; PCT=${PCT:-0}
COST=$(field cost.total_cost_usd);                    COST=${COST:-0}
RL5H=$(field rate_limits.five_hour.used_percentage)
RL7D=$(field rate_limits.seven_day.used_percentage)
RESETS_AT=$(field rate_limits.five_hour.resets_at)

# Normalize Windows paths for Git Bash: E:\projects\foo → /e/projects/foo
if [[ "$DIR" =~ ^[A-Za-z]:[\\/] ]]; then
  DIR=$(cygpath -u "$DIR" 2>/dev/null || echo "$DIR")
fi

# --- Git branch (handles detached HEAD, non-repo dirs, and set -e) ---
BRANCH=""
if git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  # Try symbolic ref first (normal branch); fall back to short SHA if detached
  BRANCH=$(git -C "$DIR" symbolic-ref --short -q HEAD 2>/dev/null \
        || git -C "$DIR" rev-parse --short HEAD 2>/dev/null \
        || echo "")
fi

# --- Colors ---
C='\033[36m' G='\033[32m' Y='\033[33m' R='\033[31m' D='\033[2m' X='\033[0m'

if   [ "$PCT" -ge 90 ]; then PCT_C="$R"
elif [ "$PCT" -ge 70 ]; then PCT_C="$Y"
else                         PCT_C="$G"
fi

if [ -n "$RL5H" ]; then
  RL5H_INT=$(printf '%.0f' "$RL5H")
  if   [ "$RL5H_INT" -ge 80 ]; then RL5H_C="$R"
  elif [ "$RL5H_INT" -ge 50 ]; then RL5H_C="$Y"
  else                               RL5H_C="$G"
  fi
fi

RESET_FMT=""
if [[ "$RESETS_AT" =~ ^[0-9]+$ ]]; then
  NOW_EPOCH=$(date +%s)
  DIFF=$(( RESETS_AT - NOW_EPOCH ))
  if [ "$DIFF" -gt 0 ]; then
    H=$(( DIFF / 3600 ))
    M=$(( (DIFF % 3600) / 60 ))
    RESET_FMT="${H}h${M}m"
  fi
fi

if [ -n "$RL7D" ]; then
  RL7D_INT=$(printf '%.0f' "$RL7D")
  if   [ "$RL7D_INT" -ge 80 ]; then RL7D_C="$R"
  elif [ "$RL7D_INT" -ge 50 ]; then RL7D_C="$Y"
  else                               RL7D_C="$G"
  fi
fi

# --- Assemble ---
COST_FMT=$(printf '$%.2f' "$COST")
LINE="${C}${MODEL}${X} ${D}·${X} 📁 ${DIR##*/}"
if [ -n "$BRANCH" ]; then
  # Mark detached HEAD visually: no slash in SHA-only, so check symbolic-ref again
  if git -C "$DIR" symbolic-ref -q HEAD >/dev/null 2>&1; then
    LINE="${LINE} ${D}·${X} 🌿 ${BRANCH}"
  else
    LINE="${LINE} ${D}·${X} 🔶 ${BRANCH}"   # detached HEAD indicator
  fi
fi
LINE="${LINE} ${D}·${X} ${PCT_C}${PCT}%${X} ctx ${D}·${X} ${COST_FMT}"
[ -n "$RL5H" ] && LINE="${LINE} ${D}·${X} ${RL5H_C}${RL5H_INT}%${X} 5h"
[ -n "$RESET_FMT" ] && LINE="${LINE} ${D}(${X}⏳ ${C}${RESET_FMT}${X} ${D}until reset)${X}"
[ -n "$RL7D" ] && LINE="${LINE} ${D}·${X} ${RL7D_C}${RL7D_INT}%${X} 7d"

printf '%b\n' "$LINE"
