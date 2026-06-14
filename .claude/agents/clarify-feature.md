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
