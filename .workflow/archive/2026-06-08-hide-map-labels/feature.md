# Feature: Hide Country Names on Map Quiz

## Goal
The map quiz should not reveal country names during gameplay. Currently, MapKit's standard map style renders country name labels directly into the map tiles, giving away answers. The map must be changed to a style that shows no text labels.

## Root cause
`MapQuizView` uses `.mapStyle(.standard(elevation: .flat))`. Standard map tiles include country, region, and city names that cannot be suppressed via SwiftUI's MapKit API. Switching to `.imagery(elevation: .flat)` (satellite/aerial imagery) removes all rendered text labels while keeping geography visible.

## Acceptance criteria
- [ ] No country names (or any other text labels) are visible on the map during a quiz session
- [ ] The map still clearly shows geographic features (coastlines, terrain, borders) so countries are identifiable
- [ ] All existing quiz interactions (tap to answer, correct/incorrect feedback, pin labels on reveal) continue to work correctly
- [ ] No regressions in other quiz modes

## Out of scope
- Changing pin appearance or quiz logic
- Adding continent/region filtering
