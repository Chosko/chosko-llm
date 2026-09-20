#!/usr/bin/env bash
# Guard the citation form of every shipped body under commands/ and skills/:
# a body that names another shipped file must name it by a path RELATIVE TO
# ITSELF, never by an absolute install home. Run it by hand whenever you edit
# a shipped body.
#
# Why: `chosko-llm add --local` repoints CLAUDE_HOME to $PWD/.claude for the
# duration of the install (scripts/lib.sh), but the executing agent expands
# `${CLAUDE_HOME:-$HOME/.claude}` itself at run time and always lands on the
# global home. So an absolute-home citation reads a different copy, or
# nothing, on every --local install — and it fails silently, which is what
# this guard turns into a caught failure.
#
# What it proves: no file under commands/ or skills/ joins an install-home
# literal — `${CLAUDE_HOME:-$HOME/.claude}`, `$HOME/.claude` or `~/.claude` —
# to a `skills/` or `commands/` path segment, whether the two sit on one line
# or the citation is wrapped across a line break (markdown prose wraps these,
# and a line-based grep alone would miss it).
#
# The one exception, and it is narrow: a SCOPE PROBE — a body asking whether a
# feature is installed at all, which has to look in both scopes Claude Code
# loads from and so cannot be relative to anything. A matching line carrying
# the marker `scope-probe` is permitted. The marker is deliberate, greppable
# and cannot be tripped by accident; it is never a way to cite a file.
# `skills/{architect,product-design}/council-gate.md` are the only two lines
# that carry it. The probe snippet in
# skills/pipeline-engine/references/probes.md needs no marker: it derives its
# homes into shell variables, which this pattern does not match.
#
# What it cannot prove: that a relative citation actually resolves to a file
# (that is a human's read, and the acceptance criteria of whatever task wrote
# it); that a citation wrapped across THREE or more lines is caught, since the
# wrap pass uses a two-line window; that a `scope-probe` marker is honestly
# placed; nor that a body which derives an install home into a shell variable
# and joins a path onto it looks in the right scopes. That last one is a
# reviewer's read: probes.md § "Which install home — both of them" is where
# the rule it has to satisfy is written.
#
# Repo-local and authoring-time only: not a feature, no frontmatter, invisible
# to every CLI verb, installed nowhere.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

for dir in commands skills; do
  [ -d "$REPO_ROOT/$dir" ] || die "$REPO_ROOT/$dir does not exist."
done

# The parser contract: an offence is one of the three home literals followed
# by a '/skills/' or '/commands/' path segment — i.e. the literal used as the
# root of a path to another shipped file — on a line that does NOT carry the
# `scope-probe` marker. A bare literal with no path segment joined onto it is
# prose (or a shell assignment) and is not matched either way.
home='(\$\{CLAUDE_HOME:-\$HOME/\.claude\}|\$HOME/\.claude|~/\.claude)'
pattern="$home/(skills|commands)/"
exempt='scope-probe'

# Pass 1 — the citation on one line.
hits="$(grep -rnE "$pattern" "$REPO_ROOT/commands" "$REPO_ROOT/skills" \
  | grep -vE "$exempt" || true)"

# Pass 2 — the same citation wrapped across a line break. Markdown prose wraps
# long paths, and pass 1 sees one line at a time, so a wrap would slip through
# in silence. Each file is re-scanned over a two-line window: the leading
# blockquote marker and indentation of the continuation line are stripped, the
# pair is joined, and a match that neither line produced on its own is an
# offence reported against the line the literal starts on.
wrapped="$(
  find "$REPO_ROOT/commands" "$REPO_ROOT/skills" -type f -print0 \
    | xargs -0 awk -v pat="$pattern" -v exempt="$exempt" '
        FNR == 1 { prev = ""; prevno = 0 }
        {
          cur = $0
          cont = cur
          sub(/^[[:space:]]*>?[[:space:]]*/, "", cont)
          joined = prev cont
          if (prev != "" && joined ~ pat && prev !~ pat && cur !~ pat && joined !~ exempt)
            printf "%s:%d:%s\n", FILENAME, prevno, joined
          prev = cur; prevno = FNR
        }' || true
)"

[ -n "$wrapped" ] && hits="${hits:+$hits
}$wrapped"

if [ -n "$hits" ]; then
  while IFS= read -r line; do
    log_error "${line#"$REPO_ROOT"/}"
  done <<< "$hits"
  die "Shipped bodies must cite another shipped file by a path relative to themselves — './<file>.md' within one skill, '../<other>/references/<file>.md' from another skill's SKILL.md, '../../<other>/references/<file>.md' from another skill's reference file, '../skills/<other>/references/<file>.md' from a command. See docs/authoring-guide.md § requires:."
fi
