# Feature: Home & Progress counts must refresh immediately after a quiz

Slug: `home-stats-stale-after-quiz`
Type: Bug fix

## Problem

After finishing (or exiting) a quiz and returning to the home screen, the per-row "New N" / "Pending N"
count pills still show the **old** values. The same staleness affects the **Progress screen**
(cards-reviewed, due-today, streak, per-category mastery tiers, per-language breakdown, charts). The
numbers only correct themselves on **app relaunch** (the one confirmed recovery) or on a full subtree
rebuild such as a language switch (`.id(languageManager.current)` re-keys the view).

## Root cause

`HomeView` and `StatsView` derive every displayed number by calling fetch accessors on the
`@Observable` stores:

- `HomeView.quizModeButton` reads `cardStore.newCards(for:).count` and `cardStore.dueCards(for:).count`.
- `StatsView` reads `cardStore.allCards`, `cardStore.dueCards()`, and `progressStatsStore.allSnapshots`.

These accessors run a fresh `FetchDescriptor` against the `ModelContext` and **do not read any
`@Observable` stored property** of the store. SwiftUI's Observation tracking therefore registers **no
dependency** for these views, so when a quiz mutates `ReviewCard` rows / inserts a `DailyProgressSnapshot`
(via `CardStore.upsert` and `ProgressStatsStore.recordSnapshot`), SwiftUI never invalidates the home or
progress views. They keep rendering the previously-fetched numbers until the whole subtree is rebuilt.

## Scope

Make the home count pills and the Progress screen reactively recompute after **any** quiz-driven
mutation, for **all** quiz types and **all** categories, with **no relaunch**.

In scope:
- An observable change signal on the stores that the views depend on, bumped on every persistence
  mutation (`upsert`, `recordSnapshot`, and any card-state save a quiz performs — e.g. graded reviews).
- `HomeView` and `StatsView` re-render and re-fetch when that signal changes.
- Covers every quiz path: MultipleChoice, MapQuiz, TextQuiz (Capital / NameFeature), in both the
  "new" (learning) and "pending" (review) piles, across countries / rivers / mountains / seas.

Out of scope:
- Redesigning the persistence layer or moving to `@Query`-driven views wholesale (a smaller observable
  signal is sufficient and lower-risk). If a `@Query` approach is cleaner for one view it is acceptable,
  but the acceptance criteria below are the contract.
- CloudKit sync behavior, dedup logic, the migration, and streak-key storage are unchanged.

## Acceptance criteria

1. After completing a quiz of **any** type/category and returning to the home screen, the affected row's
   "New N" / "Pending N" pills reflect the new state immediately (no relaunch). A row that becomes fully
   cleared shows the "all done" state and is disabled.
2. After completing a quiz and opening the Progress screen (or while it is already on screen via
   navigation back), the cards-reviewed, due-today, streak, per-category mastery tiers, per-language
   breakdown, and charts reflect the new state immediately.
3. Exiting a quiz early (partial progress) likewise refreshes both screens to the current persisted
   state on return.
4. Switching language still shows that language's track correctly (no regression from the existing
   `.id(languageManager.current)` rebuild).
5. The fix holds on a clean store/build (CI), not only on a warm local simulator.
6. Automated test coverage proves the observable signal fires on card mutation and snapshot recording,
   so the views' fetch-derived numbers are recomputed (regression guard for the observability gap).
7. `just lint` and `just test` pass.

## Notes for implementation

- The stores are already `@Observable` and injected via `.environment(...)`. The minimal robust fix is a
  stored, observable "revision/version" property (e.g. `private(set) var revision: Int = 0` or a
  `lastChanged: Date`) that is bumped inside every method that calls `modelContext.save()`
  (`upsert`, `recordSnapshot`, graded-review saves, `resetAll`, `seedIfNeeded`, `deduplicate`), and that
  the views read once in `body` so Observation registers the dependency. Reading it (even discarding the
  value) before the fetch is enough to tie the view's invalidation to mutations.
- Verify the quiz grading path that mutates `ReviewCard` (sessions: `MultipleChoiceSession`,
  `MapQuizSession`, `TextQuizSession`) ultimately routes its `save()` through a store method that bumps
  the signal — if a session saves directly on the `ModelContext`, add a store-level "card was reviewed"
  entry point (or bump on the snapshot record that every quiz already calls) so the home pills update too.
- Keep changes language-scoped and side-effect-free with respect to other languages.
