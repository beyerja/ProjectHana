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

**If the PR is BEHIND base, update it first.** With parallel worktrees advancing `main`, a PR that
was green can fall behind base between CI-pass and merge; branch protection's "require branches up to
date" then blocks the squash. This is a clean fast-forward, NOT a conflict — do not re-integrate by
hand. Check and update:
```sh
gh pr view <number> --json mergeStateStatus -q .mergeStateStatus
# BEHIND  → gh pr update-branch <number>   (then re-wait for CI on the updated branch)
# DIRTY   → real conflict: re-integrate origin/main into the branch and resolve (see create-pr / orchestrator step 5)
# CLEAN/HAS_HOOKS/BLOCKED-by-nothing-else → proceed to merge
```

Run: `gh pr merge --squash --delete-branch`

Sync to the merged main. **Worktree-aware:** in a dedicated feature worktree, do NOT
`git checkout main` (main belongs to the primary worktree). Just fetch:
```sh
git fetch origin main
# Primary checkout only — switch to main and fast-forward:
if [ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || ! git worktree list --porcelain | grep -q "^worktree $(pwd -P)$"; then
    git checkout main && git pull
fi
```

Update `<story-dir>/status.md` to `status: merged`.
Run (ignore errors):
```
just log end merge-pr "<story-id>" <R> 0 0 <B> 0 "" || true
```
Append to `<story-dir>/log.md`: `<timestamp> merge-pr: DONE`.

If any *tracked* workflow files are now dirty (check with `git status`), commit them to main via a
cleanup branch. (Note: with story 001 the `.workflow/` live working set is gitignored, so usually only
`.workflow/archive/` or agent/script/config files will be dirty.) Namespace the chore branch by the
shared feature slug so parallel features don't collide:
```sh
slug="${HANA_FEATURE_SLUG:-}"
chore_branch="chore/${slug:+$slug/}workflow-post-merge-<story-id>"
git checkout -b "$chore_branch"
git add -A .workflow
git commit -m "chore(workflow): record merge of <story-id>"   # single-line is fine; for a multi-line
                                                              # body write a file + `git commit -F`,
                                                              # never a heredoc (see CLAUDE.md)
git push -u origin "$chore_branch"
gh pr merge --squash --delete-branch --auto
```
Wait for the auto-merge to complete, then pull main again.

Output STATUS: DONE.
