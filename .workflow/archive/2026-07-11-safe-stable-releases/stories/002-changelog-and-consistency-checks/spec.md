# 002 — CHANGELOG + version/changelog consistency checks

## Title
Keep-a-Changelog `CHANGELOG.md` plus scripted changelog/version consistency checks

## Goal
Seed a root `CHANGELOG.md` in Keep-a-Changelog style and deliver the committed check scripts that
later gate releases: one that verifies `CHANGELOG.md` has a section for a given version and one that
verifies a `v*` tag matches `MARKETING_VERSION` in `project.yml`. These scripts are the reusable
gates consumed by `just release-check` (story 003) and `release.yml` (story 004) — this story must
fully deliver them as standalone, runnable, tested scripts, not stubs, so downstream stories only
wire them in.

## Acceptance Criteria
- [ ] `CHANGELOG.md` exists at the repo root in Keep-a-Changelog format with an `[Unreleased]`
      section and a seeded brief summary of the current (pre-release) state.
- [ ] The release procedure convention is documented in a short comment/header: `[Unreleased]`
      content moves under the new version heading as part of the version-bump PR (full runbook in
      story 005).
- [ ] A committed script (e.g. `scripts/check-changelog.sh`) exits non-zero with a clear message
      when `CHANGELOG.md` has no section for the version under check, and zero when it does; the
      version under check can be passed explicitly or derived from `project.yml`.
- [ ] A committed script (or a mode of the same script) verifies tag↔version consistency: given a
      tag `vX.Y.Z`, fail unless it equals `v` + `MARKETING_VERSION` from `project.yml`; supports
      prerelease-suffixed tags (e.g. `v1.1.0-rc.1`) per the semver convention.
- [ ] Both checks are demonstrated working (positive and negative case) in the story verification —
      no XCTSkip-style degradation; a failing check must actually fail.
- [ ] New shell passes shellcheck / new Python passes ruff / new YAML passes yamllint; the existing
      lint gate stays green.

## Constraints (repo-wide, apply to this story)
- Zero changes to per-PR blocking checks (`ci.yml`, `lint.yml`, `secret-scan.yml` untouched); no
  new blocking check is added for changelog enforcement — it runs only at release time.
- Allowlistable command shapes only (no `cd &&`, no heredocs, no `$(…)` payloads, no poll loops).
- Nix flake/direnv for tooling; no hardcoded /nix paths.
- Merge gate: normal CI + SHA-bound `code-owner-review` status check; nothing may bypass or weaken it.

## Dependencies
- 001 (semver-normalized `MARKETING_VERSION` in `project.yml`).
