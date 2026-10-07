# Shared library: frontmatter and validation

## Overview

Covers frontmatter parsing and source validation in `scripts/lib.sh`: the
`_FM_AWK` scanner, the readers built on it, and the installability check
`cmd-add` / `cmd-update` run before copying. The rest of `lib.sh`:
[shared-lib.md](./shared-lib.md).

## Public API

### Frontmatter
One scanner, `_FM_AWK`, with two `mode=` values — a second copy of the parser
would be a copy that drifts. It scans each file to the end rather than
`exit`ing at the closing `---` (a multi-file run cannot exit on the first file)
and clears `in_fm` there, so in both modes only the first `--- ... ---` block
is read.
- `parse_frontmatter <file>` — `mode=print`. Emits `key=value` lines, in file
  order, for nine recognized keys: `name`, `version`, `type`, `description`,
  `replaces`, `requires`, `event`, `matcher`, `project-policy`. Quotes stripped. Unknown keys
  silently dropped. First four required in practice; `replaces` optional (kind
  migration, [shared-lib-migration.md](./shared-lib-migration.md) § Public API › Kind
  migration), `requires` optional on every kind (dependencies,
  [shared-lib-requires.md](./shared-lib-requires.md) § Public API › Dependencies),
  `event`/`matcher` read for hook kind only and ignored elsewhere,
  `project-policy` optional and read only by `scripts/check-setup.sh`
  ([feature-contract.md](./feature-contract.md)). Split is on
  the FIRST colon, so a kind-prefixed value like `skill:task-engine` survives
  it intact.
- `read_frontmatter_field <file> <field>` — prints one field's value, empty if absent.
- `read_frontmatter_table <field-list> <file>…` — `mode=table`. ONE awk over
  every file given; prints `<file>` then one TAB-separated value per field, in
  the order `<field-list>` (a single space-separated string) names them, empty
  where the key is absent, first occurrence winning where it repeats. **Every
  path must exist and be readable** — awk aborts the whole run on one that is
  not, taking every file after it in the list with it, so the caller's own
  `-f` / `-r` guards stay the decider; that is the price of the batch. A file
  with no lines at all produces no output line, so read the result **by path,
  not by position**. Split each line with parameter expansion, **never
  `read -a`**: TAB is IFS whitespace, so `read -a` collapses two adjacent empty
  fields into one. TAB is also the field separator, so no requested field's
  value may contain one — a documented limit rather than a live case, since
  the keys read this way are versions and kind-prefixed specs.
- `read_frontmatter_fields <file> <field>…` — the parse-once reader for a
  caller needing two or more fields off the SAME block; it is
  `read_frontmatter_table` narrowed to one file, so the two cannot disagree
  about a value. Prints one line per requested field in the order given (empty
  line for an absent key), so the reader is one `read -r` per field:
  `{ IFS= read -r ver; IFS= read -r req; } < <(read_frontmatter_fields "$f"
  version requires)`. Line count always matches field count — no frontmatter
  value can carry a newline. Missing file yields empty values, not an error.
  One field → keep using `read_frontmatter_field`; a whole list of files → use
  the table directly and pay one awk for all of them.

### Validation
- `require_versioned_source <file>` — `die`s if file missing or its
  frontmatter missing non-empty `version` or `name`. Called by
  `cmd-add` and `cmd-update` before copying. Never checks `replaces`.

## Internal patterns

- **Frontmatter parsing awk-only.** Adding a field means one more `key == "…"`
  clause in `_FM_AWK`'s allowlist, because the generic first-colon split
  already handles any value. Cheap, but never free: the allowlist is the only
  place a key becomes visible, so a new field that is not added there is
  silently dropped. Allowed tooling: `../../CLAUDE.md` § Things to avoid.

## Domain dependencies

- None beyond [shared-lib.md](./shared-lib.md) § Domain dependencies.

## Cross-references

- [shared-lib.md](./shared-lib.md) — the hub: the frontmatter schema
  dependency and the callers.
- [shared-lib-kinds.md](./shared-lib-kinds.md),
  [shared-lib-migration.md](./shared-lib-migration.md),
  [shared-lib-requires.md](./shared-lib-requires.md) — the `event:`/`matcher:`,
  `replaces:` and `requires:` keys this scanner reads.

## When to read the source

- Adding/renaming frontmatter field → the `key == "…"` allowlist in `_FM_AWK` in
  `lib.sh`.
- Changing how many processes a caller spends reading frontmatter →
  `read_frontmatter_table` in `lib.sh` and the caller's own loop.
- Changing what makes source file installable → `require_versioned_source`
  in `lib.sh`.
