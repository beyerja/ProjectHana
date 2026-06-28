# Feature: map-quiz-wrong-answer-zoom

## Goal

After a user taps the wrong pin in a map quiz, automatically pan and zoom the map so
that both the incorrectly-tapped pin (red) and the correct pin (green) are
simultaneously visible, regardless of where the user had manually scrolled or zoomed
before tapping.

## Root Cause (verified in source)

`MapQuizView` owns `@State private var position: MapCameraPosition`
(`MapQuizView.swift`, line 28). When `session.answerState` transitions to
`.incorrect(tappedID:correctID:)` the 2-second feedback window begins, but
`position` is never updated during this window — it stays wherever the camera was
when the user tapped. If the user had manually panned or zoomed before answering,
the correct pin (now highlighted green by `mapPinState`) can be entirely off-screen.

The fix is confined to `MapQuizView.swift`: in the existing
`.onChange(of: session.answerState)` handler (lines 107–133), when the new state is
`.incorrect`, derive a new `MKCoordinateRegion` that fits both pins (tapped and
correct) via the existing `QuizRegionMath.region(fittingPins:jitter:)` helper, then
animate `position` to that region immediately — before the advance delay fires.

No changes are needed to `MapQuizSession`, `QuizRegionMath`, or `makeQuizAnnotations`.
The `MapCameraBounds` passed to `Map(bounds:)` already uses a 16× headroom
(`cameraDistanceHeadroom`), so the zoomed-out two-pin view will never be blocked
by an overly tight camera bound.

## Acceptance Criteria

- [ ] AC1: When the user taps the wrong pin, the map animates (pan + zoom) so that
  BOTH the incorrectly-tapped pin and the correct pin are simultaneously visible
  within the banner-free viewport — even if the user had manually scrolled far
  away or zoomed in tightly before tapping.

- [ ] AC2: The two-pin framing region is computed with the same
  `QuizRegionMath.region(fittingPins:jitter:none)` helper already used for
  normal question setup, with `jitter: .none` (deterministic, no randomness during
  feedback).

- [ ] AC3: The transition is animated (uses `withAnimation`) so it is not a jarring
  jump, consistent with the existing animated advance on correct answers.

- [ ] AC4: When the user taps the CORRECT pin, the map position is NOT changed
  during the feedback window — behaviour is unchanged from today for correct answers.

- [ ] AC5: After the 2-second feedback window the map advances to the next question
  and the camera is set to `session.mapRegion` for the new question, exactly as
  today (lines 128–129 of `MapQuizView.swift`). The wrong-answer re-centering
  does not interfere with this existing logic.

- [ ] AC6: The feature applies to every quiz category (countries, rivers, mountains,
  seas) — all share the same `MapQuizView` code path, so no per-category
  branching is needed.

- [ ] AC7: A unit test in `MapQuizRegionHelperTests` (or a new parallel test file)
  asserts that `QuizRegionMath.region(fittingPins:jitter:none)` called with exactly
  two coordinates (the tapped and correct pin) produces a region whose
  `visibleContentRect` contains both pins, for a representative pair of coordinates
  that are far apart (e.g. 25°+ apart, a plausible worst case).

- [ ] AC8: The `MapCameraBounds` passed to `Map(bounds:)` must not block the
  two-pin zoom-out view. Verify that the existing `cameraDistanceHeadroom = 16`
  cap is large enough to accommodate two pins separated by at most the full
  candidate-pin bounding box (which the bounds is already derived from). This is
  a static assertion in the existing `testCameraDistanceCapAllowsContinentalZoomOut`
  test and needs no new test, but should be confirmed during implementation.

## Constraints

- Must not change `MapQuizSession`, `QuizRegionMath`, or `makeQuizAnnotations` —
  the region math is already correct and well-tested; the fix is view-layer only.
- The `jitter` parameter for the two-pin region must be `.none` — the feedback
  state needs a deterministic, stable camera position.
- Must not modify `MapCameraBounds` during the feedback window; the existing bounds
  derived from the full candidate-pin region remain in effect. The bounds already
  use a 16× headroom, which is sufficient for any two-pin sub-region.
- The animation must use `withAnimation` (consistent with the existing correct-answer
  advance at line 128 of `MapQuizView.swift`).
- No UI changes to the feedback banner, pin appearance, or any other quiz element.

## Out of Scope

- Changing behaviour on correct answers.
- Changing the `MapLearningQuizView` — it has a different interaction model
  (tap to reveal rather than tap to answer) and does not have a wrong-answer
  feedback state.
- Adding a "zoom to show both pins" button the user can tap manually.
- Modifying pin count, neighbour selection, or anything in `makeQuizAnnotations`.
- Accessibility announcements beyond what already exists for the feedback banner.

## Technical Notes

### Key files

- `Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift` — the only file that needs
  changing. The `.onChange(of: session.answerState)` block (lines 107–133) is
  the insertion point.
- `Hanahuac/Views/Quiz/MapQuiz/MapQuizRegionHelper.swift` — `QuizRegionMath` and
  `makeQuizAnnotations` are already correct; no changes needed.
- `HanahuacTests/MapQuizRegionHelperTests.swift` — add AC7 test here.

### Implementation sketch

In `MapQuizView.quizBody`, inside `.onChange(of: session.answerState)`:

```swift
.onChange(of: session.answerState) { _, newState in
    // NEW: re-center on both pins when a wrong answer is given.
    if case let .incorrect(tappedID, correctID) = newState {
        let tapped  = session.annotationFeatures.first { $0.id == tappedID }
        let correct = session.annotationFeatures.first { $0.id == correctID }
        if let t = tapped, let c = correct {
            let pins = [(t.quizLat, t.quizLon), (c.quizLat, c.quizLon)]
            withAnimation {
                position = .region(QuizRegionMath.region(fittingPins: pins, jitter: .none))
            }
        }
    }
    // EXISTING: guard and delay logic follows unchanged.
    guard newState != .unanswered, !isAdvancing else { return }
    ...
}
```

The two-pin region will always be a sub-region of the initial candidate-pin region
(since both pins were visible in the initial framing), so the existing
`MapCameraBounds` (built from the full candidate-pin bounding box) will always
allow this zoom level.
