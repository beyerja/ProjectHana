## Tasks
- [x] 001: Add `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO` to the Hanahuac target's `settings.base` in `project.yml` (GENERATE_INFOPLIST_FILE is already YES) so submissions skip the export-compliance prompt.
- [x] 002: Add `INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.education` to the Hanahuac target's `settings.base` in `project.yml`.
- [x] 003: Add `MARKETING_VERSION: "1.0"` and `CURRENT_PROJECT_VERSION: "1"` to the Hanahuac target's `settings.base` in `project.yml`.
- [x] 004: Add `INFOPLIST_KEY_UILaunchScreen_Generation: YES` to the Hanahuac target's `settings.base` in `project.yml` so a UILaunchScreen is generated and the app renders full-screen with no letterboxing.
- [x] 005: Regenerate `Hanahuac.xcodeproj` from `project.yml` via `just -f /Users/Private/Documents/Code/ProjectHana-worktrees/appstore-readiness/justfile generate` and commit the regenerated project so CI builds the updated settings.
- [x] 006: Verify the generated build settings: build Mac Catalyst via `just -f .../justfile build-mac` under free/Personal-Team signing and confirm the four Info.plist keys (ITSAppUsesNonExemptEncryption, LSApplicationCategoryType, MARKETING_VERSION, CURRENT_PROJECT_VERSION, UILaunchScreen) are present in the built app's Info.plist / build settings; confirm no usage-description strings or unused capabilities were added.
