# Story 004 — Per-language streak and active set

## Goal
Make the two key-value-backed pieces of progress — the streak (`StreakTracker`) and the active set
(`ActiveSetStore`) — independent per language, by namespacing their persistence keys with the
active language.

## Design
### StreakTracker
- `StreakTracker` is currently `enum` static API over fixed UserDefaults keys
  (`streak_lastReviewDate`, `streak_count`). Add a language parameter (an `AppLocale`/`String`) to
  `currentStreak(...)` and `recordReview(...)`, and derive per-language keys, e.g.
  `streak_count.<locale>` / `streak_lastReviewDate.<locale>`.
- Update call sites (`MapQuizSession`, `MultipleChoiceSession`, `TextQuizSession`,
  `StatsView`, and the `recordSnapshot(... streak:)` callers) to pass the active language
  (`LanguageManager.shared.current`).
- Each language's streak advances/resets only from its own reviews; one language's streak is
  unaffected by activity in another.

### ActiveSetStore
- Namespace the persistence key by language. Cleanest: add the active language to the key scheme
  (`activeSet.<locale>.<category>`) in `UserDefaultsActiveSetStore` and `KeyValueActiveSetStore`
  (and mirror in `InMemoryActiveSetStore` semantics), OR inject the active language into the store.
- Call sites that build an `ActiveSetStore` (`LearningQuizView`, `MapLearningQuizView`, and
  `SyncCoordinator.makeActiveSetStore()`) pass/scope by the active language.
- Switching language presents that language's own active set; other languages' sets are preserved.

## Acceptance Criteria
1. `StreakTracker` reads/writes per-language keys; a streak in language A is independent of B.
2. `ActiveSetStore` persistence is namespaced per language; language A's active set is independent
   of B's, and switching back restores A's set exactly.
3. All updated call sites pass the active language.
4. Build passes; new tests cover per-language streak independence and per-language active-set
   isolation; existing tests stay green.
