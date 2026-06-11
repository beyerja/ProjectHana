# Story 010 — CategoryDetailView

## Title
CategoryDetailView: two-tile "New / Pending" entry point per category

## Goal
Create a new SwiftUI view, `CategoryDetailView`, scoped to a single category, that displays the count of unstarted cards ("New: N") and the count of due/in-progress cards ("Pending: N") as two side-by-side tappable tiles. The counts must derive reactively from SwiftData and update whenever cards are learned or reviewed. The view must include a back-navigation affordance but is not yet wired into HomeView (that is covered by story 011).

## Acceptance Criteria
- [ ] `CategoryDetailView` accepts a category value and displays two tiles: "New: N" and "Pending: N".
- [ ] "New" count = cards in the category with no review history (never started).
- [ ] "Pending" count = cards in the category that are due or currently in the active-10 learning loop (started but not graduated, or graduated and now due for review).
- [ ] Both counts update reactively via `@Query` or equivalent SwiftData observation — no manual refresh required.
- [ ] Tapping "New: N" navigates to `LearningQuizView` for the category (active-10 loop with 3-in-a-row graduation).
- [ ] Tapping "Pending: N" for Rivers, Mountains, or Seas navigates to `MultipleChoiceQuizView` for that category.
- [ ] Tapping "Pending: N" for Countries first navigates to `QuizModePickerView`, which then routes to Map or MCQ quiz as it does today.
- [ ] A standard SwiftUI back-navigation affordance (NavigationStack back button or equivalent) returns the user to the caller.
- [ ] No changes are made to `LearningQuizView`, `MultipleChoiceQuizView`, `MapQuizView`, or `QuizModePickerView`.
- [ ] The view compiles and can be previewed in Xcode with stubbed/preview data.

## Notes
- Use the existing SwiftData model; no schema migrations.
- QuizModePickerView for Countries is only reachable via the Pending tile — not exposed elsewhere.
- Active-10 loop logic lives in `LearningQuizView`; this story only passes the correct category parameter.
