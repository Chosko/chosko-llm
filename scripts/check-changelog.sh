#!/usr/bin/env bash
# Guard the four cheap invariants of the root CHANGELOG.md, so that the rule
# in CLAUDE.md § Versioning — a VERSION bump without a matching section is an
# incomplete change — has something that notices when it is broken. Run it by
# hand whenever you bump VERSION. It proves nothing about whether the bullets
# are true; it turns a silent omission into a caught failure.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
VERSION_FILE="$REPO_ROOT/VERSION"

# 1. CHANGELOG.md exists and has at least one section.
[ -f "$CHANGELOG" ] || die "Invariant 1: $CHANGELOG does not exist."
# The parser contract: '^## ' introduces a section and the first
# whitespace-delimited token after it is the version. Nothing else is read.
versions="$(sed -n 's/^## \([^[:space:]][^[:space:]]*\).*$/\1/p' "$CHANGELOG")"
[ -n "$versions" ] || die "Invariant 1: $CHANGELOG has no '## <version>' section."

# 2. The top section's version token equals the trimmed contents of VERSION.
[ -f "$VERSION_FILE" ] || die "Invariant 2: $VERSION_FILE does not exist, so the top section cannot be checked against it."
top_version="$(printf '%s\n' "$versions" | head -n 1)"
current_version="$(tr -d '[:space:]' < "$VERSION_FILE")"
if [ "$top_version" != "$current_version" ]; then
  die "Invariant 2: VERSION is $current_version but the top CHANGELOG.md section is $top_version — a VERSION bump without a matching section is an incomplete change."
fi

# 3. Version headers are strictly descending semver, with no duplicates.
order_problem="$(printf '%s\n' "$versions" | awk '
  function cmp(a, b,   i) {
    for (i = 1; i <= 3; i++) {
      if (a[i] + 0 > b[i] + 0) return 1
      if (a[i] + 0 < b[i] + 0) return -1
    }
    return 0
  }
  {
    if ($0 !~ /^[0-9]+\.[0-9]+\.[0-9]+$/) {
      printf "version header %s is not a semver triple", $0
      exit
    }
    split($0, cur, ".")
    if (NR > 1) {
      c = cmp(cur, prev)
      if (c == 0) { printf "version %s appears twice", $0; exit }
      if (c > 0)  { printf "version %s is listed below %s but is newer — sections must run in descending semver order", $0, prev_raw; exit }
    }
    for (i = 1; i <= 3; i++) prev[i] = cur[i]
    prev_raw = $0
  }
')"
[ -z "$order_problem" ] || die "Invariant 3: $order_problem."

# 4. The top section has at least one bullet.
top_body="$(awk '/^## /{ n++; if (n > 1) exit; next } n == 1' "$CHANGELOG")"
if ! printf '%s\n' "$top_body" | grep -q '^- '; then
  die "Invariant 4: the top CHANGELOG.md section ($top_version) has no bullets — a bump that forgot its content."
fi
