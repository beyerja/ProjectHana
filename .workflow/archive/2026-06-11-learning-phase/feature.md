# Feature: Learning Phase Before SM-2

## Goal
Before cards enter the spaced-repetition schedule, they must first pass through a learning phase: an active set of up to 10 cards is presented repeatedly until each card is answered correctly 3 times in a row, at which point it graduates into the normal SM-2 queue and a new card is pulled in to replace it.

## What is NOT currently implemented
- No consecutive-correct tracking per card
- `dueCards()` returns all 442 seeded cards immediately (all start with `nextReviewDate = .now`)
- No active-set management; sessions step linearly through all due cards
- No concept of "new" vs "reviewing"

## Design

### Model changes (`ReviewCard`)
- Add `consecutiveCorrect: Int = 0` — counts consecutive correct answers in the learning phase; resets to 0 on wrong answer
- Add `hasGraduated: Bool = false` — set to `true` once the card exits the learning phase; never reverts

### CardStore changes
- `dueCards(for:)` — add `hasGraduated == true` filter so only graduated cards appear in SM-2 review
- Add `newCards(for:) -> [ReviewCard]` — returns `hasGraduated == false` cards, stable order
- Add `ensureGraduationConsistency()` — called once on init; sets `hasGraduated = true` for any card with `repetitionCount > 0 || intervalDays > 1` (handles existing users after update)

### LearningSession (new)
- `activeSet: [ReviewCard]` — up to 10 cards currently being drilled
- `pendingPool: [ReviewCard]` — remaining new cards not yet in the active set
- On **correct**: `card.consecutiveCorrect += 1`; if `>= 3` → graduate (set `hasGraduated = true`, apply SM2 with quality 4 for initial schedule); remove from active set, pull next from pool
- On **wrong**: `card.consecutiveCorrect = 0`; card stays in active set (reinserted at a random later position)
- Session ends when active set empties (all cards graduated or pool exhausted)

### UI
- `LearningQuizView` — MCQ format, driven by `LearningSession`; shows progress ("X / Y graduated"), loops within the active set
- `HomeView` — new "Learn" section showing new-card count per category; "Start Learning" button routes to `LearningQuizView`

### Quiz format for learning
MCQ is used for all categories in the learning phase — it's the most accessible format for first exposure. The existing MCQ question generators are reused.

### Migration
- `hasGraduated` defaults to `false` in SwiftData (lightweight migration: new field with default)
- `ensureGraduationConsistency()` auto-graduates cards that have `repetitionCount > 0` so existing users don't lose their progress

## Acceptance criteria
- [x] New cards do NOT appear in `dueCards()` — `dueCards()` only returns graduated cards
- [x] `newCards(for:)` returns all ungraduated cards for a category
- [x] A learning session starts with up to 10 new cards; when one graduates a new card is pulled in
- [x] Wrong answer resets `consecutiveCorrect` to 0 and keeps the card in the active set
- [x] After 3 consecutive correct answers, `hasGraduated` is set to `true` and the card is scheduled by SM-2
- [x] HomeView shows the count of new (unlearned) cards and a route to the learning session
- [x] Existing cards with `repetitionCount > 0` are auto-graduated on first launch after update
- [x] All existing tests pass; new unit tests cover graduation logic, reset logic, and active-set refill
