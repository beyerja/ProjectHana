# 001 — Observable store revision signal + HomeView/StatsView depend on it

Branch: `story/home-stats-stale-after-quiz/store-revision-signal`

## Title
Add an observable revision signal to the stores and make HomeView & StatsView depend on it so fetch-derived counts recompute after every persistence mutation.

## Goal
`HomeView` and `StatsView` derive every displayed number from fetch accessors
(`CardStore.newCards/dueCards/allCards`, `ProgressStatsStore.allSnapshots`) that run a fresh
`FetchDescriptor` and read no `@Observable` stored property. SwiftUI Observation therefore registers
no dependency and never invalidates these views after a quiz mutates `ReviewCard` rows or records a
`DailyProgressSnapshot`. This story closes that gap with the minimal, low-risk fix described in
`.workflow/feature.md` (a stored, observable revision counter the views read in `body`), without
redesigning the persistence layer.

## Scope
- Add a stored, observable revision property to `CardStore` (e.g. `private(set) var revision: Int = 0`)
  that is bumped from **every** method that calls `modelContext.save()`: `upsert`, `resetAll`,
  `seedIfNeeded`, `deduplicate`, and the graduation-consistency save in `ensureGraduationConsistency`.
- Add the same stored, observable revision property to `ProgressStatsStore`, bumped from every method
  that saves: `recordSnapshot` and `deduplicate`.
- Bump via a single private helper per store (e.g. `private func markChanged() { revision &+= 1 }`)
  so no save path is missed and overflow is safe.
- In `HomeView` and `StatsView`, read the revision signal once in `body` (or in the computed
  properties evaluated during `body`) **before** the fetch, discarding the value, so Observation ties
  each view's invalidation to store mutations. Both `cardStore.revision` and (where present)
  `progressStatsStore?.revision` must be observed by the view that depends on those fetches:
  - HomeView depends on `cardStore.revision` (count pills).
  - StatsView depends on `cardStore.revision` and `progressStatsStore.revision` (cards-reviewed,
    due-today, per-category tiers, per-language breakdown, charts).
- Keep the existing `.id(languageManager.current)` rebuild behavior intact (no regression on language
  switch).
- Keep the change language-scoped and side-effect-free with respect to other languages.

## Out of scope
- Adding a dedicated "card was reviewed" store entry point for sessions that save the `ModelContext`
  directly (covered by story 002 if needed). Note: every quiz completion path already calls
  `progressStatsStore?.recordSnapshot(...)`, which calls `modelContext.save()`; bumping the revision
  there already invalidates both views after a quiz. Story 002 hardens the graded-card save path.
- CloudKit sync, dedup winner logic, migration, and streak-key storage remain unchanged.

## Acceptance Criteria
1. `CardStore` and `ProgressStatsStore` each expose an observable, `private(set)` revision property
   that increments inside every method that calls `modelContext.save()`.
2. After completing a quiz of any type/category and returning to home, the affected row's "New N" /
   "Pending N" pills reflect the new state immediately (no relaunch); a fully-cleared row shows the
   "all done" state and is disabled.
3. After completing a quiz and opening (or returning to) the Progress screen, cards-reviewed,
   due-today, streak, per-category mastery tiers, per-language breakdown, and charts reflect the new
   state immediately.
4. Exiting a quiz early (partial progress) refreshes both screens to the current persisted state on
   return (the recordSnapshot/save on exit bumps the signal).
5. Switching language still shows that language's track correctly (no regression from the
   `.id(languageManager.current)` rebuild).
6. Automated tests prove the revision signal increments on `upsert`, `resetAll`, `seedIfNeeded`,
   `deduplicate` (CardStore) and on `recordSnapshot`, `deduplicate` (ProgressStatsStore), so the
   views' fetch-derived numbers are recomputed (regression guard for the observability gap). Tests
   go in `HanahuacTests/CardStoreTests.swift` and `HanahuacTests/ProgressStatsStoreTests.swift`.
7. `just lint` and `just test` pass.

## Notes
- Reading the revision value (even `_ = cardStore.revision`) before the fetch in `body` is enough to
  register the Observation dependency; do not gate the fetch on it.
- Use `&+=` (wrapping add) so a long-lived store can never trap on overflow.
