---
name: wait-for-ci
description: Wait for all GitHub Actions CI checks to pass on a PR or branch. Exits with STATUS: PASS or STATUS: FAIL.
---

Requires: PR number (or branch name to find the PR from). Optionally a story-id for telemetry — if not provided, derive it from the branch name (e.g. `story/001-foo` → `001-foo`) or use `"unknown"`.

**Telemetry — run at the very start (ignore errors):**
```
just log start wait-for-ci "<story-id>" || true
```
(`<story-id>` = last path component of the story directory, e.g. `001-l10n-infrastructure`; use "unknown" only if truly unavailable)

Steps:

1. If only a branch name is given, resolve the PR number:
   ```
   gh pr list --head <branch> --json number -q '.[0].number'
   ```

2. Wait for all checks on the PR to complete:
   ```
   gh pr checks <number> --watch --fail-fast
   ```
   This blocks until all checks finish. Exit code 0 = all passed; non-zero = at least one failed or is still pending after timeout.

3. If checks pass: output STATUS: PASS.

4. If checks fail: run `gh pr checks <number>` (without --watch) to get the current check summary, include it in the output, then output STATUS: FAIL.

Notes:
- For post-merge CI on main: instead of a PR number, use `gh run list --branch main --limit 1 --json databaseId,status -q '.[0]'` to get the latest run, then `gh run watch <id> --exit-status`.

Before exiting, run (ignore errors):
```
just log end wait-for-ci "<story-id>" 0 0 0 <B> 0 "<PASS|FAIL>" || true
```
