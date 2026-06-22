## Goal

Configure the cohesive, App-Store-required build/Info.plist settings that are pure `project.yml`
changes (`Hanahuac.xcodeproj` is generated via XcodeGen — never edited directly). These are grouped
into one PR because they are all one-or-two-line settings under the same target's `settings.base` and
would otherwise become a dozen trivial PRs.

This is story 001 of the `appstore-readiness` feature; it targets the `feat/appstore-readiness`
integration branch.

## Changes

- Set `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` so submissions skip the export-compliance prompt.
- Set `INFOPLIST_KEY_LSApplicationCategoryType = public.app-category.education` (Education category).
- Set `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1` explicitly under the app target.
- Configure a generated launch screen (`INFOPLIST_KEY_UILaunchScreen_Generation = YES`) so the app
  renders full-screen on all devices with no letterboxing.
- Regenerate `Hanahuac.xcodeproj` from `project.yml` via XcodeGen.

No usage-description strings or capabilities were added for unused APIs (no network/location/camera/
photo/notification). No device signing, archiving, or App Store Connect work.

## Test plan

- [ ] `ITSAppUsesNonExemptEncryption` is NO via `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption`.
- [ ] `LSApplicationCategoryType` is `public.app-category.education`.
- [ ] `MARKETING_VERSION` (1.0) and `CURRENT_PROJECT_VERSION` (1) are set explicitly.
- [ ] Launch screen is configured (`INFOPLIST_KEY_UILaunchScreen_Generation = YES`).
- [ ] `Hanahuac.xcodeproj` regenerated from `project.yml`; project builds under free/Personal-Team
      signing and CI stays green.
