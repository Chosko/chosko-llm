---
name: context-budget
type: skill
description: Repo-local audit for chosko-llm itself — inventories every shipped body (commands, skill bodies, skill reference files, claude-md artifacts, the CLAUDE.md chain), estimates its token cost, and reports a ranked table with an estimated saving per flagged item and a total. Read-only, and not a gate: it makes cost visible, it does not say what to cut. Pass --verbose for a per-file breakdown.
---

# /context-budget
# Repo-local skill for `chosko-llm`'s own development. Inventories the bodies
# this repo ships, estimates what each costs a context window, and reports a
# ranked table. Read-only — writes nothing, ever.
# Usage: /context-budget
#        /context-budget --verbose

**No `version:` in the frontmatter, deliberately.** That field exists for
`cmd-add` / `cmd-update`, which walk `$CHOSKO_LLM_HOME/commands|skills|…` and
will never see a file under this repo's own `.claude/skills/`. `name`, `type`
and `description` stay, because Claude Code needs them.

GOAL
This repo ships prompts, and its product thesis is token-lean navigation. This
skill is how that thesis gets checked against what the repo actually ships:
walk every shipped body, estimate its token cost, flag the ones over a
threshold, and print the numbers. Nothing else.

A tool for building the product is not part of the product. This one lives
under `.claude/skills/`, is invocable only while working in this repository,
and is installed nowhere.

$ARGUMENTS

---

ARGUMENT PARSING

`--verbose` is the only argument. If present, set VERBOSE = true and strip it.
Anything else left in `$ARGUMENTS` is unrecognized: say so in one line and run
the default report anyway. This skill never refuses over its own arguments.

---

NOT A GATE

State this in the report, and mean it. A 2,109-line reference file may be
exactly right — `skills/unity-mcp-skill/` covers a large external surface, and
covering it takes the space it takes. A flag is an observation that something
costs a lot, not a claim that it should cost less.

So: **no recommendations about what to cut.** The numbers are the output; the
judgement is the author's. Do not rank by "worst offender", do not suggest a
split, do not propose a target size, and do not open a task.

---

INVENTORY — what is walked

| Set | Scope |
| --- | --- |
| Commands | `commands/*.md` |
| Skill bodies | `skills/*/SKILL.md` |
| Skill supporting files | every other file under `skills/*/`, at any depth |
| claude-md artifacts | `claude-md/*.md` |
| The `CLAUDE.md` chain | this repo's root `CLAUDE.md`, every nested `CLAUDE.md`, and any file they `@`-import |

`statusline/*.sh` and `hooks/*.sh` are deliberately out of scope: they are
shell scripts Claude Code executes, not bodies loaded into a context window.

Collect the counts in one pass, deterministically — the model classifies and
ranks, it does not eyeball sizes:

`-size +0c` matters: `skills/.gitkeep` and friends are empty, and a zero-line
file divides by zero in every per-line figure below.

```bash
for f in $(find commands claude-md -maxdepth 1 -name '*.md' -size +0c 2>/dev/null; \
           find skills -type f -size +0c 2>/dev/null | sort); do
  awk '
    BEGIN { inf = 0 }
    { lines++; words += NF; chars += length($0) + 1
      if ($0 ~ /^[ \t]*```/) { inf = !inf; fenced++; next }
      if (inf) fenced++ }
    END { printf "%s\t%d\t%d\t%d\t%d\n", FILENAME, lines, words, chars, fenced }
  ' "$f"
done
```

Frontmatter descriptions, first block only. A `description:` is a YAML plain
scalar and may wrap across several lines — count the continuation lines too, or
a paragraph-length description reads as one line's worth:

```bash
for f in commands/*.md skills/*/SKILL.md claude-md/*.md; do
  awk 'NR == 1 && /^---[ \t]*$/ { fm = 1; next }
       fm && /^---[ \t]*$/ { exit }
       fm && /^description:/ { sub(/^description:[ \t]*/, ""); d = $0; grab = 1; next }
       fm && grab { if ($0 ~ /^[A-Za-z_-]+:/) grab = 0; else d = d " " $0 }
       END { if (d != "") print FILENAME "\t" split(d, a, " ") }' "$f"
done
```

The `CLAUDE.md` chain:

```bash
find . -name 'CLAUDE.md' -not -path './.git/*' -not -path './skills/*' \
  -not -path './commands/*' | xargs wc -l
```

Resolve any `@path` import lines in those files and add their line counts too.
An import that resolves to nothing is skipped silently, not an error.

---

ESTIMATION — estimates, never measurements

Two heuristics, chosen per file:

- **Prose** — `words × 1.3`.
- **Code-heavy** — `chars / 4`. A file counts as code-heavy when **30% or more
  of its lines fall inside a fenced block** (the `fenced` column above,
  divided by `lines`). Fence delimiters count as fenced.

**Say plainly in the report that these are estimates.** No tokenizer runs here;
adding one would mean a dependency this repo forbids. An estimate presented as
a measurement is the failure mode to avoid — a reader who believes the figure
is exact will make decisions the figure cannot support. Phrase totals as
"≈ 12,400 est. tokens", never "12,400 tokens".

---

THRESHOLDS

| Signal | Flag at |
| --- | --- |
| `SKILL.md` length | > 400 lines |
| supporting reference file | > 500 lines |
| command length | > 400 lines |
| `description:` frontmatter | > 30 words |
| `CLAUDE.md` chain combined | > 300 lines |

`claude-md/*.md` artifacts are inventoried and counted toward the total but
carry no length threshold of their own — what they cost is what they inject
into a user's `CLAUDE.md`, which the chain signal already measures.

**Why `description:` is on that list, and why it matters more than its size
suggests:** a description loads into every session whether or not the feature
is ever invoked. A long body is paid for once, when someone runs the thing; a
long description is a permanent per-session cost paid by every user who has
the feature installed and never touches it. `/task-implement`'s description is
a paragraph, and is the live example in this repo.

**Estimated saving per flagged item** = the excess over the threshold, priced
at that file's own average: `(lines − threshold) × (est. tokens ÷ lines)`,
rounded. For a `description:` flag: `(words − 30) × 1.3`. It is what trimming
to the threshold would recover — not a recommendation to trim.

---

REPORT

1. **One line up front** that these are estimates, with the two heuristics
   named, and one line that this is not a gate.
2. **Ranked table** of the heaviest bodies, descending by estimated tokens.
   Include every flagged item; below them, enough unflagged rows to give the
   ranking context (roughly the top 15 overall is plenty).

   Shape, not fixed figures — these move every time a body is edited:

   ```
   path                                         kind   lines  est. tokens  flag  est. saving
   skills/unity-mcp-skill/references/workflows…  ref     2109      ≈18 600  >500      ≈14 200
   skills/task-implement/SKILL.md                skill    697       ≈7 300  >400       ≈3 100
   commands/task-add.md                          cmd      834       ≈7 200  >400       ≈3 800
   skills/context-convert/SKILL.md               skill    519       ≈4 900  >400       ≈1 100
   commands/task-list.md                         cmd      240       ≈2 200  —              —
   ```

3. **`description:` section** — every description over 30 words: feature name,
   word count, estimated saving. Silent when none are over.
4. **`CLAUDE.md` chain** — the files in the chain, combined line count, and
   whether it is over 300.
5. **Totals** — total estimated tokens across the whole inventory, and the
   summed estimated saving across every flagged item. Both labelled as
   estimates.

With VERBOSE, add a **per-file breakdown** after the table: every inventoried
file, flagged or not, with its lines, words, chars, fenced-line share, which
estimator was used, and its estimated tokens. That is the only thing
`--verbose` changes.

---

NAME COLLISIONS

A repo-local skill's `name` must never collide with a shipped feature name
under `commands/` or `skills/`. Both are visible in a session opened on this
repo, and a duplicate `/name` is ambiguous with no way for the user to
disambiguate. Before adding any future repo-local skill, check the shipped
catalogue for the name. `context-budget` was free as of 2026-08-24.

---

READ-ONLY, ALWAYS

This skill reads the repository and prints. It writes nothing, edits nothing,
deletes nothing, caches nothing between runs, opens no task, offers no
`--commit`, and installs no hook and no CI gate. Comparing two runs means
running it twice and reading both, which at this scale is cheaper than any
store would be.

DO NOT:
- Recommend what to cut, propose a split, or name a target size. Report the
  numbers and stop.
- Present an estimate as a measurement, or drop the "≈".
- Add a tokenizer, `jq`, `python`, or any other dependency to sharpen the
  estimate. The heuristic plus an honest label is the trade this repo made.
- Write, edit, delete or commit any file, including a cached result.
- Treat a flag as a failure, exit non-zero, or block anything on the outcome.
- Walk `.claude/`, `docs/`, `scripts/`, `bin/`, `statusline/` or `hooks/` —
  none of them is a body loaded into a context window.
- Add a `version:` field to this file, or to any other skill under
  `.claude/skills/`. See the note at the top.
- Bump root `VERSION` or add a `CHANGELOG.md` entry for a change confined to
  `.claude/skills/` — CLAUDE.md § Versioning exempts them.
