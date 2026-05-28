# Smoke test: tool-usage-policy (claude-md)

## Setup

Run from a machine where `install.sh` has already been run.

## Steps

1. **List available** — `chosko-llm ls --available` shows `tool-usage-policy` with kind `claude-md`.

2. **Add** — `chosko-llm add tool-usage-policy` succeeds and prints:
   `[info] Installed claude-md 'tool-usage-policy' v0.1.0 -> ~/.claude/CLAUDE.md`

3. **Section present** — `grep 'chosko-llm:tool-usage-policy:begin' ~/.claude/CLAUDE.md` finds the
   begin tag with the correct version; content between begin and end tags matches the artifact body.

4. **Duplicate guard** — running `chosko-llm add tool-usage-policy` a second time exits non-zero
   with a message pointing to `update`.

5. **List installed** — `chosko-llm ls --installed` shows `tool-usage-policy` as `up-to-date`.

6. **Update (no-op)** — `chosko-llm update tool-usage-policy` reports `Already up-to-date`.

7. **Update --all** — `chosko-llm update --all` includes claude-md sections in its scan and
   reports `Already up-to-date: claude-md 'tool-usage-policy'`.

8. **User content preserved** — add a line of custom text above and below the managed section,
   then run `chosko-llm update tool-usage-policy`; the custom lines are still present afterward.

9. **Remove** — `chosko-llm rm tool-usage-policy` succeeds; the section (begin→end inclusive) is
   gone from CLAUDE.md while surrounding user content remains.

10. **Missing guard** — `chosko-llm rm tool-usage-policy` again exits non-zero with a "not
    installed" error.

## Note on first-time migration

If `~/.claude/CLAUDE.md` already contains the tool-usage-policy content without markers (written
manually before this feature existed), `add` will append a second copy inside markers. Remove the
unwrapped duplicate manually after the first `add`.
