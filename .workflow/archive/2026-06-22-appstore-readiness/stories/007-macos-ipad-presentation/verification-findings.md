# Story 007 — macOS & iPad presentation verification findings

Verification performed under free / Personal-Team (ad-hoc) signing. No device signing, archive,
export, capabilities, or dependencies were added (per feature.md scope).

## What was checked

### 1. App-icon idiom coverage (Mac Catalyst) — gap found and fixed
- **Gap:** `Hanahuac/Assets.xcassets/AppIcon.appiconset/Contents.json` declared the single
  1024x1024 image with `"platform": "ios"`, which scopes the icon to the iOS idiom only. On Mac
  Catalyst this leaves the macOS idiom without a usable icon (missing/blurry Mac icon).
- **Fix:** Dropped the `"platform": "ios"` restriction so the universal 1024x1024 entry becomes an
  Xcode "Single Size" icon that auto-derives all idioms, including Mac. The existing `AppIcon.png`
  is reused; no new image files or generated sizes were added, and the change is confined to the
  AppIcon set. No `project.yml` source/resource entries changed, so `just generate` was not needed.

### 2. iPad / macOS layout adaptation audit (by inspection)
The view tree uses adaptive layout throughout:
- Root is `NavigationStack` with a `ScrollView` + `VStack`; content uses
  `frame(maxWidth: .infinity)` pervasively across Home, Stats/Progress, and every quiz view
  (multiple-choice, capital, name-feature, map quiz/learning, summary).
- The only fixed `.frame(width:)` uses are small control/glyph sizes (42, 44, 40, 36, 28, 20, 56)
  and GeometryReader-driven logo sizing in `HanahuacLogo.swift` (sizes derived from `geo.size`,
  `s`, `w * 0.60`, etc.), plus one preview-only `160`. None impose a fixed full-screen width, so
  nothing letterboxes or clips on the larger idioms.
- No speculative layout rework was performed; no concrete clipping/letterboxing defect was found.

## Build / run results (free signing)

| Idiom | Command | Result |
|---|---|---|
| Mac Catalyst | `just build-mac` (ad-hoc signing) | BUILD SUCCEEDED; no app-icon idiom warning (the pre-fix "no image found for idiom 'mac'"-class warning is gone) |
| iPad | `HANA_SIM_NAME="iPad Pro 13-inch (M5)" just build-sim` | BUILD SUCCEEDED |
| iPad (runtime) | Installed + launched on iPad Pro 13-inch (M5) simulator, screenshot captured | Home screen renders full-width and adaptive; category rows stretch edge-to-edge; no clipping or letterboxing |

## Quality gates
- `just lint`: PASS (SwiftLint, swiftformat --lint, l10n completeness, yaml, nix all clean).
- `just test`: TEST SUCCEEDED (full suite on iOS Simulator).

## What was fixed
- App-icon Contents.json: removed `"platform": "ios"` so the 1024x1024 icon covers Mac Catalyst.

## What was verified with no change needed
- iPad/macOS layout adaptation (adaptive `NavigationStack` + `frame(maxWidth: .infinity)`; no
  fixed full-screen widths) — confirmed correct by inspection and by iPad build + run.
