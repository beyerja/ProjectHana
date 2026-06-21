## Goal

Make the learning **active set per quiz mode**, so advancing the Multiple Choice active set for a
`(language, category)` does not affect the Map Tab Quiz active set for the same `(language, category)`.
(Story 4 of 6.)

## Changes

- **`activeSetKey` is namespaced by `(language, mode, category)`** →
  `activeSet.<language>.<mode>.<category>`. `mode: nil` keeps the pre-per-mode per-language key
  (`activeSet.<language>.<category>`) for back-compat callers and as the Story-005 migration source;
  added `legacyPerLanguageActiveSetKey(language:category:)`.
- **Threaded `mode: QuizModeID? = nil`** through `UserDefaultsActiveSetStore`,
  `KeyValueActiveSetStore`, `InMemoryActiveSetStore`, `makeUbiquitousActiveSetStore`, and
  `SyncCoordinator.makeActiveSetStore`.
- **The 4 quiz views that build an active set now pass their own mode:** `LearningQuizView`
  (`.multipleChoice`), `MapLearningQuizView` (`.mapQuiz`), `CapitalQuizView` (`.typeCapital`),
  `NameFeatureQuizView` (`.nameFeature`).

## Test plan

- [x] `just lint` clean
- [x] `just test` — TEST SUCCEEDED
- [x] New `PerModeActiveSetTests`: key namespacing, advancing/clearing one mode leaves other modes'
      active sets untouched, and the legacy per-language key is reachable as the Story-005 migration
      source.
- [x] Existing `ActiveSetStore`/sync tests unchanged and green (`mode` defaults to `nil` → legacy
      per-language key).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
