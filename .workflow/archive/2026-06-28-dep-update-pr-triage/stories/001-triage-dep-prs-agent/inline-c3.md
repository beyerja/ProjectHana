**BLOCKING — Verification GET in step 2h goes through the wrapper; a creds failure on the read is indistinguishable from a failed POST**

Step 2h uses `scripts/gh-review-bot.sh` for the verification GET:
```sh
scripts/gh-review-bot.sh gh api repos/<owner/repo>/commits/$sha/check-runs ...
```

If Keychain credentials are absent, the wrapper exits non-zero on this GET — not just on the POST in 2g. The branch in 2h says "Wrapper exited non-zero → fall to graceful degradation (2i)". So when creds fail on the READ, the agent treats it identically to a failed POST: it posts an "unable to post gate check" comment, adds the PR to the skipped list, and does not merge.

In practice: 2g's POST may have succeeded (the check is already on GitHub), but 2h's GET fails due to absent creds, so the agent skips a PR that has a valid gate check and clean CI. The gate check was posted; the PR should have been merged.

Fix: the verification GET in 2h should use the plain `gh api` command (not the wrapper), since reading check-runs does not require the App's identity:
```sh
gh api repos/<owner/repo>/commits/$sha/check-runs \
  --jq '.check_runs[] | select(.name=="code-owner-review") | {conclusion, app_id: .app.id}'
```
