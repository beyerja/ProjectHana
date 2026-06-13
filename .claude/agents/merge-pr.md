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

Pull main to sync: `git checkout main && git pull`

Update `<story-dir>/status.md` to `status: merged`.
Run (ignore errors):
```
just log end merge-pr "<story-id>" <R> 0 0 <B> 0 "" || true
```
Append to `<story-dir>/log.md`: `<timestamp> merge-pr: DONE`.

If any workflow files are now dirty (check with `git status`), commit them to main via a cleanup branch:
```sh
git checkout -b chore/workflow-post-merge-<story-id>
git add .workflow/
git commit -m "chore(workflow): record merge of <story-id>"
git push -u origin chore/workflow-post-merge-<story-id>
gh pr merge --squash --delete-branch --auto
```
Wait for the auto-merge to complete, then pull main again.

Output STATUS: DONE.
