# Story 004 — Make the active set per mode

## Goal
Each quiz mode tracks its own "new"/in-progress active set independently, so advancing the Multiple
Choice active set for a `(language, category)` does not affect the Map Tab Quiz active set for the same
`(language, category)`.

## Background
`ActiveSetStore` persists an ordered list of factIDs per category, keyed today by
`activeSet.<language>.<category>` (`activeSetKey(language:category:)`). It is constructed per-language
at call sites: `UserDefaultsActiveSetStore(language:)`, `KeyValueActiveSetStore`,
`InMemoryActiveSetStore`, and `SyncCoordinator.makeActiveSetStore(language:)`. Story 001 added the
stable mode token.

## Scope
- Namespace the active-set key by `(language, mode, category)`:
  `activeSet.<language>.<mode>.<category>`. Update `activeSetKey(...)` to take the mode token, and
  thread `mode` through every `ActiveSetStore` implementation (`UserDefaults…`, `KeyValue…`,
  `InMemory…`) and the `makeUbiquitousActiveSetStore` / `SyncCoordinator.makeActiveSetStore`
  factories.
- Update the call sites that build an `ActiveSetStore` (in `LearningQuizView`, `MapLearningQuizView`,
  `CapitalQuizView`, `NameFeatureQuizView`, and any others) to pass the quiz's mode, so each mode reads
  and writes its own active set.
- Preserve the legacy/per-language key handling that Story 005's migration relies on (expose the
  current per-`(language, category)` key as the "legacy" key the migrator copies from into the
  per-mode `mapQuiz` namespace).

## Acceptance Criteria
- [ ] The active-set persistence key is namespaced by `(language, mode, category)`.
- [ ] All `ActiveSetStore` implementations and factories take the mode; call sites pass their quiz's
      mode.
- [ ] Advancing one mode's active set for a `(language, category)` leaves the other modes' active sets
      for the same `(language, category)` unchanged — covered by a test.
- [ ] The pre-per-mode key is still reachable as the migration source for Story 005.
- [ ] `just build` and `just test` green, including the new per-mode active-set isolation test.
