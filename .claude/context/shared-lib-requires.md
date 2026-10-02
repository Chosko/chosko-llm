# Shared library: dependencies

## Overview

Covers dependencies (`requires:`) in `scripts/lib.sh`: the helpers that split,
trim and validate a feature's `requires:` value for `cmd-add`, `cmd-rm` and
`cmd-ls`. Kind-spec parsing it reuses:
[shared-lib-migration.md](./shared-lib-migration.md). The rest of `lib.sh`:
[shared-lib.md](./shared-lib.md).

## Public API

### Dependencies (`requires:`)
`requires:` names features this one reads a file out of. Flat, one level
deep, unversioned, non-transitive — a declaration, never a graph. `cmd-add`
installs what a feature names before installing it; `cmd-rm` refuses to
remove a feature something installed still requires.
- `requires_specs <file>` → one kind-prefixed spec per line, one per
  comma-separated entry of `requires:`. Whitespace around commas and around
  the kind colon squeezed out first, empty entries dropped. Each entry
  validated through `parse_replaces_spec` (§ Internal patterns). Prints
  nothing, returns 0, when the key is absent or empty.
  **`die`s on an entry with no kind prefix** rather than skipping it silently:
  the key exists to catch a dangling reference at install time, and a typo
  that parsed to nothing would defeat that. So call it through a command
  substitution (`specs="$(requires_specs "$f")" || exit 1`), NEVER a process
  substitution — there the `die` would kill only the subshell and leave the
  caller running.
- `requires_specs_lenient <file>` → the non-fatal sibling; `requires_specs` is
  a strict filter over it, re-reading the raw value only on its `die` path so
  the happy path parses the frontmatter once, not twice. Reads the
  `requires:` value and delegates to `requires_specs_from_value`, so it prints
  `ok<TAB><spec>` per well-formed entry, `bad<TAB><entry>` per entry with no
  kind prefix, nothing when the key is absent. For read-only consumers only —
  `cmd-ls`'s REQUIRES column, which must not be taken down by one typo in one
  unrelated feature; install- and removal-time callers use `requires_specs`
  and stay fatal.
- `requires_specs_from_value_into <value>` → the ONE place the value is
  actually split and trimmed, taking the raw string instead of a path so a
  caller that already parsed the file for another field doesn't parse it
  again — which is what `cmd-ls` does, once per row. Leaves its result in the
  **global array `REQUIRES_SPECS`** (`ok<TAB><spec>` / `bad<TAB><entry>` per
  element) so a looping caller needs no process substitution;
  `resolve_scope`/`SCOPE_ARGS` set that precedent. Split + both trims are
  parameter expansion. The three steps, in order: leading space, trailing
  space, then the FIRST colon's surroundings — hence a `%%`/`#` split on the
  last and not every colon.
- `requires_specs_from_value <value>` → the printing sibling; formats what
  `_into` left in `REQUIRES_SPECS`, one line per element.

## Internal patterns

- **`split_kind_spec` parses two keys, not one.** `requires:` reuses it for
  every entry rather than growing a second kind-prefix parser, so `replaces:
  skill:x` and `requires: skill:x` can never disagree about what a spec means.

## Domain dependencies

- None beyond [shared-lib-kinds.md](./shared-lib-kinds.md) § Domain
  dependencies.

## Cross-references

- [shared-lib-migration.md](./shared-lib-migration.md) — `split_kind_spec` /
  `parse_replaces_spec`, the kind-prefix split each entry goes through.
- [shared-lib-kinds.md](./shared-lib-kinds.md) — the kind helpers, and
  § Cross-references there for the `cmd-*` callers.

## When to read the source

- Changing what `requires:` accepts, how entries are split/trimmed, or whether
  a malformed entry dies rather than being skipped →
  `requires_specs_from_value_into` (the split/trim),
  `requires_specs_lenient` (the file-reading wrapper) and
  `requires_specs` (the strict filter over it) in
  `lib.sh`, plus `split_kind_spec` which validates each entry. The
  install-time and removal-time behaviour built on it lives in `cmd-add.sh`
  (`install_requires`) and `cmd-rm.sh` (the dependents guard) — see
  [cmd-add.md](./cmd-add.md) and [cmd-rm.md](./cmd-rm.md).
