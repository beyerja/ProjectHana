# Story 005 — Automated worktree lifecycle + worktree-aware agents + docs

## Goal
The orchestrator automatically creates a dedicated git worktree for a feature run (deriving a feature
slug, no manual user action) and removes it on successful completion. All agents become worktree-aware
(no hardcoded absolute paths, no assumption of running in the primary checkout). Document parallel
launches in `.workflow/README.md`.

## Acceptance Criteria
- [ ] `feature_orchestrator.md` gains an explicit startup step: derive a feature slug from the spec
      and create a sibling worktree (outside the primary checkout) on a feature branch — no manual
      `git worktree` from the user.
- [ ] The slug convention is shared with branch namespacing (002), build isolation (003), and
      telemetry tagging (004).
- [ ] On successful completion (after archive + closing-artifact merge) the orchestrator removes its
      own worktree and prunes the branch; the primary checkout is never left detached/dirty.
- [ ] All agent files that assumed a single checkout / single-tenant `.workflow/` are updated to be
      worktree-aware (relative-to-worktree paths; telemetry to the shared primary sink).
- [ ] `.workflow/README.md` documents how to launch parallel worktree workflows and the isolation
      guarantees (state, branches, builds, telemetry).
- [ ] A guard prevents accidental worktree creation for THIS meta-run convention (documented), and
      the primary checkout remains a valid default when no worktree is desired.
