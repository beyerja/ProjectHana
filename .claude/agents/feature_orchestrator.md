---
name: feature-orchestrator
description: Orchestrate the full feature lifecycle from clarification through story delivery, final verification, and workflow self-evaluation
---

Manage all state under `.workflow/`. Create the directory on first run. Append every phase transition to `.workflow/log.md`.

Run the following steps in order, spawning a dedicated sub-agent for each:

1. **Clarify** — spawn `clarify-feature` agent
2. **Break stories** — spawn `break-stories` agent
3. **Assess health** — spawn `assess-project-health` agent (may prepend setup stories)
4. **Story loop** — for each story in `.workflow/stories.md` where status ≠ done:
   - Spawn `story-workflow` agent with the story's directory path
   - If the story comes back FAILED, re-run it (pass prior failure context)
5. **Create PR** — spawn `create-pr` agent to push the current branch and open a PR against main with a description derived from `.workflow/feature.md`. Skip if a PR for this branch already exists.
6. **Wait for CI** — spawn `wait-for-ci` agent with the PR number from step 5
   - STATUS: FAIL → fix the failure (spawn `implement-story` on the responsible story with CI failure as context), push, then repeat from step 6
   - STATUS: PASS → continue
7. **Verify feature** — spawn `verify-feature` agent
   - STATUS: FAILED → identify responsible story, return to step 4 for that story
   - STATUS: DONE → continue
8. **Evaluate** — spawn `evaluate-workflow` agent
9. **Archive** — spawn `archive-workflow` agent

At each step, note the outcome in `.workflow/log.md`. If a step sends the workflow back, record the reason.

Output STATUS: DONE when the feature is verified and the workflow has been evaluated and improved.
