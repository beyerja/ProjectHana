# Feature: App Store readiness remediation

## Goal
Bring Hanahuac to a state where it would pass App Store technical/compliance review and present as a polished product on iOS, iPad, and macOS — limited to work that does NOT require a paid Apple Developer account (the owner does not have one yet). Each gap below is driven to a merged PR.

## Acceptance Criteria
- [ ] A `PrivacyInfo.xcprivacy` privacy manifest is bundled, declaring: no tracking, no collected data types, and the required-reason API for `UserDefaults` (NSPrivacyAccessedAPICategoryUserDefaults reason `CA92.1`). Audit the codebase for any other required-reason APIs (file timestamp, disk space, system boot time) and declare them too.
- [ ] `ITSAppUsesNonExemptEncryption` is set to NO (via `INFOPLIST_KEY_*` in project.yml since GENERATE_INFOPLIST_FILE is YES) so submissions skip the export-compliance prompt.
- [ ] `LSApplicationCategoryType` is set to the Education category.
- [ ] `MARKETING_VERSION` (1.0) and `CURRENT_PROJECT_VERSION` (1) are set explicitly in project.yml.
- [ ] A launch screen is configured (`INFOPLIST_KEY_UILaunchScreen_Generation = YES`, or an equivalent) so the app renders full-screen on all devices (no letterboxing).
- [ ] Accessibility: interactive and informational views carry VoiceOver labels/hints/values — prioritize the quiz flows and the MapKit map-quiz annotations (currently invisible to VoiceOver), and verify Dynamic Type scaling. There are currently ZERO accessibility modifiers in the app; this is the largest item — break it into a sensibly-scoped story (or stories) rather than attempting everything at once.
- [ ] Localization completeness is verified across all 6 languages (en, es-MX, de, fr, ko, nah): no untranslated keys and no hardcoded user-facing English. Fix any gaps found.
- [ ] A privacy-policy document is authored in-repo (e.g. docs/privacy-policy.md) suitable to host and reference from App Store Connect, accurately reflecting that the app collects/transmits no data.
- [ ] macOS and iPad presentation is verified: app icon idioms render correctly on macOS (Mac Catalyst), and layouts adapt on iPad/macOS. Fix concrete issues found.

## Constraints
- No paid Apple Developer account: do not attempt device code-signing, archiving/export, TestFlight, or App Store Connect uploads. CI must keep building under free/Personal-Team signing.
- Zero external dependencies (SwiftUI · SwiftData · MapKit only) — do not add packages.
- The app is fully offline (no network/location/camera/photo/notification requests) — do NOT add usage-description strings or capabilities for APIs the app does not use.
- Follow CLAUDE.md command-shape rules and the per-story PR -> CI -> independent-review -> merge gate (CODEOWNERS bot approval is obligatory).

## Out of Scope
- iCloud/CloudKit sync (already gated OFF behind CLOUDKIT_SYNC; leave it as-is).
- Device signing, archive/export, TestFlight.
- App Store Connect: actual screenshot/metadata/nutrition-label upload and age-rating questionnaire submission (these need the account). Authoring supporting docs/text in-repo is fine.

## Notes from the main-session audit (use as starting evidence, but verify)
- App icon is already 1024x1024 with no alpha (iOS-compliant); the only icon concern is macOS idiom coverage.
- Only 1 `try!` (preview-only) and a few defensible `fatalError`s — no broad crash-hardening story needed.
- `UserDefaults` is used in ActiveSetStore / KeyValueStore / LanguageManager (drives the privacy-manifest required-reason entry).
