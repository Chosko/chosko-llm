#!/usr/bin/env bash
# Guard the two cheap invariants of the pipeline routing table,
# skills/pipeline-engine/references/routing.md — the ownership authority the
# revision suite reads — so that a row naming a feature this repo no longer
# ships, or an engine consumer with no row, is caught at authoring time rather
# than by a run that trusted the table. Run it by hand whenever you add,
# rename, remove or re-kind a pipeline feature, or edit the table.
#
# What it proves: existence, in both directions — every row names a feature
# that exists here, as a command or as a skill, and every shipped feature that
# declares `requires: skill:pipeline-engine` has a row. What it cannot prove:
# whether a row's Consumes / Produces / Owns / Preconditions / Argument shape
# entries are true, or that a pipeline feature which does not read the engine
# has a row at all. Those halves are semantics, and stay a human's job.
#
# Repo-local and authoring-time only: not a feature, no frontmatter, invisible
# to every CLI verb, installed nowhere.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TABLE="$REPO_ROOT/skills/pipeline-engine/references/routing.md"

[ -f "$TABLE" ] || die "Invariant 1: $TABLE does not exist."
# The parser contract: a row is a line beginning '| `' — a table row whose
# first cell is a backquoted feature name — and the name is the text inside
# that first pair of backquotes, with one leading '/' stripped. The header
# row, the '| --- |' separator and every line not beginning '| `' are ignored,
# and no cell after the first is read. probes.md's `installed` probe reads
# rows by the same shape.
rows="$(sed -n 's/^| `\/\{0,1\}\([^`]*\)`.*$/\1/p' "$TABLE")"
[ -n "$rows" ] || die "Invariant 1: $TABLE has no rows — no line begins '| \`<feature>\`'."

# 1. Every row names a feature that exists in this repo, as either kind.
while IFS= read -r name; do
  [ -f "$REPO_ROOT/commands/$name.md" ] || [ -f "$REPO_ROOT/skills/$name/SKILL.md" ] \
    || die "Invariant 1: routing.md row '$name' names no feature in this repo — looked for commands/$name.md and skills/$name/SKILL.md."
done <<< "$rows"

# 2. Every shipped feature that declares the engine in `requires:` has a row.
# Its name is its path's, which its frontmatter `name:` already has to match.
for file in "$REPO_ROOT"/commands/*.md "$REPO_ROOT"/skills/*/SKILL.md; do
  [ -f "$file" ] || continue
  specs="$(requires_specs "$file")" || exit 1
  case $'\n'"$specs"$'\n' in
    *$'\n'skill:pipeline-engine$'\n'*) ;;
    *) continue ;;
  esac
  case "$file" in
    */SKILL.md) name="$(basename "$(dirname "$file")")" ;;
    *)          name="$(basename "$file" .md)" ;;
  esac
  case $'\n'"$rows"$'\n' in
    *$'\n'"$name"$'\n'*) ;;
    *) die "Invariant 2: $name declares requires: skill:pipeline-engine but has no row in routing.md." ;;
  esac
done
