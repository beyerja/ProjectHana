## Goal

When a player taps the wrong pin in a map quiz, animate the map camera so that both the incorrectly-tapped pin (red) and the correct pin (green) are simultaneously visible — regardless of where the user had manually scrolled or zoomed before tapping.

## Changes

- **`MapQuizView.swift`** — inside the existing `.onChange(of: session.answerState)` handler, adds a branch for `.incorrect(tappedID:correctID:)` that:
  1. Looks up both annotation features by ID in `session.annotationFeatures`
  2. Derives a two-pin bounding region via `QuizRegionMath.region(fittingPins:jitter:.none)` (deterministic, no randomness during feedback)
  3. Animates `position` to that region with `withAnimation { position = .region(…) }`, consistent with the existing animated advance on correct answers
- **`MapQuizSessionTests`** — adds a unit test asserting that the two-pin region computed by `QuizRegionMath.region(fittingPins:jitter:.none)` contains both pin coordinates within its visible rect

No changes to `MapQuizSession`, `QuizRegionMath`, `makeQuizAnnotations`, the feedback banner, pin appearance, or `MapCameraBounds`. The fix applies to all quiz categories (countries, rivers, mountains, seas) that share `MapQuizView`.

## Test Plan

- [ ] Build succeeds with no new warnings
- [ ] `testCameraDistanceCapAllowsContinentalZoomOut` continues to pass (confirms `cameraDistanceHeadroom = 16` cap accommodates the two-pin zoom-out)
- [ ] New unit test (`testTwoPinRegionContainsBothPins` or equivalent) passes, verifying the bounding region geometry
- [ ] Manual: tap the wrong pin — map animates to frame both the red (tapped) and green (correct) pins simultaneously
- [ ] Manual: tap the wrong pin after scrolling far away / zooming in tightly — camera still re-centers correctly
- [ ] Manual: tap the correct pin — `position` is NOT changed during feedback (behaviour unchanged)
- [ ] Manual: after the 2-second feedback window, map advances to the next question and camera resets to `session.mapRegion` as before
- [ ] All four quiz categories (countries, rivers, mountains, seas) exhibit the same behaviour
