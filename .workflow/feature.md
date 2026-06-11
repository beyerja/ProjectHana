# Feature: Category Detail Screen with New/Pending Split

## Goal
Restructure HomeView navigation so that tapping a category shows a new CategoryDetailView with two tiles — "New: N" and "Pending: N" — giving users a clear entry point into either the active-10 learning loop (New) or the review quiz for already-learned cards (Pending). This replaces the current flat model where tapping a category goes directly into a quiz and the HomeView displays a mixed "Due today" hero + separate "New cards" panel.

## Acceptance Criteria
- [ ] HomeView retains the 2×2 category grid as the primary entry point; the "Due today" hero number and standalone "New cards" panel are removed or refactored away from HomeView.
- [ ] Tapping any category tile in the grid navigates to a new CategoryDetailView (or equivalent) scoped to that category.
- [ ] CategoryDetailView shows two side-by-side tiles: "New: N" (count of cards not yet started for that category) and "Pending: N" (count of cards due/in-progress for that category).
- [ ] Tapping "New: N" launches LearningQuizView for that category with the active-10 loop and 3-in-a-row graduation — this behaviour applies to all four categories (Countries, Rivers, Mountains, Seas).
- [ ] Tapping "Pending: N" launches the existing review quiz flow for that category: MCQ for Rivers, Mountains, and Seas; for Countries it first shows the existing QuizModePickerView (Map quiz vs MCQ) before entering the chosen quiz.
- [ ] The N counts in both tiles are accurate and update reactively when cards are learned or reviewed.
- [ ] CategoryDetailView has a back-navigation affordance returning the user to HomeView.
- [ ] No regressions in LearningQuizView, MultipleChoiceQuizView, or MapQuizView behaviour.

## Constraints
- SwiftUI + SwiftData stack (no new persistence frameworks).
- Must work on the existing data model; no schema migrations unless strictly necessary.
- QuizModePickerView for Countries is only accessible via the Pending path, not at the top level.
- Active-10 loop logic (including 3-in-a-row graduation) must be consistent across all four categories in the New path.
- No changes to the quiz views themselves — only navigation wiring changes.

## Out of Scope
- Adding new quiz categories beyond the existing four.
- Redesigning or reskinning LearningQuizView, MultipleChoiceQuizView, or MapQuizView.
- Changes to the SM-2 scheduling algorithm.
- Push notifications or background refresh of due counts.
- Any onboarding or tutorial flow.
