## Goal

Establish `project.yml` as the single source of truth for the app version (`MARKETING_VERSION`, semver `X.Y.Z`) and build number (`CURRENT_PROJECT_VERSION`, monotonic integer), with a committed bump script and a `just bump <major|minor|patch>` recipe that updates both values and regenerates the Xcode project. This is the foundation for the later release stories (changelog checks, tag-consistency gate, release workflow).

## Changes

- Normalize `MARKETING_VERSION` in `project.yml` to three-component semver (`1.0` -> `1.0.0`).
- Add `scripts/bump-version.py`: bumps the requested semver part, increments `CURRENT_PROJECT_VERSION` by 1, and rewrites `project.yml` in place. Rejects non-semver current values and invalid part arguments with a clear error and non-zero exit. Script header documents the tagging convention: annotated `v<MAJOR>.<MINOR>.<PATCH>` tags on `main` only; manual edits to the version fields are discouraged (full runbook lands in story 005).
- Add `just bump <part>` recipe that runs the bump script and regenerates the Xcode project via xcodegen, so `just bump patch` yields a clean, reviewable diff.
- Add `scripts/test-bump-version.sh` plus a `just test-version-scripts` recipe covering the happy paths (major/minor/patch), normalization, and the error cases.

No changes to per-PR blocking checks (`ci.yml`, `lint.yml`, `secret-scan.yml` untouched).

## Test plan

- [ ] `just test-version-scripts` passes (bump script unit tests: major/minor/patch, invalid part, non-semver current value).
- [ ] `just bump patch` on a scratch branch produces a diff touching only `project.yml` and the regenerated project output, then `just generate` is a no-op.
- [ ] New Python passes ruff and new shell passes shellcheck; existing lint gate stays green.
- [ ] CI green on this PR.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
