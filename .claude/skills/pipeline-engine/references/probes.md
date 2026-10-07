# Probes

Authority for: the fixed set of probes that describe a project's pipeline
setup, the one verdict line every consumer prints, and when a verdict already
in the conversation may be reused instead of probing again.

- Authored here. No other feature carries a probe of its own: a consumer
  needing a pipeline-setup fact this file lacks adds it here rather than
  probing privately, or the verdict stops being one line and one definition.

---

## What the probe is for

- **One round-trip and one definition.** The probe answers every setup
  question a pipeline feature asks — is there a feature index, a backlog, a
  plan — at once, the same way everywhere, as one line the next consumer in
  the session reads instead of asking again.
- It is **not a token saving**: each probe is a file-existence check or a
  one-file grep costing next to nothing; reuse saves a round-trip, not a read.
- Do not optimise it further — no caching on disk, no narrowing per consumer,
  no skipping the probes a consumer "does not need": each trades the one
  definition for a saving that does not exist.

## Reusing a verdict

1. **Reuse** a verdict line already in the conversation — read it back, do
   not re-probe — unless one of these writers, each able to change a probed
   fact, has run in the conversation since it was printed:

   | Writer | Can change |
   | --- | --- |
   | `/project-setup` | `features`, `backlog`, `testing` |
   | `/domain-setup` | `features` |
   | `/task-setup` | `backlog` |
   | `/product-roadmap` | `roadmap` |
   | `/production-plan` | `plan` |
   | `/runbook-create` | `runbooks` |
   | `/quick-implement`, `/pipeline-revise --catch-up` | `specs` |
   | `chosko-llm add`, `chosko-llm rm`, `chosko-llm update` | `council`, `installed` |
   | any edit to `CLAUDE.md` | `testing` |
   | a change of working directory | `council`, `installed` |

2. `council` and `installed` read the project scope at `$PWD/.claude`, so they
   describe the directory the probe ran in: a consumer that has since moved,
   or a subagent started elsewhere, re-probes.
3. Every other pipeline feature — `/architect`, `/task-add`,
   `/task-implement`, `/task-clean` and `/runbook-run` among them — changes
   the contents of an index whose presence is all the probe records, so its
   run leaves a verdict standing.
4. **A subagent always re-probes.** It shares no conversation to reuse a
   verdict from, and a verdict handed down in a prompt is a claim about a
   moment the subagent cannot check.

## Running it

- Run the probe as one shell invocation — the one shell use a read-only
  consumer is allowed — exactly as written below, from the project root:

```sh
# Both install homes, always both. H1 is the project scope, where
# `chosko-llm add --local` writes. H2 is the user scope: CLAUDE_HOME when the
# user has relocated Claude Code's user directory, else ~/.claude.
H1="$PWD/.claude"
H2="${CLAUDE_HOME:-$HOME/.claude}"
# have <rel> [<rel>…] — true when either home holds any of the paths.
have() {
  for r in "$@"; do
    [ -f "$H1/$r" ] && return 0
    [ -f "$H2/$r" ] && return 0
  done
  return 1
}
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
council=no; have skills/claude-council/SKILL.md && council=yes
testing=$(sed -n 's/^Testing policy for \/task-implement: *\([a-z-][a-z-]*\).*$/\1/p' CLAUDE.md 2>/dev/null | head -n 1)
[ -n "$testing" ] || testing=none
specs=0
for f in .claude/specs/*.md; do [ -f "$f" ] && specs=$((specs + 1)); done
# Row names are UNIONED across both homes, never taken from whichever is found
# first: the two copies can differ, and a row missing from one would otherwise
# drop out of the count and out of `missing:` alike — invisibly.
row_names=$(for h in "$H1" "$H2"; do
  f="$h/skills/pipeline-engine/references/routing.md"
  [ -f "$f" ] && sed -n 's/^| `\/\{0,1\}\([^`]*\)`.*$/\1/p' "$f"
done | sort -u)
if [ -n "$row_names" ]; then
  found=0; rows=0; missing=
  for f in $row_names; do
    rows=$((rows + 1))
    if have "commands/$f.md" "skills/$f/SKILL.md"; then found=$((found + 1))
    else missing="$missing${missing:+, }$f"; fi
  done
  installed="$found/$rows${missing:+ (missing: $missing)}"
else
  installed=unknown   # no routing.md in either home — not the same as 0/0
fi
echo "Pipeline: features=$features backlog=$backlog roadmap=$roadmap plan=$plan runbooks=$runbooks council=$council testing=$testing specs=$specs installed=$installed"
```

- Feature names come from `routing.md`'s rows, read by the row shape that
  file states: the list of pipeline features is written once, in the table.

## The verdict line

The probe prints exactly one line:

```
Pipeline: features=<yes|no> backlog=<yes|partial|no> roadmap=<none|unsliced|sliced> plan=<yes|no> runbooks=<yes|no> council=<yes|no> testing=<value|none> specs=<count> installed=<found>/<rows>[ (missing: <name>, <name>)]|unknown
```

Worked examples:

```
Pipeline: features=yes backlog=yes roadmap=none plan=no runbooks=yes council=yes testing=skip-tests-unattended specs=1 installed=24/24
Pipeline: features=no backlog=partial roadmap=none plan=no runbooks=no council=no testing=none specs=0 installed=22/24 (missing: pipeline-check, runbook-suggest)
Pipeline: features=no backlog=no roadmap=none plan=no runbooks=no council=no testing=none specs=0 installed=unknown
```

- Every consumer prints it **identically**: the literal `Pipeline:` prefix,
  all nine fields, in that order, with those spellings — no per-consumer
  wording, no subset, no reordering, no added field.
- The probe's own output is the line, so it lands in the conversation as
  printed; a consumer that also shows the verdict in its report shows it
  verbatim.

## The probe set

Nine probes, fixed: each a cheap filesystem check run from the project root,
with the result shape the verdict line prints.

| Field | Checks | Result |
| --- | --- | --- |
| `features` | `.claude/FEATURES.md` exists. | `yes` \| `no` |
| `backlog` | `.claude/TASKS.md` exists and `.claude/tasks/` exists. | `yes` for both, `partial` for one, `no` for neither |
| `roadmap` | `.claude/domain/product-roadmap.md` exists, and whether any line of it begins `Covers:` — a milestone carrying scope slices. | `none` \| `unsliced` \| `sliced` |
| `plan` | `.claude/PLAN.md` exists. | `yes` \| `no` |
| `runbooks` | `.claude/RUNBOOKS.md` exists. | `yes` \| `no` |
| `council` | `skills/claude-council/SKILL.md` exists under either install home (see below) — the question the council gates of `/architect` and `/product-design` ask by name, not by path. | `yes` \| `no` |
| `testing` | The project's `CLAUDE.md` carries a line `Testing policy for /task-implement: <value>`, and its value. The marker and its values are `task-engine`'s testing-policy resolution's; the probe reads the value and interprets nothing. | the value, or `none` |
| `specs` | How many `*.md` files sit directly under `.claude/specs/` — the spec files `/quick-implement` leaves for `/pipeline-revise --catch-up`. A directory listing; no spec is read. | the count, `0` when the directory is absent |
| `installed` | Which pipeline features are installed under either install home — each feature a row of `routing.md` names, found as `commands/<name>.md` or `skills/<name>/SKILL.md`, either kind. Row names are unioned across both homes. | `<found>/<rows>`, plus ` (missing: <name>, …)` when any is absent; `unknown` when neither home has a `routing.md` |

- `sliced` follows `/architect`'s reading: a roadmap with no `Covers:` line
  is one it architects against in traditional mode.
- **There is no probe of `.claude/tasks/archive/`, and none may be added.** It
  would be the first traversal of a folder whose whole guarantee is that no
  command traverses it (`../../task-engine/references/resolution.md`
  § *The archive*), and no pipeline decision turns on whether it exists: an id
  absent from `TASKS.md` resolves from the absence alone.

## Which install home — both of them

- `council` and `installed` ask whether a *feature* is installed, not whether
  a project file exists, and answer for **both scopes Claude Code loads
  features from**: the project's own `.claude/`, where
  `chosko-llm add --local` writes, and the user scope — `CLAUDE_HOME` when
  set, else `~/.claude/`. A feature present in either is installed.
  `CLAUDE_HOME` relocates the user scope only; it never replaces the project
  scope.
- **Union `routing.md`'s row list across both homes too.** Taking it from
  whichever home is found first lets a stale copy drop a feature from the
  count, from `missing:` and from the denominator at once, leaving a verdict
  line that looks complete.
- **`installed=unknown` is not `0/0`.** With no `routing.md` in either home
  there is no row list, and a zero total would read as "nothing to install".
- This probe is the one shipped body that derives an install home, because
  `sh` cannot resolve a skill by name. Elsewhere a body cites a shipped file
  relative to itself, and asks whether an optional feature is installed by
  naming the feature.
