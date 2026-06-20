# Log — Story 004: Make the active set per mode

## Tasks
- [x] 001: Namespace `activeSetKey` by `(language, mode, category)` → `activeSet.<language>.<mode>.<category>`; `mode: nil` keeps the pre-per-mode per-language key `activeSet.<language>.<category>` (back-compat + Story-005 migration source). Add `legacyPerLanguageActiveSetKey(language:category:)`.
- [x] 002: Thread `mode: QuizModeID? = nil` through `UserDefaultsActiveSetStore`, `KeyValueActiveSetStore`, `InMemoryActiveSetStore`, `makeUbiquitousActiveSetStore`, and `SyncCoordinator.makeActiveSetStore`.
- [x] 003: Update the 4 view call sites to pass their mode: `LearningQuizView` (.multipleChoice), `MapLearningQuizView` (.mapQuiz), `CapitalQuizView` (.typeCapital), `NameFeatureQuizView` (.nameFeature).
- [x] 004: Tests: `PerModeActiveSetTests` — key namespacing, advancing/clearing one mode leaves others untouched, legacy per-language key reachable as migration source. Existing ActiveSetStore tests unchanged (mode defaults to nil). `just generate`/`lint`/`test` green.
