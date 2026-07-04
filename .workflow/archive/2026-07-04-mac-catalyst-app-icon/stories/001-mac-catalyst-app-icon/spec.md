# Story 001: Add "mac" idiom to AppIcon asset catalog

## Goal

Fix the missing app icon in the macOS Dock, Finder, and App Switcher for the Mac Catalyst build by
adding a `"mac"` idiom entry to the AppIcon asset catalog's `Contents.json`. The 1024x1024 source
PNG already exists; this is a single-file JSON edit.

## Acceptance Criteria

- [ ] `Hanahuac/Assets.xcassets/AppIcon.appiconset/Contents.json` contains a `"mac"` idiom image
      entry alongside the existing `"universal"` entry, referencing `AppIcon.png` at `1024x1024`.
- [ ] After `just build-mac`, the built Mac Catalyst bundle contains `AppIcon.icns` under
      `Contents/Resources/` (verify with `ls .build-mac/Build/Products/Release/ProjectHana.app/Contents/Resources/*.icns`).
- [ ] After `just install`, the app displays the custom brand-mark icon in the macOS Dock, Finder,
      and App Switcher (verified by visual inspection of `/Applications/Hanahuac.app`'s icon).
- [ ] `just test` continues to pass (iOS build path unaffected).
- [ ] `just generate` (xcodegen) and `just lint` continue to pass with no errors.

## Constraints

- Edit only `Hanahuac/Assets.xcassets/AppIcon.appiconset/Contents.json`. Do not regenerate the PNG,
  modify `project.yml`, or touch `project.pbxproj` unless `build-mac` proves the JSON edit alone is
  insufficient.
- Keep `"author": "xcode"` and `"version": 1` in the `info` block (already present).
- No artwork changes, no additional icon sizes, no App Store signing.
