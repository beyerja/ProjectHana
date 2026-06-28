# Story 002: Unit test — two-pin region contains both pins

## Goal

Add a unit test asserting that `QuizRegionMath.region(fittingPins:jitter:.none)`,
when called with exactly two coordinates that are far apart (25°+ separation), returns
a region whose span contains both coordinates. This validates the helper behaves
correctly for the wrong-answer zoom use-case and guards against regressions.

## Scope

Single file addition/extension: `HanahuacTests/MapQuizRegionHelperTests.swift`.

Add one test method (e.g. `testTwoPinRegionContainsBothPins`) that:

1. Creates two representative lat/lon pairs separated by at least 25° in both lat and
   lon (e.g. Tokyo ~35°N 139°E and London ~51°N 0°E).
2. Calls `QuizRegionMath.region(fittingPins: [(35, 139), (51, 0)], jitter: .none)`.
3. Asserts the returned `MKCoordinateRegion` contains both coordinates — i.e. each
   coordinate lies within `center ± span/2` (with a small tolerance for floating
   point).

No production code changes in this story.

## Acceptance Criteria

- AC7: `testTwoPinRegionContainsBothPins` passes when `QuizRegionMath.region(
  fittingPins:jitter:)` is called with two far-apart pins and produces a region that
  visibly contains both coordinates.

- The test must compile and pass on its own (it depends only on `QuizRegionMath`,
  which is already complete and unchanged).

- All pre-existing tests in `MapQuizRegionHelperTests` continue to pass.
