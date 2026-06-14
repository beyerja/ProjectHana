# Story 001: Fix Norway and Sweden Map Pin Coordinates

## Title
Fix Norway and Sweden map pin coordinates so they fall inside country borders

## Goal
Update the `lat`/`lon` values for Norway (NO) and Sweden (SE) in `countries.json` to
manually verified interior points that pass a point-in-polygon test against the
corresponding rings in `country-borders.json`. Add a test to prevent regression.

## Acceptance Criteria
- [ ] Norway's new lat/lon passes PIP test against its mainland ring (ring index 1: lat=[58.1,71.2], lon=[5.0,31.3])
- [ ] Sweden's new lat/lon passes PIP test against its mainland ring (ring index 0: lat=[55.4,69.1], lon=[11.0,23.9])
- [ ] A new unit test in MapQuizRegionHelperTests.swift (or a new test file) verifies PIP for both corrected coordinates using the border data
- [ ] No other country records in countries.json are modified
- [ ] App builds and all existing tests pass

## Technical Notes
- File to edit: `ProjectHana/Resources/countries.json`
- Norway current: lat=64.5, lon=17.9 — confirmed OUTSIDE all rings
- Sweden current: lat=62.2, lon=17.7 — confirmed OUTSIDE all ring
- Candidate replacement for Norway: lat=63.0, lon=13.0 (central Norway, inland, clear of fjords)
  - Must verify with PIP before committing
- Candidate replacement for Sweden: lat=62.0, lon=15.5 (central Sweden, inland)
  - Must verify with PIP before committing
- Border data: `ProjectHana/Resources/country-borders.json`
- PIP test file to add or extend: `ProjectHanaTests/MapQuizRegionHelperTests.swift`
