## Goal

Automatically surface failed dependency-update automation runs ("Update flake.lock" workflow and the GitHub-internal "Dependabot Updates" workflow) as a single rolling GitHub issue labeled `dep-update-failure`, so failures no longer go unnoticed.

## Changes

- New `.github/workflows/dep-update-failure-monitor.yml`:
  - **Triggers:** `workflow_run` on "Update flake.lock" (`types: [completed]`, proceeds only on `conclusion: failure`), a daily `schedule` sweep, and `workflow_dispatch` with a `lookback_days` input (default 7) for verification.
  - **Daily API sweep** covers "Dependabot Updates" as well, since GitHub-internal workflows cannot fire `workflow_run` events.
  - **Single rolling issue:** if no open issue labeled `dep-update-failure` exists, one is created with the `[dep-update-failure]` title marker; otherwise newly detected failures are appended as a comment.
  - **Per-run-id dedup:** run ids already mentioned in the issue body or comments are never re-reported; if nothing new is found, no comment is posted.
  - **Permissions:** exactly `issues: write` + `actions: read`, using only the default `GITHUB_TOKEN` (no external secrets).
- Repo label `dep-update-failure` created idempotently (`gh label create --force`).

## Test plan

- [x] YAML lint passes on the new workflow file.
- [ ] After merge to `main`, trigger `gh -R beyerja/ProjectHana workflow run dep-update-failure-monitor.yml` (with `lookback_days` widened if the known failed runs 28361869197 / 28313717613 have aged out) and confirm the issue is opened with the failed run URLs.
- [ ] Re-run the dispatch and confirm dedup: no duplicate comment for already-reported run ids.
- [ ] Confirm a successful "Update flake.lock" run skips the job cleanly (no issue activity).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
