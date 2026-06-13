# Stories

## Story 001 — Fix Country Polygon Overlay on Map Quiz
- **Dir**: `.workflow/stories/001-fix-polygon-overlay`
- **Status**: done

**Problem**: After tapping a pin in the map quiz (both Pending and New/learning flows), the country area should highlight green (correct) or red (wrong) via `MapPolygon.foregroundStyle`. The implementation exists but never renders the color because SwiftUI's `Map` content builder (`@MapContentBuilder`) does not track `@Observable` changes — reading `session.answerState` inside the `Map` closure does not register an observation, so polygons always render with `.clear`.

**Fix**: Extract the `answerState` value into a local variable (or a dedicated `@State`/computed property) outside the `Map` closure so that SwiftUI's observation system tracks it and triggers a view update. Then pass that extracted value into the `Map` content builder so the `MapPolygon.foregroundStyle` color is computed from the tracked value.

**Files to change**:
- `ProjectHana/Views/Quiz/MapQuiz/MapQuizView.swift`
- `ProjectHana/Views/Quiz/MapQuiz/MapLearningQuizView.swift`

**Acceptance criteria**:
- After tapping the correct pin, the correct country's polygon shows green fill (~35% opacity).
- After tapping the wrong pin, the wrong country shows red fill and the correct country shows green fill.
- On advance to the next question, all fills clear.
- Both `MapQuizView` (Pending) and `MapLearningQuizView` (New/learning) are fixed.

---

## Story 002 — Persist "New" Pile Card Selection Across App Restarts
- **Dir**: `.workflow/stories/002-fix-new-pile-persistence`
- **Status**: done

**Problem**: `MapLearningSession` always shuffles `newCards` fresh on every init. It does not use `ActiveSetStore`, so every app launch picks a random new set of 10 country cards. Compare with `LearningSession` (used for rivers/mountains/seas) which correctly uses `UserDefaultsActiveSetStore` to persist and restore the active set.

**Fix**:
1. Add `category: CardCategory?` and `store: ActiveSetStore?` parameters to `MapLearningSession.init`, mirroring the persistence logic already in `LearningSession.init`.
2. In `MapLearningSession.graduate()`, call `store.save(activeSet.map(\.factID), for: category)` after updating the active set (and `store.clear` when it empties), mirroring `LearningSession.graduate()`.
3. In `MapLearningQuizView.buildSession()`, create a `UserDefaultsActiveSetStore()` and pass the category through to `MapLearningSession`.
4. Update `MapLearningQuizView` to accept (or derive) a `category` parameter — currently it receives `newCards: [ReviewCard]` with no category. The caller in `LearningModePickerView` (or wherever `MapLearningQuizView` is instantiated) should pass `.country`.

**Files to change**:
- `ProjectHana/Views/Quiz/MapQuiz/MapLearningSession.swift`
- `ProjectHana/Views/Quiz/MapQuiz/MapLearningQuizView.swift`
- Possibly the caller that instantiates `MapLearningQuizView`

**Acceptance criteria**:
- Starting the New (map) learning flow picks 10 cards and saves them.
- Closing and reopening the app, then entering the New flow again shows the same 10 cards.
- When a card graduates (3 consecutive correct), it leaves the active set and the next pending card fills in; the updated set is persisted.
- Tests in `MapLearningTests.swift` cover the persistence behavior.
