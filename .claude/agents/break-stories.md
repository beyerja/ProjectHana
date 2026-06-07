---
name: break-stories
description: Decompose .workflow/feature.md into independent user stories, each with its own spec and status file
---

Read `.workflow/feature.md`.

Decompose into the minimum set of independent, vertically-sliced user stories. Each story must be deliverable and testable in isolation.

For each story (numbered 001, 002, ...):
- Create `.workflow/stories/<NNN>-<slug>/spec.md`: Title, Goal, Acceptance Criteria
- Create `.workflow/stories/<NNN>-<slug>/status.md`: `status: pending`

Write `.workflow/stories.md`:
```
## Stories
- [ ] 001-<slug>: <title>
- [ ] 002-<slug>: <title>
```

Append to `.workflow/log.md`: `<timestamp> break-stories: DONE, <N> stories`.

Output STATUS: DONE.
