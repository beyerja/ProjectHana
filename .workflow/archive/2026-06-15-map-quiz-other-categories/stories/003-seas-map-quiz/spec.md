# Story 003 — Seas map quiz & learning (polygon overlay + pin)

## Title
Add sea support: bundled `sea-borders.json` polygon overlays + pin

## Goal
Make `Sea` a `MappableFeature` and add a bundled `sea-borders.json` of marine
polygons so the seas category gets the full map quiz + map learning experience
with polygon overlays plus a pin, like countries.

## Scope / design notes
- Produce `Hanahuac/Resources/sea-borders.json` in the same shape as
  `country-borders.json`: `[{"id":"<sea id>","rings":[[[lon,lat],...], ...]}]`,
  keyed to `seas.json` ids, matched by name. Source: Natural Earth marine
  polygons (`ne_*_geography_marine_polys` / IHO Limits of Oceans and Seas).
  All 20 seas should have a matched polygon; if a sea genuinely cannot be matched
  it falls back to pin-only (document any such case in the story log).
- Wire `sea-borders.json` into `project.yml` resources and regenerate.
- Add a `SeaBorderLoader` (reuse/generalize the `CountryBorderLoader` pattern)
  returning `[String: [[CLLocationCoordinate2D]]]`.
- `Sea` conforms to `MappableFeature`:
  - pin coordinate = the `lat`/`lon` in `seas.json` (no pole computation needed,
    but ensure the pin sits sensibly; use the JSON coordinate directly).
  - border rings = the sea's rings from `SeaBorderLoader` (nil if unmatched).
  - line endpoints = nil.
- Wire `.sea` session construction over `GeographyDataLoader.shared.seas`.
- Generalize the view's border lookup so it pulls from the correct loader per
  category (country→CountryBorderLoader, sea→SeaBorderLoader).

## Acceptance Criteria
1. `sea-borders.json` is bundled, wired into `project.yml`, and loads at runtime
   via `SeaBorderLoader` into the expected dictionary; a test asserts the loader
   returns a non-trivial number of entries matched to `seas.json` ids.
2. `Sea` conforms to `MappableFeature` with pin = JSON lat/lon and rings from the
   loader.
3. A `.sea` map quiz quizzes seas with polygon overlay + pin and the standard
   correct/incorrect highlight on the polygon.
4. `.sea` map learning graduates after 3 correct with streak + persistence.
5. A test verifies polygon→sea id matching coverage (target: all 20, or the
   documented matched subset) and that unmatched seas fall back to pin-only
   without crashing.
6. Full suite green.

## Visual Verification
A seas map quiz shows a marine polygon overlay plus a pin; the polygon highlights
on answer. (Verified via unit tests + compilation.)
