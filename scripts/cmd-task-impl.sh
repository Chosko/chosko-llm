#!/usr/bin/env bash
# cmd-task-impl.sh — orchestrate the 8-step /task-implement sequence for
# external LLMs (qwen2.5-coder:14b via aider). Runs against the current
# project (cwd). One commit per task.
#
# Usage:  chosko-llm task-impl <N> [<N>…]
#         chosko-llm task-impl all
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
# shellcheck source=lib-task-external.sh
source "$SCRIPT_DIR/lib-task-external.sh"

PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
RETRIES="${CHOSKO_TASK_IMPL_RETRIES:-3}"
AIDER_MODEL="${CHOSKO_TASK_IMPL_MODEL:-ollama/qwen2.5-coder:14b}"
AIDER_MAP_TOKENS="${CHOSKO_TASK_IMPL_AIDER_MAP_TOKENS:-}"

usage() {
  cat <<'EOF' >&2
Usage: chosko-llm task-impl [OPTIONS] <N> [<N>…]
       chosko-llm task-impl [OPTIONS] all

Orchestrates the 8-step task-implement sequence for the current
project, driving aider + Ollama. Requires the project to have been
initialized via /task-setup.

Options:
  --model <name>      Aider --model arg. Overrides CHOSKO_TASK_IMPL_MODEL.
  --retries <N>       Retry budget per task. Overrides CHOSKO_TASK_IMPL_RETRIES.
  --map-tokens <N>    Aider --map-tokens arg. Overrides CHOSKO_TASK_IMPL_AIDER_MAP_TOKENS.
                      When absent and env var is unset, --map-tokens is not passed to aider.

Environment:
  CHOSKO_TASK_IMPL_RETRIES          Retry budget per task (default: 3).
  CHOSKO_TASK_IMPL_AIDER            aider executable (default: aider).
  CHOSKO_TASK_IMPL_MODEL            Aider --model arg (default: ollama/qwen2.5-coder:14b).
  CHOSKO_TASK_IMPL_AIDER_MAP_TOKENS Aider --map-tokens arg (default: unset, flag omitted).
EOF
}

if [ $# -lt 1 ]; then
  usage; exit 2
fi

# Fast-path: --help anywhere in argv
for _a in "$@"; do
  if [ "$_a" = "--help" ]; then usage; exit 0; fi
done

# ---------- argument parsing ----------

declare -a TASKS=()
declare -a _rawargs=("$@")
_i=0
while [ "$_i" -lt "${#_rawargs[@]}" ]; do
  _arg="${_rawargs[$_i]}"
  case "$_arg" in
    --model=*)
      AIDER_MODEL="${_arg#--model=}"
      [ -n "$AIDER_MODEL" ] || die "--model requires a non-empty value"
      ;;
    --model)
      _i=$((_i + 1))
      if [ "$_i" -ge "${#_rawargs[@]}" ] || [[ "${_rawargs[$_i]}" == --* ]]; then
        die "--model requires a value"
      fi
      AIDER_MODEL="${_rawargs[$_i]}"
      [ -n "$AIDER_MODEL" ] || die "--model requires a non-empty value"
      ;;
    --retries=*)
      _val="${_arg#--retries=}"
      [[ "$_val" =~ ^[0-9]+$ ]] || die "--retries value must be a non-negative integer: ${_val:-<empty>}"
      RETRIES="$_val"
      ;;
    --retries)
      _i=$((_i + 1))
      if [ "$_i" -ge "${#_rawargs[@]}" ] || [[ "${_rawargs[$_i]}" == --* ]]; then
        die "--retries requires a value"
      fi
      _val="${_rawargs[$_i]}"
      [[ "$_val" =~ ^[0-9]+$ ]] || die "--retries value must be a non-negative integer: $_val"
      RETRIES="$_val"
      ;;
    --map-tokens=*)
      _val="${_arg#--map-tokens=}"
      [[ "$_val" =~ ^[0-9]+$ ]] || die "--map-tokens value must be a non-negative integer: ${_val:-<empty>}"
      AIDER_MAP_TOKENS="$_val"
      ;;
    --map-tokens)
      _i=$((_i + 1))
      if [ "$_i" -ge "${#_rawargs[@]}" ] || [[ "${_rawargs[$_i]}" == --* ]]; then
        die "--map-tokens requires a value"
      fi
      _val="${_rawargs[$_i]}"
      [[ "$_val" =~ ^[0-9]+$ ]] || die "--map-tokens value must be a non-negative integer: $_val"
      AIDER_MAP_TOKENS="$_val"
      ;;
    --*)
      die "Unknown flag: $_arg"
      ;;
    *)
      TASKS+=("$_arg")
      ;;
  esac
  _i=$((_i + 1))
done

if [ "${#TASKS[@]}" -eq 0 ]; then
  usage; exit 2
fi

# ---------- pre-flight ----------

[ -f "$(project_tasks_index)" ] || die "No backlog at $(project_tasks_index). Run /task-setup, then /task-add."
require_external_artifacts

AIDER="${CHOSKO_TASK_IMPL_AIDER:-aider}"
command -v "$AIDER" >/dev/null 2>&1 || die "aider not found on PATH (looked for: $AIDER). Install aider or set CHOSKO_TASK_IMPL_AIDER."

SKIP_TESTS=0
if wrappers_are_stubs; then
  SKIP_TESTS=1
  log_warn "Project is in skip-tests mode (wrapper scripts are stubs). Steps 2/3/5/6 will be skipped; per-task confirmation required."
fi

# ---------- argument resolution ----------

resolve_all() {
  # Print task numbers in document order whose status is one of
  # MISSING / STUBBED / INCORRECT / PARTIAL.
  awk '
    /^## [0-9]+\. / {
      num = $2; sub(/\./, "", num)
      cur = num
      have_status[cur] = 0
      next
    }
    /^Status:[[:space:]]/ {
      if (cur != "") {
        s = $0
        sub(/^Status:[[:space:]]+/, "", s)
        status[cur] = s
        order[++n] = cur
        have_status[cur] = 1
      }
    }
    END {
      for (i = 1; i <= n; i++) {
        c = order[i]
        s = status[c]
        if (s == "[MISSING]" || s == "[STUBBED]" || s == "[INCORRECT]" || s == "[PARTIAL]") {
          print c
        }
      }
    }
  ' "$(project_tasks_index)"
}

if [ "${TASKS[0],,}" = "all" ]; then
  mapfile -t TASKS < <(resolve_all)
  [ "${#TASKS[@]}" -gt 0 ] || die "No implementable tasks (MISSING/STUBBED/INCORRECT/PARTIAL) in backlog."
  log_info "Will implement (in order): ${TASKS[*]}"
fi

# Validate all targets up front.
for n in "${TASKS[@]}"; do
  if ! [[ "$n" =~ ^[0-9]+$ ]]; then
    die "Not a task number: $n"
  fi
  block="$(task_summary_block "$n" || true)"
  [ -n "$block" ] || die "Task $n not found in $(project_tasks_index)."
  body="$(project_task_body "$n")"
  [ -f "$body" ] || die "Task $n body file missing at $body. Backlog is corrupt."
done

# ---------- per-task workflow ----------

confirm_proceed() {
  local n="$1" title="$2"
  printf 'About to implement task %s — %s. Proceed? [y/N] ' "$n" "$title" >&2
  local answer=""
  read -r answer </dev/tty || answer=""
  case "${answer,,}" in
    y|yes) return 0 ;;
    *) die "Aborted by user before task $n." ;;
  esac
}

run_aider() {
  # run_aider <prompt-file> <body-file> <message>
  # Invokes aider non-interactively. The model is told *what* to do via
  # the prompt file (system prompt) and the task body file (read-only
  # context). The <message> is the per-invocation instruction.
  local prompt="$1" body="$2" message="$3"
  local -a _cmd=(
    "$AIDER"
    --model "$AIDER_MODEL"
    --read "$prompt"
    --read "$body"
    --yes-always
    --no-auto-commits
    --message "$message"
  )
  if [ -n "$AIDER_MAP_TOKENS" ]; then _cmd+=(--map-tokens "$AIDER_MAP_TOKENS"); fi
  "${_cmd[@]}"
}

implement_one() {
  local n="$1"
  local title status files body
  title="$(task_title "$n")"
  status="$(task_status "$n")"
  files="$(task_files "$n")"
  body="$(project_task_body "$n")"

  case "$status" in
    "[MISSING]"|"[STUBBED]"|"[INCORRECT]"|"[PARTIAL]") ;;
    *)
      log_warn "Task $n status is $status; skipping."
      return 0
      ;;
  esac

  require_clean_tree

  if [ "$SKIP_TESTS" -eq 1 ]; then
    confirm_proceed "$n" "$title"
  fi

  log_info "=== Task $n: $title ==="

  # Step 1 — IN PROGRESS
  flip_task_status "$n" "[IN PROGRESS]"

  # Convert comma-separated files list to array (trim whitespace).
  declare -a file_list=()
  IFS=',' read -r -a _raw <<<"$files"
  for f in "${_raw[@]}"; do
    f="${f#"${f%%[![:space:]]*}"}"; f="${f%"${f##*[![:space:]]}"}"
    [ -n "$f" ] && file_list+=("$f")
  done

  # Affected test files = subset of file_list that lives under tests/
  # or ends in _test.* / .test.* / Test.*. The orchestrator does no
  # smarter detection — it relies on the task spec naming the test files
  # explicitly under Files:.
  declare -a test_files=()
  for f in "${file_list[@]}"; do
    case "$f" in
      tests/*|test/*|*_test.*|*.test.*|*Test.*) test_files+=("$f") ;;
    esac
  done

  if [ "$SKIP_TESTS" -eq 0 ]; then
    # Step 2 — write/extend tests via aider
    log_info "Step 2: writing tests via aider"
    run_aider "$(external_artifact tests-prompt.md)" "$body" \
      "Write or extend the test files for this task only. Do not modify production code yet."$'\n\n'"Respond in English."

    # Step 3 — affected tests must fail
    log_info "Step 3: running affected tests, expecting failure"
    if [ "${#test_files[@]}" -gt 0 ]; then
      if "$(external_artifact run-affected-tests.sh)" "${test_files[@]}"; then
        flip_task_status "$n" "[IN PROGRESS]"
        die "Task $n: new tests passed unexpectedly — they don't assert what the task intends. Stopping."
      fi
    else
      log_warn "Task $n has no test files in Files:; cannot watch fail. Continuing."
    fi
  fi

  # Step 4 — implement, with retry on test failure
  log_info "Step 4: implementing via aider (retry budget: $RETRIES)"
  local attempt=1
  local impl_ok=0
  local last_log=""
  while [ "$attempt" -le "$RETRIES" ]; do
    local msg="Implement the task. Edit only the files listed under \"Files to modify\"."
    if [ -n "$last_log" ]; then
      msg="The previous attempt did not pass the tests. Failure log follows. Fix the implementation; do not weaken the tests."$'\n\n'"$last_log"
    fi
    msg="$msg"$'\n\n'"Respond in English."
    run_aider "$(external_artifact implement-prompt.md)" "$body" "$msg" || true

    if [ "$SKIP_TESTS" -eq 1 ]; then
      impl_ok=1
      break
    fi

    log_info "Step 5: running affected tests"
    last_log="$( { "$(external_artifact run-affected-tests.sh)" "${test_files[@]}"; } 2>&1 || true)"
    if "$(external_artifact run-affected-tests.sh)" "${test_files[@]}" >/dev/null 2>&1; then
      impl_ok=1
      break
    fi
    log_warn "Affected tests still failing on attempt $attempt/$RETRIES"
    attempt=$((attempt + 1))
  done

  if [ "$impl_ok" -ne 1 ]; then
    die "Task $n: affected tests still failing after $RETRIES attempts. Status left as [IN PROGRESS]. Run halted."
  fi

  if [ "$SKIP_TESTS" -eq 0 ]; then
    # Step 6 — full suite
    log_info "Step 6: running full test suite"
    attempt=1
    local full_ok=0
    while [ "$attempt" -le "$RETRIES" ]; do
      last_log="$( { "$(external_artifact run-full-tests.sh)"; } 2>&1 || true)"
      if "$(external_artifact run-full-tests.sh)" >/dev/null 2>&1; then
        full_ok=1; break
      fi
      log_warn "Full suite failing on attempt $attempt/$RETRIES — re-invoking aider"
      run_aider "$(external_artifact implement-prompt.md)" "$body" \
        "The affected tests pass but the full suite is failing. Failure log follows. Fix without weakening any test."$'\n\n'"$last_log"$'\n\n'"Respond in English." || true
      attempt=$((attempt + 1))
    done
    if [ "$full_ok" -ne 1 ]; then
      die "Task $n: full suite still failing after $RETRIES attempts. Status left as [IN PROGRESS]."
    fi
  fi

  # Step 7 — DONE
  flip_task_status "$n" "[DONE]"

  # Step 8 — commit
  declare -a stage=("$(project_tasks_index)")
  for f in "${file_list[@]}"; do
    stage+=("$PROJECT_ROOT/$f")
  done
  ( cd "$PROJECT_ROOT" && git add -- "${stage[@]}" )
  local body_note=""
  if [ "$SKIP_TESTS" -eq 1 ]; then
    body_note=$'\n\n(no tests — manual verification pending)'
  fi
  ( cd "$PROJECT_ROOT" && git commit -m "Task $n: $title$body_note" )
  log_info "Task $n committed."
}

for n in "${TASKS[@]}"; do
  implement_one "$n"
done

log_info "All requested tasks complete."
