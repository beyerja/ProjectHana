# 002 — Privacy manifest (PrivacyInfo.xcprivacy)

## Title
Author and bundle a PrivacyInfo.xcprivacy manifest with audited required-reason API declarations

## Goal
Add the Apple privacy manifest the App Store now requires, declaring that the app does no
tracking and collects no data, and declaring the required-reason APIs the app actually uses.

## Acceptance Criteria
Traceable to feature.md:

- [ ] A `PrivacyInfo.xcprivacy` privacy manifest exists in the repo and is bundled in the app
      target (added as a resource via `project.yml` so XcodeGen includes it; regenerate the
      `.xcodeproj`). (feature.md AC: privacy manifest)
- [ ] The manifest declares `NSPrivacyTracking = false`, an empty `NSPrivacyTrackingDomains`,
      and an empty `NSPrivacyCollectedDataTypes` (no tracking, no collected data types).
- [ ] The manifest declares the required-reason API for `UserDefaults`:
      `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`. (UserDefaults is used in
      ActiveSetStore / KeyValueStore / LanguageManager.) (feature.md AC + Notes)
- [ ] The codebase is audited for OTHER required-reason APIs — file timestamp
      (`NSPrivacyAccessedAPICategoryFileTimestamp`), disk space
      (`NSPrivacyAccessedAPICategoryDiskSpace`), system boot time
      (`NSPrivacyAccessedAPICategorySystemBootTime`), active keyboard — and any that are actually
      used are declared with the correct reason code. The audit result (including "none found") is
      recorded in the PR description. (feature.md AC: audit for other required-reason APIs)
- [ ] App still builds and CI stays green after the manifest is added. (feature.md Constraints)

## Notes / Constraints
- This story is independent of 001: it only adds a resource file + a `project.yml` sources entry.
- Add no usage-description strings for unused APIs. (feature.md Constraints)
