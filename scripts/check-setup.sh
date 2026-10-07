#!/usr/bin/env bash
# Guard the tie between the per-project facts shipped features read and the
# setup commands that offer them — commands/project-setup.md,
# commands/task-setup.md and commands/domain-setup.md — so that a feature
# which starts reading a CLAUDE.md line, a claude-md section or a VCS
# operation is caught at authoring time when setup does not offer it. Run it
# by hand after adding or changing a `project-policy:` declaration, adding a
# claude-md or hook feature, or editing a setup command.
#
# What it proves: presence. Every `project-policy:` spec on a shipped feature
# is well formed and offered — a `line:` marker and each of its values appear
# in the three setup bodies taken together, a `vcs:` op has a `git <op>` row
# in /project-setup's `## VCS` template, a `section:` names a shipped
# claude-md feature that /project-setup offers — and every shipped claude-md
# and hook feature is named by /project-setup, declared or not. What it cannot
# prove: that setup explains a fact well, writes it in the right place, or
# that a feature reading a fact declares it at all. Those halves are
# semantics, and stay a human's job.
#
# Repo-local and authoring-time only: not a feature, no frontmatter, invisible
# to every CLI verb, installed nowhere. Silent on success; one line per
# violation and a non-zero exit otherwise.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_SETUP="$REPO_ROOT/commands/project-setup.md"
SETUP_BODIES=("$PROJECT_SETUP" "$REPO_ROOT/commands/task-setup.md" "$REPO_ROOT/commands/domain-setup.md")

for f in "${SETUP_BODIES[@]}"; do
  [ -f "$f" ] || die "check-setup: setup body $f does not exist."
done

violations=0
violation() { printf '%s\n' "$1"; violations=$((violations + 1)); }

offered_by_setup()   { cat "${SETUP_BODIES[@]}" | grep -qF -- "$1"; }
offered_by_project() { grep -qF -- "$1" "$PROJECT_SETUP"; }
# A `## VCS` template row is a line beginning "- `git <op>" followed by a
# space or the closing backquote.
has_vcs_row()        { grep -qE -- "^- \`git $1( |\`)" "$PROJECT_SETUP"; }

# 1. Every declared spec is well formed and offered.
for file in "$REPO_ROOT"/commands/*.md "$REPO_ROOT"/skills/*/SKILL.md \
            "$REPO_ROOT"/claude-md/*.md "$REPO_ROOT"/hooks/*.sh "$REPO_ROOT"/statusline/*.sh; do
  [ -f "$file" ] || continue
  raw="$(read_frontmatter_field "$file" project-policy || true)"
  [ -n "$raw" ] || continue
  rel="${file#"$REPO_ROOT"/}"
  IFS=',' read -r -a specs <<< "$raw"
  for spec in "${specs[@]}"; do
    spec="$(printf '%s' "$spec" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$spec" ] || continue
    case "$spec" in
      *:*) kind="${spec%%:*}"; value="${spec#*:}" ;;
      *)   violation "$rel: project-policy spec '$spec' has no kind prefix (expected line:, section: or vcs:)."; continue ;;
    esac
    case "$kind" in
      line)
        case "$value" in
          *=*) ;;
          *) violation "$rel: project-policy spec '$spec' has no '=' — expected line:<marker>=<v1>|<v2>."; continue ;;
        esac
        marker="${value%%=*}"
        offered_by_setup "$marker" \
          || violation "$rel: line '$marker' is not offered by any setup command."
        IFS='|' read -r -a values <<< "${value#*=}"
        for v in "${values[@]}"; do
          [ -n "$v" ] || continue
          offered_by_setup "$v" \
            || violation "$rel: value '$v' of line '$marker' is not offered by any setup command."
        done
        ;;
      vcs)
        has_vcs_row "$value" \
          || violation "$rel: vcs op '$value' has no 'git $value' row in /project-setup's ## VCS template."
        ;;
      section)
        if [ ! -f "$REPO_ROOT/claude-md/$value.md" ]; then
          violation "$rel: section '$value' names no shipped claude-md feature."
        elif ! offered_by_project "$value"; then
          violation "$rel: section '$value' is not offered by /project-setup."
        fi
        ;;
      *)
        violation "$rel: project-policy spec '$spec' has unknown kind '$kind' (expected line:, section: or vcs:)."
        ;;
    esac
  done
done

# 2. Every shipped claude-md and hook feature is offered by /project-setup.
for file in "$REPO_ROOT"/claude-md/*.md "$REPO_ROOT"/hooks/*.sh; do
  [ -f "$file" ] || continue
  name="$(basename "$file")"; name="${name%.*}"
  offered_by_project "$name" \
    || violation "${file#"$REPO_ROOT"/}: shipped feature '$name' is not offered by /project-setup."
done

[ "$violations" -eq 0 ]
