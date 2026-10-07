# Failures

| Situation | Orchestrator does |
|---|---|
| An agent reports a check failure it cannot fix | Stop the batch; report the failure and the agent's diagnosis; launch nothing until the owner decides. |
| Two agents need the same region | Serialise them: the second launches when the first has reported and its handoff is rewritten. |
| The single-instance tool is mid-reload or busy | Wait; never relaunch blindly. |
| An agent asks for a permission the orchestrator's session denied | Refuse; surface the request to the owner. |
| An agent's edit keeps failing on a shared file | The agent re-reads the region and retries; after that it reports the exact string it could not match and stops. |
| A handoff is missing or stale | The agent rebuilds it from the code regions its area owns, then continues. |
