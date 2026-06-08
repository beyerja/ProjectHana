---
name: break-tasks
description: Break a user story into atomic implementation tasks by reading the story spec and inspecting the codebase
---

Requires: story directory path as input (e.g. `.workflow/stories/001-<slug>`).

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start break-tasks "<story-id>" || true
```

Read `<story-dir>/spec.md`. Inspect the codebase: CLAUDE.md if present, relevant source files, existing patterns.

Break the story into atomic, independently implementable tasks — each task is one focused change.

Initialise `<story-dir>/log.md` with a header line if it does not already exist:
```
# Log — <story-title>
```

Write `<story-dir>/tasks.md`:
```
## Tasks
- [ ] 001: <description>
- [ ] 002: <description>
```

Count tool calls (R/W/E/B) and estimate chars, then run (ignore errors):
```
bash scripts/agent-log.sh end break-tasks "<story-id>" <R> <W> <E> <B> <est_chars> "" || true
```

Append to `<story-dir>/log.md`: `<timestamp> break-tasks: DONE, <N> tasks`.

Output STATUS: DONE.
