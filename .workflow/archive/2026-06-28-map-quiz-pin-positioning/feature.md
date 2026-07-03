# Feature: Fix Map Quiz Camera/Viewport Centering for Rivers, Mountains, and Seas

## Summary

The map quiz showed a completely wrong geographic region for rivers (always), and sometimes the wrong region for mountains and seas. Countries work correctly. The fix is purely about the initial `MapCameraPosition` state — pin coordinates and pin spread/randomness are unchanged.

## Root Cause

Both `MapQuizView` and `MapLearningQuizView` declared:

    @State private var position: MapCameraPosition = .automatic

MapKit resolves `.automatic` by framing the union of ALL registered map content — both the `Annotation` pins and the `featureOverlays` (polygon rings and polylines). River `linePath` polylines span 25–30° of latitude; large sea/mountain `borderRings` polygons can be continent-sized. This caused the initial rendered frame to zoom out to a continental/global scale before `buildSession()` could apply the correct `.region(...)`.

Countries are unaffected because their border polygons are small and local — the `.automatic` framing accidentally centers near the candidate pins anyway.

## Fix

Changed the `@State` initial value from `.automatic` to `.region(MKCoordinateRegion())` in both views:
- `Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift`
- `Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift`

A zero-span explicit region gives MapKit no content-union framing to perform. Since `session` is `nil` until `buildSession()` runs, the `Map` only enters the view hierarchy after `position` has already been set to `.region(s.mapRegion)` — so the first frame uses the correct candidate-pin region.

## Acceptance Criteria

- [x] **AC1 — Rivers:** All river quizzes open showing the candidate-pin cluster, not a continental/global view
- [x] **AC2 — Mountains:** All mountain quizzes open showing the candidate-pin cluster
- [x] **AC3 — Seas:** All sea quizzes open showing the candidate-pin cluster  
- [x] **AC4 — Countries:** Behavior unchanged
- [x] **AC5 — Randomness preserved:** Pin spread and jitter unchanged
- [x] **AC6 — No correct-answer hint:** Camera center derived from all-candidate bounding box
- [x] **AC7 — Existing tests pass:** All MapQuizRegionHelperTests pass
- [x] **AC8 — New tests:** MapQuizSessionTests added verifying mapRegion non-zero span on init

## Delivered in PRs
- PR #205: Added MapQuizSessionTests (regression tests at session layer)
- PR #206: The actual view fix — `.automatic` → `.region(MKCoordinateRegion())` in both views
