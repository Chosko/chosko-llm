---
name: pipeline-statusline
version: 0.1.1
type: command
description: Wire the pipeline-statusline status line into the user settings.json — backing up and later restoring any status line it replaces — refresh it, and verify it with a timed run. Use it to install, update or uninstall the pipeline status line.
requires: statusline:pipeline-statusline
---

# /pipeline-statusline
# Global command: set the user settings' `statusLine` to run the
# `pipeline-statusline` renderer (padding 1, refresh every 10 s), editing that
# one key and nothing else. A different status line already configured is
# shown and replaced only on the user's say-so, after it is backed up — its
# value and the script it runs — so `uninstall` restores it exactly. A re-run
# refreshes the renderer through `chosko-llm update` when the CLI is on the
# PATH. Every install ends with a verification: the renderer run on a status
# payload in this project and in a directory with no `.claude/`, timed.
# Global-only, as the statusline it requires. Never touches
# `statusline-progress.sh`, `statusline-combined.sh` (beyond copying it into
# the backup) or `statusline/session-statusline.sh`, and never deletes
# `statusline-last-input.json`. Commits nothing.
# Usage: /pipeline-statusline                  (install, or refresh when installed)
#        /pipeline-statusline --no-nerd-font   (same, with single-width Unicode glyphs)
#        /pipeline-statusline uninstall        (restore the previous status line)

GOAL
Leave the user's status line running the pipeline renderer, with whatever it
replaced recoverable byte for byte — or, under `uninstall`, put that back.

$ARGUMENTS

---

PATHS

- The statusline kind is global-only: everything this command touches lives
  in the user scope.
- Resolve the paths once, in one Bash call, and use the printed values for
  the rest of the run:

```sh
H="${CLAUDE_HOME:-$HOME/.claude}"
R="$H/statusline/pipeline-statusline.sh"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) command -v cygpath >/dev/null && R="$(cygpath -m "$R")" ;; esac
printf 'HOME_DIR=%s\nRENDERER=%s\nSETTINGS=%s\nBACKUP=%s\n' "$H" "$R" "$H/settings.json" "$H/statusline/pipeline-statusline.backup"
[ -f "$H/statusline/pipeline-statusline.sh" ] && echo present || echo missing
```

- RENDERER missing → stop with:
  `The renderer is not installed. Run chosko-llm add statusline:pipeline-statusline, then re-run /pipeline-statusline.`
- OURS is the `statusLine` this command writes:
  `{"type": "command", "command": "bash <RENDERER>[ --no-nerd-font]", "padding": 1, "refreshInterval": 10}`.
- A `statusLine` is *ours* when its `command` runs RENDERER, with or without
  the flag.

---

ARGUMENTS

- `uninstall` selects UNINSTALL; no `uninstall` token selects INSTALL.
- `--no-nerd-font` sets FLAG; it is meaningful only to INSTALL.
- Any other token → stop with the usage lines above.

---

INSTALL

1. **Read SETTINGS** with the Read tool.
   - Absent → it will be created holding only OURS.
   - Present but not valid JSON → stop, file untouched, naming the problem.

2. **Classify its `statusLine`.**
   - **absent** → write OURS (step 4); report `installed`.
   - **ours** → go to step 3; if its flag differs from FLAG, rewrite only
     the `command` string (step 4).
   - **anything else** → print the current value verbatim and ask:
     `A different status line is configured. Replace it (backed up, restored by /pipeline-statusline uninstall) or abort?`
     - Wait for an explicit answer; anything but replace is abort, which
       changes nothing.
     - On replace, write the backup (BACKUP below) first, then OURS
       (step 4); report `replaced`, naming BACKUP.

3. **Refresh** (already ours).
   - `command -v chosko-llm` finds the CLI → take a checksum of the renderer
     (`cksum`), run `chosko-llm update statusline:pipeline-statusline`,
     checksum again; report `already installed, script updated` when the two
     differ, else `already installed, unchanged`.
   - No CLI → report `already installed` with the renderer's `version:` line
     and `run chosko-llm update statusline:pipeline-statusline to refresh it`.

4. **Write `statusLine`** with the Edit tool.
   - Replace the existing `"statusLine": …` value, or insert the key beside
     the other top-level keys.
   - Change nothing else: no other key, no reordering, no reformatting.
   - Read the file back and confirm it still parses.

5. **Verify** (VERIFY below), then print the report:
   - the outcome from step 2 or 3;
   - BACKUP, when one was written;
   - one line noting that `statusline-last-input.json`, when present beside
     SETTINGS, is a leftover debug capture the user may delete.

BACKUP

- Write it only on replace, and never over an existing BACKUP: the backup
  always holds the status line that predates this command. BACKUP already
  exists → keep it and say so.
- `BACKUP/statusLine.json` — the replaced `statusLine` value, verbatim, as
  it stood in SETTINGS.
- The script that value runs — the first token of its `command` (after
  `bash`, `sh` or similar) that names an existing file, `~` expanded:
  - one exists → copy it into BACKUP under its original file name and write
    its original path, exactly as the command spelled it, to
    `BACKUP/script-path`;
  - none → no copy and no `script-path`.

---

UNINSTALL

1. Read SETTINGS. Its `statusLine` not ours → report
   `nothing to uninstall: the status line is not pipeline-statusline's`,
   and change nothing — BACKUP included.
2. **BACKUP exists** →
   - set `statusLine` back to the content of `BACKUP/statusLine.json`,
     verbatim, by the same surgical edit as INSTALL step 4;
   - when `BACKUP/script-path` exists and its path no longer holds a file
     identical to the copy (`cmp`), copy the script back there;
   - then delete BACKUP;
   - report `restored`, with the restored value.
3. **No BACKUP** → remove the `statusLine` key alone; report `removed`.
4. Either way, end with: the renderer stays installed —
   `chosko-llm rm statusline:pipeline-statusline` removes it.

---

VERIFY

Run after every INSTALL that did not abort, in Bash:

1. **The payload.**
   - `statusline-last-input.json` exists beside SETTINGS → read it and use
     its shape.
   - Otherwise use this fixture:

   ```json
   {"session_id":"verify","model":{"id":"claude","display_name":"Claude"},"workspace":{"current_dir":"<DIR>","project_dir":"<DIR>"},"cwd":"<DIR>","cost":{"total_cost_usd":1.2345},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":35,"resets_at":<RESET>},"seven_day":{"used_percentage":12}}}
   ```

   Whichever the source, then:
   - write two copies to a fresh `mktemp -d` directory: one with every
     current-directory field (`workspace.current_dir`,
     `workspace.project_dir`, `cwd`) set to the current project's path, one
     set to a second, empty `mktemp -d` directory with no `.claude/`;
   - set `rate_limits.five_hour.resets_at` to now plus 90 minutes
     (`date +%s`).
2. **The runs.** For each copy, run the `statusLine` command now in SETTINGS,
   timed with the bash `time` keyword (`TIMEFORMAT=%3R`, portable to the
   bash 3.2 that macOS ships), stdin from the copy, stdout to a file, and
   print the output followed by the elapsed seconds.
3. **Judge.**
   - The no-`.claude/` run prints one line.
   - The project run prints a second line, plus one per task in progress
     in scope, when the project has `.claude/TASKS.md` or
     `.claude/RUNBOOKS.md`.
   - Each run under one second; report a slower one as a warning, never
     retry it.
   - Remove both temporary directories.
