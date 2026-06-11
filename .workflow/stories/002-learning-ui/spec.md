# Story 002: Learning Phase — UI

## Goal
Wire `LearningSession` into a view and expose it from `HomeView`.

## Tasks
- [ ] Create `LearningQuizView.swift` — MCQ-format view driven by `LearningSession`; shows prompt + 4 options; correct/incorrect feedback; progress header "X / Y graduated"; auto-advances; shows completion summary when active set is empty
- [ ] Update `HomeView` to show a "Learn" section with per-category new-card count; a "Start Learning" button that launches `LearningQuizView` for all new cards across all categories (or per-category if tapped from a category button)
- [ ] Wire `LearningQuizView` into pbxproj

## Acceptance criteria
- Launching the learning session shows MCQ questions for ungraduated cards
- Progress header correctly reflects how many cards have graduated in the current session
- Wrong-answer feedback shows the correct answer; card reappears later in the session
- When all active cards graduate (or pool exhausted), a summary screen is shown
- HomeView "Learn" section updates new-card count reactively
- Build and tests pass; macOS build clean
