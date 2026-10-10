# pipeline-dashboard — architect progress

Covered:
- Input resolved: free-form prompt (the user's spec message), `Source: prompt`,
  slug `pipeline-dashboard`. Prototype read from the published artifact
  (page + data.js shape).
- Stack adopted from technical-direction.md (bash + awk, no jq); the page is a
  self-contained HTML artifact.
- Shape proposed: skill body (activation, ownership, triggers, publish
  protocol, pending protocol), generator (awk → data.js / text snapshot),
  page template, per-project state dir in the user scope, one citation line
  in runbook-run and task-implement. Awaiting answers and confirmation.

Open questions raised:
- Project identity across machines and sessions (state-dir slug, reuse of an
  existing artifact found by title).
- Project without PLAN.md (no active milestone).
- Citation as optional (by name) vs `requires:`.
