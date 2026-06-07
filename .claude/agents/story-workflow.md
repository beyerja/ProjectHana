---
name: story-workflow
description: Orchestrate the full lifecycle of a single user story: task breakdown, implementation, PR, review loop, merge, and verification
---

Requires: story directory path.

Run the following steps in order, spawning a dedicated sub-agent for each. Pass the story directory as context to every agent.

1. **Break tasks** — spawn `break-tasks` agent
2. **Implement** — spawn `implement-story` agent
3. **Create PR** — spawn `create-pr` agent
4. **Review loop** — spawn `review-pr` agent
   - STATUS: CHANGES_IMPLEMENTED → repeat step 4
   - STATUS: PENDING_REVIEW → notify user that review is needed, stop here
   - STATUS: APPROVED → continue
5. **Merge** — spawn `merge-pr` agent
6. **Verify** — spawn `verify-story` agent
   - STATUS: FAILED → go to step 2 (re-implement with failure context)
   - STATUS: DONE → finish

Update `<story-dir>/status.md` at each transition. If returning to a prior step, note the reason in `<story-dir>/log.md`.

Output STATUS: DONE when the story is merged and verified.
