# Story 002: Map Learning Session (Graduation Mechanic)

## Title
Add a map-quiz learning session with the 3-consecutive-correct graduation mechanic

## Goal
Create a new `MapLearningSession` class (or extend `MapQuizSession`) that implements the same streak-based graduation logic as `LearningSession` — correct answer increments `consecutiveCorrect`, wrong answer resets it to 0, and 3 in a row marks `hasGraduated = true` and schedules via SM-2. This is the session model backing the map learning path for new country cards.

## Background
- `MapQuizSession.advance()` currently applies SM-2 one-and-done with no streak tracking.
- `LearningSession` has the reference implementation: `recordCorrect()` / `recordWrong()` with `consecutiveCorrect` and `hasGraduated`.
- The existing `MapQuizSession` must **not** be modified in a way that breaks the Pending/due-cards review path.
- `ReviewCard.consecutiveCorrect` and `ReviewCard.hasGraduated` already exist.

## Acceptance Criteria
- [ ] A new session type (`MapLearningSession` or equivalent) exists that wraps a set of new-cards and exposes `current`, `recordCorrect()`, `recordWrong()`, `isFinished`, `graduatedCount`.
- [ ] `recordCorrect()` increments `card.consecutiveCorrect`; when it reaches 3, `hasGraduated` is set to `true`, SM-2 is applied (quality 4), and the card is removed from the active set (with pool refill if available — mirroring `LearningSession` behavior).
- [ ] `recordWrong()` resets `card.consecutiveCorrect` to 0 and reinserts the card later in the queue (same logic as `LearningSession.recordWrong()`).
- [ ] The existing `MapQuizSession` (used by the Pending tile) is unmodified / unbroken.
- [ ] The session also exposes map-quiz UI data: `currentCountry`, `annotationCountries`, `mapRegion`, `answerState`, and `handleTap(countryID:)` — delegating map logic to a shared helper or by composition.
- [ ] Unit tests cover: 3-streak graduates, wrong resets streak, pool refill after graduation, session finishes when all graduate.
