# pipeline-statusline — architect progress

Covered:
- Input resolved: free-form prompt, `Source: prompt`, slug `pipeline-statusline`.
- Stack adopted from technical-direction.md (bash + awk, git-bash on Windows, no jq).
- Packaging decided with the user: statusline kind `statusline/pipeline-statusline.sh`
  plus command `commands/pipeline-statusline.md` with
  `requires: statusline:pipeline-statusline`.
- Shape proposed (renderer, wiring command, backup store, verifier); awaiting
  answers on PHASE 1 questions and confirmation of the shape.

Open questions raised:
- Coexistence with `session-statusline`.
- How a re-run refreshes the script (CLI update vs report only).
- Backup location and uninstall's scope (restore only vs also remove the script).
- `--local` install of the command (statusline is global-only).
