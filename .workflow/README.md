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

## Running workflows in parallel (worktrees)

Multiple feature workflows can run **concurrently**, each in its own git worktree, with no manual git
commands from you. On startup the orchestrator (`feature-orchestrator`, Step 0) derives a **feature
slug** and — unless the run modifies the workflow tooling itself, see below — creates a sibling
worktree on a fresh `feat/<slug>` branch:

```
git worktree add -b feat/<slug> ../ProjectHana-<slug> main
```

It exports `HANA_FEATURE_SLUG=<slug>`, which is the single shared id that isolates everything:

| Concern        | Isolation mechanism                                                          |
|----------------|------------------------------------------------------------------------------|
| `.workflow/` live state | `feature.md`, `stories.md`, `log.md`, `stories/` are gitignored — each worktree owns its own copy. Only `archive/` + this README are tracked. |
| Branches       | `story/<slug>/<NNN>-…` and `chore/<slug>/…` (see `implement-story`, `merge-pr`). |
| Builds         | `just`'s `wt` var (from `HANA_FEATURE_SLUG`) suffixes DerivedData and `/tmp` output; `sim`/`HANA_SIM_NAME` picks a per-worktree simulator. Empty slug = legacy single-checkout paths. |
| Telemetry      | All worktrees write to the **one** sink in the primary checkout (`scripts/agent-log.sh` resolves it via `git rev-parse --git-common-dir`), each record tagged with the slug. `just telemetry --by-feature` breaks it down. |

To launch two features at once, just tell Claude to start two workflows with different descriptions;
each gets a distinct slug and worktree. On successful completion the orchestrator (Step 11) removes its
own worktree and prunes its branch, leaving the primary checkout clean.

**Meta / tooling runs (opt-out):** a run that edits the workflow tooling itself (`.claude/agents/`,
`justfile`, `.gitignore`, `scripts/`, this README) runs **in the primary checkout** on a `feat/<slug>`
branch without a worktree — a worktree would carry stale committed copies of the very files being
changed. The slug, branch namespacing, build isolation, and telemetry tagging still apply.
