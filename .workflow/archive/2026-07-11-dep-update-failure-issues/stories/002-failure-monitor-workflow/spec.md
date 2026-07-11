# Story 002 — failure monitor workflow

## Title
Add the `dep-update-failure-monitor` workflow that opens/appends a deduplicated failure issue

## Goal
Create `.github/workflows/dep-update-failure-monitor.yml` so any future failed run of the
dependency-update automations ("Update flake.lock" workflow, GitHub-internal "Dependabot Updates"
workflow) automatically opens — or comments on — a single open GitHub issue labeled
`dep-update-failure`. Create that label in the repo.

## Context

- "Something like this" = any failed run of the dependency-update automations only
  (Dependabot Updates workflow, Update flake.lock workflow) — not general CI failures.
- The GitHub-internal "Dependabot Updates" workflow **cannot fire `workflow_run` events**, hence
  a daily scheduled sweep over the Actions API is required for it. "Update flake.lock" is a
  normal workflow, so `workflow_run` gives prompt detection there.
- Issue dedup key = the single open issue with label `dep-update-failure` (single rolling issue),
  plus a title marker `[dep-update-failure]`. Per-run dedup: do not re-report a run id already
  mentioned in the issue body/comments.
- Issue creation with `GITHUB_TOKEN` is allowed regardless of the repo's PR-creation setting —
  the workflow only needs `issues: write` + `actions: read` in its `permissions:` block.
- Two known failed runs usable for dry-run verification:
  - 28361869197 ("Dependabot Updates", swift `dependency_file_not_found`)
  - 28313717613 ("Update flake.lock", "GitHub Actions is not permitted to create or approve
    pull requests")

**Command shapes (allowlist-friendly, per CLAUDE.md):**
- Label creation (idempotent): `gh -R beyerja/ProjectHana label create dep-update-failure
  --description "Failed dependency-update automation run" --color D93F0B --force`
- Trigger dry run: `gh -R beyerja/ProjectHana workflow run dep-update-failure-monitor.yml`
  then a single `gh -R beyerja/ProjectHana run watch <run-id>` (no poll loops).
- In-workflow logic should use `actions/github-script` or `gh` with `GH_TOKEN:
  ${{ github.token }}` — no external secrets.

**Scope note:** this story touches only `.github/` (workflow YAML) plus repo label state — no
app code, no Xcode build needed. Local validation = YAML lint; behavioral verification = a
`workflow_dispatch` run on the default branch after merge (or `gh workflow run` against the
story branch if the trigger permits; `workflow_dispatch` requires the workflow file on the
default branch, so final verification may land in feature verification — note this in the
story log if deferred).

## Acceptance Criteria

- [ ] `.github/workflows/dep-update-failure-monitor.yml` exists with triggers:
      `workflow_run` (workflows: ["Update flake.lock"], types: [completed]), a daily
      `schedule`, and `workflow_dispatch`.
- [ ] On a `workflow_run` completion event, the job proceeds only when the triggering run's
      conclusion is `failure` (skips cleanly on success/cancelled).
- [ ] The scheduled sweep (and `workflow_dispatch`) queries the Actions API for runs of the
      last 7 days of **both** "Update flake.lock" and "Dependabot Updates", collecting failed
      run ids + URLs.
- [ ] On detecting one or more failed runs: if no open issue labeled `dep-update-failure`
      exists, create one titled with the `[dep-update-failure]` marker, labeled
      `dep-update-failure`, listing the failed run URLs; otherwise add a comment to the
      existing open issue listing only the newly detected run URLs.
- [ ] Dedup per run id: a run id already mentioned in the open issue's body or comments is
      never re-reported; if all detected failures are already reported, no comment is posted.
- [ ] The workflow's `permissions:` block grants exactly what is needed
      (`issues: write`, `actions: read`) and uses only the default `GITHUB_TOKEN`.
- [ ] The `dep-update-failure` label exists in the repo (idempotent creation).
- [ ] The detection/issue logic is exercised: a `workflow_dispatch` (or equivalent) dry run
      against the two known failed runs (28361869197, 28313717613) demonstrates
      open-or-comment + dedup behavior — or, if those runs have aged past the 7-day window by
      implementation time, an equivalent verification (e.g. temporarily widened window or a
      scripted API-level test of the same logic) is recorded in the story log.
