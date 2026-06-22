<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context 4-eye review of the build-config/versioning changes (`project.yml` + regenerated `Hanahuac.xcodeproj`).

**Verdict: APPROVED** — no blocking findings, no nits.

### Acceptance criteria
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO` — present
- `INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.education` — present (valid LSApplicationCategoryType)
- `MARKETING_VERSION "1.0"` + `CURRENT_PROJECT_VERSION "1"` — present
- `INFOPLIST_KEY_UILaunchScreen_Generation: YES` — present (correct Xcode launch-screen generator key)
- `Hanahuac.xcodeproj` regenerated & builds under free signing — confirmed

### Constraint checks
- **pbxproj is genuinely XcodeGen-generated, not hand-edited:** ran `xcodegen generate` from `project.yml` → **zero drift** against the committed `.pbxproj`. All 5 settings appear identically in both Debug and Release configs, matching `settings.base` semantics.
- **No usage-description strings or capabilities** for unused APIs added.
- **No new dependencies** (`dependencies: []` unchanged).
- **CI green under free signing:** Build & Test passed.

Config-only diff (20 lines added, 0 removed); no logic, no deletions, no callers affected.
