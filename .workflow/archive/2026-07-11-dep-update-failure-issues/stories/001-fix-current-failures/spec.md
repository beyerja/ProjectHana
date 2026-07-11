# Story 001 — fix current failures

## Title
Fix the two failing dependency-update automations (Dependabot swift + Update flake.lock)

## Goal
Make both currently-failing dependency-update automations green: remove the by-construction-failing
`swift` ecosystem entry from `.github/dependabot.yml`, and restructure the scheduled
"Update flake.lock" workflow so it no longer needs PR-creation permission at all — it pushes the
update to a well-known branch and files a handoff issue; the local triage flow opens the PR with
the user's credentials.

## Context (root causes, empirically diagnosed via `gh run view --log-failed`)

1. **Run 28361869197 — "Dependabot Updates" (swift ecosystem, weekly):**
   `dependency_file_not_found`: *"Repo must contain a Package.swift configuration file or an
   .xcodeproj/.xcworkspace directory with a Package.resolved file."*
   The repo has **zero SPM dependencies** — no `Package.swift`, no `Package.resolved` anywhere.
   The `swift` entry in `.github/dependabot.yml` was added speculatively and fails on every
   weekly run by construction.

2. **Run 28313717613 — "Update flake.lock" (scheduled workflow):**
   `##[error]GitHub Actions is not permitted to create or approve pull requests.`
   `.github/workflows/update-flake-lock.yml` uses `peter-evans/create-pull-request@v8` with
   `secrets.GITHUB_TOKEN`, but the repo Actions setting is
   `can_approve_pull_request_reviews: false` (verified via
   `gh api repos/beyerja/ProjectHana/actions/permissions/workflow`), so PR creation is rejected.

**PERMISSION BOUNDARY (binding for this story):** flipping the repo setting
(`gh api -X PUT repos/beyerja/ProjectHana/actions/permissions/workflow
-F can_approve_pull_request_reviews=true`) was **DENIED by the auto-mode permission classifier**
as a workspace-level permission change requiring human action. Do **NOT** attempt it or any other
repo-settings mutation. The fix below is designed to not need it — and it is the better design
anyway: it preserves the repo's hardened posture (Actions cannot create PRs) and sidesteps the
known limitation that `GITHUB_TOKEN`-created PRs never trigger `pull_request` CI. The optional
setting flip remains available to the **user** as a one-command alternative, noted in the final
report only.

**New "Update flake.lock" design (branch + handoff issue, no PR from Actions):**
- `permissions:` becomes `contents: write` + `issues: write` (drop `pull-requests: write`;
  remove the `peter-evans/create-pull-request` step entirely).
- Steps: checkout → install Nix → `nix flake update` → if `flake.lock` changed:
  1. commit the change and force-push it to the well-known branch `automated/update-flake-lock`
     (force keeps the branch fresh relative to current `main`; branch push with
     `contents: write` is permitted);
  2. open **or update** a handoff issue: single open issue labeled `flake-lock-update`
     (title marker `[flake-lock-update]`), created idempotently — if one is already open,
     add a comment pointing at the new run instead of opening a duplicate. Body must state:
     the branch name, the run URL, and that the local triage flow (triage-dep-prs) opens the
     PR from this branch with user credentials, reviews, and merges it (supply-chain 1-day
     delay preserved: nothing auto-merges).
  - if `flake.lock` did NOT change: exit green, no branch push, no issue.
- Ensure the `flake-lock-update` label exists (create idempotently via `gh label create ... ||
  true` from the local session, not in the workflow, or in-workflow with `--force`-style
  idempotency).
- Keep the existing supply-chain comments; update them to describe the new flow. Document in a
  comment WHY Actions does not open the PR (setting deliberately off; GITHUB_TOKEN PRs would not
  trigger CI; local triage PRs do).
- Consuming the handoff (teaching triage-dep-prs to open the PR) is **story 003's** scope; this
  story only produces the branch + issue mechanics.

**Command shapes (allowlist-friendly, per CLAUDE.md):**
- Trigger verification: `gh -R beyerja/ProjectHana workflow run update-flake-lock.yml` then
  `gh -R beyerja/ProjectHana run watch <run-id>` (single watch, no poll loops; a single
  `sleep 10` before listing runs is fine)
- Inspect result: `gh -R beyerja/ProjectHana run list --workflow=update-flake-lock.yml --limit 3`

**Scope note:** this story touches only `.github/` config — no app code, no Xcode build, and
**no repo API settings**. `just lint` (actionlint + schema checks from story 000) validates
locally; end verification is a live `workflow_dispatch` run after merge.

## Acceptance Criteria

- [ ] `.github/dependabot.yml` no longer contains a `swift` package-ecosystem entry.
- [ ] A comment in `.github/dependabot.yml` explains when and how to re-add the `swift` entry:
      re-add once the project gains its first SPM dependency, and Dependabot requires a
      `Package.swift` or a `Package.resolved` inside the `.xcodeproj`/`.xcworkspace`.
- [ ] The `github-actions` ecosystem entry in `.github/dependabot.yml` is unchanged.
- [ ] `.github/dependabot.yml` still parses as valid YAML (schema/lint check — Dependabot's
      `github-actions` run cannot be triggered from the CLI, so validation is by lint).
- [ ] `.github/workflows/update-flake-lock.yml` no longer uses `peter-evans/create-pull-request`
      or any PR-creation API; its `permissions:` block is exactly `contents: write` +
      `issues: write`; no repo setting was changed (verify
      `gh api repos/beyerja/ProjectHana/actions/permissions/workflow` still returns
      `can_approve_pull_request_reviews: false`).
- [ ] On a lock change the workflow force-pushes `automated/update-flake-lock` and opens or
      comments on a single open issue labeled `flake-lock-update` (dedup: never a second open
      issue with that label); on no change it exits green with no side effects.
- [ ] The `flake-lock-update` label exists in the repo.
- [ ] Comments in the workflow file explain the handoff design and why Actions does not open
      the PR itself (setting off by policy; GITHUB_TOKEN PRs would not trigger CI; the local
      triage flow opens the PR with user credentials).
- [ ] `just lint` passes (actionlint + dependabot schema validation from story 000).
- [ ] A post-merge `workflow_dispatch` run of "Update flake.lock" completes successfully
      end-to-end (branch + issue produced if the lock changed, or clean green no-op). Any
      produced branch/issue is left for the triage flow (story 003) — this story does not open
      or merge a PR from it.
