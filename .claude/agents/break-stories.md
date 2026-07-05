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

**A "plumbing/foundation" story must actually complete the wiring it promises.** If a foundation story claims to reduce later stories to "pure X work that only ADD <data>," then leaving any downstream site stubbed (a `return nil` switch arm, an entry omitted from a provider's list, a placeholder resource) makes that promise false — every later story then hits the missing wiring as a wall, and the tempting "fix" is to degrade an enforcement/completeness test to pass (e.g. an `XCTSkip`), silently disabling the guarantee. So when a foundation story exists, make its acceptance criteria explicitly cover **every** fan-out site (all exhaustive switches, all provider registrations, all resource entries) — either fully wired or, better, **data-driven** so new variants need no new switch arms at all. A compiling stub is acceptable for *cross-story build order*; a stub that the foundation story claimed to have completed is a scope gap, not a stub.

**View-layer wiring is a story responsibility, not a post-hoc fix.** When a story changes a session
or model type that is displayed in a SwiftUI view (e.g. a count, flag, or list passed to a summary
screen), its acceptance criteria MUST include the view-layer wiring: that the view actually receives
and displays the new value. A story that implements the session correctly and passes unit tests but
leaves the view passing a stale field (e.g. `totalQuestions` where `reviewedCount` is now correct) is
incomplete — it will pass its own tests yet ship wrong UI and require an extra out-of-band PR to fix.
For any story that touches both a session/model type and a view that renders it, add an explicit AC:
"The `<ViewName>` displays `<property>` from `<ModelType>.<field>` (not `<stale-field>`)." If a
story only touches the session layer with no view changes, note that explicitly in the spec so the
next story can pick up the wiring.

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
