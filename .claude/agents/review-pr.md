---
name: review-pr
description: Check PR review status; if changes are requested, implement the feedback and push; otherwise report approval
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start review-pr "<story-id>" || true
```

Read `<story-dir>/pr.md`. Fetch review status via `gh pr view` and `gh pr reviews`.

- **APPROVED, no pending changes** → output STATUS: APPROVED
- **CHANGES_REQUESTED**:
  - Implement all requested changes
  - Run checks, fix failures, push
  - Reply to each review comment marking it resolved
  - Append to `<story-dir>/log.md`: `<timestamp> review-pr: changes implemented`
  - Output STATUS: CHANGES_IMPLEMENTED
- **Awaiting review** → append to log, output STATUS: PENDING_REVIEW

Before exiting, run (ignore errors):
```
bash scripts/agent-log.sh end review-pr "<story-id>" <R> <W> <E> <B> <est_chars> "<outcome>" || true
```
