# 007 — macOS & iPad presentation verification

## Title
Verify macOS (Mac Catalyst) icon idioms and iPad/macOS layout adaptation; fix concrete issues

## Goal
Confirm the app presents as a polished product on iPad and macOS (Mac Catalyst), the two
larger-idiom targets, and fix concrete presentation defects found.

## Acceptance Criteria
Traceable to feature.md:

- [ ] App icon idioms render correctly on macOS (Mac Catalyst): the asset catalog provides the
      macOS icon idiom coverage so the icon is not missing/blurry on Mac. (feature.md AC + Notes:
      "the only icon concern is macOS idiom coverage"; iOS 1024x1024/no-alpha is already fine.)
- [ ] iPad and macOS layouts adapt correctly (no broken/letterboxed/clipped layouts on the larger
      idioms); concrete layout issues found are fixed. (feature.md AC: layouts adapt on iPad/macOS)
- [ ] Verification is performed by building/running for Mac Catalyst and iPad idioms under
      free/Personal-Team signing; findings (what was checked, what was fixed) are recorded in the
      PR description. (feature.md Constraints: CI keeps building under free signing)

## Notes / Constraints
- SUPPORTS_MACCATALYST is already YES in project.yml; this story verifies and fixes, it does not
  add capabilities.
- Asset-catalog/icon and layout changes go through the normal flow; regenerate the `.xcodeproj`
  from `project.yml` if any sources/resources entries change.
- No device signing/archive/export; no new dependencies. (feature.md Constraints / Out of Scope)
- Independent of other stories.
