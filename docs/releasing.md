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
