<!-- independent-review -->

## Independent Review — Round 2

**Verdict: CHANGES_REQUESTED**

Round 1 addressed 4 blocking findings correctly. However, this round surfaces 6 new blocking issues introduced or left unresolved in the fix commit.

### Blocking findings (6)

1. **UNKNOWN retry result not assigned to `$mergeable`** (line 74)
   The retry `gh pr view` call is bare — no `mergeable=$(...)` assignment. The variable retains `UNKNOWN` regardless of what GitHub returns. Valid PRs that resolve within the 10s window are permanently skipped.

2. **Step 2b runs unconditionally, overriding the UNKNOWN skip in 2a** (line 82)
   The "For all dep PRs regardless of mergeable status" heading was added to fix Round 1's MERGEABLE checkout gap. But "regardless of mergeable status" now also includes UNKNOWN-skipped PRs, causing the agent to check out and process a PR it already added to the skipped list. The clause needs an explicit carve-out for PRs skipped in 2a.

3. **No `sleep` before `--watch` after close/reopen** (line 137)
   `gh pr checks --watch --fail-fast` is called immediately after `gh pr reopen`. If CI workflows haven't registered yet, `--watch` exits immediately (zero checks = success). The fallback "no runs within ~30s" is untestable — no sleep, no re-check is specified. CLAUDE.md requires: "do a single `sleep <n>` then one `--watch`." Add `sleep 15` before the `--watch`.

4. **Step 2f's scope excludes the 2d empty-commit push** (line 181)
   Step 2f triggers "after any push in 2c or 2e". The empty-commit push in 2d is in neither. For a MERGEABLE PR where only 2d fires, 2f is skipped, and the gate check in 2g is posted without a confirmed CI wait on the new empty-commit SHA. The 2d `--watch` call also runs against the pre-push SHA. Fix: extend 2f's trigger to include "or 2d", and update `sha` immediately after the 2d push.

5. **Verification GET in step 2h uses the wrapper — creds failure on read is mistaken for a failed POST** (line 203)
   Both the POST (2g) and the verification GET (2h) go through `scripts/gh-review-bot.sh`. If Keychain creds are absent, the wrapper exits non-zero on the GET, triggering graceful degradation (2i) — even if the POST succeeded and the gate check is already on GitHub. The PR is skipped despite having a valid gate check. Fix: use plain `gh api` for the verification read; only the POST needs App credentials.

6. **"Absent for any other reason" skip path in step 2h bypasses cleanup** (line 212)
   When 2h skips due to a non-creds failure, it says "continue to the next PR" without running 2k. The worktree remains on `dep/<n>-work`. The next PR's `original_branch` capture returns `dep/<n>-work`, and after that PR's 2k runs, the feature orchestrator's post-triage `git merge origin/main` targets the wrong branch.

### Non-blocking finding

7. **`commit --allow-empty -m "ci: re-trigger"` is inconsistent with the agent's own commit message rules** (line 142)
   The agent's "Commit message rules" section says "Always write the message to a file... then `git commit -F <file>`." The empty-commit uses inline `-m`. This is a style inconsistency (CLAUDE.md itself only prohibits `$(...)` and heredocs, not plain literals), but fixing it aligns the agent with its own declared conventions.

### What Round 1 fixed correctly

- Step 2b now runs for ALL PRs (MERGEABLE + CONFLICTING), not just CONFLICTING — the core Round 1 finding is resolved.
- Idempotency guard (`branch -D dep/<n>-work 2>/dev/null || true`) is present before checkout.
- `original_branch` is now captured per-PR before checking out. (Note: the step-2h skip path bypasses 2k and leaves the worktree dirty — see finding 6 above.)
- `RUN_TMPDIR=$(mktemp -d)` is used throughout, eliminating the `/tmp` collision risk.
- App id `4144849` hardcoding removed from prose; the agent now defers to the script.
- `feature_orchestrator.md` step renumbering is consistent throughout.

### Round number
Round 2 of 3.
