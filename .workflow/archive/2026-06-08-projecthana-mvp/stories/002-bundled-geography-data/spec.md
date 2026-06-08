# Story 002: Bundled Geography Data

## Title
Add bundled JSON datasets for countries, capitals, rivers, mountain ranges, and seas

## Goal
Ship all geography content as bundled JSON files so the app works entirely offline and has
concrete data to drive quizzes in subsequent stories.

## Acceptance Criteria
- [ ] `countries.json` in the app bundle contains all 195 UN-recognised countries, each with:
      `id` (ISO-3166-1 alpha-2), `name`, `capital`, `continent`, `lat`, `lon`
- [ ] `rivers.json` contains at least 30 major rivers, each with: `id`, `name`, `continent`,
      `sourceLat`, `sourceLon`, `mouthLat`, `mouthLon`
- [ ] `mountains.json` contains at least 20 major mountain ranges, each with: `id`, `name`,
      `continent`, `lat`, `lon`, `highestPeak`, `elevationMetres`
- [ ] `seas.json` contains at least 15 major seas/oceans, each with: `id`, `name`, `lat`, `lon`
- [ ] A Swift `GeographyDataLoader` struct reads and decodes each JSON file at app startup;
      decoding errors produce a clear `fatalError` message in debug builds
- [ ] Corresponding `Codable` Swift structs exist: `Country`, `River`, `MountainRange`, `Sea`
- [ ] Unit tests verify that each JSON file loads without errors and record counts meet minimums
