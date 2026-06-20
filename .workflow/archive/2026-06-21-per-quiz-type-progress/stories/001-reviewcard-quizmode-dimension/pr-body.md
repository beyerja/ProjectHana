## Goal

Lay the data-model foundation for **per-quiz-type progress**: add `quizMode` as an orthogonal second
dimension alongside the existing `language` dimension, so a fact's spaced-repetition progress can be
tracked independently per quiz mode. This story is **additive only** — no store/runtime behavior
changes yet (every path defaults `quizMode` to the empty legacy sentinel), so the build and all
existing tests stay green on this commit alone. (Story 1 of 6 for the feature.)

## Changes

- Add a Foundation-only `QuizModeID` enum (`mapQuiz`, `multipleChoice`, `typeCapital`, `nameFeature`)
  as the stable **persisted** token, with `legacyMigrationTarget` (= `mapQuiz`) for the upgrade
  migration. The model/store/migrator layers reference it without a SwiftUI dependency.
- Bridge the SwiftUI `HomeQuizMode` to it via `quizModeID` / `quizModeRawValue` / `init(quizModeID:)`.
- Add a defaulted `quizMode: String = ""` stored column to `ReviewCard` and `DailyProgressSnapshot`
  (CloudKit-safe: defaulted, no `@Attribute(.unique)`). Card identity becomes
  `(factID, language, quizMode)`; the empty-`quizMode` snapshot is the mode-aggregated rollup.
- Bump the head schema to `SchemaV3` (`Schema.Version(3,0,0)`): additive lightweight migration, single
  version, no stages — identical pattern to V2. `HanahuacMigrationPlan` and
  `SyncCoordinator.makeModelContainer()` now open against `SchemaV3`.

## Test plan

- [x] `just lint` clean
- [x] `just test` — TEST SUCCEEDED
- [x] New `QuizModeDimensionTests`: `quizMode` defaults to `""`; the same `(factID, language)` holds
      an independent card per quiz mode; `QuizModeID` round-trips through `HomeQuizMode`; migration
      target is `mapQuiz`.
- [x] Existing per-language / progress tests unchanged and green (defaulted column keeps memberwise
      inits compiling).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
