## Goal

Make spaced-repetition card state **independent per quiz mode**. Each quiz mode now reads/writes a
`CardStore` scoped to `(language, quizMode)`, so grading a fact in the Map Tab Quiz never touches that
fact's cards in Multiple Choice (or any other mode). (Story 2 of 6 — builds on the additive `quizMode`
column + `SchemaV3` from #122.)

## Changes

- **`CardStore` is now `(language, quizMode)`-scoped:** every fetch predicate (`allCards`/`dueCards`/
  `newCards`), `seedIfNeeded`, `upsert`, `deduplicate`, and `resetAll` is scoped to both dimensions.
  `seedIfNeeded` takes an optional category filter so a mode only seeds the categories it serves.
- **New `CardStoreProvider` (`@Observable`)** lazily builds + seeds one `CardStore` per `QuizModeID`
  for the active language, rebuilt on language change. Exposes `store(for:)`, an aggregate `revision`
  (Home invalidation), and aggregate `allCards`/`dueCards` (the Progress screen's default mode-
  aggregated totals). `typeCapital` is seeded Countries-only.
- **Provider injected into the environment** in place of the single `CardStore` (`HanahuacApp`,
  `PreviewStore`). `HomeView` resolves a per-mode store for each row's counts; every quiz view +
  `PilePickerView` resolves its own mode's store; `StatsView` reads the provider's aggregate.
- `QuizModeID` gains `servedCategories`; `HomeQuizMode` gains `allModes`.

## Test plan

- [x] `just lint` clean
- [x] `just test` — TEST SUCCEEDED
- [x] New `PerQuizModeProgressTests`: per-mode isolation (grading one mode leaves the others' cards for
      the same fact untouched), no cross-mode dedup, reset scoping, provider vends an independent
      seeded store per mode, `typeCapital` is Countries-only, aggregate `allCards` = union of modes.
- [x] Manual: clean-store launch on the simulator shows each Countries mode with its own independent
      "New 197" count (per-mode seeding works end-to-end; no SwiftData crash on the fresh `SchemaV3`
      store).

Note: the per-mode `recordSnapshot(...)` call sites currently pass the active mode's cards; making the
**daily snapshot** record per-mode + an aggregate rollup is Story 3 — this PR keeps the Progress
screen's card-derived totals correct via the provider aggregate.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
