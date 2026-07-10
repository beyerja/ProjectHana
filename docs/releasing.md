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

## Release quality gates

`release.yml` runs the following gates, in order, on every tag push and every dry run. It is
deliberately **not** a per-PR workflow (a full Catalyst test suite + Release builds on a macOS
runner is slow); the per-PR blocking set (`ci.yml`, `lint.yml`, `secret-scan.yml`) is separate and
untouched by releases.

| Gate | What runs | What it protects |
|------|-----------|------------------|
| (a) Tag ↔ version consistency | `scripts/check-tag-version.sh <tag>` | A published Release can never claim a version different from the app's `MARKETING_VERSION` in `project.yml`. Enforced only on real tag refs; **skipped with an explicit explanation on dry runs** (tag enforcement is publish-time only). |
| (b) CHANGELOG section present | `scripts/check-changelog.sh` | Every release ships human-readable release notes — no tag without a finalized `## [X.Y.Z]` changelog section. |
| (c) Full lint suite | `just lint` | The release commit meets the same fail-on-violation lint bar (Swift/Python/shell/Nix/YAML/GHA + l10n completeness) as every PR. |
| (d) Full test suite | `xcodebuild test` on Mac Catalyst, exactly as `ci.yml`'s Test step (Debug, unsigned flags) | No release from a commit whose tests don't pass; **UI tests execute in CI** on Catalyst. |
| (e) Geo packs up to date | `just geo-packs-check` | The committed per-language geo-name ODR packs cannot drift from the bundled geo source data. |
| (f) ODR pack integrity | `just verify-odr-packs` | ODR packs are data-only (no executable/Mach-O content) and the `lang-<code>` tag contract holds. |
| (g) Release build + base-only validation | `just verify-base-only-release` | The Release-config app launches fully usable offline with zero packs downloaded (base languages bundled, non-base declared on-demand). |

After the gates, the workflow builds the unsigned `.xcarchive` + `.ipa` via `just archive` (never
re-implemented in YAML), zips the archive, emits `SHA256SUMS.txt`, and uploads everything as the
`release-artifacts` workflow artifact. Only real (non-dry-run) tag refs then run the
`publish-release` job.

### Local equivalents

Run the same quality bar locally before tagging:

- **`just release-check [vX.Y.Z]`** — the full local release quality bar in 6 steps: (1) lint
  suite, (2) full test suite on Mac Catalyst as `ci.yml`, (3) geo packs up to date, (4) ODR pack
  integrity, (5) Release build + base-only bundle verification, (6) changelog presence — plus
  tag↔version consistency when the optional tag argument is given (skipped with a note otherwise).
- **`just archive`** — produces the unsigned Release `.xcarchive` (generic iOS device) and the
  unsigned `.ipa` (`scripts/package-ipa.sh`), identical to what the workflow ships.

### Story 003 empirical outcome (why unsigned works)

The unsigned **iOS device Release archive is PROVEN**: `xcodebuild archive` against
`generic/platform=iOS` with `CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
CODE_SIGNING_ALLOWED=NO` succeeds with **no signing identity, no provisioning profile, and no Apple
credentials** — no Catalyst fallback was needed. The unsigned `.ipa` is produced from that archive
by `scripts/package-ipa.sh` (plain Payload zip); it is an **installable-evidence artifact** only —
suitable for sideloading or re-signing later, not App Store distribution.

### Documented deviation: local UI-test execution

`just test-mac` **compiles** `HanahuacUITests` (xcodebuild builds every test bundle in the scheme)
but **skips its execution locally**: launching the XCUITest runner against a Catalyst app on a
local Mac hangs deterministically before establishing a connection (it needs UI-automation
permissions this environment doesn't grant — reproduced twice in story 003, with all unit tests
green either way). CI is not affected: the required Build & Test check and gate (d) above execute
the UI tests on Catalyst. The local UI path is `just ui-walkthrough`, which drives the app on the
iOS simulator with screenshots + accessibility dumps per step.
