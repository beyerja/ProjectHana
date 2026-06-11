# Feature: Country Borders on Map Quiz

## Goal
Show country political borders on the satellite map so players can identify where each country is without country name labels being visible. The current `.imagery` style shows geography but no political boundaries, making it hard to locate specific countries. We must keep `.imagery` (not switch to `.hybrid`, which would re-introduce name labels).

## Approach
Bundle a simplified country border dataset (polygon rings derived from Natural Earth 110m admin-0 boundaries, keyed by ISO alpha-2 code) and render each country as a `MapPolygon` overlay with a thin visible stroke and no fill, on top of the existing satellite imagery.

## Constraints
- Must NOT reveal country names — no text on the map
- Must NOT switch away from `.imagery` map style (`.hybrid` adds labels)
- Border data must be bundled (no network requests at runtime)
- The ISO alpha-2 `id` field already present in `countries.json` is used to match borders to quiz countries

## Acceptance criteria
- [ ] Country political borders are visible as thin lines on the satellite map during a quiz session
- [ ] No country name labels appear anywhere on the map
- [ ] All 197 quiz countries have corresponding border polygons rendered (or as many as the 110m dataset covers — small territories may be absent)
- [ ] Existing quiz interactions (tap, correct/incorrect pin feedback) continue to work correctly
- [ ] Build and tests pass; macOS build succeeds
