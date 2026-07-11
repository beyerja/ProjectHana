# Tasks — Fix the two failing dependency-update automations

Story: 001-fix-current-failures
Scope: `.github/` config only — no app code, no Xcode build, and **no repo/org settings
mutations** (any `gh api -X PUT …/settings|permissions` is explicitly denied; do not attempt).

## Tasks

- [x] 001: Remove the `swift` package-ecosystem entry from `.github/dependabot.yml`
      (lines 18–31: the entire second `updates:` list item including its lead-in comment).
      Replace it with a comment block explaining when/how to re-add it: re-add a `swift`
      entry once the project gains its first SPM dependency — Dependabot's swift ecosystem
      requires a `Package.swift` at the configured directory, or a `Package.resolved` inside
      an `.xcodeproj`/`.xcworkspace`; today the repo has neither, so the entry fails every
      weekly run with `dependency_file_not_found`. The `github-actions` entry (lines 1–16)
      must remain **byte-identical** — do not reflow, re-indent, or re-quote it.

- [x] 002: Restructure `.github/workflows/update-flake-lock.yml` — drop PR creation, keep
      checkout/Nix/update. Change `permissions:` to exactly `contents: write` +
      `issues: write` (remove `pull-requests: write`). Delete the
      `peter-evans/create-pull-request@v8` step entirely. Keep the existing
      `actions/checkout@v7`, `DeterminateSystems/nix-installer-action@v22`, and
      `nix flake update` steps. Add a detection step that sets an output when `flake.lock`
      changed (e.g. `git status --porcelain flake.lock`), so later steps are `if:`-gated and
      the workflow exits green with **no side effects** when nothing changed.

- [x] 003: In the same workflow, add the "on lock change" branch-push step: configure the
      Actions bot git identity, commit `flake.lock` with message
      `chore(nix): update flake.lock`, and **force-push** to the well-known branch
      `automated/update-flake-lock` (force keeps the branch fresh relative to current `main`;
      branch push is allowed under `contents: write`). Step runs only when the detection
      output from 002 says the lock changed.

- [x] 004: In the same workflow, add the "on lock change" handoff-issue step using
      `gh` with `GH_TOKEN: ${{ github.token }}` (issue creation via `issues: write` is
      permitted — only PR creation is blocked). Dedup logic: search for a single **open**
      issue labeled `flake-lock-update` (title marker `[flake-lock-update]`); if one exists,
      add a comment pointing at the new run URL; otherwise create the issue. Body must state:
      the branch name `automated/update-flake-lock`, the run URL
      (`${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}`),
      and that the local triage flow (triage-dep-prs, story 003) opens the PR from this
      branch with user credentials, reviews, and merges it — nothing auto-merges, preserving
      the 1-day supply-chain delay. Never produce a second open issue with that label.

- [x] 005: In the same workflow, update the comments: keep/adapt the existing supply-chain
      cadence comment for the new flow, and add a comment block explaining WHY Actions does
      not open the PR itself: (a) the repo setting
      `can_approve_pull_request_reviews: false` deliberately blocks Actions from creating
      PRs (hardened posture, intentionally not flipped); (b) even if allowed,
      `GITHUB_TOKEN`-created PRs never trigger `pull_request` CI; (c) the local triage flow
      opens the PR with user credentials, which does trigger CI.

- [x] 006: Create the `flake-lock-update` label idempotently from the **local session**
      (not in-workflow):
      `gh -R beyerja/ProjectHana label create flake-lock-update --description "Handoff issue from the Update flake.lock workflow" --color 1D76DB || true`.
      Verify it exists with `gh -R beyerja/ProjectHana label list --search flake-lock-update`.

- [x] 007: Validate: run
      `just -f /Users/Private/Documents/Code/ProjectHana-worktrees/dep-update-failure-issues/justfile lint`
      (actionlint + dependabot schema + yaml checks) and confirm it passes. Also grep-confirm
      no `peter-evans/create-pull-request` or `pull-requests:` reference remains in
      `.github/workflows/update-flake-lock.yml`, and no `package-ecosystem: "swift"` remains
      in `.github/dependabot.yml`.

## Out of scope (handled elsewhere)

- Post-merge `workflow_dispatch` end-to-end run — verify step, not an implementation task.
- Teaching triage-dep-prs to consume the branch + issue — story 003.
- Any repo settings mutation (`gh api -X PUT …`) — permission-denied by policy; the optional
  setting flip is a user action noted in the final report only.
