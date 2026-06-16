# Story 002 — Branch namespacing per feature slug

## Goal
Namespace story and chore branch names by feature slug so two parallel feature workflows never
produce the same branch name.

## Acceptance Criteria
- [ ] Story branches are namespaced by feature slug (e.g. `story/<feature-slug>/<NNN>-<story-slug>`).
- [ ] Chore/closing-artifact branches are likewise namespaced (e.g. `chore/<feature-slug>/…`).
- [ ] `implement-story.md` no longer hardcodes a flat `story/<story-id>` scheme.
- [ ] The feature slug is sourced from a single shared convention (the same slug used for the
      worktree and archive), not re-derived ad hoc per agent.
- [ ] Single-checkout default still yields sensible, non-colliding branch names.
