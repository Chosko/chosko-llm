#!/usr/bin/env bash
# Guard the cheap-to-check invariants shared by the two encodings of the
# 7-step task workflow: the /task-implement prompt (English, under
# skills/task-implement/) and cmd-task-impl.sh (bash). It does not prove
# full parity — it turns silent drift in the status vocabulary or the step
# count into a caught diff.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPT_DIR="$REPO_ROOT/skills/task-implement"
BASH_FILES=("$REPO_ROOT/scripts/cmd-task-impl.sh" "$REPO_ROOT/scripts/lib-task-external.sh")

[ -f "$PROMPT_DIR/SKILL.md" ] || die "Prompt side missing: $PROMPT_DIR/SKILL.md"
for f in "${BASH_FILES[@]}"; do
  [ -f "$f" ] || die "Bash side missing: $f"
done

PROMPT_FILES=()
for f in "$PROMPT_DIR"/*.md; do
  [ -e "$f" ] || continue
  PROMPT_FILES+=("$f")
done

# The full status vocabulary. The prompt must know every tag; the bash side
# drives only the statuses it can act on, so [SKIP] is legitimately absent
# there (it excludes non-eligible tasks by omission). [STALE] follows the
# same precedent for the opposite reason: the prompt may implement a stale
# task on the user's say-so, but the unattended orchestrator refuses one, so
# it is never a status the bash side acts *on*.
CANONICAL_TAGS='[DONE]
[IN PROGRESS]
[INCORRECT]
[MISSING]
[PARTIAL]
[SKIP]
[STALE]
[STUBBED]'
BASH_REQUIRED_TAGS='[DONE]
[IN PROGRESS]
[INCORRECT]
[MISSING]
[PARTIAL]
[STUBBED]'
# Bracketed uppercase tokens that are not status tags.
NON_STATUS_TAGS='[OPTIONS]'

WORKFLOW_STEPS='Step 1
Step 2
Step 3
Step 4
Step 5
Step 6
Step 7'

tags_in()  { grep -oh '\[[A-Z][A-Z ]*\]' "$@" 2>/dev/null | sort -u || true; }
steps_in() { grep -oh 'Step [0-9]'       "$@" 2>/dev/null | sort -u || true; }

failures=0
fail() { log_error "$*"; failures=$((failures + 1)); }

# Report every line in $1 that is absent from $2.
missing_from() { comm -23 <(printf '%s\n' "$1") <(printf '%s\n' "$2"); }

prompt_tags="$(tags_in "${PROMPT_FILES[@]}")"
bash_tags="$(tags_in "${BASH_FILES[@]}")"
known_tags="$(printf '%s\n%s\n' "$CANONICAL_TAGS" "$NON_STATUS_TAGS" | sort -u)"

# 1. No unknown bracketed tag on either side — catches a fake/typo'd status.
while IFS= read -r t; do
  [ -n "$t" ] && fail "Unknown status tag on the prompt side: $t (not in the canonical vocabulary)"
done < <(missing_from "$prompt_tags" "$known_tags")

while IFS= read -r t; do
  [ -n "$t" ] && fail "Unknown status tag on the bash side: $t (not in the canonical vocabulary)"
done < <(missing_from "$bash_tags" "$known_tags")

# 2. No canonical tag dropped from either side.
while IFS= read -r t; do
  [ -n "$t" ] && fail "Status tag $t is in the canonical vocabulary but absent from the prompt (skills/task-implement/)"
done < <(missing_from "$CANONICAL_TAGS" "$prompt_tags")

while IFS= read -r t; do
  [ -n "$t" ] && fail "Status tag $t is acted on by the prompt but absent from the bash side (scripts/cmd-task-impl.sh, scripts/lib-task-external.sh)"
done < <(missing_from "$BASH_REQUIRED_TAGS" "$bash_tags")

# 3. Both sides encode the same 7 per-task steps.
prompt_steps="$(steps_in "${PROMPT_FILES[@]}")"
bash_steps="$(steps_in "${BASH_FILES[@]}")"

while IFS= read -r s; do
  [ -n "$s" ] && fail "$s is missing from the prompt side"
done < <(missing_from "$WORKFLOW_STEPS" "$prompt_steps")

while IFS= read -r s; do
  [ -n "$s" ] && fail "$s is missing from the bash side"
done < <(missing_from "$WORKFLOW_STEPS" "$bash_steps")

while IFS= read -r s; do
  [ -n "$s" ] && fail "Prompt side has an extra workflow step not in the bash side: $s"
done < <(missing_from "$prompt_steps" "$WORKFLOW_STEPS")

while IFS= read -r s; do
  [ -n "$s" ] && fail "Bash side has an extra workflow step not in the prompt: $s"
done < <(missing_from "$bash_steps" "$WORKFLOW_STEPS")

# 4. Target-field gating (added by task 85 / documented across the prompt
# side). The unattended orchestrator hard-refuses any task whose Target is
# not exactly `claude`; the prompt side documents all four Target values
# and how each is handled. Neither side should be able to silently drop
# that coverage, so check both — grep-based, not a behavioral test.
bash_blob="$(cat "${BASH_FILES[@]}" 2>/dev/null || true)"
prompt_blob="$(cat "${PROMPT_FILES[@]}" 2>/dev/null || true)"

if ! printf '%s' "$bash_blob" | grep -q '!= "claude"'; then
  fail "Bash side (scripts/cmd-task-impl.sh) no longer gates on Target != claude — task 85's hard-refuse check for non-claude targets may have regressed."
fi

for v in 'claude+human' 'human' 'local'; do
  if ! printf '%s' "$bash_blob" | grep -qF -- "$v"; then
    fail "Bash side (scripts/cmd-task-impl.sh, scripts/lib-task-external.sh) no longer mentions Target value '$v' — task 85's hard-refuse logic for non-claude targets may have regressed."
  fi
done

for v in 'claude' 'local' 'claude+human' 'human'; do
  if ! printf '%s' "$prompt_blob" | grep -qF -- "Target: $v"; then
    fail "Prompt side (skills/task-implement/) no longer documents Target: $v — target-gating documentation may have regressed."
  fi
done

if [ "$failures" -gt 0 ]; then
  die "task-implement parity check failed with $failures problem(s)."
fi
log_success "task-implement parity check passed: status vocabulary, 7-step workflow, and Target-field gating agree."
