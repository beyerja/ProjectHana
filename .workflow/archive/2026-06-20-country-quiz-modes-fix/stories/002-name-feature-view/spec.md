# Story 002 — Name-that-feature map-pin view

## Title
Map-pin "Name that feature" quiz view (type the name of the pinned feature)

## Goal
Build the SwiftUI view for the map-pin "Name that feature" quiz: show the current feature pinned on the
map (reusing the same pin/region machinery as the map-tap quiz) and a text field where the user types
the feature's name. Wire it to the session logic from story 001 for both the pending and new piles,
including SM-2 scheduling, graduation, progress-snapshot recording, and the completion/summary screen.

## Acceptance Criteria
- [ ] A new view (e.g. `NameFeatureQuizView`) renders a `Map` centered on the current feature's
      `pinCoordinate` with that feature's pin shown (reuse `MapFeaturePinView` and the existing
      region/annotation helpers), plus a focused text input and Check button. The feature's name is NOT
      shown until after the answer is submitted.
- [ ] Submitting an answer uses the story-001 matching (trimmed, case-insensitive, localized primary +
      English fallback). Correct/incorrect feedback reveals the correct localized feature name; a wrong
      answer reveals the pin label too.
- [ ] Pending pile: drives the SM-2 due session — quality 4/1, advances through the deck, shows the
      existing `QuizSummaryView` on finish, and calls `ProgressStatsStore.recordSnapshot` on each
      advance (no-op when no stats store is injected, matching `CapitalQuizView`).
- [ ] New pile: drives the learning variant (3-consecutive-correct graduation + active set, persisting
      via `UserDefaultsActiveSetStore` when a category is supplied), showing the same graduation/streak
      progress and completion screen style as the other learning views.
- [ ] Empty/nothing-due state is handled with a `ContentUnavailableView` consistent with the other
      quiz views; localized strings are used throughout (placeholder added as needed — see story 003 for
      the full string set, but any strings this view introduces must have keys wired so the build/tests
      that assert key coverage pass).
- [ ] Map gestures behave consistently with the existing map quiz (pinch handling, scene-phase reset)
      to the extent they apply to a single-pin view.
- [ ] SwiftUI previews compile. Existing tests still pass; any view-level logic that can be unit-tested
      without UIKit is covered or already covered by story 001.

## Notes
This story may reference the routing enum cases that story 003 finalizes; keep the view self-contained
(constructed from `newCards`/`category` or `category` for pending, like `MapLearningQuizView` /
`MapQuizView`) so it compiles independently and 003 only wires navigation to it.
