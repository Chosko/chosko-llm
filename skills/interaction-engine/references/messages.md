# Messages

Authority for: the output rules for gate summaries and closing reports, and
the question rules.

Read by every interactive feature before its first gate, question or closing
report. Both sets of rules hold under both policies; only the gate classes
(`./gates.md`) depend on the policy.

---

## Output

These rules cover gate summaries and closing reports. A read-only listing
prints what it prints.

- **No verbatim artifact previews at a gate.** No full drafts and no
  before → after diffs. A gate shows a concise plain-language summary: what
  changes, why, and what it affects.
- **`show` prints the draft.** The user can reply `show` at any gate; the
  feature then prints the full draft and asks the same question again.
- **Soft length.** About 8 lines for a gate summary and about 10 for a
  closing report, exceeded only when the content really needs it.
- **Identifiers only when they matter.** Commit SHAs, diffstats and file
  paths are left out unless they matter to the reader's next decision. An
  auto-passed gate's commit always matters, and is always named.
- **Reply shortcuts are not printed each time.** Shortcuts such as
  `all but N` or `P1: Q1a` keep working; a message carries at most a one-line
  hint of them.

## Questions

- **A message that asks ends with its questions.** Nothing follows them: no
  draft, no legend, no grammar list. Context goes above.
- **Plain language first, identifiers last in parentheses.** Say exactly what
  was not done and why; spend words on meaning, not on task numbers, slugs or
  section anchors the reader does not have in context.

  Bad:

  > task 42's acceptance criterion not met, update password-auth § Session to
  > match?

  Good:

  > The login task was supposed to log users out after 30 idle minutes, but
  > the code only ends sessions when the browser closes, because the session
  > library has no idle timer. Should I change the design to accept that, or
  > keep the 30-minute rule and add a task for it? (task 42, password-auth)

- **One ask per stop.** A run collects its questions and asks them together
  when it stops, never one per message across several stops.
