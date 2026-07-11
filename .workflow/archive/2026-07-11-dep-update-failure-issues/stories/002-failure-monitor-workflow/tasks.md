# Tasks — Story 002: failure monitor workflow

Conventions to follow throughout (derived from the repo, not training data):
- Action pinning: copy tag-pinned majors from existing workflows (`actions/checkout@v7`,
  `cachix/install-nix-action@v31` in `lint.yml`; `DeterminateSystems/nix-installer-action@v22`
  in `update-flake-lock.yml`). Do NOT introduce versions not already used in this repo unless
  no existing workflow uses the action at all — and this workflow likely needs no checkout or
  Nix at all (pure `gh` API calls).
- Issue logic style: this repo uses `gh` in `run:` steps with `GH_TOKEN: ${{ github.token }}`
  (see the "Open or update handoff issue" step in `update-flake-lock.yml`) — no
  `actions/github-script` anywhere. Match that; write issue bodies to a file and use
  `--body-file`, never inline heredoc-into-gh-flag payload contortions.
- Only the default `GITHUB_TOKEN`; no external secrets. `permissions:` = exactly
  `issues: write` + `actions: read`.
- PERMISSION BOUNDARY: no repo/org settings mutations (no `gh api -X PUT` on settings
  endpoints) at any point in this story.
- Local agent commands must be allowlist-shaped per CLAUDE.md: `gh -R beyerja/ProjectHana …`,
  `just -f <worktree>/justfile …`, no `cd &&`, no poll loops, Edit/Write for log appends.
- Note: `update-flake-lock.yml` on main no longer creates PRs (handoff-branch + issue model);
  the monitor cares ONLY about run conclusion == failure, nothing about PRs.

## Tasks
- [x] 001: Create the `dep-update-failure` label in the repo (idempotent, run locally with
      user creds): `gh -R beyerja/ProjectHana label create dep-update-failure --description
      "Failed dependency-update automation run" --color D93F0B --force`. Verify with
      `gh -R beyerja/ProjectHana label list --search dep-update-failure`. Record the result in
      the story log (this is repo state, not a commit — note that explicitly).
- [x] 002: Scaffold `.github/workflows/dep-update-failure-monitor.yml`: `name:
      dep-update-failure-monitor`; triggers `workflow_run` (workflows: ["Update flake.lock"],
      types: [completed]), a daily `schedule` cron, and `workflow_dispatch` with an input
      `lookback_days` (default `"7"`, description documenting that post-merge verification
      widens the window to pick up known failed runs 28361869197 and 28313717613, both now
      older than 7 days); `permissions:` block with exactly `issues: write` and
      `actions: read`; a single ubuntu-latest job with a job-level `if:` so the
      `workflow_run`-triggered path proceeds only when
      `github.event.workflow_run.conclusion == 'failure'` while schedule/dispatch always
      proceed (skips cleanly on success/cancelled). Add a header comment block explaining the
      two detection paths and why "Dependabot Updates" needs the sweep (GitHub-internal
      workflow cannot fire `workflow_run` events) — mirroring the documentation style of
      `update-flake-lock.yml`. Keep yamllint happy (`.yamllint`: `on:` truthy allowed,
      line-length 200 warning, document-start disabled).
- [x] 003: Implement the failure-collection step (bash `run:` step, `GH_TOKEN:
      ${{ github.token }}`): on the `workflow_run` event, collect the single triggering run
      (id + html_url) from `github.event.workflow_run`; on schedule/dispatch, sweep the
      Actions API for runs with `status=completed` + `conclusion=failure` created in the last
      N days (N = `inputs.lookback_days` for dispatch, 7 for schedule) of BOTH "Update
      flake.lock" and "Dependabot Updates" — resolve each workflow by name from
      `GET /repos/.../actions/workflows` (the Dependabot one exists there even though it is
      GitHub-internal) and query its runs endpoint with a `created=>=<date>` filter. Emit the
      collected `id url` pairs to a file / step output; when the list is empty, exit the job
      green with no side effects (log "no failed runs"). Filter strictly on
      conclusion == failure (not cancelled/skipped).
- [x] 004: Implement the dedup + open-or-comment step: find the single open issue labeled
      `dep-update-failure` (`gh issue list --state open --label dep-update-failure`, take at
      most one — never create a second open issue); if one exists, fetch its body AND all
      comments and drop every collected run id already mentioned in either; if nothing new
      remains, log "all runs already reported" and exit green (no comment). Otherwise: if no
      open issue exists, create one titled with the `[dep-update-failure]` marker (e.g.
      "[dep-update-failure] Failed dependency-update automation runs"), labeled
      `dep-update-failure`, body (via `--body-file`) listing each new failed run as
      "workflow name — run URL"; if an open issue exists, add a comment listing ONLY the newly
      detected run URLs. Both trigger paths (workflow_run and sweep) must flow through this
      same dedup step so a prompt `workflow_run` report is not duplicated by the next day's
      sweep and vice versa.
- [x] 005: Validate: run `just -f <worktree>/justfile lint` (actionlint semantically checks
      the new workflow; yamllint checks style) and fix all findings. No app code, no Xcode
      build for this story.
- [x] 006: Record the verification plan/deferral in the story log: `workflow_dispatch`
      requires the workflow file on the default branch, so the behavioral dry run is deferred
      to post-merge feature verification. Write down the exact commands for that step:
      `gh -R beyerja/ProjectHana workflow run dep-update-failure-monitor.yml -f
      lookback_days=<N>` with N large enough to cover runs 28361869197 ("Dependabot Updates")
      and 28313717613 ("Update flake.lock"), then a single
      `gh -R beyerja/ProjectHana run watch <run-id>` (no poll loops), then a second dispatch
      to demonstrate dedup (expect: no new comment). Expected outcome: one open issue with
      the `[dep-update-failure]` title marker listing both run URLs.
