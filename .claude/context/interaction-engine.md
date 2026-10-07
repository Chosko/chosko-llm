# Features: interaction engine

## Overview

Covers `interaction-engine`, the non-invocable reference library every
interactive feature reads for the interaction policy. It serves every
family, so it has its own file rather than a section of
[task-engine.md](./task-engine.md) or [pipeline.md](./pipeline.md).

- `skills/interaction-engine/` — reference library; **not user-invocable**,
  takes no arguments, runs nothing. `SKILL.md` is a MAP, not a rule holder:
  the not-invocable notice, the relative-citation note
  (`../interaction-engine/references/<file>.md` from a skill root,
  `../../interaction-engine/…` from a skill's `references/`,
  `../skills/interaction-engine/…` from a command) and a three-row map
  saying when each file is opened; frontmatter carries
  `disable-model-invocation: true`. Three files under `references/`, one
  authority each:
  - `policy.md` — opened by every interactive feature at argument parsing.
    One value per run, `attended` (default) or `unattended`. Precedence,
    first match wins: `--attended` / `--unattended` or a policy handed down
    by the parent run; a runbook's `Execution policy:` header
    (`/runbook-run` only); the project's `CLAUDE.md` line
    `Interaction policy: attended|unattended`; `attended`. A parent states
    the policy under both values (runbook step preamble: *This run is
    attended* / *This run is unattended*; a delegated prompt's resolved-flag
    list) and never says *non-interactive*. Argument errors: both flags
    together; a `CLAUDE.md` value outside the two words. Every interactive
    feature accepts both flags. Leaves the testing-policy marker and the
    `-y` flags alone.
  - `gates.md` — opened only under `unattended`. Three classes, declared
    at each gate by a one-word tag (`confirmation`, `design`,
    `destructive`); no catalogue of gates, and an untagged gate is class 2.
    Class 1 passes on its own with a summary naming its commit (or the
    uncommitted change on a no-commit or non-git run), each auto-passed
    write its own commit, and a failed commit stops like the feature's own.
    Class 2 waits: parks where the feature can park, else stops with summary
    and question. Class 3 waits under every policy. A parked gate is the
    parking mechanism's `approval gate` case. Real decisions park, else
    stop; never pick an option.
  - `messages.md` — opened before the first gate, question or closing
    report. Output: no verbatim drafts or before → after diffs at a gate, a
    plain summary, `show` prints the draft and asks again, ~8 lines per gate
    summary and ~10 per closing report (soft), SHAs/diffstats/paths only when
    they matter (an auto-passed gate's commit always), reply shortcuts at
    most a one-line hint. Questions: a message that asks ends with its
    questions; plain language first, identifiers last in parentheses (the
    bad/good login-timeout example); one ask per stop.

  Consumers declare `requires: skill:interaction-engine`: `/task-implement`,
  `/task-add`, `/task-setup`, `/task-iterate`, `/task-clean`,
  `/runbook-run`, `/runbook-create`, `/runbook-clean`, `/runbook-prune`,
  `/architect`, `/product-design`, `/product-roadmap`, `/production-plan`,
  `/domain-setup`, `/pipeline-revise`, `/pipeline-check` (accepts the flags,
  no gate; the plain-language rule reaches it through `lint.md`'s
  templates), `/context-build`, `/context-update`, `/context-convert`,
  `/refactor-codebase`, `/refactor-tests`, `/doc-consolidate`,
  `/project-setup`, `/session-save`, `/follow-ups-resolve`. The engines
  (`task-engine`, `pipeline-engine`) cite it from their reference files but
  take no `requires:` — their consumers carry it.

## Public API

- Each file's contract is its text in § Overview. Frontmatter and
  loading-control keys: [feature-contract.md](./feature-contract.md)
  § Public API.

## Internal patterns

- A consumer states only its own part: its gates' class tags, what it
  writes before a stop, and its own templates written to `messages.md`. It
  never restates a class rule or the precedence.
- Features that cannot park (everything but `/task-implement` and
  `/runbook-run`) stop at whatever waits under `unattended`.

## Domain dependencies

- `../domain/features/interaction-policy.md` — the design.
- `../domain/features/unattended-parking.md` — the parking mechanisms
  "waits" resolves to.

## Cross-references

- [features.md](./features.md) — the hub listing every shipped feature.
- [task-engine.md](./task-engine.md) — `parking.md`, the task parking
  mechanism; [runbook-run.md](./runbook-run.md) — step parking.

## When to read the source

- Before changing a class rule, the precedence or a message rule: read the
  reference file itself, then grep consumers for the tag or citation.
