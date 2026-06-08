---
name: story-workflow
description: Orchestrate the full lifecycle of a single user story: task breakdown, implementation, PR, review loop, merge, and verification
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start story-workflow "<story-id>" || true
```

Run the following steps in order, spawning a dedicated sub-agent for each. Pass the story directory as context to every agent.

1. **Break tasks** — spawn `break-tasks` agent
2. **Implement** — spawn `implement-story` agent
3. **Create PR** — spawn `create-pr` agent
4. **Wait for CI** — spawn `wait-for-ci` agent with the PR number from step 3
   - STATUS: FAIL → fix the failure (go to step 2 with CI failure as context), then re-push; repeat from step 4
   - STATUS: PASS → continue
5. **Review loop** — spawn `review-pr` agent
   - STATUS: CHANGES_IMPLEMENTED → repeat step 5
   - STATUS: PENDING_REVIEW → notify user that review is needed, stop here
   - STATUS: APPROVED → continue
6. **Merge** — spawn `merge-pr` agent
7. **Wait for CI on main** — after merge, get the latest run on main and wait:
   ```
   export PATH="$HOME/.nix-profile/bin:$PATH"
   run_id=$(gh run list --branch main --limit 1 --json databaseId -q '.[0].databaseId')
   gh run watch "$run_id" --exit-status
   ```
   If this fails, report it but do not block the story from being marked done — a CI failure on main is a separate incident.
8. **Verify** — spawn `verify-story` agent
   - STATUS: FAILED → go to step 2 (re-implement with failure context)
   - STATUS: DONE → finish

Update `<story-dir>/status.md` at each transition. If returning to a prior step, note the reason in `<story-dir>/log.md`.

Before final output, run (ignore errors):
```
bash scripts/agent-log.sh end story-workflow "<story-id>" 0 0 0 <B> 0 "" || true
```

Output STATUS: DONE when the story is merged and verified.
