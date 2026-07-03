**BLOCKING — "Absent for any other reason" skip path in step 2h bypasses cleanup (step 2k)**

When step 2h determines the gate check is absent for a reason other than creds failure, it says:
> "do NOT merge. Append the failure verbatim to `.workflow/log.md`, add the PR to the skipped list, and continue to the next PR."

This jumps directly past steps 2j and 2k. Step 2k is the only place that runs:
```sh
git -C <worktree> checkout $original_branch
git -C <worktree> branch -D dep/<number>-work 2>/dev/null || true
```

Without cleanup, the worktree remains checked out on `dep/<number>-work`. The next iteration of the loop then captures `original_branch=$(git -C <worktree> rev-parse --abbrev-ref HEAD)` — which returns `dep/<prev-number>-work` instead of the feature branch. Every subsequent PR's cleanup will restore to the wrong branch, and the feature orchestrator's post-triage `git merge origin/main` targets a dep branch instead of the feature branch.

Fix: add the cleanup commands (or a "Go to cleanup" reference) on every skip/abort path, including the 2h "absent for other reason" path.
