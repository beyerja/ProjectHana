**BLOCKING — UNKNOWN retry result not assigned back to `$mergeable`**

The retry fetch command is issued bare with no assignment:
```sh
gh -R <owner/repo> pr view <number> --json mergeable --jq .mergeable
```

`$mergeable` still holds `UNKNOWN` after this runs, even if GitHub has resolved mergeability. The subsequent check "if still UNKNOWN after retry → skip" always fires on a PR that became `MERGEABLE` in those 10 seconds, causing valid PRs to be permanently skipped.

Fix:
```sh
mergeable=$(gh -R <owner/repo> pr view <number> --json mergeable --jq .mergeable)
```
