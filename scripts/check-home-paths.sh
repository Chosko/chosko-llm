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
# What it cannot prove: that a relative citation actually resolves to a file
# (that is a human's read, and the acceptance criteria of whatever task wrote
# it); that a citation wrapped across THREE or more lines is caught, since the
# wrap pass uses a two-line window; nor that a body which assigns the home to a
# shell variable and joins a path onto that variable is scope-correct. The
# `installed` and `council` probes in
# skills/pipeline-engine/references/probes.md are the repo's one case of that
# last kind: they run from the project root, where there is no citing body to
# be relative to, so they stay bound to the global home. That is current
# behaviour this guard does not police, not a decision this guard makes.
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
# root of a path to another shipped file. A bare literal with no path segment
# joined onto it is prose (or a shell assignment) and is not matched.
home='(\$\{CLAUDE_HOME:-\$HOME/\.claude\}|\$HOME/\.claude|~/\.claude)'
pattern="$home/(skills|commands)/"

# Pass 1 — the citation on one line.
hits="$(grep -rnE "$pattern" "$REPO_ROOT/commands" "$REPO_ROOT/skills" || true)"

# Pass 2 — the same citation wrapped across a line break. Markdown prose wraps
# long paths, and pass 1 sees one line at a time, so a wrap would slip through
# in silence. Each file is re-scanned over a two-line window: the leading
# blockquote marker and indentation of the continuation line are stripped, the
# pair is joined, and a match that neither line produced on its own is an
# offence reported against the line the literal starts on.
wrapped="$(
  find "$REPO_ROOT/commands" "$REPO_ROOT/skills" -type f -print0 \
    | xargs -0 awk -v pat="$pattern" '
        FNR == 1 { prev = ""; prevno = 0 }
        {
          cur = $0
          cont = cur
          sub(/^[[:space:]]*>?[[:space:]]*/, "", cont)
          if (prev != "" && (prev cont) ~ pat && prev !~ pat && cur !~ pat)
            printf "%s:%d:%s\n", FILENAME, prevno, prev cont
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
