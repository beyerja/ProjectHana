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
5. **Verify feature** — spawn `verify-feature` agent
   - STATUS: FAILED → identify responsible story, return to step 4 for that story
   - STATUS: DONE → continue
6. **Evaluate** — spawn `evaluate-workflow` agent
7. **Archive** — spawn `archive-workflow` agent

At each step, note the outcome in `.workflow/log.md`. If a step sends the workflow back, record the reason.

Output STATUS: DONE when the feature is verified and the workflow has been evaluated and improved.
