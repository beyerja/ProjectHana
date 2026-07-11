# Feature: Fix failing dependency-update automations + self-healing failure loop

Slug: `dep-update-failure-issues`
Repo: `beyerja/ProjectHana`

## User request (verbatim)

"Some dependency updates aren't working (https://github.com/beyerja/ProjectHana/actions/runs/28361869197, https://github.com/beyerja/ProjectHana/actions/runs/28313717613). I want you to fix this. In addition, I want you to implement that whenever something like this happens again, it opens an issue (or comments on a pre-existing open issue). The feature workflow should be adjusted to check for any such issue in the beginning, mark that it will take care of it, and include it in its scope."

## Diagnosed root causes (empirical, from `gh run view --log-failed`)

1. **Run 28361869197 — "Dependabot Updates" (swift ecosystem, weekly):**
   `dependency_file_not_found`: *"Repo must contain a Package.swift configuration file or an
   .xcodeproj/.xcworkspace directory with a Package.resolved file."*
   The repo has **zero SPM dependencies** — no `Package.swift`, no `Package.resolved` anywhere.
   The `swift` entry in `.github/dependabot.yml` was added speculatively ("ready for when packages
   are added") and fails on every weekly run by construction.

2. **Run 28313717613 — "Update flake.lock" (scheduled workflow):**
   `##[error]GitHub Actions is not permitted to create or approve pull requests.`
   `.github/workflows/update-flake-lock.yml` uses `peter-evans/create-pull-request@v8` with
   `secrets.GITHUB_TOKEN`, but the repo Actions setting is
   `can_approve_pull_request_reviews: false` (verified via
   `gh api repos/beyerja/ProjectHana/actions/permissions/workflow`), so PR creation is rejected.

## Scope — three parts

### Part 1: Fix the current failures
- **Dependabot swift:** remove the `swift` package-ecosystem entry from `.github/dependabot.yml`,
  leaving a comment explaining it must be re-added when the project gains its first SPM dependency
  (and that Dependabot requires a `Package.swift` or a `Package.resolved` in the xcodeproj).
  The `github-actions` ecosystem entry stays untouched.
- **Update flake.lock (REVISED after permission-classifier denial):** the original plan (flip
  `can_approve_pull_request_reviews=true` via `gh api -X PUT`) was denied by the auto-mode
  permission classifier as a workspace-level permission change requiring human action. Revised
  design needs no settings change and is strictly better: the workflow drops PR creation entirely —
  on a lock change it force-pushes the update to the well-known branch `automated/update-flake-lock`
  (`contents: write`) and opens/updates a single deduplicated handoff issue labeled
  `flake-lock-update` (`issues: write`; both permitted for `GITHUB_TOKEN` regardless of the PR
  setting). The local triage flow (story 003) opens the PR from that branch with the user's
  credentials — which also makes CI trigger normally (GITHUB_TOKEN-created PRs never trigger
  `pull_request` workflows, so even the setting flip alone would have produced un-CI'd PRs).
  Supply-chain 1-day-delay posture is preserved: nothing auto-merges, Actions still cannot create
  PRs. User follow-ups (optional, final report): flip the setting themselves, or provision the
  GitHub App key as an Actions secret for `actions/create-github-app-token`.
- Verify: re-trigger "Update flake.lock" via `workflow_dispatch` and confirm it succeeds
  (opens a PR or exits green with no changes). Dependabot swift cannot be re-triggered once the
  ecosystem entry is removed — success = the failing job no longer exists; the `github-actions`
  ecosystem check can be triggered from the repo's Dependabot UI is out of CLI scope, so validate
  `dependabot.yml` by schema/lint instead.

### Part 2: Alerting — auto-open/append a GitHub issue on future failures
- New workflow `.github/workflows/dep-update-failure-monitor.yml`:
  - Triggers: `workflow_run` (workflows: ["Update flake.lock"], types: [completed]) for prompt
    detection, plus a daily `schedule` sweep and `workflow_dispatch`.
  - The scheduled sweep queries recent runs (last 7 days) of **both** "Update flake.lock" and the
    GitHub-internal "Dependabot Updates" workflow (which cannot fire `workflow_run` events, hence
    the sweep) via the Actions API.
  - On detecting one or more failed runs: find an open issue labeled `dep-update-failure`;
    if none, create one (title marker: `[dep-update-failure]`), else add a comment listing the
    new failed run URLs. Deduplicate per run id (do not re-report a run id already mentioned in
    the issue body/comments).
  - Token: default `GITHUB_TOKEN` with `issues: write` + `actions: read` permissions (issue
    creation is allowed regardless of the PR-creation setting).
- Create the `dep-update-failure` label in the repo (idempotent).

### Part 3: Feature workflow integration (agents in `.claude/agents/`)
- `feature-orchestrator.md`: add an early step (alongside triage-dep-prs) — check for open issues
  labeled `dep-update-failure`; if found, comment on the issue that this workflow run will take
  care of it, record it in `.workflow/log.md`, and include the fix in the workflow scope (as
  context to clarify/break-stories or as a prepended story).
- `triage-dep-prs.md`: extend to perform that issue check as part of triage: diagnose each
  reported failed run, fix what it can, and close the issue with a summary comment when all
  reported failures are resolved (or leave it open with a status comment if not).
- `triage-dep-prs.md` additionally consumes the flake.lock handoff (see revised Part 1): if the
  branch `automated/update-flake-lock` exists ahead of `main` (and/or an open `flake-lock-update`
  issue exists), open a PR from it with the user's credentials, then treat it as a normal dep PR
  (verify, gate, merge) and close the handoff issue.

## Acceptance criteria

1. `.github/dependabot.yml` no longer contains a `swift` ecosystem entry; a comment explains when
   and how to re-add it. `github-actions` entry unchanged.
2. A `workflow_dispatch` run of "Update flake.lock" completes successfully end-to-end: green run;
   on a lock change it pushes `automated/update-flake-lock` and opens/updates one deduplicated
   `flake-lock-update` handoff issue (no PR creation from Actions; repo setting untouched —
   still `can_approve_pull_request_reviews: false`).
3. A `dep-update-failure-monitor` workflow exists that (a) fires on completion of
   "Update flake.lock", (b) sweeps Dependabot Updates runs on a schedule, and (c) opens or
   comments on a single deduplicated issue labeled `dep-update-failure` when failures are found.
   Its detection/issue logic is exercised (e.g. `workflow_dispatch` dry run against the two known
   failed runs, or equivalent verification).
4. `feature-orchestrator.md` and `triage-dep-prs.md` instruct future runs to check for open
   `dep-update-failure` issues at workflow start, comment "taking care of it", and include the
   fix in scope.
5. The `dep-update-failure` label exists in the repo.

## Assumptions (clarify skipped — non-interactive session)

- Removing the speculative `swift` Dependabot entry is preferred over adding a placeholder
  `Package.resolved` (no SPM deps exist; a placeholder would be misleading).
- Repo settings must not be mutated by agents (enforced by the auto-mode permission classifier
  mid-run); the flake.lock fix therefore uses the branch+handoff-issue design. Flipping
  `can_approve_pull_request_reviews` or provisioning the App key as an Actions secret remain
  optional human follow-ups.
- Issue dedup key = open issue with label `dep-update-failure` (single rolling issue), per the
  user's "comments on a pre-existing open issue ... deduplicated e.g. by a label or title marker".
- "Something like this" = any failed run of the dependency-update automations (Dependabot Updates
  workflow, Update flake.lock workflow) — not general CI failures.
