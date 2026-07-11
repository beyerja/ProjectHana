# 004 — Release CI workflow

## Title
`.github/workflows/release.yml`: gated, unsigned, artifact-producing release pipeline

## Goal
Deliver the tag-triggered release workflow that enforces the full quality bar, produces unsigned
inspectable artifacts with checksums, publishes a GitHub Release, and carries the cleanly-skipped
signing/upload placeholders. This story completes ALL fan-out wiring it promises: every gate, every
artifact step, and both placeholder steps are present and functional (skip-with-message counts as
functional for placeholders) — no step may be left as a TODO for a later story. The archive/ipa
commands are the ones empirically proven in story 003 (including the Catalyst fallback if that was
the recorded outcome).

## Acceptance Criteria
- [ ] `.github/workflows/release.yml` exists, triggers on `v*` tag push AND `workflow_dispatch`
      with a `dry_run` input; it has NO `pull_request` trigger. Dry-run performs everything except
      tag-consistency enforcement and Release creation/publication.
- [ ] The workflow enforces in order, each failing the run on violation:
      (a) tag↔`project.yml` version match (skipped in dry-run), (b) `CHANGELOG.md` section present
      for the version, (c) full lint suite, (d) xcodegen generate + full `xcodebuild test`
      (Mac Catalyst, as ci.yml does), (e) `generate-geo-packs.py --check`, (f) `verify-odr-packs.sh`,
      (g) Release-config build + `verify-base-only-bundle.sh`. Gates (a)/(b) reuse the story 002
      scripts.
- [ ] The workflow produces an unsigned Release-configuration `.xcarchive` (zipped) plus, if story
      003 proved it feasible without signing, an unsigned `.ipa`, each with SHA-256 checksums in a
      checksum file.
- [ ] For real tags, a GitHub Release is created with auto-generated notes (`generate_release_notes`)
      PLUS the CHANGELOG section body, with the zipped `.xcarchive`, `.ipa` (if feasible), and
      checksum file attached; prerelease-suffixed tags (e.g. `v1.1.0-rc.1`) are marked prerelease.
- [ ] App Store Connect / TestFlight upload steps exist as clearly-labeled placeholders gated on a
      repo variable (e.g. `vars.APPSTORE_UPLOAD_ENABLED == 'true'`) AND presence of the API-key
      secrets; with no account configured they SKIP with an explanatory log line and the workflow
      still succeeds end-to-end. Nothing in the workflow requires signing or Apple credentials.
- [ ] Runner is macos-15, mirroring existing workflow patterns; Nix/flake for lint tools as in
      lint.yml; permissions minimal (`contents: write` only where the Release is created);
      concurrency group per ref.
- [ ] The workflow YAML passes the repo's yamllint gate; any new shell passes shellcheck, new
      Python passes ruff.
- [ ] GitHub Action versions match majors verified against the repo's existing pins and/or current
      marketplace majors at implementation time — recorded in the PR description, NOT assumed from
      training data. (Known in-repo majors at spec time: checkout @v6/@v7, cachix/install-nix-action
      @v31, github/codeql-action @v4, dorny/paths-filter @v4 — re-verify.)
- [ ] No changes to the per-PR blocking check set: `ci.yml`, `lint.yml`, `secret-scan.yml`
      triggers/required checks untouched; all new automation runs only on tag push or
      `workflow_dispatch`.

## Constraints (repo-wide, apply to this story)
- Allowlistable command shapes only (no `cd &&`, no heredocs, no `$(…)` payloads, no poll loops)
  in any locally-run commands; workflow steps follow existing workflow style.
- Nix flake/direnv for tooling; no hardcoded /nix paths.
- Merge gate: normal CI + SHA-bound `code-owner-review` status check; nothing may bypass or weaken it.

## Dependencies
- 002 (check scripts), 003 (empirically proven archive/ipa commands and fallback decision).
