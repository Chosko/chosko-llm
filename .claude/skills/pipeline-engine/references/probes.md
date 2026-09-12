# Probes

Authority for: the fixed set of probes that describe a project's pipeline
setup, the one verdict line every consumer prints, and when a verdict already
in the conversation may be reused instead of probing again.

Authored here. No other feature carries a probe of its own: a consumer that
needs a fact about a project's pipeline setup that this file does not carry
adds it here rather than probing privately — or the verdict stops being one
line and one definition.

---

## What the probe is for

One round-trip and one definition. Every pipeline feature that needs to know
a project's setup asks the same questions — is there a feature index, a
backlog, a plan — and without this file each would ask them its own way, in
its own number of calls, with its own idea of what "present" means. The probe
answers all of them at once, the same way everywhere, and prints the answer as
one line the next consumer in the session reads instead of asking again.

It is **not a token saving**. Each probe is a file-existence check or a
one-file grep that costs next to nothing; the reuse rule below saves a
round-trip, not a read. Do not optimise it further: caching it on disk,
narrowing it per consumer, or skipping the probes a consumer "does not need"
all trade the one definition for a saving that does not exist.

## The probe set

Eight probes, fixed. Each is a cheap filesystem check run from the project
root, with the result shape the verdict line prints.

| Field | Checks | Result |
| --- | --- | --- |
| `features` | `.claude/FEATURES.md` exists. | `yes` \| `no` |
| `backlog` | `.claude/TASKS.md` exists and `.claude/tasks/` exists. | `yes` for both, `partial` for one, `no` for neither |
| `roadmap` | `.claude/domain/product-roadmap.md` exists, and whether any line of it begins `Covers:` — a milestone carrying scope slices. | `none` \| `unsliced` \| `sliced` |
| `plan` | `.claude/PLAN.md` exists. | `yes` \| `no` |
| `runbooks` | `.claude/RUNBOOKS.md` exists. | `yes` \| `no` |
| `council` | `${CLAUDE_HOME:-$HOME/.claude}/skills/claude-council/SKILL.md` exists — the path the council gates of `/architect` and `/product-design` probe. | `yes` \| `no` |
| `testing` | The project's `CLAUDE.md` carries a line `Testing policy for /task-implement: <value>`, and its value. The marker and its values are `/task-implement`'s; the probe reads the value and interprets nothing. | the value, or `none` |
| `installed` | Which pipeline features are installed under `${CLAUDE_HOME:-$HOME/.claude}` — each feature a row of `routing.md` names, found as `commands/<name>.md` or `skills/<name>/SKILL.md`, either kind. | `<found>/<rows>`, plus ` (missing: <name>, …)` when any is absent |

`sliced` follows `/architect`'s own reading of a roadmap: a roadmap with no
`Covers:` line is one it architects against in traditional mode.

**There is no probe of `.claude/tasks/archive/`, and none may be added.** A
folder no command traverses costs the same as a folder that is not there —
that is the archive's whole guarantee
(`${CLAUDE_HOME:-$HOME/.claude}/skills/task-engine/references/resolution.md`
§ *The archive*) — and a probe here would be the first traversal of it. No
pipeline decision turns on whether the archive exists: an id absent from
`TASKS.md` resolves from the absence alone.

## Running it

The probe is one shell invocation — the one shell use a read-only consumer is
allowed. This is its reference form; a consumer runs it as written, from the
project root:

```sh
H="${CLAUDE_HOME:-$HOME/.claude}"
yn() { if [ -e "$1" ]; then echo yes; else echo no; fi; }
features=$(yn .claude/FEATURES.md)
if [ -f .claude/TASKS.md ] && [ -d .claude/tasks ]; then backlog=yes
elif [ -e .claude/TASKS.md ] || [ -e .claude/tasks ]; then backlog=partial
else backlog=no; fi
roadmap=none
if [ -f .claude/domain/product-roadmap.md ]; then
  roadmap=unsliced
  grep -q '^Covers:' .claude/domain/product-roadmap.md && roadmap=sliced
fi
plan=$(yn .claude/PLAN.md)
runbooks=$(yn .claude/RUNBOOKS.md)
council=$(yn "$H/skills/claude-council/SKILL.md")
testing=$(sed -n 's/^Testing policy for \/task-implement: *\([a-z-][a-z-]*\).*$/\1/p' CLAUDE.md 2>/dev/null | head -n 1)
[ -n "$testing" ] || testing=none
found=0; rows=0; missing=
for f in $(sed -n 's/^| `\/\{0,1\}\([^`]*\)`.*$/\1/p' "$H/skills/pipeline-engine/references/routing.md" 2>/dev/null); do
  rows=$((rows + 1))
  if [ -f "$H/commands/$f.md" ] || [ -f "$H/skills/$f/SKILL.md" ]; then found=$((found + 1))
  else missing="$missing${missing:+, }$f"; fi
done
echo "Pipeline: features=$features backlog=$backlog roadmap=$roadmap plan=$plan runbooks=$runbooks council=$council testing=$testing installed=$found/$rows${missing:+ (missing: $missing)}"
```

The feature names come from `routing.md`'s rows, read by the row shape that
file states, so the list of pipeline features is written once — in the table.

## The verdict line

The probe prints exactly one line:

```
Pipeline: features=<yes|no> backlog=<yes|partial|no> roadmap=<none|unsliced|sliced> plan=<yes|no> runbooks=<yes|no> council=<yes|no> testing=<value|none> installed=<found>/<rows>[ (missing: <name>, <name>)]
```

Worked examples:

```
Pipeline: features=yes backlog=yes roadmap=none plan=no runbooks=yes council=yes testing=skip-tests-unattended installed=19/19
Pipeline: features=no backlog=partial roadmap=none plan=no runbooks=no council=no testing=none installed=17/19 (missing: pipeline-check, runbook-suggest)
```

Every consumer prints it **identically**: the literal `Pipeline:` prefix, all
eight fields, in that order, with those spellings — no per-consumer wording,
no subset, no reordering, no added field. The probe's own output is the line,
so it lands in the conversation as printed; a consumer that also shows the
verdict in its report shows that line verbatim.

## Reusing a verdict

A verdict line already in the conversation is **reused** — read back, not
re-probed — unless one of these writers has run in the conversation since it
was printed. Each can change a probed fact:

| Writer | Can change |
| --- | --- |
| `/project-setup` | `features`, `backlog`, `testing` |
| `/domain-setup` | `features` |
| `/task-setup` | `backlog` |
| `/product-roadmap` | `roadmap` |
| `/production-plan` | `plan` |
| `/runbook-create` | `runbooks` |
| `chosko-llm add`, `chosko-llm rm`, `chosko-llm update` | `council`, `installed` |
| any edit to `CLAUDE.md` | `testing` |

Every other pipeline feature — `/architect`, `/task-add`, `/task-implement`,
`/task-clean` and `/runbook-run` among them — changes the contents of an
index whose presence is all the probe records, so its run leaves a verdict
standing.

**A subagent always re-probes.** It shares no conversation, so there is no
verdict in it to reuse — and a verdict handed down in a prompt is a claim
about a moment the subagent cannot check.
