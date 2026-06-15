# Story 004 — Mountains map quiz & learning (polygon overlay + pin, with fallback)

## Title
Add mountain support: bundled `mountain-borders.json` polygons + pin-only fallback

## Goal
Make `MountainRange` a `MappableFeature` and add a bundled
`mountain-borders.json` of range polygons so the mountains category gets the
full map quiz + map learning experience, with a pin-only fallback for ranges
whose polygon cannot be confidently matched.

## Scope / design notes
- Produce `Hanahuac/Resources/mountain-borders.json` in the
  `[{"id","rings":[[[lon,lat],...]]}]` shape, matched to `mountains.json` ids by
  name. Source: GMBA Mountain Inventory or Natural Earth region polygons.
  Mountain-range borders are fuzzier than seas — match what is confident; ranges
  with no confident match are simply omitted from the JSON and render pin-only.
  Document in the story log which ranges got polygons and which fell back.
- Wire `mountain-borders.json` into `project.yml` and regenerate.
- Add a `MountainBorderLoader` (reuse/generalize the loader pattern).
- `MountainRange` conforms to `MappableFeature`:
  - pin coordinate = the `lat`/`lon` in `mountains.json`.
  - border rings = the range's rings from the loader, or nil → pin-only.
  - line endpoints = nil.
- Wire `.mountain` session construction over
  `GeographyDataLoader.shared.mountains`.

## Acceptance Criteria
1. `mountain-borders.json` is bundled, wired into `project.yml`, and loads via
   `MountainBorderLoader`; a test asserts every entry id matches a known mountain
   id and the loader returns the expected count.
2. `MountainRange` conforms to `MappableFeature` with pin = JSON lat/lon and
   rings from the loader (nil → pin-only).
3. A `.mountain` map quiz quizzes mountains; ranges with polygons show overlay +
   pin, ranges without show pin-only — no crash, no mismatched polygon.
4. `.mountain` map learning graduates after 3 correct with streak + persistence.
5. A test verifies the pin-only fallback path (an unmatched range renders without
   rings and the session still functions).
6. Full suite green.

## Visual Verification
A mountains map quiz shows a range polygon overlay + pin where matched, and a
bare pin where not. (Verified via unit tests + compilation.)
