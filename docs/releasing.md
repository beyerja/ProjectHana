# Releasing Hanahuac

This document is the end-to-end release runbook: how versions are managed, how a release is cut
(bump PR → tag → automated pipeline), which quality gates protect every release and their local
equivalents, and — clearly marked at the end — the exact switch-on steps for the day a paid Apple
Developer account exists. Today every release artifact is **unsigned** (proven to work in story
003); nothing in the current pipeline requires signing identities, provisioning profiles, or Apple
credentials.

## Versioning

`project.yml` is the **single source of truth** for the app version. Two settings in its `targets`
build-settings block carry it:

- `MARKETING_VERSION` — strict three-component semver `X.Y.Z` (all numeric), the user-facing
  version.
- `CURRENT_PROJECT_VERSION` — a monotonically increasing positive integer build number.

No version value may be introduced anywhere else. The committed
`Hanahuac.xcodeproj/project.pbxproj` is regenerated output (xcodegen) — never hand-edited — so the
version flows from `project.yml` into the project on every `just generate`.

**Manual edits to these two fields are discouraged.** Bump the version with:

```sh
just bump <major|minor|patch>
```

This wraps `scripts/bump-version.py`, which bumps the requested semver part (resetting the lower
parts to 0), increments the build number by 1, rewrites only those two lines in `project.yml`
(byte-for-byte preservation of everything else), and regenerates the Xcode project the same way
`just generate` does.

### Tags-only release model

Releases exist **only** as annotated `v<MAJOR>.<MINOR>.<PATCH>` tags on `main` (e.g. `v1.2.0`).
There are no release branches. Semver prerelease suffixes are allowed — an annotated tag like
`v1.1.0-rc.1` runs the same pipeline and the workflow marks the resulting GitHub Release as a
prerelease (any tag containing `-`). The tag's `X.Y.Z` base must match `MARKETING_VERSION` in
`project.yml`; gate (a) below enforces this at publish time.

## Release runbook (step by step)

### 1. Open the bump PR

On a branch off `main`:

```sh
just bump <major|minor|patch>
```

Then finalize `CHANGELOG.md` (Keep-a-Changelog format): move the `## [Unreleased]` content under a
new `## [X.Y.Z] - YYYY-MM-DD` heading matching the bumped `MARKETING_VERSION`, and leave a fresh
empty `[Unreleased]` section on top. `scripts/check-changelog.sh` is the enforcement — the release
pipeline fails if the section for the version under release is missing. Commit `project.yml`, the
regenerated `Hanahuac.xcodeproj/project.pbxproj`, and `CHANGELOG.md`, and open the PR.

### 2. Merge via the normal gate

The bump PR merges through the standard merge gate like any other PR: per-PR CI (Build & Test,
lint, secret scan) plus the SHA-bound `code-owner-review` status check. Nothing about a release
bypasses or weakens this gate. Note that the review check is bound to a specific commit SHA —
`gh pr update-branch` (or any new push) re-blocks the merge until the gate is re-posted on the new
SHA.

### 3. Create and push the annotated tag

On the merge commit on `main`:

```sh
git checkout main
git pull
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

### 4. The tag push triggers the release pipeline

Pushing the `v*` tag triggers `.github/workflows/release.yml`, which runs every quality gate,
builds the unsigned artifacts, and publishes the GitHub Release. The workflow is also manually
dispatchable (`workflow_dispatch`) with a `dry_run` input — a dry run executes every gate and
produces all artifacts but skips tag-consistency enforcement and Release publication (see
[Dry runs](#dry-runs-and-the-first-proven-run) below).

### 5. Verify the GitHub Release

When the workflow finishes, check the Release on GitHub:

- **Title** equals the tag (e.g. `v1.2.0`); prerelease-suffixed tags are marked as prereleases.
- **Body** is the tag's `CHANGELOG.md` section followed by the auto-generated notes.
- **Assets**: `Hanahuac.xcarchive.zip` (the unsigned Release device archive),
  `Hanahuac.ipa` (unsigned, installable-evidence artifact), and `SHA256SUMS.txt`.
- Verify the checksums: download all three assets into one directory and run
  `shasum -a 256 -c SHA256SUMS.txt`.
