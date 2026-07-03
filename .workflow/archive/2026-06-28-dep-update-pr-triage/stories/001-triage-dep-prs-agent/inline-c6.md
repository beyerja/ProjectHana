**BLOCKING — Step 2f's scope ("any push in 2c or 2e") excludes the empty-commit push in 2d**

When step 2d pushes an empty commit to re-trigger CI:
```sh
git -C <worktree> commit --allow-empty -m "ci: re-trigger"
git -C <worktree> push origin dep/<number>-work:<headRefName>
```

This changes the head SHA. Step 2f says it runs "after any push that changes the head SHA" in steps 2c or 2e — but the 2d push is in neither. For a MERGEABLE PR where 2c (conflict resolution) and 2e (fix commit) do not push, 2f is skipped. The gate check in 2g is then posted on the new empty-commit SHA without a confirmed CI wait on that SHA.

Step 2d does call `--watch` inline after the empty commit, which partially mitigates this — but if 2d's `--watch` is called on the pre-push SHA (before `sha` is updated), it waits for the wrong SHA. The 2g re-read of `sha` gets the right commit, but by then the CI wait has already finished against a stale reference.

Fix: explicitly include "or 2d" in step 2f's trigger condition, and ensure `sha` is updated immediately after the 2d empty-commit push before calling `--watch`.
