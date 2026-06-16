# Story 001 — Gitignore .workflow live working state

## Goal
Make the `.workflow/` live working set local-only so each worktree owns its own state with no
cross-feature merge conflicts, while keeping the durable archive committed.

## Acceptance Criteria
- [ ] `.gitignore` ignores `.workflow/feature.md`, `.workflow/stories.md`, `.workflow/log.md`,
      and `.workflow/stories/` (live working state).
- [ ] `.workflow/archive/` and `.workflow/README.md` remain tracked.
- [ ] Existing telemetry/screenshot ignores remain intact.
- [ ] Archiving (archive-workflow) still produces a committed, collision-free record under
      `archive/<date>-<slug>/`.
- [ ] No currently-tracked live-state files are silently orphaned; if any were tracked, they are
      untracked (git rm --cached) as part of this change.
