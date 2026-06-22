# 001 — Build config, compliance flags & versioning

## Title
Set App Store compliance build settings, app category, version, and launch screen in project.yml

## Goal
Configure the cohesive, App-Store-required build/Info.plist settings that are pure
`project.yml` changes (Hanahuac.xcodeproj is generated via XcodeGen — never edit it directly).
These are grouped here because they are all one-or-two-line settings under the same target's
`settings.base` and would otherwise become a dozen trivial PRs.

## Acceptance Criteria
Traceable to feature.md:

- [ ] `ITSAppUsesNonExemptEncryption` is set to NO via `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption`
      in `project.yml` (GENERATE_INFOPLIST_FILE is YES), so submissions skip the export-compliance
      prompt. (feature.md AC: ITSAppUsesNonExemptEncryption)
- [ ] `LSApplicationCategoryType` is set to the Education category
      (`public.app-category.education`) via `INFOPLIST_KEY_LSApplicationCategoryType`.
      (feature.md AC: LSApplicationCategoryType)
- [ ] `MARKETING_VERSION` (1.0) and `CURRENT_PROJECT_VERSION` (1) are set explicitly in
      `project.yml` under the app target's build settings. (feature.md AC: MARKETING/CURRENT version)
- [ ] A launch screen is configured (`INFOPLIST_KEY_UILaunchScreen_Generation = YES`, or an
      equivalent generated UILaunchScreen) so the app renders full-screen on all devices with no
      letterboxing. (feature.md AC: launch screen)
- [ ] `Hanahuac.xcodeproj` is regenerated from `project.yml` (xcodegen) and the project still
      builds under free/Personal-Team signing; CI stays green. (feature.md Constraints)

## Notes / Constraints
- Source of truth is `project.yml`; regenerate the `.xcodeproj` with the project's xcodegen flow.
- Do NOT add usage-description strings or capabilities for APIs the app does not use
  (no network/location/camera/photo/notification). (feature.md Constraints / Out of Scope)
- No device signing, archiving, or App Store Connect work.
