---
name: clarify-feature
description: Engage the user to clarify a feature request and write the finalized spec to .workflow/feature.md
---

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start clarify-feature "feature" || true
```

Read `.workflow/feature.md` if it exists (prior context).

Ask the user targeted questions until requirements are unambiguous. Cover: goal, acceptance criteria, constraints, non-goals. Follow up on vague answers.

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
bash scripts/agent-log.sh end clarify-feature "feature" <R> <W> 0 <B> <est_chars> "" || true
```

Append to `.workflow/log.md`: `<timestamp> clarify-feature: DONE`.

Output STATUS: DONE.
