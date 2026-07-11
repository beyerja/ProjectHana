# 001 — Versioning scheme + bump tooling

## Title
Deterministic semver versioning with a scripted `just bump` procedure

## Goal
Establish `project.yml` as the single source of truth for the app version (`MARKETING_VERSION`,
semver `X.Y.Z`) and build number (`CURRENT_PROJECT_VERSION`, monotonically increasing integer), with
a committed bump script and `just bump <major|minor|patch>` recipe that updates both values and
regenerates the Xcode project. This is the foundation every later release story (changelog checks,
tag-consistency gate, release workflow) builds on.

## Acceptance Criteria
- [ ] `project.yml` remains the single source of truth for `MARKETING_VERSION` (semver) and
      `CURRENT_PROJECT_VERSION` (integer build number); no version value is introduced anywhere else.
- [ ] `MARKETING_VERSION` is normalized to three-component semver (`1.0` → `1.0.0`) as part of this
      story, per feature Assumption 2.
- [ ] A committed bump script (`scripts/bump-version.sh` or `.py`) exposed as
      `just bump <major|minor|patch>` updates BOTH values (semver part bumped, build number
      incremented by 1), regenerates the Xcode project (`just generate` / xcodegen), and is
      idempotent/validated: it rejects non-semver current values and invalid part arguments with a
      clear error and non-zero exit.
- [ ] Running `just bump patch` produces a clean, reviewable diff touching only `project.yml` (and
      any regenerated project output the repo already commits, if applicable).
- [ ] The versioning/tagging convention is stated in the script header or a short comment: annotated
      `v<MAJOR>.<MINOR>.<PATCH>` tags on `main` only; manual edits to the version fields are
      documented as discouraged (full runbook lands in story 005).
- [ ] New shell passes shellcheck / new Python passes ruff; the existing lint gate stays green.

## Constraints (repo-wide, apply to this story)
- Zero changes to per-PR blocking checks (`ci.yml`, `lint.yml`, `secret-scan.yml` untouched).
- Allowlistable command shapes only (no `cd &&`, no heredocs, no `$(…)` payloads, no poll loops).
- Nix flake/direnv for tooling; no hardcoded /nix paths.
- Do not assume GitHub Action versions from training data (not applicable here — no workflow changes).
- Merge gate: normal CI + SHA-bound `code-owner-review` status check; nothing may bypass or weaken it.
