# Story 002 — Scope CardStore per quiz mode and vend a store per active mode

## Goal
Make spaced-repetition card state independent per quiz mode. Each quiz mode reads/writes a `CardStore`
scoped by `(language, quizMode)`, so grading a fact in one mode never touches that fact's cards in
another mode. Because the Home screen shows multiple modes at once, introduce a provider that vends/
caches a per-mode `CardStore`, and thread the active mode through Home + every quiz view.

## Background
Today a single `CardStore(modelContext:language:)` is built once in `AppRootView.rebuildStores` and
injected into the environment; `HomeView`, `PilePickerView`, `StatsView`, and all quiz views read it
via `@Environment(CardStore.self)`. All fetches scope only by `language`. Story 001 added the
`quizMode` column and a stable mode token.

## Scope
- Scope `CardStore` by `(language, quizMode)`: add a `let quizMode: String`; every `FetchDescriptor`
  predicate (`allCards`, `dueCards`, `newCards`, dedup grouping, `seedIfNeeded`) additionally filters/
  stamps `quizMode`. `seedIfNeeded` stamps inserted cards with this store's `quizMode`; `upsert`
  stamps an empty `quizMode` like it already does for `language`. `deduplicate` keys on
  `(factID, language, quizMode)` (achieved by the store already being mode-scoped, grouping by
  `factID`). `resetAll` clears only this `(language, quizMode)`.
- Introduce a `CardStoreProvider` (`@Observable`, injected in place of / alongside the single
  `CardStore`) that lazily builds and caches one `CardStore` per `(language, quizMode)` for the active
  language, seeding each on first access. It rebuilds when the active language changes (same re-key
  trigger as today). Provide `store(for mode: HomeQuizMode) -> CardStore`.
- Thread the active mode to consumers:
  - `HomeView` resolves the per-mode store for each mode row's count pills (so each mode's new/pending
    counts are independent). Keep reading a revision signal for invalidation — aggregate across the
    vended stores' revisions, or observe the provider, so the pills still refresh after a graded
    answer.
  - Each quiz view obtains the `CardStore` for ITS mode (the mode is already known at the navigation
    `directQuizView`/route level) instead of the single ambient store. Pass the resolved store (or the
    mode) into `MapLearningQuizView`, `MapQuizView`, `LearningQuizView`, `MultipleChoiceQuizView`,
    `CapitalQuizView`, `NameFeatureQuizView`, and `PilePickerView` so they read/write their mode's
    track.
- `StatsView` keeps using an aggregate/whole-language view of cards (mastery tiers across modes) — its
  per-mode breakdown is Story 006; here it must keep compiling and showing today's aggregate numbers
  (e.g. via the provider summing across modes, or a dedicated aggregate accessor).
- Preview/`PreviewStore` helpers updated to vend the provider so previews compile.

## Acceptance Criteria
- [ ] `CardStore` is constructed with `(language, quizMode)` and every read/write/seed/dedup/reset is
      scoped by both; two modes hold independent cards for the same `(factID, language)`.
- [ ] A `CardStoreProvider` vends and caches one seeded `CardStore` per active mode and rebuilds on
      language change; quiz views and Home rows use the store for their own mode.
- [ ] Grading a fact in one mode (mutating + persisting its card) leaves the same fact's cards in the
      other three modes unchanged — covered by a test.
- [ ] Home count pills show per-mode new/pending counts and still refresh immediately after a graded
      answer in that mode.
- [ ] `typeCapital`'s store is only ever populated for the Countries category (it serves no others);
      no cards are created for categories it doesn't serve.
- [ ] `StatsView` still compiles and shows the existing aggregate numbers (per-mode breakdown deferred
      to Story 006).
- [ ] `just build` and `just test` green, including the new cross-mode-isolation test.
