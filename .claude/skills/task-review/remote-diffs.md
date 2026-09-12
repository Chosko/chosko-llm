# Branch and PR modes — acquiring a diff that is not in the working tree

Read this from `SKILL.md`'s ARGUMENT PARSING, and **only** when the input
left after stripping `task=` and `base=` is non-empty. A local-mode run —
the common path, and the one `/task-implement --review` always takes — never
loads this file.

Nothing else moves here. Task resolution, the review gates, severity, the
finding schema, the report, the output destination and the read-only
contract all stay in `SKILL.md`: they are identical in all three modes.

Everything below is read-only. `git` commands inspect; `gh` commands read.
No command in this file changes a file, a ref, a remote, or a pull request.

## Telling the two apart

The input is a **PR** if it is a bare integer or a GitHub pull-request URL —
see the sanitisation rule below, which is also the classifier. Anything else
is a **branch name**.

A branch is not verified by pattern. Resolve it with `git rev-parse --verify`
against the local ref, then `origin/<branch>`. If neither exists, stop and
say the branch was not found locally or on `origin` — do not guess a similar
name and do not fall back to local mode.

## Branch mode

Diff source: `git diff <base>...<branch>` — three dots, so the diff is the
branch's own work against the merge base, not the difference between two
tips. Two dots would attribute everything that landed on the base since the
branch forked to the branch under review.

Resolving `<base>`, first hit wins:

1. **`base=<ref>` from the argument.** Verify it resolves
   (`git rev-parse --verify`); if it does not, stop and say so rather than
   silently falling through to the default.
2. **The repository's default branch** —
   `git symbolic-ref --quiet refs/remotes/origin/HEAD`, which yields
   `refs/remotes/origin/<name>`; take `<name>`.
3. **`git remote show origin`**, whose `HEAD branch:` line says the same
   thing when the symbolic ref is absent locally.
4. **`master` or `main`**, whichever exists as a ref. If both do, or neither,
   stop and ask for `base=<ref>`.

Report the resolved base in the report header. A reader who disagrees with
the base disagrees with every verdict in the report, so it must be visible
without being asked for.

The default is the repository's default branch because that is what a
finished branch merges into. A stacked branch wants its parent instead, and
that is what `base=<ref>` is for.

## PR mode

### Sanitising the argument — before it can reach a shell

Accept exactly two forms:

- a **bare integer**: the whole argument matches `^[0-9]+$`;
- the **trailing number of a GitHub PR URL**: the argument matches
  `^https://github\.com/[^/]+/[^/]+/pull/([0-9]+)(/.*)?$`, and the capture
  group is the number.

Reject anything else and stop, naming what was rejected. Do not strip
characters until something matches, do not try a looser pattern on failure,
and do not ask the shell to interpret it.

**The raw argument is never interpolated into a command.** What reaches
`gh` is the integer extracted by one of the two patterns above — a value that
by construction contains nothing but digits. This is the rule; an argument
that merely *looks* safe is still passed as the extracted integer, never as
itself.

### `gh` is required here, and only here

Check `gh` is available (`gh --version`) before the first `gh` call. If it is
missing, stop with an error that names it:

> Reviewing a pull request needs the GitHub CLI (`gh`), which is not
> available on this machine. Install it, or review the branch instead:
> `/task-review <branch>`.

**Never fall back** to local or branch mode on a PR input. A silent fallback
would review the working tree and report it as a review of PR 214 — the
answer would be confidently about the wrong diff.

Local and branch mode never invoke `gh` at all, so its absence is invisible
to them. Do not check for it on those paths.

### Reading the PR

- **Diff**: `gh pr diff <N>`.
- **Title and body**: `gh pr view <N>` — the title is one of `SKILL.md`'s
  task-resolution signals (a leading `Task <n>:` or a bare number).
- **Review comments**: read the existing threads on the PR
  (`gh pr view <N> --comments`, or the review-comments API through
  `gh api`). Treat them as **prior context, not findings**: a point another
  reviewer already made is not re-raised as a new finding, and a thread whose
  concern the diff already addresses is not reopened. Where an existing
  thread supports a finding of this review, cite it.

Reading threads is a read. Replying to one, resolving one, or opening a
review is `/task-iterate`'s job and is forbidden here.

## Back to `SKILL.md`

With the diff in hand, return to RESOLVING THE TASK. Branch mode has the
branch name as a resolution signal; PR mode has the branch name and the PR
title. Everything after that point is mode-independent.
