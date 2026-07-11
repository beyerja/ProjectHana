## Goal

Seed a Keep-a-Changelog `CHANGELOG.md` and deliver the committed, tested consistency-check scripts that later gate releases: one verifying `CHANGELOG.md` has a section for a given version, and one verifying a `v*` tag matches `MARKETING_VERSION` in `project.yml`. These are the reusable gates consumed by `just release-check` (story 003) and `release.yml` (story 004) — delivered here as standalone, runnable, tested scripts, not stubs.

## Changes

- **`CHANGELOG.md`** — seeded at the repo root in Keep-a-Changelog format with an `[Unreleased]` section summarizing the current pre-release state, plus a release-procedure header comment documenting the convention: `[Unreleased]` content moves under the new version heading as part of the version-bump PR (full runbook lands in story 005).
- **`scripts/check-changelog.sh`** — exits non-zero with a clear message when `CHANGELOG.md` has no section for the version under check, zero when it does; the version can be passed explicitly or derived from `MARKETING_VERSION` in `project.yml`.
- **`scripts/check-tag-version.sh`** — verifies tag↔version consistency: given a tag `vX.Y.Z`, fails unless it equals `v` + `MARKETING_VERSION` from `project.yml`; supports prerelease-suffixed tags (e.g. `v1.1.0-rc.1`) per the semver convention.
- **Tests** — fixture-only test scripts for both checks on the `scripts/test-lib.sh` harness (36 assertions covering positive and negative cases — failing checks actually fail).
- **`justfile`** — new recipes: `test-release-scripts`, `check-changelog`, `check-tag-version`.

No `.github/workflows` changes — per-PR blocking checks (`ci.yml`, `lint.yml`, `secret-scan.yml`) are untouched; changelog enforcement runs only at release time.

## Test plan

- [ ] `just test-release-scripts` passes (36 assertions, positive + negative cases for both scripts)
- [ ] `just check-changelog` passes against the seeded `CHANGELOG.md` with the current `MARKETING_VERSION`
- [ ] `just check-tag-version v<MARKETING_VERSION>` passes; a mismatched tag fails with a clear message
- [ ] Prerelease-suffixed tag (e.g. `v1.1.0-rc.1`) is accepted by the tag check
- [ ] shellcheck passes on the new scripts; existing lint gate stays green
- [ ] CI is green

🤖 Generated with [Claude Code](https://claude.com/claude-code)
