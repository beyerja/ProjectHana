---
name: wait-for-ci
description: Wait for all GitHub Actions CI checks to pass on a PR or branch. Exits with STATUS: PASS or STATUS: FAIL.
---

Requires: PR number (or branch name to find the PR from).

**Telemetry — run at the very start (ignore errors):**
```
just log start wait-for-ci "<story-id>" || true
```

Steps:

1. If only a branch name is given, resolve the PR number:
   ```
   gh pr list --head <branch> --json number -q '.[0].number'
   ```

2. Wait for all checks on the PR to complete:
   ```
   export PATH="$HOME/.nix-profile/bin:$PATH"
   gh pr checks <number> --watch --fail-fast
   ```
   This blocks until all checks finish. Exit code 0 = all passed; non-zero = at least one failed or is still pending after timeout.

3. If checks pass: output STATUS: PASS.

4. If checks fail: run `gh pr checks <number>` (without --watch) to get the current check summary, include it in the output, then output STATUS: FAIL.

Notes:
- `gh` is at `~/.nix-profile/bin/gh`; always prepend `export PATH="$HOME/.nix-profile/bin:$PATH"` before `gh` calls.
- For post-merge CI on main: instead of a PR number, use `gh run list --branch main --limit 1 --json databaseId,status -q '.[0]'` to get the latest run, then `gh run watch <id> --exit-status`.

Before exiting, run (ignore errors):
```
just log end wait-for-ci "<story-id>" 0 0 0 <B> 0 "<PASS|FAIL>" || true
```
