# Log — Fix map-quiz centering for river, mountain, and sea quizzes
2026-06-21T14:09:07 break-tasks: DONE, 4 tasks

## 2026-06-21 implement-story — confirmed root cause (task 001)

Traced the camera path in both `MapQuizView.swift` and `MapLearningQuizView.swift`.

Ruled OUT (confirmed in code, as required):
- Region math bug: `QuizRegionMath.region(fittingPins:)` centers on the candidate-pin
  bounding-box center (independent of the answer), fits all pins with margin/aspect/banner
  insets, and clamps jitter. Covered by extensive passing tests in
  `MapQuizRegionHelperTests`. Not the bug.
- Lat/lon swap: pins use `pinCoordinate` consistently for BOTH the `Annotation`
  coordinates and the region pins (`makeQuizAnnotations` maps `quizLat`/`quizLon`,
  which are `pinCoordinate.latitude`/`.longitude`). No swap.
- Pin-coordinate / bundled-JSON data error: sane (sea/mountain use explicit lat/lon,
  river uses path-midpoint vertex). Not the bug.

CONFIRMED mechanism (overlay extent re-frames the camera):
The `Map` was created as `Map(position: $position)` with NO camera bounds. `position`
is seeded to `.region(session.mapRegion)` (the candidate-pin region), but the Map's
content builder also emits `featureOverlays(for:answerState:)`, which renders, per
candidate feature:
- rivers: the FULL source→mouth `linePath` polyline (the whole course of the river), and
- seas / mountains: large `borderRings` polygons (whole marine basin / mountain range).
These overlays extend FAR beyond the candidate-pin bounding box. With a bare
`position` binding and no `bounds`, SwiftUI's `Map` reconciles the requested region
against the natural extent of its content and frames the union — i.e. the giant overlay
geometry — pushing the candidate pins off-screen ("opposite side of the map"). Country
quizzes look correct because `Country.borderRings` are small, local polygons near the
pins, so the content union ≈ the pin bounding box. River has no `borderRings` but a
full-course `linePath`; sea/mountain have huge `borderRings`. This explains exactly why
river/mountain/sea mis-center while country does not.

Fix (task 002, shared single path): added `QuizRegionMath.cameraDistance(for:)` and
`QuizRegionMath.cameraBounds(for:)`, and passed `bounds:` into BOTH views'
`Map(position:bounds:)`. The bounds (a) constrain the camera CENTER to the candidate-pin
`mapRegion` and (b) cap `maximumDistance` to the metres that frame the region's span
(with a small 1.15 headroom) — far below the overlay extent — so the overlay geometry can
never zoom/pan the camera away from the pins. Framing still derives purely from
`QuizRegionMath.region(fittingPins:)` (bounding box of all candidate pins, independent of
the answer); the correct pin is not centered or distinguished. One code path serves all
four categories and both views; no per-category branch.

Regression coverage (task 003): added three tests to `MapQuizRegionHelperTests` —
`testCameraDistanceCapStaysAtCandidatePinScaleNotOverlayScale` (cap stays at pin scale,
far below a 60° overlay extent), `testCameraDistanceFramesEveryCandidatePin` (cap still
covers the whole framed span so no pin clips), and
`testCameraBoundsCenterRegionIsBoundingBoxNotCorrectPin` (centre is the bounding box, not
the answer pin). `MapCameraBounds` exposes no readable properties, so the tests assert on
`QuizRegionMath.cameraDistance(for:)` (the value feeding the cap). Country tests stay green.

`just install` skipped: no Swift files added/removed (no `just generate` needed); the only
new API is `Map(position:bounds:)` / `MapCameraBounds` from MapKit-SwiftUI (already
available, no new dependency) and it compiled+ran clean under `just test`.

2026-06-21 implement-story: DONE — tasks 001–004 (root cause confirmed + documented,
shared camera-bounds fix in both views, 3 regression tests added), lint + test green.

2026-06-21 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/143

2026-06-21 independent-review: APPROVED — shared camera-bounds fix is correct and at the right altitude; all ACs met, CI green. Formal bot APPROVE submitted via scripts/gh-review-bot.sh (wrapper present, not skipped). Two non-blocking inline nits posted: tautological test assertions (keep cap < overlayExtentMeters) and maximumDistance-vs-ground-span units approximation.

2026-06-21T12:29:30Z merge-pr: DONE

2026-06-21 verify-story: DONE — verified on feat/map-quiz-zoom-fix (= merged PR #143, 19d978a).
All 7 acceptance criteria satisfied:
1. Root cause confirmed in code & documented: bare `Map(position:)` with no bounds let the
   content union (full-course river `linePath` / large sea-mountain `borderRings`) re-frame the
   camera past the candidate-pin region; country borders are small so its union ≈ pin bbox. Not
   the region math, not a lat/lon swap, not a coordinate-data bug (all ruled out in code).
2. Shared `QuizRegionMath.cameraBounds(for: session.mapRegion)` wired into BOTH views at
   MapQuizView.swift:59 and MapLearningQuizView.swift:59 — frames all candidate pins for all
   four categories.
3. Framing derives from `QuizRegionMath.region(fittingPins:)` bounding-box center, independent
   of the answer; correct pin not centered/distinguished (testCameraBoundsCenterRegionIs
   BoundingBoxNotCorrectPin, testRegionCenterDerivedFromBoundingBoxNotCorrectFeature pass).
4. Zoom unchanged except the maximumDistance cap that prevents overlay-driven zoom-out.
5. Single shared path in QuizRegionMath; no per-category branch.
6. Regression tests added in MapQuizRegionHelperTests (testCameraDistanceCapStaysAtCandidate
   PinScaleNotOverlayScale, testCameraDistanceFramesEveryCandidatePin, testCameraBoundsCenter
   RegionIsBoundingBoxNotCorrectPin) — all pass; country tests stay green.
7. `just lint` passed (all linters) and `just test` passed (** TEST SUCCEEDED **).