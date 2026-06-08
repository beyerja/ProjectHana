# Story 001: Hide Map Labels

## Goal
Change the MapQuizView map style from `.standard` (which bakes country names into the tiles) to `.imagery` (satellite/aerial, no text) so no country names are visible during a quiz session.

## Tasks
- [ ] In `MapQuizView.swift`, change `.mapStyle(.standard(elevation: .flat))` to `.mapStyle(.imagery(elevation: .flat))`

## Acceptance criteria
- No country/city/region names appear on the map during a quiz session
- Geographic features (coastlines, water bodies, terrain) are still clearly visible
- All quiz interactions (tap, correct/incorrect state, name reveal on pin) still work
- Build and tests pass; macOS build succeeds

## Notes
This is a single-line change. No new files, no pbxproj changes needed.
