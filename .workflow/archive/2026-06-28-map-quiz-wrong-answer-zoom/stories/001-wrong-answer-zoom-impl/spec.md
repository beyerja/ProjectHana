# Story 001: Wrong-answer zoom implementation

## Goal

When a player taps the wrong pin in a map quiz, animate the map camera so that both
the incorrectly-tapped pin (red) and the correct pin (green) are simultaneously
visible — regardless of where the user had manually scrolled or zoomed before tapping.

## Scope

Single file change: `Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift`.

Inside the existing `.onChange(of: session.answerState)` handler (lines 107–133), add
a branch that fires when the new state is `.incorrect(tappedID:correctID:)`. The
branch:

1. Looks up both annotation features by ID in `session.annotationFeatures`.
2. Derives a two-pin bounding region via the existing
   `QuizRegionMath.region(fittingPins:jitter:)` helper with `jitter: .none`.
3. Animates `position` to that region with `withAnimation { position = .region(…) }`.

No changes to `MapQuizSession`, `QuizRegionMath`, `makeQuizAnnotations`, the feedback
banner, pin appearance, or `MapCameraBounds`.

## Acceptance Criteria

- AC1: When the user taps the wrong pin, the map animates (pan + zoom) so that BOTH
  the incorrectly-tapped pin and the correct pin are simultaneously visible within the
  banner-free viewport, even if the user had manually scrolled far away or zoomed in
  tightly before tapping.

- AC2: The two-pin framing region is computed with
  `QuizRegionMath.region(fittingPins:jitter:.none)` — deterministic, no randomness
  during feedback.

- AC3: The transition uses `withAnimation`, consistent with the existing animated
  advance on correct answers.

- AC4: When the user taps the CORRECT pin, `position` is NOT changed during the
  feedback window — behaviour is unchanged from today for correct answers.

- AC5: After the 2-second feedback window the map advances to the next question and
  the camera is reset to `session.mapRegion` exactly as today (lines 128–129). The
  wrong-answer re-centering does not interfere with this existing logic.

- AC6: The feature applies to every quiz category (countries, rivers, mountains, seas)
  — all share the same `MapQuizView` code path; no per-category branching is needed.

- AC8: The existing `testCameraDistanceCapAllowsContinentalZoomOut` test continues to
  pass, confirming the `cameraDistanceHeadroom = 16` cap is sufficient to accommodate
  the two-pin zoom-out view.
