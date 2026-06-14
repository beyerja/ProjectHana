# Story 004 — CodeQL: schedule + push-to-main only (drop per-PR trigger)

## Goal

Amend the merged `.github/workflows/codeql.yml` so CodeQL no longer runs on `pull_request`.
On this Swift project CodeQL takes >20 min, so gating every PR on it kills throughput.
CodeQL must run on a weekly `schedule` and on `push` to `main` only; its findings surface as
GitHub code-scanning alerts in the Security tab and are tracked/addressed over time, without
blocking PR merge.

This corrects the policy that story 001 (PR #65, already merged) shipped, where CodeQL ran on
`pull_request` to `main`.

## Acceptance Criteria

- [ ] `.github/workflows/codeql.yml` no longer has a `pull_request` trigger.
- [ ] It retains the weekly `schedule` (cron) trigger and the `push` to `main` trigger.
- [ ] Everything else (macos-15 runner, swift language, xcodebuild build step, v4 action
      pins, `security-events: write`, Security-tab upload) is unchanged.
- [ ] A short comment in the workflow explains WHY there is no PR trigger (>20 min; tracked
      via Security-tab alerts instead of blocking PRs).
- [ ] Valid YAML; no hardcoded `/nix/...` paths.

## Notes

- Touches only `.github/workflows/codeql.yml`. No Swift source changes.
- Verified-once at authoring: leaving only `push`/`schedule` means CodeQL still produces a
  fresh baseline on the default branch and on a weekly cadence; PRs are never gated on it.
