# 005 — Release runbook docs + proven green dry-run

## Title
`docs/releasing.md` runbook and a green `workflow_dispatch` dry-run of `release.yml`

## Goal
Document the entire release process end-to-end — including the exact "switch-on" steps for when the
Apple Developer account exists — and prove the delivered pipeline by completing a green
`workflow_dispatch` dry-run of `release.yml` on GitHub Actions with no Apple credentials present.
This is the feature's "first proven run" and the human-facing contract for every future release.

## Acceptance Criteria
- [ ] `docs/releasing.md` exists (lowercase, in `docs/`, matching repo docs layout) and documents:
      the versioning scheme (semver `MARKETING_VERSION` + integer `CURRENT_PROJECT_VERSION`,
      `project.yml` as single source of truth, manual edits discouraged), the bump procedure
      (`just bump <major|minor|patch>`), and the tags-only model (annotated `v<semver>` on `main`).
- [ ] It contains the step-by-step release runbook: bump PR (version + CHANGELOG finalization) →
      merge via the normal CI + SHA-bound `code-owner-review` gate → annotated tag → release
      workflow → verify GitHub Release + artifacts (checksums included).
- [ ] It documents each release quality gate and what it protects, and the local equivalents
      (`just release-check`, `just archive`), including the recorded story 003 outcome (unsigned
      device archive vs. Catalyst fallback and the `.ipa` feasibility result).
- [ ] It contains a clearly-marked **"When the Apple Developer account exists"** section listing:
      the exact `DEVELOPMENT_TEAM`/`CODE_SIGN_STYLE` settings to add to `project.yml`, the exact
      secret names to create (App Store Connect API key id, issuer id, `.p8` key content), the repo
      variable to flip (e.g. `APPSTORE_UPLOAD_ENABLED`), the ExportOptions plist to add, and which
      `release.yml` placeholder steps become live (TestFlight upload, App Store submission) — with
      the explicit note that the exact upload tooling (`xcodebuild -exportArchive` + upload vs.
      fastlane) must be re-verified against current Apple tooling at switch-on time, not assumed.
      It also notes that creating secrets is a human action, per project convention.
- [ ] A `workflow_dispatch` dry-run of `release.yml` has completed GREEN on GitHub Actions (on
      `main` or the feature branch), demonstrating the full pipeline (minus Release publication)
      with no Apple credentials present; the run URL is recorded in the story log and PR
      description. A failing dry-run must be fixed, not waived.
- [ ] New Markdown/YAML/shell/Python introduced passes the existing lint gate (yamllint,
      shellcheck, ruff as applicable).

## Constraints (repo-wide, apply to this story)
- Zero changes to per-PR blocking checks (`ci.yml`, `lint.yml`, `secret-scan.yml` untouched).
- Allowlistable command shapes only (no `cd &&`, no heredocs, no `$(…)` payloads, no poll loops);
  wait on the dispatched run with a single blocking `gh run watch` — no hand-rolled poll loops.
- Nix flake/direnv for tooling; no hardcoded /nix paths.
- Merge gate: normal CI + SHA-bound `code-owner-review` status check; nothing may bypass or weaken it.

## Dependencies
- 001–004 (documents and proves everything they delivered).
