## Goal

Confirm the app presents as a polished product on iPad and macOS (Mac Catalyst), the two larger-idiom
targets, and fix concrete presentation defects found. Verification was performed under free /
Personal-Team (ad-hoc) signing — no device signing, archive, export, capabilities, or dependencies
were added.

## Summary of changes

- **App-icon idiom coverage (Mac Catalyst) — gap found and fixed.** `AppIcon.appiconset/Contents.json`
  declared the single 1024x1024 image with `"platform": "ios"`, scoping the icon to the iOS idiom only
  and leaving the macOS idiom without a usable icon (missing/blurry Mac icon). Removed the
  `"platform": "ios"` restriction so the universal 1024x1024 entry becomes an Xcode "Single Size" icon
  that auto-derives all idioms, including Mac. The existing `AppIcon.png` is reused; no new image files
  or generated sizes added, change confined to the AppIcon set. No `project.yml` source/resource
  entries changed, so `just generate` was not needed.
- **iPad / macOS layout adaptation — audited, no change needed.** The view tree uses adaptive layout
  throughout: root `NavigationStack` + `ScrollView`/`VStack` with `frame(maxWidth: .infinity)`
  pervasively across Home, Stats/Progress, and every quiz view. The only fixed `.frame(width:)` uses
  are small control/glyph sizes and GeometryReader-driven logo sizing — none impose a fixed
  full-screen width, so nothing letterboxes or clips on the larger idioms. No speculative rework done;
  no concrete clipping/letterboxing defect found.

## Acceptance criteria

- [x] App icon idioms render correctly on macOS (Mac Catalyst) — Mac Catalyst build shows no app-icon
      idiom warning (the pre-fix "no image found for idiom 'mac'"-class warning is gone).
- [x] iPad and macOS layouts adapt correctly (no broken/letterboxed/clipped layouts); confirmed by
      inspection and by iPad build + run.
- [x] Verification performed by building/running for Mac Catalyst and iPad idioms under free signing;
      findings recorded here.

## Test plan

- [x] `just build-mac` (Mac Catalyst, ad-hoc signing) — BUILD SUCCEEDED; no app-icon idiom warning.
- [x] `HANA_SIM_NAME="iPad Pro 13-inch (M5)" just build-sim` — BUILD SUCCEEDED.
- [x] iPad runtime: installed + launched on iPad Pro 13-inch (M5) simulator — Home renders full-width
      and adaptive, category rows stretch edge-to-edge, no clipping or letterboxing.
- [x] `just lint` — PASS (SwiftLint, swiftformat --lint, l10n completeness, yaml, nix all clean).
- [x] `just test` — TEST SUCCEEDED (full suite on iOS Simulator).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
