---
name: doc-consolidate
version: 0.2.0
type: skill
description: Rewrite a rules document — a command or skill body, a feature document, a context file, a CLAUDE.md — or every document under a folder, under the editing discipline, dropping superseded, historical, duplicated and restated statements without changing what it means. Use it on a document that has stratified.
disable-model-invocation: true
---

# /doc-consolidate
# Global skill: consolidate one document, or every document under a folder,
# under `claude-md:editing-discipline`: remove statements that are
# superseded, historical, duplicated or restated, merge overlapping ones, and
# keep every rule the document carried. Meaning-preserving, never a style
# compressor. Plan-first: every section of every file is classified before
# anything is written, the full per-section ledgers — only what is dropped or
# merged, never what is kept — go to a file in the session's scratchpad, and
# the run stops once, at a single gate listing only the entries the
# discipline's rules cannot settle; a run with none of those asks nothing.
# After the rewrite an
# independent verifier with fresh context reads old and new and lists every
# normative statement present in the old text and absent from the new; the
# run ends only when that list is empty or every item on it was restored or
# explicitly accepted. Schema-aware: frontmatter, a shipped body's `#`
# header, a context file's six sections and a feature document's sections
# stay in place. Leaves the result uncommitted by default.
# Usage: /doc-consolidate <path>                   (a file, or a folder consolidated file by file)
#        /doc-consolidate <path> --commit          (commit and push the rewrite)
#        /doc-consolidate <path> --commit --no-push
# Examples: /doc-consolidate commands/task-add.md
#           /doc-consolidate skills/runbook-run/SKILL.md --commit
#           /doc-consolidate .claude/domain/features

GOAL
A rules document that was edited many times carries its history: the old
sentence beside the one that replaced it, a rule restated in three
sections, a "no longer" that tells the reader what used to be true. Rewrite
it so that it states the current rules once each, and prove that no rule
was lost.

$ARGUMENTS

---

THE RULES IT APPLIES

The nine rules of `claude-md:editing-discipline`, read from the project's
`CLAUDE.md`, where the feature installs them. A project whose `CLAUDE.md`
carries no such section stops here, before anything is read:
`/doc-consolidate needs claude-md:editing-discipline in this project's CLAUDE.md — chosko-llm add claude-md:editing-discipline --local, then re-run.`
This skill restates none of the rules. What it
adds is a procedure for applying them to a document that already violates
them, with a proof at the end.

Meaning-preserving means: every rule the old text stated, the new text
states, once. Wording that carries meaning is kept, terse or not. A sentence
is dropped only when its meaning is carried elsewhere in the new text, when
it describes a state that no longer holds, or when it is history.

---

ARGUMENT PARSING

Scan `$ARGUMENTS` for `--commit` (COMMIT = true; default false — an
authoring run leaves its result uncommitted for review) and `--no-push`
(NO_PUSH = true; meaningful only with `--commit`). `--commit` and
`--no-commit` together stop the run with: `--commit and --no-commit cannot be
combined. Pick one.`

What remains is `<path>`, required: a file, or a folder. A missing path
stops with `/doc-consolidate needs a file or folder to consolidate.`; a path
that does not exist stops naming it. A folder is consolidated one file at a
time, in path order, every `.md` under it at any depth; each file runs the
whole workflow below, and step 6 runs once more across the folder.

---

SUPPORTING FILES (read on demand — not up front)

| Read this file | Exactly when |
| -------------- | ------------ |
| `./verifier.md` | Step 5, once per file, to assemble the verifier's prompt. |

---

WHAT IT PRESERVES

Consolidation happens inside a document's structure, never to it:

- **Frontmatter** — every key and value, untouched.
- **A shipped body's `#` header** — the comment block under the title that
  carries the flags and usage lines, per the authoring conventions the body
  was written to. Its lines may be consolidated like any prose; the block
  stays, in place, first.
- **A context file's six sections** — the schema the `context-build` skill
  defines. Every section stays, in order, with its heading.
- **A feature document's sections** — the schema the `architect` skill's
  feature-document template defines. Every section stays, in order, with
  its heading.
- **Any other document's `##` headings** — kept in order. A section is
  dropped only when it is empty after consolidation and the schema above
  does not require it.
- **Fenced blocks, tables and quoted templates** — kept verbatim unless a
  duplicate of one already in the document.

When those skills are not installed, the schema is still recognised from the
document's own headings; naming them records the authority, not a
prerequisite.

---

WORKFLOW

Steps 1 and 2 run per file, in path order. Steps 3 and 4 run once for the
whole run, across every file it covers. Step 5 runs per file again, and steps
6 and 7 close the run.

**1. Read.** The whole file, once. On a shipped body, also read the
frontmatter's `requires:` and the files the body cites by relative path, so
a statement that lives in a cited file is recognised as restated here.

**2. Classify.** Walk the document sentence by sentence and mark every
normative statement — a sentence that tells the reader what to do, never
do, or what holds — as one of:

- **kept** — states a current rule stated nowhere else in the document;
- **superseded** — an older statement of a rule a later sentence in the
  same document now states differently; the later one is the rule;
- **historical** — "previously", "now", "no longer", "used to", a date or a
  task id as provenance, a rationale for a change rather than a rule;
- **duplicate** — the same rule already stated in this document, or in a
  file this document cites by path;
- **restated** — a rule the document cites from another file and then
  paraphrases;
- **merge** — two or more sentences that overlap or qualify each other and
  together state one rule.

Everything not normative — an example, a template, a heading, a rendered
block — is kept as it is.

**3. The ledgers.** Classify every section of every file the run covers
before anything is asked and before anything is written. For each `##`
section (or the whole file, when it has none or fewer than four), render:

```
§ <section> — <n> statements, <k> kept

Superseded:
  old: <the sentence>
  new: <the sentence that supersedes it, quoted>
Historical (<count>):
  - <the sentence>
Duplicate:
  - <the sentence> — kept at § <section> | cited from <path>
Restated:
  - <the sentence> — the rule is <path> § <section>
Merged:
  - <sentence A>
  - <sentence B>
  → <the one sentence that carries both>
```

Kept statements are never listed: they are the new text. A section with
nothing to drop or merge takes one line, `§ <section> — nothing to
consolidate`.

Every file's ledgers go to one file in the session's scratchpad directory,
never inside the repository, under a name of its own so that it cannot
collide with the copies of the old text step 5 writes there. Print its path
once — `Ledgers: <path>` — and nothing else of them in chat.

**Judgement calls.** An entry is a **judgement call** when the discipline's
rules cannot settle it mechanically: a superseded pair whose two versions
disagree on the rule rather than on its wording; a drop or a merge that
changes what the document says rather than where it says it. A duplicate
whose surviving copy the ledger names, a restated rule sitting beside its
citation, a historical tail, a rule-6 DO NOT bullet and a meaning-preserving
merge are never judgement calls — the rules settle each of them, and the
verifier in step 5 is the check that they were settled right.

**4. The gate — once per run.** Present every judgement call across every
file and section as one numbered list, each a short block naming the file and
the section, the entry, the options and a recommendation:

```
1. skills/foo/SKILL.md § The gate — superseded pair, versions disagree
   old: <the sentence>
   new: <the sentence that supersedes it>
   They state two different rules, not one rule twice.
   Options: keep the later one | keep both | keep the older one
   Recommendation: keep the later one — <one clause>
```

Then one count line per file:

```
<path>: <n> statements, <k> kept, <d> dropped, <m> merged
```

The user answers once, for the whole run. `all` approves every judgement
call as recommended. Numbers overrule — each number named keeps that entry
as it was, and every call not named is approved. `ledger` prints the ledgers
in chat and re-asks. Silence, an unclear reply or EOF writes nothing: no file
is rewritten and the run ends.

**A run with no judgement calls is not gated.** Print the count lines and the
ledger path and continue to step 5 without asking — the rules settled every
entry, and the verifier is what proves nothing was lost.

**5. Rewrite and verify.** Rewrite each file's sections under rule 7 of
the discipline — the section as if written fresh with its kept statements
and merged sentences in, in the document's own register — and write the
file. Then spawn the verifier: one subagent with fresh context, model the
same as this session, prompt assembled from `./verifier.md` with the old
text — the file as read in step 1, written to a copy in the session's
scratchpad directory, never inside the repository, and removed once the
verifier has returned — and the new text. It receives no ledger. Wait for
its result — the Agent call returns an id, not the report; the report
arrives later — then print it under `Verifier: <n> statements lost`.

For each item the verifier lists: restore it into the section it came from,
or, when the user says its loss is right (a rule the old text stated that
the new text carries in other words, and the verifier missed the match),
record the acceptance in the report. A run that ends with an item neither
restored nor accepted is incomplete and says so.

**6. Across a folder.** Once every file in a folder has been consolidated,
collect the normative statements of all of them — the method the repo-local
`rule-overlap` audit uses: a mechanical pass over every file for the
sentences that carry `must`, `never`, `always`, `refuse`, `forbid`,
`prohibit`, `do not`, `don't`, `cannot`, `can't`, `may not` or `shall not`,
headings kept as placement — and group the ones that
state one rule across two or more files. For each group, the rule stays in
the file that owns it (the file whose subject it is, or the one the others
already cite) and every other file cites it by path in one sentence. Each
such change goes through steps 3 to 5 for the file it edits.

**7. Report.** One line per file — `<path>: <before> → <after> lines;
dropped <n> (superseded <a>, historical <b>, duplicate <c>, restated <d>),
merged <m>; verifier: <lost> lost, <restored> restored, <accepted>
accepted` — then the cross-file groups resolved. The line counts are an
observation; no number in this skill is a target, and a file that grew is
reported without comment.

---

COMMITTING

Under `--commit`, commit and push the rewritten files per the
commit-and-push protocol every authoring feature in this suite follows —
pull at start, stage exactly the files written by explicit path, one commit
(`Consolidate <path>`), re-sync, push unless `--no-push`. Without it, nothing
touches git and the report ends by listing the files left uncommitted.
