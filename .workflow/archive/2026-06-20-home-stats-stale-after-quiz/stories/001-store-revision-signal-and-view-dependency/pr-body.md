## Goal

`HomeView` and `StatsView` derive every displayed number from fetch accessors
(`CardStore.newCards/dueCards/allCards`, `ProgressStatsStore.allSnapshots`) that run a fresh
`FetchDescriptor` and read no `@Observable` stored property. SwiftUI Observation therefore registers
no dependency and never invalidates these views after a quiz mutates `ReviewCard` rows or records a
`DailyProgressSnapshot`. This story closes that gap with a minimal, low-risk fix: a stored, observable
revision counter the views read in `body`, without redesigning the persistence layer.

## Changes

- Added a stored, observable `private(set) var revision: Int = 0` to `CardStore`, bumped via a single
  `markChanged()` helper (`revision &+= 1`) from every method that calls `modelContext.save()`:
  `upsert`, `resetAll`, `seedIfNeeded`, `deduplicate`, and the graduation-consistency save in
  `ensureGraduationConsistency`.
- Added the same observable revision property to `ProgressStatsStore`, bumped from every saving method:
  `recordSnapshot` and `deduplicate`.
- `HomeView` reads `cardStore.revision` in `body` before its fetch-derived counts so Observation ties
  the view's invalidation to store mutations (count pills).
- `StatsView` reads both `cardStore.revision` and `progressStatsStore?.revision` before its fetches so
  cards-reviewed, due-today, per-category tiers, per-language breakdown, and charts recompute after a
  quiz.
- Kept the existing `.id(languageManager.current)` rebuild behavior intact (no language-switch
  regression); change is language-scoped and side-effect-free.
- Used `&+=` (wrapping add) so a long-lived store can never trap on overflow.

## Test plan

- [ ] `just lint` passes
- [ ] `just test` passes
- [ ] `CardStoreTests` proves `revision` increments on `upsert`, `resetAll`, `seedIfNeeded`, `deduplicate`
- [ ] `ProgressStatsStoreTests` proves `revision` increments on `recordSnapshot`, `deduplicate`
- [ ] Complete a quiz and return home: affected row's "New N" / "Pending N" pills update immediately; a fully-cleared row shows "all done" and is disabled
- [ ] Open/return to Progress after a quiz: cards-reviewed, due-today, streak, mastery tiers, per-language breakdown, and charts reflect new state
- [ ] Exit a quiz early: both screens refresh to current persisted state on return
- [ ] Switching language still shows that language's track correctly
