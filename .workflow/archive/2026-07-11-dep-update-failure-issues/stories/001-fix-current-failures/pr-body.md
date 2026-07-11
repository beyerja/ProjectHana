## Goal

Make both currently-failing dependency-update automations green:

1. **Dependabot `swift` ecosystem** fails on every weekly run with `dependency_file_not_found` — the repo has zero SPM dependencies (no `Package.swift`, no `Package.resolved`), so the entry fails by construction.
2. **"Update flake.lock"** fails with `GitHub Actions is not permitted to create or approve pull requests` — the repo Actions setting `can_approve_pull_request_reviews` is deliberately `false`, so `peter-evans/create-pull-request` is rejected on every scheduled run.

## Changes

- **`.github/dependabot.yml`**
  - Remove the by-construction-failing `swift` package-ecosystem entry.
  - Add a comment explaining when/how to re-add it: once the project gains its first SPM dependency (Dependabot requires a `Package.swift` or a `Package.resolved` inside the `.xcodeproj`/`.xcworkspace`).
  - `github-actions` ecosystem entry unchanged.
- **`.github/workflows/update-flake-lock.yml`** — restructure to a branch-push + handoff-issue design that needs no PR-creation permission at all:
  - Drop `peter-evans/create-pull-request` entirely; `permissions:` is now exactly `contents: write` + `issues: write` (no `pull-requests: write`).
  - On a lock change: commit and force-push to the well-known branch `automated/update-flake-lock`, then open **or update** a single deduplicated handoff issue labeled `flake-lock-update` (comment on the existing open issue instead of filing a duplicate).
  - On no change: exit green with no side effects.
  - Comments document why Actions does not open the PR itself: the repo setting is off by policy (hardened posture preserved), and `GITHUB_TOKEN`-created PRs would never trigger `pull_request` CI anyway — the local triage flow opens the PR with user credentials instead (story 003 consumes the handoff).
  - No repo API settings were changed.

## Test plan

- [ ] `just lint` passes (actionlint + dependabot schema validation)
- [ ] `.github/dependabot.yml` parses as valid YAML and contains no `swift` entry
- [ ] `permissions:` block of `update-flake-lock.yml` is exactly `contents: write` + `issues: write`, no PR-creation API anywhere
- [ ] `gh api repos/beyerja/ProjectHana/actions/permissions/workflow` still returns `can_approve_pull_request_reviews: false`
- [ ] Post-merge: `workflow_dispatch` run of "Update flake.lock" completes green end-to-end (branch + deduplicated issue on lock change, clean no-op otherwise)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
