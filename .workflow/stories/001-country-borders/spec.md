# Story 001: Country Borders on Map Quiz

## Goal
Bundle country border polygon data and render it as MapPolygon overlays on the satellite map in MapQuizView.

## Tasks
- [ ] Download Natural Earth 110m admin-0 GeoJSON and process into `country-borders.json` — a compact array of `{"id": "<ISO-A2>", "rings": [[[lon,lat],...], ...]}` objects; add file to `ProjectHana/Resources/` and wire into pbxproj
- [ ] Add `CountryBorderLoader` (or extend `GeographyDataLoader`) to parse `country-borders.json` into `[String: [[CLLocationCoordinate2D]]]` (keyed by ISO alpha-2 id)
- [ ] Render borders as `MapPolygon` overlays in `MapQuizView` — thin white/light stroke, clear fill, on top of `.imagery`

## Acceptance criteria
- Country borders are visible on the satellite map
- No text labels appear on the map
- Existing quiz tap/feedback behaviour is unchanged
- All tests pass; macOS build clean
