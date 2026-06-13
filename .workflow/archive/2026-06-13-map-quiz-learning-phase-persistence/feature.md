# Feature: Map Quiz Learning Phase + Session Card Persistence

## Goal

Two related correctness/UX fixes to the learning model introduced in the learning-phase feature:

1. **Map quiz in the learning phase** — The map quiz was always an available mode for country cards, but the learning phase (New cards) is currently MCQ-only. The map quiz must also be a valid learning path so users can learn new country cards via the map. Furthermore, the map quiz session must apply the same 3-consecutive-correct graduation mechanic that `LearningSession` uses, rather than the one-and-done SM-2 scheduling currently used in `MapQuizSession`.

2. **Stable active-set selection** — `LearningSession` re-shuffles and picks a new random 10 cards every time a `LearningQuizView` is created. If the user dismisses mid-session and returns, they get a different 10 cards. The selection of which 10 (or fewer) cards form the active set for a category must be persisted so it stays the same until those cards graduate out of it.

## Current State (from codebase exploration)

- `CategoryDetailView` routes the "New" tile for all categories to `LearningQuizView`, which uses MCQ questions only.
- `MapQuizView` / `MapQuizSession` is only reachable from the "Pending" tile via `QuizModePickerView` (for countries with due SM-2 cards). It is completely absent from the learning/New path.
- `MapQuizSession.advance()` calls `SM2Scheduler.apply()` directly (one-and-done), with no 3-streak graduation mechanic.
- `LearningSession` selects its active set in `init` via `newCards.shuffled().prefix(10)` with no persistence — every construction produces a different 10.
- `ReviewCard` already carries `consecutiveCorrect` and `hasGraduated` fields.

## Acceptance Criteria

- [ ] The "New" tile for the Countries category offers the user a choice between the map quiz mode and the MCQ mode to learn new cards.
- [ ] When a user picks "Map" in the learning path, they are presented with a map quiz that uses the 3-consecutive-correct graduation mechanic (same as `LearningSession`): a card only graduates (marks `hasGraduated = true` and schedules via SM-2) after it has been answered correctly 3 times in a row; a wrong answer resets `consecutiveCorrect` to 0 and reinserts the card later.
- [ ] When a user picks "MCQ" in the learning path, the existing `LearningQuizView` / `LearningSession` behavior is unchanged.
- [ ] The active set of up to 10 cards chosen from a category's New pile is persisted across app launches and session re-entries (for the same category). Re-opening the learning session for that category always shows the same active set until cards graduate out.
- [ ] When all cards in the active set graduate, the session finishes and up to 10 more ungraduated cards are drawn into the new active set (normal pool-refill already works intra-session; this requires the persisted selection to be updated too).
- [ ] The graduation mechanic in the map learning path resets `consecutiveCorrect` to 0 on wrong answer and increments it on correct answer, identical to the MCQ learning path.
- [ ] Existing `LearningTests` continue to pass. New unit tests cover: map-quiz graduation mechanic (3-streak graduates, wrong resets), and active-set persistence (same IDs returned across session constructions).
- [ ] The app builds without warnings in CI.

## Constraints

- Use SwiftData / `UserDefaults` for persistence; do not add new third-party dependencies.
- Persist the active-set selection per category (at minimum `.country`; the other categories already go through `LearningQuizView` so they benefit from the same fix).
- The map quiz learning path is only meaningful for the `.country` category (map quiz only covers countries). Other categories keep MCQ.
- Preserve the existing `MapQuizView` / `MapQuizSession` for the Pending/due-cards path — do not break the SM-2-scheduled review quiz.

## Out of Scope

- Redesigning the map quiz UI or adding new map features.
- Changing the quiz mode picker for the Pending tile.
- iCloud sync.
- Any UI/UX redesign.
