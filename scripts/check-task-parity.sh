#!/usr/bin/env bash
# Guard the cheap-to-check invariants shared by the two encodings of the
# 8-step task workflow: the /task-implement prompt (English, under
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
# there (it excludes non-eligible tasks by omission).
CANONICAL_TAGS='[DONE]
[IN PROGRESS]
[INCORRECT]
[MISSING]
[PARTIAL]
[SKIP]
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
Step 7
Step 8'

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

# 3. Both sides encode the same 8 per-task steps.
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

if [ "$failures" -gt 0 ]; then
  die "task-implement parity check failed with $failures problem(s)."
fi
log_success "task-implement parity check passed: status vocabulary and 8-step workflow agree."
