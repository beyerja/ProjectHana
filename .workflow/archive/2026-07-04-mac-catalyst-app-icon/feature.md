# Feature: mac-catalyst-app-icon

## Goal

The installed macOS app (Mac Catalyst, installed via `just install` to `/Applications/Hanahuac.app`)
currently displays a blank/default icon in Finder, the Dock, and the App Switcher. Fix this so the
app displays its custom brand-mark icon everywhere macOS shows app icons.

## Root Cause (verified)

The bug is in `Hanahuac/Assets.xcassets/AppIcon.appiconset/Contents.json`. It currently declares
only a single `"idiom": "universal"` entry at `1024x1024`. When `actool` compiles the asset catalog
for the Mac Catalyst destination, the `universal` idiom satisfies iOS but does **not** cause actool
to emit `AppIcon.icns` into the Mac bundle's `Contents/Resources/`. The built app bundle
(`.build-mac/Build/Products/Release/ProjectHana.app/Contents/Resources/`) confirms this: the
directory contains only JSON data files — no `.icns` file is present.

The 1024x1024 source PNG (`Hanahuac/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, 490 KB) is a
valid, opaque image rendered by `scripts/make-icon.swift`. No new artwork is needed.

The fix: add a `"mac"` idiom entry pointing to the same `AppIcon.png` in `Contents.json`, so actool
emits `AppIcon.icns` during the Catalyst build.

## Acceptance Criteria

- [ ] `Hanahuac/Assets.xcassets/AppIcon.appiconset/Contents.json` includes a `"mac"` idiom image
      entry (alongside the existing `"universal"` entry) referencing `AppIcon.png` at `1024x1024`.
- [ ] After `just build-mac`, the built Mac Catalyst bundle contains an `AppIcon.icns` file under
      `Contents/Resources/`.
- [ ] After `just install`, the app shows the custom brand-mark icon in the macOS Dock, Finder, and
      App Switcher (verified by visual inspection of `/Applications/Hanahuac.app`'s icon).
- [ ] The existing iOS build path is unaffected: `just test` continues to pass.
- [ ] `just generate` (xcodegen) and `just lint` continue to pass with no errors.

## Constraints

- The source PNG (`AppIcon.png`) is already the correct 1024x1024 opaque image — do not regenerate
  it or change the artwork.
- The `Contents.json` change must be compatible with Xcode's asset catalog format; use
  `"author": "xcode"` and `"version": 1` in the `info` block (already present).
- Do not modify `project.yml` or the generated `project.pbxproj` unless the `Contents.json` change
  alone proves insufficient after a build-mac verification.
- No App Store signing, distribution, or icon set changes for other idioms (iPhone, iPad) are in
  scope — the installed `.icns` is the only deliverable.

## Out of Scope

- Changing the icon artwork or brand mark.
- Adding macOS-specific icon sizes (16x16, 32x32, 128x128, etc.) to the `.icns` — `actool` derives
  all sizes from the single 1024x1024 source.
- iOS Simulator or TestFlight icon display (iOS already works via the `universal` idiom).
- App Store submission or signing.
- Any other per-PR CI check changes.
