---
name: story-workflow
description: Orchestrate the full lifecycle of a single user story: task breakdown, implementation, PR, review loop, merge, and verification
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
just log start story-workflow "<story-id>" || true
```

Run the following steps in order, spawning a dedicated sub-agent for each. Pass the story directory as context to every agent.

1. **Break tasks** — spawn `break-tasks` agent
2. **Implement** — spawn `implement-story` agent
3. **Create PR** — spawn `create-pr` agent
4. **Wait for CI** — spawn `wait-for-ci` agent with the PR number from step 3 and the story-id
   - STATUS: FAIL → fix the failure (go to step 2 with CI failure as context), then re-push; repeat from step 4
   - STATUS: PASS → continue
5. **Review loop** — spawn `review-pr` agent
   - STATUS: CHANGES_IMPLEMENTED → repeat step 5
   - STATUS: PENDING_REVIEW → notify the user that the PR needs review and they should merge it when ready. Wait for the user's confirmation that the PR is merged, then skip step 6 and go directly to step 7.
   - STATUS: APPROVED → continue
6. **Merge** — spawn `merge-pr` agent (skip this step if the user already confirmed they merged the PR in the PENDING_REVIEW path above)
7. **Verify** — spawn `verify-story` agent
   - STATUS: FAILED → go to step 2 (re-implement with failure context)
   - STATUS: DONE → finish

Update `<story-dir>/status.md` at each transition. If returning to a prior step, note the reason in `<story-dir>/log.md`.

**Telemetry — always run before exiting, even if a subagent handled the final step:**
```
just log end story-workflow "<story-id>" 0 0 0 <B> 0 "" || true
```
Where `<B>` = number of Bash calls made directly by this agent (not by subagents). This call must be issued by the story-workflow agent itself, not delegated.

Output STATUS: DONE when the story is merged and verified.
