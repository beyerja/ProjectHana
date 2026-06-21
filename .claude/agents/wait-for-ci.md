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

   **Do not hand-roll a registration poll loop** (`for i in $(seq …); do gh pr checks …; done`) — loops
   are always prompted (see CLAUDE.md → "Emit allowlistable command shapes"). `--watch` already blocks
   on pending checks. The only race is checks not yet *registered* right after a push, in which case
   `--watch` returns immediately with none found: handle that with a single `sleep 15` then one more
   `gh pr checks <number> --watch --fail-fast`, not a loop.

   **If no checks are found** (e.g. the PR only modifies files outside CI path filters such as `.claude/` or `.workflow/`), `gh pr checks` will report nothing. Treat this as STATUS: PASS — no CI path triggered.

   **A SKIPPED check is a PASS, not an incomplete run.** A path-filtered job (e.g. `Build & Test`
   skipped because the PR has no build-relevant Swift delta) reports state `SKIPPED`/`NEUTRAL`;
   `--watch` exits 0 and that is correct — do NOT treat a skipped expected check as "CI didn't finish"
   and re-push or wait. Only an actual `FAILURE`/`TIMED_OUT`/`CANCELLED` is a fail.

3. If checks pass: output STATUS: PASS.

4. If checks fail: run `gh pr checks <number>` (without --watch) to get the current check summary, include it in the output, then output STATUS: FAIL.

Notes:
- For post-merge CI on main: instead of a PR number, use `gh run list --branch main --limit 1 --json databaseId,status -q '.[0]'` to get the latest run, then `gh run watch <id> --exit-status`.

Before exiting, run (ignore errors):
```
just log end wait-for-ci "<story-id>" 0 0 0 <B> 0 "<PASS|FAIL>" || true
```
