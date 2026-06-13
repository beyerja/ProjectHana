# Story 002 Log — Persist New Pile Cards

## Implementation

**Root cause**: `MapLearningSession.init` always shuffled `newCards` fresh, ignoring any persisted active set. It had no `category` or `store` parameters.

**Fix**:
1. Added `category: CardCategory?` and `store: ActiveSetStore?` to `MapLearningSession.init`, with a convenience `init(newCards:allCountries:)` for backwards compatibility with tests.
2. Mirrored `LearningSession`'s rehydration logic: on init, load stored IDs, filter out graduated cards, resume if any remain; otherwise clear and draw fresh.
3. Added persistence in `graduate()`: save updated active set IDs after each graduation, clear when empty.
4. Updated `MapLearningQuizView` to accept `category: CardCategory?` and create `UserDefaultsActiveSetStore()` when a category is provided.
5. Updated the caller in `LearningModePickerView` to pass `category: .country`.
6. Added 5 new tests in `MapLearningTests.swift` covering the persistence behaviour.

**Files changed**:
- `ProjectHana/Views/Quiz/MapQuiz/MapLearningSession.swift`
- `ProjectHana/Views/Quiz/MapQuiz/MapLearningQuizView.swift`
- `ProjectHana/Views/Quiz/LearningModePickerView.swift`
- `ProjectHanaTests/MapLearningTests.swift`

## Status: DONE
