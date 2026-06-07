---
name: break-tasks
description: Break a user story into atomic implementation tasks by reading the story spec and inspecting the codebase
---

Requires: story directory path as input (e.g. `.workflow/stories/001-<slug>`).

Read `<story-dir>/spec.md`. Inspect the codebase: CLAUDE.md if present, relevant source files, existing patterns.

Break the story into atomic, independently implementable tasks — each task is one focused change.

Write `<story-dir>/tasks.md`:
```
## Tasks
- [ ] 001: <description>
- [ ] 002: <description>
```

Append to `<story-dir>/log.md`: `<timestamp> break-tasks: DONE, <N> tasks`.

Output STATUS: DONE.
