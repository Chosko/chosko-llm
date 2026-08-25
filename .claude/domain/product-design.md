# chosko-llm

`chosko-llm` is a personal, git-backed workbench for Claude Code
configuration. It is two halves of one product: a small CLI that installs
commands, skills, CLAUDE.md snippets, statuslines, and hooks into
`~/.claude/` — or into a single repository — on any machine, and an authoring environment — domain docs, a navigation
context layer, a task backlog, and a frontmatter contract — that makes
those features reliable to design, plan, implement, and maintain. The
distribution half answers "how does my config reach this machine"; the
authoring half answers "how does an idea become a working feature". Both
live in the same repository and are used by the same person, in different
sessions.

Technical foundations (stack, architecture, hosting) are recorded in
[technical-direction.md](./technical-direction.md), not here.

## Target users

The product is built for personal and small-team use. It is not a public
package registry and is not designed for anonymous consumers.

**The director.** The repository's owner, working on their own Claude Code
setup. They do not write feature prompts by hand — Claude does the
implementation. Their role is to decide what a feature should do, review
what Claude produced, and approve it into history. What they reach for the
product with is a new idea, a rough edge in an existing feature, or a fresh
machine that has no configuration on it.

**Claude, as operator.** Every feature in this repository is authored by
Claude Code working inside the repository's own structure. Claude is the
one that reads the domain and context layers, works the task backlog,
writes the markdown, and bumps the versions. The authoring half of the
product exists primarily to give Claude enough structure to do that
reliably; the ergonomics that matter are Claude's, not a human editor's.

**Consuming teammates.** People who want the features but do not author
them. They run `install.sh`, get the managed clone and the installed
features, and stay on the receiving end.

**Authoring teammates.** People who clone, install, and occasionally build
something. Write access to the repository is held by the owner alone;
teammates contribute through pull requests.

Before this existed, the alternative in reach was a dotfiles repository
with symlinks into `~/.claude/`. That distributes files but offers nothing
for designing or maintaining what is in them.

## User experience and key flows

**Zero to configured on a new machine.** Run `install.sh`. It clones the
repository into a managed clone at `~/.chosko-llm/` and places a thin proxy
at `~/bin/chosko-llm`. From there `chosko-llm add --all` copies the
available features into `~/.claude/`. `chosko-llm ls` shows what is
installed against what is available, with versions, so the gap between the
two is always visible. A machine goes from nothing to the full
configuration in one command.

**Idea to shipped feature.** The director describes what they want. Claude
works inside the repository's structure — reading the domain layer for
product and workflow knowledge and the context layer for codebase
structure, then either implementing directly or going through the task
backlog (`/task-add`, `/task-implement`) for work that deserves planning.
The feature is written under `commands/` or `skills/` with its frontmatter
contract, its version set, and the root `VERSION` bumped. Verification is
by reading the diff and running the CLI against a real clone. The director
reviews and commits. The feature reaches other machines on the next
`chosko-llm upgrade` and `chosko-llm update`.

**Testing unmerged work without breaking anything.** `chosko-llm channel
<branch>` points the managed clone at a branch, so a feature can be
installed and exercised for real before it lands on the main branch. Other
terminals continue running the last-pushed version, because the working
repository and the managed clone are separate copies.

**Deploying features into a single repository.** `--local` installs
selected features into a project rather than into `~/.claude/`, so cloud
agents that cannot run `install.sh` still have the commands they need.

## Design decisions

- **One product, two halves.** Distribution and authoring ship together
  and are versioned together. The authoring environment is not scaffolding
  around the CLI; it is the reason the product exists.
- **Copy on install, never symlink.** Installed features are independent
  copies. Editing the working repository does not change what is installed
  until `chosko-llm update` runs.
- **The working repository and the managed clone are separate.** The
  friction this creates — edit here, `upgrade` and `update` there — is
  accepted deliberately in exchange for sandbox isolation: work in progress
  cannot break the version other terminals are using.
- **The filesystem is the state.** Installed and available features are
  discovered by walking directories and reading frontmatter. There is no
  lockfile and no state file.
- **Features are versioned individually and at the root.** Each command and
  skill carries a `version:` in its frontmatter; the repository carries a
  root `VERSION`. A shipped change moves both.
- **Global features by default.** The product targets `~/.claude/`.
  `--local` is a deployment option for repositories whose agents cannot
  install, not a second class of feature.
- **A feature may start project-specific and generalize.** Some features
  were built for one repository — the Plastic SCM and Unity sections — and
  are expected to serve others over time. Being born narrow is not a defect.
- **Gates keep the director in the reviewer's seat.** Plan-first approval,
  authoring commands that leave their output uncommitted unless `--commit`
  is passed, and stop-and-approve phases exist so that Claude operates and
  the director decides.
- **Governance stays simple on purpose.** One person holds write access;
  authoring teammates open pull requests. A richer permission model was
  judged not worth the scope.
- **No dependencies beyond POSIX shell tooling.** Bash with awk, sed, and
  grep. No yq, jq, or Python.
- **No test suite, by design.** The product ships markdown prompts and thin
  shell wrappers; changes are verified by reading the diff and running the
  CLI against a real clone.
- **Nothing is permanent, but nothing changes before the need is
  demonstrated.** Every constraint above is open to revision once a real
  problem shows up. None of them are revised in anticipation of one. Known
  and deliberately unaddressed today: local copies installed with `--local`
  may drift from the global version, and `ls` / `update` have no local
  awareness — both wait on evidence that the drift actually costs
  something. On the same terms, and with no trigger set: `/task-add
  feature=<slug>` does not warn when a feature's dependencies are
  unsatisfied. It was weighed while designing the planning layer and left
  out, because nothing yet shows the warning would change a decision.

## High-level features

Eleven features, listed in the order the product is experienced: the four
that distribute configuration to a machine, then the seven that author it.
Where a feature's mechanism is already specified in a workflow document, this
section names the experience and points there rather than restating it.

### Machine bootstrap

Getting the product onto a machine that has never had it. One run of
`install.sh` clones the repository into a managed clone at `~/.chosko-llm/`
and places a thin proxy at `~/bin/chosko-llm`, so the tool is on the path
and pointed at a copy the user never edits by hand. `uninstall.sh` reverses
that, leaving whatever was installed into `~/.claude/` to be removed
separately. Serves the consuming teammate and the director on a fresh
machine; it is the opening step of the zero-to-configured flow, and nothing
else in the product works before it has run.

### Feature catalogue and deployment

See the gap, close the gap. `ls` reports every feature with its installed
version against its available version, so the difference between what this
machine has and what the repository offers is always visible; `show`
inspects one feature — versions, status, description, body, or a diff
against the installed copy. `add`, `rm`, and `update` move features across,
one at a time or with `--all`. The default target is `~/.claude/`;
`--local` installs into the current repository instead, for agents that
cannot run `install.sh` themselves. All five artifact kinds — commands,
skills, CLAUDE.md snippets, statuslines, hooks — use the same verbs. Two of
them are scope-bound in opposite directions: a statusline belongs to a
terminal and is global-only; a hook only fires where it is committed and is
local-only. Serves every
user; completes the zero-to-configured flow and is the whole of the
`--local` deploy flow. Copies placed with `--local` can drift, as recorded
under design decisions above.

### Staying current

`upgrade` pulls the managed clone and refreshes the proxy, so both CLI
behaviour and feature content arrive without re-running `install.sh`; a
daily auto-upgrade can be switched on so it happens unattended. `channel`
points the managed clone at a branch — with no argument it reports the
current channel, `--list` shows what is available — so unmerged work can be
installed and exercised for real. Serves the director testing a feature
before it lands, and every user keeping up. Upgrading the clone and
updating the installed copies stay two separate acts, in line with the
copy-on-install decision.

### Config export

Packages a repository's Claude configuration into a single markdown file or
a zip, for use where the CLI is not: handing the configuration to someone
who does not have the tool, feeding it to another agent, or recording what
a project was configured with at a point in time. Serves the director and
teammates, and does not depend on the install path.

### Project initialization

Takes a repository Claude Code has never worked in to one it can.
`/project-setup` is the wizard: it gathers every choice up front — version
control system, CLAUDE.md content, AGENTS.md, task backlog, domain layer,
context layer — confirms once, then executes them in a fixed order.
`/task-setup` and `/domain-setup` do their own parts standalone for a
project that needs only one. Serves Claude-as-operator above all: what it
produces is the structure Claude reads in every later session. Every
authoring feature below assumes it has run.

### Product design pipeline

Turns an idea into a designed feature. `/product-design` works top-down
with the director — product, users, flows, decisions, feature set,
technical direction — writing the domain documents as it goes and resuming
across sessions from a recorded stage rather than from anyone's memory.
`/architect` takes one high-level feature from that design and produces a
low-level feature document plus its entry in the feature index. The
director decides, Claude writes. First half of the idea-to-shipped flow.
The document set, the feature index schema, and the feature status
vocabulary are specified in [product-workflow.md](./product-workflow.md).

### Roadmap and planning

Answers when, which the pipeline above and the backlog below both leave open.
`/product-roadmap` records an ordered set of milestones — each with the
outcome it delivers, the criteria that make it shippable, and the share it
takes of each high-level feature. That share is the load-bearing idea: a
high-level feature is a design unit, not a scheduling unit, and the axis that
splits it across releases is business strategy rather than architecture, so
"Authentication" can mean email and password in an early milestone and
third-party providers in a much later one. Those **scope slices** are what
`/architect` then decomposes, one at a time, so no low-level feature ever
straddles a release.

`/production-plan` takes it from there at feature level, writing
`.claude/PLAN.md`: which architected feature sits in which milestone, in what
order, and after which others. Dependencies are proposed from the prose each
feature document already carries and recorded as a graph; a cycle, or a
dependency scheduled after the thing that needs it, is refused rather than
warned about. Position in a milestone's list is the priority — there is no
second priority axis to contradict it.

`/production-status` reads the result and answers the question the whole
layer exists for: what to build next, what is blocked and by what, and which
roadmap slices have no architected features yet. `/task-list` groups the
backlog by milestone when a plan exists. Both write nothing and derive
everything at read time.

Serves the director deciding what the next release contains, and Claude as
the operator that has to pick up work in a defensible order. The roadmap
holds intent and rationale in the domain layer; `PLAN.md` holds state beside
`TASKS.md` and `FEATURES.md`, the same split as `product-design.md` versus
`FEATURES.md`. Both stages are entered, never mandatory: a project with no
roadmap gets dependency ordering anyway, and every command above behaves
exactly as it does today when neither document exists.

### Task backlog

Turns a designed feature — or a free-form description, which needs no
design upstream — into implementable work, then into code. `/task-add`
plans and writes tasks; `/task-list` and `/task-clean` keep the backlog
readable and pruned; `/task-implement` implements, optionally giving each
task of a multi-task run its own subagent. A task declares who implements
it — Claude, or a human performing steps no agent can. Second half of the
idea-to-shipped flow; the seam with the feature above is the feature
document. Schemas and the implementation model are specified in
[task-workflow.md](./task-workflow.md).

### Navigation context layer

Cuts what every later session costs. `/context-build` reads the codebase
once and writes a navigation layer recording which file implements what, so
later sessions read short context files instead of source. `/context-update`
refreshes it after changes; `/context-convert` restructures between a flat
layer and a nested router-plus-leaves one as the codebase grows. Serves
Claude-as-operator; the director experiences it only as sessions that stay
affordable. It describes structure, not product knowledge — the boundary
against this document's own layer, and the rest of the mechanism, is in
[context-workflow.md](./context-workflow.md).

### Codebase maintenance

Behaviour-preserving cleanup on demand. `/refactor-codebase` applies
clean-code work — extracted constants, removed duplication, split oversized
files, tidied imports, renamed identifiers — behind a plan-first gate the
director approves before anything changes, and can be limited to a scope or
to one concern. `/refactor-tests` splits oversized test files, running the
suite before and after each split to keep the baseline green. Serves the
director; changes no observable behaviour by construction. The philosophy
and invariants are in [refactor-workflow.md](./refactor-workflow.md).

### Unity/MCP integration

Makes a Unity project ready for MCP-assisted implementation.
`/unity-mcp-setup` installs the Unity-side package, records the fact in the
project's versioned artifacts, and registers and verifies the machine-local
server; `unity-mcp-skill` is what Claude then reads to drive the editor.
Serves the director on Unity projects and Claude as the operator of one.
Born for a single repository and expected to serve others — the working
example of the decision above that a feature may start project-specific and
generalize.
