# Story 002 — Wire triage-dep-prs into the feature orchestrator

## Title
Integrate `triage-dep-prs` as Step 1 of `feature-orchestrator`

## Goal
Update `.claude/agents/feature_orchestrator.md` so that, immediately after worktree setup (Step 0)
and before `clarify-feature`, the orchestrator spawns the `triage-dep-prs` agent. After the triage
agent completes, the orchestrator runs `git fetch origin && git merge origin/main` inside the
feature worktree so all subsequent story work starts from the post-triage `main`.

## Acceptance Criteria

- [ ] `feature_orchestrator.md` references `triage-dep-prs` as a numbered step between worktree
      setup (Step 0) and the clarify step (which becomes Step 2).
- [ ] The orchestrator spawns `triage-dep-prs` unconditionally on every new feature run
      (not only when dep PRs are detected — the agent itself handles the no-op case).
- [ ] After `triage-dep-prs` returns `STATUS: DONE`, the orchestrator runs:
      ```
      git -C <worktree> fetch origin
      git -C <worktree> merge origin/main
      ```
      to pull any freshly-merged dep changes into the feature branch before proceeding.
- [ ] The orchestrator logs the outcome of the triage step (how many PRs merged / skipped, or
      "no dep PRs") in `.workflow/log.md`.
- [ ] The existing step numbering (clarify, break-stories, assess-health, story-loop, …) is
      renumbered consistently — no step is lost or duplicated.
- [ ] The update does not alter any other orchestrator logic (the story loop, CI wait, verify,
      evaluate, archive, teardown steps are unchanged).
- [ ] The file compiles correctly as a Markdown agent spec (valid frontmatter, no broken
      references to old step numbers in the prose).
