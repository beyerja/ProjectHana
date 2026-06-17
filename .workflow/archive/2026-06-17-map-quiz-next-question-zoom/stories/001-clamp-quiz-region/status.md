status: done

Implemented in Hanahuac/Views/Quiz/MapQuiz/MapQuizRegionHelper.swift:
- Replaced quizRegion(for:correct:) with pure, testable QuizRegionMath.region(fittingPins:jitter:).
- Region now centers on the pin bounding-box center (not the correct feature).
- Span sized to fit all pins + ~18% margin, with a 30% vertical inset budget for the
  top prompt / bottom feedback banner overlays.
- Corrects for latitude compression (cos(lat)) and portrait map aspect ratio.
- Jitter preserved but clamped to the slack that keeps every pin inside the visible rect.
- Degenerate cases (empty / single / coincident pins) handled via minSpanDegrees.
- makeQuizAnnotations signature unchanged → both MapQuizSession (MapQuizView) and
  MapLearningSession (MapLearningQuizView) covered with no call-site changes.

Tests (HanahuacTests/MapQuizRegionHelperTests.swift): replaced two old-behavior tests
(center-offset-from-correct, 20° floor) with new-contract tests; added 8 containment /
clamp / aspect / latitude / degenerate tests. Full suite: TEST SUCCEEDED; region suite
13/13 pass. just lint-swift clean.
