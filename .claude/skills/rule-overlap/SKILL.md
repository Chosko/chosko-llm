---
name: rule-overlap
type: skill
description: Repo-local audit for chosko-llm itself — mechanically collects every normative statement in the shipped feature bodies, then reports the ones restated across three or more features and whether the copies still agree. Read-only; it reports, it never dedupes.
---

# /rule-overlap
# Repo-local skill for `chosko-llm`'s own development. Collects the normative
# statements out of every shipped feature body, then reports which ones are
# carried by three or more features. Read-only — writes nothing, ever.
# Usage: /rule-overlap

**No `version:` in the frontmatter, deliberately.** That field exists for
`cmd-add` / `cmd-update`, which walk `$CHOSKO_LLM_HOME/commands|skills|…` and
will never see a file under this repo's own `.claude/skills/`. `name`, `type`
and `description` stay, because Claude Code needs them.

GOAL
The same rules are restated across the `task-*` suite — the commit-and-push
protocol, the status vocabulary, the approval-gate wording. That is the problem
[`shared-phase-engine`](../../domain/features/shared-phase-engine.md) exists to
fix, and there is no way to find the next instance of it, nor to confirm after
that refactor that the extracted rules really did stop being restated. This
skill is that way.

A tool for building the product is not part of the product. This one lives
under `.claude/skills/`, is invocable only while working in this repository,
and is installed nowhere.

$ARGUMENTS

---

NO ARGUMENTS

This skill takes none. If `$ARGUMENTS` is non-empty, say so in one line and run
the default report anyway — it never refuses over its own arguments.

---

THE PRINCIPLE — deterministic collection, model judgment

Two steps, and the split between them is the whole design:

- **Collection is mechanical.** `grep` and `awk` gather the statements. No model
  reads a body to decide what counts as normative, and no body is skimmed,
  sampled, or "spot-checked".
- **Judgment is the model's, and only judgment is.** Deciding that two
  differently worded lines are the same rule is what a model is for. Deciding
  which lines exist is not.

**Collection must be exhaustive.** A sampled collection produces confident
conclusions about material it never saw: the report would name three features
carrying a rule while a fourth, unread, carries a fourth version of it that
already disagrees. Over-collecting is the safe direction — a line the model
discards costs one read. Under-collecting is the failure mode, and it is silent.

---

COLLECT — scope

| In scope | Why |
| --- | --- |
| `commands/*.md` | shipped command bodies |
| `skills/**/*.md` | shipped skill bodies **and** their supporting reference files, at any depth — a rule restated in a reference file is restated |
| `claude-md/*.md` | shipped CLAUDE.md sections; they are normative by construction |

Excluded, each for a stated reason:

- **`skills/unity-mcp-skill/` and `skills/claude-council/`** — the two vendored
  skills. They are re-synced from upstream (docs/authoring-guide.md § Vendored
  skills), so a restatement found in one cannot be extracted without breaking
  the vendoring contract. Surfacing it would be noise the reader can never act
  on.
- **`hooks/*.sh` and `statusline/*.sh`** — shell scripts, carrying no normative
  prose to collect. Stated here rather than left to inference.
- **`.claude/`, `docs/`, `scripts/`, `bin/`** — not shipped feature bodies.
  `docs/authoring-guide.md` is authoritative *about* the features; it is not one
  of them, and folding it in would report every rule it documents as an overlap.

**Express the scope as a glob over what exists at run time — never as a
hardcoded list of feature names.** Feature bodies are deleted and added
(`commands/task-enrich.md` goes with the dual-LLM lane; the `runbook-*` family
arrives), and a name list rots on the first of them. The globs above are the
scope; whatever they match today is the input.

---

COLLECT — the pass

Run it as written. `-size +0c` keeps a zero-byte body out of the file list,
where it would contribute nothing and clutter the per-file counts.

```bash
NORM='must|never|always|refuse|forbid|prohibit|do not|don.t|cannot|can.t|may not|shall not'

for f in $(find commands claude-md -maxdepth 1 -name '*.md' -size +0c 2>/dev/null; \
           find skills -type f -name '*.md' -size +0c \
                -not -path 'skills/unity-mcp-skill/*' \
                -not -path 'skills/claude-council/*' 2>/dev/null | sort); do
  awk -v norm="$NORM" '
    /^#+[ \t]/         { printf "%s\th\t%d\t%s\n", FILENAME, FNR, $0; next }
    tolower($0) ~ norm { printf "%s\ts\t%d\t%s\n", FILENAME, FNR, $0 }
  ' "$f"
done
```

Each line is `path`, `h` (heading) or `s` (statement), line number, text.
Headings come along because they are how a statement is placed: the same
sentence under "FAILURE HANDLING" and under "ARGUMENT PARSING" is usually two
different rules.

Then the per-file statement counts, which the verification below depends on:

```bash
… | awk -F'\t' '$2 == "s" { n[$1]++ } END { for (f in n) printf "%s\t%d\n", f, n[f] }' | sort
```

If any in-scope body reports zero statements, the collection is broken, not the
body. Say so and stop rather than reporting a clean result.

**Read the whole collected set before judging anything.** That is the point of
collecting it.

---

JUDGE — three or more

Report a statement when **three or more features** carry it with materially the
same meaning. Different wording, same rule, counts; the model's job is exactly
that call.

Three, not two: two features sharing a rule is often correct and coincidental —
two commands that both push will both say how. Three is where a shared authority
starts paying for the indirection it costs.

Count **features**, not occurrences. A skill that states the same rule in its
`SKILL.md` and again in two of its reference files is one feature saying it
three times — worth noticing, but it is not an overlap across the catalogue.
Note it separately if it is striking; do not let it reach the threshold.

---

REPORT

One entry per overlap group:

- **The statement**, in one neutral sentence — not a quote from whichever copy
  happened to be read first.
- **The features carrying it**, with `path:line` for each.
- **Whether they agree.**

Shape, not fixed content:

```
Commit and push are one per task, immediately after that task's own commit.
  skills/task-implement/SKILL.md:412   commands/task-add.md:661
  commands/task-clean.md:203
  AGREE

A pre-existing dirty tree stops the run.
  commands/task-clean.md:88            skills/task-implement/SKILL.md:301
  commands/task-list.md:44
  DISAGREE — task-implement prompts with four options and can fold the changes
  into the commit; task-clean halts outright; task-list warns and continues.
```

**Disagreement is the highest-value finding in the report, and it is ranked
first.** Copies that agree are duplication — a cost, and a future drift risk.
Copies that disagree mean the rule has already drifted, which is the exact
failure the engine refactor is meant to prevent, and no reader of any single
body can see it.

Close with the counts: bodies collected, statements collected, groups found, of
which disagreeing.

---

VERIFYING A RUN

Verify against the `task-*` family: `commands/task-add.md`,
`commands/task-clean.md`, `commands/task-list.md`,
`skills/task-implement/SKILL.md`. What counts as a correct result depends on
when the run happens — **do not assume either state**:

- **Before the `shared-phase-engine` extraction lands**, those four restate the
  commit-and-push protocol, the status vocabulary and the approval-gate rules
  between them. A run that surfaces no overlap across them is **under-collecting**
  — that is the failure to look for, not evidence that the repo is clean.
- **After it lands**, a clean or much-reduced result across the same four is the
  expected confirmation that the extracted rules stopped being restated, and is
  not to be read as under-collection.

Distinguish the two by the per-file statement counts, never by the group count:
an under-collecting run emits few or no statements from those bodies; a
genuinely clean run emits them in quantity and finds each carried once.

---

RUNNING ORDER, AND WHY THERE IS NO DEPENDENCY

This skill declares no dependency on the `shared-phase-engine` work, in either
direction, because both orders are valid:

- Run it **before** that refactor, and its output *is* the extraction list.
- Run it **after**, and its output is the confirmation that the extraction held.

A dependency either way would forbid one of the two uses.

---

IF INLINE COLLECTION PROVES UNRELIABLE

The `grep`/`awk` above lives in this body rather than in a shell script. A
script under `.claude/scripts/` would be more faithful to "deterministic
collection", but adds a file kind this repo has no precedent for outside
`scripts/`. If the inline pass turns out to under-collect in a way that cannot
be fixed by widening `NORM`, moving it to a script is the escape hatch — the
principle survives the move, and only the location changes.

---

READ-ONLY, ALWAYS

This skill reads the repository and prints. It writes nothing, edits nothing,
caches nothing between runs, opens no task, offers no `--commit`, and installs
no hook and no CI gate.

DO NOT:
- Edit a body to dedupe a finding, or make any edit at all.
- Propose an extraction as an action, open a task for one, or draft the shared
  reference file. Naming what overlaps is the output; deciding what to do about
  it is the author's.
- Sample, skim, or spot-check bodies instead of collecting from all of them.
- Let the model decide what counts as a normative statement — that is the
  `awk` pass's job, and moving it into the model breaks the design.
- Report a group carried by two features, or by one feature three times.
- Hardcode a list of feature names anywhere in place of the globs.
- Include the vendored skills, `hooks/`, `statusline/`, `docs/` or `.claude/`
  in the collection.
- Treat a finding as a failure, exit non-zero, or block anything on the outcome.
- Add a `version:` field to this file, or to any other skill under
  `.claude/skills/`. See the note at the top.
- Add `jq`, `python` or any other dependency. ECC's `rules-distill` contributed
  one idea to this skill and none of its machinery, precisely because its
  scripts need `jq`.
- Bump root `VERSION` or add a `CHANGELOG.md` entry for a change confined to
  `.claude/skills/` — CLAUDE.md § Versioning exempts them.
