# Story 002: Fix Map Camera Initial Position

## Problem

MapQuizView and MapLearningQuizView both used `@State private var position: MapCameraPosition = .automatic`. MapKit resolves `.automatic` by framing the union of ALL registered map content (annotations + featureOverlays). River linePath polylines span 25–30° of latitude; large sea/mountain polygons can be continent-sized. This caused the initial rendered frame to zoom out to continental/global scale before `buildSession()` could apply the correct `.region(...)`, making candidate pins invisible or centering on the wrong area.

## Fix

Initialise `position` to `.region(MKCoordinateRegion())` instead of `.automatic` in both `MapQuizView.swift` and `MapLearningQuizView.swift`. A zero-span region gives MapKit no content-union framing to perform. Since `session` is nil until `buildSession()` runs, the Map only enters the view hierarchy after `position` has already been set to `.region(s.mapRegion)` — so the first frame MapKit ever renders for this Map uses the correct candidate-pin region, not the overlay union.

## Acceptance Criteria

- AC1: River quiz opens with map centered on the river's candidate-pin region (not continent-scale zoom-out)
- AC2: Mountain range quiz opens with map centered on the mountain-pin region
- AC3: Sea quiz opens with map centered on the sea-pin region
- AC4: Country quiz is unaffected (countries were not broken; fix must not regress them)
- AC5: `MapQuizSession.mapRegion` has a non-zero lat/lon span immediately after init for rivers
- AC6: `MapQuizSession.mapRegion` has a non-zero lat/lon span immediately after init for seas
- AC7: `MapQuizSession.mapRegion` has a non-zero lat/lon span immediately after init for mountains
- AC8: `MapQuizSession.mapRegion` has a non-zero lat/lon span immediately after init for countries
- AC9: `MapLearningSession.mapRegion` has a non-zero lat/lon span immediately after init for all four categories
- AC10: No changes to pin-spread logic, QuizRegionMath, or overlay rendering

## Implementation

PR #206 squash-merged as: `fix(map-quiz): stop using .automatic MapCameraPosition in river/mountain/sea quizzes`

Files changed:
- `Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift` — line 28
- `Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift` — line 32

Tests added (PR #205):
- `HanahuacTests/MapQuizSessionTests.swift` — 8 tests covering all categories × both session types
