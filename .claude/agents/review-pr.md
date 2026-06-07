---
name: review-pr
description: Check PR review status; if changes are requested, implement the feedback and push; otherwise report approval
---

Requires: story directory path.

Read `<story-dir>/pr.md`. Fetch review status via `gh pr view` and `gh pr reviews`.

- **APPROVED, no pending changes** → output STATUS: APPROVED
- **CHANGES_REQUESTED**:
  - Implement all requested changes
  - Run checks, fix failures, push
  - Reply to each review comment marking it resolved
  - Append to `<story-dir>/log.md`: `<timestamp> review-pr: changes implemented`
  - Output STATUS: CHANGES_IMPLEMENTED
- **Awaiting review** → append to log, output STATUS: PENDING_REVIEW
