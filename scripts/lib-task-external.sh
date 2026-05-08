#!/usr/bin/env bash
# Shared helpers for the external-LLM task orchestrator (cmd-task-impl.sh).
# Source this file; do not exec it. Sourcing lib.sh first is required —
# this lib uses log_info/log_warn/log_error/die from there.
# shellcheck shell=bash

# ---------- paths ----------

# project_tasks_index — path to the backlog index in the current project.
project_tasks_index() { printf '%s/.claude/TASKS.md' "${PROJECT_ROOT:-$PWD}"; }

# project_task_body <N> — path to a task's body file in the current project.
project_task_body() { printf '%s/.claude/tasks/%s.md' "${PROJECT_ROOT:-$PWD}" "$1"; }

# project_external_dir — path to the per-project external-LLM artifacts.
project_external_dir() { printf '%s/.claude/external' "${PROJECT_ROOT:-$PWD}"; }

# ---------- TASKS.md parsing ----------

# task_summary_block <N>
# Prints the summary block for task <N> from .claude/TASKS.md, or empty
# if the task is not present. The block runs from the `## <N>. <title>`
# heading up to (but not including) the next `---` separator or EOF.
task_summary_block() {
  local n="$1"
  local index
  index="$(project_tasks_index)"
  [ -f "$index" ] || return 1
  awk -v n="$n" '
    BEGIN { in_block = 0 }
    /^## [0-9]+\. / {
      # match e.g. "## 3. Title" — capture leading number
      num = $2
      sub(/\./, "", num)
      if (num == n) { in_block = 1; print; next }
      else if (in_block) { exit }
      else { next }
    }
    /^---[[:space:]]*$/ {
      if (in_block) exit
      next
    }
    in_block { print }
  ' "$index"
}

# task_field <N> <field>
# Prints the value of a `Field:` line from task <N>'s summary block.
# Field names: Status, Files, Preconditions, Title.
# `Title` is synthetic — extracted from the heading.
task_field() {
  local n="$1" field="$2"
  local block
  block="$(task_summary_block "$n")" || return 1
  [ -n "$block" ] || return 1
  case "$field" in
    Title)
      printf '%s\n' "$block" | awk -v n="$n" '
        $0 ~ "^## " n "\\. " {
          sub("^## " n "\\. ", "")
          print
          exit
        }
      '
      ;;
    *)
      printf '%s\n' "$block" | awk -v f="$field" '
        $0 ~ "^"f":[[:space:]]" {
          sub("^"f":[[:space:]]+", "")
          print
          exit
        }
      '
      ;;
  esac
}

# task_status <N>      — convenience: prints "[MISSING]", "[DONE]", etc.
task_status()        { task_field "$1" Status; }
# task_files <N>       — comma-separated files list.
task_files()         { task_field "$1" Files; }
# task_title <N>       — the task title.
task_title()         { task_field "$1" Title; }
# task_preconditions <N> — comma-separated task numbers or "none".
task_preconditions() { task_field "$1" Preconditions; }

# ---------- TASKS.md mutation ----------

# flip_task_status <N> <new-status>
# Replaces the `Status:` line in task <N>'s summary block. <new-status>
# must include the brackets, e.g. "[IN PROGRESS]". Atomic: writes to a
# tempfile and renames.
flip_task_status() {
  local n="$1" new="$2"
  local index tmp
  index="$(project_tasks_index)"
  [ -f "$index" ] || die "TASKS.md not found at $index"
  tmp="$(mktemp "${index}.XXXXXX")"
  awk -v n="$n" -v new="$new" '
    BEGIN { in_block = 0 }
    /^## [0-9]+\. / {
      num = $2; sub(/\./, "", num)
      in_block = (num == n)
      print; next
    }
    /^---[[:space:]]*$/ { in_block = 0; print; next }
    in_block && /^Status:[[:space:]]/ {
      print "Status: " new
      next
    }
    { print }
  ' "$index" > "$tmp"
  mv "$tmp" "$index"
}

# ---------- per-project wrapper detection ----------

# external_artifact <name> — path under .claude/external/.
external_artifact() { printf '%s/%s' "$(project_external_dir)" "$1"; }

# require_external_artifacts
# Errors out if any of the three orchestrator-required artifacts is
# missing under .claude/external/.
require_external_artifacts() {
  local missing=0
  local f
  for f in implement-prompt.md tests-prompt.md run-affected-tests.sh run-full-tests.sh; do
    if [ ! -f "$(external_artifact "$f")" ]; then
      log_error "Missing .claude/external/$f"
      missing=1
    fi
  done
  if [ $missing -ne 0 ]; then
    die "Project is not initialized for external-LLM task implementation. Run /task-setup first."
  fi
  if [ ! -x "$(external_artifact run-affected-tests.sh)" ] || [ ! -x "$(external_artifact run-full-tests.sh)" ]; then
    die "Wrapper scripts under .claude/external/ are not executable. Re-run /task-setup."
  fi
}

# wrappers_are_stubs
# Returns 0 (true) if the wrapper scripts are no-op stubs (skip-tests
# mode), 1 otherwise. Stubs are identified by a sentinel marker line:
#   # CHOSKO_TASK_IMPL_STUB
wrappers_are_stubs() {
  grep -q '^# CHOSKO_TASK_IMPL_STUB$' "$(external_artifact run-full-tests.sh)" 2>/dev/null
}

# ---------- git ----------

# require_clean_tree
# Errors out if the working tree has uncommitted changes (other than
# untracked files matched by .gitignore — `git status --porcelain`
# already respects that).
require_clean_tree() {
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    die "Working tree is dirty. Commit or stash before running task-impl."
  fi
}
