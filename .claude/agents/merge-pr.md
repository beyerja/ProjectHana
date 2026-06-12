---
name: merge-pr
description: Merge an approved PR via squash merge and clean up the story branch
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
just log start merge-pr "<story-id>" || true
```

Read `<story-dir>/pr.md`. Confirm PR is approved and all CI checks pass.

Run: `gh pr merge --squash --delete-branch`

Update `<story-dir>/status.md` to `status: merged`.
Run (ignore errors):
```
just log end merge-pr "<story-id>" <R> 0 0 <B> 0 "" || true
```
Append to `<story-dir>/log.md`: `<timestamp> merge-pr: DONE`.

Output STATUS: DONE.
