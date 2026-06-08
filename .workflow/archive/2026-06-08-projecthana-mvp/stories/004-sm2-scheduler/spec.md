# Story 004: SM-2 Spaced Repetition Scheduler

## Title
Implement the SM-2 algorithm as a pure Swift module with full unit-test coverage

## Goal
Provide a correct, dependency-free SM-2 scheduler that the quiz engine calls after each
answer to update card intervals.

## Acceptance Criteria
- [ ] `SM2Scheduler` is a pure (no side effects) Swift struct/enum with a single method:
      `func schedule(card: ReviewCard, quality: Int) -> SM2Result` where `quality` is 0–5
- [ ] `SM2Result` contains: `newRepetitionCount`, `newEaseFactor`, `newIntervalDays`,
      `nextReviewDate`
- [ ] Algorithm correctness:
      - quality < 3 → reset repetitionCount to 0, interval to 1 day (restart learning)
      - repetitionCount == 0 → interval = 1 day
      - repetitionCount == 1 → interval = 6 days
      - repetitionCount >= 2 → interval = round(previousInterval × easeFactor)
      - easeFactor updated by: EF' = EF + (0.1 − (5 − q) × (0.08 + (5 − q) × 0.02))
      - minimum easeFactor clamped to 1.3
- [ ] Unit tests cover: first review (quality 4), second review, forgetting (quality 1),
      ease factor floor, quality 5 streak of 5 cards, boundary quality values 0 and 5
- [ ] At least 15 distinct unit test cases for the scheduler
- [ ] `SM2Scheduler` has zero imports beyond `Foundation` (for `Date`/`Calendar`)
