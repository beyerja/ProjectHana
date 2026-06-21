# 006 — ODR pack packaging, build config & async validation CI

## Title
Package the non-base language packs as version-tagged On-Demand Resources and validate them via
async (non-per-PR) CI

## Goal
Make the per-language pack resources (the fr/de/ko/nah `.lproj` UI strings + their geo-name JSON
data) actually ship as On-Demand Resource tags built per app version, removing them from the main
binary, and add the build/packaging configuration plus an async device/ODR validation job that
does NOT block PRs. This is the step that realizes the "installed size stays flat" goal and the
release-tied pack versioning constraint.

## Background (current state)
- All 6 `.lproj` directories and the geo JSON are bundled into the main app target today.
- CI conventions: fast checks block PRs; slow/device-only scans run on schedule / push-to-main
  with tracked findings (per project memory and feature constraint).

## Acceptance Criteria
- [ ] The non-base languages' resources (fr/de/ko/nah `.lproj` and their geo-name pack JSON) are
      assigned ODR tags and excluded from the main app binary's always-bundled resources, so they
      are delivered on demand. en + es-MX resources remain bundled.
- [ ] ODR tags are organized so each downloadable language maps to the tag(s) the provider
      (story 004) requests; the build produces these as Apple-hosted, code-signed ODR packs.
- [ ] Pack versioning is tied to the app release: ODR tags are built per app version and
      already-installed packs refresh on app update. No independent OTA pack updates.
- [ ] Build/packaging config changes are documented (how packs are tagged/produced) so the
      release process is reproducible.
- [ ] Fast PR checks remain blocking and fast; any slow or device-only ODR validation (e.g.
      verifying packs download and resolve on a real build/device) runs async — scheduled or on
      push-to-main — with findings tracked, NOT as a per-PR gate.
- [ ] A validation step confirms packs are DATA-ONLY (no executable content) and that the app
      builds and launches with zero packs present (offline base-only path).
- [ ] No custom network/crypto/signature-verification trust code is introduced; integrity is
      inherited from Apple App Store ODR code-signing.

## Out of Scope
- The signed-CDN provider implementation and its packaging (future feature).
- OTA pack updates independent of app releases.
- Adding new languages.
