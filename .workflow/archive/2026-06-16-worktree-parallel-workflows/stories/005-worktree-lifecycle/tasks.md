## Tasks
- [ ] 001: Audit all agent files for hardcoded absolute paths / single-checkout assumptions; confirm none break in a worktree (telemetry already routes to primary via story 004).
- [ ] 002: Add a worktree-lifecycle startup step to feature_orchestrator.md — derive HANA_FEATURE_SLUG from the spec, create a sibling worktree on a feature branch, export the slug for all sub-agents; include a guard so meta/primary runs (this one) can opt out.
- [ ] 003: Add a teardown step to feature_orchestrator.md — after archive + closing-artifact merge, remove the worktree and prune the branch, never leaving the primary checkout dirty/detached.
- [ ] 004: Make create-pr.md and archive-workflow.md worktree/slug aware (PR head branch namespaced; archive committed on the feature branch so it merges to main).
- [ ] 005: Document parallel worktree launches + isolation guarantees in .workflow/README.md.
