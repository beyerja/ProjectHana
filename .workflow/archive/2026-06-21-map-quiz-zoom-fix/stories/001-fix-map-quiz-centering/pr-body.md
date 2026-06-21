## Goal

River, mountain, and sea map quizzes opened panned to the wrong location — the candidate pins (including the correct answer) landed off-screen near "the opposite side of the map", forcing manual scrolling. Country quizzes framed correctly and served as the control. This fixes the framing for **all four categories** (river, mountain, sea, country) in **both** `MapQuizView` and `MapLearningQuizView`, so every question opens with all candidate pins visible.

## Confirmed root cause

The `Map` was created as `Map(position: $position)` with **no camera bounds**. `position` was seeded to `.region(session.mapRegion)` (the candidate-pin region), but the Map's content builder also emits `featureOverlays(for:answerState:)`, which renders, per candidate feature:

- rivers: the FULL source→mouth `linePath` polyline (the whole course of the river), and
- seas / mountains: large `borderRings` polygons (whole marine basin / mountain range).

These overlays extend far beyond the candidate-pin bounding box. With a bare `position` binding and no `bounds`, SwiftUI's `Map` reconciles the requested region against the natural extent of its content and frames the union — i.e. the giant overlay geometry — pushing the candidate pins off-screen. Country quizzes looked correct because `Country.borderRings` are small, local polygons near the pins, so the content union ≈ the pin bounding box.

Ruled out (confirmed in code, not assumed): the region math (`QuizRegionMath.region(fittingPins:)` already centers on the candidate-pin bounding box independent of the answer), a lat/lon swap, and a pin-coordinate / bundled-JSON data error.

## Changes

- Added `QuizRegionMath.cameraDistance(for:)` and `QuizRegionMath.cameraBounds(for:)` to `MapQuizRegionHelper.swift` — the bounds constrain the camera **center** to the candidate-pin `mapRegion` and cap `maximumDistance` to the metres that frame the region's span (with a small 1.15 headroom), far below the overlay extent.
- Passed `bounds:` into `Map(position:bounds:)` in **both** `MapQuizView.swift` and `MapLearningQuizView.swift`, so the overlay geometry can never zoom or pan the camera away from the pins.
- Framing still derives purely from `QuizRegionMath.region(fittingPins:)` (bounding box of all candidate pins, independent of which pin is the answer); the correct pin is **not** centered, zoomed-to, or otherwise distinguished.
- One shared code path serves all four categories and both views — no per-category centering branch.
- Added 3 regression tests to `MapQuizRegionHelperTests`: cap stays at pin scale (not overlay scale), cap still covers the whole framed span so no pin clips, and the bounds center is the bounding box rather than the correct pin.

## Test plan

- [ ] `just lint` passes
- [ ] `just test` passes (including the 3 new regression tests)
- [ ] CI green on the PR
- [ ] River, mountain, sea, and country quizzes each open with all candidate pins framed and no manual scrolling, in both `MapQuizView` and `MapLearningQuizView`
- [ ] Correct pin is not centered or visually distinguished versus distractors at question open
