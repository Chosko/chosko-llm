# Repo-local audits

Two audits that apply to `chosko-llm`'s own development and to nobody else's:
a context-budget pass that flags oversized shipped bodies, and a shared-rule
pass that finds material repeated across features. Both live in the repo's own
`.claude/skills/`, carry no `version:`, and are never installed anywhere.

## Purpose

This repo ships prompts. Its product thesis is token-lean navigation, and it
has no way to check its own bodies against that thesis: `unity-mcp-skill`
carries a 2,109-line reference file, `task-add.md` is 879 lines, and nothing
notices. Separately, the same rules are restated across the `task-*` suite —
the problem [shared-phase-engine](./shared-phase-engine.md) exists to fix, and
which needs a way to find the next instance after that refactor lands.

Both are production concerns for this repository. Neither is a feature anyone
else wants installed, and shipping them would add two more features to a
catalogue whose size is itself the thing being measured.

The distinction this feature draws is the useful part: **a tool for building
the product is not part of the product.** `chosko-llm` has had no place to put
one until now.

## Scope and non-goals

In scope: the location and shape of unshipped repo-local skills, and the two
audits themselves.

Deliberately out:

- **Shipping either audit.** They are not features. They get no `version:`, no
  entry in `ls --available`, and no place under `skills/`.
- **ECC's implementations.** `context-budget`'s thresholds and estimation
  heuristics are worth copying; its report format, MCP analysis and
  agent-description rules are for a different shape of repo. `rules-distill`
  contributes one idea — deterministic collection, model judgment — and none of
  its scripts, which need `jq`.
- **Automation.** No hook, no CI gate, no `Stop` enforcement. Both are run by
  hand when someone wants the answer.
- **Acting on findings.** Both report. Neither edits, deletes, or opens a task.

## Architecture

### Where unshipped skills live

Claude Code reads project-level skills from `.claude/skills/` in the working
repo, and `cmd-ls --available` walks `$CHOSKO_LLM_HOME/skills/` — the shipped
catalogue — not the project's `.claude/`. The two directories never meet, which
gives the separation for free with no CLI change:

```
skills/                     shipped catalogue; versioned; walked by cmd-ls
.claude/skills/             repo-local; unversioned; invisible to the CLI
  context-budget/SKILL.md
  rule-overlap/SKILL.md
```

They are invocable as `/context-budget` and `/rule-overlap` while working in
this repo, and nowhere else. No frontmatter `version:` — the field exists for
`cmd-add` and `cmd-update`, which will never see these files. `name`, `type`
and `description` stay, because Claude Code needs them.

This also establishes the pattern for any future repo-local tooling, which is
the more durable outcome than either audit.

### `/context-budget`

Adapted from ECC's skill of the same name, cut to this repo's shape.

**Inventory** — walk `commands/*.md`, `skills/*/SKILL.md`, every supporting file
under `skills/*/`, `claude-md/*.md`, and the `CLAUDE.md` chain. Estimate tokens
as `words × 1.3` for prose and `chars / 4` for anything code-heavy.

**Thresholds**, taken from ECC and re-anchored to what this repo actually ships:

| Signal | Flag at |
|---|---|
| `SKILL.md` length | > 400 lines |
| supporting reference file | > 500 lines |
| command length | > 400 lines |
| `description:` frontmatter | > 30 words |
| `CLAUDE.md` chain combined | > 300 lines |

ECC's observation about `description:` is the one worth carrying deliberately:
it loads whether or not the feature is ever invoked, so a bloated description is
a permanent cost paid by every session. Several descriptions in this repo run
long enough to matter — `task-implement`'s is a paragraph.

**Report** — a ranked table of the heaviest bodies with an estimated saving per
item, and a total. No recommendations about what to cut; the numbers are the
output, the judgement is the author's.

The skill is explicitly *not* a gate. A 2,109-line reference file may be
correct — `unity-mcp-skill` covers a large external surface. The audit's job is
to make the cost visible, not to litigate it.

### `/rule-overlap`

The distillation idea from ECC's `rules-distill`, without its machinery, and
built on the principle that skill states more clearly than it follows:
**deterministic collection, model judgment.** A script gathers exhaustively; the
model only decides.

**Collect** — for each shipped feature body, extract its headings and any
normative statement (a line containing must, never, always, refuse, or a
prohibition). This is mechanical: `grep` and `awk`, no model involved, and it
must be exhaustive because a sampled collection produces confident conclusions
about material it never saw.

**Judge** — the model reads the full collected set and reports statements that
appear in three or more features with materially the same meaning. Three,
because two features sharing a rule is often correct and coincidental; three is
where a shared authority starts paying.

**Report** — each overlap group: the statement, the features carrying it, and
whether they agree. Disagreement between copies is the highest-value finding —
it means the rule has already drifted, which is the failure the engine refactor
is meant to prevent.

After [shared-phase-engine](./shared-phase-engine.md) lands, this audit is how
the next extraction candidate is found, and how it is confirmed that the
extracted rules really did stop being restated.

## Data and state

None. Both audits read the repository and print. Nothing is written, cached, or
tracked between runs. Comparing two runs means running twice and reading both,
which at this scale is cheaper than any store would be.

## Interfaces and contracts

```
/context-budget            ranked table of body sizes and estimated tokens
/context-budget --verbose  per-file breakdown
/rule-overlap              statements repeated across 3+ features
```

Available only inside this repository. Both are read-only, always.

Hard contracts:

- Neither appears in `chosko-llm ls --available`.
- Neither carries a `version:` field.
- Neither is referenced by any shipped feature body — a shipped feature that
  depends on repo-local tooling would break for every user.
- Root `VERSION` is **not** bumped for changes to these. They are not shipped
  changes, and bumping for them would corrupt the meaning of the version the
  installer reports.

That last point is a genuine exception to the repo's "bump on every shipped
change" rule and should be recorded in `CLAUDE.md` when this lands, or the next
session will bump `VERSION` for a file no user receives.

## Dependencies

None on other features. `/rule-overlap` becomes materially more useful after
[shared-phase-engine](./shared-phase-engine.md), but is independently valid
before it — running it first is how the extraction list gets built.

## Open questions

- **Does `.claude/skills/` collide with the installed global skills?** Both are
  visible in a session in this repo, so a repo-local skill sharing a name with
  a shipped one would be ambiguous. Neither name is taken; keeping it that way
  is a cheap rule, and `/context-budget` is a name ECC also uses, which matters
  only if ECC is ever installed alongside.
- **Should the collection step be a script or inline instructions?** A
  `.claude/scripts/` shell script is more faithful to "deterministic
  collection", but adds a file kind this repo has no precedent for outside
  `scripts/`. Inline `grep`/`awk` in the skill body is weaker but simpler.
  Leaning inline until it proves unreliable.
- **Is `words × 1.3` accurate enough** for markdown that is mostly prose with
  embedded code fences? It is a heuristic, and the report should say so rather
  than presenting estimates as measurements.
