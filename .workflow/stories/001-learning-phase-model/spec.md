# Story 001: Learning Phase — Model and Session Logic

## Goal
Add the data model and session logic for the learning phase, with full unit-test coverage.

## Tasks
- [ ] Add `consecutiveCorrect: Int` and `hasGraduated: Bool` to `ReviewCard`
- [ ] Add `ensureGraduationConsistency()` to `CardStore` and call it from `init`; update `dueCards(for:)` to filter `hasGraduated == true`; add `newCards(for:) -> [ReviewCard]`
- [ ] Create `LearningSession.swift` — manages active set (≤ 10), consecutive-correct tracking, graduation (set `hasGraduated = true`, apply SM-2 quality 4), wrong-answer reset (consecutiveCorrect = 0, reinsert card)
- [ ] Add unit tests in `LearningTests.swift` covering: graduation at 3 correct, reset on wrong, active-set refill from pool, session completion, `dueCards` exclusion of new cards, `newCards` return

## Acceptance criteria
- `ReviewCard` compiles with both new fields defaulting correctly
- `dueCards()` returns only `hasGraduated == true` cards
- `newCards(for:)` returns only `hasGraduated == false` cards
- A `LearningSession` with 1 active card graduates it after exactly 3 correct advances
- A wrong answer resets the streak and the card remains in the active set
- When a card graduates and the pool is non-empty, the active set grows back to capacity
- All existing tests continue to pass
