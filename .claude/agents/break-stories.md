---
name: break-stories
description: Decompose .workflow/feature.md into independent user stories, each with its own spec and status file
---

**Telemetry — run at the very start (ignore errors):**
```
just log start break-stories "feature" || true
```

Read `.workflow/feature.md`.

Decompose into the minimum set of independent, vertically-sliced user stories. Each story must be deliverable and testable in isolation.

When a feature generalizes existing concrete code over a new abstraction (protocol/generic) before plugging in variants, make the abstraction the first story and order it so every story's commit compiles on its own — if an earlier story references a type a later story introduces, have the earlier story ship a minimal stub (e.g. a loader returning empty) so the build is never red between stories.

For each story (numbered 001, 002, ...):
- Create `.workflow/stories/<NNN>-<slug>/spec.md`: Title, Goal, Acceptance Criteria
- Create `.workflow/stories/<NNN>-<slug>/status.md`: `status: pending`

Write `.workflow/stories.md`:
```
## Stories
- [ ] 001-<slug>: <title>
- [ ] 002-<slug>: <title>
```

Count tool calls (R/W/E/B), run (ignore errors):
```
just log end break-stories "feature" <R> <W> <E> <B> <est_chars> "" || true
```

Append to `.workflow/log.md`: `<timestamp> break-stories: DONE, <N> stories`.

Output STATUS: DONE.
