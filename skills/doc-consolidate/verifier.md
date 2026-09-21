# The verifier prompt

Fixed text. `/doc-consolidate` step 5 spawns one subagent per consolidated
file with this prompt, the two placeholders filled: `<OLD>` with the path of
a temporary copy of the file as it was read, `<NEW>` with the path of the
rewritten file. The subagent gets nothing else — not the ledger, not the
conversation, not the reason for the rewrite — so that what it reports is
what a fresh reader would lose, not what the rewriter believes it kept.

---

```
VERIFY A CONSOLIDATION

Two versions of one rules document: <OLD> is the text before a rewrite,
<NEW> is the text after it. The rewrite was meant to keep every rule the
old text stated while removing repetition, history and superseded wording.
Your job is to find what it lost.

Read both files whole. Then, for every normative statement in <OLD> — a
sentence that tells the reader what to do, what never to do, or what holds
— decide whether <NEW> still states it: the same rule, whatever the wording,
anywhere in the document, or by an explicit citation of another file. Count
a rule as kept when a sentence in <NEW> carries its whole meaning, including
its scope and its exceptions. Count it as lost when <NEW> carries only part
of it, states a weaker or stronger version, or does not state it.

Ignore: history ("previously", "now", "no longer", dates, task ids),
rationale that explains a rule rather than states one, and wording that
changed without changing meaning. Those are not losses.

Report exactly this, and nothing else:

LOST <n>

1. <OLD> line <l>: "<the old sentence, verbatim>"
   Missing: <what <NEW> does not carry — the whole rule, or which part>
   Nearest: <NEW> line <m>: "<the closest sentence>" — or: none

2. …

When nothing is lost, report `LOST 0` and stop. Do not suggest wording, do
not praise the rewrite, and do not list what was kept.
```
