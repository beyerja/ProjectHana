---
name: clarify-feature
description: Engage the user to clarify a feature request and write the finalized spec to .workflow/feature.md
---

**Telemetry — run at the very start (ignore errors):**
```
just log start clarify-feature "feature" || true
```

Read `.workflow/feature.md` if it exists (prior context).

Ask the user targeted questions until requirements are unambiguous. Cover: goal, acceptance criteria, constraints, non-goals. Follow up on vague answers. When the feature adds CI checks, scans, or other per-PR automation, also clarify runtime/throughput cost: which checks may block PR merge vs. run async (scheduled / push-to-default-branch with tracked findings), so slow steps don't gate every PR. Capture the blocking-vs-async split in the spec.

**For bug-fix features, verify the root cause in code before writing the spec.** A plausible hypothesis
(e.g. "wrong coordinates fed to the camera") is not the root cause until you have traced the actual
code path and ruled out alternatives. Read the relevant source files — view initializers, `@State`
defaults, SwiftUI/MapKit lifecycle entry points — and confirm the mechanism before committing it to
`feature.md`. A spec built on the wrong root cause propagates the error into stories and sends
implement-story down a blind path (e.g. adding tests at the model layer for a rendering-layer bug).
State the verified root cause explicitly: the exact symbol, file, and line that is wrong, and *why*
correcting it fixes the symptom.

Write `.workflow/feature.md`:
```
# Feature: <name>
## Goal
## Acceptance Criteria
- [ ] <criterion>
## Constraints
## Out of Scope
```

Run (ignore errors):
```
just log end clarify-feature "feature" <R> <W> 0 <B> <est_chars> "" || true
```

Append to `.workflow/log.md`: `<timestamp> clarify-feature: DONE`.

Output STATUS: DONE.
