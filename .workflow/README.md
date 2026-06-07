# Workflow State

This directory is managed by the feature-orchestrator agent and its sub-agents.

## Structure

```
.workflow/
  feature.md              # Feature spec (written by clarify-feature)
  stories.md              # Story list with statuses
  log.md                  # Global phase transition log
  stories/
    <NNN>-<slug>/
      spec.md             # Story spec and acceptance criteria
      tasks.md            # Task checklist
      status.md           # Current status (pending | in-progress | merged | done)
      pr.md               # PR URL and number
      log.md              # Story-level event log
```

## Statuses

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in-progress` | Story workflow is running |
| `merged` | PR merged, awaiting verification |
| `done` | Verified and complete |

## Starting the workflow

Tell Claude: "Start the feature workflow for <feature description>" — it will spawn the `feature-orchestrator` agent.
