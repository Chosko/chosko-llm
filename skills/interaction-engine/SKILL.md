---
name: interaction-engine
version: 0.1.0
type: skill
description: Reference library for the interaction policy — the attended/unattended policy and its precedence, the three gate classes, and the output and question rules every interactive feature shares, under references/; read by path, never invoked.
disable-model-invocation: true
---

# interaction-engine
# Reference library, read by path by every interactive chosko-llm feature
# while it runs; not invoked.

> **Not directly invocable.** This skill exists so that the rules for how an
> interactive feature treats the person running it — which gates wait, how a
> gate summary or closing report is written, how a question is asked — have
> exactly one home. It has no command, no arguments and no behaviour of its
> own. Nothing invokes `/interaction-engine`; nothing should suggest it. Every
> feature with a gate, a question or a closing report cites the files below by
> path while it runs, and those files are the only content here.

> **Install path assumption:** this skill installs beside the features that
> read it — `chosko-llm add skill:interaction-engine` writes it under the same
> home those features are installed into, whichever home that is. So a
> feature names a file here by a path **relative to its own body**, never by
> an absolute home path, counting directories up to the install home and back
> down: `../interaction-engine/references/<file>.md` from a file at another
> skill's root, `../../interaction-engine/references/<file>.md` from a file
> under another skill's `references/`,
> `../skills/interaction-engine/references/<file>.md` from a command, and
> `./<file>.md` between two files in this skill.
>
> That is scope-proof by construction. `CLAUDE_HOME` still governs where
> `install.sh` and the `scripts/cmd-*.sh` verbs *write* — including
> `--local`, which repoints the whole home to `$PWD/.claude` — but a shipped
> body cannot re-derive it at run time, because the executing agent expands
> `${CLAUDE_HOME:-$HOME/.claude}` itself and always lands on the global home.
> Citing body and cited file are always siblings under one root, so a
> relative path is correct in either scope with no probing and no fallback.

---

## The map

| Reference file | Owns | Opened |
| -------------- | ---- | ------ |
| `references/policy.md` | The policy values, the `Interaction policy:` line, the `--attended` / `--unattended` flags, the precedence that resolves one value per run, how a parent hands its policy down, and the argument errors. | At argument parsing, by every interactive feature. |
| `references/gates.md` | The three gate classes, what each does under `unattended`, the auto-pass summary and commit, runs that do not commit, and the park-else-stop rule for real decisions. | Only when the policy resolves to `unattended`. Under `attended` every gate waits and this file is never opened. |
| `references/messages.md` | The output rules for gate summaries and closing reports, and the question rules. | Before the feature's first gate, question or closing report. |

Each file is the **single authority** for its rule. A consuming feature cites
the file and states only what it does differently — its own gates' class
tags, its own parking mechanism if it has one, its own templates written to
these rules.

**This `SKILL.md` carries no rule text.** It exists because `chosko-llm`
installs a skill folder, and a folder needs a versioned `SKILL.md` to be
installable at all. Every rule lives in a reference file; adding rule text
here would recreate the duplication the engine exists to remove.
