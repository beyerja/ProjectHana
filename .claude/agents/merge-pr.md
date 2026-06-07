---
name: merge-pr
description: Merge an approved PR via squash merge and clean up the story branch
---

Requires: story directory path.

Read `<story-dir>/pr.md`. Confirm PR is approved and all CI checks pass.

Run: `gh pr merge --squash --delete-branch`

Update `<story-dir>/status.md` to `status: merged`.
Append to `<story-dir>/log.md`: `<timestamp> merge-pr: DONE`.

Output STATUS: DONE.
