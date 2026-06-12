# Story 011 — HomeView Navigation Rewire

## Title
HomeView cleanup: remove Due/New panels, wire category grid to CategoryDetailView

## Goal
Rewire `HomeView` so that tapping any category tile navigates to `CategoryDetailView` (built in story 010). Remove the "Due today" hero number and the standalone "New cards" panel from `HomeView`, leaving the 2×2 category grid as the sole primary entry point. No quiz views change; this story is purely navigation plumbing and HomeView layout cleanup.

## Acceptance Criteria
- [ ] The "Due today" hero number is removed from `HomeView`.
- [ ] The standalone "New cards" panel is removed from `HomeView`.
- [ ] The 2×2 category grid remains on `HomeView` as the primary UI element.
- [ ] Tapping any category tile in the grid pushes `CategoryDetailView` for that category onto the navigation stack.
- [ ] Navigation uses `NavigationStack` / `NavigationLink` (or the project's existing navigation pattern); no modal sheet unless the project already uses sheets for this level.
- [ ] No regressions: `LearningQuizView`, `MultipleChoiceQuizView`, `MapQuizView`, and `QuizModePickerView` continue to behave exactly as before.
- [ ] The app builds without warnings introduced by this story and passes any existing unit/UI tests.

## Notes
- Depends on story 010 (`CategoryDetailView`) being merged first, or developed in the same branch.
- Only `HomeView` (and its direct subcomponents if any) should change; quiz views are out of scope.
- If the project uses a router/coordinator pattern rather than inline `NavigationLink`, follow that pattern.
